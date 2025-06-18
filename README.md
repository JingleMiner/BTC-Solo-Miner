This is a forked version from the NerdAxe miner that was modified for using on the [NerdQAxe+](https://github.com/shufps/qaxe).

需要espidf以及bitaxetool依赖

通过build.bat生成 nerdqaxeplus.bin 并烧录到设备

烧录命令：
bitaxetool --config config.cvs --firmware nerdqaxeplus.bin

config.cvs为配置文件