/*
 * 初始化阶段测试
 * 测试流程：SRAM控制初始化
 * S1: 256MB BRAM (0x40000000)
 * S2: 64KB BRAM  (0x5000_0000-0x5000_FFFF)
 * S3: 64KB BRAM  (0x5001_0000-0x5001_FFFF)
 * S4: 64KB BRAM  (0x5002_0000-0x5002_FFFF)
 * S5: 64KB BRAM  (0x5003_0000-0x5003_FFFF)
 * S6: 64KB BRAM  (0x5004_0000-0x5004_FFFF)
 * S7: 64KB BRAM  (0x5005_0000-0x5005_FFFF)
 * CTRL Config: 0x5006_0000
 * DMA APB接口: 0x00420000
 */

// 地址定义
#define S1_BASE_ADDR     0x40000000    // S1: 256MB BRAM
#define S2_BASE_ADDR     0x50000000    // S2: 0x5000_0000-0x5000_FFFF
#define S3_BASE_ADDR     0x50010000    // S3: 0x5001_0000-0x5001_FFFF
#define S4_BASE_ADDR     0x50020000    // S4: 0x5002_0000-0x5002_FFFF
#define S5_BASE_ADDR     0x50030000    // S5: 0x5003_0000-0x5003_FFFF
#define S6_BASE_ADDR     0x50040000    // S6: 0x5004_0000-0x5004_FFFF
#define S7_BASE_ADDR     0x50050000    // S7: 0x5005_0000-0x5005_FFFF
#define CTRL_BASE_ADDR   0x50060000    // CTRL
#define DMA_APB_BASE     0x00420000    // DMA APB基地址

// DMA寄存器偏移（基于dma_reg.v）
#define DMA_CTRL         0x00          // DMA控制寄存器
#define DMA_STATUS       0x04          // DMA状态寄存器
#define DMA_ERR_CLR      0x08          // DMA错误清除寄存器
#define DESC0_MODE       0x20          // 描述符0模式配置
#define DESC0_LENGTH     0x24          // 描述符0传输长度
#define DESC0_SRC_ADDR   0x28          // 描述符0源地址
#define DESC0_DST_ADDR   0x2C          // 描述符0目标地址

// SRAM控制位定义
#define CTRL_WEIGHT_SRAM0_BIT  0  // RAM2控制位 (权重SRAM 0)
#define CTRL_WEIGHT_SRAM1_BIT  1  // RAM3控制位 (权重SRAM 1)
#define CTRL_OUTPUT_SRAM0_BIT  2  // RAM4控制位 (输出SRAM 0)
#define CTRL_OUTPUT_SRAM1_BIT  3  // RAM5控制位 (输出SRAM 1)
// 0=AXI控制, 1=MAC Machine控制

// APB访问函数
static inline void apb_write(unsigned int addr, unsigned int data) {
    volatile unsigned int *reg = (volatile unsigned int *)(DMA_APB_BASE + addr);
    *reg = data;
}

static inline unsigned int apb_read(unsigned int addr) {
    volatile unsigned int *reg = (volatile unsigned int *)(DMA_APB_BASE + addr);
    return *reg;
}

// 延时函数
void delay_cycles(int cycles) {
    for(int i = 0; i < cycles; i++) {
        __asm__ volatile ("nop");
    }
}

void short_delay(void) {
    delay_cycles(100);
}

void long_delay(void) {
    delay_cycles(1000);
}

// SRAM控制设置函数
void set_sram_control(unsigned int weight_sram0_ctrl,
                      unsigned int weight_sram1_ctrl,
                      unsigned int output_sram0_ctrl,
                      unsigned int output_sram1_ctrl) {
    volatile unsigned int *ctrl_base = (volatile unsigned int *)CTRL_BASE_ADDR;

    // 打包控制位：{28'h0, ctrl_bits[3:0]}
    unsigned int sram_ctrl_data = (output_sram1_ctrl << CTRL_OUTPUT_SRAM1_BIT) |
                                  (output_sram0_ctrl << CTRL_OUTPUT_SRAM0_BIT) |
                                  (weight_sram1_ctrl << CTRL_WEIGHT_SRAM1_BIT) |
                                  (weight_sram0_ctrl << CTRL_WEIGHT_SRAM0_BIT);

    // 使用寄存器传递调试信息
    __asm__ volatile ("mv x4, %0" : : "r"(weight_sram0_ctrl) : "x4");
    __asm__ volatile ("mv x5, %0" : : "r"(weight_sram1_ctrl) : "x5");
    __asm__ volatile ("mv x6, %0" : : "r"(output_sram0_ctrl) : "x6");
    __asm__ volatile ("mv x7, %0" : : "r"(output_sram1_ctrl) : "x7");

    // 写入控制数据
    *ctrl_base = sram_ctrl_data;

    // 等待写入稳定
    long_delay();
}

int main(void)
{
    // 地址对齐检查
    if ((S1_BASE_ADDR & 0x07) != 0 || (S2_BASE_ADDR & 0x07) != 0 ||
        (S3_BASE_ADDR & 0x07) != 0 || (S4_BASE_ADDR & 0x07) != 0 ||
        (S5_BASE_ADDR & 0x07) != 0 || (S6_BASE_ADDR & 0x07) != 0 ||
        (S7_BASE_ADDR & 0x07) != 0 || (CTRL_BASE_ADDR & 0x07) != 0) {
        __asm__ volatile ("li x3, 80");  // 地址未8字节对齐
        goto end;
    }

    long_delay();  // 系统稳定

    // === 步骤1: SRAM控制初始化 ===
    __asm__ volatile ("li x3, 1");  // 标记进入步骤1

    // 初始化SRAM控制：所有SRAM切换到外部控制（AXI控制）
    // weight_sram0, weight_sram1, output_sram0, output_sram1 = 0 (AXI)
    set_sram_control(0, 0, 0, 0);

    // 验证控制寄存器写入是否成功
    volatile unsigned int *ctrl_base = (volatile unsigned int *)CTRL_BASE_ADDR;
    unsigned int read_back = *ctrl_base;

    // 保存读取回的值用于调试
    __asm__ volatile ("mv x8, %0" : : "r"(read_back) : "x8");

    // 检查是否写入成功（期望值为0）
    if (read_back != 0x0) {
        __asm__ volatile ("li x3, 81");  // SRAM控制初始化失败
        goto end;
    }

    // === 步骤1成功完成 ===
    __asm__ volatile ("li x3, 100");    // 初始化阶段成功完成

    end:
    // 停机：进入低功耗等待状态，等待仿真监测 x3 == 100 后结束
    while (1) {
        __asm__ volatile ("li x3, 100" : : : "memory");
        __asm__ volatile ("nop");
    }
}

/*
 * 错误码说明：
 * 80: 地址未8字节对齐
 * 81: SRAM控制初始化失败（写入后读取不匹配）
 * 100: 初始化阶段成功完成
 *
 * 调试寄存器：
 * x3: 主要错误码或最终状态
 *     1: 进入步骤1的标记
 *     100: 成功
 *     其他值: 具体错误码
 * x4: weight_sram0_ctrl 参数
 * x5: weight_sram1_ctrl 参数
 * x6: output_sram0_ctrl 参数
 * x7: output_sram1_ctrl 参数
 * x8: SRAM控制寄存器读取回的值
 */

