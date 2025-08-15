#!/usr/bin/env python3
"""
NVS Partition Generator for JingleMiner Config
将config.cvs文件转换为NVS二进制分区
"""

import os
import sys
import csv
import struct
from pathlib import Path

# NVS相关常量
NVS_VERSION = 1
NVS_NAMESPACE_INDEX = 0
NVS_TYPE_U8 = 0x01
NVS_TYPE_U16 = 0x02
NVS_TYPE_U32 = 0x04
NVS_TYPE_STR = 0x21
NVS_TYPE_BLOB = 0x42

class NVSPartitionGenerator:
    def __init__(self, partition_size=0x6000):  # 24KB
        self.partition_size = partition_size
        self.data = bytearray(partition_size)
        self.current_offset = 0
        self.page_size = 4096
        
    def write_page_header(self, page_index):
        """写入页头"""
        offset = page_index * self.page_size
        # NVS页头格式: [version(4), seq_no(4), crc(4), reserved(20)]
        header = struct.pack('<III', NVS_VERSION, page_index, 0)  # CRC稍后计算
        header += b'\xFF' * 20  # reserved
        self.data[offset:offset+32] = header
        return offset + 32
        
    def write_entry(self, namespace_idx, entry_type, key, value):
        """写入NVS条目"""
        if self.current_offset + 32 > self.partition_size:
            raise Exception("NVS partition overflow")
            
        # 条目格式: [ns_idx(1), type(1), span(1), chunk_idx(1), crc32(4), key(16), data(8)]
        key_bytes = key.encode('utf-8')[:15]  # 最大15字节
        key_padded = key_bytes + b'\x00' * (16 - len(key_bytes))
        
        if entry_type == NVS_TYPE_STR:
            # 字符串类型
            value_bytes = value.encode('utf-8')
            data_field = struct.pack('<HH', len(value_bytes), 0) + b'\x00' * 4
            span = 1 + (len(value_bytes) + 31) // 32  # 需要的32字节块数
        elif entry_type == NVS_TYPE_U16:
            # 16位整数
            data_field = struct.pack('<H', int(value)) + b'\x00' * 6
            span = 1
        elif entry_type == NVS_TYPE_U32:
            # 32位整数  
            data_field = struct.pack('<I', int(value)) + b'\x00' * 4
            span = 1
        else:
            # 字符串（默认）
            value_bytes = value.encode('utf-8')
            data_field = struct.pack('<HH', len(value_bytes), 0) + b'\x00' * 4
            span = 1 + (len(value_bytes) + 31) // 32
            
        # 写入条目头
        entry_header = struct.pack('<BBBBI', 
                                 namespace_idx, entry_type, span, 0,  # chunk_idx=0
                                 0)  # CRC32稍后计算
        entry_header += key_padded + data_field
        
        self.data[self.current_offset:self.current_offset+32] = entry_header
        self.current_offset += 32
        
        # 如果是字符串且需要额外空间，写入字符串数据
        if entry_type == NVS_TYPE_STR and span > 1:
            value_bytes = value.encode('utf-8')
            padded_size = ((len(value_bytes) + 31) // 32) * 32
            value_padded = value_bytes + b'\x00' * (padded_size - len(value_bytes))
            self.data[self.current_offset:self.current_offset+len(value_padded)] = value_padded
            self.current_offset += len(value_padded)

def convert_csv_to_nvs(csv_file, output_file):
    """将CSV配置文件转换为NVS二进制分区"""
    generator = NVSPartitionGenerator()
    
    # 写入第一页的页头
    generator.current_offset = generator.write_page_header(0)
    
    # 读取CSV文件
    with open(csv_file, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        namespace_idx = 1
        
        for row in reader:
            key = row['key'].strip()
            type_str = row['type'].strip()
            encoding = row['encoding'].strip()
            value = row['value'].strip()
            
            # 跳过命名空间行和空行
            if type_str == 'namespace' or not key:
                continue
                
            # 确定数据类型
            if encoding == 'u16':
                entry_type = NVS_TYPE_U16
            elif encoding == 'u32':
                entry_type = NVS_TYPE_U32
            elif encoding in ['string', '']:
                entry_type = NVS_TYPE_STR
            else:
                entry_type = NVS_TYPE_STR  # 默认为字符串
                
            try:
                generator.write_entry(namespace_idx, entry_type, key, value)
                print(f"Added: {key} = {value} (type: {encoding})")
            except Exception as e:
                print(f"Error adding {key}: {e}")
    
    # 写入到文件
    with open(output_file, 'wb') as f:
        f.write(generator.data)
    
    print(f"NVS partition generated: {output_file}")
    print(f"Size: {len(generator.data)} bytes")

def main():
    if len(sys.argv) != 3:
        print("Usage: python generate_nvs_partition.py <input.csv> <output.bin>")
        sys.exit(1)
        
    csv_file = sys.argv[1]
    output_file = sys.argv[2]
    
    if not os.path.exists(csv_file):
        print(f"Error: {csv_file} not found")
        sys.exit(1)
        
    # 创建输出目录
    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    
    convert_csv_to_nvs(csv_file, output_file)

if __name__ == "__main__":
    main() 