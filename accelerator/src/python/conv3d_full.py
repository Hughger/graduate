import numpy as np
import csv
import os
import scipy.signal as signal
import argparse  # 添加命令行参数解析
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
            writer.writerow([])
    
    print(f"已保存量化后的3D矩阵到 {filename}")
    print(f"矩阵形状: {quantized_matrix.shape}")
    print(f"每个输出通道的行数: {quantized_matrix.shape[1]}")
    print(f"每行的列数: {quantized_matrix.shape[2]}")

def convolve3d_full(feature_map, kernel):
    """
    执行三维卷积运算（支持多输出通道），不旋转卷积核（类似PyTorch行为）
    参数:
        feature_map: 三维特征图 [C, H, W]
        kernel: 四维卷积核 [O, C, KH, KW]
    返回:
        三维输出特征图 [O, H_out, W_out]
    """
    O, C, KH, KW = kernel.shape
    _, H, W = feature_map.shape
    
    # 计算输出尺寸 (full padding)
    H_out = H + KH - 1
    W_out = W + KW - 1
    output = np.zeros((O, H_out, W_out))
    
    # 对每个输出通道进行卷积
    for o in range(O):
        # 对每个输入通道进行卷积并累加
        for c in range(C):
            # 使用scipy的相关函数（不旋转卷积核）
            # mode='valid' 与硬件实现保持一致
            output[o] += signal.correlate(
                feature_map[c], 
                kernel[o, c], 
                mode='full'
            )
    return output

