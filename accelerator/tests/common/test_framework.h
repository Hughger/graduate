/******************************************************************************
 * @file    test_framework.h
 * @brief   单元测试框架
 * @author  Test Group 3
 * @date    2026-05-22
 ******************************************************************************/

#ifndef TEST_FRAMEWORK_H
#define TEST_FRAMEWORK_H

#include <stdio.h>
#include <stdint.h>
#include <string.h>

#ifdef __cplusplus
extern "C" {
#endif

/******************************************************************************
 * 测试统计信息
 ******************************************************************************/
typedef struct {
    int total;          // 总测试数
    int passed;         // 通过数
    int failed;         // 失败数
    int skipped;        // 跳过数
} TestStats;

/******************************************************************************
 * 测试用例结构体
 ******************************************************************************/
typedef struct {
    const char* name;           // 测试名称
    const char* description;    // 测试描述
    int (*test_func)(void);     // 测试函数
    int enabled;                // 是否启用
} TestCase;

/******************************************************************************
 * 全局测试统计
 ******************************************************************************/
extern TestStats g_test_stats;

/******************************************************************************
 * 断言宏
 ******************************************************************************/

// 基础断言
#define TEST_ASSERT(condition) \
    do { \
        if (!(condition)) { \
            printf("  [FAIL] Assertion failed: %s (line %d)\n", #condition, __LINE__); \
            return -1; \
        } \
    } while(0)

// 相等断言
#define TEST_ASSERT_EQ(expected, actual) \
    do { \
        if ((expected) != (actual)) { \
            printf("  [FAIL] Expected %d, got %d (line %d)\n", \
                   (int)(expected), (int)(actual), __LINE__); \
            return -1; \
        } \
    } while(0)

// 浮点相等断言 (带误差)
#define TEST_ASSERT_FLOAT_EQ(expected, actual, epsilon) \
    do { \
        float diff = (expected) - (actual); \
        if (diff < 0) diff = -diff; \
        if (diff > (epsilon)) { \
            printf("  [FAIL] Expected %.6f, got %.6f (diff %.6f, line %d)\n", \
                   (float)(expected), (float)(actual), diff, __LINE__); \
            return -1; \
        } \
    } while(0)

// 非空断言
#define TEST_ASSERT_NOT_NULL(ptr) \
    do { \
        if ((ptr) == NULL) { \
            printf("  [FAIL] Pointer is NULL (line %d)\n", __LINE__); \
            return -1; \
        } \
    } while(0)

// 内存相等断言
#define TEST_ASSERT_MEM_EQ(expected, actual, size) \
    do { \
        if (memcmp((expected), (actual), (size)) != 0) { \
            printf("  [FAIL] Memory mismatch (size %d, line %d)\n", (int)(size), __LINE__); \
            return -1; \
        } \
    } while(0)

/******************************************************************************
 * 测试运行宏
 ******************************************************************************/

// 运行单个测试
#define TEST_RUN(test_func) \
    do { \
        printf("\n[TEST] %s\n", #test_func); \
        g_test_stats.total++; \
        int result = test_func(); \
        if (result == 0) { \
            printf("  [PASS] %s\n", #test_func); \
            g_test_stats.passed++; \
        } else { \
            printf("  [FAIL] %s\n", #test_func); \
            g_test_stats.failed++; \
        } \
    } while(0)

// 运行测试用例数组
#define TEST_RUN_SUITE(test_cases, count) \
    do { \
        for (int i = 0; i < (count); i++) { \
            if (test_cases[i].enabled) { \
                printf("\n[TEST] %s: %s\n", test_cases[i].name, test_cases[i].description); \
                g_test_stats.total++; \
                int result = test_cases[i].test_func(); \
                if (result == 0) { \
                    printf("  [PASS] %s\n", test_cases[i].name); \
                    g_test_stats.passed++; \
                } else { \
                    printf("  [FAIL] %s\n", test_cases[i].name); \
                    g_test_stats.failed++; \
                } \
            } else { \
                printf("\n[SKIP] %s\n", test_cases[i].name); \
                g_test_stats.skipped++; \
            } \
        } \
    } while(0)

/******************************************************************************
 * 测试报告函数
 ******************************************************************************/

/**
 * @brief 初始化测试统计
 */
static inline void test_init(void) {
    memset(&g_test_stats, 0, sizeof(g_test_stats));
}

/**
 * @brief 打印测试报告
 */
static inline void test_print_report(void) {
    printf("\n");
    printf("========================================\n");
    printf("           测试报告\n");
    printf("========================================\n");
    printf("总测试数:  %d\n", g_test_stats.total);
    printf("通过:      %d\n", g_test_stats.passed);
    printf("失败:      %d\n", g_test_stats.failed);
    printf("跳过:      %d\n", g_test_stats.skipped);
    printf("----------------------------------------\n");
    
    if (g_test_stats.failed == 0) {
        printf("结果: 全部通过 ✓\n");
    } else {
        printf("结果: 有测试失败 ✗\n");
    }
    printf("========================================\n");
}

/**
 * @brief 获取测试是否全部通过
 * @return 1 if all passed, 0 otherwise
 */
static inline int test_all_passed(void) {
    return (g_test_stats.failed == 0 && g_test_stats.total > 0);
}

/******************************************************************************
 * 测试主程序模板
 ******************************************************************************/

#define TEST_MAIN_BEGIN() \
    int main(void) { \
        printf("========================================\n"); \
        printf("       单元测试开始\n"); \
        printf("========================================\n"); \
        test_init();

#define TEST_MAIN_END() \
        test_print_report(); \
        return test_all_passed() ? 0 : -1; \
    }

#ifdef __cplusplus
}
#endif

#endif /* TEST_FRAMEWORK_H */
