#include "cnn_perf.h"

NetworkPerfStats g_perfStats;

uint64_t perf_get_cycle_count(void) {
    uint64_t cycle_count;
    __asm__ volatile ("rdcycle %0" : "=r"(cycle_count));
    return cycle_count;
}

void perf_init(NetworkPerfStats *stats, int numLayers) {
    stats->numLayers = numLayers;
    stats->totalCycles = 0;
    stats->totalMacOperations = 0;
    stats->averageMacUtilization = 0.0f;
    stats->speedupRatio = 0.0f;
}

void perf_start_layer(int layerIdx) {
    if (layerIdx < g_perfStats.numLayers) {
        g_perfStats.layerStats[layerIdx].startTime = perf_get_cycle_count();
        g_perfStats.layerStats[layerIdx].macOperations = 0;
        g_perfStats.layerStats[layerIdx].dmaTransfers = 0;
        g_perfStats.layerStats[layerIdx].interrupts = 0;
    }
}

void perf_end_layer(int layerIdx, uint64_t macOps, uint64_t dmaXfers, uint64_t irqs) {
    if (layerIdx < g_perfStats.numLayers) {
        g_perfStats.layerStats[layerIdx].endTime = perf_get_cycle_count();
        g_perfStats.layerStats[layerIdx].elapsedCycles = 
            g_perfStats.layerStats[layerIdx].endTime - 
            g_perfStats.layerStats[layerIdx].startTime;
        g_perfStats.layerStats[layerIdx].macOperations = macOps;
        g_perfStats.layerStats[layerIdx].dmaTransfers = dmaXfers;
        g_perfStats.layerStats[layerIdx].interrupts = irqs;
    }
}

void perf_calculate_total(NetworkPerfStats *stats) {
    stats->totalCycles = 0;
    stats->totalMacOperations = 0;
    
    for (int i = 0; i < stats->numLayers; i++) {
        stats->totalCycles += stats->layerStats[i].elapsedCycles;
        stats->totalMacOperations += stats->layerStats[i].macOperations;
    }
    
    if (stats->totalCycles > 0) {
        stats->averageMacUtilization = (float)stats->totalMacOperations / (float)stats->totalCycles;
    } else {
        stats->averageMacUtilization = 0.0f;
    }
    
    float theoreticalPeak = 256.0f * 2.0f;
    stats->speedupRatio = stats->averageMacUtilization / (1.0f / theoreticalPeak);
}

void perf_print_layer_stats(int layerIdx) {
    if (layerIdx >= g_perfStats.numLayers) return;
    
    LayerPerfStats *stats = &g_perfStats.layerStats[layerIdx];
}

void perf_print_network_summary(NetworkPerfStats *stats) {
}