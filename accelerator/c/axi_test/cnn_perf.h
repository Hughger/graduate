#ifndef CNN_PERF_H
#define CNN_PERF_H

#include <stdint.h>

typedef struct {
    uint64_t startTime;
    uint64_t endTime;
    uint64_t elapsedCycles;
    uint64_t macOperations;
    uint64_t dmaTransfers;
    uint64_t interrupts;
} LayerPerfStats;

typedef struct {
    LayerPerfStats *layerStats;
    int numLayers;
    uint64_t totalCycles;
    uint64_t totalMacOperations;
    float averageMacUtilization;
    float speedupRatio;
} NetworkPerfStats;

extern NetworkPerfStats g_perfStats;

void perf_init(NetworkPerfStats *stats, int numLayers);

void perf_start_layer(int layerIdx);

void perf_end_layer(int layerIdx, uint64_t macOps, uint64_t dmaXfers, uint64_t irqs);

void perf_calculate_total(NetworkPerfStats *stats);

void perf_print_layer_stats(int layerIdx);

void perf_print_network_summary(NetworkPerfStats *stats);

uint64_t perf_get_cycle_count(void);

#endif