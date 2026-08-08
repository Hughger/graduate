#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
图像预处理工具 - 将图像转换为加速器输入格式

使用方法:
    python image_preprocess.py --input image.png --output input_data.h --size 28

作者: Tool Group 2
日期: 2026-05-22
"""

import argparse
import numpy as np
from pathlib import Path
from typing import Tuple, Optional, Union

# 尝试导入PIL
try:
    from PIL import Image
    PIL_AVAILABLE = True
except ImportError:
    PIL_AVAILABLE = False
    print("警告: Pillow未安装，将使用模拟数据")


class ImagePreprocessor:
    """图像预处理器"""
    
    def __init__(self, target_size: Tuple[int, int] = (28, 28),
                 normalize: bool = True,
                 quantize: bool = True,
                 grayscale: bool = True):
        """
        初始化预处理器
        
        Args:
            target_size: 目标尺寸 (高, 宽)
            normalize: 是否归一化到[0, 1]
            quantize: 是否量化为INT8
            grayscale: 是否转换为灰度图
        """
        self.target_size = target_size
        self.normalize = normalize
        self.quantize = quantize
        self.grayscale = grayscale
    
    def load_image(self, path: str) -> np.ndarray:
        """
        加载图像
        
        Args:
            path: 图像文件路径
            
        Returns:
            图像数组 (H, W, C) 或 (H, W)
        """
        if not PIL_AVAILABLE:
            raise RuntimeError("Pillow未安装，无法加载图像")
        
        img = Image.open(path)
        
        if self.grayscale:
            img = img.convert('L')  # 灰度
        else:
            img = img.convert('RGB')  # RGB
        
        return np.array(img)
    
    def resize(self, image: np.ndarray) -> np.ndarray:
        """
        调整图像尺寸
        
        Args:
            image: 输入图像
            
        Returns:
            调整后的图像
        """
        if not PIL_AVAILABLE:
            # 简单的最近邻插值
            from scipy.ndimage import zoom
            h, w = image.shape[:2]
            th, tw = self.target_size
            zoom_h = th / h
            zoom_w = tw / w
            
            if len(image.shape) == 3:
                return zoom(image, (zoom_h, zoom_w, 1), order=1)
            else:
                return zoom(image, (zoom_h, zoom_w), order=1)
        
        # 使用PIL进行高质量resize
        if len(image.shape) == 3:
            mode = 'RGB'
        else:
            mode = 'L'
        
        img = Image.fromarray(image.astype(np.uint8), mode=mode)
        img = img.resize((self.target_size[1], self.target_size[0]), Image.BILINEAR)
        return np.array(img)
    
    def normalize_image(self, image: np.ndarray) -> Tuple[np.ndarray, float]:
        """
        归一化图像
        
        Args:
            image: 输入图像 (0-255)
            
        Returns:
            (归一化后的图像, scale)
        """
        if self.normalize:
            # 归一化到[0, 1]
            normalized = image.astype(np.float32) / 255.0
            scale = 1.0 / 255.0
        else:
            normalized = image.astype(np.float32)
            scale = 1.0
        
        return normalized, scale
    
    def quantize_image(self, image: np.ndarray, scale: float) -> Tuple[np.ndarray, float]:
        """
        量化图像到INT8
        
        Args:
            image: 归一化后的图像 [0, 1]
            scale: 归一化scale
            
        Returns:
            (量化后的图像, 量化scale)
        """
        if not self.quantize:
            return image, scale
        
        # 对称量化到INT8
        # 输入范围 [0, 1] -> [0, 127]
        quantized = np.round(image * 127).astype(np.int8)
        quant_scale = scale * 127
        
        return quantized, quant_scale
    
    def preprocess(self, image: Union[str, np.ndarray]) -> Dict:
        """
        完整的预处理流程
        
        Args:
            image: 图像路径或数组
            
        Returns:
            预处理结果字典
        """
        # 加载图像
        if isinstance(image, str):
            img = self.load_image(image)
        else:
            img = image
        
        original_shape = img.shape
        
        # Resize
        img_resized = self.resize(img)
        
        # 归一化
        img_normalized, norm_scale = self.normalize_image(img_resized)
        
        # 量化
        img_quantized, quant_scale = self.quantize_image(img_normalized, norm_scale)
        
        # 转换为CHW格式 (通道优先)
        if len(img_quantized.shape) == 3:
            img_chw = np.transpose(img_quantized, (2, 0, 1))  # HWC -> CHW
        else:
            img_chw = img_quantized[np.newaxis, :, :]  # HW -> 1HW
        
        return {
            'original_shape': original_shape,
            'resized_shape': img_resized.shape,
            'final_shape': img_chw.shape,
            'data': img_chw,
            'scale': quant_scale,
            'zero_point': 0,
            'dtype': 'int8'
        }


def save_as_c_array(result: Dict, output_path: str, var_name: str = "input_image"):
    """
    保存为C数组格式
    
    Args:
        result: 预处理结果
        output_path: 输出文件路径
        var_name: 变量名
    """
    data = result['data']
    scale = result['scale']
    shape = result['final_shape']
    
    # 计算总大小
    size = 1
    for dim in shape:
        size *= dim
    
    with open(output_path, 'w') as f:
        # 文件头
        f.write(f"""/******************************************************************************
 * @file    {Path(output_path).name}
 * @brief   预处理后的输入图像数据
 * @note    由image_preprocess.py自动生成
 * @date    {np.datetime64('today')}
 ******************************************************************************/

