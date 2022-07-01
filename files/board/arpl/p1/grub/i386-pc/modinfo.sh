#!/bin/bash

# User-controllable options
grub_modinfo_target_cpu=i386
grub_modinfo_platform=pc
grub_disk_cache_stats=0
grub_boot_time_stats=0
grub_have_font_source=0

# Autodetected config
grub_have_asm_uscore=0
grub_bss_start_symbol="__bss_start"
grub_end_symbol="end"

# Build environment
grub_target_cc='/home/fabio/dirgit/arpl/buildroot-2022.02.2/output/host/bin/x86_64-buildroot-linux-gnu-gcc'
grub_target_cc_version='x86_64-buildroot-linux-gnu-gcc.br_real (Buildroot -gf34edcf) 10.3.0'
grub_target_cflags='-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64  -Os -g0 -D_FORTIFY_SOURCE=1 -Os -Wall -W -Wshadow -Wpointer-arith -Wundef -Wchar-subscripts -Wcomment -Wdeprecated-declarations -Wdisabled-optimization -Wdiv-by-zero -Wfloat-equal -Wformat-extra-args -Wformat-security -Wformat-y2k -Wimplicit -Wimplicit-function-declaration -Wimplicit-int -Wmain -Wmissing-braces -Wmissing-format-attribute -Wmultichar -Wparentheses -Wreturn-type -Wsequence-point -Wshadow -Wsign-compare -Wswitch -Wtrigraphs -Wunknown-pragmas -Wunused -Wunused-function -Wunused-label -Wunused-parameter -Wunused-value  -Wunused-variable -Wwrite-strings -Wnested-externs -Wstrict-prototypes -g -Wredundant-decls -Wmissing-prototypes -Wmissing-declarations  -Wextra -Wattributes -Wendif-labels -Winit-self -Wint-to-pointer-cast -Winvalid-pch -Wmissing-field-initializers -Wnonnull -Woverflow -Wvla -Wpointer-to-int-cast -Wstrict-aliasing -Wvariadic-macros -Wvolatile-register-var -Wpointer-sign -Wmissing-include-dirs -Wmissing-prototypes -Wmissing-declarations -Wformat=2 -march=i386 -m32 -mrtd -mregparm=3 -falign-jumps=1 -falign-loops=1 -falign-functions=1 -freg-struct-return -mno-mmx -mno-sse -mno-sse2 -mno-sse3 -mno-3dnow -msoft-float -fno-dwarf2-cfi-asm -mno-stack-arg-probe -fno-asynchronous-unwind-tables -fno-unwind-tables -fno-PIE -fno-pie -fno-stack-protector -Wtrampolines'
grub_target_cppflags='-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -Os -fno-stack-protector -Wall -W  -DGRUB_MACHINE_PCBIOS=1 -DGRUB_MACHINE=I386_PC -m32 -nostdinc -isystem /home/fabio/dirgit/arpl/buildroot-2022.02.2/output/host/lib/gcc/x86_64-buildroot-linux-gnu/10.3.0/include -I$(top_srcdir)/include -I$(top_builddir)/include'
grub_target_ccasflags=' -g  -m32 -msoft-float'
grub_target_ldflags=' -Os -m32 -Wl,-melf_i386 -no-pie -Wl,--build-id=none'
grub_cflags='-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64  -Os -g0 -D_FORTIFY_SOURCE=1 -Os'
grub_cppflags='-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -Os -fno-stack-protector -D_FILE_OFFSET_BITS=64'
grub_ccasflags='-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64  -Os -g0 -D_FORTIFY_SOURCE=1 -Os'
grub_ldflags=''
grub_target_strip='/home/fabio/dirgit/arpl/buildroot-2022.02.2/output/host/bin/x86_64-buildroot-linux-gnu-strip'
grub_target_nm='/home/fabio/dirgit/arpl/buildroot-2022.02.2/output/host/bin/x86_64-buildroot-linux-gnu-gcc-nm'
grub_target_ranlib='ranlib'
grub_target_objconf=''
grub_target_obj2elf=''
grub_target_img_base_ldopt='-Wl,-Ttext'
grub_target_img_ldflags='@TARGET_IMG_BASE_LDFLAGS@'

# Version
grub_version="2.04"
grub_package="grub"
grub_package_string="GRUB 2.04"
grub_package_version="2.04"
grub_package_name="GRUB"
grub_package_bugreport="bug-grub@gnu.org"
