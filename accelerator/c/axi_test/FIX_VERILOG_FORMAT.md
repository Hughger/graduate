# Verilog文件格式修复说明

## 问题诊断

### 发现的问题：

1. **文件包含.rodata段（字符串数据）**
   - `@00000000` ~ `@000009A0`：代码段（.text），约2464字节
   - `@000009A0` ~ 文件末尾：只读数据段（.rodata），包含字符串常量
   - 第4099行位于.rodata段，包含ASCII字符串数据

2. **`$readmemh`警告原因**
   - `.rodata`段包含ASCII字符串（如`"MCAUSE"`, `"MEPC"`等）
   - 这些数据不是有效的机器码，导致`$readmemh`解析失败

3. **PC卡在0x00001000的原因**
   - 指令值`0x0000000000300000`看起来无效
   - 可能是MROM跳转未正确执行

## 解决方案

### 方案1：只提取代码段（已实施）

已修改`Makefile`，只提取`.text`段：

```makefile
$(OBJCOPY) -j .text -O verilog $< $@
```

**优点：**
- 文件只包含机器码，没有字符串数据
- `$readmemh`可以正确解析
- 文件大小减小

**缺点：**
- 如果程序需要访问.rodata中的字符串，可能会出问题
- 但通常.rodata字符串在运行时不需要，或者可以移到DTCM

### 方案2：修改链接脚本（备选）

如果需要保留.rodata，可以将其移到DTCM：

```ld
.text : ALIGN(4)
{
    KEEP(*(.text.init))
    *(.text)
    *(.text.*)
    . = ALIGN(4);
    __text_end = .;
} > itcm

.rodata : ALIGN(4)
{
    *(.rodata)
    *(.rodata.*)
} > dtcm AT > itcm
```

## 操作步骤

### 1. 重新生成verilog文件

```bash
cd c/axi_test
make clean
make verilog
# 或者
make sim
```

### 2. 验证新文件

```bash
# 检查文件大小（应该比之前小很多）
wc -l axi_test.verilog

# 检查地址标记（应该只有@00000000）
grep "^@" axi_test.verilog

# 查看文件末尾（应该是正常的十六进制数据）
tail -10 axi_test.verilog
```

**预期结果：**
- 文件应该只有几百行（而不是8637行）
- 只有一个地址标记：`@00000000`
- 文件末尾是正常的十六进制数据

### 3. 重新运行仿真

```bash
cd vsim/run
# 运行仿真
# 检查是否还有警告
```

**预期结果：**
- 不应该再有"Illegal entry"警告
- ITCM数据应该正确加载

## 验证检查点

### ✅ 文件格式检查
- [ ] 文件只有`.text`段数据
- [ ] 没有.rodata段数据
- [ ] 只有一个`@00000000`地址标记
- [ ] 所有数据都是有效的十六进制

### ✅ 仿真检查
- [ ] 没有`$readmemh`警告
- [ ] ITCM数据正确加载
- [ ] PC能够正确跳转到0x80000000
- [ ] 程序能够正常执行

## 如果仍有问题

### PC仍然卡在0x00001000

如果修复后PC仍然卡在0x00001000，可能的原因：

1. **MROM跳转未执行**
   - 检查MROM代码是否正确
   - 验证CPU是否从0x00000000开始执行

2. **ITCM地址映射问题**
   - 检查ITCM物理地址是否正确映射
   - 验证PC=0x80000000时ITCM索引是否正确

3. **数据加载问题**
   - 检查ITCM[0]是否包含有效指令
   - 验证数据是否正确加载到ITCM数组

### 调试建议

1. **添加调试输出**
   ```verilog
   $display("ITCM[0] = 0x%016h", `ITCM.mem_r[0]);
   $display("PC=0x80000000 -> ITCM索引=%d", 32'h80000000[13:3]);
   ```

2. **检查MROM执行**
   ```verilog
   if (pc < 32'h00001000) begin
       $display("MROM执行: PC=0x%08h", pc);
   end
   ```

3. **查看波形**
   - 使用Verdi查看PC信号
   - 检查ITCM数据
   - 验证MROM访问

## 总结

主要修复：
- ✅ 修改Makefile，只提取`.text`段
- ✅ 排除`.rodata`段（字符串数据）
- ✅ 生成纯机器码文件

下一步：
1. 重新生成verilog文件
2. 验证文件格式
3. 重新运行仿真
4. 如果PC仍然卡住，检查MROM和地址映射



