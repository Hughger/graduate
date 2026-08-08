import numpy as np
import csv
import os
import scipy.signal as signal
import argparse
from scipy.ndimage import maximum_filter

# 全局位宽设置
input_bitwidth = 8  # 输入数据位宽
final_bitwidth = 8  # 输出数据位宽

def quantize(value, bitwidth):
    """将浮点数量化为指定位宽的有符号整数"""
    max_val = 2**(bitwidth-1) - 1
    min_val = -2**(bitwidth-1)
    return np.clip(np.round(value), min_val, max_val).astype(int)

def read_3d_matrix_from_csv(filename, bitwidth):
    """从CSV文件读取三维矩阵并量化为指定位宽"""
    channels = []
    current_channel = []
    
    with open(filename, 'r') as f:
        reader = csv.reader(f)
        for row in reader:
            if not row:  # 空行表示通道分隔
                if current_channel:
                    channels.append(np.array(current_channel, dtype=float))
                    current_channel = []
            else:
                current_channel.append(list(map(float, row)))
    
    if current_channel:  # 添加最后一个通道
        channels.append(np.array(current_channel, dtype=float))
    
    # 量化为指定位宽
    return np.vectorize(lambda x: quantize(x, bitwidth))(np.array(channels))

def write_quantized_3d_matrix(matrix, filename, bitwidth):
    """将三维矩阵量化为指定位宽后写入CSV文件"""
    # 先量化整个矩阵
    quantized_matrix = np.vectorize(lambda x: quantize(x, bitwidth))(matrix)
    
    with open(filename, 'w', newline='') as f:
        writer = csv.writer(f)
        for o in range(quantized_matrix.shape[0]):  # 遍历输出通道
            # 写入当前通道的2D结果
            for row in quantized_matrix[o]:
                writer.writerow(row)
            # 通道间添加空行分隔
            if o < quantized_matrix.shape[0] - 1:
                writer.writerow([])

def hardware_maxpool3d(input_tensor, colSize=4):
    """
    硬件兼容的3D最大池化操作
    实现方式：
    1. 对每行进行pairwise max（每两个相邻元素取最大值）
    2. 对相邻两行的pairwise max结果进行比较，取更大的值
    3. 结果放在前半部分，后半部分清零
    
    参数:
        input_tensor: 三维输入张量 [C, H, W]
        colSize: 列大小，用于确定pairwise max的范围
    返回:
        三维输出张量 [C, H_out, W_out]
    """
    C, H, W = input_tensor.shape
    
    # 确保H是偶数，因为需要两行进行比较
    if H % 2 != 0:
        # 如果H是奇数，复制最后一行
        padding = np.expand_dims(input_tensor[:, -1, :], axis=1)
        input_tensor = np.concatenate([input_tensor, padding], axis=1)
        H = input_tensor.shape[1]
    
    # 计算输出尺寸
    H_out = H // 2  # 两行合并成一行
    W_out = W // 2  # 每行内部pairwise max，列数减半
    
    output = np.zeros((C, H_out, W_out))
    
    # 对每个通道进行硬件兼容的maxpool
    for c in range(C):
        for i in range(H_out):
            # 获取两行数据
            row1 = input_tensor[c, 2*i, :]      # 第一行
            row2 = input_tensor[c, 2*i+1, :]    # 第二行
            
            # 对每行进行pairwise max
            pairwise_max1 = np.zeros(W_out)
            pairwise_max2 = np.zeros(W_out)
            
            for j in range(W_out):
                # 每行内部每两个元素取最大值
                pairwise_max1[j] = max(row1[2*j], row1[2*j+1])
                pairwise_max2[j] = max(row2[2*j], row2[2*j+1])
            
            # 两行的pairwise max结果进行比较
            for j in range(W_out):
                output[c, i, j] = max(pairwise_max1[j], pairwise_max2[j])
    
    return output

