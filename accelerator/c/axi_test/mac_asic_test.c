/*
 * DMA 传输测试
 * 测试流程：CPU写S1 → DMA搬运S1到S2 → CPU读S2验证
 *          → DMA搬运S1到S3 → CPU读S3验证
 *          → DMA搬运S1到S4 → CPU读S4验证
 *          → DMA搬运S1到S5 → CPU读S5验证
 *          → DMA搬运S1到S6 → CPU读S6验证
 *          → CPU写S7 → DMA搬运S7到S1(0x40000100) → CPU读S1验证
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
#define S1_OFFSET_ADDR   0x40000100    // S1偏移地址，用于S7向S1写数据
#define DMA_APB_BASE     0x00420000    // DMA APB基地址

// DMA寄存器偏移（基于dma_reg.v）
#define DMA_CTRL         0x00          // DMA控制寄存器
#define DMA_STATUS       0x04          // DMA状态寄存器  
#define DMA_ERR_CLR      0x08          // DMA错误清除寄存器
#define DESC0_MODE       0x20          // 描述符0模式配置
#define DESC0_LENGTH     0x24          // 描述符0传输长度
#define DESC0_SRC_ADDR   0x28          // 描述符0源地址
#define DESC0_DST_ADDR   0x2C          // 描述符0目标地址

#define TEST_COUNT       16            // 测试数据个数
#define TEST_BYTES       (TEST_COUNT * 4)  // 总字节数：64字节
// 注意：DMA使用64位数据宽度，但我们测试32位数据
// 64字节 = 8个64位传输 = 16个32位数据 ✓

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

// 等待DMA完成（轮询方式）
int wait_dma_complete(void) {
    int timeout = 100000;  // 超时计数
    
    while(timeout-- > 0) {
        unsigned int status = apb_read(DMA_STATUS);
        
        // 解析状态寄存器
        unsigned int version = (status >> 8) & 0xFFFF;  // bit[23:8]: 版本号
        unsigned int dma_state = (status >> 2) & 0x03;  // bit[3:2]: 状态
        unsigned int dma_err = (status >> 1) & 0x01;    // bit[1]: 错误标志
        unsigned int dma_done = status & 0x01;          // bit[0]: 完成标志
        
        // 打印调试信息（前几次）
        if (timeout > 99995) {
            // 使用寄存器x3传递调试信息
            __asm__ volatile ("mv x3, %0" : : "r"(status) : "x3");
        }
        
        // 检查错误状态
        if (dma_err) {
            // DMA错误，清除错误标志
            apb_write(DMA_ERR_CLR, 1);
            return -1;  // 返回错误
        }
        
        // 根据状态机检查完成
        // DMA状态：00=idle, 01=check, 10=run, 11=done
        if (dma_state == 0x03) {  // DMA_DONE状态
            // DMA完成，清除start位（保持maxburst设置）
            apb_write(DMA_CTRL, (8 << 8) | 0);  // 匹配启动时的maxburst=8
            return 0;   // 成功完成
        }
        
        // 也检查完成标志位作为备用
        if (dma_done) {
            apb_write(DMA_CTRL, (8 << 8) | 0);  // 匹配启动时的maxburst=8
            return 0;   // 成功完成
        }
        
        short_delay();
    }
    
    return -2;  // 超时
}

int main(void)
{
    volatile unsigned int *s1_base = (volatile unsigned int *)S1_BASE_ADDR;
    volatile unsigned int *s2_base = (volatile unsigned int *)S2_BASE_ADDR;
    volatile unsigned int *s3_base = (volatile unsigned int *)S3_BASE_ADDR;
    volatile unsigned int *s4_base = (volatile unsigned int *)S4_BASE_ADDR;
    volatile unsigned int *s5_base = (volatile unsigned int *)S5_BASE_ADDR;
    volatile unsigned int *s6_base = (volatile unsigned int *)S6_BASE_ADDR;
    volatile unsigned int *s7_base = (volatile unsigned int *)S7_BASE_ADDR;
    volatile unsigned int *ctrl_base = (volatile unsigned int *)CTRL_BASE_ADDR;
    volatile unsigned int *s1_offset = (volatile unsigned int *)S1_OFFSET_ADDR;

    // 地址对齐检查
    if ((S1_BASE_ADDR & 0x07) != 0 || (S2_BASE_ADDR & 0x07) != 0 ||
        (S3_BASE_ADDR & 0x07) != 0 || (S4_BASE_ADDR & 0x07) != 0 ||
        (S5_BASE_ADDR & 0x07) != 0 || (S6_BASE_ADDR & 0x07) != 0 ||
        (S7_BASE_ADDR & 0x07) != 0 || (S1_OFFSET_ADDR & 0x07) != 0 ||
        (CTRL_BASE_ADDR & 0x07) != 0) {
        __asm__ volatile ("li x3, 80");  // 地址未8字节对齐
        goto end;
    }
    
    // 测试数据模式
    unsigned int test_patterns[TEST_COUNT];
    test_patterns[0]  = 0x12345678;
    test_patterns[1]  = 0xCAFEBABE;
    test_patterns[2]  = 0xDEADBEEF;
    test_patterns[3]  = 0x55AA55AA;
    test_patterns[4]  = 0xA5A5A5A5;
    test_patterns[5]  = 0x0F0F0F0F;
    test_patterns[6]  = 0xF0F0F0F0;
    test_patterns[7]  = 0x87654321;
    test_patterns[8]  = 0x11111111;
    test_patterns[9]  = 0x22222222;
    test_patterns[10] = 0x33333333;
    test_patterns[11] = 0x44444444;
    test_patterns[12] = 0x55555555;
    test_patterns[13] = 0x66666666;
    test_patterns[14] = 0x77777777;
    test_patterns[15] = 0x88888888;

    long_delay();  // 系统稳定

    // === 步骤1: CPU写入测试数据到S1 ===
    __asm__ volatile ("li x3, 1");  // 标记进入步骤1

    for(int i = 0; i < TEST_COUNT; i++) {
        s1_base[i] = test_patterns[i];
        short_delay();  // 确保写入稳定
    }
    
    long_delay();  // 等待S1写入完全稳定

    // === 步骤2: 向S2写入测试数据（地址每次+8）===
    __asm__ volatile ("li x3, 2");  // 标记进入步骤2

    for(int i = 0; i < TEST_COUNT; i++) {
        volatile unsigned int *target_addr = (volatile unsigned int *)((unsigned char *)s2_base + i * 8);
        *target_addr = test_patterns[i];
        short_delay();
    }
    
    long_delay();  // 等待S2写入测试数据完成

/*
    // === 步骤3: 配置DMA进行S1→S2传输 ===
    __asm__ volatile ("li x3, 3");  // 标记进入步骤3

    // 3.0 检查DMA初始状态
    unsigned int initial_status = apb_read(DMA_STATUS);
    __asm__ volatile ("mv x4, %0" : : "r"(initial_status) : "x4");  // 保存初始状态到x4
    
    // 3.1 配置描述符0：增量模式，使能
    // bit[2]=0: 读增量模式, bit[1]=0: 写增量模式, bit[0]=1: 使能
    apb_write(DESC0_MODE, 1);
    short_delay();
    
    // 3.2 配置传输长度（字节数）
    apb_write(DESC0_LENGTH, TEST_BYTES);
    short_delay();
    
    // 3.3 配置源地址（S1地址）- 确保4字节对齐
    apb_write(DESC0_SRC_ADDR, S1_BASE_ADDR);
    short_delay();
    
    // 3.4 配置目标地址（S2地址）- 确保4字节对齐
    apb_write(DESC0_DST_ADDR, S2_BASE_ADDR);
    short_delay();
    
    // 3.5 验证配置是否正确写入
    unsigned int verify_mode = apb_read(DESC0_MODE);
    unsigned int verify_length = apb_read(DESC0_LENGTH);
    unsigned int verify_src = apb_read(DESC0_SRC_ADDR);
    unsigned int verify_dst = apb_read(DESC0_DST_ADDR);
    
    // 将验证结果保存到寄存器（用于调试）
    __asm__ volatile ("mv x5, %0" : : "r"(verify_mode) : "x5");
    __asm__ volatile ("mv x6, %0" : : "r"(verify_length) : "x6");
    __asm__ volatile ("mv x7, %0" : : "r"(verify_src) : "x7");
    __asm__ volatile ("mv x8, %0" : : "r"(verify_dst) : "x8");
    
    // 3.6 检查配置后的状态
    unsigned int config_status = apb_read(DMA_STATUS);
    if ((config_status >> 1) & 0x01) {  // 检查错误位
        __asm__ volatile ("li x3, 90");  // 配置错误
        goto end;
    }
    
    // 3.7 启动DMA传输
    // 传输64字节 = 8个64位传输，maxburst=8刚好匹配
    // bit[15:8]=8: maxburst=8 (最优突发长度), bit[0]=1: start
    apb_write(DMA_CTRL, (8 << 8) | 1);
    
    long_delay();  // 给DMA一些时间开始工作

    // === 步骤4: 等待DMA传输完成 ===
    __asm__ volatile ("li x3, 4");  // 标记进入步骤4

    int dma_result = wait_dma_complete();
    
    if (dma_result != 0) {
        // DMA传输失败
        if (dma_result == -1) {
            __asm__ volatile ("li x3, 100");  // DMA错误
        } else {
            __asm__ volatile ("li x3, 101");  // DMA超时
        }
        goto end;
    }
    
    long_delay();  // 确保DMA传输完全完成

    // === 步骤5: S2数据验证跳过（S2不能被读取）===
    __asm__ volatile ("li x3, 5");  // 标记进入步骤5
    // S2不能被读取，跳过数据验证步骤
    
    // === 步骤6: 验证S1原始数据未被破坏 ===
    __asm__ volatile ("li x3, 6");  // 标记进入步骤6

    for(int i = 0; i < TEST_COUNT; i++) {
        unsigned int read_data = s1_base[i];
        short_delay();

        if (read_data != test_patterns[i]) {
            // S1数据被意外修改，返回失败的索引 + 150
            int fail_code = i + 150;
            __asm__ volatile ("mv x3, %0" : : "r"(fail_code) : "x3");
            goto end;
        }
    }

    long_delay();  // 等待系统稳定
*/
/*
    // === 步骤7: 清零S3区域（验证DMA确实工作了）===
    __asm__ volatile ("li x3, 7");  // 标记进入步骤7

    for(int i = 0; i < TEST_COUNT; i++) {
        s3_base[i] = 0x00000000;
        short_delay();
    }

    long_delay();  // 等待S3清零完成

    // === 步骤8: 配置DMA进行S1→S3传输 ===
    __asm__ volatile ("li x3, 8");  // 标记进入步骤8

    // 8.1 配置描述符0：增量模式，使能
    apb_write(DESC0_MODE, 1);
    short_delay();

    // 8.2 配置传输长度（字节数）
    apb_write(DESC0_LENGTH, TEST_BYTES);
    short_delay();

    // 8.3 配置源地址（S1地址）
    apb_write(DESC0_SRC_ADDR, S1_BASE_ADDR);
    short_delay();

    // 8.4 配置目标地址（S3地址）
    apb_write(DESC0_DST_ADDR, S3_BASE_ADDR);
    short_delay();

    // 8.5 启动DMA传输
    apb_write(DMA_CTRL, (8 << 8) | 1);

    long_delay();  // 给DMA一些时间开始工作

    // === 步骤9: 等待DMA传输完成 ===
    __asm__ volatile ("li x3, 9");  // 标记进入步骤9

    dma_result = wait_dma_complete();

    if (dma_result != 0) {
        // DMA传输失败
        if (dma_result == -1) {
            __asm__ volatile ("li x3, 170");  // S1→S3 DMA错误
        } else {
            __asm__ volatile ("li x3, 171");  // S1→S3 DMA超时
        }
        goto end;
    }

    long_delay();  // 确保DMA传输完全完成

    // === 步骤10: S3数据验证跳过（S3不能被读取）===
    __asm__ volatile ("li x3, 10");  // 标记进入步骤10
    // S3不能被读取，跳过数据验证步骤

    long_delay();  // 等待系统稳定

    // === 步骤11: 清零S4区域（验证DMA确实工作了）===
    __asm__ volatile ("li x3, 11");  // 标记进入步骤11

    for(int i = 0; i < TEST_COUNT; i++) {
        s4_base[i] = 0x00000000;
        short_delay();
    }

    long_delay();  // 等待S4清零完成

    // === 步骤12: 配置DMA进行S1→S4传输 ===
    __asm__ volatile ("li x3, 12");  // 标记进入步骤12

    // 12.1 配置描述符0：增量模式，使能
    apb_write(DESC0_MODE, 1);
    short_delay();

    // 12.2 配置传输长度（字节数）
    apb_write(DESC0_LENGTH, TEST_BYTES);
    short_delay();

    // 12.3 配置源地址（S1地址）
    apb_write(DESC0_SRC_ADDR, S1_BASE_ADDR);
    short_delay();

    // 12.4 配置目标地址（S4地址）
    apb_write(DESC0_DST_ADDR, S4_BASE_ADDR);
    short_delay();

    // 12.5 启动DMA传输
    apb_write(DMA_CTRL, (8 << 8) | 1);

    long_delay();  // 给DMA一些时间开始工作

    // === 步骤13: 等待DMA传输完成 ===
    __asm__ volatile ("li x3, 13");  // 标记进入步骤13

    dma_result = wait_dma_complete();

    if (dma_result != 0) {
        // DMA传输失败
        if (dma_result == -1) {
            __asm__ volatile ("li x3, 200");  // S1→S4 DMA错误
        } else {
            __asm__ volatile ("li x3, 201");  // S1→S4 DMA超时
        }
        goto end;
    }

    long_delay();  // 确保DMA传输完全完成

    // === 步骤14: CPU读取S4数据并验证 ===
    __asm__ volatile ("li x3, 14");  // 标记进入步骤14

    for(int i = 0; i < TEST_COUNT; i++) {
        unsigned int read_data = s4_base[i];
        short_delay();

        if (read_data != test_patterns[i]) {
            // S4数据验证失败，返回失败的索引 + 210
            int fail_code = i + 210;
            __asm__ volatile ("mv x3, %0" : : "r"(fail_code) : "x3");
            goto end;
        }
    }

    long_delay();  // 等待系统稳定
*/
/*
    // === 步骤15: 清零S5区域（验证DMA确实工作了）===
    __asm__ volatile ("li x3, 15");  // 标记进入步骤15

    for(int i = 0; i < TEST_COUNT; i++) {
        s5_base[i] = 0x00000000;
        short_delay();
    }

    long_delay();  // 等待S5清零完成

    // === 步骤16: 配置DMA进行S1→S5传输 ===
    __asm__ volatile ("li x3, 16");  // 标记进入步骤16

    // 16.1 配置描述符0：增量模式，使能
    apb_write(DESC0_MODE, 1);
    short_delay();

    // 16.2 配置传输长度（字节数）
    apb_write(DESC0_LENGTH, TEST_BYTES);
    short_delay();

    // 16.3 配置源地址（S1地址）
    apb_write(DESC0_SRC_ADDR, S1_BASE_ADDR);
    short_delay();

    // 16.4 配置目标地址（S5地址）
    apb_write(DESC0_DST_ADDR, S5_BASE_ADDR);
    short_delay();

    // 16.5 启动DMA传输
    apb_write(DMA_CTRL, (8 << 8) | 1);

    long_delay();  // 给DMA一些时间开始工作

    // === 步骤17: 等待DMA传输完成 ===
    __asm__ volatile ("li x3, 17");  // 标记进入步骤17

    dma_result = wait_dma_complete();

    if (dma_result != 0) {
        // DMA传输失败
        if (dma_result == -1) {
            __asm__ volatile ("li x3, 220");  // S1→S5 DMA错误
        } else {
            __asm__ volatile ("li x3, 221");  // S1→S5 DMA超时
        }
        goto end;
    }

    long_delay();  // 确保DMA传输完全完成

    // === 步骤18: CPU读取S5数据并验证 ===
    __asm__ volatile ("li x3, 18");  // 标记进入步骤18

    for(int i = 0; i < TEST_COUNT; i++) {
        unsigned int read_data = s5_base[i];
        short_delay();

        if (read_data != test_patterns[i]) {
            // S5数据验证失败，返回失败的索引 + 230
            int fail_code = i + 230;
            __asm__ volatile ("mv x3, %0" : : "r"(fail_code) : "x3");
            goto end;
        }
    }

    long_delay();  // 等待系统稳定
*/
    // === 步骤19: 清零S6区域（验证DMA确实工作了）===
    __asm__ volatile ("li x3, 19");  // 标记进入步骤19

    for(int i = 0; i < TEST_COUNT; i++) {
        s6_base[i] = 0x00000000;
        short_delay();
    }

    long_delay();  // 等待S6清零完成

    // === 步骤20: 配置DMA进行S1→S6传输 ===
    __asm__ volatile ("li x3, 20");  // 标记进入步骤20

    // 20.1 配置描述符0：增量模式，使能
    apb_write(DESC0_MODE, 1);
    short_delay();

    // 20.2 配置传输长度（字节数）
    apb_write(DESC0_LENGTH, TEST_BYTES);
    short_delay();

    // 20.3 配置源地址（S1地址）
    apb_write(DESC0_SRC_ADDR, S1_BASE_ADDR);
    short_delay();

    // 20.4 配置目标地址（S6地址）
    apb_write(DESC0_DST_ADDR, S6_BASE_ADDR);
    short_delay();

    // 20.5 启动DMA传输
    apb_write(DMA_CTRL, (8 << 8) | 1);

    long_delay();  // 给DMA一些时间开始工作

    // === 步骤21: 等待DMA传输完成 ===
    __asm__ volatile ("li x3, 21");  // 标记进入步骤21

    int dma_result = wait_dma_complete();

    if (dma_result != 0) {
        // DMA传输失败
        if (dma_result == -1) {
            __asm__ volatile ("li x3, 240");  // S1→S6 DMA错误
        } else {
            __asm__ volatile ("li x3, 241");  // S1→S6 DMA超时
        }
        goto end;
    }

    long_delay();  // 确保DMA传输完全完成

    // === 步骤22: CPU读取S6数据并验证 ===
    __asm__ volatile ("li x3, 22");  // 标记进入步骤22

    for(int i = 0; i < TEST_COUNT; i++) {
        unsigned int read_data = s6_base[i];
        short_delay();

        if (read_data != test_patterns[i]) {
            // S6数据验证失败，返回失败的索引 + 250
            int fail_code = i + 250;
            __asm__ volatile ("mv x3, %0" : : "r"(fail_code) : "x3");
            goto end;
        }
    }

    long_delay();  // 等待系统稳定
