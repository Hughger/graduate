# 仿真问题诊断和修复步骤

## 问题描述
- PC卡在 `0x00001000`，未跳转到ITCM (`0x80000000`)
- 程序执行超时
- 文件加载警告（第4099行）

---

## 步骤1：验证文件格式和内容

### 1.1 检查 verilog 文件格式
```bash
cd c/axi_test
# 检查文件行数
wc -l axi_test.verilog

# 检查文件中的地址标记
grep "^@" axi_test.verilog

# 检查文件末尾是否有格式问题
tail -20 axi_test.verilog
```

**预期结果：**
- 文件应该有4个地址标记：`@00000000`, `@000000BC`, `@00002370`, `@0000262C`
- 文件末尾应该是正常的数据行，没有空行或格式错误

### 1.2 验证文件中的数据
```bash
# 查看文件前几行，确认数据格式正确
head -20 axi_test.verilog
```

**预期格式：**
```
@00000000
73 70 04 30 73 50 40 30 97 11 00 10 93 81 81 85
...
```

---

## 步骤2：检查ITCM加载的数据

### 2.1 修改testbench添加详细调试信息

编辑 `tb/tb_top.v`，在加载数据后添加更多调试输出：

```verilog
// 在第352行之后添加
$display("=== ITCM加载验证 ===");
$display("ITCM数组大小: %d", `E203_ITCM_RAM_DP);
$display("ITCM[0] (对应PC=0x80000000): 0x%016h", `ITCM.mem_r[0]);
$display("ITCM[1] (对应PC=0x80000008): 0x%016h", `ITCM.mem_r[1]);
$display("ITCM[2] (对应PC=0x80000010): 0x%016h", `ITCM.mem_r[2]);

// 验证地址映射
$display("=== 地址映射验证 ===");
$display("PC=0x80000000 -> ITCM索引=%d", 32'h80000000[13:3]);
$display("PC=0x00001000 -> ITCM索引=%d", 32'h00001000[13:3]);
```

### 2.2 重新编译和运行仿真
```bash
# 重新编译（如果需要）
cd vsim/run
make clean
make

# 运行仿真并查看输出
# 注意观察ITCM加载的数据是否正确
```

**检查点：**
- ITCM[0] 应该包含程序的第一个64位指令
- 确认数据不是全0或全X

---

## 步骤3：检查MROM跳转逻辑

### 3.1 验证MROM代码
MROM应该包含跳转到ITCM的代码：
- 地址0: `auipc t0, 0x7ffff` (0x7ffff297)
- 地址4: `jr t0` (0x00028067)

### 3.2 添加MROM执行监控

在 `tb/tb_top.v` 中添加MROM访问监控：

```verilog
// 在initial块中添加
wire [`E203_PC_SIZE-1:0] mrom_pc;
assign mrom_pc = `CPU_TOP.u_e203_ifu.u_e203_ifu_ift2icb.ifu_req_pc;

always @(posedge hfclk) begin
    if (rst_n && (mrom_pc < 32'h00001000)) begin
        $display("MROM访问: PC=0x%08h", mrom_pc);
        if (mrom_pc == 32'h00000000) begin
            $display("  -> 执行MROM[0]: auipc t0, 0x7ffff");
        end
        if (mrom_pc == 32'h00000004) begin
            $display("  -> 执行MROM[1]: jr t0");
            $display("  -> 应该跳转到: 0x80000000");
        end
    end
end
```

### 3.3 检查跳转是否执行

**检查点：**
- MROM[0] 是否被执行
- MROM[1] 是否被执行
- PC是否从0x00000004跳转到0x80000000

---

## 步骤4：验证地址映射

### 4.1 理解地址映射关系

- **ITCM物理地址**: `0x80000000` ~ `0x8000FFFF` (64KB)
- **ITCM数组索引**: `0` ~ `8191` (64KB / 8字节 = 8192个64位字)
- **地址转换**: `PC[13:3]` 用于索引ITCM数组

**关键公式：**
```
ITCM索引 = (PC - 0x80000000) >> 3
         = PC[13:3]  (当PC在ITCM范围内)
```

### 4.2 验证PC=0x80000000的映射

```verilog
// 在testbench中添加
$display("PC=0x80000000的地址映射:");
$display("  PC[31:14] = 0x%05h (应该是0x20000)", 32'h80000000[31:14]);
$display("  PC[13:3]  = 0x%03h (应该是0x000)", 32'h80000000[13:3]);
$display("  -> ITCM索引 = %d", 32'h80000000[13:3]);
```

**预期结果：**
- PC=0x80000000 -> ITCM索引=0
- PC=0x80000008 -> ITCM索引=1
- PC=0x80000010 -> ITCM索引=2

