###############################################################################
# Copyright (C) 2023, Advanced Micro Devices, Inc.  All rights reserved.
# SPDX-License-Identifier: MIT
###############################################################################
#! /bin/sh

sleep 10

DelayVal=20
IterationCnt=1
dmesg -n 1
if [ -d "/sys/firmware/devicetree/base/firmware/zynqmp-firmware" ]; then
    Interface="zynqmp"
    echo "APU: ZynqMP interface"
    PGGS_INTERFACE=/sys/devices/platform/firmware:zynqmp-firmware/pggs3

    # Disable active wakeups
    echo disabled > /sys/devices/platform/axi/ffa60000.rtc/power/wakeup
    echo disabled > /sys/devices/platform/axi/ff000000.serial/power/wakeup
    echo disabled > /sys/devices/platform/axi/ff010000.serial/power/wakeup
    echo disabled > /sys/devices/platform/axi/ff0a0000.gpio/power/wakeup
else
    Interface="versal"
    echo "APU: Versal interface"
    PGGS_INTERFACE=/sys/devices/platform/firmware:versal-firmware/pggs0

    # Disable active wakeups
    echo disabled > /sys/devices/platform/axi/f12a0000.rtc/power/wakeup
    echo disabled > /sys/devices/platform/axi/f12a0000.rtc/rtc/rtc0/alarmtimer.1.auto/power/wakeup
    echo disabled > /sys/devices/platform/axi/f1020000.gpio/power/wakeup
fi

# Disable console suspend
echo 0 > /sys/module/printk/parameters/console_suspend

sync_apu_rpu() {
    printf "APU: Sleeping ${DelayVal} seconds...\n\n"
    sleep ${DelayVal}

    while :
    do
        ggs_val=$(cat ${PGGS_INTERFACE})
        ggs=$(( $ggs_val & 0xFF00 ))

        usleep 100

        if [ $ggs == $((0xAA00)) ]; then
            echo "APU: Sending sync command"
            ggs_val=$(cat ${PGGS_INTERFACE})
            pggs_val=$(($ggs_val & 0xFFFFFF00 | 0xA5))
            pggs_val=$(printf '%x\n' $pggs_val)
            echo $pggs_val > ${PGGS_INTERFACE}
            ggs_val=$(cat ${PGGS_INTERFACE})
            pggs_val=$(($ggs_val & 0xFFFF00FF))
            pggs_val=$(printf '%x\n' $pggs_val)
            echo $pggs_val > ${PGGS_INTERFACE}
            break
        fi
    done
}

