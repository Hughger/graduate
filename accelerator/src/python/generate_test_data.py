import os
import random
import argparse  # 添加命令行参数解析
import math

def box_muller_transform(u1, u2):
    """
    Box-Muller变换：将均匀分布转换为正态分布
    """
    z0 = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
    return z0

def generate_normal_random(mean=0.0, std=1.0):
    """
    生成正态分布随机数
    """
    u1 = random.random()
    u2 = random.random()
    z = box_muller_transform(u1, u2)
    return mean + std * z

def generate_cnn_feature_value(distribution='normal', sparsity=0.3):
    """
    生成符合CNN特征图分布的随机值
    特征图特点：
    - 高稀疏性：大量值为0（ReLU激活后）
    - 非零值多为正值，集中在中等范围
    - 范围在0-127之间
    """
    # 首先决定是否为0（稀疏性）
    if random.random() < sparsity:
        return 0
    
    if distribution == 'normal':
        # 使用正态分布，均值=64，标准差=20
        value = generate_normal_random(mean=64.0, std=20.0)
    elif distribution == 'uniform':
        # 使用均匀分布，偏向正值
        value = random.uniform(0, 127)
    elif distribution == 'exponential':
        # 使用指数分布，模拟ReLU激活后的特征
        value = random.expovariate(1.0/50.0)  # 指数分布，均值=50
        value = min(127, int(round(value)))
    elif distribution == 'sparse_normal':
        # 稀疏正态分布：均值=80，标准差=25，更集中在高值区域
        value = generate_normal_random(mean=80.0, std=25.0)
    else:
        # 默认正态分布
        value = generate_normal_random(mean=64.0, std=20.0)
    
    # 截断到0-127范围
    value = max(0, min(127, int(round(value))))
    return value

def generate_cnn_weight_value(distribution='normal', sparsity=0.5):
    """
    生成符合CNN权重分布的随机值
    权重特点：
    - 高稀疏性：大量权重接近0（剪枝后）
    - 非零权重正负值都有，集中在0附近
    - 范围在-128到127之间
    """
    # 首先决定是否为0（稀疏性）
    if random.random() < sparsity:
        return 0
    
    if distribution == 'normal':
        # 使用正态分布，均值=0，标准差=32
        value = generate_normal_random(mean=0.0, std=32.0)
    elif distribution == 'uniform':
        # 使用均匀分布
        value = random.uniform(-128, 127)
    elif distribution == 'laplace':
        # 使用拉普拉斯分布，更符合权重分布
        u = random.random() - 0.5
        value = -32 * math.copysign(1, u) * math.log(1 - 2 * abs(u))
    elif distribution == 'sparse_normal':
        # 稀疏正态分布：均值=0，标准差=20，更集中在0附近
        value = generate_normal_random(mean=0.0, std=20.0)
    else:
        # 默认正态分布
        value = generate_normal_random(mean=0.0, std=32.0)
    
    # 截断到-128到127范围
    value = max(-128, min(127, int(round(value))))
    return value

