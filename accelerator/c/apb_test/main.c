/*
 * APB BRAM 连续写后连续读测试，，
 * 模式：连续写多个地址 → 休息 → 连续读多个地址并验证
 */



// 定义bram_0的基地址
#define APB_BASE_ADDR    0x00400000
#define TEST_COUNT       8  // 测试8个地址

// 定义bram_1的基地址
#define APB_BASE_ADDR1    0x00410000
// 定义bram_1的基地址
#define APB_BASE_ADDR2    0x00420000

// BRAM稳定延迟
void wait_bram_stable(void) {
    for(int i = 0; i < 20; i++) {
        __asm__ volatile ("nop");
        __asm__ volatile ("nop");
        __asm__ volatile ("nop");
        __asm__ volatile ("nop");
    }
}

// 更长的休息延迟
void long_delay(void) {
    for(int i = 0; i < 100; i++) {
        wait_bram_stable();
    }
}

int main(void)
{
    volatile unsigned int *apb_base = (volatile unsigned int *)APB_BASE_ADDR;

    // 定义指针指向APB_BASE_ADDR1
    volatile unsigned int *apb_base1 = (volatile unsigned int *)APB_BASE_ADDR1;

    // 定义指针指向APB_BASE_ADDR2
    volatile unsigned int *apb_base2 = (volatile unsigned int *)APB_BASE_ADDR2;
    
    // 预定义测试数据 - 避免数组初始化
    unsigned int test_patterns[TEST_COUNT];
    test_patterns[0] = 0x12345678;
    test_patterns[1] = 0xCAFEBABE;
    test_patterns[2] = 0xDEADBEEF;
    test_patterns[3] = 0x55AA55AA;
    test_patterns[4] = 0xA5A5A5A5;
    test_patterns[5] = 0x0F0F0F0F;
    test_patterns[6] = 0xF0F0F0F0;
    test_patterns[7] = 0x87654321;

    // 预定义测试数据 - 避免数组初始化，针对AXI_BASE_ADDR1
    unsigned int test_patterns1[TEST_COUNT];
    test_patterns1[0] = 0xA3F7C91D;
    test_patterns1[1] = 0x5B2E8D4A;
    test_patterns1[2] = 0xF94E37A2;
    test_patterns1[3] = 0xE149B376;
    test_patterns1[4] = 0x9D3A6F2C;
    test_patterns1[5] = 0x2F7A1E5B;
    test_patterns1[6] = 0xD46C9B3A;
    test_patterns1[7] = 0x61B5D2F8;

    // 预定义测试数据 - 避免数组初始化，针对AXI_BASE_ADDR2
    unsigned int test_patterns2[TEST_COUNT];
    test_patterns2[0] = 0x4A2F7C3E;
    test_patterns2[1] = 0x871F4D2E;
    test_patterns2[2] = 0xC52D8F1B;
    test_patterns2[3] = 0x2D9A5F3E;
    test_patterns2[4] = 0x7A9C4E2F;
    test_patterns2[5] = 0x3E6B9F7A;
    test_patterns2[6] = 0x9C7D2E6A;
    test_patterns2[7] = 0x1A3F7B9C;

    long_delay();  // 充分的休息时间

    // === 阶段1: 连续写操作 ===
    for(int i = 0; i < TEST_COUNT; i++) {
        apb_base[i] = test_patterns[i];  // 写入地址 i*4
    }

    //new === 阶段1: 连续写操作(写入APB_BASE_ADDR1) ===
    long_delay();  // 充分的休息时间
    for(int i = 0; i < TEST_COUNT; i++) {
        apb_base1[i] = test_patterns1[i];  // 写入地址 i*4
    }

    //new === 阶段1: 连续写操作(写入APB_BASE_ADDR2) ===
    long_delay();  // 充分的休息时间
    for(int i = 0; i < TEST_COUNT; i++) {
        apb_base2[i] = test_patterns2[i];  // 写入地址 i*4
    }
    
    // === 阶段2: 等待BRAM完全稳定 ===
    long_delay();  // 充分的休息时间
    
    // === 阶段3: 连续读操作并验证 ===
    for(int i = 0; i < TEST_COUNT; i++) {
        unsigned int read_data = apb_base[i];
        wait_bram_stable();
        wait_bram_stable();
        wait_bram_stable();
        wait_bram_stable();
        
        if (read_data != test_patterns[i]) {
            // 失败：返回失败的地址索引 + 10
            int fail_code = i + 10;
            __asm__ volatile ("mv x3, %0" : : "r"(fail_code) : "x3");
            goto end;
        }
    }

    //new: === 阶段3: 连续读操作并验证(针对AXI_BASE_ADDR1) ===
    for(int i = 0; i < TEST_COUNT; i++) {
        unsigned int read_data1 = apb_base1[i];
        wait_bram_stable();
        wait_bram_stable();
        wait_bram_stable();
        wait_bram_stable();
        
        if (read_data1 != test_patterns1[i]) {
            // 失败：返回失败的地址索引 + 10
            int fail_code = i + 10;
            __asm__ volatile ("mv x3, %0" : : "r"(fail_code) : "x3");
            goto end;
        }
    }

    //new: === 阶段3: 连续读操作并验证(针对AXI_BASE_ADDR2) ===
    for(int i = 0; i < TEST_COUNT; i++) {
        unsigned int read_data2 = apb_base2[i];
        wait_bram_stable();
        wait_bram_stable();
        wait_bram_stable();
        wait_bram_stable();
        
        if (read_data2 != test_patterns2[i]) {
            // 失败：返回失败的地址索引 + 10
            int fail_code = i + 10;
            __asm__ volatile ("mv x3, %0" : : "r"(fail_code) : "x3");
            goto end;
        }
    }
    
    // === 阶段4: 额外测试 - 随机顺序读取 ===
    // 反向读取验证
    for(int i = TEST_COUNT-1; i >= 0; i--) {
        unsigned int read_data = apb_base[i];
        
        if (read_data != test_patterns[i]) {
            // 失败：返回失败的地址索引 + 20 (反向测试失败)
            int fail_code = i + 20;
            __asm__ volatile ("mv x3, %0" : : "r"(fail_code) : "x3");
            goto end;
        }
    }

    // new: === 阶段4: 额外测试 - 随机顺序读取(针对AXI_BASE_ADDR1) ===
    // 反向读取验证
    for(int i = TEST_COUNT-1; i >= 0; i--) {
        unsigned int read_data1 = apb_base1[i];
        
        if (read_data1 != test_patterns1[i]) {
            // 失败：返回失败的地址索引 + 20 (反向测试失败)
            int fail_code = i + 20;
            __asm__ volatile ("mv x3, %0" : : "r"(fail_code) : "x3");
            goto end;
        }
    }

    // new: === 阶段4: 额外测试 - 随机顺序读取(针对AXI_BASE_ADDR2) ===
    // 反向读取验证
    for(int i = TEST_COUNT-1; i >= 0; i--) {
        unsigned int read_data2 = apb_base2[i];
        
        if (read_data2 != test_patterns2[i]) {
            // 失败：返回失败的地址索引 + 20 (反向测试失败)
            int fail_code = i + 20;
            __asm__ volatile ("mv x3, %0" : : "r"(fail_code) : "x3");
            goto end;
        }
    }
    
    // === 所有测试完全成功！===
    __asm__ volatile ("li x3, 200");    // 连续写读测试成功
    
    end:
    __asm__ volatile ("lui t0, 0x80000");
    __asm__ volatile ("addi t0, t0, 0x86");
    __asm__ volatile ("jr t0");
    
    while(1);
} 