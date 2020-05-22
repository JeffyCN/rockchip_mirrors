/*************************************************************************
    > File Name: main.cpp
    > Author: jkand.huang
    > Mail: jkand.huang@rock-chips.com
    > Created Time: Mon 20 May 2019 10:56:06 AM CST
 ************************************************************************/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <getopt.h>
#include <sys/reboot.h>
#include "log.h"
#include "update.h"
#include "../bootloader.h"
#include "defineHeader.h"

RK_Upgrade_Status_t m_status = RK_UPGRADE_ERR;

void handle_upgrade_callback(void *user_data, RK_Upgrade_Status_t status){
    if (status == RK_UPGRADE_FINISHED) {
        LOGI("rk ota success.\n");
        setSlotActivity();
    }
    m_status = status;
    LOGI("rk m_status = %d.\n", m_status);
}

static int MiscUpdate(char *url,  char *update_partition, char *save_path) {
    int partition;
    if (url == NULL) {
        //如果没有传入URL，则可以去查找是否有存在
        LOGE("MiscUpdate URL must be set.\n");
        return -1;
    }
    if (update_partition == NULL) {
        //没有传入要升级的分区，默认升级，u-boot，trust，boot，recovery，boot，rootfs，oem
        partition = 0x3F00;
    } else {
        partition = strtol(update_partition+2, NULL, 16);
    }

    if ((partition & 0x0400)) {
        LOGI("update recovery in normal system.\n");
        partition = partition & 0xFBFF;
        RK_ota_set_url(url, save_path);
        LOGI("url = %s.\n", url);
        if (!RK_ota_set_partition(0x0400)) {
            LOGE("ota file is error.\n");
            return -1;
        }
        RK_ota_start(handle_upgrade_callback);
        if (m_status != RK_UPGRADE_FINISHED) {
            return -1;
        }
    }

    //写MISC
    struct bootloader_message msg;
    memset(&msg, 0, sizeof(msg));
    char recovery_str[] = "recovery\n--update_package=";
    strcpy(msg.command, "boot-recovery");
    strcpy(msg.recovery, recovery_str);
    if (strcmp(save_path, DEFAULT_DOWNLOAD_PATH) != 0) {
        memcpy(msg.recovery + strlen(recovery_str), save_path, ((strlen(save_path) > sizeof(msg.recovery))?sizeof(msg.recovery) : strlen(save_path)));
    } else {
        memcpy(msg.recovery + strlen(recovery_str), url, ((strlen(url) > sizeof(msg.recovery))?sizeof(msg.recovery) : strlen(url)));
    }
    msg.recovery[strlen(msg.recovery) + 1] = '\n';
    memcpy(msg.needupdate, &partition, 4);
    set_bootloader_message(&msg);
    return 0;
}

void display() {
    LOGI("--misc=now           Linux A/B mode: Setting the current partition to bootable.\n");
    LOGI("--misc=other         Linux A/B mode: Setting another partition to bootable.\n");
    LOGI("--misc=update        Recovery mode: Setting the partition to be upgraded.\n");
    LOGI("--misc=wipe_userdata Format data partition.\n");
    LOGI("--update             Upgrade mode.\n");
    LOGI("--partition=0xFF00   Set the partition to be upgraded.\n");
    LOGI("                     0xFF00: 1111 1111 0000 0000.\n");
    LOGI("                     11111111: loader parameter uboot trust boot recovery rootfs oem.\n");
    LOGI("--reboot             Restart the machine at the end of the program.\n");
    LOGI("--version_url=url    The path to the file of version.\n");
    LOGI("--image_url=url      Path to upgrade firmware.\n");
    LOGI("--savepath=url       save the update.img to url.\n");

}

static const struct option engine_options[] = {
  { "update", optional_argument, NULL, 'u' },
  { "version_url", required_argument, NULL, 'v' + 'u' },
  { "image_url", required_argument, NULL, 'i' + 'u'},
  { "check", required_argument, NULL, 'c' },
  { "misc", required_argument, NULL, 'm' },
  { "partition", required_argument, NULL, 'p' },
  { "reboot", no_argument, NULL, 'r' },
  { "help", no_argument, NULL, 'h' },
  { "pipefd", required_argument, NULL, 'p' + 'f' },
  { "savepath", required_argument, NULL, 's'},
  { NULL, 0, NULL, 0 },
};

extern bool is_sdboot;
int main(int argc, char *argv[]) {
    LOGI("*** update_engine: Version V1.0.1 ***.\n");
    int arg;
    char *image_url = NULL;
    char *version_url = NULL;
    char *misc_func = NULL;
    char *save_path = NULL;
    char *partition = NULL;
    bool is_update = false;
    bool is_reboot = false;
    int pipefd = -1;

    while ((arg = getopt_long(argc, argv, "", engine_options, NULL)) != -1) {
        switch (arg) {
        case 'u': is_update = true; if(optarg != NULL) is_sdboot = true; continue;
        case 'c': version_url = optarg; continue;
        case 'm': misc_func = optarg; continue;
        case 'p': partition = optarg; continue;
        case 's': save_path = optarg; continue;
        case 'r': is_reboot = true; continue;
        case 'v' + 'u': version_url = optarg; continue;
        case 'i' + 'u': image_url = optarg; continue;
        case 'p' + 'f': pipefd = atoi(optarg); continue;
        case 'h': display(); break;
        case '?':
            LOGE("Invalid command argument\n");
            continue;
        }
    }

    if ( is_update ) {
        int res = 0x3F00; //默认升级的分区
        if (partition != NULL) {
            res = strtol(partition+2, NULL, 16);
        }
        RK_ota_set_url(image_url, save_path);
        if ( !RK_ota_set_partition(res) ){
            LOGE("ota file is error.\n");
            return -1;
        }

        if (version_url != NULL) {
            if (!RK_ota_check_version(version_url) ){
                LOGE("you shouldn't update the device.\n");
                return -1;
            }
        }

        RK_ota_start(handle_upgrade_callback);
    }else if (misc_func != NULL) {
        if (strcmp(misc_func, "now") == 0) {
            if (setSlotSucceed() ==0) {
                m_status = RK_UPGRADE_FINISHED;
            }
        } else if (strcmp(misc_func, "other") == 0) {
            if (setSlotActivity() == 0) {
                m_status = RK_UPGRADE_FINISHED;
            }
        } else if (strcmp(misc_func, "wipe_userdata") == 0) {
            if (wipe_userdata(0) == 0) {
                m_status = RK_UPGRADE_FINISHED;
            }
        } else if (strcmp(misc_func, "update") == 0) {
            if (MiscUpdate(image_url, partition, save_path) == 0) {
                m_status = RK_UPGRADE_FINISHED;
            }
        } else if (strcmp(misc_func, "display") == 0) {
            miscDisplay();
        } else {
            LOGE("unknow misc cmdline : %s.\n", misc_func);
            return 0;
        }
    }

    if (is_reboot && (m_status == RK_UPGRADE_FINISHED)) {
        sync();
        reboot(RB_AUTOBOOT);
    }

    return m_status;
}
