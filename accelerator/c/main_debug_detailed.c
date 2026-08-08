#include <stdint.h>

#define AXI_BASE 0x40000000

// 简单延时函数
void delay(int cycles) {
    for(volatile int i = 0; i < cycles; i++) {
        asm volatile ("nop");
    }
}

int main() {
    volatile uint32_t *axi_ptr = (volatile uint32_t *)AXI_BASE;
    uint32_t test_data = 0x12345678;
    uint32_t rdata;
    
    // 测试1: 地址0x0
    axi_ptr[0] = test_data;  // 写地址0x0
    delay(100);              // 添加延时
    rdata = axi_ptr[0];      // 读地址0x0
    
    if (rdata != test_data) {
        asm volatile ("li x3, 1; j end");  // 失败
    }
    
    // 测试2: 地址0x4 (单独测试)
    delay(100);
    test_data = 0xABCDEF00;
    axi_ptr[1] = test_data;  // 写地址0x4
    delay(100);              // 更长延时
    rdata = axi_ptr[1];      // 读地址0x4
    
    if (rdata != test_data) {
        asm volatile ("li x3, 2; j end");  // 失败在地址0x4
    }
    
    // 测试3: 地址0x8
    delay(100);
    test_data = 0x55AA55AA;
    axi_ptr[2] = test_data;  // 写地址0x8
    delay(100);
    rdata = axi_ptr[2];      // 读地址0x8
    
    if (rdata != test_data) {
        asm volatile ("li x3, 3; j end");  // 失败在地址0x8
    }
    
    // 所有测试通过
    asm volatile ("li x3, 100; j end");
    
    end:
    while(1);
    return 0;
} 