---

## 步骤5：检查CPU复位和启动流程

### 5.1 验证复位地址

E203 CPU复位后应该从 `0x00000000` 开始执行（MROM）。

### 5.2 添加复位监控

```verilog
// 监控复位和PC变化
reg [31:0] last_pc;
always @(posedge hfclk) begin
    if (rst_n == 1'b0) begin
        last_pc <= 32'hFFFFFFFF;
        $display("=== CPU复位 ===");
    end
    else if (pc_vld && (pc != last_pc)) begin
        $display("PC变化: 0x%08h -> 0x%08h", last_pc, pc);
        last_pc <= pc;
        
        // 检查是否卡在某个地址
        if (pc == 32'h00001000) begin
            $display("警告: PC卡在0x00001000!");
            $display("  当前指令: 0x%016h", `ITCM.mem_r[pc[13:3]]);
        end
    end
end
```

---

## 步骤6：修复方案

### 方案A：如果MROM跳转未执行

**可能原因：**
1. MROM代码错误
2. 跳转指令执行失败
3. 地址映射问题

**解决方法：**
1. 检查 `rtl/e203/mems/sirv_mrom.v` 中的跳转代码
2. 确认MROM地址映射正确
3. 检查CPU的指令执行路径

### 方案B：如果ITCM数据未正确加载

**可能原因：**
1. `$readmemh` 读取失败
2. 地址偏移计算错误
3. 数据格式不匹配

**解决方法：**
1. 检查 `axi_test.verilog` 文件格式
2. 确认 `$readmemh` 正确解析地址标记
3. 验证数据加载到正确的数组索引

### 方案C：如果地址映射错误

**可能原因：**
1. ITCM地址基址配置错误
2. PC地址计算错误

**解决方法：**
1. 检查 `rtl/e203/core/config.v` 中的 `E203_CFG_ITCM_ADDR_BASE`
2. 确认地址译码逻辑正确
3. 验证PC到ITCM索引的转换

---

## 步骤7：重新生成verilog文件（如果需要）

### 7.1 检查链接脚本
```bash
cd c/axi_test
cat link.ld | grep ORIGIN
```

**预期：**
- ITCM ORIGIN = 0x80000000

### 7.2 重新编译
```bash
make clean
make all
make sim
```

### 7.3 检查生成的verilog文件
```bash
head -5 axi_test.verilog
# 应该看到 @00000000（这是LMA，不是VMA）
```

**注意：** `objcopy -O verilog` 生成的是LMA（Load Memory Address），不是VMA（Virtual Memory Address）。虽然链接脚本定义VMA为0x80000000，但objcopy可能生成从0x00000000开始的地址。这是正常的，因为testbench会将数据加载到ITCM数组索引0，而ITCM物理地址是0x80000000。

---

## 步骤8：最终验证

### 8.1 运行完整仿真
```bash
cd vsim/run
# 运行仿真
# 观察输出日志
```

### 8.2 检查关键指标

1. **MROM执行：**
   - PC从0x00000000开始
   - 执行MROM[0]和MROM[1]
   - 跳转到0x80000000

2. **ITCM加载：**
   - ITCM[0]包含有效指令
   - 数据不是全0或全X

3. **程序执行：**
   - PC跳转到0x80000000
   - 执行ITCM中的指令
   - 程序正常运行

---

## 常见问题排查

### Q1: PC一直卡在0x00001000
**可能原因：**
- MROM跳转未执行
- ITCM地址映射错误
- CPU执行路径问题

**解决方法：**
- 检查MROM代码
- 验证地址映射
- 添加更多调试信息

### Q2: ITCM数据全0或全X
**可能原因：**
- 文件加载失败
- 地址偏移错误
- 数据格式问题

**解决方法：**
- 检查文件格式
- 验证加载逻辑
- 添加数据验证

### Q3: 文件加载警告
**可能原因：**
- 文件格式错误
- 地址标记问题
- 数据行格式错误

**解决方法：**
- 检查文件格式
- 验证地址标记
- 检查数据行

---

## 调试技巧

1. **使用波形查看器：**
   - 查看PC信号变化
   - 查看ITCM数据
   - 查看MROM访问

2. **添加断点：**
   - 在关键地址设置断点
   - 观察寄存器值
   - 检查内存内容

3. **逐步调试：**
   - 先验证文件加载
   - 再验证MROM执行
   - 最后验证程序执行

---

## 联系信息

如果问题仍未解决，请提供：
1. 完整的仿真日志
2. ITCM加载的数据
3. PC执行轨迹
4. 相关配置文件



