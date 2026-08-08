#include <stdint.h>
#include <stdarg.h>

// UART0寄存器地址定义 (根据e203处理器内存映射)
#define UART0_BASE_ADDR    0x10013000
#define UART1_BASE_ADDR    0x10023000  
#define UART2_BASE_ADDR    0x10033000

// UART寄存器偏移
#define UART_RBR_OFFSET    0x00  // 接收缓冲寄存器 (读取)
#define UART_THR_OFFSET    0x00  // 发送保持寄存器 (写入)
#define UART_DLL_OFFSET    0x00  // 除数锁存器低字节
#define UART_IER_OFFSET    0x04  // 中断使能寄存器
#define UART_DLM_OFFSET    0x04  // 除数锁存器高字节
#define UART_IIR_OFFSET    0x08  // 中断识别寄存器
#define UART_FCR_OFFSET    0x08  // FIFO控制寄存器
#define UART_LCR_OFFSET    0x0C  // 线路控制寄存器
#define UART_MCR_OFFSET    0x10  // 调制解调器控制寄存器
#define UART_LSR_OFFSET    0x14  // 线路状态寄存器
#define UART_MSR_OFFSET    0x18  // 调制解调器状态寄存器
#define UART_SCR_OFFSET    0x1C  // 暂存寄存器

// UART寄存器操作宏
#define UART_REG(base, offset) (*(volatile uint32_t*)((base) + (offset)))

// 线路控制寄存器位定义
#define UART_LCR_DLAB      (1 << 7)  // 除数锁存器访问位
#define UART_LCR_8BITS     (3 << 0)  // 8位数据位

// 线路状态寄存器位定义
#define UART_LSR_THRE      (1 << 5)  // 发送保持寄存器空
#define UART_LSR_DR        (1 << 0)  // 数据准备就绪

// GPIO寄存器定义 (用于配置UART引脚功能)
#define GPIO_BASE_ADDR     0x10012000
#define GPIO_IOF_EN_OFFSET 0x1C   // IOF配置寄存器 (修复: 原来是0x38，错误)
#define GPIO_PADDIR_OFFSET 0x00   // GPIO方向寄存器

/**
 * 延时函数
 */
void delay_ms(uint32_t ms) {
    // 简单的延时循环，实际时间取决于时钟频率
    for(uint32_t i = 0; i < ms * 1000; i++) {
        __asm__ volatile ("nop");
    }
}

/**
 * UART初始化函数
 * @param uart_base UART基地址
 * @param baudrate 波特率 (例如: 115200)
 */
void uart_init(uint32_t uart_base, uint32_t baudrate) {
    // 计算波特率除数 (假设时钟频率为16MHz)
    uint32_t clk_freq = 16000000;  // 16MHz
    uint32_t divisor = clk_freq / baudrate;
    
    // 设置线路控制寄存器: 8位数据，1停止位，无奇偶校验
    UART_REG(uart_base, UART_LCR_OFFSET) = UART_LCR_8BITS;
    
    // 设置DLAB位以访问除数锁存器
    UART_REG(uart_base, UART_LCR_OFFSET) |= UART_LCR_DLAB;
    
    // 设置波特率除数
    UART_REG(uart_base, UART_DLL_OFFSET) = divisor & 0xFF;        // 低字节
    UART_REG(uart_base, UART_DLM_OFFSET) = (divisor >> 8) & 0xFF; // 高字节
    
    // 清除DLAB位，恢复正常操作
    UART_REG(uart_base, UART_LCR_OFFSET) &= ~UART_LCR_DLAB;
    
    // 禁用中断
    UART_REG(uart_base, UART_IER_OFFSET) = 0x00;
    
    // 配置FIFO
    UART_REG(uart_base, UART_FCR_OFFSET) = 0x07; // 使能FIFO，清除FIFO
}

/**
 * 配置GPIO引脚为UART功能
 */
void uart_gpio_config(void) {
    // 关键修复：使用正确的IOF配置寄存器地址
    // 启用GPIO16和GPIO17的IOF功能（UART0 RX/TX）
    UART_REG(GPIO_BASE_ADDR, GPIO_IOF_EN_OFFSET) = (1 << 16) | (1 << 17);
    
    // 设置GPIO方向寄存器（虽然IOF会覆盖，但为了安全起见）
    uint32_t gpio_dir = UART_REG(GPIO_BASE_ADDR, GPIO_PADDIR_OFFSET);
    gpio_dir |= (1 << 17);   // GPIO17(TXD)设为输出
    gpio_dir &= ~(1 << 16);  // GPIO16(RXD)设为输入  
    UART_REG(GPIO_BASE_ADDR, GPIO_PADDIR_OFFSET) = gpio_dir;
}

