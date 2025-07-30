@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

REM set BOARD=NERDAXEGAMMA
set BOARD=NERDQAXEPLUS2
idf.py set-target esp32s3
idf.py build
esptool.py --chip esp32s3 merge_bin --flash_mode dio --flash_size 16MB --flash_freq 80m 0x0 build\bootloader\bootloader.bin 0x8000 build\partition_table\partition-table.bin 0x10000 build\esp-miner.bin 0x410000 build\www.bin 0xf10000 build\ota_data_initial.bin -o 4.8t-monitor.bin
bitaxetool --config config.cvs --firmware firmware.bin