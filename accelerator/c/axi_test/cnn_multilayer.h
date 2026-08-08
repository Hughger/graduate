#ifndef CNN_MULTILAYER_H
#define CNN_MULTILAYER_H

#include <stdint.h>

// ========== 层类型枚举 ==========
typedef enum {
    LAYER_CONV,     
    LAYER_POOL,     
    LAYER_ACT,      
    LAYER_FC        
} LayerType;

// ========== 激活函数类型 ==========
typedef enum {
    ACT_NONE,
    ACT_RELU,
    ACT_RELU6,
    ACT_SIGMOID
} ActivationType;

// ========== 池化类型 ==========
typedef enum {
    POOL_NONE,
    POOL_MAX,
    POOL_AVG
} PoolType;

// ========== CNN层配置结构体 ==========
typedef struct {
    LayerType type;
    
    // 卷积参数
    int k;              // 卷积核大小
    int cout;           // 输出通道数
    int cin;            // 输入通道数
    int stride;         // 步长
    int padding;        // 填充
    int groupSize;      // 每组处理单元数
    int groupNum;       // 组数
    
    // 特征图尺寸
    int inHeight;       // 输入高度
    int inWidth;        // 输入宽度
    int outHeight;      // 输出高度
    int outWidth;       // 输出宽度
    
    // 激活函数配置
    int actEn;          // 激活使能
    ActivationType actType;  // 激活类型
    
    // 池化配置
    int poolEn;         // 池化使能
    PoolType poolType;  // 池化类型
    int poolK;          // 池化核大小
    int poolStride;     // 池化步长
    
    // 批归一化配置
    int bnEn;          // BN使能
    
    // 数据地址（S1 BRAM中的偏移地址）
    uint32_t weightAddr; // 权重地址
    uint32_t biasAddr;   // 偏置地址
    uint32_t inputAddr;  // 输入特征图地址
    uint32_t outputAddr; // 输出特征图地址
    
    // 运行时状态
    int layerIdx;       // 层索引
} CNNLayerConfig;

// ========== 网络配置结构体 ==========
typedef struct {
    CNNLayerConfig *layers;
    int numLayers;
    uint32_t inputBaseAddr;   // 输入数据基地址
    uint32_t outputBaseAddr;  // 输出数据基地址
    uint32_t weightBaseAddr;  // 权重基地址
} CNNNetworkConfig;

// ========== 全局变量声明 ==========
extern CNNNetworkConfig g_network;

// ========== 函数声明 ==========

// 初始化CNN网络配置
void cnn_init_network(CNNNetworkConfig *network, CNNLayerConfig *layers, int numLayers);

// 配置单个CNN层
void cnn_config_layer(CNNLayerConfig *layer);

// 执行单步卷积推理
void cnn_run_convolution(CNNLayerConfig *layer);

// 执行池化操作
void cnn_run_pooling(CNNLayerConfig *layer);

// 执行激活操作
void cnn_run_activation(CNNLayerConfig *layer);

// 执行完整网络推理
void cnn_run_network(CNNNetworkConfig *network);

// 计算输出特征图尺寸
void cnn_calculate_output_size(CNNLayerConfig *layer);

// 打印网络配置
void cnn_print_network(CNNNetworkConfig *network);

#endif // CNN_MULTILAYER_H