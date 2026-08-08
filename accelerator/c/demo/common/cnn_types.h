/******************************************************************************
 * @file    cnn_types.h
 * @brief   CNN通用类型定义
 * @author  Demo Group
 * @date    2026-05-22
 ******************************************************************************/

#ifndef CNN_TYPES_H
#define CNN_TYPES_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/******************************************************************************
 * 层类型定义
 ******************************************************************************/
typedef enum {
    LAYER_CONV = 0,         // 卷积层
    LAYER_FC,               // 全连接层
    LAYER_POOL,             // 池化层
    LAYER_ACTIVATION,       // 激活函数层
    LAYER_BN,               // 批归一化层
    LAYER_INPUT,            // 输入层
    LAYER_OUTPUT            // 输出层
} LayerType;

/******************************************************************************
 * 激活函数类型
 ******************************************************************************/
typedef enum {
    ACT_NONE = 0,           // 无激活
    ACT_RELU,               // ReLU
    ACT_LEAKY_RELU,         // Leaky ReLU
    ACT_SIGMOID,            // Sigmoid
    ACT_TANH                // Tanh
} ActivationType;

/******************************************************************************
 * 池化类型
 ******************************************************************************/
typedef enum {
    POOL_NONE = 0,          // 无池化
    POOL_MAX,               // 最大池化
    POOL_AVG               // 平均池化
} PoolType;

/******************************************************************************
 * 层配置结构体
 ******************************************************************************/
typedef struct {
    // 层基本信息
    int layer_id;           // 层ID
    LayerType type;         // 层类型
    
    // 输入维度
    int input_c;            // 输入通道数
    int input_h;            // 输入高度
    int input_w;            // 输入宽度
    uint32_t input_addr;    // 输入数据地址
    
    // 输出维度
    int output_c;           // 输出通道数
    int output_h;           // 输出高度
    int output_w;           // 输出宽度
    uint32_t output_addr;   // 输出数据地址
    
    // 卷积参数
    int kernel_size;        // 卷积核大小 (k)
    int stride;             // 步长
    int padding;            // 填充
    
    // 池化参数
    PoolType pool_type;     // 池化类型
    int pool_kernel;        // 池化核大小
    int pool_stride;        // 池化步长
    
    // 激活函数
    ActivationType act_type; // 激活函数类型
    
    // 权重和偏置
    uint32_t weight_addr;   // 权重地址
    uint32_t weight_size;   // 权重大小 (字节)
    uint32_t bias_addr;     // 偏置地址
    uint32_t bias_size;     // 偏置大小 (字节)
    
    // 加速器特定配置
    int group_size;         // 组大小 (Tile数)
    int group_num;          // 组数量
    int tile_config[16];    // Tile配置
    
    // 量化参数
    float input_scale;      // 输入量化scale
    float output_scale;     // 输出量化scale
    int input_zero_point;   // 输入zero point
    int output_zero_point;  // 输出zero point
} LayerConfig;

/******************************************************************************
 * 网络配置结构体
 ******************************************************************************/
typedef struct {
    const char* name;               // 网络名称
    int num_layers;                 // 层数
    const LayerConfig* layers;      // 层配置数组
    uint32_t input_addr;            // 网络输入地址
    uint32_t output_addr;           // 网络输出地址
    int input_size;                 // 输入数据大小
    int output_size;                // 输出数据大小
} NetworkConfig;

/******************************************************************************
 * 推理结果结构体
 ******************************************************************************/
typedef struct {
    int predicted_class;            // 预测类别
    float confidence;               // 置信度
    float probabilities[10];        // 各类别概率 (用于分类任务)
} InferenceResult;

/******************************************************************************
 * 常用宏定义
 ******************************************************************************/

// 计算卷积输出尺寸
#define CONV_OUTPUT_SIZE(input_size, kernel, stride, padding) \
    (((input_size) + 2 * (padding) - (kernel)) / (stride) + 1)

// 计算池化输出尺寸
#define POOL_OUTPUT_SIZE(input_size, kernel, stride) \
    (((input_size) - (kernel)) / (stride) + 1)

// 对齐到指定边界
#define ALIGN_UP(size, align) (((size) + (align) - 1) & ~((align) - 1))

// 计算数据大小 (字节)
#define DATA_SIZE(ch, h, w) ((ch) * (h) * (w) * sizeof(int8_t))

#ifdef __cplusplus
}
#endif

#endif /* CNN_TYPES_H */
