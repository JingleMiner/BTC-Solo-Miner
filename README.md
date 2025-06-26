This is a forked version from the NerdAxe miner that was modified for using on the [NerdQAxe+](https://github.com/shufps/qaxe).

需要espidf以及bitaxetool依赖

** 烧录说明 **

1. 配置不同的机型，用BOARD环境变量
    - 1芯片： BOARD=NERDAXEGAMMA
    - 4芯片： BOARD=NERDQAXEPLUS2

2. 配置控制板信息
    idf.py set-target esp32s3

3. 构建bin文件
    idf.py build

4. 合并bin文件
    esptool.py --chip esp32s3 merge_bin --flash_mode dio --flash_size 16MB --flash_freq 80m 0x0 build\bootloader\bootloader.bin 0x8000 build\partition_table\partition-table.bin 0x10000 build\esp-miner.bin 0x410000 build\www.bin 0xf10000 build\ota_data_initial.bin -o nerdaxegamma.bin

5. 烧录命令：
    bitaxetool --config config.cvs --firmware nerdaxegamma.bin

config.cvs为配置文件

** 修改界面 **

修改main/displays/images/themes/NerdQaxePlus2/ 文件夹中，.c文件的生成由image_to_c实现，图片格式为RGB565
