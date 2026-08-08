# AXI Test Project for E203 RISC-V Processor

## 项目概述

这是一个专为E203 RISC-V处理器设计的裸机C程序，用于测试AXI接口连通性。

## 内存布局

| 内存区域 | 起始地址 | 大小 | 用途 |
|---------|----------|------|------|
| ITCM | 0x80000000 | 64KB | 指令存储，程序代码 |
| DTCM | 0x90000000 | 64KB | 数据存储，变量和栈 |
| AXI目标 | 0x40000000 | - | 外设测试地址 |

## 文件结构

```
application/custom/axi_test/
├── main.c           # 主程序，AXI接口测试
├── startup.S        # 启动汇编代码
├── link.ld          # 自定义链接脚本
├── Makefile         # 构建脚本
└── README.md        # 项目说明
```

## 编译和运行

### 环境准备
```bash
# Windows环境下设置SDK环境
setup.bat
```

### 编译项目
```bash
cd application/custom/axi_test
make all
```

### 生成仿真文件
```bash
make sim
```

### 查看内存分布
```bash
make memmap
```

### 生成调试信息
```bash
make debug
```

## 输出文件

| 文件类型 | 文件名 | 用途 |
|---------|--------|------|
| ELF | axi_test.elf | 调试用可执行文件 |
| HEX | axi_test.hex | Intel HEX格式，用于$readmemh() |
| Verilog | axi_test.verilog | Verilog内存格式 |
| Binary | axi_test.bin | 纯二进制文件 |
| Dump | axi_test.dump | 反汇编文件 |

## $readmem系列函数区别

### $readmemh vs $readmemb

| 函数 | 格式 | 用途 | 示例 |
|------|------|------|------|
| `$readmemh` | 十六进制ASCII | 读取.hex文件 | `$readmemh("axi_test.hex", memory);` |
| `$readmemb` | 二进制ASCII | 读取二进制文本 | `$readmemb("data.txt", memory);` |

### 在Testbench中使用

```verilog
// 方法1：使用HEX文件
reg [31:0] itcm_memory [0:16383];  // 64KB ITCM
initial begin
    $readmemh("axi_test.hex", itcm_memory);
end

// 方法2：使用Verilog格式文件
reg [31:0] dtcm_memory [0:16383];  // 64KB DTCM  
initial begin
    $readmemh("axi_test.verilog", dtcm_memory);
end
```

## 测试内容

程序会执行以下AXI接口测试：

1. **基本读写测试**：向0x40000000写入0xDEADBEEF并读回验证
2. **不同模式测试**：向0x40000004写入0xCAFEBABE并读回验证  
3. **序列模式测试**：向0x40000008写入0x12345678并读回验证
4. **交替模式测试**：向0x4000000C写入0xA5A5A5A5并读回验证
5. **连续地址测试**：向0x40000000-0x4000003F写入递增数据并验证

## 程序特性

- ✅ **无标准库依赖**：不使用printf、malloc等标准库函数
- ✅ **自定义启动代码**：完全控制初始化过程
- ✅ **严格内存限制**：代码64KB，数据64KB
- ✅ **直接硬件访问**：使用volatile指针直接访问内存映射寄存器
- ✅ **仿真友好**：生成适合Verilog testbench的内存文件

## 返回值

- `0`：所有测试通过
- `-1`：有测试失败

## 注意事项

### 1. **程序入口地址** 
- 固定在 `0x80000000`（ITCM起始地址）
- 链接脚本强制将 `.text.init` 段放在ITCM首地址
- 复位后处理器从此地址开始执行

### 2. **栈指针配置**
- 初始化为 `0x90010000`（DTCM顶部）
- DTCM范围：`0x90000000` ~ `0x9000FFFF` (64KB)
- 栈向下增长，4KB栈空间足够裸机程序使用

### 3. **内存初始化**
- **BSS段自动清零**：全局未初始化变量被清零
- **数据段复制**：已初始化数据从ITCM复制到DTCM（当前程序无初始化数据）
- **栈区域**：不需要初始化，使用时自动分配

### 4. **AXI接口规格**
- **数据位宽**：32bit（4字节）
- **地址对齐**：所有访问必须4字节对齐
- **访问模式**：使用 `volatile unsigned int*` 确保每次访问都直接操作硬件

### 5. **中断和异常**
- **全局中断禁用**：`mstatus = 0`
- **中断源禁用**：`mie = 0`  
- **纯轮询模式**：不依赖任何中断机制 