#include <stdint.h>
#include <stdarg.h>
#include <stddef.h>

/************************ 简易 libc 支持 ************************/
void *memcpy(void *dest, const void *src, size_t n)
{
    unsigned char       *d = (unsigned char *)dest;
    const unsigned char *s = (const unsigned char *)src;
    while (n--) {
        *d++ = *s++;
    }
    return dest;
}

/************************ UART 定义 ************************/
#define UART0_BASE_ADDR    0x10013000U

/* 寄存器偏移 */
#define UART_RBR_OFFSET    0x00U
#define UART_THR_OFFSET    0x00U
#define UART_DLL_OFFSET    0x00U
#define UART_IER_OFFSET    0x04U
#define UART_DLM_OFFSET    0x04U
#define UART_IIR_OFFSET    0x08U
#define UART_FCR_OFFSET    0x08U
#define UART_LCR_OFFSET    0x0CU
#define UART_LSR_OFFSET    0x14U

/* UART_LCR 位 */
#define UART_LCR_DLAB      (1U << 7)
#define UART_LCR_8BITS     (3U << 0)

/* UART_LSR 位 */
#define UART_LSR_THRE      (1U << 5)
#define UART_LSR_DR        (1U << 0)

/* GPIO 用于 UART IOF 选择 */
#define GPIO_BASE_ADDR     0x10012000U
#define GPIO_IOF_EN_OFFSET 0x1CU
#define GPIO_PADDIR_OFFSET 0x00U

#define REG32(base, off)   (*(volatile uint32_t *)((base) + (off)))

static void uart_gpio_config(void)
{
    REG32(GPIO_BASE_ADDR, GPIO_IOF_EN_OFFSET) |= (1U << 16) | (1U << 17);
    uint32_t dir = REG32(GPIO_BASE_ADDR, GPIO_PADDIR_OFFSET);
    dir |=  (1U << 17);
    dir &= ~(1U << 16);
    REG32(GPIO_BASE_ADDR, GPIO_PADDIR_OFFSET) = dir;
}

static void uart_init(uint32_t uart_base, uint32_t baudrate)
{
    uint32_t clk_freq = 16000000U;
    uint32_t divisor  = clk_freq / baudrate;

    REG32(uart_base, UART_LCR_OFFSET) = UART_LCR_8BITS;
    REG32(uart_base, UART_LCR_OFFSET) |= UART_LCR_DLAB;
    REG32(uart_base, UART_DLL_OFFSET)  = divisor & 0xFFU;
    REG32(uart_base, UART_DLM_OFFSET)  = (divisor >> 8) & 0xFFU;
    REG32(uart_base, UART_LCR_OFFSET) &= ~UART_LCR_DLAB;
    REG32(uart_base, UART_IER_OFFSET)  = 0U;
    REG32(uart_base, UART_FCR_OFFSET)  = 0x07U;
}

static void uart_putchar(uint32_t uart_base, char ch)
{
    while (!(REG32(uart_base, UART_LSR_OFFSET) & UART_LSR_THRE)) {
        /* wait */
    }
    REG32(uart_base, UART_THR_OFFSET) = (uint32_t)ch;
}

static void uart_puts(uint32_t uart_base, const char *str)
{
    while (*str) {
        uart_putchar(uart_base, *str++);
    }
}

static void uart_printf(uint32_t uart_base, const char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    for (const char *p = fmt; *p; p++) {
        if (*p != '%') {
            uart_putchar(uart_base, *p);
            continue;
        }
        p++;
        switch (*p) {
        case 'd': {
            int val = va_arg(ap, int);
            char buf[12];
            int idx = 0;
            if (val == 0) {
                buf[idx++] = '0';
            } else {
                if (val < 0) {
                    uart_putchar(uart_base, '-');
                    val = -val;
                }
                while (val > 0) {
                    buf[idx++] = '0' + (val % 10);
                    val /= 10;
                }
            }
            while (idx--) uart_putchar(uart_base, buf[idx]);
            break;
        }
        case 'x': {
            unsigned int val = va_arg(ap, unsigned int);
            char buf[8];
            int idx = 0;
            if (val == 0) buf[idx++] = '0';
            while (val && idx < 8) {
                uint8_t d = val & 0xF;
                buf[idx++] = (d < 10) ? ('0' + d) : ('A' + d - 10);
                val >>= 4;
            }
            while (idx--) uart_putchar(uart_base, buf[idx]);
            break;
        }
        case 'c': {
            char ch = (char)va_arg(ap, int);
            uart_putchar(uart_base, ch);
            break;
        }
        case 's': {
            const char *s = va_arg(ap, const char *);
            uart_puts(uart_base, s);
            break;
        }
        default:
            uart_putchar(uart_base, *p);
            break;
        }
    }
    va_end(ap);
}

/************************ DMA & 测试相关定义 ************************/
#define S1_BASE_ADDR     0x40000000U
#define S2_BASE_ADDR     0x50000000U
#define DMA_APB_BASE     0x00420000U

/* DMA Reg Offsets */
#define DMA_CTRL         0x00U
#define DMA_STATUS       0x04U
#define DMA_ERR_CLR      0x08U
#define DESC0_MODE       0x20U
#define DESC0_LENGTH     0x24U
#define DESC0_SRC_ADDR   0x28U
#define DESC0_DST_ADDR   0x2CU

#define TEST_COUNT       16U
#define TEST_BYTES       (TEST_COUNT * 4U)

static inline void apb_write(uint32_t off, uint32_t data)
{
    *((volatile uint32_t *)(DMA_APB_BASE + off)) = data;
}