def maxpool3d(input_tensor, pool_size=(2, 2), stride=None):
    """
    执行三维最大池化操作
    参数:
        input_tensor: 三维输入张量 [C, H, W]
        pool_size: 池化窗口大小 (height, width)，默认为(2, 2)
        stride: 步长，默认为None（与pool_size相同）
    返回:
        三维输出张量 [C, H_out, W_out]
    """
    if stride is None:
        stride = pool_size
    
    C, H, W = input_tensor.shape
    pool_h, pool_w = pool_size
    stride_h, stride_w = stride
    
    # 计算输出尺寸
    H_out = (H - pool_h) // stride_h + 1
    W_out = (W - pool_w) // stride_w + 1
    
    output = np.zeros((C, H_out, W_out))
    
    # 对每个通道进行最大池化
    for c in range(C):
        for i in range(H_out):
            for j in range(W_out):
                # 计算池化窗口的起始位置
                start_h = i * stride_h
                start_w = j * stride_w
                end_h = start_h + pool_h
                end_w = start_w + pool_w
                
                # 提取池化窗口并计算最大值
                window = input_tensor[c, start_h:end_h, start_w:end_w]
                output[c, i, j] = np.max(window)
    
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
                # 使用pandas读取，自动处理列数不一致的问题
                df_actual = pd.read_csv(actual_file, header=None, engine='python')
                # 填充缺失值为NaN，然后转换为numpy数组
                actual = df_actual.fillna(0).values
                print(f"使用pandas成功读取，实际结果形状: {actual.shape}")
            except ImportError:
                print("❌ 错误: pandas未安装，无法处理列数不一致的CSV文件")
                return
            except Exception as e2:
                print(f"❌ 错误: 使用pandas读取文件失败: {e2}")
                return
        else:
            print(f"❌ 错误: 读取 {actual_file} 失败: {e}")
            return
    
    try:
        expected = np.loadtxt(expected_file, delimiter=',')
    except Exception as e:
        print(f"❌ 错误: 读取 {expected_file} 失败: {e}")
        return
    
    # 计算需要比较的列数
    compare_cols = colSize * resolutionColIdxTotal
    
    # 裁剪实际结果矩阵（只保留前 compare_cols 列）
    actual_cropped = actual[:, :compare_cols] if actual.ndim == 2 else actual[:compare_cols]
    
    # 裁剪预期结果矩阵（只保留前 compare_cols 列）
    expected_cropped = expected[:, :compare_cols] if expected.ndim == 2 else expected[:compare_cols]
    
    # 确保两个矩阵形状相同
    if actual_cropped.shape != expected_cropped.shape:
        print(f"⚠️ 警告: 裁剪后实际结果形状 {actual_cropped.shape} 与预期结果形状 {expected_cropped.shape} 不匹配")
        
        # 裁剪到最小公共形状
        min_rows = min(actual_cropped.shape[0], expected_cropped.shape[0])
        min_cols = min(actual_cropped.shape[1], expected_cropped.shape[1])
        
        actual_cropped = actual_cropped[:min_rows, :min_cols]
        expected_cropped = expected_cropped[:min_rows, :min_cols]
        
        print(f"进一步裁剪到公共形状: {actual_cropped.shape}")
    
    # 量化为指定位宽后比较
    quantized_actual = np.vectorize(lambda x: quantize(x, bitwidth))(actual_cropped)
    quantized_expected = np.vectorize(lambda x: quantize(x, bitwidth))(expected_cropped)
    
    # 1. 检查是否完全相等
    if np.array_equal(quantized_actual, quantized_expected):
        print("✅ 结果验证通过! (完全匹配)")
    else:
        print("❌ 结果验证失败! (不完全匹配)")
        
        # 2. 计算逐元素差异统计
        diff = quantized_actual - quantized_expected
        abs_diff = np.abs(diff)
        max_diff = np.max(abs_diff)
        mean_diff = np.mean(abs_diff)
        std_diff = np.std(abs_diff)
        
        print(f"最大绝对差异: {max_diff}")
        print(f"平均绝对差异: {mean_diff:.4f}")
        print(f"差异标准差: {std_diff:.4f}")
        
        # 3. 计算相似度指标
        # 3.1 皮尔逊相关系数 (线性关系)
        corr_coef = np.corrcoef(quantized_actual.flatten(), quantized_expected.flatten())[0, 1]
        print(f"皮尔逊相关系数: {corr_coef:.6f}")
        
        # 3.2 余弦相似度 (方向相似性)
        dot_product = np.dot(quantized_actual.flatten(), quantized_expected.flatten())
        norm_actual = np.linalg.norm(quantized_actual.flatten())
        norm_expected = np.linalg.norm(quantized_expected.flatten())
        cosine_sim = dot_product / (norm_actual * norm_expected)
        print(f"余弦相似度: {cosine_sim:.6f}")
        
        # 3.3 结构相似性指数 (SSIM)
        # 由于SSIM需要图像块，我们使用滑动窗口计算
        from skimage.metrics import structural_similarity as ssim
        
        # 确保两个矩阵形状相同
        min_shape = min(quantized_actual.shape, quantized_expected.shape)
        actual_crop = quantized_actual[:min_shape[0], :min_shape[1]]
        expected_crop = quantized_expected[:min_shape[0], :min_shape[1]]
        
        ssim_value = ssim(actual_crop, expected_crop, 
                          data_range=2**(bitwidth)-1, 
                          win_size=min(3, min(min_shape[0], min_shape[1])))
        print(f"结构相似性指数 (SSIM): {ssim_value:.6f}")
        
        # 4. 差异分布直方图
        unique, counts = np.unique(abs_diff, return_counts=True)
        print("\n差异分布直方图:")
        for value, count in zip(unique, counts):
            print(f"差异 {value}: {count} 个元素 ({count/abs_diff.size*100:.2f}%)")
        
        # 5. 保存差异热力图
        try:
            import matplotlib.pyplot as plt
            plt.figure(figsize=(12, 6))
            
            plt.subplot(1, 2, 1)
            plt.imshow(abs_diff, cmap='hot', interpolation='nearest')
            plt.colorbar()
            plt.title('绝对差异热力图')
            
            plt.subplot(1, 2, 2)
            plt.hist(abs_diff.flatten(), bins=range(0, int(max_diff)+2), alpha=0.7)
            plt.title('差异分布直方图')
            plt.xlabel('绝对差异')
            plt.ylabel('元素数量')
            
            diff_plot_path = os.path.join(os.path.dirname(actual_file), 'difference_plot.png')
            plt.savefig(diff_plot_path)
            plt.close()
            print(f"\n差异热力图已保存到: {diff_plot_path}")
        except ImportError:
            print("\n无法生成差异热力图: matplotlib 未安装")

def print_3d_matrix(matrix, name):
    """打印三维矩阵的摘要信息"""
    print(f"\n{name} 形状: {matrix.shape}")
    print(f"前 2 个通道的前 3 行数据:")
    for c in range(min(2, matrix.shape[0])):
        print(f"通道 {c}:")
        for r in range(min(3, matrix.shape[1])):
            print(f"  行 {r}: {matrix[c, r, :min(5, matrix.shape[2])]}...")
    print()

def print_4d_matrix(matrix, name):
    """打印四维矩阵的摘要信息"""
    print(f"\n{name} 形状: {matrix.shape}")
    print(f"前 2 个输出通道的前 2 个输入通道的前 3 行数据:")
    for o in range(min(2, matrix.shape[0])):
        for c in range(min(2, matrix.shape[1])):
            print(f"输出通道 {o}, 输入通道 {c}:")
            for r in range(min(3, matrix.shape[2])):
                print(f"  行 {r}: {matrix[o, c, r, :min(5, matrix.shape[3])]}...")
    print()

