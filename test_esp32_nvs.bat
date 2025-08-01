@echo off
echo 测试ESP32标准NVS生成器...
echo.
echo 生成4.8T版本ESP32 NVS分区...
python scripts\esp32_nvs_generator.py release\JingleMiner4.8T.cvs build\nvs_4.8T_esp32.bin
echo.
echo 生成1.2T版本ESP32 NVS分区...
python scripts\esp32_nvs_generator.py release\JingleMiner1.2T.cvs build\nvs_1.2T_esp32.bin
echo.
echo 测试完成!
pause 