@echo off
echo 生成1.2T版本配置分区...
python scripts\csv_to_nvs.py release\JingleMiner1.2T.cvs build\nvs_1.2T.bin
echo.
echo 合并1.2T版本固件...
esptool.py --chip esp32s3 merge_bin --flash_mode dio --flash_size 16MB --flash_freq 80m 0x0 build\bootloader\bootloader.bin 0x8000 build\partition_table\partition-table.bin 0x9000 build\nvs_1.2T.bin 0x10000 build\esp-miner.bin 0x410000 build\www.bin 0xf10000 build\ota_data_initial.bin -o release\JingleMiner1.2T_complete.bin
echo.
echo 完成!
pause 