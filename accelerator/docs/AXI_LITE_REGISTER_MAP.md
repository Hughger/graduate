# SD1.5 Diffusion Accelerator AXI-Lite Register Map

This interface is the software control and measurement plane for
`DiffusionAccelTop`.  All registers are 32 bits wide and use byte addresses.
Counters accumulate from reset.  Multiword counters are exposed as a stable
64-bit snapshot so a host never mixes words sampled in different cycles.

## Control registers

| Address | Name | Access | Description |
| --- | --- | --- | --- |
| `0x000` | `CONTROL` | WO | Write bit 0 as one to start one residual-block schedule. A start request while `STATUS.busy` is one returns AXI `SLVERR`; all other writes return `OKAY`. |
| `0x004` | `STATUS` | RO | Bit 0 is `busy`. It remains asserted from accepted start through the block scheduler completion. |
| `0x008` | `PERF_SNAPSHOT` | WO | Write bit 0 as one to capture all live performance counters atomically. |

The implementation accepts AXI-Lite write address and data channels in either
order.  The start and snapshot strobes require byte lane 0 to be enabled.

## Performance counter window

Each counter is unsigned, saturating, and 64 bits.  Read the low word first
or high word first after a `PERF_SNAPSHOT` write; both belong to the same
captured sample.

| Low / high address | Counter | Unit | Definition |
| --- | --- | --- | --- |
| `0x010` / `0x014` | `totalCycles` | cycles | Cycles for which the residual-block scheduler is busy. |
| `0x018` / `0x01c` | `readBytes` | bytes | 64 bytes for every accepted TensorRead DMA beat. |
| `0x020` / `0x024` | `writeBytes` | bytes | 64 bytes for every accepted TensorWrite DMA beat. |
| `0x028` / `0x02c` | `macCycles` | cycles | Scheduler cycles in `Gn1Conv1` or `Gn2Conv2Residual`. |
| `0x030` / `0x034` | `groupNormCycles` | cycles | Scheduler cycles in `Gn1Stats` or `Gn2Stats`. |
| `0x038` / `0x03c` | `stallCycles` | cycles | Busy cycles with MIG or mandatory top-level result-stream backpressure (`valid && !ready`). Multiple blocked interfaces still count as one cycle. |

## Recommended host sequence

1. Write `PERF_SNAPSHOT[0] = 1` and record a baseline sample.
2. Program the DMA and tensor command interfaces for one residual block.
3. Write `CONTROL[0] = 1` and wait for `STATUS.busy` to return to zero.
4. Write `PERF_SNAPSHOT[0] = 1`, read the counter pairs, and reconstruct
   each value as `(high << 32) | low`.
5. Subtract the baseline sample to obtain per-block measurements.

The software-visible snapshot supplements the existing direct hardware
`perfSnapshot` / `perfCounters` ports.  Both trigger paths capture the same
`PerfMonitor` state.
