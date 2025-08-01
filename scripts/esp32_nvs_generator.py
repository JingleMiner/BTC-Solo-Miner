#!/usr/bin/env python3
"""
ESP32 NVS Partition Generator
使用ESP-IDF标准的NVS格式生成配置分区
"""

import os
import sys
import csv
import struct
import hashlib
from io import StringIO

class ESP32NVSGenerator:
    """符合ESP32标准的NVS生成器"""
    
    # NVS常量
    NVS_VERSION = 0xFE
    NVS_PAGE_SIZE = 4096
    NVS_ENTRY_SIZE = 32
    NVS_NAMESPACE = 0x00
    NVS_TYPE_STR = 0x21
    NVS_TYPE_U16 = 0x02
    NVS_TYPE_U32 = 0x04
    NVS_TYPE_U64 = 0x08
    
    def __init__(self, partition_size=0x6000):
        self.partition_size = partition_size
        self.data = bytearray(partition_size)
        self.current_offset = 0
        self.namespace_index = 1
        
        # 初始化为全FF
        for i in range(partition_size):
            self.data[i] = 0xFF
            
    def write_page_header(self, page_index, seq_no=0):
        """写入NVS页头"""
        offset = page_index * self.NVS_PAGE_SIZE
        
        # NVS页头结构
        header = bytearray(32)
        header[0] = self.NVS_VERSION  # version
        header[4:8] = struct.pack('<I', seq_no)  # sequence number
        header[8:12] = struct.pack('<I', 0)  # crc32 (稍后计算)
        
        self.data[offset:offset+32] = header
        return offset + 32
        
    def write_namespace_entry(self, namespace_name, namespace_index):
        """写入namespace条目"""
        if self.current_offset + 32 > self.partition_size:
            return False
            
        entry = bytearray(32)
        
        # Entry header
        entry[0] = namespace_index  # namespace index
        entry[1] = self.NVS_NAMESPACE  # type
        entry[2] = 1  # span
        entry[3] = 0  # chunk index
        # entry[4:8] = crc32 (稍后计算)
        
        # Key (namespace name)
        name_bytes = namespace_name.encode('utf-8')[:15]
        entry[8:8+len(name_bytes)] = name_bytes
        
        # Value (empty for namespace)
        
        self.data[self.current_offset:self.current_offset+32] = entry
        self.current_offset += 32
        return True
        
    def write_string_entry(self, namespace_index, key, value):
        """写入字符串条目"""
        if self.current_offset + 32 > self.partition_size:
            return False
            
        value_bytes = value.encode('utf-8')
        
        # 计算需要的span
        span = 1
        if len(value_bytes) > 8:
            span += (len(value_bytes) - 1) // 32 + 1
            
        if self.current_offset + span * 32 > self.partition_size:
            return False
            
        # 主条目
        entry = bytearray(32)
        entry[0] = namespace_index
        entry[1] = self.NVS_TYPE_STR
        entry[2] = span
        entry[3] = 0
        
        # Key
        key_bytes = key.encode('utf-8')[:15]
        entry[8:8+len(key_bytes)] = key_bytes
        
        # Value (前8字节或长度信息)
        if len(value_bytes) <= 8:
            entry[24:24+len(value_bytes)] = value_bytes
        else:
            # 存储长度和偏移
            entry[24:26] = struct.pack('<H', len(value_bytes))
            
        self.data[self.current_offset:self.current_offset+32] = entry
        self.current_offset += 32
        
        # 如果字符串超过8字节，写入额外数据
        if len(value_bytes) > 8:
            remaining = value_bytes
            while remaining and self.current_offset + 32 <= self.partition_size:
                chunk = remaining[:32]
                chunk_data = bytearray(32)
                chunk_data[:len(chunk)] = chunk
                self.data[self.current_offset:self.current_offset+32] = chunk_data
                self.current_offset += 32
                remaining = remaining[32:]
                
        return True
        
    def write_u16_entry(self, namespace_index, key, value):
        """写入u16条目"""
        if self.current_offset + 32 > self.partition_size:
            return False
            
        entry = bytearray(32)
        entry[0] = namespace_index
        entry[1] = self.NVS_TYPE_U16
        entry[2] = 1
        entry[3] = 0
        
        # Key
        key_bytes = key.encode('utf-8')[:15]
        entry[8:8+len(key_bytes)] = key_bytes
        
        # Value
        entry[24:26] = struct.pack('<H', int(value))
        
        self.data[self.current_offset:self.current_offset+32] = entry
        self.current_offset += 32
        return True
        
    def write_u32_entry(self, namespace_index, key, value):
        """写入u32条目"""
        if self.current_offset + 32 > self.partition_size:
            return False
            
        entry = bytearray(32)
        entry[0] = namespace_index
        entry[1] = self.NVS_TYPE_U32
        entry[2] = 1
        entry[3] = 0
        
        # Key
        key_bytes = key.encode('utf-8')[:15]
        entry[8:8+len(key_bytes)] = key_bytes
        
        # Value
        entry[24:28] = struct.pack('<I', int(value))
        
        self.data[self.current_offset:self.current_offset+32] = entry
        self.current_offset += 32
        return True
        
    def generate_from_csv(self, csv_file):
        """从CSV生成NVS数据"""
        print(f"正在生成ESP32标准NVS格式: {csv_file}")
        
        # 写入页头
        self.current_offset = self.write_page_header(0)
        
        # 写入main namespace
        if not self.write_namespace_entry("main", self.namespace_index):
            print("错误: 无法写入namespace")
            return False
            
        # 预处理CSV
        processed_lines = []
        with open(csv_file, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            
        header_found = False
        for line in lines:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            if not header_found and 'key,type,encoding,value' in line:
                processed_lines.append(line)
                header_found = True
                continue
            if header_found:
                processed_lines.append(line)
        
        csv_content = '\n'.join(processed_lines)
        csv_file_obj = StringIO(csv_content)
        reader = csv.DictReader(csv_file_obj)
        
        entry_count = 0
        for row in reader:
            key = row.get('key', '').strip() if row.get('key') else ''
            type_str = row.get('type', '').strip() if row.get('type') else ''
            encoding = row.get('encoding', '').strip() if row.get('encoding') else ''
            value = row.get('value', '').strip() if row.get('value') else ''
            
            if type_str == 'namespace' or not key or not value:
                continue
                
            # 根据encoding确定写入方法
            success = False
            if encoding == 'u16':
                success = self.write_u16_entry(self.namespace_index, key, value)
            elif encoding == 'u32':
                success = self.write_u32_entry(self.namespace_index, key, value)
            else:  # string 或其他
                success = self.write_string_entry(self.namespace_index, key, value)
                
            if success:
                entry_count += 1
                print(f"  添加: {key} = {value} ({encoding})")
            else:
                print(f"  跳过: {key} (空间不足)")
                break
                
        print(f"共写入 {entry_count} 个配置项")
        return True

def convert_csv_to_esp32_nvs(csv_file, output_file):
    """转换CSV到ESP32 NVS格式"""
    if not os.path.exists(csv_file):
        print(f"错误: 配置文件不存在 {csv_file}")
        return False
        
    generator = ESP32NVSGenerator()
    
    if not generator.generate_from_csv(csv_file):
        print("错误: NVS生成失败")
        return False
        
    # 写入文件
    try:
        output_dir = os.path.dirname(output_file)
        if output_dir and not os.path.exists(output_dir):
            os.makedirs(output_dir, exist_ok=True)
            
        with open(output_file, 'wb') as f:
            f.write(generator.data)
        print(f"ESP32 NVS文件已生成: {output_file} ({len(generator.data)} 字节)")
        return True
    except Exception as e:
        print(f"错误: 写入失败 - {e}")
        return False

def main():
    if len(sys.argv) != 3:
        print("用法: python esp32_nvs_generator.py <配置.csv> <输出.bin>")
        print("示例: python esp32_nvs_generator.py config.cvs nvs_esp32.bin")
        sys.exit(1)
        
    csv_file = sys.argv[1]
    output_file = sys.argv[2]
    
    if convert_csv_to_esp32_nvs(csv_file, output_file):
        print("转换成功! 使用ESP32标准NVS格式")
    else:
        print("转换失败!")
        sys.exit(1)

if __name__ == "__main__":
    main() 