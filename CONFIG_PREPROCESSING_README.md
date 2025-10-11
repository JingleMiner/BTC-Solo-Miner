# JingleMiner Configuration Preprocessing Workflow

## Overview

This workflow satisfies the requirement to parse the configuration file and merge it into the firmware during the build. Flashing then only needs a single BIN image.

## Workflow Explanation

### Traditional flow
```
1. Build firmware -> 2. Use bitaxetool to process the configuration -> 3. Flash
   ├─ firmware.bin
   └─ config.csv -> bitaxetool -> final_firmware.bin
```

### New flow
```
1. Build firmware + preprocess configuration -> 2. Flash directly
   ├─ firmware.bin
   ├─ config.csv -> csv_to_nvs.py -> nvs_partition.bin
   └─ esptool.py merge_bin -> complete_firmware.bin
```

## File Summary

| File | Purpose |
|------|---------|
| `scripts/csv_to_nvs.py` | Convert the CSV configuration into an NVS binary partition. |
| `build_all_in_one.bat` | All-in-one build script (recommended). |
| `build_with_config.bat` | Build script that performs configuration preprocessing. |

## Usage

### Option 1: All-in-one build script (recommended)

```cmd
build_all_in_one.bat
```

This script will:
1. Verify the build environment automatically.
2. Build both 1.2T and 4.8T firmware variants.
3. Process the matching configuration files.
4. Generate complete BIN images that include every component.

Output files:
- `release/JingleMiner1.2T_complete.bin` - 1.2T complete firmware.
- `release/JingleMiner4.8T_complete.bin` - 4.8T complete firmware.

### Option 2: Use the configuration converter manually

```cmd
python scripts/csv_to_nvs.py config.cvs nvs_config.bin
```

Then merge the image manually:

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

## Flashing

Only one file needs to be flashed:

```cmd
# Flash the 1.2T release
esptool.py write_flash 0x0 release/JingleMiner1.2T_complete.bin

# Flash the 4.8T release
esptool.py write_flash 0x0 release/JingleMiner4.8T_complete.bin
```

## Contents of the Complete Firmware

The merged BIN file contains:

| Address | Component | Description |
|---------|-----------|-------------|
| 0x0 | bootloader.bin | Bootloader |
| 0x8000 | partition-table.bin | Partition table |
| 0x9000 | nvs_config.bin | Preprocessed configuration partition |
| 0x10000 | esp-miner.bin | Main application |
| 0x410000 | www.bin | Web interface |
| 0xf10000 | ota_data_initial.bin | OTA data |

## Benefits

- Simplified flashing: only a single BIN image is required.
- No bitaxetool dependency.
- Production friendly: different configurations can be generated in advance.
- Fewer mistakes: configurations are validated and integrated during the build.
- Better version control: firmware and configuration stay packaged together.

## Configuration File Notes

The configuration file format remains CSV:

```csv
key,type,encoding,value
main,namespace,,
hostname,data,string,JingleMiner
wifissid,data,string,YourWiFi
stratumurl,data,string,your.pool.com
...
```

Supported configuration categories:
- Network settings: Wi-Fi SSID, password, hostname.
- Mining settings: pool URL, port, username, password.
- Hardware parameters: ASIC frequency, voltage, thermal control.
- System settings: display, fan, and similar options.

## Troubleshooting

### Issue: Python environment error
```
Error: Python is not installed or not available in PATH
```
Solution: Install Python and ensure it is added to PATH.

### Issue: ESP-IDF environment is not configured
```
Error: esptool.py not found, please check the ESP-IDF environment
```
Solution: Run the ESP-IDF environment setup script.

### Issue: Configuration file format error
Solution: Validate the CSV format and make sure it follows the specification.

## Notes

1. Partition size limit: the NVS partition is 0x6000 (24 KB); too many entries can exceed the limit.
2. Character encoding: use UTF-8 for the configuration file.
3. Path handling: confirm that all file paths are correct.
4. Backup: keep a backup of the original build scripts.

## Technical Details

### NVS partition format
- Simplified key-value storage layout.
- Magic header: "NVSC" (NVS Config).
- Data structure: [key_len][key][value_len][value].
- End marker: key_len = 0.

### Address map
```
0x0000 - 0x8000:  Bootloader (32 KB)
0x8000 - 0x9000:  Partition table (4 KB)
0x9000 - 0xF000:  NVS config (24 KB)   configuration data lives here
0x10000+:         Application and data
```

This workflow fully implements the requirement: configuration preprocessing and firmware merging run during the build, so flashing needs only a single BIN file.
