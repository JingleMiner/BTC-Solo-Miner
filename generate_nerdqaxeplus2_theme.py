#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
NerdQaxePlus2主题图片转换脚本
自动将Raw Images中的PNG图片转换为LVGL格式的.c文件
"""

import os
import sys
import subprocess
from PIL import Image
import argparse

def convert_png_to_c(theme_name, image_path, screen_name, output_dir):
    """
    将PNG图片转换为LVGL格式的.c文件
    
    Args:
        theme_name: 主题名称 (例如: NerdQaxePlus2)
        image_path: 输入PNG图片路径
        screen_name: 屏幕名称 (例如: btcscreen)
        output_dir: 输出目录
    """
    
    # 检查输入文件是否存在
    if not os.path.isfile(image_path):
        print(f"错误: 文件 '{image_path}' 不存在。")
        return False
    
    # 创建输出目录
    os.makedirs(output_dir, exist_ok=True)
    
    # 生成输出文件名
    output_c_file = os.path.join(output_dir, f"ui_img_{screen_name}_png.c")
    
    try:
        # 打开图片
        image = Image.open(image_path)
        print(f"处理图片: {os.path.basename(image_path)} ({image.width}x{image.height})")
        
        # 检查是否有透明通道
        if image.mode == 'RGBA':
            use_alpha = True
            image = image.convert('RGBA')
        else:
            use_alpha = False
            image = image.convert('RGB')
        
        # 图片尺寸
        width, height = image.size
        
        # 生成变量名
        var_name = f"{theme_name}_{screen_name}"
        
        # 写入.c文件
        with open(output_c_file, 'w', encoding='utf-8') as f:
            # 写入文件头
            f.write('#include "lvgl.h"\n\n')
            f.write('#ifndef LV_ATTRIBUTE_MEM_ALIGN\n')
            f.write('    #define LV_ATTRIBUTE_MEM_ALIGN\n')
            f.write('#endif\n\n')
            
            # 写入图片数据注释
            f.write(f'// IMAGE DATA: {os.path.basename(image_path)}\n')
            f.write(f'const LV_ATTRIBUTE_MEM_ALIGN uint8_t ui_img_{var_name}_png_data[] = {{\n')
            
            # 处理图片像素
            pixel_data = []
            for y in range(height):
                for x in range(width):
                    if use_alpha:
                        r, g, b, a = image.getpixel((x, y))
                    else:
                        r, g, b = image.getpixel((x, y))
                    
                    # 转换为16位565格式
                    r = (r >> 3) & 0x1F    # 红色5位
                    g = (g >> 2) & 0x3F    # 绿色6位  
                    b = (b >> 3) & 0x1F    # 蓝色5位
                    
                    # 合并为16位值
                    rgb565 = (r << 11) | (g << 5) | b
                    
                    # 分解为两个8位值 (高字节和低字节)
                    high_byte = (rgb565 >> 8) & 0xFF
                    low_byte = rgb565 & 0xFF
                    
                    # 添加到像素数据列表
                    pixel_data.append(f'0x{high_byte:02X}')
                    pixel_data.append(f'0x{low_byte:02X}')
                    
                    # 如果使用透明通道，添加alpha字节
                    if use_alpha:
                        pixel_data.append(f'0x{a:02X}')
            
            # 写入像素数据到.c文件
            for i, value in enumerate(pixel_data):
                if i % 16 == 0:
                    f.write('    ')
                f.write(value + ', ')
                if (i + 1) % 16 == 0:
                    f.write('\n')
            
            # 结束数据数组
            f.write('\n};\n\n')
            
            # 确定正确的颜色格式
            color_format = "LV_IMG_CF_TRUE_COLOR_ALPHA" if use_alpha else "LV_IMG_CF_TRUE_COLOR"
            
            # 写入lv_img_dsc_t结构体
            f.write(f'const lv_img_dsc_t ui_img_{var_name}_png = {{\n')
            f.write(f'    .header.always_zero = 0,\n')
            f.write(f'    .header.w = {width},\n')
            f.write(f'    .header.h = {height},\n')
            f.write(f'    .data_size = sizeof(ui_img_{var_name}_png_data),\n')
            f.write(f'    .header.cf = {color_format},\n')
            f.write(f'    .data = ui_img_{var_name}_png_data\n')
            f.write('};\n')
        
        print(f"转换完成！输出保存到: {output_c_file}")
        return True
        
    except Exception as e:
        print(f"转换图片 {image_path} 时发生错误: {e}")
        return False

def update_theme_system():
    """更新主题系统文件"""
    try:
        converter_tool_path = "main/displays/images/Converter Tool/create_themes.py"
        
        if not os.path.exists(converter_tool_path):
            print(f"警告: 主题更新工具 '{converter_tool_path}' 不存在，跳过主题系统更新")
            return False
        
        print("\n正在更新主题系统...")
        result = subprocess.run([sys.executable, converter_tool_path], 
                              capture_output=True, text=True, cwd=os.getcwd())
        
        if result.returncode == 0:
            print("✅ 主题系统更新成功！")
            return True
        else:
            print(f"⚠️  主题系统更新失败: {result.stderr}")
            return False
            
    except Exception as e:
        print(f"更新主题系统时发生错误: {e}")
        return False

def main():
    """主函数"""
    parser = argparse.ArgumentParser(description='NerdQaxePlus2主题图片转换工具')
    parser.add_argument('--raw-dir', default='main/displays/images/themes/NerdQaxePlus2/Raw Images',
                       help='原始图片目录路径')
    parser.add_argument('--output-dir', default='main/displays/images/themes/NerdQaxePlus2', 
                       help='输出目录路径')
    parser.add_argument('--theme-name', default='NerdQaxePlus2',
                       help='主题名称')
    parser.add_argument('--no-update', action='store_true',
                       help='不自动更新主题系统')
    
    args = parser.parse_args()
    
    # 定义所有需要转换的屏幕图片
    screens = [
        "initscreen2",
        "miningscreen2", 
        "portalscreen",
        "btcscreen",
        "settingsscreen",
        "splashscreen2",
        "globalStats"
    ]
    
    print("🎨 NerdQaxePlus2主题图片转换工具")
    print("=" * 60)
    print(f"主题名称: {args.theme_name}")
    print(f"原始图片目录: {args.raw_dir}")
    print(f"输出目录: {args.output_dir}")
    print("-" * 50)
    
    # 检查原始图片目录是否存在
    if not os.path.exists(args.raw_dir):
        print(f"❌ 错误: 原始图片目录 '{args.raw_dir}' 不存在！")
        print("请确保路径正确，或使用--raw-dir参数指定正确的路径")
        return 1
    
    # 检查PIL/Pillow是否可用
    try:
        from PIL import Image
    except ImportError:
        print("❌ 错误: 未安装Pillow库！")
        print("请运行: pip install Pillow")
        return 1
    
    success_count = 0
    total_count = 0
    
    # 转换每个屏幕图片
    for screen in screens:
        image_file = f"{screen}.png"
        image_path = os.path.join(args.raw_dir, image_file)
        
        total_count += 1
        
        if not os.path.exists(image_path):
            print(f"⚠️  警告: 图片文件 '{image_path}' 不存在，跳过...")
            continue
        
        if convert_png_to_c(args.theme_name, image_path, screen, args.output_dir):
            success_count += 1
    
    print("-" * 50)
    print(f"转换完成！成功转换 {success_count}/{total_count} 个图片文件")
    
    if success_count > 0:
        print("✅ 图片转换成功！")
        print(f"\n生成的.c文件已保存到: {args.output_dir}")
        print("\n生成的文件列表:")
        for screen in screens:
            c_file = os.path.join(args.output_dir, f"ui_img_{screen}_png.c")
            if os.path.exists(c_file):
                file_size = os.path.getsize(c_file)
                print(f"  - {c_file} ({file_size/1024:.1f} KB)")
        
        if not args.no_update:
            # 自动更新主题系统
            if update_theme_system():
                print("\n🎉 所有任务完成！NerdQaxePlus2主题已准备就绪！")
            else:
                print("\n⚠️  请手动运行以下命令更新主题系统:")
                print("  python \"main/displays/images/Converter Tool/create_themes.py\"")
        else:
            print("\n请手动运行以下命令更新主题系统:")
            print("  python \"main/displays/images/Converter Tool/create_themes.py\"")
        
    else:
        print("❌ 没有成功转换的图片文件")
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main()) 