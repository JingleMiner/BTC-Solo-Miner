@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

echo ===============================================
echo JingleMiner 一体化构建脚本
echo 配置预处理 + 固件合并 = 一个完整的bin文件
echo ===============================================

REM 检查必要的工具
echo [检查] 验证构建环境...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: Python未安装或不在PATH中
    pause
    exit /b 1
)

esptool.py version >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: esptool.py不可用，请检查ESP-IDF环境
    pause
    exit /b 1
)

REM 创建必要的目录
if not exist scripts mkdir scripts
if not exist release mkdir release
if not exist build mkdir build

echo [检查] 环境验证通过!
echo.

REM ============ 构建1.2T版本 ============
echo ===============================================
echo 构建 JingleMiner 1.2T 版本
echo ===============================================

echo [1/4] 设置构建环境 (1.2T)...
set BOARD=NERDAXEGAMMA
idf.py set-target esp32s3

echo [2/4] 编译固件 (1.2T)...
idf.py build
if %errorlevel% neq 0 (
    echo 错误: 固件编译失败
    pause
    exit /b 1
)

echo [3/4] 生成配置分区 (1.2T)...
python scripts\csv_to_nvs.py release\JingleMiner1.2T.cvs build\nvs_1.2T.bin
if %errorlevel% neq 0 (
    echo 错误: 配置分区生成失败
    pause
    exit /b 1
)

echo [4/4] 合并完整固件 (1.2T)...
esptool.py --chip esp32s3 merge_bin --flash_mode dio --flash_size 16MB --flash_freq 80m ^
    0x0 build\bootloader\bootloader.bin ^
    0x8000 build\partition_table\partition-table.bin ^
    0x9000 build\nvs_1.2T.bin ^
    0x10000 build\esp-miner.bin ^
    0x410000 build\www.bin ^
    0xf10000 build\ota_data_initial.bin ^
    -o release\JingleMiner1.2T_complete.bin

if %errorlevel% neq 0 (
    echo 错误: 固件合并失败
    pause
    exit /b 1
)

echo ✅ JingleMiner 1.2T 完整固件构建成功!
echo.

REM ============ 构建4.8T版本 ============
echo ===============================================
echo 构建 JingleMiner 4.8T 版本  
echo ===============================================

echo [1/4] 设置构建环境 (4.8T)...
set BOARD=NERDQAXEPLUS2
idf.py set-target esp32s3

echo [2/4] 编译固件 (4.8T)...
idf.py build
if %errorlevel% neq 0 (
    echo 错误: 固件编译失败
    pause
    exit /b 1
)

echo [3/4] 生成配置分区 (4.8T)...
python scripts\csv_to_nvs.py release\JingleMiner4.8T.cvs build\nvs_4.8T.bin
if %errorlevel% neq 0 (
    echo 错误: 配置分区生成失败
    pause
    exit /b 1
)

echo [4/4] 合并完整固件 (4.8T)...
esptool.py --chip esp32s3 merge_bin --flash_mode dio --flash_size 16MB --flash_freq 80m ^
    0x0 build\bootloader\bootloader.bin ^
    0x8000 build\partition_table\partition-table.bin ^
    0x9000 build\nvs_4.8T.bin ^
    0x10000 build\esp-miner.bin ^
    0x410000 build\www.bin ^
    0xf10000 build\ota_data_initial.bin ^
    -o release\JingleMiner4.8T_complete.bin

if %errorlevel% neq 0 (
    echo 错误: 固件合并失败
    pause
    exit /b 1
)

echo ✅ JingleMiner 4.8T 完整固件构建成功!
echo.

REM ============ 构建完成 ============
echo ===============================================
echo 🎉 构建全部完成!
echo ===============================================
echo.
echo 生成的完整固件文件:
echo   📦 release\JingleMiner1.2T_complete.bin
echo   📦 release\JingleMiner4.8T_complete.bin
echo.
echo 这些文件包含了:
echo   ✓ 引导加载程序 (bootloader)
echo   ✓ 分区表 (partition table)  
echo   ✓ 预配置的NVS分区 (配置文件)
echo   ✓ 应用程序固件 (esp-miner)
echo   ✓ Web界面 (www)
echo   ✓ OTA数据 (ota_data)
echo.
echo 📋 烧录命令:
echo   esptool.py write_flash 0x0 release\JingleMiner1.2T_complete.bin
echo   esptool.py write_flash 0x0 release\JingleMiner4.8T_complete.bin
echo.
echo 💡 提示: 现在您只需要烧录一个bin文件，无需bitaxetool!
echo ===============================================

REM 显示文件大小信息
echo.
echo 📊 文件信息:
if exist release\JingleMiner1.2T_complete.bin (
    for %%A in (release\JingleMiner1.2T_complete.bin) do echo   1.2T版本: %%~zA 字节
)
if exist release\JingleMiner4.8T_complete.bin (
    for %%A in (release\JingleMiner4.8T_complete.bin) do echo   4.8T版本: %%~zA 字节
)

echo.
pause 