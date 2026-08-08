#include "cnn_multilayer.h"

#define INPUT_BASE_ADDR    0x40000000
#define OUTPUT_BASE_ADDR   0x40100000
#define WEIGHT_BASE_ADDR   0x40200000

CNNLayerConfig layers[3];
CNNNetworkConfig network;

void setup_cnn_layers() {
    layers[0].type = LAYER_CONV;
    layers[0].k = 3;
    layers[0].cout = 32;
    layers[0].cin = 3;
    layers[0].stride = 1;
    layers[0].padding = 1;
    layers[0].groupSize = 2;
    layers[0].groupNum = 16;
    layers[0].inHeight = 32;
    layers[0].inWidth = 32;
    layers[0].actEn = 1;
    layers[0].actType = ACT_RELU;
    layers[0].poolEn = 0;
    layers[0].poolType = POOL_NONE;
    layers[0].bnEn = 0;
    layers[0].weightAddr = WEIGHT_BASE_ADDR;
    layers[0].biasAddr = WEIGHT_BASE_ADDR + 32 * 3 * 3 * 3 * 4;
    layers[0].outputAddr = OUTPUT_BASE_ADDR + 0;
    
    layers[1].type = LAYER_CONV;
    layers[1].k = 3;
    layers[1].cout = 64;
    layers[1].cin = 32;
    layers[1].stride = 2;
    layers[1].padding = 1;
    layers[1].groupSize = 2;
    layers[1].groupNum = 16;
    layers[1].inHeight = 32;
    layers[1].inWidth = 32;
    layers[1].actEn = 1;
    layers[1].actType = ACT_RELU;
    layers[1].poolEn = 1;
    layers[1].poolType = POOL_MAX;
    layers[1].poolK = 2;
    layers[1].poolStride = 2;
    layers[1].bnEn = 0;
    layers[1].weightAddr = WEIGHT_BASE_ADDR + 32 * 3 * 3 * 3 * 4 + 32 * 4;
    layers[1].biasAddr = WEIGHT_BASE_ADDR + 32 * 3 * 3 * 3 * 4 + 32 * 4 + 64 * 32 * 3 * 3 * 4;
    layers[1].outputAddr = OUTPUT_BASE_ADDR + 32 * 32 * 32 * 4;
    
    layers[2].type = LAYER_CONV;
    layers[2].k = 3;
    layers[2].cout = 128;
    layers[2].cin = 64;
    layers[2].stride = 1;
    layers[2].padding = 1;
    layers[2].groupSize = 2;
    layers[2].groupNum = 16;
    layers[2].inHeight = 8;
    layers[2].inWidth = 8;
    layers[2].actEn = 1;
    layers[2].actType = ACT_RELU;
    layers[2].poolEn = 0;
    layers[2].poolType = POOL_NONE;
    layers[2].bnEn = 0;
    layers[2].weightAddr = WEIGHT_BASE_ADDR + 32 * 3 * 3 * 3 * 4 + 32 * 4 + 64 * 32 * 3 * 3 * 4 + 64 * 4;
    layers[2].biasAddr = WEIGHT_BASE_ADDR + 32 * 3 * 3 * 3 * 4 + 32 * 4 + 64 * 32 * 3 * 3 * 4 + 64 * 4 + 128 * 64 * 3 * 3 * 4;
    layers[2].outputAddr = OUTPUT_BASE_ADDR + 32 * 32 * 32 * 4 + 64 * 8 * 8 * 4;
}

int main() {
    network.inputBaseAddr = INPUT_BASE_ADDR;
    network.outputBaseAddr = OUTPUT_BASE_ADDR;
    network.weightBaseAddr = WEIGHT_BASE_ADDR;
    
    setup_cnn_layers();
    
    cnn_init_network(&network, layers, 3);
    
    cnn_print_network(&network);
    
    cnn_run_network(&network);
    
    return 0;
}