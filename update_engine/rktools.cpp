/*************************************************************************
    > File Name: rktools.cpp
    > Author: jkand.huang
    > Mail: jkand.huang@rock-chips.com
    > Created Time: Fri 17 May 2019 07:30:44 PM CST
 ************************************************************************/

#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include "log.h"
#include "rktools.h"
#include "download.h"
extern "C" {
    #include "../mtdutils/mtdutils.h"
}


#define LOCAL_VERSION_PATH "/etc/version"
#define DOWNLOAD_VERSION_PATH "/tmp/version"

bool getVersionFromfile(const char * filepath,char *version, int maxLength) {
    if (version == NULL || filepath == NULL) {
        LOGE("getLocalVersion is error, version == null.\n");
        return false;
    }
    FILE *fp = fopen(filepath, "r");
    if (fp == NULL) {
        LOGE("open %s failed, error is %s.\n", filepath, strerror(errno));
        return false;
    }

    char *line = NULL;
    size_t len = 0;
    size_t read;
    while ((read = getline(&line, &len, fp)) != -1) {
        if (read == 0 || line[0] == '#') {
            continue;
        }
        char *pline = strstr(line, "RK_VERSION");
        if (pline != NULL && (pline = strstr(pline, "=")) != NULL) {
            pline++; //过滤掉等于号
            //过滤掉空格
            while (*pline == ' ') {
                pline++;
            }
            int pline_len = strlen(pline) - 1;
            int version_len = (pline_len > maxLength ? maxLength:pline_len);
            memcpy(version, pline, version_len);
            LOGI("version = %s.\n", version);
            break;
        }
    }
    free(line);
    fclose(fp);
    return true;
}

//下载服务器版本号文件
bool getRemoteVersion(char *url, char *version, int maxLength) {
    if (url == NULL) {
        LOGE("getRemoteVersion url is null.\n");
        return false;
    }

    if (download_file(url, DOWNLOAD_VERSION_PATH) == -1){
        LOGE("getRemoteVersion failed, url is %s.\n", url);
        return false;
    }

    return getVersionFromfile(DOWNLOAD_VERSION_PATH, version, maxLength);
}

//获取本地版本号
bool getLocalVersion(char *version, int maxLength) {
    return getVersionFromfile(LOCAL_VERSION_PATH, version, maxLength);
}

//判断是MTD还是block 设备
bool isMtdDevice() {
    char param[2048];
    int fd, ret;
    char *s = NULL;
    fd = open("/proc/cmdline", O_RDONLY);
    ret = read(fd, (char*)param, 2048);
    s = strstr(param,"storagemedia");
    if(s == NULL){
        LOGI("no found storagemedia in cmdline, default is not MTD.\n");
        return false;
    }else{
        s = strstr(s, "=");
        if (s == NULL) {
            LOGI("no found storagemedia in cmdline, default is not MTD.\n");
            return false;
        }

        s++;
        while (*s == ' ') {
            s++;
        }

        if (strncmp(s, "mtd", 3) == 0 ) {
            LOGI("Now is MTD.\n");
            return true;
        } else if (strncmp(s, "sd", 2) == 0) {
            LOGI("Now is SD.\n");
            if ( !access(MTD_PATH, F_OK) ) {
                LOGI("Now is MTD.\n");
                return true;
            }
        }
    }
    LOGI("Current device is not MTD");
    return false;
}

/**
 * 从cmdline 获取从哪里引导
 * 返回值：
 *     0: a分区
 *     1: b分区
 *    -1: recovery 模式
 */
int getCurrentSlot(){
    char cmdline[CMDLINE_LENGTH];
    int fd = open("/proc/cmdline", O_RDONLY);
    read(fd, (char*)cmdline, CMDLINE_LENGTH);
    close(fd);
    char *slot = strstr(cmdline, "androidboot.slot_suffix");
    if(slot != NULL){
        slot = strstr(slot, "=");
        if(slot != NULL && *(++slot) == '_'){
            slot += 1;
            if((*slot) == 'a'){
                return 0;
            }else if((*slot) == 'b'){
                return 1;
            }
        }
    }
    LOGI("Current Mode is recovery.\n");
    return -1;
}

void getFlashPoint(char *path) {
    char *emmc_point = getenv(EMMC_POINT_NAME);
    if ( !access(emmc_point, F_OK) ) {
        LOGI("Current device is emmc : %s.\n", emmc_point);
        strcpy(path, emmc_point);
    } else {
        LOGI("Current device is nand : %s.\n", NAND_DRIVER_DEV_LBA);
        strcpy(path, NAND_DRIVER_DEV_LBA);
    }
}
/*
 * 获得flash 的大小，和块数
 */
int getFlashSize(char *path, long long* flash_size, long long* block_num) {

    if (isMtdDevice()) {
        size_t total_size;
        size_t erase_size;
        mtd_scan_partitions();
        const MtdPartition *part = mtd_find_partition_by_name("rk-nand");
        if (part == NULL || mtd_partition_info(part, &total_size, &erase_size, NULL)) {
            LOGE("Can't find %s\n", "rk-nand");
            return -1;
        }
        total_size = total_size - (erase_size * 4);
        *flash_size = total_size / 1024; //Kib
        *block_num = *flash_size * 2;
    } else {
        int fd_dest = open(path, O_RDWR);
        if (fd_dest < 0) {
            LOGE("Can't open %s\n", path);
            return -2;
        }
        if ((*flash_size = lseek64(fd_dest, 0, SEEK_END)) == -1) {
            LOGE("getFlashInfo lseek64 failed.\n");
            return -2;
        }
        lseek64(fd_dest, 0, SEEK_SET);
        *flash_size = *flash_size / (1024);    //Kib
        *block_num = *flash_size * 2;
        close(fd_dest);
    }
    return 0;
}
