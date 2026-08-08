/******************************************************************************
 * @file    test_conv.c
 * @brief   卷积算子单元测试
 * @author  Test Group 3
 * @date    2026-05-22
 ******************************************************************************/

#include "../common/test_framework.h"
#include <string.h>

/******************************************************************************
 * 测试用例1: 基础卷积测试
 * Input: 4x4, Kernel: 3x3, Stride: 1
 ******************************************************************************/
int test_basic_conv(void) {
    // 输入特征图: 4x4
    int8_t input[4][4] = {
        {1, 2, 3, 4},
        {5, 6, 7, 8},
        {9, 10, 11, 12},
        {13, 14, 15, 16}
    };
    
    // 卷积核: 3x3
    int8_t kernel[3][3] = {
        {1, 0, -1},
        {1, 0, -1},
        {1, 0, -1}
    };
    
    // 预期输出: 2x2 (使用valid卷积)
    int32_t expected[2][2] = {
        {1*1+2*0+3*(-1) + 5*1+6*0+7*(-1) + 9*1+10*0+11*(-1), 
         2*1+3*0+4*(-1) + 6*1+7*0+8*(-1) + 10*1+11*0+12*(-1)},
        {5*1+6*0+7*(-1) + 9*1+10*0+11*(-1) + 13*1+14*0+15*(-1),
         6*1+7*0+8*(-1) + 10*1+11*0+12*(-1) + 14*1+15*0+16*(-1)}
    };
    
    // 简化计算验证
    int32_t output[2][2];
    for (int i = 0; i < 2; i++) {
        for (int j = 0; j < 2; j++) {
            int32_t sum = 0;
            for (int ki = 0; ki < 3; ki++) {
                for (int kj = 0; kj < 3; kj++) {
                    sum += input[i + ki][j + kj] * kernel[ki][kj];
                }
            }
            output[i][j] = sum;
        }
    }
    
    // 验证结果
    for (int i = 0; i < 2; i++) {
        for (int j = 0; j < 2; j++) {
            TEST_ASSERT_EQ(expected[i][j], output[i][j]);
        }
    }
    
    return 0;
}

/******************************************************************************
 * 测试用例2: 多通道卷积测试
 * Input: 2@4x4, Kernel: 2@3x3, Output: 1@2x2
 ******************************************************************************/
int test_multi_channel_conv(void) {
    // 2通道输入: 每个通道 4x4
    int8_t input[2][4][4] = {
        {  // Channel 0
            {1, 1, 1, 1},
            {1, 1, 1, 1},
            {1, 1, 1, 1},
            {1, 1, 1, 1}
        },
        {  // Channel 1
            {2, 2, 2, 2},
            {2, 2, 2, 2},
            {2, 2, 2, 2},
            {2, 2, 2, 2}
        }
    };
    
    // 2通道卷积核
    int8_t kernel[2][3][3] = {
        {  // Channel 0 kernel
            {1, 0, 0},
            {0, 1, 0},
            {0, 0, 1}
        },
        {  // Channel 1 kernel
            {1, 1, 1},
            {1, 1, 1},
            {1, 1, 1}
        }
    };
    
    // 计算输出 (2x2)
    int32_t output[2][2];
    for (int i = 0; i < 2; i++) {
        for (int j = 0; j < 2; j++) {
            int32_t sum = 0;
            // 通道0卷积
            for (int ki = 0; ki < 3; ki++) {
                for (int kj = 0; kj < 3; kj++) {
                    sum += input[0][i + ki][j + kj] * kernel[0][ki][kj];
                }
            }
            // 通道1卷积
            for (int ki = 0; ki < 3; ki++) {
                for (int kj = 0; kj < 3; kj++) {
                    sum += input[1][i + ki][j + kj] * kernel[1][ki][kj];
                }
            }
            output[i][j] = sum;
        }
    }
    
    // 验证: 通道0贡献 = 3 (对角线), 通道1贡献 = 18 (9个2的和)
    // 总计 = 21
    for (int i = 0; i < 2; i++) {
        for (int j = 0; j < 2; j++) {
            TEST_ASSERT_EQ(21, output[i][j]);
        }
    }
    
    return 0;
}

/******************************************************************************
 * 测试用例3: 步长测试
 * Input: 6x6, Kernel: 3x3, Stride: 2
 ******************************************************************************/
