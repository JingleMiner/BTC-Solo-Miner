# Jingle Miner BTC Solo Miner

| Supported Targets | ESP32-S3              |
| ----------------- | --------------------- |
| Required Platform | >= ESP-IDF v5.3.X       |
| ----------------- | --------------------- |

Jingle Miner BTC Solo Miner is a fork of the NerdAxe miner tailored for the [NerdQAxe+](https://github.com/shufps/qaxe) control board.

Credits to the devs:
- BitAxe devs on OSMU: @skot/ESP-Miner, @ben and @jhonny
- NerdAxe dev @BitMaker

## Prerequisites

Before you build or flash locally, make sure the following tooling is installed (Docker users can skip to the section further below):

- ESP-IDF v5.1 or later (repository tested with `espressif/idf:release-v5.5`)
- Python 3.10+ plus project dependencies via `pip install -r requirements.txt`
- `bitaxetool` (`pip install bitaxetool` so the CLI is on PATH)
- `esptool.py` (ships with ESP-IDF)
- Git, CMake, Ninja and a supported compiler (bundled with ESP-IDF)
- Optional: Node.js 20.x if you intend to rebuild the Angular-based web UI

**Tip**: On Windows launch the official *ESP-IDF PowerShell* so environment variables are preset. On Linux/macOS run `source $IDF_PATH/export.sh` before executing ESP-IDF commands.

## How to flash/update firmware

Project repository: https://github.com/JingleMiner/BTC-Solo-Miner

Latest releases: https://github.com/JingleMiner/BTC-Solo-Miner/releases

### Recommended Method: The Webflasher

The [Webflasher](https://jingleminer.com/jingle-miner-web-flasher/) (a modified fork of the excellent [Bitaxe Webflasher](https://github.com/bitaxeorg/bitaxe-web-flasher) by [Wantclue](https://github.com/WantClue)) is the easiest method for updating all Jingle Miner Solo Miner variants.

It pulls the latest releases directly from this repository. Use Chrome/Edge or another browser with Web Serial support, connect the board in bootloader mode, pick the matching device, and flash.

### Windows Batch: build_official_nvs.bat

Run `build_official_nvs.bat` from an ESP-IDF PowerShell (or command prompt with the environment exported) for a one-command build and flash bundle. The script:
- verifies your ESP-IDF installation and the official `nvs_partition_gen.py`
- builds the firmware for the 1.2T and 4.8T boards if `build\esp-miner.bin` is missing
- generates NVS partitions from `release\JingleMiner1.2T.cvs` and `release\JingleMiner4.8T.cvs`
- merges complete images into `release\BTC_Solo_Lite_1.2T.bin` and `release\BTC_Solo_Pro_4.8T.bin`

After it finishes, flash the generated bundle with `esptool.py write_flash 0x0 release\BTC_Solo_Lite_1.2T.bin` (or the 4.8T image) or point `bitaxetool` at the same binaries.

### Manual Methods

#### Clone repository and prepare config

```bash
# clone repository
git clone https://github.com/JingleMiner/BTC-Solo-Miner.git

# change into the cloned repository
cd BTC-Solo-Miner

# copy the example config
cp config.cvs.example config.cvs
```

`config.cvs` is the runtime configuration (Wi-Fi, Stratum URL/credentials, default difficulty, etc.). Tweak it to match your deployment before flashing.

To regenerate an NVS partition from the CSV file (optional but recommended when shipping devices):

```bash
python $IDF_PATH/components/nvs_flash/nvs_partition_generator/nvs_partition_gen.py generate \
    config.cvs build/nvs.bin 0x6000
```

#### Bitaxetool

After preparing `config.cvs`, you can flash a release binary and config via the CLI utility. Put the controller into bootloader mode (press BOOT while toggling RESET) and run:

```bash
bitaxetool --config ./config.cvs --firmware esp-miner-factory-NERDQAXEPLUS-v1.0.10.bin -p COM5
```

Adjust the firmware path and serial port (`-p`) to your setup. Add `--nvs build/nvs.bin` if you generated a custom NVS image.

#### Manual flashing with esptool.py

If you prefer working directly with `esptool.py`, either flash a merged image: 

```bash
esptool.py --chip esp32s3 --port COM5 --baud 921600 write_flash 0x0 bundle.bin
```

Or flash the partitions one by one: 

```bash
esptool.py --chip esp32s3 write_flash \
    0x0      build/bootloader/bootloader.bin \
    0x8000   build/partition_table/partition-table.bin \
    0x9000   build/nvs.bin \
    0x10000  build/esp-miner.bin \
    0x410000 build/www.bin \
    0xF10000 build/ota_data_initial.bin
```

## How to build firmware

### ESP-IDF local workflow

Commands below assume Windows PowerShell with ESP-IDF sourced. Replace backslashes with forward slashes and use `export` on Linux/macOS.

1. **Enter the workspace**
   ```powershell
   cd F:\BTC-Solo-Miner
   ```

2. **Select the board profile** (controls pinout, voltage, fan defaults, etc.):
   - Single ASIC (1.2T): `set BOARD=NERDAXEGAMMA`
   - Quad ASIC (4.8T): `set BOARD=NERDQAXEPLUS2`

3. **Configure the ESP-IDF target**
   ```powershell
   idf.py set-target esp32s3
   # Optional: idf.py menuconfig   # adjust serial port, logging, Wi-Fi defaults, etc.
   ```

4. **Install Python requirements** (first build only)
   ```powershell
   pip install -r requirements.txt
   ```

5. **Build the firmware**
   ```powershell
   idf.py build
   ```
   Key outputs appear under `build/`: `bootloader.bin`, `partition-table.bin`, `esp-miner.bin`, `www.bin`, `ota_data_initial.bin`.

6. **Merge binaries (optional but convenient)**
   ```powershell
   esptool.py --chip esp32s3 merge_bin \
       --flash_mode dio --flash_size 16MB --flash_freq 80m \
       0x0      build\bootloader\bootloader.bin \
       0x8000   build\partition_table\partition-table.bin \
       0x9000   build\nvs.bin \
       0x10000  build\esp-miner.bin \
       0x410000 build\www.bin \
       0xF10000 build\ota_data_initial.bin \
       -o release\btc_solo_miner.bin
   ```
   Skip the `0x9000 build\nvs.bin` pair if you are not bundling a custom NVS image.

### Managing NVS configuration

- `config.cvs`: active runtime configuration.
- `config.cvs.example`: documented template.
- `main/Kconfig.projbuild` ? compile-time defaults; useful when experimenting via `idf.py menuconfig`.

Always double-check `stratumurl`, `stratumuser`, Wi-Fi SSID/password, and difficulty values prior to provisioning hardware.

### Using Docker

Docker containers allow you to use the toolchain without installing ESP-IDF or Node locally.

#### 0. TL;DR - build `esp-miner.bin` and `www.bin`
```bash
# only once
cd docker
./build_docker.sh
cd ..

export BOARD="NERDQAXEPLUS2"
./docker/idf.sh set-target esp32-s3

# after each source modification
./docker/idf.sh build
```

Build artifacts (`esp-miner.bin`, `www.bin`) will appear in `build/`.

#### 1. Build the container
```bash
cd docker
./build_docker.sh
```

#### 2. Start an interactive ESP-IDF shell
```bash
./docker/idf-shell.sh
```

Inside the shell you have access to `idf.py`, `bitaxetool`, `esptool.py`, and `nvs_partition_gen.py`. The project is mounted at `/home/builder/project`.

#### 3. Compile & flash from the shell

```bash
# inside docker shell
export BOARD="NERDQAXEPLUS2"
idf.py set-target esp32s3
idf.py build

# optional: merge partitions
./merge_bin.sh nerdqaxe+.bin

bitaxetool --config config.cvs --firmware esp-miner-factory-nerdqaxe+.bin -p /dev/ttyACM0
```

For full manual control (generate config NVS, merge with firmware, flash using `esptool`), follow the detailed steps from the original instructions located in `docker/` scripts (`merge_bin_with_config.sh`, etc.).

### Without Docker

If you do not wish to use Docker, simply install bitaxetool via pip: 

```bash
pip install --upgrade bitaxetool
```

## Updating UI assets

Display assets reside in `main/displays/images/themes/`. The `.c` files are generated from RGB565 images using the `image_to_c` tooling. To update the UI:
1. Replace or edit the images in the respective theme folder.
2. Run `scripts/image_to_c.py` (or the matching batch script) to regenerate the `.c` sources.
3. Rebuild and flash the firmware.

## Grafana Monitoring

<img src="https://github.com/user-attachments/assets/3c485428-5e48-4761-9717-bd88579a747d" width="600px">

The Jingle Miner firmware supports InfluxDB telemetry. A ready-to-go monitoring stack with Grafana dashboards is available under [`monitoring/`](https://github.com/JingleMiner/BTC-Solo-Miner/tree/main/monitoring).

## Troubleshooting

- `idf.py fullclean && idf.py build` clears stale artifacts when switching branches or board profiles.
- Ensure the `BOARD` environment variable matches the attached hashboard, otherwise voltage/fan defaults will be wrong.
- If Wi-Fi or pool connections fail, revisit `config.cvs` for SSID, password, pool URL, and worker typos.
- During flashing issues, try a lower baud rate or hold BOOT while toggling RESET to force download mode.
- `idf.py -p COM5 monitor` (adjust the port) opens the serial console for live diagnostics.

For further customization refer to the ESP-IDF programming guide and the upstream NerdAxe documentation.
