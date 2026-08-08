#include "cnn_multilayer.h"
#include "mac_test_tb2.c"

CNNNetworkConfig g_network;

void cnn_calculate_output_size(CNNLayerConfig *layer) {
    if (layer->type == LAYER_CONV) {
        layer->outHeight = (layer->inHeight + 2 * layer->padding - layer->k) / layer->stride + 1;
        layer->outWidth = (layer->inWidth + 2 * layer->padding - layer->k) / layer->stride + 1;
    } else if (layer->type == LAYER_POOL) {
        layer->outHeight = (layer->inHeight - layer->poolK) / layer->poolStride + 1;
        layer->outWidth = (layer->inWidth - layer->poolK) / layer->poolStride + 1;
    } else if (layer->type == LAYER_FC) {
        layer->outHeight = 1;
        layer->outWidth = layer->cout;
    }
}

void cnn_init_network(CNNNetworkConfig *network, CNNLayerConfig *layers, int numLayers) {
    network->layers = layers;
    network->numLayers = numLayers;
    
    for (int i = 0; i < numLayers; i++) {
        layers[i].layerIdx = i;
        
        if (i == 0) {
            layers[i].inputAddr = network->inputBaseAddr;
        } else {
            layers[i].inputAddr = layers[i-1].outputAddr;
        }
        
        if (layers[i].type == LAYER_CONV) {
            cnn_calculate_output_size(&layers[i]);
        }
    }
}

void cnn_config_layer(CNNLayerConfig *layer) {
    switch (layer->type) {
        case LAYER_CONV:
            config_tiles_and_noc(layer->groupSize, layer->k);
            break;
        case LAYER_POOL:
            break;
        case LAYER_ACT:
            break;
        case LAYER_FC:
            break;
        default:
            break;
    }
}

void cnn_run_convolution(CNNLayerConfig *layer) {
    int k = layer->k;
    int cout = layer->cout;
    int cin = layer->cin;
    int groupSize = layer->groupSize;
    int groupNum = layer->groupNum;
    int stride = layer->stride;
    int cinIdxTotal = (cin + groupSize - 1) / groupSize;
    int resolutionColTotal = 1;
    int resolutionRowTotal = (layer->outHeight + 15) / 16;
    
    unsigned int featurePingpongFlag = 0;
    unsigned int weightPingpongFlag = 0;
    unsigned int outputPingpongFlag = 0;
    unsigned int pingpongEnFlag = 0;
    int planeWorkMode = 0;
    int dataFlowMode = 0;
    int truncateBits = 0;
    int truncateEn = 0;
    
    set_sram_control(0, 0, 0, 0);
    
    config_tiles_and_noc(groupSize, k);
    
    int weightLength = cout * cinIdxTotal * groupSize;
    drive_weights_from_files(weightLength);
    
    drive_features_to_sram();
    
    for (int resolutionRowIdx = 0; resolutionRowIdx < resolutionRowTotal; resolutionRowIdx++) {
        for (int resolutionColIdx = 0; resolutionColIdx < resolutionColTotal; resolutionColIdx++) {
            if (resolutionRowIdx == 0) {
                planeWorkMode = (resolutionColIdx == 0) ? 0 : 4;
            } else {
                planeWorkMode = (resolutionColIdx == 0) ? 1 : 2;
            }
            
            run_process(0, resolutionColIdx, resolutionRowIdx, k, cout, groupSize, groupNum, stride,
                       cinIdxTotal, resolutionColTotal, resolutionRowTotal, dataFlowMode, truncateBits, truncateEn,
                       featurePingpongFlag, weightPingpongFlag, outputPingpongFlag, pingpongEnFlag, planeWorkMode);
            
            planeWorkMode = 3;
            
            for (int cinIdx = 1; cinIdx < cinIdxTotal; cinIdx++) {
                run_process(cinIdx, resolutionColIdx, resolutionRowIdx, k, cout, groupSize, groupNum, stride,
                           cinIdxTotal, resolutionColTotal, resolutionRowTotal, dataFlowMode, truncateBits, truncateEn,
                           featurePingpongFlag, weightPingpongFlag, outputPingpongFlag, pingpongEnFlag, planeWorkMode);
            }
            
            print_output_results(resolutionColIdx, resolutionRowIdx, outputPingpongFlag);
        }
    }
}

void cnn_run_pooling(CNNLayerConfig *layer) {
    if (!layer->poolEn || layer->poolType == POOL_NONE) {
        return;
    }
    
    int poolK = layer->poolK;
    int poolStride = layer->poolStride;
    int cout = layer->cout;
    int inHeight = layer->inHeight;
    int inWidth = layer->inWidth;
    
    set_sram_control(0, 0, 0, 0);
}

void cnn_run_activation(CNNLayerConfig *layer) {
    if (!layer->actEn || layer->actType == ACT_NONE) {
        return;
    }
    
    set_sram_control(0, 0, 0, 0);
}

void cnn_run_network(CNNNetworkConfig *network) {
    dma_irq_ctx_t dma_ctx = {0};
    mac_irq_ctx_t mac_ctx = {0};
    dma_set_context(&dma_ctx);
    mac_set_context(&mac_ctx);
    
    plic_set_threshold(0);
    plic_init_mac_interrupts();
    plic_init_dma_interrupts();
    
    set_mtvec(trap_entry);
    enable_plic_interrupts();
    
    for (int i = 0; i < network->numLayers; i++) {
        CNNLayerConfig *layer = &network->layers[i];
        
        switch (layer->type) {
            case LAYER_CONV:
                cnn_run_convolution(layer);
                break;
            case LAYER_POOL:
                cnn_run_pooling(layer);
                break;
            case LAYER_ACT:
                cnn_run_activation(layer);
                break;
            case LAYER_FC:
                break;
            default:
                break;
        }
        
        if (layer->actEn && layer->actType != ACT_NONE) {
            cnn_run_activation(layer);
        }
        
        if (layer->poolEn && layer->poolType != POOL_NONE) {
            cnn_run_pooling(layer);
        }
    }
}

void cnn_print_network(CNNNetworkConfig *network) {
    for (int i = 0; i < network->numLayers; i++) {
        CNNLayerConfig *layer = &network->layers[i];
        
        switch (layer->type) {
            case LAYER_CONV:
                break;
            case LAYER_POOL:
                break;
            case LAYER_ACT:
                break;
            case LAYER_FC:
                break;
            default:
                break;
        }
    }
}