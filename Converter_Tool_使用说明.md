# Converter Tool 使用说明

本文档介绍位于 `main/displays/images/Converter Tool/` 目录下的两个 Python 工具的使用方法。

## 概述

这两个工具用于将 PNG 图像文件转换为 C 语言格式，供 ESP32 项目中的 LVGL 图形库使用。

## 工具介绍

### 1. convert_single.py - 单个图像转换工具

**功能：** 将单个 PNG 图像转换为 C 语言格式的像素数据

**支持格式：** 
- RGB 格式的 PNG 图像
- RGBA 格式的 PNG 图像（包含透明度通道）

**转换格式：** 
- 将像素数据转换为 16 位 RGB565 格式
- 生成符合 LVGL 图形库要求的 C 代码文件

#### 使用方法：

```bash
# 方式一：不指定主题名称
python convert_single.py <输入图像.png> <屏幕名称>

# 方式二：指定主题名称
python convert_single.py <主题名称> <输入图像.png> <屏幕名称>
```

#### 参数说明：
- `主题名称`：可选参数，用于生成变量名的前缀
- `输入图像.png`：要转换的 PNG 图像文件路径
- `屏幕名称`：屏幕标识符，用于生成 C 代码中的变量名

#### 使用示例：
```bash
# 转换单个图像
python convert_single.py ./images/splash.png splashscreen

# 带主题名称的转换
python convert_single.py dark_theme ./images/splash.png splashscreen
```

#### 输出文件：
- 生成文件名格式：`ui_img_<屏幕名称>_png.c`
- 包含像素数据数组和 LVGL 图像描述符结构

### 2. create_themes.py - 批量主题生成工具

**功能：** 批量处理多个主题目录，为每个主题生成完整的图像文件集

**处理的屏幕类型：**
- `initscreen2` - 初始化屏幕
- `miningscreen2` - 挖矿屏幕
- `portalscreen` - 门户屏幕
- `btcscreen` - 比特币屏幕
- `settingsscreen` - 设置屏幕
- `splashscreen2` - 启动屏幕
- `globalStats` - 全局统计屏幕

#### 目录结构要求：

```
main/displays/images/
├── Converter Tool/
│   ├── create_themes.py
│   ├── convert_single.py
│   ├── themes.h.j2 (模板文件)
│   └── themes.c.j2 (模板文件)
└── themes/
    ├── theme1/
    │   └── Raw Images/
    │       ├── initscreen2.png
    │       ├── miningscreen2.png
    │       ├── portalscreen.png
    │       ├── btcscreen.png
    │       ├── settingsscreen.png
    │       ├── splashscreen2.png
    │       └── globalStats.png
    └── theme2/
        └── Raw Images/
            ├── initscreen2.png
            └── ... (其他屏幕图像)
```

#### 使用方法：

```bash
# 在 Converter Tool 目录下运行
python create_themes.py
```

#### 工具执行流程：

1. **扫描主题目录**：自动扫描 `../themes/` 目录下的所有主题文件夹
2. **批量转换图像**：对每个主题的所有屏幕图像调用 `convert_single.py` 进行转换
3. **生成头文件**：使用 Jinja2 模板生成 `themes.h` 头文件
4. **生成源文件**：使用 Jinja2 模板生成 `themes.c` 源文件

#### 输出文件：
- 每个主题目录下生成对应的 `.c` 文件
- 在 `themes/` 目录下生成：
  - `themes.h` - 包含所有主题的声明
  - `themes.c` - 包含所有主题的实现

## 环境要求

### Python 依赖包：
```bash
pip install Pillow jinja2
```

### 系统要求：
- Python 3.6 或更高版本
- PIL/Pillow 图像处理库
- Jinja2 模板引擎

## 注意事项

1. **图像格式**：输入图像必须是 PNG 格式
2. **文件命名**：屏幕图像文件名必须严格按照预定义的名称
3. **目录结构**：必须按照要求的目录结构组织文件
4. **路径问题**：确保在正确的目录下运行脚本
5. **权限问题**：确保脚本有读写文件的权限

## 故障排除

### 常见错误：

1. **文件不存在错误**
   - 检查图像文件路径是否正确
   - 确认文件名拼写无误

2. **模块导入错误**
   - 安装缺失的 Python 包：`pip install Pillow jinja2`

3. **权限错误**
   - 确保对目标目录有写入权限
   - 在 Windows 上可能需要以管理员身份运行

4. **模板文件缺失**
   - 确认 `themes.h.j2` 和 `themes.c.j2` 模板文件存在

## 技术细节

### 图像转换规格：
- **颜色深度**：16 位 RGB565 格式
- **字节序**：大端序（高字节在前）
- **透明度**：支持 Alpha 通道
- **内存对齐**：使用 LVGL 的内存对齐属性

### 生成的 C 代码结构：
```c
// 像素数据数组
const LV_ATTRIBUTE_MEM_ALIGN uint8_t ui_img_<主题>_<屏幕>_png_data[] = {
    // 像素数据...
};

// LVGL 图像描述符
const lv_img_dsc_t ui_img_<主题>_<屏幕>_png = {
    .header.always_zero = 0,
    .header.w = <宽度>,
    .header.h = <高度>,
    .data_size = sizeof(ui_img_<主题>_<屏幕>_png_data),
    .header.cf = <颜色格式>,
    .data = ui_img_<主题>_<屏幕>_png_data
};
```

## 使用流程建议

1. **准备图像文件**：将所有 PNG 图像文件放入对应主题的 `Raw Images` 目录
2. **检查目录结构**：确保目录结构符合要求
3. **运行批量转换**：执行 `create_themes.py` 进行批量处理
4. **验证输出**：检查生成的 C 文件和头文件
5. **集成到项目**：将生成的文件包含到 ESP32 项目中

通过以上步骤，您可以高效地将 PNG 图像转换为适合 ESP32 LVGL 项目使用的 C 格式文件。 