#ifndef INPUT_DATA_H
#define INPUT_DATA_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {{
#endif

/******************************************************************************
 * 输入图像信息
 ******************************************************************************/
#define INPUT_BATCH_SIZE    1
#define INPUT_CHANNEL       {shape[0]}
#define INPUT_HEIGHT        {shape[1]}
#define INPUT_WIDTH         {shape[2]}
#define INPUT_TOTAL_SIZE    {size}
#define INPUT_SCALE         {scale:.8f}f

/******************************************************************************
 * 输入图像数据 (CHW格式)
 ******************************************************************************/
static const int8_t {var_name}[{size}] = {{
    """)
        
        # 写入数据
        flat_data = data.flatten()
        for i, val in enumerate(flat_data):
            if i > 0:
                if i % 16 == 0:
                    f.write(",\n    ")
                else:
                    f.write(", ")
            f.write(f"{int(val):4d}")
        
        f.write(f"""
}};

#ifdef __cplusplus
}}
#endif

#endif /* INPUT_DATA_H */
""")
    
    print(f"输入数据已保存到: {output_path}")


def generate_test_image(size: Tuple[int, int] = (28, 28), 
                        pattern: str = 'random') -> np.ndarray:
    """
    生成测试图像
    
    Args:
        size: 图像尺寸 (高, 宽)
        pattern: 图案类型 ('random', 'gradient', 'checkerboard')
        
    Returns:
        测试图像数组
    """
    h, w = size
    
    if pattern == 'random':
        return np.random.randint(0, 256, (h, w), dtype=np.uint8)
    
    elif pattern == 'gradient':
        x = np.linspace(0, 255, w)
        y = np.linspace(0, 255, h)
        X, Y = np.meshgrid(x, y)
        return ((X + Y) / 2).astype(np.uint8)
    
    elif pattern == 'checkerboard':
        checker = np.zeros((h, w), dtype=np.uint8)
        block_size = 4
        for i in range(0, h, block_size * 2):
            for j in range(0, w, block_size * 2):
                checker[i:i+block_size, j:j+block_size] = 255
                checker[i+block_size:i+2*block_size, j+block_size:j+2*block_size] = 255
        return checker
    
    else:
        return np.ones((h, w), dtype=np.uint8) * 128


def main():
    parser = argparse.ArgumentParser(description='图像预处理工具')
    parser.add_argument('--input', '-i', type=str, default=None,
                        help='输入图像路径')
    parser.add_argument('--output', '-o', type=str, default='input_data.h',
                        help='输出C头文件路径')
    parser.add_argument('--size', '-s', type=int, default=28,
                        help='目标尺寸 (正方形)')
    parser.add_argument('--height', type=int, default=None,
                        help='目标高度')
    parser.add_argument('--width', type=int, default=None,
                        help='目标宽度')
    parser.add_argument('--rgb', action='store_true',
                        help='保持RGB格式 (默认灰度)')
    parser.add_argument('--no-quantize', action='store_true',
                        help='不进行量化 (保持float)')
    parser.add_argument('--test', action='store_true',
                        help='生成测试图像')
    parser.add_argument('--pattern', type=str, default='random',
                        choices=['random', 'gradient', 'checkerboard'],
                        help='测试图像图案')
    
    args = parser.parse_args()
    
    # 确定目标尺寸
    if args.height is not None and args.width is not None:
        target_size = (args.height, args.width)
    else:
        target_size = (args.size, args.size)
    
    # 创建预处理器
    preprocessor = ImagePreprocessor(
        target_size=target_size,
        grayscale=not args.rgb,
        quantize=not args.no_quantize
    )
    
    # 获取输入图像
    if args.test or args.input is None:
        print(f"生成测试图像 (pattern={args.pattern})...")
        image = generate_test_image(target_size, args.pattern)
    else:
        print(f"加载图像: {args.input}")
        image = args.input
    
    # 预处理
    print(f"预处理图像 -> {target_size}...")
    result = preprocessor.preprocess(image)
    
    # 打印信息
    print(f"\n预处理结果:")
    print(f"  原始尺寸: {result['original_shape']}")
    print(f"  调整后尺寸: {result['resized_shape']}")
    print(f"  最终尺寸 (CHW): {result['final_shape']}")
    print(f"  数据范围: [{result['data'].min()}, {result['data'].max()}]")
    print(f"  Scale: {result['scale']:.8f}")
    print(f"  数据类型: {result['dtype']}")
    
    # 保存
    save_as_c_array(result, args.output)
    
    print("\n预处理完成!")


if __name__ == '__main__':
    main()
