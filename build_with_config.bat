@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

echo ===============================================
echo JingleMiner 构建脚本 (带配置预处理)
echo ===============================================

REM 确保scripts目录存在
if not exist scripts mkdir scripts

REM 检查Python是否可用
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: Python未安装或不在PATH中
    pause
    exit /b 1
)

REM 构建单芯固件 (1.2T)
echo.
echo [1/6] 构建单芯固件...
set BOARD=NERDAXEGAMMA
idf.py set-target esp32s3
idf.py build

if %errorlevel% neq 0 (
    echo 错误: 构建失败
    pause
    exit /b 1
)

echo.
echo [2/6] 生成NVS配置分区 (1.2T)...
python scripts\generate_nvs_partition.py release\JingleMiner1.2T.cvs build\nvs_1.2T.bin

echo.
echo [3/6] 合并固件 (包含预处理配置 1.2T)...
esptool.py --chip esp32s3 merge_bin --flash_mode dio --flash_size 16MB --flash_freq 80m ^
    0x0 build\bootloader\bootloader.bin ^
    0x8000 build\partition_table\partition-table.bin ^
    0x9000 build\nvs_1.2T.bin ^
    0x10000 build\esp-miner.bin ^
    0x410000 build\www.bin ^
    0xf10000 build\ota_data_initial.bin ^
    -o release\JingleMiner1.2T_with_config.bin

REM 构建4芯固件 (4.8T)
echo.
echo [4/6] 构建4芯固件...
set BOARD=NERDQAXEPLUS2
idf.py set-target esp32s3
idf.py build

if %errorlevel% neq 0 (
    echo 错误: 构建失败
    pause
    exit /b 1
)

echo.
echo [5/6] 生成NVS配置分区 (4.8T)...
python scripts\generate_nvs_partition.py release\JingleMiner4.8T.cvs build\nvs_4.8T.bin

echo.
echo [6/6] 合并固件 (包含预处理配置 4.8T)...
esptool.py --chip esp32s3 merge_bin --flash_mode dio --flash_size 16MB --flash_freq 80m ^
    0x0 build\bootloader\bootloader.bin ^
    0x8000 build\partition_table\partition-table.bin ^
    0x9000 build\nvs_4.8T.bin ^
    0x10000 build\esp-miner.bin ^
    0x410000 build\www.bin ^
    0xf10000 build\ota_data_initial.bin ^
    -o release\JingleMiner4.8T_with_config.bin

echo.
echo ===============================================
echo 构建完成!
echo ===============================================
echo 生成的文件:
echo   - release\JingleMiner1.2T_with_config.bin (包含预配置)
echo   - release\JingleMiner4.8T_with_config.bin (包含预配置)
echo.
echo 现在您可以直接烧录这些bin文件，无需再使用bitaxetool处理配置!
echo.
echo 烧录命令示例:
echo   esptool.py write_flash 0x0 release\JingleMiner1.2T_with_config.bin
echo ===============================================
pause 