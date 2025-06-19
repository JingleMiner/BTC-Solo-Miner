This is a forked version from the NerdAxe miner that was modified for using on the [NerdQAxe+](https://github.com/shufps/qaxe).

需要espidf以及bitaxetool依赖

** 烧录说明 **

通过build.bat生成 nerdqaxeplus.bin 并烧录到设备

烧录命令：
bitaxetool --config config.cvs --firmware nerdqaxeplus.bin

config.cvs为配置文件

** 修改界面 **

修改main/displays/images/themes/NerdQaxePlus2/ 文件夹中，.c文件的生成由image_to_c实现，图片格式为RGB565