def check_csv_consistency(filename):
    """检查CSV文件的列数一致性"""
    try:
        with open(filename, 'r') as f:
            lines = f.readlines()
        
        if not lines:
            print(f"⚠️ 警告: {filename} 是空文件")
            return False
        
        # 检查每行的列数
        col_counts = []
        for i, line in enumerate(lines):
            if line.strip():  # 跳过空行
                cols = line.strip().split(',')
                col_counts.append(len(cols))
        
        if not col_counts:
            print(f"⚠️ 警告: {filename} 没有有效数据行")
            return False
        
        # 检查列数是否一致
        first_col_count = col_counts[0]
        inconsistent_lines = []
        for i, col_count in enumerate(col_counts):
            if col_count != first_col_count:
                inconsistent_lines.append((i+1, col_count, first_col_count))
        
        if inconsistent_lines:
            print(f"⚠️ 警告: {filename} 列数不一致:")
            for line_num, actual_cols, expected_cols in inconsistent_lines:
                print(f"  第 {line_num} 行: {actual_cols} 列 (期望: {expected_cols} 列)")
            return False
        else:
            print(f"✅ {filename} 列数一致: 每行 {first_col_count} 列")
            return True
            
    except Exception as e:
        print(f"❌ 错误: 检查 {filename} 时出错: {e}")
        return False

