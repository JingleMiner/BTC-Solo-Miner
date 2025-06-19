# NerdQaxePlus2 主题图片转换工具

这个工具可以自动将 `NerdQaxePlus2/Raw Images` 目录中的PNG图片转换为LVGL格式的.c文件，用于图形界面显示。

## 功能说明

- 🎨 自动转换PNG图片为LVGL C代码格式
- 📦 支持RGB和RGBA（带透明通道）格式
- 🔄 自动更新主题系统文件
- 📊 显示转换进度和文件大小信息
- ✅ 完整的错误处理和状态报告

## 环境要求

- Python 3.6+
- Pillow 库 (PIL)

### 安装依赖

```bash
pip install -r requirements.txt
```

或者手动安装：

```bash
pip install Pillow
```

## 使用方法

### 基本使用

在项目根目录运行：

```bash
python generate_nerdqaxeplus2_theme.py
```

这将自动：
1. 查找 `main/displays/images/themes/NerdQaxePlus2/Raw Images/` 中的PNG图片
2. 转换为.c文件保存到 `main/displays/images/themes/NerdQaxePlus2/`
3. 自动更新主题系统文件

### 高级选项

```bash
# 指定自定义路径
python generate_nerdqaxeplus2_theme.py \
    --raw-dir "custom/raw/images/path" \
    --output-dir "custom/output/path" \
    --theme-name "CustomTheme"

# 仅转换，不更新主题系统
python generate_nerdqaxeplus2_theme.py --no-update
```

### 参数说明

- `--raw-dir`: 原始PNG图片目录路径（默认：`main/displays/images/themes/NerdQaxePlus2/Raw Images`）
- `--output-dir`: 输出.c文件目录路径（默认：`main/displays/images/themes/NerdQaxePlus2`）
- `--theme-name`: 主题名称，用于生成变量名（默认：`NerdQaxePlus2`）
- `--no-update`: 跳过自动更新主题系统

## 支持的图片文件

工具会查找并转换以下7个界面图片：

1. `initscreen2.png` - 初始化界面
2. `miningscreen2.png` - 挖矿界面
3. `portalscreen.png` - 门户界面
4. `btcscreen.png` - BTC界面
5. `settingsscreen.png` - 设置界面
6. `splashscreen2.png` - 启动界面
7. `globalStats.png` - 全局统计界面

## 输出文件格式

每个PNG图片会生成一个对应的.c文件，包含：

- 图片数据数组：`ui_img_NerdQaxePlus2_[屏幕名]_png_data[]`
- LVGL图像描述符：`ui_img_NerdQaxePlus2_[屏幕名]_png`

## 文件结构

```
project_root/
├── generate_nerdqaxeplus2_theme.py  # 主转换脚本
├── requirements.txt                 # 依赖文件
├── README_NerdQaxePlus2.md         # 本说明文件
└── main/displays/images/themes/NerdQaxePlus2/
    ├── Raw Images/                 # 原始PNG图片
    │   ├── initscreen2.png
    │   ├── miningscreen2.png
    │   ├── portalscreen.png
    │   ├── btcscreen.png
    │   ├── settingsscreen.png
    │   ├── splashscreen2.png
    │   └── globalStats.png
    └── [生成的.c文件]
        ├── ui_img_initscreen2_png.c
        ├── ui_img_miningscreen2_png.c
        ├── ui_img_portalscreen_png.c
        ├── ui_img_btcscreen_png.c
        ├── ui_img_settingsscreen_png.c
        ├── ui_img_splashscreen2_png.c
        └── ui_img_globalStats_png.c
```

## 技术细节

### 图片转换过程

1. **读取PNG图片**：使用PIL/Pillow库加载图片
2. **颜色格式转换**：转换为RGB565格式（16位色彩）
3. **透明度处理**：自动检测并保留Alpha通道
4. **数据编码**：将像素数据转换为C语言数组格式
5. **生成描述符**：创建LVGL图像描述符结构

### 颜色格式

- **RGB565**：16位色彩格式，红色5位，绿色6位，蓝色5位
- **支持透明度**：RGBA图片会保留Alpha通道信息
- **内存对齐**：使用`LV_ATTRIBUTE_MEM_ALIGN`优化内存访问

## 故障排除

### 常见问题

1. **找不到图片文件**
   - 检查Raw Images目录是否存在
   - 确认PNG文件名是否正确

2. **Pillow安装问题**
   ```bash
   pip install --upgrade Pillow
   ```

3. **权限问题**
   - 确保有写入输出目录的权限
   - Windows用户可能需要以管理员身份运行

4. **路径问题**
   - 使用绝对路径或确认相对路径正确
   - Windows用户注意路径分隔符

### 调试信息

运行时会显示详细的处理信息：
- 图片尺寸和格式
- 转换进度
- 生成的文件大小
- 错误信息和警告

## 集成到构建系统

建议将此工具集成到项目的构建流程中：

```bash
# 在构建前自动更新主题
python generate_nerdqaxeplus2_theme.py
make build
```

## 版本兼容性

- 兼容LVGL 8.x及以上版本
- 支持ESP32等嵌入式平台
- 生成的代码符合C99标准

---

*此工具基于项目现有的转换系统，并针对NerdQaxePlus2主题进行了优化。* 