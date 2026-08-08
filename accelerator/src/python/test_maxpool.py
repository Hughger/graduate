import numpy as np
from conv3d_full import maxpool3d

def test_maxpool():
    """测试maxpool3d函数"""
    
    # 创建一个简单的测试数据
    # 2个通道，4x4的数据
    test_data = np.array([
        # 通道0
        [[1, 2, 3, 4],
         [5, 6, 7, 8],
         [9, 10, 11, 12],
         [13, 14, 15, 16]],
        
        # 通道1  
        [[17, 18, 19, 20],
         [21, 22, 23, 24],
         [25, 26, 27, 28],
         [29, 30, 31, 32]]
    ])
    
    print("输入数据:")
    print(f"形状: {test_data.shape}")
    for c in range(test_data.shape[0]):
        print(f"通道 {c}:")
        print(test_data[c])
        print()
    
    # 执行2x2 maxpool
    result = maxpool3d(test_data, pool_size=(2, 2), stride=None)
    
    print("maxpool结果:")
    print(f"形状: {result.shape}")
    for c in range(result.shape[0]):
        print(f"通道 {c}:")
        print(result[c])
        print()
    
    # 手动验证
    print("手动验证:")
    for c in range(test_data.shape[0]):
        print(f"通道 {c}:")
        # 第一个2x2窗口: [0:2, 0:2]
        window1 = test_data[c, 0:2, 0:2]
        max1 = np.max(window1)
        print(f"  窗口1 [0:2, 0:2]: {window1.flatten()} -> max = {max1}")
        
        # 第二个2x2窗口: [0:2, 2:4]
        window2 = test_data[c, 0:2, 2:4]
        max2 = np.max(window2)
        print(f"  窗口2 [0:2, 2:4]: {window2.flatten()} -> max = {max2}")
        
        # 第三个2x2窗口: [2:4, 0:2]
        window3 = test_data[c, 2:4, 0:2]
        max3 = np.max(window3)
        print(f"  窗口3 [2:4, 0:2]: {window3.flatten()} -> max = {max3}")
        
        # 第四个2x2窗口: [2:4, 2:4]
        window4 = test_data[c, 2:4, 2:4]
        max4 = np.max(window4)
        print(f"  窗口4 [2:4, 2:4]: {window4.flatten()} -> max = {max4}")
        
        print(f"  预期结果: [{max1}, {max2}]")
        print(f"             [{max3}, {max4}]")
        print(f"  实际结果: {result[c]}")
        print()

if __name__ == "__main__":
    test_maxpool()
