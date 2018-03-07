#!/bin/bash
TOOLCHAIN_PREFIX=arm-eabi-
make msm8916 EMMC_BOOT=1 -j4
signlk -i=./build-msm8916/emmc_appsboot.mbn -o=./build-msm8916/emmc_appsboot_signed.mbn

