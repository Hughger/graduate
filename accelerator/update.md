# E203_dev Branch Commit History

## v3.3
- 2025-09-14 (chengkexun):
    - 去掉了S2的其中一个接口ram
    - 修改所有的ram大小为64KB
    - 将MacMachine例化进来，并新增2个64KB RAM供其使用
    - 针对`mac_connect_test.c`已测试通过，FPGA版本已形成，和NextCloud上的系统框图一致，可以由挺然师兄进行测试

## v3.1
- 2025-09-08 (chengkexun):
    - 给S2、S3、S4都加了一个128KB，字对齐，宽度为256 bit的ram，形成了3套乒乓ram
    - 给S2、S3、S4中每个ram加了一套控制切换模块，支持使用 `基地址 + 0xF_0000` 的方式切换控制方为 `AXI` or `MacMachine`
        - `基地址 + 0xF_0000` 写入的数据data主要关注低两位，即 `data[1:0]`
            - `data[0]` 控制ping ram，`data[0] == 1'b0`（默认状态），ping ram控制权在 `AXI` ； `data[0] == 1'b1`，ping ram控制权在 `MacMachine`
            - `data[1]` 控制pong ram，`data[1] == 1'b0`（默认状态），pong ram控制权在 `AXI` ； `data[1] == 1'b1`，pong ram控制权在 `MacMachine`
    - 增加 `MacMachine_RamCtrlSimple` 模块用于测试，会始终往ram的`[0]`地址写`{32{8'h66}}`

## v3.0
- 2025-09-07 (chengkexun):
    - 将S1改为字对齐，宽度为64 bit
    - 将S2改为128KB，并改为字对齐，宽度为256 bit
    - 添加64 bit -> 256 bit 转换模块，进行S1 -> S2 搬数测试，并PASS
    - 添加S3、S4，均为128KB，字对齐，宽度为256 bit
    - 进行S1 -> S2, S1 -> S3, S4 -> S1 搬数测试，并PASS

## v2.0
- 2025-09-01 (chengkexun): axi2bram1mb_asic版更新，替换ip
- 2025-08-30 (chengkexun): 修复paddr地址不对齐问题
- 2025-07-24 (zhaoyi): jtag_pass
- 2025-07-19 (chengkexun): uart test pass!
- 2025-07-14 (cuiying): uart init（注意tb和bootrom启动）
- 2025-07-02 (chengkexun): DMA PASS!
- 2025-06-29 (chengkexun): APB&AXI done
- 2025-06-28 (chengkexun): Merge remote-tracking branch 'origin/apb_mux' into e203_dev
- 2025-06-27 (zhaoyi): apb_test文件上传
- 2025-06-27 (zhaoyi): apb_mux
- 2025-06-26 (chengkexun): v2.0 AXI Matrix换成ASIC ip，256M RAM测试pass
- 2025-06-09 (chengkexun): v1.9 AXI interconnect done
