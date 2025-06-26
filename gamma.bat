@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

echo 正在删除旧的固件文件...
if exist nerdaxegamma.bin del nerdaxegamma.bin

set BOARD=NERDAXEGAMMA
idf.py set-target esp32s3
idf.py build

echo 正在合并固件文件...
esptool.py --chip esp32s3 merge_bin --flash_mode dio --flash_size 16MB --flash_freq 80m 0x0 build\bootloader\bootloader.bin 0x8000 build\partition_table\partition-table.bin 0x10000 build\esp-miner.bin 0x410000 build\www.bin 0xf10000 build\ota_data_initial.bin -o nerdaxegamma.bin
timeout /t 10 /nobreak

echo 检查固件文件是否生成成功...
if exist nerdaxegamma.bin (
    echo ✅ 固件文件生成成功！
    echo 正在烧录固件到设备...
    bitaxetool --config config-1chip.cvs --firmware nerdaxegamma.bin
) else (
    echo ❌ 错误：固件文件生成失败！
    echo 请检查编译过程是否有错误。
    pause
    exit /b 1
)

echo 操作完成！
pause