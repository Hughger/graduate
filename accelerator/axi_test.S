# AXI接口汇编测试
# 测试地址：0x40000000

.section .text
.global _start

_start:
    # 设置测试数据
    li t0, 0x12345678      # 测试数据
    li t1, 0x40000000      # AXI基地址
    
    # 写入数据
    sw t0, 0(t1)           # 写入到AXI地址
    
    # 读取数据
    lw t2, 0(t1)           # 从AXI地址读取
    
    # 比较结果
    beq t0, t2, test_pass  # 如果相等则测试通过
    
    # 测试失败
    li a0, 1               # 返回值1表示失败
    j exit
    
test_pass:
    li a0, 0               # 返回值0表示成功
    
exit:
    # 系统调用退出（具体实现依赖于您的运行时环境）
    # 这里只是示例，实际使用时需要根据您的系统调整
    li a7, 93              # exit系统调用号
    ecall                  # 系统调用
    
.section .data
# 这里可以放置测试数据 