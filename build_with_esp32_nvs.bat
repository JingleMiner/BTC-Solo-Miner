@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

echo ===============================================
echo JingleMiner ESP32标准NVS构建脚本
echo 使用符合ESP32规范的NVS格式
echo ===============================================

REM 检查必要的工具
echo [检查] 验证构建环境...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: Python未安装或不在PATH中
    pause
    exit /b 1
)

REM 创建必要的目录
if not exist scripts mkdir scripts
if not exist release mkdir release
if not exist build mkdir build

echo [检查] 环境验证通过!
echo.

REM ============ 构建4.8T版本 (使用ESP32标准NVS) ============
echo ===============================================
echo 构建 JingleMiner 4.8T 版本 (ESP32标准NVS)
echo ===============================================

echo [1/4] 设置构建环境 (4.8T)...
set BOARD=NERDQAXEPLUS2

echo [2/4] 生成ESP32标准NVS配置分区 (4.8T)...
python scripts\esp32_nvs_generator.py release\JingleMiner4.8T.cvs build\nvs_4.8T_esp32.bin
if %errorlevel% neq 0 (
    echo 错误: ESP32 NVS配置分区生成失败
    pause
    exit /b 1
)

echo [3/4] 检查固件文件是否存在...
if not exist "build\esp-miner.bin" (
    echo 警告: 固件文件不存在，需要先编译
    echo 正在编译固件...
    idf.py set-target esp32s3
    idf.py build
    if %errorlevel% neq 0 (
        echo 错误: 固件编译失败
        pause
        exit /b 1
    )
)

echo [4/4] 合并完整固件 (4.8T ESP32标准NVS)...
esptool.py --chip esp32s3 merge_bin --flash_mode dio --flash_size 16MB --flash_freq 80m 0x0 build\bootloader\bootloader.bin 0x8000 build\partition_table\partition-table.bin 0x9000 build\nvs_4.8T_esp32.bin 0x10000 build\esp-miner.bin 0x410000 build\www.bin 0xf10000 build\ota_data_initial.bin -o release\JingleMiner4.8T_ESP32NVS.bin

if %errorlevel% neq 0 (
    echo 错误: 固件合并失败 (4.8T)
    echo 提示: 请确保在ESP-IDF环境中运行此脚本
) else (
    echo ✅ JingleMiner 4.8T (ESP32标准NVS) 完整固件构建成功!
)

echo.

REM ============ 构建1.2T版本 (使用ESP32标准NVS) ============  
echo ===============================================
echo 构建 JingleMiner 1.2T 版本 (ESP32标准NVS)
echo ===============================================

echo [1/4] 设置构建环境 (1.2T)...
set BOARD=NERDAXEGAMMA

echo [2/4] 生成ESP32标准NVS配置分区 (1.2T)...
python scripts\esp32_nvs_generator.py release\JingleMiner1.2T.cvs build\nvs_1.2T_esp32.bin
if %errorlevel% neq 0 (
    echo 错误: ESP32 NVS配置分区生成失败
    pause
    exit /b 1
)

echo [3/4] 检查固件文件是否存在...
if not exist "build\esp-miner.bin" (
    echo 警告: 固件文件不存在，需要先编译
    echo 正在编译固件...
    idf.py set-target esp32s3
    idf.py build
    if %errorlevel% neq 0 (
        echo 错误: 固件编译失败
        pause
        exit /b 1
    )
)

echo [4/4] 合并完整固件 (1.2T ESP32标准NVS)...
esptool.py --chip esp32s3 merge_bin --flash_mode dio --flash_size 16MB --flash_freq 80m 0x0 build\bootloader\bootloader.bin 0x8000 build\partition_table\partition-table.bin 0x9000 build\nvs_1.2T_esp32.bin 0x10000 build\esp-miner.bin 0x410000 build\www.bin 0xf10000 build\ota_data_initial.bin -o release\JingleMiner1.2T_ESP32NVS.bin

if %errorlevel% neq 0 (
    echo 错误: 固件合并失败 (1.2T)
    echo 提示: 请确保在ESP-IDF环境中运行此脚本
) else (
    echo ✅ JingleMiner 1.2T (ESP32标准NVS) 完整固件构建成功!
)

echo.

REM ============ 构建完成 ============
echo ===============================================
echo 🎉 ESP32标准NVS构建完成!
echo ===============================================
echo.

REM 验证文件是否生成
set "files_ok=1"
if not exist "release\JingleMiner1.2T_ESP32NVS.bin" (
    echo ❌ release\JingleMiner1.2T_ESP32NVS.bin 未找到
    set "files_ok=0"
) else (
    echo ✅ release\JingleMiner1.2T_ESP32NVS.bin 已生成
)

if not exist "release\JingleMiner4.8T_ESP32NVS.bin" (
    echo ❌ release\JingleMiner4.8T_ESP32NVS.bin 未找到
    set "files_ok=0"
) else (
    echo ✅ release\JingleMiner4.8T_ESP32NVS.bin 已生成
)

echo.
if "%files_ok%"=="1" (
    echo 🎉 所有ESP32标准NVS固件生成成功!
    echo.
    echo 生成的完整固件文件:
    echo   📦 release\JingleMiner1.2T_ESP32NVS.bin
    echo   📦 release\JingleMiner4.8T_ESP32NVS.bin
    echo.
    echo 🔥 重要说明:
    echo   ✓ 使用ESP32官方NVS标准格式
    echo   ✓ "main" namespace匹配代码要求
    echo   ✓ 正确的数据类型映射 (string/u16/u32)
    echo   ✓ 32字节条目对齐
    echo.
    echo 📋 烧录命令:
    echo   esptool.py write_flash 0x0 release\JingleMiner1.2T_ESP32NVS.bin
    echo   esptool.py write_flash 0x0 release\JingleMiner4.8T_ESP32NVS.bin
    echo.
    echo 💡 提示: 这个版本的配置应该能被ESP32正确读取!
) else (
    echo ❌ 部分文件生成失败，请检查错误信息
    echo 💡 提示: esptool.py错误通常是因为不在ESP-IDF环境中
)

echo ===============================================

REM 显示文件大小信息
echo.
echo 📊 文件信息:
if exist release\JingleMiner1.2T_ESP32NVS.bin (
    for %%A in (release\JingleMiner1.2T_ESP32NVS.bin) do echo   1.2T版本: %%~zA 字节 (%%~nxA)
)
if exist release\JingleMiner4.8T_ESP32NVS.bin (
    for %%A in (release\JingleMiner4.8T_ESP32NVS.bin) do echo   4.8T版本: %%~zA 字节 (%%~nxA)
)

echo.
echo 构建完成时间: %date% %time%
pause 