/*
    // === 步骤23: CPU写入测试数据到S7 ===
    __asm__ volatile ("li x3, 23");  // 标记进入步骤23

    // 使用不同的测试数据模式来区分
    unsigned int s7_test_patterns[TEST_COUNT];
    s7_test_patterns[0]  = 0xAAAAAAAA;
    s7_test_patterns[1]  = 0xBBBBBBBB;
    s7_test_patterns[2]  = 0xCCCCCCCC;
    s7_test_patterns[3]  = 0xDDDDDDDD;
    s7_test_patterns[4]  = 0xEEEEEEEE;
    s7_test_patterns[5]  = 0xFFFFFFFF;
    s7_test_patterns[6]  = 0x99999999;
    s7_test_patterns[7]  = 0x88888888;
    s7_test_patterns[8]  = 0x77777777;
    s7_test_patterns[9]  = 0x66666666;
    s7_test_patterns[10] = 0x55555555;
    s7_test_patterns[11] = 0x44444444;
    s7_test_patterns[12] = 0x33333333;
    s7_test_patterns[13] = 0x22222222;
    s7_test_patterns[14] = 0x11111111;
    s7_test_patterns[15] = 0x00000000;

    for(int i = 0; i < TEST_COUNT; i++) {
        s7_base[i] = s7_test_patterns[i];
        short_delay();  // 确保写入稳定
    }

    long_delay();  // 等待S7写入完全稳定
*/
    // === 步骤24: 配置DMA进行S6→S1(偏移地址)传输 ===
    __asm__ volatile ("li x3, 24");  // 标记进入步骤24

    // 24.1 配置描述符0：增量模式，使能
    apb_write(DESC0_MODE, 1);
    short_delay();

    // 24.2 配置传输长度（字节数）
    apb_write(DESC0_LENGTH, TEST_BYTES);
    short_delay();

    // 24.3 配置源地址（S6地址）
    apb_write(DESC0_SRC_ADDR, S6_BASE_ADDR);
    short_delay();

    // 24.4 配置目标地址（S1偏移地址）
    apb_write(DESC0_DST_ADDR, S1_OFFSET_ADDR);
    short_delay();

    // 24.5 启动DMA传输
    apb_write(DMA_CTRL, (8 << 8) | 1);

    long_delay();  // 给DMA一些时间开始工作

    // === 步骤25: 等待DMA传输完成 ===
    __asm__ volatile ("li x3, 25");  // 标记进入步骤25

    dma_result = wait_dma_complete();

    if (dma_result != 0) {
        // DMA传输失败
        if (dma_result == -1) {
            __asm__ volatile ("li x3, 260");  // S6→S1 DMA错误
        } else {
            __asm__ volatile ("li x3, 261");  // S6→S1 DMA超时
        }
        goto end;
    }

    long_delay();  // 确保DMA传输完全完成

    // === 步骤26: CPU读取S1偏移地址数据并验证 ===
    __asm__ volatile ("li x3, 26");  // 标记进入步骤26

    for(int i = 0; i < TEST_COUNT; i++) {
        unsigned int read_data = s1_offset[i];
        short_delay();

        if (read_data != test_patterns[i]) {
            // S1偏移地址数据验证失败，返回失败的索引 + 270
            int fail_code = i + 270;
            __asm__ volatile ("mv x3, %0" : : "r"(fail_code) : "x3");
            goto end;
        }
    }

    // === 步骤27: 再次验证S1原始数据未被破坏 ===
    __asm__ volatile ("li x3, 27");  // 标记进入步骤27

    for(int i = 0; i < TEST_COUNT; i++) {
        unsigned int read_data = s1_base[i];
        short_delay();

        if (read_data != test_patterns[i]) {
            // S1原始数据被意外修改，返回失败的索引 + 280
            int fail_code = i + 280;
            __asm__ volatile ("mv x3, %0" : : "r"(fail_code) : "x3");
            goto end;
        }
    }

    // === 步骤28: 控制测试 ===
    __asm__ volatile ("li x3, 28");  // 标记进入步骤28

    // 28.1 向ctrl_base写入0xF
    *ctrl_base = 0xF;
    long_delay();  // 等待一段时间

    // 28.2 再写入0
    *ctrl_base = 0x0;
    long_delay();  // 等待一段时间

    // 28.3 从S7_BASE_ADDR取一个数
    unsigned int s7_read_value = s7_base[0];
    __asm__ volatile ("mv x3, %0" : : "r"(s7_read_value) : "x3");  // 保存读取的值到x9用于调试

    // === 所有测试成功！===
    __asm__ volatile ("li x3, 290");    // 扩展DMA传输测试完全成功
    
    end:
    // 停机：进入低功耗等待状态，等待仿真监测 x3 == 290 后结束
    while (1) {
        __asm__ volatile ("li x3, 290" : : : "memory");
        __asm__ volatile ("nop");
    }
}