# Get higher and lower APU frequencies
freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies)
IFS=' ' # space is set as delimiter
read -ra freq_list <<< "$freq"
freq_cnt=${#freq_list[@]}
low_freq=${freq_list[0]}
high_freq=${freq_list[$freq_cnt - 1]}

printf "APU: Setting all APU Cores frequency to $(($high_freq / 1000)).$(($high_freq % 1000)) MHz\n\n" 
echo ${high_freq} > /sys/devices/system/cpu/cpu0/cpufreq/scaling_setspeed
echo ${high_freq} > /sys/devices/system/cpu/cpu1/cpufreq/scaling_setspeed
if [ $Interface == "zynqmp" ]; then
    echo ${high_freq} > /sys/devices/system/cpu/cpu2/cpufreq/scaling_setspeed
    echo ${high_freq} > /sys/devices/system/cpu/cpu3/cpufreq/scaling_setspeed
fi

if [ $Interface != "zynqmp" ]; then
    # load partial pdi
    fpgautil -R
    fpgautil -o /usr/bin/aie.dtbo &>/dev/null
    xrt-smi program -u /usr/bin/aie-matrix-multiplication.xclbin &>/dev/null
    xrt-smi advanced --aie-clock -s 1250000000 &>/dev/null
    printf "\nAPU: ************** APU, RPU, PL, AIE in full power mode ***************\n"
    yes > /dev/null &
    yes > /dev/null &
    aie-matrix-multiplication &>/dev/null
fi

if [ $Interface == "zynqmp" ]; then
    printf "\nAPU: ************** APU, RPU, PL in full power mode *******************\n"
    yes > /dev/null &
    yes > /dev/null &
    printf "APU: Sleeping ${DelayVal} seconds...\n\n"
    sleep ${DelayVal}
fi



if [ $Interface == "zynqmp" ]; then
    echo "APU: Latency to low power PL domain"
    ggs_val=$(cat ${PGGS_INTERFACE})
    pggs_val=$(($ggs_val & 0xFFFFFF00 | 0x11))
    pggs_val=$(printf '%x\n' $pggs_val)
    echo $pggs_val > ${PGGS_INTERFACE}
else
    echo "APU: Lowering PL domain power"
    xrt-smi reset --force -d &>/dev/null
    xrt-smi program -u /usr/bin/aie-matrix-multiplication.xclbin  &>/dev/null
    xrt-smi advanced --aie-clock -s 625000000  &>/dev/null
    printf "\nAPU: ********* APU and RPU full load, PL, AIE Half Frequency ***********\n"
    printf "APU: Sleeping ${DelayVal} seconds...\n\n"
    aie-matrix-multiplication  &>/dev/null
fi

if [ $Interface != "zynqmp" ]; then
    printf "\nAPU: ********* APU and RPU full load, PL, AIE clock gated  ************\n"
    printf "APU: Sleeping ${DelayVal} seconds...\n\n"
    sleep ${DelayVal}
fi

if [ $Interface == "zynqmp" ]; then
    echo "APU: Latency to low power PL domain"
    ggs_val=$(cat ${PGGS_INTERFACE})
    pggs_val=$(($ggs_val & 0xFFFFFF00 | 0x11))
    pggs_val=$(printf '%x\n' $pggs_val)
    echo $pggs_val > ${PGGS_INTERFACE}
else
    echo "APU: Lowering PL domain power"
    xrt-smi reset --force -d &>/dev/null
    fpgautil -b /usr/bin/greybox.pdi &>/dev/null
    fpgautil -R
fi

printf "\nAPU: ************** APU and RPU full load, PL in low power *************\n"
printf "APU: Sleeping ${DelayVal} seconds...\n\n"
sleep ${DelayVal}

# Clear the PGGS register first
echo 0x0 > ${PGGS_INTERFACE}

# Set the Delay between 2 power modes
val=$(printf '%x\n' $(($DelayVal << 16)))
ggs_val=$(cat ${PGGS_INTERFACE})
pggs_val=$(($ggs_val & 0xFF00FFFF | $(($DelayVal << 16))))
pggs_val=$(printf '%x\n' $pggs_val)
echo $pggs_val > ${PGGS_INTERFACE}

# Set Iteration count value for APU latency measurement
val=$(printf '%x\n' $(($IterationCnt << 24)))
ggs_val=$(cat ${PGGS_INTERFACE})
pggs_val=$(($ggs_val & 0x00FFFFFF | $(($IterationCnt << 24))))
pggs_val=$(printf '%x\n' $pggs_val)
echo $pggs_val > ${PGGS_INTERFACE}

echo "APU: Sending sync command to idle RPU"
ggs_val=$(cat ${PGGS_INTERFACE})
pggs_val=$(($ggs_val & 0xFFFFFF00 | 0xA5))
pggs_val=$(printf '%x\n' $pggs_val)
echo $pggs_val > ${PGGS_INTERFACE}

printf "\nAPU: ************** APU full load, RPU idle, PL in low power ***********\n"
sync_apu_rpu
printf "\nAPU: Latency to Power OFF APU1 core\n"
time echo 0 > /sys/devices/system/cpu/cpu1/online
sync_apu_rpu

if [ $Interface == "zynqmp" ]; then
    printf "\nAPU: Latency to Power OFF APU2 core\n"
    time echo 0 > /sys/devices/system/cpu/cpu2/online
    sync_apu_rpu

    printf "\nAPU: Latency to Power OFF APU3 core\n"
    time echo 0 > /sys/devices/system/cpu/cpu3/online
    sync_apu_rpu
fi

printf "\nAPU: ******* APU (APU0 only) full load, RPU idle, PL in low power ******\n"
sync_apu_rpu
printf "APU: Setting APU0 Core frequency lower to $(($low_freq / 1000)).$(($low_freq % 1000)) MHz\n"
time echo ${low_freq} > /sys/devices/system/cpu/cpu0/cpufreq/scaling_setspeed

printf "\nAPU: ***** APU (APU0 low freq) full load, RPU idle, PL in low power ****\n"
sync_apu_rpu
time killall yes
printf "APU: Setting APU0 Core frequency higher to $(($high_freq / 1000)).$(($high_freq % 1000)) MHz\n"
echo ${high_freq} > /sys/devices/system/cpu/cpu0/cpufreq/scaling_setspeed

printf "\nAPU: ************* APU Linux Idle, RPU idle, PL in low power ***********\n"
sync_apu_rpu
ggs_val=$(cat ${PGGS_INTERFACE})
pggs_val=$(($ggs_val & 0xFFFFFF00 | 0x5A))
pggs_val=$(printf '%x\n' $pggs_val)
echo $pggs_val > ${PGGS_INTERFACE}

while :
do
    ggs_val=$(cat ${PGGS_INTERFACE})
    ggs=$(( $ggs_val & 0xFF00 ))

#    usleep 100

    if [ $ggs == $((0xaa00)) ]; then
        echo "APU: Sending sync command"
        ggs_val=$(cat ${PGGS_INTERFACE})
        pggs_val=$(($ggs_val & 0xFFFFFF00 | 0xA5))
        pggs_val=$(printf '%x\n' $pggs_val)
        echo $pggs_val > ${PGGS_INTERFACE}
        ggs_val=$(cat ${PGGS_INTERFACE})
        pggs_val=$(($ggs_val & 0xFFFF00FF))
        pggs_val=$(printf '%x\n' $pggs_val)
        echo $pggs_val > ${PGGS_INTERFACE}
    elif [ $ggs == $((0xab00)) ]; then
        echo "APU: APU Suspend request came from RPU"
        echo $pggs_val > ${PGGS_INTERFACE}
        ggs_val=$(cat ${PGGS_INTERFACE})
        pggs_val=$(($ggs_val & 0xFFFF00FF))
        ggs_val=$(printf '%x\n' $pggs_val)
        echo mem > /sys/power/state
    elif [ $ggs == $((0x5500)) ]; then
        echo "APU: Resumed script successfully"
        echo "APU: Sending sync command"
        ggs_val=$(cat ${PGGS_INTERFACE})
        pggs_val=$(($ggs_val & 0xFFFFFF00 | 0xA5))
        pggs_val=$(printf '%x\n' $pggs_val)
        echo $pggs_val > ${PGGS_INTERFACE}
        ggs_val=$(cat ${PGGS_INTERFACE})
        pggs_val=$(($ggs_val & 0xFFFF00FF))
        pggs_val=$(printf '%x\n' $pggs_val)
        echo $pggs_val > ${PGGS_INTERFACE}
        break
    fi
done


printf "\nAPU: ************* APU Linux Idle, RPU Idle, PL in low power ***********\n"
sync_apu_rpu
yes > /dev/null &
yes > /dev/null &
if [ $Interface == "zynqmp" ]; then
    yes > /dev/null &
    yes > /dev/null &
fi
printf "APU: Setting APU0 Core frequency lower to $(($low_freq / 1000)).$(($low_freq % 1000)) MHz\n"
time echo ${low_freq} > /sys/devices/system/cpu/cpu0/cpufreq/scaling_setspeed

printf "\nAPU: ******* APU (APU0 low freq) full load, RPU idle, PL in low power **\n"
sync_apu_rpu
printf "APU: Setting APU0 Core high frequency to $(($high_freq / 1000)).$(($high_freq % 1000)) MHz\n"
time echo ${high_freq} > /sys/devices/system/cpu/cpu0/cpufreq/scaling_setspeed

printf "\nAPU: ******* APU (APU0 only) full load, RPU idle, PL in low power ******\n"
sync_apu_rpu
printf "\nAPU: Latency to Power ON APU1 core\n"
time echo 1 > /sys/devices/system/cpu/cpu1/online
sync_apu_rpu

if [ $Interface == "zynqmp" ]; then
    printf "\nAPU: Latency to Power ON APU2 core\n"
    time echo 1 > /sys/devices/system/cpu/cpu2/online
    sync_apu_rpu
    printf "\nAPU: Latency to Power ON APU3 core\n"
    time echo 1 > /sys/devices/system/cpu/cpu3/online
    sync_apu_rpu
fi

printf "\nAPU: *************** APU full load, RPU idle, PL in low power **********\n"
sync_apu_rpu
ggs_val=$(cat ${PGGS_INTERFACE})
pggs_val=$(($ggs_val & 0xFFFFFF00 | 0x5A))
pggs_val=$(printf '%x\n' $pggs_val)
echo $pggs_val > ${PGGS_INTERFACE}

printf "\nAPU: ************** APU and RPU full load, PL in low power *************\n"
printf "APU: Sleeping ${DelayVal} seconds...\n\n"
sleep ${DelayVal}
if [ $Interface == "zynqmp" ]; then
    echo "APU: Latency to Power ON PL domain"
    ggs_val=$(cat ${PGGS_INTERFACE})
    pggs_val=$(($ggs_val & 0xFFFFFF00 | 0x12))
    pggs_val=$(printf '%x\n' $pggs_val)
    echo $pggs_val > ${PGGS_INTERFACE}
printf "\nAPU: **************** APU, RPU and PL in high power ********************\n"
else
    echo "APU: Powering on PL domain"
    # load partial pdi
#    time (fpgautil -R && fpgautil -b /usr/bin/partial.pdi)
    fpgautil -R
    fpgautil -o /usr/bin/aie.dtbo &>/dev/null
    xrt-smi program -u /usr/bin/aie-matrix-multiplication.xclbin &>/dev/null
    xrt-smi advanced --aie-clock -s 1250000000 &>/dev/null
    printf "\nAPU: ************** APU, RPU, PL, AIE in full power mode ***************\n"
    yes > /dev/null &
    yes > /dev/null &
    aie-matrix-multiplication &>/dev/null
fi

printf "APU: Sleeping ${DelayVal} seconds...\n\n"
sleep ${DelayVal}

killall yes
echo "APU: Power demo application completed successfully!"

dmesg -n 7
