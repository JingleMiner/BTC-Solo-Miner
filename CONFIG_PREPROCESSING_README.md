# JingleMiner 配置预处理方案

## 概述

这个方案解决了您提出的需求：**将配置文件的解析和固件合并提前做掉，烧录时只需要一个bin文件**。

## 原理说明

### 传统流程
```
1. 构建固件 → 2. 使用bitaxetool处理配置 → 3. 烧录
   ├─ 固件.bin
   └─ 配置.csv  →  bitaxetool  →  最终固件.bin
```

### 新流程
```
1. 构建固件 + 预处理配置 → 2. 直接烧录
   ├─ 固件.bin
   ├─ 配置.csv  →  csv_to_nvs.py  →  NVS分区.bin
   └─ esptool.py merge_bin  →  完整固件.bin
```

## 文件说明

| 文件 | 用途 |
|------|------|
| `scripts/csv_to_nvs.py` | 将CSV配置文件转换为NVS二进制分区 |
| `build_all_in_one.bat` | 一体化构建脚本（推荐使用） |
| `build_with_config.bat` | 带配置预处理的构建脚本 |

## 使用方法

### 方法一：使用一体化构建脚本（推荐）

```cmd
build_all_in_one.bat
```

这个脚本会：
1. ✅ 自动检查构建环境
2. ✅ 构建1.2T和4.8T两个版本的固件
3. ✅ 自动处理对应的配置文件
4. ✅ 生成包含所有组件的完整bin文件

**输出文件：**
- `release/JingleMiner1.2T_complete.bin` - 1.2T完整固件
- `release/JingleMiner4.8T_complete.bin` - 4.8T完整固件

### 方法二：单独使用配置转换工具

```cmd
python scripts/csv_to_nvs.py config.cvs nvs_config.bin
```

然后手动合并：
```cmd
esptool.py --chip esp32s3 merge_bin --flash_mode dio --flash_size 16MB --flash_freq 80m ^
    0x0 build/bootloader/bootloader.bin ^
    0x8000 build/partition_table/partition-table.bin ^
    0x9000 nvs_config.bin ^
    0x10000 build/esp-miner.bin ^
    0x410000 build/www.bin ^
    0xf10000 build/ota_data_initial.bin ^
    -o complete_firmware.bin
```

## 烧录说明

现在您只需要烧录一个文件：

```cmd
# 烧录1.2T版本
esptool.py write_flash 0x0 release/JingleMiner1.2T_complete.bin

# 烧录4.8T版本  
esptool.py write_flash 0x0 release/JingleMiner4.8T_complete.bin
```

## 完整固件包含的组件

生成的完整bin文件包含：

| 地址 | 组件 | 说明 |
|------|------|------|
| 0x0 | bootloader.bin | 引导加载程序 |
| 0x8000 | partition-table.bin | 分区表 |
| 0x9000 | nvs_config.bin | **预处理的配置分区** |
| 0x10000 | esp-miner.bin | 主应用程序 |
| 0x410000 | www.bin | Web界面 |
| 0xf10000 | ota_data_initial.bin | OTA数据 |

## 优势

✅ **简化烧录流程** - 只需要一个bin文件  
✅ **无需bitaxetool** - 省去了额外的工具依赖  
✅ **批量生产友好** - 可预先生成不同配置的固件  
✅ **错误减少** - 配置在构建时就验证和集成  
✅ **版本管理** - 配置和固件打包在一起，便于管理  

## 配置文件说明

配置文件格式保持不变，仍然是CSV格式：

```csv
key,type,encoding,value
main,namespace,,
hostname,data,string,JingleMiner
wifissid,data,string,YourWiFi
stratumurl,data,string,your.pool.com
...
```

支持的配置项：
- 网络配置：WiFi SSID、密码、主机名
- 挖矿配置：矿池URL、端口、用户名、密码
- 硬件参数：ASIC频率、电压、温度控制
- 系统设置：屏幕、风扇等

## 故障排除

### 问题：Python环境错误
```
错误: Python未安装或不在PATH中
```
**解决方案：** 确保Python已安装并在PATH中

### 问题：ESP-IDF环境未配置
```
错误: esptool.py不可用，请检查ESP-IDF环境
```
**解决方案：** 运行ESP-IDF环境配置脚本

### 问题：配置文件格式错误
**解决方案：** 检查CSV文件格式，确保符合标准

## 注意事项

1. **分区大小限制**：NVS分区大小为24KB (0x6000)，如果配置过多可能超出限制
2. **字符编码**：配置文件请使用UTF-8编码
3. **路径问题**：确保配置文件路径正确
4. **备份**：建议备份原始的build.bat文件

## 技术细节

### NVS分区格式
- 使用简化的键值对存储格式
- Magic Header: "NVSC" (NVS Config)
- 数据结构: [key_len][key][value_len][value]
- 结束标记: key_len = 0

### 地址映射
```
0x0000 - 0x8000:  Bootloader (32KB)
0x8000 - 0x9000:  Partition Table (4KB)  
0x9000 - 0xF000:  NVS Config (24KB) ← 配置数据在这里
0x10000+:         Application & Data
```

这个方案完全实现了您的需求：配置预处理和固件合并都在构建时完成，烧录时只需要一个bin文件！ 