#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
权重量化工具 - 将PyTorch模型权重量化为INT8格式

使用方法:
    python quantize_weights.py --input model.pth --output weights.h --model lenet

作者: Tool Group 2
日期: 2026-05-22
"""

import argparse
import struct
import numpy as np
from pathlib import Path
from typing import Dict, List, Tuple, Optional

# 尝试导入PyTorch
try:
    import torch
    import torch.nn as nn
    TORCH_AVAILABLE = True
except ImportError:
    TORCH_AVAILABLE = False
    print("警告: PyTorch未安装，将使用模拟数据进行测试")


class WeightQuantizer:
    """权重量化器"""
    
    def __init__(self, scheme: str = "symmetric"):
        """
        初始化量化器
        
        Args:
            scheme: 量化方案 ("symmetric" 或 "asymmetric")
        """
        self.scheme = scheme
        self.quantized_weights = {}
        self.scales = {}
        self.zero_points = {}
    
    def quantize_symmetric(self, weights: np.ndarray) -> Tuple[np.ndarray, float]:
        """
        对称量化 (Symmetric Quantization)
        
        公式:
            scale = max(abs(w)) / 127
            w_int8 = round(w / scale)
        
        Args:
            weights: 原始权重数组
            
        Returns:
            (量化后的权重, scale)
        """
        max_val = np.max(np.abs(weights))
        if max_val < 1e-8:
            scale = 1.0
        else:
            scale = max_val / 127.0
        
        quantized = np.round(weights / scale).astype(np.int8)
        return quantized, scale
    
    def quantize_asymmetric(self, weights: np.ndarray) -> Tuple[np.ndarray, float, int]:
        """
        非对称量化 (Asymmetric Quantization)
        
        公式:
            scale = (max - min) / 255
            zero_point = round(-min / scale)
            w_uint8 = round(w / scale + zero_point)
        
        Args:
            weights: 原始权重数组
            
        Returns:
            (量化后的权重, scale, zero_point)
        """
        min_val = np.min(weights)
        max_val = np.max(weights)
        
        if max_val - min_val < 1e-8:
            scale = 1.0
            zero_point = 0
        else:
            scale = (max_val - min_val) / 255.0
            zero_point = int(np.round(-min_val / scale))
        
        quantized = np.round(weights / scale + zero_point).astype(np.uint8)
        return quantized, scale, zero_point
    
    def quantize_layer(self, name: str, weights: np.ndarray) -> Dict:
        """
        量化单层权重
        
        Args:
            name: 层名称
            weights: 权重数组
            
        Returns:
            包含量化结果的字典
        """
        if self.scheme == "symmetric":
            quantized, scale = self.quantize_symmetric(weights)
            result = {
                'name': name,
                'weights': quantized,
                'scale': scale,
                'zero_point': 0,
                'shape': weights.shape,
                'dtype': 'int8'
            }
        else:
            quantized, scale, zero_point = self.quantize_asymmetric(weights)
            result = {
                'name': name,
                'weights': quantized,
                'scale': scale,
                'zero_point': zero_point,
                'shape': weights.shape,
                'dtype': 'uint8'
            }
        
        self.quantized_weights[name] = result
        return result
    
    def quantize_model(self, model_dict: Dict[str, np.ndarray]) -> Dict[str, Dict]:
        """
        量化整个模型的权重
        
        Args:
            model_dict: 模型权重字典 {层名: 权重数组}
            
        Returns:
            量化结果字典
        """
        results = {}
        for name, weights in model_dict.items():
            # 只量化权重，不量化偏置 (偏置通常用int32)
            if 'weight' in name.lower():
                results[name] = self.quantize_layer(name, weights)
            elif 'bias' in name.lower():
                # 偏置通常保持int32或float
                results[name] = {
                    'name': name,
                    'weights': weights.astype(np.int32),
                    'scale': 1.0,
                    'zero_point': 0,
                    'shape': weights.shape,
                    'dtype': 'int32'
                }
        return results


def load_pytorch_model(path: str) -> Dict[str, np.ndarray]:
    """
    加载PyTorch模型权重
    
    Args:
        path: 模型文件路径
        
    Returns:
        权重字典
    """
    if not TORCH_AVAILABLE:
        raise RuntimeError("PyTorch未安装，无法加载模型")
    
    state_dict = torch.load(path, map_location='cpu')
    
    # 转换为numpy数组
    weights = {}
    for name, param in state_dict.items():
        if isinstance(param, torch.Tensor):
            weights[name] = param.detach().cpu().numpy()
    
    return weights


def generate_test_weights() -> Dict[str, np.ndarray]:
    """
    生成测试用的模拟权重 (用于没有PyTorch时的测试)
    
    Returns:
        模拟权重字典
    """
    np.random.seed(42)
    return {
        'conv1.weight': np.random.randn(6, 1, 5, 5).astype(np.float32) * 0.1,
        'conv1.bias': np.random.randn(6).astype(np.float32) * 0.1,
        'conv2.weight': np.random.randn(16, 6, 5, 5).astype(np.float32) * 0.1,
        'conv2.bias': np.random.randn(16).astype(np.float32) * 0.1,
        'fc1.weight': np.random.randn(120, 400).astype(np.float32) * 0.1,
        'fc1.bias': np.random.randn(120).astype(np.float32) * 0.1,
        'fc2.weight': np.random.randn(84, 120).astype(np.float32) * 0.1,
        'fc2.bias': np.random.randn(84).astype(np.float32) * 0.1,
        'fc3.weight': np.random.randn(10, 84).astype(np.float32) * 0.1,
        'fc3.bias': np.random.randn(10).astype(np.float32) * 0.1,
    }


def save_as_c_array(results: Dict[str, Dict], output_path: str, model_name: str = "model"):
    """
    将量化结果保存为C数组格式
    
    Args:
        results: 量化结果字典
        output_path: 输出文件路径
        model_name: 模型名称
    """
    with open(output_path, 'w') as f:
        # 写入文件头
        f.write(f"""/******************************************************************************
 * @file    {Path(output_path).name}
 * @brief   {model_name}量化权重数据
 * @note    由quantize_weights.py自动生成，请勿手动修改
 * @date    {np.datetime64('today')}
 ******************************************************************************/

