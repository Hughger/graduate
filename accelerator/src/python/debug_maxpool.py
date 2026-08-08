import numpy as np
import csv
from conv3d_full import read_3d_matrix_from_csv, maxpool3d, quantize

def debug_maxpool():
    """调试maxpool实现"""
    
    # 读取输入数据
    print("=== 读取输入数据 ===")
    input_data = read_3d_matrix_from_csv('features.csv', 8)
    print(f"输入数据形状: {input_data.shape}")
    print(f"输入数据内容:")
    for c in range(input_data.shape[0]):
        print(f"通道 {c}:")
        print(input_data[c])
        print()
    
    # 读取权重数据
    print("=== 读取权重数据 ===")
    weights = read_3d_matrix_from_csv('weights.csv', 8)
    print(f"权重数据形状: {weights.shape}")
    print(f"权重数据内容:")
    for c in range(weights.shape[0]):
        print(f"通道 {c}:")
        print(weights[c])
        print()
    
    # 执行卷积
    print("=== 执行卷积 ===")
    import scipy.signal as signal
    result = signal.convolve(input_data, weights, mode='valid')
    print(f"卷积结果形状: {result.shape}")
    print(f"卷积结果内容:")
    for c in range(result.shape[0]):
        print(f"通道 {c}:")
        print(result[c])
        print()
    
    # 执行maxpool
    print("=== 执行maxpool ===")
    maxpool_result = maxpool3d(result, pool_size=(2, 2), stride=None)
    print(f"maxpool结果形状: {maxpool_result.shape}")
    print(f"maxpool结果内容:")
    for c in range(maxpool_result.shape[0]):
        print(f"通道 {c}:")
        print(maxpool_result[c])
        print()
    
    # 手动验证第一个2x2窗口
    print("=== 手动验证第一个2x2窗口 ===")
    if result.shape[0] > 0 and result.shape[1] >= 2 and result.shape[2] >= 2:
        print("第一个通道的前2x2窗口:")
        window = result[0, 0:2, 0:2]
        print(window)
        print(f"手动计算的最大值: {np.max(window)}")
        print(f"maxpool3d的结果: {maxpool_result[0, 0, 0]}")
        print(f"是否匹配: {np.max(window) == maxpool_result[0, 0, 0]}")
    
    # 检查所有2x2窗口
    print("=== 检查所有2x2窗口 ===")
    for c in range(result.shape[0]):
        print(f"通道 {c}:")
        for i in range(maxpool_result.shape[1]):
            for j in range(maxpool_result.shape[2]):
                # 计算池化窗口的起始位置
                start_h = i * 2
                start_w = j * 2
                end_h = start_h + 2
                end_w = start_w + 2
                
                # 提取池化窗口
                window = result[c, start_h:end_h, start_w:end_w]
                manual_max = np.max(window)
                maxpool_value = maxpool_result[c, i, j]
                
                print(f"  位置 ({i}, {j}): 窗口={window.flatten()}, 手动max={manual_max}, maxpool3d={maxpool_value}, 匹配={manual_max == maxpool_value}")

if __name__ == "__main__":
    debug_maxpool()