def verify_result(actual_file, expected_file, bitwidth, colSize, resolutionColIdxTotal):
    """验证实际结果与预期结果是否匹配，只比较前 colSize + (k-1) 列"""
    # 更健壮地读取CSV文件，处理列数不一致的情况
    try:
        actual = np.loadtxt(actual_file, delimiter=',')
    except ValueError as e:
        if "number of columns changed" in str(e):
            print(f"⚠️ 警告: {actual_file} 文件列数不一致，尝试使用pandas读取...")
            try:
                import pandas as pd
                actual_df = pd.read_csv(actual_file, header=None)
                actual = actual_df.values
            except ImportError:
                print("❌ 错误: 需要安装pandas来处理列数不一致的CSV文件")
                return False
        else:
            print(f"❌ 错误: 无法读取 {actual_file}: {e}")
            return False
    
    try:
        expected = np.loadtxt(expected_file, delimiter=',')
    except ValueError as e:
        if "number of columns changed" in str(e):
            print(f"⚠️ 警告: {expected_file} 文件列数不一致，尝试使用pandas读取...")
            try:
                import pandas as pd
                expected_df = pd.read_csv(expected_file, header=None)
                expected = expected_df.values
            except ImportError:
                print("❌ 错误: 需要安装pandas来处理列数不一致的CSV文件")
                return False
        else:
            print(f"❌ 错误: 无法读取 {expected_file}: {e}")
            return False
    
    # 确保两个数组都是2D的
    if actual.ndim == 1:
        actual = actual.reshape(1, -1)
    if expected.ndim == 1:
        expected = expected.reshape(1, -1)
    
    # 计算比较的列数
    compare_cols = colSize + 3  # 假设k=3，所以是colSize + (k-1)
    
    # 截取前compare_cols列进行比较
    actual_compare = actual[:, :min(compare_cols, actual.shape[1])]
    expected_compare = expected[:, :min(compare_cols, expected.shape[1])]
    
    # 确保两个数组形状相同
    min_rows = min(actual_compare.shape[0], expected_compare.shape[0])
    min_cols = min(actual_compare.shape[1], expected_compare.shape[1])
    
    actual_compare = actual_compare[:min_rows, :min_cols]
    expected_compare = expected_compare[:min_rows, :min_cols]
    
    # 比较结果
    if np.array_equal(actual_compare, expected_compare):
        print(f"✅ 验证通过: {actual_file} 与 {expected_file} 匹配")
        return True
    else:
        print(f"❌ 验证失败: {actual_file} 与 {expected_file} 不匹配")
        print(f"实际结果形状: {actual_compare.shape}")
        print(f"预期结果形状: {expected_compare.shape}")
        
        # 显示差异
        diff_mask = actual_compare != expected_compare
        if np.any(diff_mask):
            print("差异位置:")
            diff_indices = np.where(diff_mask)
            for i, j in zip(diff_indices[0], diff_indices[1]):
                print(f"  位置 ({i}, {j}): 实际={actual_compare[i, j]}, 预期={expected_compare[i, j]}")
        
        return False

def main():
    parser = argparse.ArgumentParser(description='硬件兼容的3D卷积和maxpool计算')
    parser.add_argument('--input', type=str, default='features.csv',
                        help='输入特征图CSV文件路径')
    parser.add_argument('--weights', type=str, default='weights.csv',
                        help='权重CSV文件路径')
    parser.add_argument('--output', type=str, default='expected_results.csv',
                        help='输出结果CSV文件路径')
    parser.add_argument('--maxpool_output', type=str, default='maxpool_results.csv',
                        help='maxpool结果CSV文件路径')
    parser.add_argument('--kernel_size', type=int, default=3,
                        help='卷积核大小')
    parser.add_argument('--stride', type=int, default=1,
                        help='卷积步长')
    parser.add_argument('--padding', type=int, default=0,
                        help='填充大小')
    parser.add_argument('--pool_size', type=int, nargs=2, default=[2, 2],
                        help='maxpool窗口大小 [height, width]（默认：[2, 2]）')
    parser.add_argument('--pool_stride', type=int, nargs=2, default=None,
                        help='maxpool步长 [height, width]（默认：与pool_size相同）')
    parser.add_argument('--colSize', type=int, default=4,
                        help='列大小，用于硬件兼容的maxpool')
    parser.add_argument('--verify', action='store_true',
                        help='验证结果')
    
    args = parser.parse_args()
    
    # 读取输入数据
    print("读取输入数据...")
    input_data = read_3d_matrix_from_csv(args.input, input_bitwidth)
    print(f"输入数据形状: {input_data.shape}")
    
    # 读取权重数据
    print("读取权重数据...")
    weights = read_3d_matrix_from_csv(args.weights, input_bitwidth)
    print(f"权重数据形状: {weights.shape}")
    
    # 执行卷积
    print("执行3D卷积...")
    result = signal.convolve(input_data, weights, mode='valid')
    print(f"卷积结果形状: {result.shape}")
    
    # 保存卷积结果
    write_quantized_3d_matrix(result, args.output, final_bitwidth)
    print(f"卷积计算完成! 结果已保存到 {args.output} (量化为{final_bitwidth}位整数)")
    
    # 执行硬件兼容的maxpool
    print("执行硬件兼容的maxpool...")
    print(f"池化窗口大小: {args.pool_size}")
    if args.pool_stride is not None:
        print(f"池化步长: {args.pool_stride}")
    else:
        print(f"池化步长: 与窗口大小相同")
    
    # 对卷积结果执行硬件兼容的maxpool
    maxpool_result = hardware_maxpool3d(result, colSize=args.colSize)
    
    # 保存maxpool结果（量化后）
    write_quantized_3d_matrix(maxpool_result, args.maxpool_output, final_bitwidth)
    print(f"硬件兼容maxpool计算完成! 结果已保存到 {args.maxpool_output} (量化为{final_bitwidth}位整数)")
    
    # 打印maxpool结果摘要
    print(f"\n硬件兼容maxpool结果摘要:")
    print(f"输出形状: {maxpool_result.shape}")
    print(f"池化窗口: {args.pool_size}")
    print(f"数据范围: [{np.min(maxpool_result)}, {np.max(maxpool_result)}]")
    
    # 验证结果
    if args.verify:
        print("\n验证结果...")
        verify_result(args.maxpool_output, args.output, final_bitwidth, args.colSize, 1)

if __name__ == "__main__":
    main()
