/******************************************************************************
 * @file    lenet_config.h
 * @brief   LeNet-5网络配置 for FLOOD加速器
 * @author  Demo Group 1
 * @date    2026-05-22
 ******************************************************************************/

#ifndef LENET_CONFIG_H
#define LENET_CONFIG_H

#include "../common/cnn_types.h"

#ifdef __cplusplus
extern "C" {
#endif

/******************************************************************************
 * LeNet-5网络结构定义
 * 
 * 原始LeNet-5结构:
 * - Input: 1@32x32 (MNIST 28x28 with padding)
 * - C1: Conv 1→6, k=5, stride=1, pad=0 → 6@28x28
 * - S2: AvgPool k=2, stride=2 → 6@14x14
 * - C3: Conv 6→16, k=5, stride=1 → 16@10x10
 * - S4: AvgPool k=2, stride=2 → 16@5x5
 * - C5: FC 16*5*5=400 → 120
 * - F6: FC 120 → 84
 * - Output: FC 84 → 10
 ******************************************************************************/

/******************************************************************************
 * 网络层数定义
 ******************************************************************************/
#define LENET_TOTAL_LAYERS      7

/******************************************************************************
 * 各层配置参数
 ******************************************************************************/

// Layer 1: Conv C1 (1→6, k=5)
#define LENET_L1_INPUT_C        1
#define LENET_L1_INPUT_H        32
#define LENET_L1_INPUT_W        32
#define LENET_L1_OUTPUT_C       6
#define LENET_L1_OUTPUT_H       28
#define LENET_L1_OUTPUT_W       28
#define LENET_L1_KERNEL_SIZE    5
#define LENET_L1_STRIDE         1
#define LENET_L1_PADDING        0

// Layer 2: AvgPool S2 (k=2)
#define LENET_L2_INPUT_C        6
#define LENET_L2_INPUT_H        28
#define LENET_L2_INPUT_W        28
#define LENET_L2_OUTPUT_C       6
#define LENET_L2_OUTPUT_H       14
#define LENET_L2_OUTPUT_W       14
#define LENET_L2_KERNEL_SIZE    2
#define LENET_L2_STRIDE         2

// Layer 3: Conv C3 (6→16, k=5)
#define LENET_L3_INPUT_C        6
#define LENET_L3_INPUT_H        14
#define LENET_L3_INPUT_W        14
#define LENET_L3_OUTPUT_C       16
#define LENET_L3_OUTPUT_H       10
#define LENET_L3_OUTPUT_W       10
#define LENET_L3_KERNEL_SIZE    5
#define LENET_L3_STRIDE         1
#define LENET_L3_PADDING        0

// Layer 4: AvgPool S4 (k=2)
#define LENET_L4_INPUT_C        16
#define LENET_L4_INPUT_H        10
#define LENET_L4_INPUT_W        10
#define LENET_L4_OUTPUT_C       16
#define LENET_L4_OUTPUT_H       5
#define LENET_L4_OUTPUT_W       5
#define LENET_L4_KERNEL_SIZE    2
#define LENET_L4_STRIDE         2

// Layer 5: FC C5 (400→120)
#define LENET_L5_INPUT_SIZE     400     // 16*5*5
#define LENET_L5_OUTPUT_SIZE    120

// Layer 6: FC F6 (120→84)
#define LENET_L6_INPUT_SIZE     120
#define LENET_L6_OUTPUT_SIZE    84

// Layer 7: Output (84→10)
#define LENET_L7_INPUT_SIZE     84
#define LENET_L7_OUTPUT_SIZE    10

/******************************************************************************
 * 加速器特定配置
 * 
 * 根据FLOOD加速器硬件参数配置:
 * - rowSize = 32, colSize = 32 (CIMCore阵列)
 * - tileSize = 16 (Cluster内Tile数量)
 * - maxKernelSize = 32 (最大卷积核尺寸)
 ******************************************************************************/

// Layer 1加速器配置
#define LENET_L1_GROUP_SIZE     2       // 每组2个Tile
#define LENET_L1_GROUP_NUM      3       // 共3组 (输出6通道)
#define LENET_L1_TILE_CONFIG    {0x0000, 0x0101, 0x0202, 0x0303, 0x0404, 0x0505}

// Layer 3加速器配置
#define LENET_L3_GROUP_SIZE     2
#define LENET_L3_GROUP_NUM      8       // 输出16通道
#define LENET_L3_TILE_CONFIG    {0x0000, 0x0101, 0x0202, 0x0303, 0x0404, 0x0505, \
                                 0x0606, 0x0707, 0x0808, 0x0909, 0x0A0A, 0x0B0B, \
                                 0x0C0C, 0x0D0D, 0x0E0E, 0x0F0F}

/******************************************************************************
 * 权重和偏置地址定义
 ******************************************************************************/
#define LENET_WEIGHT_BASE_ADDR  0x40200000
#define LENET_BIAS_BASE_ADDR    0x40280000

// Layer 1权重地址: 6*1*5*5 = 150
#define LENET_L1_WEIGHT_ADDR    LENET_WEIGHT_BASE_ADDR
#define LENET_L1_WEIGHT_SIZE    150
#define LENET_L1_BIAS_ADDR      LENET_BIAS_BASE_ADDR
#define LENET_L1_BIAS_SIZE      6

// Layer 3权重地址: 16*6*5*5 = 2400
#define LENET_L3_WEIGHT_ADDR    (LENET_WEIGHT_BASE_ADDR + 0x1000)
#define LENET_L3_WEIGHT_SIZE    2400
#define LENET_L3_BIAS_ADDR      (LENET_BIAS_BASE_ADDR + 0x100)
#define LENET_L3_BIAS_SIZE      16

/******************************************************************************
 * 特征图地址定义
 ******************************************************************************/
#define LENET_FEATURE_BASE_ADDR 0x40000000

// Layer 1输出: 6*28*28 = 4704
#define LENET_L1_OUTPUT_ADDR    LENET_FEATURE_BASE_ADDR
#define LENET_L1_OUTPUT_SIZE    4704

// Layer 2输出: 6*14*14 = 1176
#define LENET_L2_OUTPUT_ADDR    (LENET_FEATURE_BASE_ADDR + 0x2000)
#define LENET_L2_OUTPUT_SIZE    1176

// Layer 3输出: 16*10*10 = 1600
#define LENET_L3_OUTPUT_ADDR    (LENET_FEATURE_BASE_ADDR + 0x4000)
#define LENET_L3_OUTPUT_SIZE    1600

// Layer 4输出: 16*5*5 = 400
#define LENET_L4_OUTPUT_ADDR    (LENET_FEATURE_BASE_ADDR + 0x6000)
#define LENET_L4_OUTPUT_SIZE    400

/******************************************************************************
 * 层配置结构体
 ******************************************************************************/
extern const LayerConfig lenet_layers[LENET_TOTAL_LAYERS];

/******************************************************************************
 * 函数声明
 ******************************************************************************/

/**
 * @brief 初始化LeNet网络配置
 */
void lenet_init_network(void);

/**
 * @brief 获取指定层的配置
 * @param layer_idx 层索引 (0-6)
 * @return 层配置指针
 */
const LayerConfig* lenet_get_layer_config(int layer_idx);

/**
 * @brief 打印网络结构信息
 */
void lenet_print_network_info(void);

#ifdef __cplusplus
}
#endif

#endif /* LENET_CONFIG_H */
