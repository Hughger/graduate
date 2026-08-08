/*
 * DMA 传输测试
 * 测试流程：CPU写S1 → DMA搬运S1到S2 → CPU读S2验证
 *          → DMA搬运S1到S3 → CPU读S3验证
 *          → CPU写S4 → DMA搬运S4到S1(0x40000100) → CPU读S1验证
 *          → 测试特定地址写入读取
 * S1: 256MB BRAM (0x40000000)
 * S2: 1MB BRAM  (0x50000000)
 * S3: 1MB BRAM  (0x50100000)
 * S4: 1MB BRAM  (0x50200000)
 * S2测试地址:  (0x500F0000)
 * S3测试地址:  (0x501F0000)
 * S4测试地址:  (0x502F0000)
 * DMA APB接口: 0x00420000
 */

// 地址定义
#define S1_BASE_ADDR     0x40000000    // S1: 256MB BRAM
#define S2_BASE_ADDR     0x50010000    // S2: 1MB BRAM
#define S3_BASE_ADDR     0x50110000    // S3: 1MB BRAM
#define S4_BASE_ADDR     0x50210000    // S4: 1MB BRAM
#define S1_OFFSET_ADDR   0x40000100    // S1偏移地址，用于S4向S1写数据
#define S2_TEST_ADDR     0x500F0000    // S2测试地址：S2_BASE + 0xF0000
#define S3_TEST_ADDR     0x501F0000    // S3测试地址：S3_BASE + 0xF0000
#define S4_TEST_ADDR     0x502F0000    // S4测试地址：S4_BASE + 0xF0000
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
    volatile unsigned int *s1_offset = (volatile unsigned int *)S1_OFFSET_ADDR;

    // 地址对齐检查
    if ((S1_BASE_ADDR & 0x07) != 0 || (S2_BASE_ADDR & 0x07) != 0 ||
        (S3_BASE_ADDR & 0x07) != 0 || (S4_BASE_ADDR & 0x07) != 0 ||
        (S1_OFFSET_ADDR & 0x07) != 0 || (S2_TEST_ADDR & 0x07) != 0 ||
        (S3_TEST_ADDR & 0x07) != 0 || (S4_TEST_ADDR & 0x07) != 0) {
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

    // === 步骤2: 清零S2区域（验证DMA确实工作了）===
    __asm__ volatile ("li x3, 2");  // 标记进入步骤2

    for(int i = 0; i < TEST_COUNT; i++) {
        s2_base[i] = 0x00000000;
        short_delay();
    }
    
    long_delay();  // 等待S2清零完成

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

    // === 步骤5: CPU读取S2数据并验证 ===
    __asm__ volatile ("li x3, 5");  // 标记进入步骤5

    for(int i = 0; i < TEST_COUNT; i++) {
        unsigned int read_data = s2_base[i];
        short_delay();
        
        if (read_data != test_patterns[i]) {
            // 数据不匹配，返回失败的索引 + 110
            int fail_code = i + 110;
            __asm__ volatile ("mv x3, %0" : : "r"(fail_code) : "x3");
            goto end;
        }
    }
    
    // === 步骤6: 反向验证（增强测试） ===
    __asm__ volatile ("li x3, 6");  // 标记进入步骤6

    for(int i = TEST_COUNT-1; i >= 0; i--) {
        unsigned int read_data = s2_base[i];
        short_delay();
        
        if (read_data != test_patterns[i]) {
            // 反向验证失败，返回失败的索引 + 130
            int fail_code = i + 130;
            __asm__ volatile ("mv x3, %0" : : "r"(fail_code) : "x3");
            goto end;
        }
    }
    
    // === 步骤7: 验证S1原始数据未被破坏 ===
    __asm__ volatile ("li x3, 7");  // 标记进入步骤7

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

    // === 步骤8: 清零S3区域（验证DMA确实工作了）===
    __asm__ volatile ("li x3, 8");  // 标记进入步骤8

    for(int i = 0; i < TEST_COUNT; i++) {
        s3_base[i] = 0x00000000;
        short_delay();
    }

    long_delay();  // 等待S3清零完成

    // === 步骤9: 配置DMA进行S1→S3传输 ===
    __asm__ volatile ("li x3, 9");  // 标记进入步骤9

    // 9.1 配置描述符0：增量模式，使能
    apb_write(DESC0_MODE, 1);
    short_delay();

    // 9.2 配置传输长度（字节数）
    apb_write(DESC0_LENGTH, TEST_BYTES);
    short_delay();

    // 9.3 配置源地址（S1地址）
    apb_write(DESC0_SRC_ADDR, S1_BASE_ADDR);
    short_delay();

    // 9.4 配置目标地址（S3地址）
    apb_write(DESC0_DST_ADDR, S3_BASE_ADDR);
    short_delay();

    // 9.5 启动DMA传输
    apb_write(DMA_CTRL, (8 << 8) | 1);

    long_delay();  // 给DMA一些时间开始工作

    // === 步骤10: 等待DMA传输完成 ===
    __asm__ volatile ("li x3, 10");  // 标记进入步骤10

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

    // === 步骤11: CPU读取S3数据并验证 ===
    __asm__ volatile ("li x3, 11");  // 标记进入步骤11

    for(int i = 0; i < TEST_COUNT; i++) {
        unsigned int read_data = s3_base[i];
        short_delay();

        if (read_data != test_patterns[i]) {
            // S3数据验证失败，返回失败的索引 + 180
            int fail_code = i + 180;
            __asm__ volatile ("mv x3, %0" : : "r"(fail_code) : "x3");
            goto end;
        }
    }

    long_delay();  // 等待系统稳定

    // === 步骤12: CPU写入测试数据到S4 ===
    __asm__ volatile ("li x3, 12");  // 标记进入步骤12

    // 使用不同的测试数据模式来区分
    unsigned int s4_test_patterns[TEST_COUNT];
    s4_test_patterns[0]  = 0xAAAAAAAA;
    s4_test_patterns[1]  = 0xBBBBBBBB;
    s4_test_patterns[2]  = 0xCCCCCCCC;
    s4_test_patterns[3]  = 0xDDDDDDDD;
    s4_test_patterns[4]  = 0xEEEEEEEE;
    s4_test_patterns[5]  = 0xFFFFFFFF;
    s4_test_patterns[6]  = 0x99999999;
    s4_test_patterns[7]  = 0x88888888;
    s4_test_patterns[8]  = 0x77777777;
    s4_test_patterns[9]  = 0x66666666;
    s4_test_patterns[10] = 0x55555555;
    s4_test_patterns[11] = 0x44444444;
    s4_test_patterns[12] = 0x33333333;
    s4_test_patterns[13] = 0x22222222;
    s4_test_patterns[14] = 0x11111111;
    s4_test_patterns[15] = 0x00000000;

    for(int i = 0; i < TEST_COUNT; i++) {
        s4_base[i] = s4_test_patterns[i];
        short_delay();  // 确保写入稳定
    }

    long_delay();  // 等待S4写入完全稳定

    // === 步骤13: 配置DMA进行S4→S1(偏移地址)传输 ===
    __asm__ volatile ("li x3, 13");  // 标记进入步骤13

    // 13.1 配置描述符0：增量模式，使能
    apb_write(DESC0_MODE, 1);
    short_delay();

    // 13.2 配置传输长度（字节数）
    apb_write(DESC0_LENGTH, TEST_BYTES);
    short_delay();

    // 13.3 配置源地址（S4地址）
    apb_write(DESC0_SRC_ADDR, S4_BASE_ADDR);
    short_delay();

    // 13.4 配置目标地址（S1偏移地址）
    apb_write(DESC0_DST_ADDR, S1_OFFSET_ADDR);
    short_delay();

    // 13.5 启动DMA传输
    apb_write(DMA_CTRL, (8 << 8) | 1);

    long_delay();  // 给DMA一些时间开始工作

    // === 步骤14: 等待DMA传输完成 ===
    __asm__ volatile ("li x3, 14");  // 标记进入步骤14

    dma_result = wait_dma_complete();

    if (dma_result != 0) {
        // DMA传输失败
        if (dma_result == -1) {
            __asm__ volatile ("li x3, 190");  // S4→S1 DMA错误
        } else {
            __asm__ volatile ("li x3, 191");  // S4→S1 DMA超时
        }
        goto end;
    }

    long_delay();  // 确保DMA传输完全完成

    // === 步骤15: CPU读取S1偏移地址数据并验证 ===
    __asm__ volatile ("li x3, 15");  // 标记进入步骤15

    for(int i = 0; i < TEST_COUNT; i++) {
        unsigned int read_data = s1_offset[i];
        short_delay();

        if (read_data != s4_test_patterns[i]) {
            // S1偏移地址数据验证失败，返回失败的索引 + 200
            int fail_code = i + 200;
            __asm__ volatile ("mv x3, %0" : : "r"(fail_code) : "x3");
            goto end;
        }
    }

    // === 步骤16: 再次验证S1原始数据未被破坏 ===
    __asm__ volatile ("li x3, 16");  // 标记进入步骤16

    for(int i = 0; i < TEST_COUNT; i++) {
        unsigned int read_data = s1_base[i];
        short_delay();

        if (read_data != test_patterns[i]) {
            // S1原始数据被意外修改，返回失败的索引 + 220
            int fail_code = i + 220;
            __asm__ volatile ("mv x3, %0" : : "r"(fail_code) : "x3");
            goto end;
        }
    }

    // === 步骤17: 测试特定地址写入和读取 ===
    __asm__ volatile ("li x3, 17");  // 标记进入步骤17

    // 17.1 依次向偏移地址写入0x1
    volatile unsigned int *s2_test = (volatile unsigned int *)S2_TEST_ADDR;
    volatile unsigned int *s3_test = (volatile unsigned int *)S3_TEST_ADDR;
    volatile unsigned int *s4_test = (volatile unsigned int *)S4_TEST_ADDR;

    *s2_test = 0x2;
    short_delay();
    *s3_test = 0x2;
    short_delay();
    *s4_test = 0x2;
    short_delay();

    // 17.2 依次向偏移地址写入0x0
    *s2_test = 0x0;
    short_delay();
    *s3_test = 0x0;
    short_delay();
    *s4_test = 0x0;
    short_delay();

    // 17.3 依次读取基地址，验证是否为0x6666
    unsigned int s2_value = *s2_base;
    short_delay();
    if (s2_value != 0x6666) {
        __asm__ volatile ("li x3, 240");  // S2基地址读取失败
        goto end;
    }

    unsigned int s3_value = *s3_base;
    short_delay();
    if (s3_value != 0x6666) {
        __asm__ volatile ("li x3, 241");  // S3基地址读取失败
        goto end;
    }

    unsigned int s4_value = *s4_base;
    short_delay();
    if (s4_value != 0x6666) {
        __asm__ volatile ("li x3, 242");  // S4基地址读取失败
        goto end;
    }

    // === 所有测试成功！===
    __asm__ volatile ("li x3, 250");    // 扩展DMA传输测试完全成功
    
    end:
    // 停机：进入低功耗等待状态，等待仿真监测 x3 == 250 后结束
    while (1) {
        __asm__ volatile ("li x3, 250" : : : "memory");
        __asm__ volatile ("nop");
    }
}

/*
 * 错误码说明：
 * 80: 地址未8字节对齐
 * 90: DMA配置错误
 * 100: DMA传输错误
 * 101: DMA传输超时
 * 110-125: S2数据验证失败（索引0-15）
 * 130-145: S2反向验证失败（索引15-0）
 * 150-165: S1原始数据被意外修改（索引0-15）
 * 170: S1→S3 DMA传输错误
 * 171: S1→S3 DMA传输超时
 * 180-195: S3数据验证失败（索引0-15）
 * 190: S4→S1 DMA传输错误
 * 191: S4→S1 DMA传输超时
 * 200-215: S1偏移地址数据验证失败（索引0-15）
 * 220-235: S1原始数据被意外修改（索引0-15）
 * 240: S2基地址读取值不是0x6666
 * 241: S3基地址读取值不是0x6666
 * 242: S4基地址读取值不是0x6666
 * 250: 所有扩展测试成功
 *
 * 调试寄存器：
 * x3: 主要错误码或最终状态
 *      1-17: 进入对应步骤的标记
 *      250: 成功
 *      其他值: 具体错误码
 * x4: DMA初始状态
 * x5: 描述符模式验证
 * x6: 传输长度验证
 * x7: 源地址验证
 * x8: 目标地址验证
 */
