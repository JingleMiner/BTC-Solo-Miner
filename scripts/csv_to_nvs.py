#!/usr/bin/env python3
"""
CSV to NVS Binary Converter
兼容ESP-IDF NVS格式的配置文件转换器
"""

import os
import sys
import csv
import struct
import hashlib
import binascii

class SimpleNVSGenerator:
    """简化的NVS生成器，专门用于配置文件"""
    
    def __init__(self, partition_size=0x6000):
        self.partition_size = partition_size
        self.data = bytearray(partition_size)
        self.fill_with_ff()
        
    def fill_with_ff(self):
        """用0xFF填充整个分区"""
        for i in range(self.partition_size):
            self.data[i] = 0xFF
            
    def generate_from_csv(self, csv_file):
        """从CSV文件生成NVS数据"""
        print(f"正在处理配置文件: {csv_file}")
        
        # 创建一个简单的键值对存储格式
        # 这里使用一种简化的方式，直接在分区开头存储配置数据
        offset = 0
        
        # 写入magic header
        magic = b'NVSC'  # NVS Config
        self.data[offset:offset+4] = magic
        offset += 4
        
        # 预处理CSV文件，过滤注释和空行
        processed_lines = []
        with open(csv_file, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            
        header_found = False
        for line in lines:
            line = line.strip()
            # 跳过空行和注释行
            if not line or line.startswith('#'):
                continue
            
            if not header_found and 'key,type,encoding,value' in line:
                processed_lines.append(line)
                header_found = True
                continue
                
            if header_found:
                processed_lines.append(line)
        
        # 创建临时CSV内容
        csv_content = '\n'.join(processed_lines)
        
        # 使用StringIO来处理CSV
        from io import StringIO
        csv_file_obj = StringIO(csv_content)
        
        reader = csv.DictReader(csv_file_obj)
        entry_count = 0
        
        for row in reader:
            # 安全获取字段值
            key = row.get('key', '').strip() if row.get('key') else ''
            type_str = row.get('type', '').strip() if row.get('type') else ''
            encoding = row.get('encoding', '').strip() if row.get('encoding') else ''
            value = row.get('value', '').strip() if row.get('value') else ''
            
            # 跳过namespace和空行
            if type_str == 'namespace' or not key or not value:
                continue
                
            # 简化格式: [key_len(1)] [key] [value_len(2)] [value]
            key_bytes = key.encode('utf-8')
            value_bytes = value.encode('utf-8')
            
            if offset + 1 + len(key_bytes) + 2 + len(value_bytes) >= self.partition_size:
                print(f"警告: 分区空间不足，跳过 {key}")
                break
            
            # 写入key长度和key
            self.data[offset] = len(key_bytes)
            offset += 1
            self.data[offset:offset+len(key_bytes)] = key_bytes
            offset += len(key_bytes)
            
            # 写入value长度和value
            self.data[offset:offset+2] = struct.pack('<H', len(value_bytes))
            offset += 2
            self.data[offset:offset+len(value_bytes)] = value_bytes
            offset += len(value_bytes)
            
            entry_count += 1
            print(f"  添加: {key} = {value}")
        
        # 写入结束标记
        if offset < self.partition_size:
            self.data[offset] = 0  # key_len = 0 表示结束
            
        print(f"共处理 {entry_count} 个配置项")
        return True

def convert_config_to_nvs(csv_file, output_file):
    """将配置CSV转换为NVS二进制文件"""
    if not os.path.exists(csv_file):
        print(f"错误: 找不到配置文件 {csv_file}")
        return False
        
    generator = SimpleNVSGenerator()
    
    if not generator.generate_from_csv(csv_file):
        print("错误: 生成NVS数据失败")
        return False
        
    # 写入输出文件
    try:
        # 确保输出目录存在
        output_dir = os.path.dirname(output_file)
        if output_dir and not os.path.exists(output_dir):
            os.makedirs(output_dir, exist_ok=True)
        
        with open(output_file, 'wb') as f:
            f.write(generator.data)
        print(f"NVS文件已生成: {output_file} ({len(generator.data)} 字节)")
        return True
    except Exception as e:
        print(f"错误: 写入文件失败 - {e}")
        return False

def main():
    if len(sys.argv) != 3:
        print("用法: python csv_to_nvs.py <配置.csv> <输出.bin>")
        print("示例: python csv_to_nvs.py config.cvs nvs_config.bin")
        sys.exit(1)
        
    csv_file = sys.argv[1]
    output_file = sys.argv[2]
    
    if convert_config_to_nvs(csv_file, output_file):
        print("转换成功!")
    else:
        print("转换失败!")
        sys.exit(1)

if __name__ == "__main__":
    main() 