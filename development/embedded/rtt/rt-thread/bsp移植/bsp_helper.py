#!/usr/bin/env python
# -*- coding: UTF-8 -*-


import sys


def to_hex_upper_str(int_value):
    hex_str = hex(int_value)[2:].upper().zfill(8)
    hex_val = hex(int_value)[:2] + hex_str
    return hex_val


def patch_board_h(flash_size, ram_size):
    flash_size_str = "(%s * 1024)" % flash_size

    print("board/board.h")
    flash_info = "STM32_FLASH_SIZE => %s" % flash_size_str
    ram_info = "STM32_SRAM_SIZE => %s" % ram_size
    print(flash_info)
    print(ram_info)
    print("\r")


def patch_link_gnu_lds(flash_size, ram_size):
    print("board/linker_scripts/link.lds, ====For gnu arm-none-eabi-gcc")
    flash_info = "ROM (rx) : ORIGIN = 0x08000000, LENGTH = xxxk => ROM (rx) : ORIGIN = 0x08000000, LENGTH = %sk" % flash_size
    ram_info = "RAM (rw) : ORIGIN = 0x20000000, LENGTH = yyyk => RAM (rw) : ORIGIN = 0x20000000, LENGTH = %sk" % ram_size

    print(flash_info)
    print(ram_info)
    print("\r")


def patch_link_keil_sct(flash_size, ram_size):
    flash_size_str = to_hex_upper_str(int(flash_size) * 1024)
    ram_size_str = to_hex_upper_str(int(ram_size) * 1024)

    print("board/linker_scripts/link.sct, ====For keil sct")
    flash_info1 = "LR_IROM1 0x08000000 xxxxxxxx => LR_IROM1 0x08000000 %s" % flash_size_str
    flash_info2 = "ER_IROM1 0x08000000 xxxxxxxx => ER_IROM1 0x08000000 %s" % flash_size_str
    ram_info = "RW_IRAM1 0x20000000 yyyyyyyy => RW_IRAM1 0x20000000 %s" % ram_size_str

    print(flash_info1)
    print(flash_info2)
    print(ram_info)
    print("\r")


def patch_link_iar_icf(flash_size, ram_size):
    flash_size_str = to_hex_upper_str(int(0x08000000) + int(flash_size) * 1024 - 1)
    ram_size_str = to_hex_upper_str(int(0x20000000) + int(ram_size) * 1024 - 1)

    print("board/linker_scripts/link.icf, ====For iar icf")
    flash_info = "__ICFEDIT_region_ROM_end__ => %s" % flash_size_str
    ram_info = "__ICFEDIT_region_RAM_end__ => %s" % ram_size_str

    print(flash_info)
    print(ram_info)
    print("\r")


if __name__ == "__main__":
    if 3 != len(sys.argv):
        print("使用方法: %s FLASH_SIZE RAM_SIZE (单位k)" % sys.argv[0])
        exit(0)

    flash_size = sys.argv[1]
    ram_size = sys.argv[2]

    patch_board_h(flash_size, ram_size)
    patch_link_gnu_lds(flash_size, ram_size)
    patch_link_keil_sct(flash_size, ram_size)
    patch_link_iar_icf(flash_size, ram_size)
