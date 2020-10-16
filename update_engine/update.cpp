/*************************************************************************
    > File Name: update.cpp
    > Author: jkand.huang
    > Mail: jkand.huang@rock-chips.com
    > Created Time: Mon 20 May 2019 09:59:19 AM CST
 ************************************************************************/
#include <stdio.h>
#include <string.h>
#include "update.h"
#include "log.h"
#include "download.h"
#include "rkimage.h"
#include "flash_image.h"
#include "rktools.h"
#include "md5sum.h"
#include "defineHeader.h"

static char * _url = NULL;
static char * _save_path = NULL;
double processvalue = 0;

void RK_ota_set_url(char *url, char *savepath) {
    LOGI("start RK_ota_url.\n");
    if ( url == NULL ) {
        LOGE("RK_ota_set_url : url is NULL.\n");
        return ;
    }
    if (savepath == NULL) {
        _save_path = DEFAULT_DOWNLOAD_PATH;
    } else {
        _save_path = savepath;
    }
    LOGI("save image to %s.\n", _save_path);
    _url = url;
}

bool is_sdboot = false;

UPDATE_CMD update_cmd[] = {
    {"bootloader", false, false, 0, 0, 0, "", flash_bootloader},
    {"parameter", false, false, 0, 0, 0,"", flash_parameter},
    {"uboot", false, false, 0, 0, 0,"", flash_normal},
    {"trust", false, false, 0, 0, 0,"", flash_normal},
    {"boot", false, true, 0, 0, 0,"", flash_normal},
    {"recovery", false, false, 0, 0, 0, "", flash_normal},
    {"rootfs", false, true, 0, 0, 0, "", flash_normal},
    {"oem", false, false, 0, 0, 0, "", flash_normal},
    {"misc", false, false, 0, 0, 0, "", flash_normal},
};

bool RK_ota_set_partition(int partition) {
    //0000000000000000 : 没有升级分区
    //1000000000000000 : 升级loader分区
    //0100000000000000 : 升级parameter分区
    //0010000000000000 : 升级uboot分区
    //0001000000000000 : 升级trust分区
    //0000100000000000 : 升级boot分区
    //0000010000000000 : 升级recovery分区
    //0000001000000000 : 升级rootfs分区
    //0000000100000000 : 升级oem分区
    //0000000010000000 : 升级misc分区，sdboot使用
    int num = sizeof(update_cmd)/sizeof(UPDATE_CMD);
    if (partition == -1) {
        //设置目标分区大小
        RKIMAGE_HDR rkimage_hdr;
        if( analyticImage(_url, &rkimage_hdr) != 0){
            LOGE("analyticImage error.\n");
            return false;
        }
        for (int i = 0; i < num; i++) {
            if ( update_cmd[i].need_update ) {
                update_cmd[i].need_update = false;
                for (int j = 0; j < rkimage_hdr.item_count; j++) {
                    if (strcmp(rkimage_hdr.item[j].name, update_cmd[i].name) == 0) {
                        LOGI("found rkimage_hdr.item[%d].name = %s.\n", j, update_cmd[i].name);
                        if (rkimage_hdr.item[j].file[50]=='H') {
                            update_cmd[i].offset = *((DWORD *)(&rkimage_hdr.item[j].file[51]));
                            update_cmd[i].offset <<= 32;
                            update_cmd[i].offset += rkimage_hdr.item[j].offset;
                            LOGI("offset more than 4G, after adjusting is %lld.\n", update_cmd[i].offset);
                        } else {
                            update_cmd[i].offset = rkimage_hdr.item[j].offset;
                        }

                        if (rkimage_hdr.item[j].file[55]=='H') {
                            update_cmd[i].size = *((DWORD *)(&rkimage_hdr.item[j].file[56]));
                            update_cmd[i].size <<= 32;
                            update_cmd[i].size += rkimage_hdr.item[j].size;
                            LOGI("size more than 4G, after adjusting is %lld.\n", update_cmd[i].size);
                        } else {
                            update_cmd[i].size = rkimage_hdr.item[j].size;
                        }

                        if (is_sdboot) {
                            update_cmd[i].flash_offset = rkimage_hdr.item[j].flash_offset * SECTOR_SIZE;
                        }
                        update_cmd[i].need_update = true;
                        continue ;
                    }
                }
            }
        }
        return true;
    }

    for (int i = 0; i < num; i++) {
        if ( (partition & 0x8000) ) {
            LOGI("need update %s.\n", update_cmd[i].name);
            update_cmd[i].need_update = true;

            if (!isMtdDevice()) {
                int slot = getCurrentSlot();
                if (is_sdboot) {
                    char flash_name[20];
                    getFlashPoint(flash_name);
                    sprintf(update_cmd[i].dest_path, "%s", flash_name);
                } else if ((slot == 0 || slot == 1) && update_cmd[i].is_ab) {
                    //双分区
                    if(strcmp(update_cmd[i].name, "rootfs") == 0){
                        sprintf(update_cmd[i].dest_path, "/dev/block/by-name/%s_%c", "system", slot == 0?'b':'a');
                    } else {
                        sprintf(update_cmd[i].dest_path, "/dev/block/by-name/%s_%c", update_cmd[i].name, slot == 0?'b':'a');
                    }
                } else {
                    //非双分区
                    sprintf(update_cmd[i].dest_path, "/dev/block/by-name/%s", update_cmd[i].name);
                }
            } else {
                int slot = getCurrentSlot();
                LOGI("slot ======= %d.\n", slot);
                if (is_sdboot) {
                    sprintf(update_cmd[i].dest_path, "%s", "/mnt/sdcard/sdupdate.bin");
                    LOGI("update_cmd[%i].des_path = %s.\n", i, update_cmd[i].dest_path);
                } else if ((slot == 0 || slot == 1) && update_cmd[i].is_ab) {
                    //双分区
                    if(strcmp(update_cmd[i].name, "rootfs") == 0){
                        sprintf(update_cmd[i].dest_path, "%s_%c", "system", slot == 0?'b':'a');
			LOGI("update_cmd[%d].dest_path is %s.\n", i,update_cmd[i].dest_path);
                    } else {
                        sprintf(update_cmd[i].dest_path, "%s_%c", update_cmd[i].name, slot == 0?'b':'a');
			LOGI("update_cmd[%d].dest_path is %s.\n",i,update_cmd[i].dest_path);
                    }
                } else {
                    //非双分区
                    strcpy(update_cmd[i].dest_path, update_cmd[i].name);
                }
            }
        }
        partition = (partition << 1);
    }

    return true;

}