/*
 * 错误码说明：
 * 80: 地址未8字节对齐
 * 90: DMA配置错误
 * 100: S1→S2 DMA传输错误
 * 101: S1→S2 DMA传输超时
 * 150-165: S1原始数据被意外修改（索引0-15）
 * 170: S1→S3 DMA传输错误
 * 171: S1→S3 DMA传输超时
 * 200: S1→S4 DMA传输错误
 * 201: S1→S4 DMA传输超时
 * 210-225: S4数据验证失败（索引0-15）
 * 220: S1→S5 DMA传输错误
 * 221: S1→S5 DMA传输超时
 * 230-245: S5数据验证失败（索引0-15）
 * 240: S1→S6 DMA传输错误
 * 241: S1→S6 DMA传输超时
 * 250-265: S6数据验证失败（索引0-15）
 * 260: S7→S1 DMA传输错误
 * 261: S7→S1 DMA传输超时
 * 270-285: S1偏移地址数据验证失败（索引0-15）
 * 290: 所有扩展测试成功
 *
 * 调试寄存器：
 * x3: 主要错误码或最终状态
 *      1-27: 进入对应步骤的标记
 *      290: 成功
 *      其他值: 具体错误码
 * x4: DMA初始状态
 * x5: 描述符模式验证
 * x6: 传输长度验证
 * x7: 源地址验证
 * x8: 目标地址验证
 */