#ifndef {model_name.upper()}_WEIGHTS_H
#define {model_name.upper()}_WEIGHTS_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {{
#endif

""")
        
        # 写入每层权重
        for name, data in results.items():
            var_name = name.replace('.', '_').replace('-', '_')
            weights = data['weights']
            shape = data['shape']
            scale = data['scale']
            zero_point = data.get('zero_point', 0)
            dtype = data['dtype']
            
            # 计算数组大小
            size = 1
            for dim in shape:
                size *= dim
            
            # 写入注释
            f.write(f"""
/******************************************************************************
 * Layer: {name}
 * Shape: {shape}
 * Scale: {scale:.6f}
 * Zero Point: {zero_point}
 * Dtype: {dtype}
 ******************************************************************************/
""")
            
            # 写入数组大小宏
            f.write(f"#define {var_name.upper()}_SIZE {size}\n")
            f.write(f"#define {var_name.upper()}_SCALE {scale:.6f}f\n")
            
            # 写入数组定义
            c_type = 'int8_t' if dtype == 'int8' else 'uint8_t' if dtype == 'uint8' else 'int32_t'
            f.write(f"static const {c_type} {var_name}[{size}] = {{\n    ")
            
            # 写入数据 (每行16个)
            flat_weights = weights.flatten()
            for i, val in enumerate(flat_weights):
                if i > 0:
                    if i % 16 == 0:
                        f.write(",\n    ")
                    else:
                        f.write(", ")
                f.write(f"{int(val):4d}")
            
            f.write("\n};\n")
        
        # 写入文件尾
        f.write(f"""

#ifdef __cplusplus
}}
#endif

#endif /* {model_name.upper()}_WEIGHTS_H */
""")
    
    print(f"权重已保存到: {output_path}")


def main():
    parser = argparse.ArgumentParser(description='权重量化工具')
    parser.add_argument('--input', '-i', type=str, default=None,
                        help='输入模型文件路径 (.pth)')
    parser.add_argument('--output', '-o', type=str, default='weights.h',
                        help='输出C头文件路径')
    parser.add_argument('--model', '-m', type=str, default='model',
                        help='模型名称')
    parser.add_argument('--scheme', '-s', type=str, default='symmetric',
                        choices=['symmetric', 'asymmetric'],
                        help='量化方案')
    parser.add_argument('--test', action='store_true',
                        help='使用测试数据运行')
    
    args = parser.parse_args()
    
    # 加载权重
    if args.test or args.input is None:
        print("使用测试数据...")
        weights = generate_test_weights()
    else:
        print(f"加载模型: {args.input}")
        weights = load_pytorch_model(args.input)
    
    print(f"\n找到 {len(weights)} 个权重张量")
    for name, w in weights.items():
        print(f"  {name}: shape={w.shape}, min={w.min():.4f}, max={w.max():.4f}")
    
    # 量化
    print(f"\n使用 {args.scheme} 量化方案...")
    quantizer = WeightQuantizer(scheme=args.scheme)
    results = quantizer.quantize_model(weights)
    
    # 打印量化结果
    print("\n量化结果:")
    for name, data in results.items():
        print(f"  {name}: scale={data['scale']:.6f}, dtype={data['dtype']}")
    
    # 保存为C数组
    save_as_c_array(results, args.output, args.model)
    
    print("\n量化完成!")


if __name__ == '__main__':
    main()
