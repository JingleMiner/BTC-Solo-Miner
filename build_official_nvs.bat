@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

echo ===============================================
echo JingleMiner official NVS build script
echo Uses the ESP-IDF nvs_partition_gen.py utility
echo ===============================================

rem Check ESP-IDF environment
echo [Check] Validating ESP-IDF environment...
if "%IDF_PATH%"=="" (
    echo Error: IDF_PATH environment variable is not set.
    echo Please run this script from an ESP-IDF command prompt.
    pause
    exit /b 1
)

echo IDF_PATH: %IDF_PATH%
echo.

rem Verify nvs_partition_gen.py exists
set "NVS_TOOL=%IDF_PATH%\components\nvs_flash\nvs_partition_generator\nvs_partition_gen.py"
if not exist "%NVS_TOOL%" (
    echo Error: nvs_partition_gen.py was not found.
    echo Expected at: %NVS_TOOL%
    pause
    exit /b 1
)

rem Ensure output directories exist
if not exist release mkdir release
if not exist build mkdir build

echo [Check] Environment validation passed.
echo.

rem ============ Build 1.2T bundle (official NVS) ============
echo ===============================================
echo Building JingleMiner 1.2T bundle (official NVS)
echo ===============================================

echo [1/4] Preparing build environment (1.2T)...
set BOARD=NERDAXEGAMMA

echo [2/4] Checking for build\esp-miner.bin...
if not exist "build\esp-miner.bin" (
    echo Warning: build\esp-miner.bin not found. Running idf.py build.
    idf.py set-target esp32s3
    idf.py build
    if %errorlevel% neq 0 (
        echo Error: Firmware build failed.
        pause
        exit /b 1
    )
)

echo [3/4] Generating official NVS partition (1.2T)...
python "%NVS_TOOL%" generate release\JingleMiner1.2T.cvs build\nvs_1.2T_official.bin 0x6000
if %errorlevel% neq 0 (
    echo Error: Failed to generate NVS partition (1.2T).
    pause
    exit /b 1
)

echo [4/4] Merging full firmware image (1.2T)...
esptool.py --chip esp32s3 merge_bin --flash_mode dio --flash_size 16MB --flash_freq 80m 0x0 build\bootloader\bootloader.bin 0x8000 build\partition_table\partition-table.bin 0x9000 build\nvs_1.2T_official.bin 0x10000 build\esp-miner.bin 0x410000 build\www.bin 0xf10000 build\ota_data_initial.bin -o release\BTC_Solo_Lite_1.2T.bin

if %errorlevel% neq 0 (
    echo Error: Firmware merge failed (1.2T).
    echo Hint: Ensure the ESP-IDF environment is configured before running this script.
) else (
    echo Success: JingleMiner 1.2T (official NVS) bundle generated.
)

echo.

rem ============ Build 4.8T bundle (official NVS) ============
echo ===============================================
echo Building JingleMiner 4.8T bundle (official NVS)
echo ===============================================

echo [1/4] Preparing build environment (4.8T)...
set BOARD=NERDQAXEPLUS2

echo [2/4] Checking for build\esp-miner.bin...
if not exist "build\esp-miner.bin" (
    echo Warning: build\esp-miner.bin not found. Running idf.py build.
    idf.py set-target esp32s3
    idf.py build
    if %errorlevel% neq 0 (
        echo Error: Firmware build failed.
        pause
        exit /b 1
    )
)

echo [3/4] Generating official NVS partition (4.8T)...
python "%NVS_TOOL%" generate release\JingleMiner4.8T.cvs build\nvs_4.8T_official.bin 0x6000
if %errorlevel% neq 0 (
    echo Error: Failed to generate NVS partition (4.8T).
    pause
    exit /b 1
)

echo [4/4] Merging full firmware image (4.8T)...
esptool.py --chip esp32s3 merge_bin --flash_mode dio --flash_size 16MB --flash_freq 80m 0x0 build\bootloader\bootloader.bin 0x8000 build\partition_table\partition-table.bin 0x9000 build\nvs_4.8T_official.bin 0x10000 build\esp-miner.bin 0x410000 build\www.bin 0xf10000 build\ota_data_initial.bin -o release\BTC_Solo_Pro_4.8T.bin

if %errorlevel% neq 0 (
    echo Error: Firmware merge failed (4.8T).
    echo Hint: Ensure the ESP-IDF environment is configured before running this script.
) else (
    echo Success: JingleMiner 4.8T (official NVS) bundle generated.
)

echo.

rem ============ Summary ============
echo ===============================================
echo Official NVS build summary
echo ===============================================

echo.

rem Verify output bundles
set "files_ok=1"
if not exist "release\JingleMiner1.2T_Official.bin" (
    echo [Missing] release\JingleMiner1.2T_Official.bin was not created.
    set "files_ok=0"
) else (
    echo [OK] release\JingleMiner1.2T_Official.bin is present.
)

if not exist "release\JingleMiner4.8T_Official.bin" (
    echo [Missing] release\JingleMiner4.8T_Official.bin was not created.
    set "files_ok=0"
) else (
    echo [OK] release\JingleMiner4.8T_Official.bin is present.
)

echo.
if "%files_ok%"=="1" (
    echo All official NVS bundles were generated successfully.
    echo.
    echo Output bundles:
    echo   release\JingleMiner1.2T_Official.bin
    echo   release\JingleMiner4.8T_Official.bin
    echo.
    echo Flash commands:
    echo   esptool.py write_flash 0x0 release\BTC_Solo_Lite_1.2T.bin
    echo   esptool.py write_flash 0x0 release\BTC_Solo_Pro_4.8T.bin
    echo.
    echo Tip: These images were produced with the official ESP-IDF tools to guarantee NVS compatibility.
) else (
    echo One or more files failed to generate. Review the errors above.
    echo Tip: Make sure you are running in an ESP-IDF environment and that the CSV files are valid.
)

echo ===============================================

echo.
echo File size information:
if exist release\JingleMiner1.2T_Official.bin (
    for %%A in (release\JingleMiner1.2T_Official.bin) do echo   1.2T bundle: %%~zA bytes (%%~nxA)
)
if exist release\JingleMiner4.8T_Official.bin (
    for %%A in (release\JingleMiner4.8T_Official.bin) do echo   4.8T bundle: %%~zA bytes (%%~nxA)
)

echo.
echo Build finished at: %date% %time%
pause
