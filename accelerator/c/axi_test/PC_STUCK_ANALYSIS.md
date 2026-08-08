# PC卡在0x00001000问题分析

## 当前状态

✅ **已解决：**
- 文件格式问题已修复（删除了.rodata段）
- ITCM数据成功加载
- 不再有"Illegal entry"警告

❌ **仍存在问题：**
- PC卡在`0x00001000`，未跳转到ITCM (`0x80000000`)
- 指令值显示为`0xXXXXXXXXXXXXXXXXX`（这是正常的，因为testbench错误地从ITCM读取MROM地址）

## 问题分析

### MROM跳转代码分析

MROM代码（`rtl/e203/mems/sirv_mrom.v`）：
- **MROM[0]** (地址0x00001000): `auipc t0, 0x7ffff` (0x7ffff297)
- **MROM[1]** (地址0x00001004): `jr t0` (0x00028067)

**跳转逻辑：**
1. 执行`auipc t0, 0x7ffff`：
   - `t0 = PC + (0x7ffff << 12)`
   - 如果PC = 0x00001000，则 `t0 = 0x00001000 + 0x7ffff000 = 0x80000000` ✅
   - 这应该是正确的！

2. 执行`jr t0`：
   - 应该跳转到`t0 = 0x80000000`
   - 但PC仍然卡在0x00001000

### 可能的原因

1. **MROM跳转指令未执行**
   - CPU可能没有正确执行`jr t0`指令
   - 或者跳转目标地址计算错误

2. **地址映射问题**
   - PC=0x80000000时，ITCM地址映射可能不正确
   - ITCM索引计算可能有问题

3. **CPU复位地址问题**
   - CPU复位后应该从0x00000000开始，但实际从0x00001000开始
   - 这可能表示MROM地址映射有问题

## 调试建议

### 1. 修复testbench调试输出

当前testbench在第72行错误地从ITCM读取所有PC地址。需要根据PC地址范围选择正确的内存：

```verilog
// 修复后的调试输出
always @(posedge hfclk) begin
    if (pc_vld) begin
        if (pc < 32'h00002000) begin
            // MROM地址范围：0x00000000 - 0x00001FFF
            $display("Debug: cycle %d, PC = 0x%08h (MROM)", cycle_count, pc);
        end
        else if ((pc >= 32'h80000000) && (pc < 32'h80010000)) begin
            // ITCM地址范围：0x80000000 - 0x8000FFFF
            $display("Debug: cycle %d, PC = 0x%08h, Instruction = 0x%016h (ITCM)", 
                     cycle_count, pc, `ITCM.mem_r[(pc - 32'h80000000) >> 3]);
        end
        else begin
            $display("Debug: cycle %d, PC = 0x%08h (Other)", cycle_count, pc);
        end
    end
end
```

### 2. 检查MROM执行

添加MROM执行监控：

```verilog
// 监控MROM访问
wire [`E203_PC_SIZE-1:0] ifu_pc;
assign ifu_pc = `CPU_TOP.u_e203_ifu.u_e203_ifu_ift2icb.ifu_req_pc;

always @(posedge hfclk) begin
    if (rst_n && (ifu_pc < 32'h00002000)) begin
        $display("MROM访问: PC=0x%08h, rom_addr=%d", ifu_pc, ifu_pc[11:2]);
        if (ifu_pc == 32'h00001000) begin
            $display("  -> 应该执行: auipc t0, 0x7ffff");
        end
        if (ifu_pc == 32'h00001004) begin
            $display("  -> 应该执行: jr t0");
            $display("  -> 应该跳转到: 0x80000000");
        end
    end
end
```

### 3. 检查寄存器值

监控t0寄存器的值：

```verilog
wire [31:0] t0 = `EXU.u_e203_exu_regfile.rf_r[5]; // t0是x5

always @(posedge hfclk) begin
    if (pc_vld && (pc == 32'h00001004)) begin
        $display("PC=0x00001004时，t0 = 0x%08h", t0);
        $display("  期望值: 0x80000000");
    end
end
```

### 4. 检查CPU复位地址

确认CPU复位后的起始地址：

```verilog
// 监控复位和PC变化
reg [31:0] last_pc;
always @(posedge hfclk) begin
    if (rst_n == 1'b0) begin
        last_pc <= 32'hFFFFFFFF;
        $display("=== CPU复位 ===");
    end
    else if (pc_vld && (pc != last_pc)) begin
        if (last_pc == 32'hFFFFFFFF) begin
            $display("复位后第一个PC: 0x%08h", pc);
        end
        $display("PC变化: 0x%08h -> 0x%08h", last_pc, pc);
        last_pc <= pc;
    end
end
```

## 预期行为

### 正确的执行流程：

1. **CPU复位**
   - PC应该从某个地址开始（可能是0x00000000或0x00001000）

2. **执行MROM[0]**
   - PC = 0x00001000
   - 执行`auipc t0, 0x7ffff`
   - `t0 = 0x00001000 + 0x7ffff000 = 0x80000000`

3. **执行MROM[1]**
   - PC = 0x00001004
   - 执行`jr t0`
   - 跳转到PC = 0x80000000

4. **执行ITCM代码**
   - PC = 0x80000000
   - 执行ITCM[0]中的指令
   - 程序正常运行

## 下一步操作

1. **修复testbench调试输出**（最重要）
   - 正确区分MROM和ITCM地址
   - 添加MROM和寄存器监控

2. **重新运行仿真**
   - 观察MROM是否执行
   - 检查t0寄存器值
   - 确认跳转是否发生

3. **如果MROM未执行跳转**
   - 检查MROM代码是否正确
   - 检查CPU指令执行路径
   - 检查地址映射配置

## 关键检查点

- [ ] CPU复位后PC的起始地址
- [ ] MROM[0]是否执行（PC=0x00001000）
- [ ] t0寄存器值是否正确（应该是0x80000000）
- [ ] MROM[1]是否执行（PC=0x00001004）
- [ ] 跳转是否发生（PC是否到达0x80000000）
- [ ] ITCM[0]是否包含有效指令