def generate_features_csv(file_path, group_num, group_size, col_size, row_size, mode, fixed_value=None, resolution_col_idx_total=1, cin_idx_total=1, resolution_row_idx_total=1, feature_distribution='normal', feature_sparsity=0.3):
    """
    生成特征图CSV文件
    参数:
        mode: 'random' - 随机数, 'fixed' - 固定值, 'zigzag_weight' - 按行递增模式, 'zigzag_feature' - zigzag特征图模式
        fixed_value: 固定模式下使用的值
        resolution_col_idx_total: 特征图总列数倍数，实际列数为col_size * resolution_col_idx_total
        cin_idx_total: 输入通道数倍数，实际输入通道数为row_size * cin_idx_total
        resolution_row_idx_total: 特征图总行数倍数，实际行数为group_num * resolution_row_idx_total
    """
    # 计算实际的特征图列数
    actual_col_size = col_size * resolution_col_idx_total
    # 计算实际的输入通道数
    actual_cin_size = row_size * cin_idx_total * group_size
    # 计算实际的特征图行数
    actual_row_size = group_num * resolution_row_idx_total 
    
    with open(file_path, 'w') as f:
        for channel in range(actual_cin_size):  # 输入通道
            for row in range(actual_row_size):  # 特征图高度
                if mode == 'zigzag_weight':
                    # 所有元素固定为1
                    values = ['1' for _ in range(actual_col_size)]
                elif mode == 'zigzag_feature':
                    # zigzag特征图模式：每行从0开始递增到15，下一行全部加1
                    base_value = row % 16  # 每行的基础值
                    values = [str((base_value + col) % 16) for col in range(actual_col_size)]
                elif mode == 'random':
                    # 每行生成actual_col_size个符合CNN特征图分布的随机值
                    values = [str(generate_cnn_feature_value(feature_distribution, feature_sparsity)) for _ in range(actual_col_size)]
                elif mode == 'fixed' and fixed_value is not None:
                    # 每行生成actual_col_size个固定值
                    values = [str(fixed_value) for _ in range(actual_col_size)]
                else:
                    # 默认使用符合CNN特征图分布的随机数
                    values = [str(generate_cnn_feature_value(feature_distribution, feature_sparsity)) for _ in range(actual_col_size)]
                
                f.write(','.join(values) + '\n')
            
            # 通道间用空行分隔（最后一个通道后不加空行）
            if channel < actual_cin_size - 1:
                f.write('\n')

def generate_weights_csv(file_path, cout, group_size, row_size, k, mode, fixed_value=None, cin_idx_total=1, weight_distribution='normal', weight_sparsity=0.5):
    """
    生成权重CSV文件
    参数:
        mode: 'random' - 随机数, 'fixed' - 固定值, 'zigzag_weight' - 按行递增模式, 'zigzag_feature' - -1,1,-1,1循环模式
        fixed_value: 固定模式下使用的值
    """
    # 计算实际的输入通道数
    actual_cin_size = row_size * cin_idx_total * group_size 
    with open(file_path, 'w') as f:
        for output_ch in range(cout):  # 输出通道
            for input_ch in range(actual_cin_size):  # 输入通道
                # 为每个输入通道生成k×k的卷积核
                kernel = [[0] * k for _ in range(k)]
                
                if mode == 'zigzag_weight':
                    # 按行递增模式
                    current_value = 0  # 每个输入通道从0开始
                    for y in range(k):
                        for x in range(k):
                            kernel[y][x] = current_value
                            current_value += 1
                elif mode == 'zigzag_feature':
                    # zigzag_feature权重模式：奇数行1,2,3...，偶数行-1,-2,-3...
                    for y in range(k):
                        for x in range(k):
                            if y % 2 == 0:  # 偶数行（0,2,4...）
                                kernel[y][x] = x + 1  # 1, 2, 3, ...
                            else:  # 奇数行（1,3,5...）
                                kernel[y][x] = -(x + 1)  # -1, -2, -3, ...
                elif mode == 'random':
                    # 生成符合CNN权重分布的随机值
                    for y in range(k):
                        for x in range(k):
                            kernel[y][x] = generate_cnn_weight_value(weight_distribution, weight_sparsity)
                elif mode == 'fixed' and fixed_value is not None:
                    # 生成固定权重值
                    for y in range(k):
                        for x in range(k):
                            kernel[y][x] = fixed_value
                else:
                    # 默认使用符合CNN权重分布的随机数
                    for y in range(k):
                        for x in range(k):
                            kernel[y][x] = generate_cnn_weight_value(weight_distribution, weight_sparsity)
                
                # 写入卷积核
                for y in range(k):
                    values = [str(kernel[y][x]) for x in range(k)]
                    f.write(','.join(values) + '\n')
                
                # 输入通道间用空行分隔（最后一个通道后不加空行）
                if input_ch < actual_cin_size - 1:
                    f.write('\n')
            
            # 输出通道间用两个空行分隔（最后一个通道后不加空行）
            if output_ch < cout:
                f.write('\n\n')