void RK_ota_start(RK_upgrade_callback cb) {
    LOGI("start RK_ota_start.\n");
    processvalue = 95;
    cb(NULL, RK_UPGRADE_START);

    //确认升级路径
    if (_url == NULL) {
        LOGE("url is NULL\n");
        cb(NULL, RK_UPGRADE_ERR);
        return ;
    }

    // 1. 获取文件
    int res = download_file(_url, _save_path);
    if (res == 0) {
        _url = _save_path;
    } else if (res == -1) {
        LOGE("download_file error.\n");
        cb(NULL, RK_UPGRADE_ERR);
        return ;
    }

    // 2. 获取文件信息
    if (!RK_ota_set_partition(-1)) {
        LOGE("RK_ota_set_partition failed.\n");
        cb(NULL, RK_UPGRADE_ERR);
        return ;
    }

    // 3. 下载文件到分区并校验
    int num = sizeof(update_cmd)/sizeof(UPDATE_CMD);
    for (int i = 0; i < num; i++ ) {
        if (update_cmd[i].need_update) {
            if (update_cmd[i].cmd != NULL) {
                LOGI("now write %s to %s.\n", update_cmd[i].name, update_cmd[i].dest_path);
                if (!is_sdboot && (strcmp(update_cmd[i].name, "misc") == 0)) {
                    LOGI("ingore misc.\n");
                    continue;
                }
                // 下载固件到分区
                printf("update_cmd.flash_offset = %lld.\n", update_cmd[i].flash_offset);
                if (update_cmd[i].cmd(_url, (void*)(&update_cmd[i])) != 0) {
                    LOGE("update %s error.\n", update_cmd[i].dest_path);
                    cb(NULL, RK_UPGRADE_ERR);
                    return ;
                }
                if (is_sdboot) {
                    LOGI("not check in sdboot.\n");
                    continue;
                }
                // parameter 和loader 先不校验
                if (strcmp(update_cmd[i].name, "parameter") == 0 || strcmp(update_cmd[i].name, "bootloader") == 0) {
                    LOGI("not check parameter and loader.\n");
                    continue;
                }
                // 校验分区
                if (comparefile(update_cmd[i].dest_path, _url, update_cmd[i].flash_offset, update_cmd[i].offset, update_cmd[i].size))
                {
                    LOGI("check %s ok.\n", update_cmd[i].dest_path);
                } else {
                    LOGE("check %s failed.\n", update_cmd[i].dest_path);
                    cb(NULL, RK_UPGRADE_ERR);
                    return ;
                }
            }
        }
    }

    // 4. 是否设置misc

    LOGI("RK_ota_start is ok!");
    processvalue = 100;
    cb(NULL, RK_UPGRADE_FINISHED);
}

int RK_ota_get_progress() {
    return processvalue;
}

void RK_ota_get_sw_version(char *buffer, int  maxLength) {
    getLocalVersion(buffer, maxLength);
}

bool RK_ota_check_version(char *url) {
    char source_version[20] = {0};
    char target_version[20] = {0};
    if (!getLocalVersion(source_version, sizeof(source_version))) {
        return false;
    }

    if (strncmp(url, "http", 4) == 0) {
        //如果是远程文件，从远程获取版本号
        if (!getRemoteVersion(url, target_version, sizeof(target_version))) {
            return false;
        }
    } else {
        //如果是本地文件，从固件获取版本号
        if (!getImageVersion(url, target_version, sizeof(target_version))) {
            return false;
        }
    }

    LOGI("check version new:%s  old:%s", target_version, source_version);
    if (strcmp(target_version, source_version) > 0) {
        return true;
    }
    return false;
}