/**
 * 发送单个字符
 * @param uart_base UART基地址
 * @param ch 要发送的字符
 */
void uart_putchar(uint32_t uart_base, char ch) {
    // 等待发送保持寄存器空
    while (!(UART_REG(uart_base, UART_LSR_OFFSET) & UART_LSR_THRE)) {
        // 等待
    }
    
    // 发送字符
    UART_REG(uart_base, UART_THR_OFFSET) = ch;
}

/**
 * 接收单个字符
 * @param uart_base UART基地址
 * @return 接收到的字符
 */
char uart_getchar(uint32_t uart_base) {
    // 等待数据准备就绪
    while (!(UART_REG(uart_base, UART_LSR_OFFSET) & UART_LSR_DR)) {
        // 等待
    }
    
    // 读取字符
    return (char)UART_REG(uart_base, UART_RBR_OFFSET);
}

/**
 * 发送字符串
 * @param uart_base UART基地址
 * @param str 要发送的字符串
 */
void uart_puts(uint32_t uart_base, const char* str) {
    while (*str) {
        uart_putchar(uart_base, *str++);
    }
}

/**
 * 简单的printf实现 (仅支持%d, %s, %c)
 */
void uart_printf(uint32_t uart_base, const char* format, ...) {
    const char* ptr = format;
    va_list args;
    va_start(args, format);
    
    while (*ptr) {
        if (*ptr == '%') {
            ptr++;
            switch (*ptr) {
                case 'd': {
                    int num = va_arg(args, int);
                    char buffer[12];
                    int i = 0;
                    if (num == 0) {
                        uart_putchar(uart_base, '0');
                    } else {
                        if (num < 0) {
                            uart_putchar(uart_base, '-');
                            num = -num;
                        }
                        while (num > 0) {
                            buffer[i++] = '0' + (num % 10);
                            num /= 10;
                        }
                        for (int j = i - 1; j >= 0; j--) {
                            uart_putchar(uart_base, buffer[j]);
                        }
                    }
                    break;
                }
                case 's': {
                    char* str = va_arg(args, char*);
                    uart_puts(uart_base, str);
                    break;
                }
                case 'c': {
                    char ch = va_arg(args, int);
                    uart_putchar(uart_base, ch);
                    break;
                }
                default:
                    uart_putchar(uart_base, *ptr);
                    break;
            }
        } else {
            uart_putchar(uart_base, *ptr);
        }
        ptr++;
    }
    
    va_end(args);
}

/**
 * 主函数 - UART通信测试
 */
int main(void) {
    // 配置GPIO引脚为UART功能
    uart_gpio_config();
    
    // 初始化UART0，波特率115200
    uart_init(UART0_BASE_ADDR, 115200);
    
    // 发送欢迎信息
    uart_puts(UART0_BASE_ADDR, "\r\n=== E203 UART Test ===\r\n");
    uart_puts(UART0_BASE_ADDR, "System Started\r\n");
    uart_puts(UART0_BASE_ADDR, "UART Test Ready\r\n\r\n");
    
    uint32_t counter = 0;
    
    // 立即发送一些测试字符
    uart_puts(UART0_BASE_ADDR, "Hello World!\r\n");
    uart_puts(UART0_BASE_ADDR, "UART Test 123\r\n");
    uart_printf(UART0_BASE_ADDR, "Counter: %d\r\n", 0);
    
    while (1) {
        counter++;

        // ---- 回显功能：有数据就读并立即发回 ----
        if (UART_REG(UART0_BASE_ADDR, UART_LSR_OFFSET) & UART_LSR_DR) {
            char ch = uart_getchar(UART0_BASE_ADDR);
            uart_putchar(UART0_BASE_ADDR, ch);  // 直接回显
        }
        
        // 每隔一段时间发送心跳信息
        if ((counter % 50000) == 0) {
            uart_printf(UART0_BASE_ADDR, "Heartbeat %d\r\n", counter / 50000);
        }
        
        // 简单延时
        for (volatile int i = 0; i < 100; i++);
        
        // 为了仿真测试，在一定次数后退出
        // if (counter > 1000000) {
        //     uart_puts(UART0_BASE_ADDR, "Test Complete!\r\n");
        //     break;
        // }
        // （可选）若仅用于仿真可退出；板上运行则不退出
    }
    
    return 0;
}

 