#!/bin/bash
### file: rockchip-test.sh
### function: ddr cpu gpio flash bt audio recovery s2r sdio/pcie(wifi)
###           ethernet reboot ddrfreq npu camera video and so on.

moudle_env()
{
   export  MODULE_CHOICE
}

module_choice()
{
    echo "******************************************************"
    echo "***                                                ***"
    echo "***          *****************************         ***"
    echo "***          *    ROCKCHIPS TEST TOOLS   *         ***"
    echo "***          *  V1.0 updated on 20220218 *         ***"
    echo "***          *****************************         ***"
    echo "***                                                ***"
    echo "*****************************************************"


    echo "*****************************************************"
    echo "ddr test :            1 (memtester & stressapptest)"
    echo "cpufreq test:         2 (cpufreq stresstest)"
    echo "flash stress test:    3"
    echo "bluetooth test:       4 (bluetooth on&off test)"
    echo "audio test:           5"
    echo "recovery test:        6 (default wipe all)"
    echo "suspend_resume test:  7 (suspend & resume)"
    echo "wifi test:            8"
    echo "ethernet test:        9"
    echo "auto reboot test:     10"
    echo "ddr freq scaling test 11"
    echo "npu test              12"
    echo "npu2 test             13 (rk356x or rk3588)"
    echo "camera test           14 (use rkisp_demo)"
    echo "video test            15 (use gstreamer-wayland and app_demo)"
    echo "gpu test              16 (use glmark2)"
    echo "chromium test         17 (chromium with video hardware acceleration)"
    echo "nand power lost test: 18"
    echo "*****************************************************"

    echo  "please input your test moudle: "
    read -t 30  MODULE_CHOICE
}

npu_stress_test()
{
    bash /rockchip-test/npu/npu_test.sh
}

npu2_stress_test()
{
    bash /rockchip-test/npu2/npu_test.sh
}

ddr_test()
{
    bash /rockchip-test/ddr/ddr_test.sh
}

cpufreq_test()
{
    bash /rockchip-test/cpu/cpufreq_test.sh
}

flash_stress_test()
{
    bash /rockchip-test/flash_test/flash_stress_test.sh 5 20000&
}

recovery_test()
{
    bash /rockchip-test/recovery_test/recovery_test.sh
}

suspend_resume_test()
{
    bash /rockchip-test/suspend_resume/suspend_resume.sh
}

wifi_test()
{
    bash /rockchip-test/wifi/wifi_test.sh
}

ethernet_test()
{
    bash /test_plan/ethernet/eth_test.sh
}

bluetooth_test()
{
    bash /rockchip-test/bluetooth/bt_onoff.sh &
}

audio_test()
{
    bash /rockchip-test/audio/audio_functions_test.sh
}

auto_reboot_test()
{
    fcnt=/userdata/cfg/rockchip/reboot_cnt;
    if [ -e "$fcnt" ]; then
	rm -f $fcnt;
    fi
    bash /rockchip-test/auto_reboot/auto_reboot.sh
}

ddr_freq_scaling_test()
{
    bash /rockchip-test/ddr/ddr_freq_scaling.sh
}

camera_test()
{
    bash /rockchip-test/camera/camera_test.sh
}

video_test()
{
    bash /rockchip-test/video/video_test.sh
}

gpu_test()
{
    bash /rockchip-test/gpu/gpu_test.sh
}

chromium_test()
{
    bash /rockchip-test/chromium/chromium_test.sh
}

power_lost_test()
{
        fcnt=/data/config/rockchip-test/reboot_cnt;
        if [ -e "$fcnt" ]; then
                rm -f $fcnt;
        fi
        bash /rockchip-test/flash_test/power_lost_test.sh &
}

module_test()
{
    case ${MODULE_CHOICE} in
        1)
            ddr_test
            ;;
        2)
            cpufreq_test
            ;;
        3)
            flash_stress_test
            ;;
        4)
            bluetooth_test
            ;;
        5)
            audio_test
            ;;
        6)
            recovery_test
            ;;
        7)
            suspend_resume_test
            ;;
        8)
            wifi_test
            ;;
        9)
            ethernet_test
            ;;
        10)
            auto_reboot_test
            ;;
	11)
	    ddr_freq_scaling_test
	    ;;
	12)
	    npu_stress_test
	    ;;
	13)
	    npu2_stress_test
	    ;;
	14)
	    camera_test
	    ;;
	15)
	    video_test
	    ;;
	16)
	    gpu_test
	    ;;
	17)
	    chromium_test
	    ;;
	18)
	    power_lost_test
	    ;;
    esac
}

module_choice
module_test