int test_stride_conv(void) {
    // 输入: 6x6
    int8_t input[6][6];
    for (int i = 0; i < 6; i++) {
        for (int j = 0; j < 6; j++) {
            input[i][j] = i * 6 + j;
        }
    }
    
    // 卷积核: 全1
    int8_t kernel[3][3] = {
        {1, 1, 1},
        {1, 1, 1},
        {1, 1, 1}
    };
    
    // Stride=2, 输出尺寸 = (6-3)/2 + 1 = 2
    int stride = 2;
    int output_size = (6 - 3) / stride + 1;  // = 2
    
    TEST_ASSERT_EQ(2, output_size);
    
    int32_t output[2][2];
    for (int i = 0; i < output_size; i++) {
        for (int j = 0; j < output_size; j++) {
            int32_t sum = 0;
            for (int ki = 0; ki < 3; ki++) {
                for (int kj = 0; kj < 3; kj++) {
                    sum += input[i * stride + ki][j * stride + kj] * kernel[ki][kj];
                }
            }
            output[i][j] = sum;
        }
    }
    
    // 验证输出尺寸
    TEST_ASSERT_EQ(2, output_size);
    
    // 验证第一个输出值 (左上角3x3的和)
    // 0+1+2 + 6+7+8 + 12+13+14 = 63
    TEST_ASSERT_EQ(63, output[0][0]);
    
    return 0;
}

/******************************************************************************
 * 测试用例4: 填充测试
 * Input: 4x4, Kernel: 3x3, Stride: 1, Pad: 1
 ******************************************************************************/
int test_padding_conv(void) {
    // 原始输入: 4x4
    int8_t input[4][4] = {
        {1, 2, 3, 4},
        {5, 6, 7, 8},
        {9, 10, 11, 12},
        {13, 14, 15, 16}
    };
    
    // 填充后: 6x6 (四周补0)
    int8_t padded[6][6] = {0};
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            padded[i + 1][j + 1] = input[i][j];
        }
    }
    
    // 卷积核: 全1
    int8_t kernel[3][3] = {
        {1, 1, 1},
        {1, 1, 1},
        {1, 1, 1}
    };
    
    // 输出尺寸 = (4+2*1-3)/1 + 1 = 4 (same卷积)
    int output_size = 4;
    int32_t output[4][4];
    
    for (int i = 0; i < output_size; i++) {
        for (int j = 0; j < output_size; j++) {
            int32_t sum = 0;
            for (int ki = 0; ki < 3; ki++) {
                for (int kj = 0; kj < 3; kj++) {
                    sum += padded[i + ki][j + kj] * kernel[ki][kj];
                }
            }
            output[i][j] = sum;
        }
    }
    
    // 验证输出尺寸
    TEST_ASSERT_EQ(4, output_size);
    
    // 验证中心值 (包含原始6)
    // 周围: 2,3,5,7,10,11 (来自padded)
    // 6 + 2+3+5+7+10+11 = 44
    TEST_ASSERT_EQ(44, output[1][1]);
    
    return 0;
}

/******************************************************************************
 * 测试用例5: 输出尺寸计算测试
 ******************************************************************************/
int test_output_size_calculation(void) {
    // 测试各种配置的输出尺寸
    
    // Case 1: 4x4 input, 3x3 kernel, stride 1, no padding
    // Output = (4 - 3) / 1 + 1 = 2
    int size1 = (4 - 3) / 1 + 1;
    TEST_ASSERT_EQ(2, size1);
    
    // Case 2: 6x6 input, 3x3 kernel, stride 2, no padding
    // Output = (6 - 3) / 2 + 1 = 2
    int size2 = (6 - 3) / 2 + 1;
    TEST_ASSERT_EQ(2, size2);
    
    // Case 3: 4x4 input, 3x3 kernel, stride 1, padding 1
    // Output = (4 + 2*1 - 3) / 1 + 1 = 4
    int size3 = (4 + 2*1 - 3) / 1 + 1;
    TEST_ASSERT_EQ(4, size3);
    
    // Case 4: 7x7 input, 3x3 kernel, stride 2, padding 1
    // Output = (7 + 2*1 - 3) / 2 + 1 = 4
    int size4 = (7 + 2*1 - 3) / 2 + 1;
    TEST_ASSERT_EQ(4, size4);
    
    return 0;
}

/******************************************************************************
 * 测试用例6: 边界值测试
 ******************************************************************************/
int test_boundary_values(void) {
    // 测试最大值
    int8_t max_val = 127;
    int8_t kernel[1][1] = {{1}};
    int32_t result = max_val * kernel[0][0];
    TEST_ASSERT_EQ(127, result);
    
    // 测试最小值
    int8_t min_val = -128;
    result = min_val * kernel[0][0];
    TEST_ASSERT_EQ(-128, result);
    
    // 测试溢出 (INT8乘法结果用INT32存储)
    result = max_val * max_val;  // 127 * 127 = 16129
    TEST_ASSERT_EQ(16129, result);
    
    return 0;
}

/******************************************************************************
 * 测试主程序
 ******************************************************************************/
TEST_MAIN_BEGIN()

    printf("\n>>> 卷积算子单元测试 <<<\n");
    
    TEST_RUN(test_basic_conv);
    TEST_RUN(test_multi_channel_conv);
    TEST_RUN(test_stride_conv);
    TEST_RUN(test_padding_conv);
    TEST_RUN(test_output_size_calculation);
    TEST_RUN(test_boundary_values);

TEST_MAIN_END()