if __name__ == "__main__":
    # 创建命令行参数解析器
    parser = argparse.ArgumentParser(description='执行3D卷积计算（full模式）')
    parser.add_argument('--bitwidth', '-b', type=int, default=8,
                        help='量化位宽（默认：8位）')
    # 新增：用于计算/校验 cin 的参数（与 generate_test_data 对齐）
    parser.add_argument('--row_size', type=int, default=32,
                        help='单组输入通道数 rowSize（cin = rowSize * cinIdxTotal）')
    parser.add_argument('--col_size', type=int, default=32,
                        help='每半行列数（用于验证裁剪列数）')
    parser.add_argument('--group_size', type=int, default=1,
                        help='组内 Tile 数（用于日志校验，不影响卷积计算）')
    parser.add_argument('--cin_idx_total', type=int, default=1,
                        help='输入通道组倍数 cinIdxTotal（cin = rowSize * cinIdxTotal）')
    # 可选：用于结果验证裁剪的参数（保持原函数 verify_result 的接口习惯）
    parser.add_argument('--resolution_col_idx_total', type=int, default=1,
                        help='卷积核尺寸 k（用于验证裁剪列数）')
    parser.add_argument('--resolution_row_idx_total', type=int, default=1,
                        help='分辨率行索引总数（用于多行卷积计算）')
    # 新增：maxpool相关参数
    parser.add_argument('--enable_maxpool', action='store_true',
                        help='是否启用maxpool计算')
    parser.add_argument('--pool_size', type=int, nargs=2, default=[2, 2],
                        help='maxpool窗口大小 [height, width]（默认：[2, 2]）')
    parser.add_argument('--pool_stride', type=int, nargs=2, default=None,
                        help='maxpool步长 [height, width]（默认：与pool_size相同）')
    
    args = parser.parse_args()
    final_bitwidth = args.bitwidth  # 使用命令行参数设置量化位宽

    # 获取当前脚本所在目录
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # 构建文件路径
    features_path = os.path.join(script_dir, 'features.csv')
    weights_path = os.path.join(script_dir, 'weights.csv')
    expected_path = os.path.join(script_dir, 'expected_results.csv')
    result_path = os.path.join(script_dir, 'actual_results.csv')
    maxpool_path = os.path.join(script_dir, 'maxpool_results.csv')
    
    # 从CSV文件读取权重和特征图
    feature_map = read_3d_matrix_from_csv(features_path, final_bitwidth)
    kernel = read_3d_matrix_from_csv(weights_path, final_bitwidth)
    
    # # 打印读取的特征图和权重矩阵
    # print_3d_matrix(feature_map, "特征图 (feature_map)")
    # print_3d_matrix(kernel, "权重矩阵 (kernel) - 原始3D")
    
    # 基于 rowSize 与 cinIdxTotal 计算/校验 cin，并重塑权重为4D [O, C, KH, KW]
    row_size = args.row_size
    cin_idx_total = args.cin_idx_total
    group_size = args.group_size  # 目前仅用于日志提示
    resolution_row_idx_total = args.resolution_row_idx_total  # 新增：分辨率行索引总数

    cin_expected = row_size * cin_idx_total * group_size
    cin_from_features = feature_map.shape[0]
    if cin_from_features != cin_expected:
        print(f"⚠️ 警告: features 中的通道数 C={cin_from_features} 与期望 cin=rowSize*cinIdxTotal={cin_expected} 不一致，按 features={cin_from_features} 继续。")
        cin_expected = cin_from_features

    # 计算 O，并进行一致性检查
    total_kernels = len(kernel)
    KH, KW = kernel[0].shape[0], kernel[0].shape[1]
    if total_kernels % cin_expected != 0:
        print(f"⚠️ 警告: 权重平面数 total={total_kernels} 不是 cin={cin_expected} 的整数倍，尝试按 features 的 C={cin_from_features} 重新计算。")
        if total_kernels % cin_from_features == 0:
            cin_expected = cin_from_features
        else:
            # 兜底：尽量不崩溃，取最大可整除的 C
            for c_try in (cin_expected, cin_from_features):
                if c_try > 0 and total_kernels % c_try == 0:
                    cin_expected = c_try
                    break
    O = total_kernels // cin_expected if cin_expected > 0 else 0
    if O == 0:
        raise ValueError(f"无法根据权重平面数 {total_kernels} 与 cin {cin_expected} 推导输出通道数 O")

    kernel_4d = kernel.reshape(O, cin_expected, KH, KW)
    
    # # 打印重塑后的权重矩阵
    # print_4d_matrix(kernel_4d, "权重矩阵 (kernel) - 重塑为4D")
    
    # 打印参数信息
    print(f"\n卷积参数:")
    print(f"  row_size: {row_size}")
    print(f"  cin_idx_total: {cin_idx_total}")
    print(f"  resolution_row_idx_total: {resolution_row_idx_total}")
    print(f"  resolution_col_idx_total: {args.resolution_col_idx_total}")
    print(f"  group_size: {group_size}")
    print(f"  cin_expected: {cin_expected}")
    
    # 打印完整的特征图矩阵
    print("\n完整的特征图矩阵:")
    for c in range(feature_map.shape[0]):
        print(f"通道 {c}:")
        for row in feature_map[c]:
            print("  " + ", ".join(map(str, row)))
        print()
    
    # 打印完整的权重矩阵
    print("\n完整的权重矩阵 (4D):")
    for o in range(kernel_4d.shape[0]):
        print(f"输出通道 {o}:")
        for c in range(kernel_4d.shape[1]):
            print(f"  输入通道 {c}:")
            for row in kernel_4d[o, c]:
                print("    " + ", ".join(map(str, row)))
            print()
        print("=" * 50)
    
    # 执行三维卷积
    result = convolve3d_full(feature_map, kernel_4d)
    
    # 保存预期结果（量化后）
    write_quantized_3d_matrix(result, expected_path, final_bitwidth)
    print(f"卷积计算完成! 预期结果已保存到 {expected_path} (量化为{final_bitwidth}位整数)")
    
    # 如果启用maxpool，执行maxpool计算
    if args.enable_maxpool:
        print(f"\n开始执行maxpool计算...")
        print(f"池化窗口大小: {args.pool_size}")
        if args.pool_stride is not None:
            print(f"池化步长: {args.pool_stride}")
        else:
            print(f"池化步长: 与窗口大小相同")
        
        # 对卷积结果执行maxpool
        maxpool_result = maxpool3d(result, 
                                  pool_size=tuple(args.pool_size), 
                                  stride=tuple(args.pool_stride) if args.pool_stride is not None else None)
        
        # 保存maxpool结果（量化后）
        write_quantized_3d_matrix(maxpool_result, e, final_bitwidth)
        print(f"maxpool计算完成! 结果已保存到 {maxpool_path} (量化为{final_bitwidth}位整数)")
        
        # 打印maxpool结果摘要
        print(f"\nmaxpool结果摘要:")
        print(f"输入形状: {result.shape}")
        print(f"输出形状: {maxpool_result.shape}")
        print(f"池化窗口: {args.pool_size}")
        
        # 打印maxpool结果的完整矩阵
        print("\n完整的maxpool结果矩阵:")
        for c in range(maxpool_result.shape[0]):
            print(f"通道 {c}:")
            for row in maxpool_result[c]:
                print("  " + ", ".join(map(str, row)))
            print()
    
    # 检查CSV文件的一致性
    print("\n检查CSV文件一致性:")
    check_csv_consistency(expected_path)
    check_csv_consistency(result_path)
    if args.enable_maxpool:
        check_csv_consistency(maxpool_path)
    
    # 验证结果（使用参数中的 col_size 与 kernel_size）
    verify_result(result_path, expected_path, final_bitwidth, args.col_size, args.resolution_col_idx_total)