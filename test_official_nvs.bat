@echo off
echo 使用ESP-IDF官方NVS工具生成配置分区...
echo.

echo 检查ESP-IDF环境...
if "%IDF_PATH%"=="" (
    echo 错误: IDF_PATH 环境变量未设置，请在ESP-IDF命令提示符中运行
    pause
    exit /b 1
)

echo IDF_PATH: %IDF_PATH%
echo.

echo 生成1.2T版本官方NVS分区...
python "%IDF_PATH%\components\nvs_flash\nvs_partition_generator\nvs_partition_gen.py" generate release\JingleMiner1.2T.cvs build\nvs_1.2T_official.bin 0x6000
if %errorlevel% neq 0 (
    echo 错误: 官方NVS生成失败 (1.2T)
) else (
    echo ✅ 1.2T 官方NVS生成成功
)

echo.
echo 生成4.8T版本官方NVS分区...
python "%IDF_PATH%\components\nvs_flash\nvs_partition_generator\nvs_partition_gen.py" generate release\JingleMiner4.8T.cvs build\nvs_4.8T_official.bin 0x6000
if %errorlevel% neq 0 (
    echo 错误: 官方NVS生成失败 (4.8T)
) else (
    echo ✅ 4.8T 官方NVS生成成功
)

echo.
echo 检查生成的文件...
if exist build\nvs_1.2T_official.bin (
    echo ✅ build\nvs_1.2T_official.bin 已生成
    for %%A in (build\nvs_1.2T_official.bin) do echo    大小: %%~zA 字节
) else (
    echo ❌ build\nvs_1.2T_official.bin 未找到
)

if exist build\nvs_4.8T_official.bin (
    echo ✅ build\nvs_4.8T_official.bin 已生成
    for %%A in (build\nvs_4.8T_official.bin) do echo    大小: %%~zA 字节
) else (
    echo ❌ build\nvs_4.8T_official.bin 未找到
)

echo.
echo 测试完成!
pause 