static inline uint32_t apb_read(uint32_t off)
{
    return *((volatile uint32_t *)(DMA_APB_BASE + off));
}

static inline void nop_delay(int cnt)
{
    while (cnt--) {
        __asm__ volatile("nop");
    }
}

static void short_delay(void) { nop_delay(100); }
static void long_delay(void)  { nop_delay(1000); }

static int wait_dma_complete(void)
{
    int timeout = 100000;
    while (timeout-- > 0) {
        uint32_t status = apb_read(DMA_STATUS);
        uint32_t dma_state = (status >> 2) & 0x3U;
        uint32_t dma_err   = (status >> 1) & 0x1U;
        uint32_t dma_done  =  status       & 0x1U;

        if (dma_err) {
            apb_write(DMA_ERR_CLR, 1U);
            return -1;
        }
        if (dma_state == 0x3U || dma_done) {
            apb_write(DMA_CTRL, (8U << 8)); /* clear start */
            return 0;
        }
        short_delay();
    }
    return -2;
}

int main(void)
{
    uart_gpio_config();
    uart_init(UART0_BASE_ADDR, 115200U);
    uart_puts(UART0_BASE_ADDR, "\r\n=== DMA Transfer Test (UART) ===\r\n");

    volatile uint32_t *s1 = (volatile uint32_t *)S1_BASE_ADDR;
    volatile uint32_t *s2 = (volatile uint32_t *)S2_BASE_ADDR;

    /* 准备测试数据 */
    uint32_t patterns[TEST_COUNT] = {
        0x12345678U, 0xCAFEBABEU, 0xDEADBEEFU, 0x55AA55AAU,
        0xA5A5A5A5U, 0x0F0F0F0FU, 0xF0F0F0F0U, 0x87654321U,
        0x11111111U, 0x22222222U, 0x33333333U, 0x44444444U,
        0x55555555U, 0x66666666U, 0x77777777U, 0x88888888U
    };

    long_delay();

    /* Step1: CPU 写 S1 */
    uart_puts(UART0_BASE_ADDR, "Step1: Writing S1...\r\n");
    for (uint32_t i = 0; i < TEST_COUNT; i++) {
        s1[i] = patterns[i];
        short_delay();
    }

    long_delay();

    /* Step2: 清零 S2 */
    uart_puts(UART0_BASE_ADDR, "Step2: Clearing S2...\r\n");
    for (uint32_t i = 0; i < TEST_COUNT; i++) {
        s2[i] = 0x0U;
        short_delay();
    }

    long_delay();

    /* Step3: 配置 DMA */
    uart_puts(UART0_BASE_ADDR, "Step3: Configuring DMA...\r\n");
    apb_write(DESC0_MODE, 1U);
    apb_write(DESC0_LENGTH, TEST_BYTES);
    apb_write(DESC0_SRC_ADDR, S1_BASE_ADDR);
    apb_write(DESC0_DST_ADDR, S2_BASE_ADDR);

    /* 启动 DMA */
    apb_write(DMA_CTRL, (8U << 8) | 1U);
    uart_puts(UART0_BASE_ADDR, "DMA started. Waiting...\r\n");

    int dma_ret = wait_dma_complete();
    if (dma_ret != 0) {
        if (dma_ret == -1) uart_puts(UART0_BASE_ADDR, "DMA error!\r\n");
        else               uart_puts(UART0_BASE_ADDR, "DMA timeout!\r\n");
        __asm__ volatile("li x3, 100");
        goto end;
    }
    uart_puts(UART0_BASE_ADDR, "DMA complete.\r\n");

    long_delay();

    /* Step4: 校验 S2 数据 */
    uart_puts(UART0_BASE_ADDR, "Step4: Verifying S2...\r\n");
    for (uint32_t i = 0; i < TEST_COUNT; i++) {
        uint32_t rd = s2[i];
        if (rd != patterns[i]) {
            uart_printf(UART0_BASE_ADDR, "Mismatch @%d exp 0x%x got 0x%x\r\n", i, patterns[i], rd);
            int fail_code = i + 110;
            __asm__ volatile("mv x3, %0" :: "r"(fail_code) : "x3");
            goto end;
        }
    }
    uart_puts(UART0_BASE_ADDR, "S2 verify OK.\r\n");

    /* Step5: 反向校验 S2 */
    uart_puts(UART0_BASE_ADDR, "Step5: Reverse verify S2...\r\n");
    for (int i = TEST_COUNT - 1; i >= 0; i--) {
        uint32_t rd = s2[i];
        if (rd != patterns[i]) {
            uart_printf(UART0_BASE_ADDR, "Rev mismatch @%d exp 0x%x got 0x%x\r\n", i, patterns[i], rd);
            int fail_code = i + 130;
            __asm__ volatile("mv x3, %0" :: "r"(fail_code) : "x3");
            goto end;
        }
    }
    uart_puts(UART0_BASE_ADDR, "Reverse verify OK.\r\n");

    /* Step6: 校验 S1 未被破坏 */
    uart_puts(UART0_BASE_ADDR, "Step6: Verifying S1 integrity...\r\n");
    for (uint32_t i = 0; i < TEST_COUNT; i++) {
        uint32_t rd = s1[i];
        if (rd != patterns[i]) {
            uart_printf(UART0_BASE_ADDR, "S1 corrupt @%d\r\n", i);
            int fail_code = i + 150;
            __asm__ volatile("mv x3, %0" :: "r"(fail_code) : "x3");
            goto end;
        }
    }

    uart_puts(UART0_BASE_ADDR, "All tests PASSED!\r\n");
    __asm__ volatile("li x3, 200");

end:
    while (1) {
        /* idle */
    }
    return 0;
}