def main():
    # 创建命令行参数解析器
    parser = argparse.ArgumentParser(description='生成测试数据')
    
    # 添加模式选择参数
    parser.add_argument('--mode', type=str, default='random',
                        choices=['random', 'fixed_features', 'fixed_weights', 'fixed_all', 'zigzag_weight', 'zigzag_feature'],
                        help='数据生成模式: random(全随机), fixed_features(特征图固定/权重随机), fixed_weights(特征图随机/权重固定), fixed_all(全固定), zigzag_weight(权重按行递增), zigzag_feature(特征图zigzag/权重-1,1循环)')
    
    # 添加分布选择参数
    parser.add_argument('--feature_distribution', type=str, default='normal',
                        choices=['normal', 'uniform', 'exponential', 'sparse_normal'],
                        help='特征图分布类型: normal(正态分布), uniform(均匀分布), exponential(指数分布), sparse_normal(稀疏正态分布)')
    parser.add_argument('--weight_distribution', type=str, default='normal',
                        choices=['normal', 'uniform', 'laplace', 'sparse_normal'],
                        help='权重分布类型: normal(正态分布), uniform(均匀分布), laplace(拉普拉斯分布), sparse_normal(稀疏正态分布)')
    
    # 添加稀疏性参数
    parser.add_argument('--feature_sparsity', type=float, default=0.3,
                        help='特征图稀疏性比例 (0.0-1.0)，0.3表示30%的值为0')
    parser.add_argument('--weight_sparsity', type=float, default=0.5,
                        help='权重稀疏性比例 (0.0-1.0)，0.5表示50%的值为0')
    
    # 添加固定值参数
    parser.add_argument('--feature_value', type=int, default=1,
                        help='特征图固定模式下使用的值')
    parser.add_argument('--weight_value', type=int, default=1,
                        help='权重固定模式下使用的值')
    
    # 添加其他参数
    parser.add_argument('--group_num', type=int, default=4,
                        help='特征图高度')
    parser.add_argument('--group_size', type=int, default=1,
                        help='Cluster内一组的Tile个数')
    parser.add_argument('--col_size', type=int, default=32,
                        help='特征图宽度')
    parser.add_argument('--row_size', type=int, default=32, 
                        help='输入通道数')
    parser.add_argument('--cout', type=int, default=4,
                        help='输出通道数')
    parser.add_argument('--k', type=int, default=4,
                        help='卷积核尺寸')
    parser.add_argument('--resolution_col_idx_total', type=int, default=1,
                        help='特征图总列数倍数，实际列数为col_size * resolution_col_idx_total')
    parser.add_argument('--cin_idx_total', type=int, default=1,
                        help='输入通道数倍数，实际输入通道数为row_size * cin_idx_total')
    parser.add_argument('--resolution_row_idx_total', type=int, default=1,
                        help='特征图总行数倍数，实际行数为group_num * resolution_row_idx_total')
    
    args = parser.parse_args()
    
    # 设置随机种子以确保可重复性
    random.seed(42)
    
    # 生成文件
    features_path = os.path.join('src', 'python', 'features.csv')
    weights_path = os.path.join('src', 'python', 'weights.csv')
    
    # 根据模式生成数据
    if args.mode == 'zigzag_weight':
        # zigzag_weight模式: 特征图全1, 权重按行递增
        generate_features_csv(features_path, args.group_num, args.group_size, args.col_size, args.row_size, 'zigzag_weight', resolution_col_idx_total=args.resolution_col_idx_total, cin_idx_total=args.cin_idx_total, resolution_row_idx_total=args.resolution_row_idx_total, feature_distribution=args.feature_distribution, feature_sparsity=args.feature_sparsity)
        generate_weights_csv(weights_path, args.cout, args.group_size, args.row_size, args.k, 'zigzag_weight', cin_idx_total=args.cin_idx_total, weight_distribution=args.weight_distribution, weight_sparsity=args.weight_sparsity)
        print(f"生成zigzag_weight模式数据: 特征图全1, 权重按行递增")
        print(f"特征图列数: {args.col_size} * {args.resolution_col_idx_total} = {args.col_size * args.resolution_col_idx_total}")
        print(f"特征图行数: {args.group_num} * {args.resolution_row_idx_total} = {args.group_num * args.resolution_row_idx_total}")
        print(f"特征图输入通道数: {args.row_size} * {args.cin_idx_total} = {args.row_size * args.cin_idx_total}")
    elif args.mode == 'zigzag_feature':
        # zigzag_feature模式: 特征图zigzag分布, 权重-1,1,-1,1循环
        generate_features_csv(features_path, args.group_num, args.group_size, args.col_size, args.row_size, 'zigzag_feature', resolution_col_idx_total=args.resolution_col_idx_total, cin_idx_total=args.cin_idx_total, resolution_row_idx_total=args.resolution_row_idx_total, feature_distribution=args.feature_distribution, feature_sparsity=args.feature_sparsity)
        generate_weights_csv(weights_path, args.cout, args.group_size, args.row_size, args.k, 'zigzag_feature', cin_idx_total=args.cin_idx_total, weight_distribution=args.weight_distribution, weight_sparsity=args.weight_sparsity)
        print(f"生成zigzag_feature模式数据: 特征图zigzag分布, 权重-1,1,-1,1循环")
        print(f"特征图列数: {args.col_size} * {args.resolution_col_idx_total} = {args.col_size * args.resolution_col_idx_total}")
        print(f"特征图行数: {args.group_num} * {args.resolution_row_idx_total} = {args.group_num * args.resolution_row_idx_total}")
        print(f"特征图输入通道数: {args.row_size} * {args.cin_idx_total} = {args.row_size * args.cin_idx_total}")
    else:
        # 根据模式生成特征图
        if args.mode in ['random', 'fixed_weights']:
            # 随机特征图
            generate_features_csv(features_path, args.group_num, args.group_size, args.col_size, args.row_size, 'random', resolution_col_idx_total=args.resolution_col_idx_total, cin_idx_total=args.cin_idx_total, resolution_row_idx_total=args.resolution_row_idx_total, feature_distribution=args.feature_distribution, feature_sparsity=args.feature_sparsity)
            print(f"生成随机特征图文件: {features_path}")
            print(f"特征图高度: {args.group_num} * {args.resolution_row_idx_total} = {args.group_num * args.resolution_row_idx_total}")
            print(f"特征图宽度: {args.col_size} * {args.resolution_col_idx_total} = {args.col_size * args.resolution_col_idx_total}")
            print(f"特征图通道数: {args.row_size} * {args.cin_idx_total} = {args.row_size * args.cin_idx_total}")
        else:
            # 固定特征图
            generate_features_csv(features_path, args.group_num, args.group_size, args.col_size, args.row_size, 'fixed', args.feature_value, resolution_col_idx_total=args.resolution_col_idx_total, cin_idx_total=args.cin_idx_total, resolution_row_idx_total=args.resolution_row_idx_total, feature_distribution=args.feature_distribution, feature_sparsity=args.feature_sparsity)
            print(f"生成固定特征图文件: {features_path} (值={args.feature_value})")
            print(f"特征图高度: {args.group_num} * {args.resolution_row_idx_total} = {args.group_num * args.resolution_row_idx_total}")
            print(f"特征图宽度: {args.col_size} * {args.resolution_col_idx_total} = {args.col_size * args.resolution_col_idx_total}")
            print(f"特征图通道数: {args.row_size} * {args.cin_idx_total} = {args.row_size * args.cin_idx_total}")
        
        # 根据模式生成权重
        if args.mode in ['random', 'fixed_features']:
            # 随机权重
            generate_weights_csv(weights_path, args.cout, args.group_size, args.row_size, args.k, 'random', cin_idx_total=args.cin_idx_total, weight_distribution=args.weight_distribution, weight_sparsity=args.weight_sparsity)
            print(f"生成随机权重文件: {weights_path}")
            print(f"权重输入通道数: {args.row_size} * {args.cin_idx_total} = {args.row_size * args.cin_idx_total}")
            print(f"权重输出通道数: {args.cout}")
            print(f"权重k值: {args.k}")
        else:
            # 固定权重
            generate_weights_csv(weights_path, args.cout, args.group_size, args.row_size, args.k, 'fixed', args.weight_value, cin_idx_total=args.cin_idx_total, weight_distribution=args.weight_distribution, weight_sparsity=args.weight_sparsity)
            print(f"生成固定权重文件: {weights_path} (值={args.weight_value})")
            print(f"权重输入通道数: {args.row_size} * {args.cin_idx_total} = {args.row_size * args.cin_idx_total}")
            print(f"权重输出通道数: {args.cout}")
            print(f"权重k值: {args.k}")

if __name__ == "__main__":
    main() 