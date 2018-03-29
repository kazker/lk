# MSM8996 Target

Heavily modified to enable certain devices (e.g. Dragonboard 820c) to boot ELF64 files, for example, sealed UEFI firmware device files. This saves time making Android-like boot images. Fastboot `boot` flashing check is removed too.

Boot application `aboot` will attempt to boot normal Android image in `boot` partition first, if header check fails, fallback to ELF64 boot mode. There are some restrictions in ELF64 boot mode by design:

- To make it easier for UEFI GOP initialization, display panel won't turn off
- Only single `LOAD` section in ELF64 files will be recognized, it must has physical address and virtual address matched (identity mapping), additionaly, entry point and physical address must match.
- Too many sections considered invalid (`Elf64_Ehdr`, offset and `Elf64_Phdr` must reside in a single UFS page)

If both boot mechanisms fail, it will enter fastboot automatically.

# Make UEFI FD bootable via LK

First piece code in FD definition must be SEC or PEI code.

    [FV.FVMAIN_COMPACT]
    FvAlignment        = 8
    ERASE_POLARITY     = 1
    MEMORY_MAPPED      = TRUE
    STICKY_WRITE       = TRUE
    LOCK_CAP           = TRUE
    LOCK_STATUS        = TRUE
    ...

      INF Dragonboard820cPkg/PI/Pi.inf
      ...

Prepare a linker directive for sealed ELF64 image.

    ENTRY(_start);

    SECTIONS
    {
        _start = 0x80200000;
        . = 0x80200000;
        .data : {
            *(.data)
        }
    }

Note: Most Qualcomm UEFI images start at `0x80200000` or `0x10200000`, depending on platform HRD. But you don't have to do that, you can choose `0x80080000` or something else. But if you changed, make sure entry point in Flash Device Definition (`.fd`) and linker directive matches.

And finally seal UEFI FD into a ELF64 image:

    aarch64-elf-objcopy -I binary -O elf64-littleaarch64 --binary-architecture aarch64 APQ8096SGE_EFI.fd APQ8096SGE_EFI.o
    aarch64-elf-ld -m aarch64elf APQ8096SGE_EFI.o -T Dragonboard820cPkg/FvWrapper.ld -o APQ8096SGE_EFI.elf

Flash into device:

    fastboot flash boot APQ8096SGE_EFI.elf

You should see something like this on serial console.

    [260] Run ELF64 boot routine
    [260] Verifier: Payload has valid ELF magic.
    [260] Verifier: ELF reports valid architecture.
    [270] Verifier: ELF reports valid type.
    [270] Verifier: 1 program header entries found.
    [270] FD entry point = 0x80200000, partition offset = 0xc000, length = 0x120000
    [290] UEFI FD loaded into memory.
    [290] UEFI FD ready.
    [290] RPM GLINK UnInit
    [290] Qseecom De-Init Done in Appsbl
    [300] Jumping to kernel via monitor


    UEFI SEC Phase started, offset : 1258 ms

# Additional notes

This should work for U-Boot too.
