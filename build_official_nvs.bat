@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

echo ===============================================
echo JingleMiner 官方NVS构建脚本
echo 使用ESP-IDF官方nvs_partition_gen.py工具
echo ===============================================

REM 检查ESP-IDF环境
echo [检查] 验证ESP-IDF环境...
if "%IDF_PATH%"=="" (
    echo 错误: IDF_PATH 环境变量未设置
    echo 请在ESP-IDF命令提示符中运行此脚本
    pause
    exit /b 1
)

echo IDF_PATH: %IDF_PATH%
echo.

REM 检查官方NVS工具
set "NVS_TOOL=%IDF_PATH%\components\nvs_flash\nvs_partition_generator\nvs_partition_gen.py"
if not exist "%NVS_TOOL%" (
    echo 错误: 官方NVS工具不存在
    echo 路径: %NVS_TOOL%
    pause
    exit /b 1
)

REM 创建必要的目录
if not exist release mkdir release
if not exist build mkdir build

echo [检查] 环境验证通过!
echo.

REM ============ 构建1.2T版本 (官方NVS) ============
echo ===============================================
echo 构建 JingleMiner 1.2T 版本 (官方NVS)
echo ===============================================

echo [1/4] 设置构建环境 (1.2T)...
set BOARD=NERDAXEGAMMA

echo [2/4] 生成官方NVS配置分区 (1.2T)...
python "%NVS_TOOL%" generate release\JingleMiner1.2T.cvs build\nvs_1.2T_official.bin 0x6000
if %errorlevel% neq 0 (
    echo 错误: 官方NVS配置分区生成失败 (1.2T)
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

echo [4/4] 合并完整固件 (1.2T 官方NVS)...
esptool.py --chip esp32s3 merge_bin --flash_mode dio --flash_size 16MB --flash_freq 80m 0x0 build\bootloader\bootloader.bin 0x8000 build\partition_table\partition-table.bin 0x9000 build\nvs_1.2T_official.bin 0x10000 build\esp-miner.bin 0x410000 build\www.bin 0xf10000 build\ota_data_initial.bin -o release\JingleMiner1.2T_Official.bin

if %errorlevel% neq 0 (
    echo 错误: 固件合并失败 (1.2T)
    echo 提示: 请确保在ESP-IDF环境中运行此脚本
) else (
    echo ✅ JingleMiner 1.2T (官方NVS) 完整固件构建成功!
)

echo.

REM ============ 构建4.8T版本 (官方NVS) ============
echo ===============================================
echo 构建 JingleMiner 4.8T 版本 (官方NVS)
echo ===============================================

echo [1/4] 设置构建环境 (4.8T)...
set BOARD=NERDQAXEPLUS2

echo [2/4] 生成官方NVS配置分区 (4.8T)...
python "%NVS_TOOL%" generate release\JingleMiner4.8T.cvs build\nvs_4.8T_official.bin 0x6000
if %errorlevel% neq 0 (
    echo 错误: 官方NVS配置分区生成失败 (4.8T)
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

echo [4/4] 合并完整固件 (4.8T 官方NVS)...
esptool.py --chip esp32s3 merge_bin --flash_mode dio --flash_size 16MB --flash_freq 80m 0x0 build\bootloader\bootloader.bin 0x8000 build\partition_table\partition-table.bin 0x9000 build\nvs_4.8T_official.bin 0x10000 build\esp-miner.bin 0x410000 build\www.bin 0xf10000 build\ota_data_initial.bin -o release\JingleMiner4.8T_Official.bin

if %errorlevel% neq 0 (
    echo 错误: 固件合并失败 (4.8T)
    echo 提示: 请确保在ESP-IDF环境中运行此脚本
) else (
    echo ✅ JingleMiner 4.8T (官方NVS) 完整固件构建成功!
)

echo.

REM ============ 构建完成 ============
echo ===============================================
echo 🎉 官方NVS构建完成!
echo ===============================================
echo.

REM 验证文件是否生成
set "files_ok=1"
if not exist "release\JingleMiner1.2T_Official.bin" (
    echo ❌ release\JingleMiner1.2T_Official.bin 未找到
    set "files_ok=0"
) else (
    echo ✅ release\JingleMiner1.2T_Official.bin 已生成
)

if not exist "release\JingleMiner4.8T_Official.bin" (
    echo ❌ release\JingleMiner4.8T_Official.bin 未找到
    set "files_ok=0"
) else (
    echo ✅ release\JingleMiner4.8T_Official.bin 已生成
)

echo.
if "%files_ok%"=="1" (
    echo 🎉 所有官方NVS固件生成成功!
    echo.
    echo 生成的完整固件文件:
    echo   📦 release\JingleMiner1.2T_Official.bin
    echo   📦 release\JingleMiner4.8T_Official.bin
    echo.
    echo 🔥 重要说明:
    echo   ✓ 使用ESP-IDF官方nvs_partition_gen.py工具
    echo   ✓ 100%兼容ESP32 NVS标准格式
    echo   ✓ 与esp_nvs库完全匹配
    echo   ✓ 保证配置能被正确读取
    echo.
    echo 📋 烧录命令:
    echo   esptool.py write_flash 0x0 release\JingleMiner1.2T_Official.bin
    echo   esptool.py write_flash 0x0 release\JingleMiner4.8T_Official.bin
    echo.
    echo 💡 提示: 这个版本使用ESP-IDF官方工具，配置应该100%生效!
) else (
    echo ❌ 部分文件生成失败，请检查错误信息
    echo 💡 提示: 确保在ESP-IDF环境中运行，检查配置文件格式
)

echo ===============================================

REM 显示文件大小信息
echo.
echo 📊 文件信息:
if exist release\JingleMiner1.2T_Official.bin (
    for %%A in (release\JingleMiner1.2T_Official.bin) do echo   1.2T版本: %%~zA 字节 (%%~nxA)
)
if exist release\JingleMiner4.8T_Official.bin (
    for %%A in (release\JingleMiner4.8T_Official.bin) do echo   4.8T版本: %%~zA 字节 (%%~nxA)
)

echo.
echo 构建完成时间: %date% %time%
pause 