@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

echo ===============================================
echo JingleMiner Official NVS Build Script
echo Using ESP-IDF nvs_partition_gen.py tool
echo ===============================================

REM Check ESP-IDF environment
echo [CHECK] Verifying ESP-IDF environment...
if "%IDF_PATH%"=="" (
    echo Error: IDF_PATH environment variable is not set.
    echo Please run this script from the ESP-IDF command prompt.
    pause
    exit /b 1
)

echo IDF_PATH: %IDF_PATH%
echo.

REM Check ESP-IDF NVS tool
set "NVS_TOOL=%IDF_PATH%\components\nvs_flash\nvs_partition_generator\nvs_partition_gen.py"
if not exist "%NVS_TOOL%" (
    echo Error: ESP-IDF NVS tool not found.
    echo Path: %NVS_TOOL%
    pause
    exit /b 1
)

REM Ensure required directories exist
if not exist release mkdir release
if not exist build mkdir build

echo [CHECK] Environment verification passed.
echo.

REM ============ Build 1.2T Variant (Official NVS) ============
echo ===============================================
echo Building JingleMiner 1.2T (Official NVS)
echo ===============================================

echo [1/4] Setting build context (1.2T)...
set BOARD=NERDAXEGAMMA

echo [3/4] Checking firmware binary presence...
if not exist "build\esp-miner.bin" (
    echo Warning: Firmware binary missing, compiling first.
    echo Building firmware...
    idf.py set-target esp32s3
    idf.py build
    set "cmd_err=!errorlevel!"
    if not "!cmd_err!"=="0" (
        echo Error: Firmware build failed.
        pause
        exit /b 1
    )
)

echo [2/4] Generating official NVS partition (1.2T)...
python "%NVS_TOOL%" generate release\JingleMiner1.2T.cvs build\nvs_1.2T_official.bin 0x6000
set "cmd_err=!errorlevel!"
if not "!cmd_err!"=="0" (
    echo Error: NVS partition generation failed (1.2T).
    pause
    exit /b 1
)

echo [4/4] Merging full firmware image (1.2T Official NVS)...
esptool.py --chip esp32s3 merge_bin --flash_mode dio --flash_size 16MB --flash_freq 80m 0x0 build\bootloader\bootloader.bin 0x8000 build\partition_table\partition-table.bin 0x9000 build\nvs_1.2T_official.bin 0x10000 build\esp-miner.bin 0x410000 build\www.bin 0xf10000 build\ota_data_initial.bin -o release\BTC_Solo_Lite_1.2T.bin

set "cmd_err=!errorlevel!"
if not "!cmd_err!"=="0" (
    echo Error: Firmware merge failed (1.2T).
    echo Hint: Ensure this script runs in an ESP-IDF environment.
) else (
    echo Success: JingleMiner 1.2T (Official NVS) firmware generated.
)

echo.

REM ============ Build 4.8T Variant (Official NVS) ============
echo ===============================================
echo Building JingleMiner 4.8T (Official NVS)
echo ===============================================

echo [1/4] Setting build context (4.8T)...
set BOARD=NERDQAXEPLUS2

echo [3/4] Checking firmware binary presence...
if not exist "build\esp-miner.bin" (
    echo Warning: Firmware binary missing, compiling first.
    echo Building firmware...
    idf.py set-target esp32s3
    idf.py build
    set "cmd_err=!errorlevel!"
    if not "!cmd_err!"=="0" (
        echo Error: Firmware build failed.
        pause
        exit /b 1
    )
)

echo [2/4] Generating official NVS partition (4.8T)...
python "%NVS_TOOL%" generate release\JingleMiner4.8T.cvs build\nvs_4.8T_official.bin 0x6000
set "cmd_err=!errorlevel!"
if not "!cmd_err!"=="0" (
    echo Error: NVS partition generation failed (4.8T).
    pause
    exit /b 1
)

echo [4/4] Merging full firmware image (4.8T Official NVS)...
esptool.py --chip esp32s3 merge_bin --flash_mode dio --flash_size 16MB --flash_freq 80m 0x0 build\bootloader\bootloader.bin 0x8000 build\partition_table\partition-table.bin 0x9000 build\nvs_4.8T_official.bin 0x10000 build\esp-miner.bin 0x410000 build\www.bin 0xf10000 build\ota_data_initial.bin -o release\BTC_Solo_Pro_4.8T.bin

set "cmd_err=!errorlevel!"
if not "!cmd_err!"=="0" (
    echo Error: Firmware merge failed (4.8T).
    echo Hint: Ensure this script runs in an ESP-IDF environment.
) else (
    echo Success: JingleMiner 4.8T (Official NVS) firmware generated.
)

echo.

REM ============ Build Summary ============
echo ===============================================
echo Official NVS build completed.
echo ===============================================
echo.

REM Verify generated files
set "files_ok=1"
if not exist "release\JingleMiner1.2T_Official.bin" (
    echo Warning: release\JingleMiner1.2T_Official.bin not found.
    set "files_ok=0"
) else (
    echo Info: release\JingleMiner1.2T_Official.bin found.
)

if not exist "release\JingleMiner4.8T_Official.bin" (
    echo Warning: release\JingleMiner4.8T_Official.bin not found.
    set "files_ok=0"
) else (
    echo Info: release\JingleMiner4.8T_Official.bin found.
)

echo.
if "%files_ok%"=="1" (
    echo All official NVS firmware images generated successfully.
    echo.
    echo Generated images:
    echo   release\JingleMiner1.2T_Official.bin
    echo   release\JingleMiner4.8T_Official.bin
    echo.
    echo Additional notes:
    echo   Generated with ESP-IDF nvs_partition_gen.py
    echo   Compatible with ESP32 NVS format
    echo   Matches esp_nvs library requirements
    echo   Ensures configuration is readable
    echo.
    echo Flash commands:
    echo   esptool.py write_flash 0x0 release\BTC_Solo_Lite_1.2T.bin
    echo   esptool.py write_flash 0x0 release\BTC_Solo_Pro_4.8T.bin
    echo.
    echo Reminder: This version uses the official ESP-IDF tool for reliable configuration.
) else (
    echo Some files failed to generate. Review the messages above.
    echo Reminder: Run inside the ESP-IDF environment and validate CSV formatting.
)

echo ===============================================

REM Display file size information
echo.
echo File summary:
if exist release\JingleMiner1.2T_Official.bin (
    for %%A in (release\JingleMiner1.2T_Official.bin) do echo   1.2T image: %%~zA bytes (%%~nxA)
)
if exist release\JingleMiner4.8T_Official.bin (
    for %%A in (release\JingleMiner4.8T_Official.bin) do echo   4.8T image: %%~zA bytes (%%~nxA)
)

echo.
echo Build finished at: %date% %time%
pause
