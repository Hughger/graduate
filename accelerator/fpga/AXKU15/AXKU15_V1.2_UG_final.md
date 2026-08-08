

# <a name="_bookmark1"></a>**目 录**
[文档版本控制*	2](#_bookmark0)

[目 录*	3](#_bookmark1)

[一、 开发板简介*	5](#_bookmark2)

[二、 ACKU15 核心板*	7](#_bookmark3)

[(一) 简介*	7](#_bookmark4)

[(二) FPGA 芯片*	8](#_bookmark5)

[(三) DDR4*	9](#_bookmark6)

[(四) QSPI Flash*	14](#_bookmark7)

[(五) 时钟配置*	15](#_bookmark8)

[(六) LED 灯*	17](#_bookmark9)

[(七) 电源*	18](#_bookmark10)

[(八) 结构图*	20](#_bookmark11)

[(九) 连接器管脚定义*	20](#_bookmark12)

[三、 扩展板*	38](#_bookmark13)

[(一) 简介*	38](#_bookmark14)

[(二) PCIe 插槽*	38](#_bookmark15)

[(三) 千兆网接口*	41](#_bookmark16)

[(四) FMCHPC 接口*	43](#_bookmark17)

[(五) MIPI 接口*	53](#_bookmark18)

[(六) USB 转串口*	55](#_bookmark19)

[(七) SD 卡槽*	55](#_bookmark20)

[(八) SATA 接口*	56](#_bookmark21)

[(九) 按键和 LED 灯*	57](#_bookmark22)

[(十) EEPROM*	58](#_bookmark23)

[(十一) 温度传感器*	59](#_bookmark24)

[(十二) 光纤接口*	60](#_bookmark25)

[(十三) JTAG 调试口*	62](#_bookmark26)

[(十四) 电源*	63](#_bookmark27)

[(十五) 结构尺寸图*	65](#_bookmark28)

芯驿电子科技（上海）有限公司 基于 Xilinx FPGA Kintex Ultrascale+开发平台的开发板（型号：AXKU15）正式发布了，为了让您对此开发平台可以快速了解，我们编写了此用户手册。

这款 Kintex Ultrascale+ FPGA 开发平台采用核心板加扩展板的模式，方便用户对核心板的二次开发利用。核心板使用 Xilinx 的 Kintex Ultrascale+芯片 XCKU15PFFVE1517 的解决方案，挂载了 5 片 1GB 的高速 DDR4 SDRAM 芯片和 2 片 512Mb 的 QSPI FLASH 芯片。

在底板设计上我们为用户扩展了丰富的外围接口，比如 1 个 PCIe3.0x16 接口、2 路 FMC HPC 接口、1 路千兆以太网接口、2 个 QSFP28 光纤接口、2 路 MIPIx4 输入接口、1 路 UART 串口接口、1 路 SD 卡接口等等。可满足用户各种高速数据交换，视频传输处理以及工业控制的要求，是一款"专业级“的 FPGA 开发平台。为高速数据传输和交换，数据处理的前期验证和后期应用提供了可能。相信这样的一款产品非常适合从事 FPGA 开发的学生、工程师等群体。



## **一、	<a name="一、开发板简介"></a><a name="_bookmark2"></a>开发板简介**
在这里，对这款 Kintex Ultrascale+ AXKU15 开发平台进行简单的功能介绍。

开发板的整个结构，继承了我们一贯的核心板+扩展板的模式来设计的。核心板和扩展板之间使用高速板间连接器连接。

核心板主要由 XCKU15PFFVE1517 +5 个 DDR4 + QSPI FLASH 的最小系统构成。采用 Xilinx 的 Kintex Ultrascale+系列的芯片，型号为 XCKU15PFFVE1517。在 FPGA 芯片的 HP端口上连接了 5 片 DDR4 存储芯片，每片 DDR4 容量高达 1GB 字节，组成 80 位的数据位宽。 2 个 512Mb 的 QSPI FLASH 用来静态存储 FPGA 芯片的配置文件或者其它用户数据。

底板为核心板扩展了丰富的外围接口，其中包含 1 个 PCIe3.0x16 接口、2 路 FMC HPC接口、1 路千兆网接口、2 路 MIPI 输入接口、1 路 UART 串口接口、1 路 SD 卡接口、一些按键及 LED。

下图为整个开发系统的结构示意图：


通过这个示意图，我们可以看到，我们这个开发平台所能含有的接口和功能。

- FPGA 核心板

由 XCKU15P + 5 个 DDR4 + 2 个 QSPI FLASH 的最小系统组成，另外有两个晶振提供时钟，2 个 200MHz 晶振提供为 FPGA 逻辑和 DDR 控制参考时钟。

- PCIe3.0 x16 接口

支持 PCI Express 3.0 标准，提供标准的 PCIe x16 高速数据传输接口，单通道通信速率可高达 8GBaud。

- 2 路 FMC HPC 接口

FPGA 中的 8 路高速收发器连接到 FMC HPC 专用的高速管脚上，其中 1 个 FMC 接口引出 34 对 LA 信号差分对、2 对时钟信号及 24 对 HA 信号；另一 FMC 接口引出 34 对 LA 信号差分对和2 对时钟信号，可满足高速信号传输要求，符合FMC 标准，可以各种FMC 模块（HDMI输入输出模块，高速 AD 模块等等）。

- 1 路千兆网接口

千兆以太网接口芯片采用 JL2121D 以太网 PHY 芯片为用户提供网络通信服务。芯片支持 10/100/1000 Mbps 网络传输速率; 全双工和自适应。

- 2 路 MIPI 输入接口

板载 2 路 MIPI lanex4 输入接口，最高速率支持 2.5Gb/s，用于连接 MIPI 摄像头模块。

- USB Uart 接口

1 路 Uart 转 USB 接口，用于和电脑通信，方便用户调试。串口芯片采用 Silicon Labs CP2102GM 的 USB-UAR 芯片, USB 接口采用 MINI USB 接口。

- Micro SD 卡座

1 路 Micro SD 卡座，用于存储操作系统镜像和文件系统。

- 2 路 SATA 接口

2 个标准的 SATA 接口，可用连接 SATA 外设，如 SATA 接口的固态硬盘。

- JTAG 调试口

1 个 10 针 2.54mm 标准的JTAG 口，用于 FPGA 程序的下载和调试，用户可以通过 XILINX下载器对 FPGA 系统进行调试和下载。

- LED 灯

7 个发光二极管 LED, 核心板上 3 个，底板上 7 个。核心板上 1 个电源指示灯；1 个 DONE

配置指示灯和用户指示灯。底板上有 1 个电源指示灯，4 个用户指示灯和 2 个串口指示灯。

- 按键

底板上 4 个用户按键。

## **二、	<a name="二、acku15核心板"></a><a name="_bookmark3"></a>ACKU15 核心板**
### **(一) 简介**
ACKU15(**核心板型号，下同**)核心板，FPGA 芯片是基于 Xilinx FPGA Kintex Ultrascale+的主芯片 XCKU15PFFVE1517 设计。核心板在 FPGA 的 HP 端口上连接了 5 片 DDR4 存储芯片组成 80 位的数据带宽，每片 DDR4 容量高达 1GB。HP 端的内存带宽高达 210Gb/s。另外核心板上也集成了 2 片 512MBit 大小的 QSPI FLASH，用于启动存储配置和系统文件。

这款核心板的采用个板对板连接器扩展出了 256 个 HPIO 和 88 个 HDIO，引出的 IO 的电平可以通过更换底板上的 LDO 芯片来修改，满足用户不用电平接口的要求；另外核心板也扩展出了 24 对 GTY 和 32 对 GTH 高速收发器接口。对于需要大量 IO 和高速收发器的用户，此核心板将是不错的选择。而且 IO 连接部分，FPGA 芯片到接口之间走线做了等长和差分处理，并且核心板尺寸仅为 80\*80（mm），对于二次开发来说，非常适合。


#### 图 2-1-1 ACKU15 核心板正面图

### **(二) <a name="_bookmark5"></a>FPGA 芯片**
前面已经介绍过了，我们所使用的 FPGA 型号为 **XCKU15PFFVE1517**，属于 Xilinx 公司 Kintex Ultrascale+系列的产品，速度等级为 2，温度等级为工业级。此型号为 FFVE1517 封装，1517 个引脚。Xilinx Kintex Ultrascale+ FPGA 的芯片命名规则如下：



图 2-2-1 为开发板所用的 FPGA 芯片实物图。







图 2-2-1 FPGA 芯片实物其中 FPGA 芯片的主要参数如下所示：

|名称|具体参数|
| :-: | :-: |
|Logic Cells|1143K|
|触发器(FF)|1,045,440|
|LUTs|522,720|
|Total Block RAM|34\.6Mb|

|DSP Slices|1968|
| :-: | :-: |
|CMTs|11|
|GTY/Gb/s|24/28.21Gb|
|GTH/Gb/s|32/16.3Gb|
|PCIe Gen3 x16|1|
|速度等级|-2|
|温度等级|工业级|
### **(三) <a name="_bookmark6"></a>DDR4**
ACKU15 开 发 板 上 配 有 5 片 Micron( 美 光 ） 的 1GB 的 DDR4 芯 片 ， 型 号 为 MT40A512M16LY-062E，连接在FPGA的HP端，组成80位数据总线和5GB的容量。DDR4 SDRAM的在FPGA端的最高运行数据速率2666Mbps，5片DDR4存储系统直接连接到了 BANK 66、67、68的存储器接口上。DDR4 SDRAM的具体配置如下表2-3-1所示。

表 2-3-1 DDR4 SDRAM 配置

|**位号**|**芯片型号**|**容量**|**厂家**|
| :-: | :-: | :-: | :-: |
|U3、U4、U7、U8、U9|MT40A512M16LY-062E|512Mx 16bit|Micron|

DDR4 的硬件设计需要严格考虑信号完整性，我们在电路设计和 PCB 设计的时候已经充分考虑了匹配电阻/终端电阻,走线阻抗控制，走线等长控制，保证 DDR4 的高速稳定的工作。

FPGA 端的 DDR4 的硬件连接方式如图 2-3-1 所示:



图2-3-1 DDR4 DRAM原理图部分

图 2-3-2 为开发板的 2 片 DDR4 DRAM 实物图



图 2-3-2 4 片 DDR4 DRAM 实物图

##### **DDR4 SDRAM 引脚分配：**

|**信号名称**|**引脚号**|
| :-: | :-: |
|DDR4\_D0|AJ28|
|DDR4\_D1|AK27|
|DDR4\_D2|AK26|
|DDR4\_D3|AL27|
|DDR4\_D4|AJ26|
|DDR4\_D5|AN26|
|DDR4\_D6|AN27|
|DDR4\_D7|AK28|
|DDR4\_D8|AK22|
|DDR4\_D9|AL24|
|DDR4\_D10|AJ23|
|DDR4\_D11|AM25|
|DDR4\_D12|AH23|
|DDR4\_D13|AK24|
|DDR4\_D14|AK23|
|DDR4\_D15|AJ24|
|DDR4\_D16|AN25|
|DDR4\_D17|AP23|
|DDR4\_D18|AP24|
|DDR4\_D19|AT25|
|DDR4\_D20|AN23|
|DDR4\_D21|AP26|

|DDR4\_D22|AP25|
| :-: | :-: |
|DDR4\_D23|AT26|
|DDR4\_D24|AU23|
|DDR4\_D25|AV26|
|DDR4\_D26|AU24|
|DDR4\_D27|AW25|
|DDR4\_D28|AT24|
|DDR4\_D29|AW26|
|DDR4\_D30|AV23|
|DDR4\_D31|AV27|
|DDR4\_D32|AM38|
|DDR4\_D33|AK39|
|DDR4\_D34|AL37|
|DDR4\_D35|AL39|
|DDR4\_D36|AN38|
|DDR4\_D37|AJ39|
|DDR4\_D38|AL36|
|DDR4\_D39|AM39|
|DDR4\_D40|AM35|
|DDR4\_D41|AL35|
|DDR4\_D42|AM34|
|DDR4\_D43|AL34|
|DDR4\_D44|AH33|
|DDR4\_D45|AK35|
|DDR4\_D46|AJ33|
|DDR4\_D47|AJ34|
|DDR4\_D48|AK32|
|DDR4\_D49|AL32|
|DDR4\_D50|AJ30|
|DDR4\_D51|AM33|
|DDR4\_D52|AH31|
|DDR4\_D53|AH32|
|DDR4\_D54|AJ29|
|DDR4\_D55|AM32|
|DDR4\_D56|AL29|

|DDR4\_D57|AM30|
| :-: | :-: |
|DDR4\_D58|AM29|
|DDR4\_D59|AN33|
|DDR4\_D60|AP28|
|DDR4\_D61|AL30|
|DDR4\_D62|AP29|
|DDR4\_D63|AN32|
|DDR4\_D64|AU29|
|DDR4\_D65|AW31|
|DDR4\_D66|AW28|
|DDR4\_D67|AV31|
|DDR4\_D68|AT29|
|DDR4\_D69|AU30|
|DDR4\_D70|AW29|
|DDR4\_D71|AT30|
|DDR4\_D72|AT35|
|DDR4\_D73|AW34|
|DDR4\_D74|AU33|
|DDR4\_D75|AU34|
|DDR4\_D76|AU32|
|DDR4\_D77|AT36|
|DDR4\_D78|AU35|
|DDR4\_D79|AW35|
|DDR4\_DM0|AL25|
|DDR4\_DM1|AM23|
|DDR4\_DM2|AR23|
|DDR4\_DM3|AW23|
|DDR4\_DM4|AM37|
|DDR4\_DM5|AK33|
|DDR4\_DM6|AH30|
|DDR4\_DM7|AM28|
|DDR4\_DM8|AU28|
|DDR4\_DM9|AV35|
|DDR4\_DQS0\_N|AH27|
|DDR4\_DQS0\_P|AH26|

|DDR4\_DQS1\_N|AJ25|
| :-: | :-: |
|DDR4\_DQS1\_P|AH25|
|DDR4\_DQS2\_N|AR27|
|DDR4\_DQS2\_P|AR26|
|DDR4\_DQS3\_N|AV25|
|DDR4\_DQS3\_P|AU25|
|DDR4\_DQS4\_N|AK38|
|DDR4\_DQS4\_P|AK37|
|DDR4\_DQS5\_N|AN36|
|DDR4\_DQS5\_P|AN35|
|DDR4\_DQS6\_N|AL31|
|DDR4\_DQS6\_P|AK31|
|DDR4\_DQS7\_N|AN31|
|DDR4\_DQS7\_P|AN30|
|DDR4\_DQS8\_N|AW30|
|DDR4\_DQS8\_P|AV30|
|DDR4\_DQS9\_N|AV33|
|DDR4\_DQS9\_P|AV32|
|DDR4\_OTD|AR33|
|DDR4\_PAR|AV36|
|DDR4\_RAS\_B|AP35|
|DDR4\_RST|AH34|
|DDR4\_WE\_B|AP31|
|DDR4\_A0|AV38|
|DDR4\_A1|AR38|
|DDR4\_A2|AV37|
|DDR4\_A3|AR36|
|DDR4\_A4|AU39|
|DDR4\_A5|AP38|
|DDR4\_A6|AT31|
|DDR4\_A7|AP39|
|DDR4\_A8|AV28|
|DDR4\_A9|AT39|
|DDR4\_A10|AU38|
|DDR4\_A11|AW36|

|DDR4\_A12|AR37|
| :-: | :-: |
|DDR4\_A13|AR39|
|DDR4\_ACT\_B|AT37|
|DDR4\_ALERT\_B|AK34|
|DDR4\_BA0|AW33|
|DDR4\_BA1|AP36|
|DDR4\_BG0|AR31|
|DDR4\_CAS\_B|AP34|
|DDR4\_CKE|AU37|
|DDR4\_CLK\_N|AT34|
|DDR4\_CLK\_P|AR34|
|DDR4\_CLKREF\_N|AT32|
|DDR4\_CLKREF\_P|AR32|
|DDR4\_CS\_B|AP33|
### **(四) <a name="_bookmark7"></a>QSPI Flash**
核 心 板 配 有 2 片 512MBit 大 小 的 Quad-SPI FLASH 芯 片 ， 型 号 为 MT25QU512ABA1EW9，它使用 1.8V CMOS 电压标准。由于 QSPI FLASH 的非易失特性，在使用中， 它可以存储 FPGA 的配置 Bin 文件以及其它的用户数据文件。QSPI FLASH 的具体型号和相关参数见表 2-4-1。

表2-4-1 QSPI Flash的型号和参数

|**位号**|**芯片类型**|**容量**|**厂家**|
| :-: | :-: | :-: | :-: |
|U10、U11|MT25QU512ABB1EW9|512Mbit|Micron|

QSPI FLASH 连接到 FPGA 芯片的的专用管脚上，其中时钟管脚连接到专用 BANK0 的 CCLK0 上，数据管脚分别连接到 BANK0 和 BANK65 上。图 2-4-1 为 QSPI Flash 和 FPGA芯片的连接示意图。




图 4-1 QSPI Flash 连接示意图
##### **配置芯片引脚分配：**

|**信号名称**|**FPGA 引脚号**|
| :-: | :-: |
|QSPI\_CLK|AD23|
|QSPI0\_CS|AG22|
|QSPI0\_DQ0|AD25|
|QSPI0\_DQ1|AD26|
|QSPI0\_DQ2|AE22|
|QSPI0\_DQ3|AE23|
|QSPI1\_CS|AV11|
|QSPI1\_DQ0|AM12|
|QSPI1\_DQ1|AN12|
|QSPI1\_DQ2|AR13|
|QSPI1\_DQ3|AR12|

### **(五) 时钟配置**
核心板上为 FPGA 系统提供了 200Mhz 的 2 路差分有源时钟。分别为 FPGA 逻辑部分提供差分时钟源。时钟电路设计的示意图如下图 2-5-1 所示：




图 2-5-1 核心板时钟源
##### **FPGA 系统时钟源**
板上提供了 2 个 200MHz 差分晶振，可为 DDR4 控制器及 FPGA 逻辑提供参考时钟。晶振输出连接到 FPGA BANK66 和 BANK84 的全局时钟上，这个全局时钟可以用来驱动 FPGA内的 DDR4 控制器和用户逻辑电路。该时钟源的原理图如图 2-5-2 所示








图 2-5-2 系统时钟源
##### **时钟引脚分配：**

|**信号名称**|**FPGA 引脚**|
| :-: | :-: |
|**B94\_L5\_P**|G12|
|**B94\_L5\_N**|G11|
|**DDR4\_CLKREF\_P**|AR32|
|**DDR4\_CLKREF\_N**|AT32|

### **(六) <a name="_bookmark9"></a>LED 灯**
ACKU15 核心板上有 3 个红色 LED 灯，其中 1 个是电源指示灯(PWR1)，1 个是配置 LED灯(D1)，还有一个用户指示灯（LED1）。核心上电时指示灯会亮起；当 FPGA 配置程序后，配置 LED 灯会亮起。用户指示灯可用于自定义功能指示。LED 灯硬件连接的示意图如图 2-6-1

所示：



图 2-6-1 核心板 LED 灯硬件连接示意图
### **(七) 电源**
ACKU15 核心板供电电压为+12V，通过连接底板供电。板上的电源设计示意图如下图 2-7-1 所示:




图 2-7-1 原理图中电源接口部分

+12V 通过 DCDC 电源芯片 IS6608 产生 FPGA 核心电源，输出电流高达 60A，可满足核心电压的电流需求。+12V 电源再通过3 个DCDC 芯片：SGM61163 产生VCCAUX，IS66066

产生 MGTAVCC，MGTAVTT 电源，给 FPGA 辅助电源和高速收发器供电。同时+12V 电源再通过 DCDC 芯片 ETA1471 与 SGM61163 来产生+1.2V，VCC1V8\_FPGA、D3V3 电源给

DDR4、FPGA 的 BANK 及外设供电。另外 D3V3 通过 2 个 LDO 芯片 ETA5060 产生高速收发器的辅助电源和 FPGA 的 ADC 供电电源+1.8V； DDR4 的 VTT 和 DDR2V5 电压由 TPS51200 和 ETA5050 产生。

因为 FPGA 的电源有上电顺序的要求，在电路设计中，我们已经按照芯片的电源要求设计，保证芯片的正常工作。

### **(八) 结构图**


图 2-8-1 正面图（Top View）

### **(九) 连接器管脚定义**
核心板一共扩展出 4 个高速扩展口，使用 4 个 240Pin 的板间连接器（J1~J4）和底板连接，核心板供电由 J3 连接器输入。

##### **J1 连接器的引脚分配**

|**J1 管脚**|**信号名称**|<p>**FPGA 引**</p><p>**脚号**</p>|**J1 管脚**|**信号名称**|<p>**FPGA 引脚**</p><p>**号**</p>|
| :-: | :-: | :-: | :-: | :-: | :-: |
|A1|B90\_L10\_N|B4|B1|B90\_L12\_N|A6|
|A2|B90\_L10\_P|B5|B2|B90\_L12\_P|B6|
|A3|B90\_L8\_N|C4|B3|B90\_L11\_N|A3|
|A4|B90\_L8\_P|C5|B4|B90\_L11\_P|A4|
|A5|GND|-|B5|GND|-|
|A6|B90\_L9\_N|B2|B6|B90\_L7\_N|C3|
|A7|B90\_L9\_P|C2|B7|B90\_L7\_P|D3|
|A8|B90\_L4\_N|E1|B8|B90\_L6\_N|D1|
|A9|B90\_L4\_P|F1|B9|B90\_L6\_P|D2|
|A10|GND|-|B10|GND|-|
|A11|B90\_L5\_N|D5|B11|B90\_L3\_N|F2|
|A12|B90\_L5\_P|D6|B12|B90\_L3\_P|F3|
|A13|B90\_L1\_N|E4|B13|B90\_L2\_N|E3|
|A14|B90\_L1\_P|E5|B14|B90\_L2\_P|F4|
|A15|GND|-|B15|GND|-|
|A16|B91\_L11\_N|A9|B16|B91\_L9\_N|A7|
|A17|B91\_L11\_P|B10|B17|B91\_L9\_P|B7|
|A18|B91\_L12\_N|A11|B18|B91\_L10\_N|A8|
|A19|B91\_L12\_P|B11|B19|B91\_L10\_P|B9|
|A20|GND|-|B20|GND|-|
|A21|B91\_L7\_N|C7|B21|B91\_L5\_N|D7|
|A22|B91\_L7\_P|C8|B22|B91\_L5\_P|D8|
|A23|B91\_L3\_N|E8|B23|B91\_L1\_N|E6|
|A24|B91\_L3\_P|F9|B24|B91\_L1\_P|F6|
|A25|GND|-|B25|GND|-|
|A26|B91\_L8\_N|C9|B26|B91\_L2\_N|F7|
|A27|B91\_L8\_P|C10|B27|B91\_L2\_P|F8|
|A28|B91\_L6\_N|D10|B28|B91\_L4\_N|E9|

|A29|B91\_L6\_P|D11|B29|B91\_L4\_P|E10|
| :-: | :-: | :-: | :-: | :-: | :-: |
|A30|GND|-|B30|GND|-|
|A31|B93\_L12\_N|K10|B31|B93\_L10\_N|K13|
|A32|B93\_L12\_P|K11|B32|B93\_L10\_P|L13|
|A33|B93\_L7\_N|L14|B33|B93\_L11\_N|L11|
|A34|B93\_L7\_P|M14|B34|B93\_L11\_P|L12|
|A35|GND|-|B35|GND|-|
|A36|B93\_L9\_N|M10|B36|B93\_L8\_N|M11|
|A37|B93\_L9\_P|N10|B37|B93\_L8\_P|M12|
|A38|B93\_L3\_N|P12|B38|B93\_L4\_N|P10|
|A39|B93\_L3\_P|P13|B39|B93\_L4\_P|P11|
|A40|GND|-|B40|GND|-|
|A41|B93\_L6\_N|N12|B41|B93\_L2\_N|R13|
|A42|B93\_L6\_P|N13|B42|B93\_L2\_P|R14|
|A43|B93\_L5\_N|N14|B43|B93\_L1\_N|P15|
|A44|B93\_L5\_P|N15|B44|B93\_L1\_P|R15|
|A45|GND|-|B45|GND|-|
|A46|GND|-|B46|GND|-|
|A47|MGT227\_CLK0\_P|AE12|B47|MGT227\_CLK1\_P|AD10|
|A48|MGT227\_CLK0\_N|AE11|B48|MGT227\_CLK1\_N|AD9|
|A49|GND|-|B49|GND|-|
|A50|MGT227\_RX3\_P|AD2|B50|MGT227\_TX3\_P|AD6|
|A51|MGT227\_RX3\_N|AD1|B51|MGT227\_TX3\_N|AD5|
|A52|GND|-|B52|GND|-|
|A53|MGT227\_RX2\_P|AE4|B53|MGT227\_TX2\_P|AE8|
|A54|MGT227\_RX2\_N|AE3|B54|MGT227\_TX2\_N|AE7|
|A55|GND|-|B55|GND|-|
|A56|MGT227\_RX1\_P|AF2|B56|MGT227\_TX1\_P|AF6|
|A57|MGT227\_RX1\_N|AF1|B57|MGT227\_TX1\_N|AF5|
|A58|GND|-|B58|GND|-|
|A59|MGT227\_RX0\_P|AG4|B59|MGT227\_TX0\_P|AG8|
|A60|MGT227\_RX0\_N|AG3|B60|MGT227\_TX0\_N|AG7|





|<p>**J1 管**</p><p>**脚**</p>|**信号名称**|<p>**FPGA 引**</p><p>**脚号**</p>|<p>**J1 管**</p><p>**脚**</p>|**信号名称**|**FPGA 引脚号**|
| :- | :- | :- | :- | :- | :-: |
|C1|MGT231\_CLK0\_P|U12|D1|MGT231\_CLK1\_P|T10|
|C2|MGT231\_CLK0\_N|U11|D2|MGT231\_CLK1\_N|T9|
|C3|GND|-|D3|GND|-|
|C4|MGT231\_RX3\_P|H2|D4|MGT231\_TX3\_P|H6|
|C5|MGT231\_RX3\_N|H1|D5|MGT231\_TX3\_N|H5|
|C6|GND|-|D6|GND|-|
|C7|MGT231\_RX2\_P|J4|D7|MGT231\_TX2\_P|J8|
|C8|MGT231\_RX2\_N|J3|D8|MGT231\_TX2\_N|J7|
|C9|GND|-|D9|GND|-|
|C10|MGT231\_RX1\_P|K2|D10|MGT231\_TX1\_P|K6|
|C11|MGT231\_RX1\_N|K1|D11|MGT231\_TX1\_N|K5|
|C12|GND|-|D12|GND|-|
|C13|MGT231\_RX0\_P|L4|D13|MGT231\_TX0\_P|L8|
|C14|MGT231\_RX0\_N|L3|D14|MGT231\_TX0\_N|L7|
|C15|GND|-|D15|GND|-|
|C16|MGT230\_RX3\_P|M2|D16|MGT230\_TX3\_P|M6|
|C17|MGT230\_RX3\_N|M1|D17|MGT230\_TX3\_N|M5|
|C18|GND|-|D18|GND|-|
|C19|MGT230\_RX2\_P|N4|D19|MGT230\_TX2\_P|N8|
|C20|MGT230\_RX2\_N|N3|D20|MGT230\_TX2\_N|N7|
|C21|GND|-|D21|GND|-|
|C22|MGT230\_RX1\_P|P2|D22|MGT230\_TX1\_P|P6|
|C23|MGT230\_RX1\_N|P1|D23|MGT230\_TX1\_N|P5|
|C24|GND|-|D24|GND|-|
|C25|MGT230\_RX0\_P|R4|D25|MGT230\_TX0\_P|R8|
|C26|MGT230\_RX0\_N|R3|D26|MGT230\_TX0\_N|R7|

|C27|GND|-|D27|GND|-|
| :-: | :-: | :-: | :-: | :-: | :-: |
|C28|MGT230\_CLK1\_P|V10|D28|MGT230\_CLK0\_P|W12|
|C29|MGT230\_CLK1\_N|V9|D29|MGT230\_CLK0\_N|W11|
|C30|GND|-|D30|GND|-|
|C31|MGT229\_RX3\_P|T2|D31|MGT229\_TX3\_P|T6|
|C32|MGT229\_RX3\_N|T1|D32|MGT229\_TX3\_N|T5|
|C33|GND|-|D33|GND|-|
|C34|MGT229\_RX2\_P|U4|D34|MGT229\_TX2\_P|U8|
|C35|MGT229\_RX2\_N|U3|D35|MGT229\_TX2\_N|U7|
|C36|GND|-|D36|GND|-|
|C37|MGT229\_RX1\_P|V2|D37|MGT229\_TX1\_P|V6|
|C38|MGT229\_RX1\_N|V1|D38|MGT229\_TX1\_N|V5|
|C39|GND|-|D39|GND|-|
|C40|MGT229\_RX0\_P|W4|D40|MGT229\_TX0\_P|W8|
|C41|MGT229\_RX0\_N|W3|D41|MGT229\_TX0\_N|W7|
|C42|GND|-|D42|GND|-|
|C43|MGT229\_CLK1\_P|Y10|D43|MGT229\_CLK0\_P|AA12|
|C44|MGT229\_CLK1\_N|Y9|D44|MGT229\_CLK0\_N|AA11|
|C45|GND|-|D45|GND|-|
|C46|GND|-|D46|GND|-|
|C47|MGT228\_RX3\_P|Y2|D47|MGT228\_TX3\_P|Y6|
|C48|MGT228\_RX3\_N|Y1|D48|MGT228\_TX3\_N|Y5|
|C49|GND|-|D49|GND|-|
|C50|MGT228\_RX2\_P|AA4|D50|MGT228\_TX2\_P|AA8|
|C51|MGT228\_RX2\_N|AA3|D51|MGT228\_TX2\_N|AA7|
|C52|GND|-|D52|GND|-|
|C53|MGT228\_RX1\_P|AB2|D53|MGT228\_TX1\_P|AB6|
|C54|MGT228\_RX1\_N|AB1|D54|MGT228\_TX1\_N|AB5|
|C55|GND|-|D55|GND|-|
|C56|MGT228\_RX0\_P|AC4|D56|MGT228\_TX0\_P|AC8|
|C57|MGT228\_RX0\_N|AC3|D57|MGT228\_TX0\_N|AC7|
|C58|GND|-|D58|GND|-|

|C59|MGT228\_CLK0\_P|AC12|D59|MGT228\_CLK1\_P|AB10|
| :-: | :-: | :-: | :-: | :-: | :-: |
|C60|MGT228\_CLK0\_N|AC11|D60|MGT228\_CLK1\_N|AB9|

##### **J2 连接器的引脚分配**

|**J2 管脚**|**信号名称**|<p>**FPGA 引**</p><p>**脚号**</p>|**J2 管脚**|**信号名称**|<p>**FPGA 引脚**</p><p>**号**</p>|
| -: | :- | :- | -: | :- | :- |
|A1|FPGA\_VP\_IN|W20|B1|FPGA\_TDI|AG24|
|A2|FPGA\_VN\_IN|Y19|B2|FPGA\_TDO|AG27|
|A3|GND|-|B3|GND|-|
|A4|B64\_L1\_P|AU22|B4|B64\_L19\_P|AH21|
|A5|B64\_L1\_N|AV22|B5|B64\_L19\_N|AJ21|
|A6|GND|-|B6|GND|-|
|A7|B64\_L21\_P|AJ20|B7|B64\_L10\_P|AK21|
|A8|B64\_L21\_N|AJ19|B8|B64\_L10\_N|AL21|
|A9|GND|-|B9|GND|-|
|A10|B64\_L8\_P|AL22|B10|B65\_L17\_P|AJ16|
|A11|B64\_L8\_N|AM22|B11|B65\_L17\_N|AJ15|
|A12|GND|-|B12|GND|-|
|A13|B65\_L18\_P|AK16|B13|B65\_L16\_P|AK17|
|A14|B65\_L18\_N|AL16|B14|B65\_L16\_N|AL17|
|A15|GND|-|B15|GND|-|
|A16|B65\_L20\_P|AN13|B16|B65\_L14\_P|AM15|
|A17|B65\_L20\_N|AP13|B17|B65\_L14\_N|AN15|
|A18|GND|-|B18|GND|-|
|A19|B65\_L11\_P|AR14|B19|B65\_L10\_P|AP16|
|A20|B65\_L11\_N|AT14|B20|B65\_L10\_N|AR16|
|A21|GND|-|B21|GND|-|
|A22|B65\_L7\_P|AV16|B22|B65\_L8\_P|AT15|
|A23|B65\_L7\_N|AW16|B23|B65\_L8\_N|AU15|
|A24|GND|-|B24|GND|-|
|A25|B65\_L9\_P|AV15|B25|B65\_L6\_P|AU14|
|A26|B65\_L9\_N|AW15|B26|B65\_L6\_N|AU13|

|A27|GND|-|B27|GND|-|
| :-: | :-: | :-: | :-: | :-: | :-: |
|<p></p><p>A28</p>|<p></p><p>VCCIO\_64</p>|<p>AK20、 AN19、</p><p>AT8</p>|<p></p><p>B28</p>|<p></p><p>B65\_T2U</p>|<p></p><p>AN16</p>|
|<p></p><p>A29</p>|<p></p><p>VCCIO\_65</p>|<p>AK15、 AN14、</p><p>AT13</p>|<p></p><p>B29</p>|<p></p><p>B65\_T3U</p>|<p></p><p>AP10</p>|
|A30|GND|-|B30|GND|-|
|A31|B65\_L5\_P|AV13|B31|B65\_L3\_P|AW14|
|A32|B65\_L5\_N|AV12|B32|B65\_L3\_N|AW13|
|A33|GND|-|B33|GND|-|
|A34|B65\_L12\_P|AP15|B34|B65\_L24\_P|AM14|
|A35|B65\_L12\_N|AP14|B35|B65\_L24\_N|AM13|
|A36|GND|-|B36|GND|-|
|A37|B65\_L13\_P|AL15|B37|B65\_L15\_P|AJ14|
|A38|B65\_L13\_N|AL14|B38|B65\_L15\_N|AK14|
|A39|GND|-|B39|GND|-|
|A40|B65\_L1\_P|AW11|B40|B65\_L4\_P|AU10|
|A41|B65\_L1\_N|AW10|B41|B65\_L4\_N|AV10|
|A42|GND|-|B42|GND|-|
|A43|B65\_L19\_P|AT12|B43|B65\_L23\_P|AP11|
|A44|B65\_L19\_N|AT11|B44|B65\_L23\_N|AR11|
|A45|GND|-|B45|GND|-|
|A46|GND|-|B46|GND|-|
|A47|MGT225\_RX0\_P|AR4|B47|MGT225\_TX0\_P|AR8|
|A48|MGT225\_RX0\_N|AR3|B48|MGT225\_TX0\_N|AR7|
|A49|GND|-|B49|GND|-|
|A50|MGT225\_RX1\_P|AP2|B50|MGT225\_TX1\_P|AP6|
|A51|MGT225\_RX1\_N|AP1|B51|MGT225\_TX1\_N|AP5|
|A52|GND|-|B52|GND|-|
|A53|MGT225\_RX2\_P|AN4|B53|MGT225\_TX2\_P|AN8|
|A54|MGT225\_RX2\_N|AN3|B54|MGT225\_TX2\_N|AN7|

|A55|GND|-|B55|GND|-|
| :-: | :-: | :-: | :-: | :-: | :-: |
|A56|MGT225\_RX3\_P|AM2|B56|MGT225\_TX3\_P|AM6|
|A57|MGT225\_RX3\_N|AM1|B57|MGT225\_TX3\_N|AM5|
|A58|GND|-|B58|GND|-|
|A59|MGT225\_CLK0\_P|AJ12|B59|MGT225\_CLK1\_P|AH10|
|A60|MGT225\_CLK0\_N|AJ11|B60|MGT225\_CLK1\_N|AH9|




|<p>**J2 管**</p><p>**脚**</p>|**信号名称**|<p>**FPGA 引脚**</p><p>**号**</p>|**J2 管脚**|**信号名称**|**FPGA 引脚号**|
| :- | :- | :- | :-: | :- | :-: |
|C1|FPGA\_TMS|AD22|D1|B64\_L9\_P|AP21|
|C2|FPGA\_TCK|AG23|D2|B64\_L9\_N|AP20|
|C3|GND|-|D3|GND|-|
|C4|B64\_L5\_P|AT22|D4|B64\_L7\_P|AR22|
|C5|B64\_L5\_N|AT21|D5|B64\_L7\_N|AR21|
|C6|GND|-|D6|GND|-|
|C7|B64\_L3\_P|AV21|D7|B64\_L15\_P|AT20|
|C8|B64\_L3\_N|AW21|D8|B64\_L15\_N|AT19|
|C9|GND|-|D9|GND|-|
|C10|B64\_L12\_P|AL20|D10|B64\_L2\_P|AU20|
|C11|B64\_L12\_N|AM20|D11|B64\_L2\_N|AV20|
|C12|GND|-|D12|GND|-|
|C13|B64\_L11\_P|AN21|D13|B64\_L17\_P|AU19|
|C14|B64\_L11\_N|AN20|D14|B64\_L17\_N|AU18|
|C15|GND|-|D15|GND|-|
|C16|B64\_L20\_P|AL19|D16|B64\_L4\_P|AW20|
|C17|B64\_L20\_N|AM19|D17|B64\_L4\_N|AW19|
|C18|GND|-|D18|GND|-|
|C19|B64\_L13\_P|AP19|D19|B64\_L6\_P|AV18|
|C20|B64\_L13\_N|AR19|D20|B64\_L6\_N|AW18|

|C21|GND|-|D21|GND|-|
| :-: | :-: | :-: | :-: | :-: | :-: |
|C22|B64\_L14\_P|AN18|D22|B64\_L16\_P|AT17|
|C23|B64\_L14\_N|AP18|D23|B64\_L16\_N|AU17|
|C24|GND|-|D24|GND|-|
|C25|B64\_L24\_P|AM18|D25|B64\_L18\_P|AR18|
|C26|B64\_L24\_N|AM17|D26|B64\_L18\_N|AR17|
|C27|GND|-|D27|GND|-|
|C28|B64\_L22\_P|AK19|D28|B64\_L23\_P|AH18|
|C29|B64\_L22\_N|AK18|D29|B64\_L23\_N|AJ18|
|C30|GND|-|D30|GND|-|
|C31|GND|-|D31|GND|-|
|C32|MGT224\_CLK0\_P|AM10|D32|MGT224\_CLK1\_P|AK10|
|C33|MGT224\_CLK0\_N|AM9|D33|MGT224\_CLK1\_N|AK9|
|C34|GND|-|D34|GND|-|
|C35|MGT224\_RX3\_P|AT2|D35|MGT224\_TX3\_P|AT6|
|C36|MGT224\_RX3\_N|AT1|D36|MGT224\_TX3\_N|AT5|
|C37|GND|-|D37|GND|-|
|C38|MGT224\_RX2\_P|AU4|D38|MGT224\_TX2\_P|AU8|
|C39|MGT224\_RX2\_N|AU3|D39|MGT224\_TX2\_N|AU7|
|C40|GND|-|D40|GND|-|
|C41|MGT224\_RX0\_P|AW4|D41|MGT224\_TX0\_P|AW8|
|C42|MGT224\_RX0\_N|AW3|D42|MGT224\_TX0\_N|AW7|
|C43|GND|-|D43|GND|-|
|C44|MGT224\_RX1\_P|AV2|D44|MGT224\_TX1\_P|AV6|
|C45|MGT224\_RX1\_N|AV1|D45|MGT224\_TX1\_N|AV5|
|C46|GND|-|D46|GND|-|
|C47|MGT226\_CLK0\_P|AG12|D47|MGT226\_CLK1\_P|AF10|
|C48|MGT226\_CLK0\_N|AG11|D48|MGT226\_CLK1\_N|AF9|
|C49|GND|-|D49|GND|-|
|C50|MGT226\_RX0\_P|AL4|D50|MGT226\_TX0\_P|AL8|
|C51|MGT226\_RX0\_N|AL3|D51|MGT226\_TX0\_N|AL7|
|C52|GND|-|D52|GND|-|

|C53|MGT226\_RX1\_P|AK2|D53|MGT226\_TX1\_P|AK6|
| :-: | :-: | :-: | :-: | :-: | :-: |
|C54|MGT226\_RX1\_N|AK1|D54|MGT226\_TX1\_N|AK5|
|C55|GND|-|D55|GND|-|
|C56|MGT226\_RX2\_P|AJ4|D56|MGT226\_TX2\_P|AJ8|
|C57|MGT226\_RX2\_N|AJ3|D57|MGT226\_TX2\_N|AJ7|
|C58|GND|-|D58|GND|-|
|C59|MGT226\_RX3\_P|AH2|D59|MGT226\_TX3\_P|AH6|
|C60|MGT226\_RX3\_N|AH1|D60|MGT226\_TX3\_N|AH5|

##### **J3 连接器的引脚分配**

|**J3 管脚**|**信号名称**|<p>**FPGA**</p><p>**引脚号**</p>|**J3 管脚**|**信号名称**|<p>**FPGA 引**</p><p>**脚号**</p>|
| :-: | :-: | :- | :-: | :-: | :-: |
|A1|+12V|-|B1|+12V|-|
|A2|+12V|-|B2|+12V|-|
|A3|GND|-|B3|GND|-|
|<p></p><p>A4</p>|<p></p><p>FMC1\_VREF\_A\_M2C\_1</p>|<p></p><p>M27</p>|<p></p><p>B4</p>|<p></p><p>VCCIO\_71</p>|<p>B18、 E17、</p><p>H16</p>|
|A5|VCCAUX\_PG|-|B5|FMC1\_VREF\_A\_M2C\_2|M24|
|A6|GND|-|B6|GND|-|
|A7|MGT131\_RX3\_P|J38|B7|MGT131\_TX3\_P|E33|
|A8|MGT131\_RX3\_N|J39|B8|MGT131\_TX3\_N|E34|
|A9|GND|-|B9|GND|-|
|A10|MGT131\_RX2\_P|K36|B10|MGT131\_TX2\_P|F35|
|A11|MGT131\_RX2\_N|K37|B11|MGT131\_TX2\_N|F36|
|A12|GND|-|B12|GND|-|
|A13|MGT131\_RX1\_P|L38|B13|MGT131\_TX1\_P|G33|
|A14|MGT131\_RX1\_N|L39|B14|MGT131\_TX1\_N|G34|
|A15|GND|-|B15|GND|-|
|A16|MGT131\_RX0\_P|M36|B16|MGT131\_TX0\_P|J33|
|A17|MGT131\_RX0\_N|M37|B17|MGT131\_TX0\_N|J34|

|A18|GND|-|B18|GND|-|
| :-: | :-: | :-: | :-: | :-: | :-: |
|A19|MGT131\_CLK0\_P|T27|B19|MGT131\_CLK1\_P|R29|
|A20|MGT131\_CLK0\_N|T28|B20|MGT131\_CLK1\_N|R30|
|A21|GND|-|B21|GND|-|
|A22|MGT129\_RX3\_P|U38|B22|MGT129\_TX3\_P|R33|
|A23|MGT129\_RX3\_N|U39|B23|MGT129\_TX3\_N|R34|
|A24|GND|-|B24|GND|-|
|A25|MGT129\_RX2\_P|V36|B25|MGT129\_TX2\_P|T31|
|A26|MGT129\_RX2\_N|V37|B26|MGT129\_TX2\_N|T32|
|A27|GND|-|B27|GND|-|
|A28|MGT129\_RX1\_P|W38|B28|MGT129\_TX1\_P|U33|
|A29|MGT129\_RX1\_N|W39|B29|MGT129\_TX1\_N|U34|
|A30|GND|-|B30|GND|-|
|A31|MGT129\_RX0\_P|Y36|B31|MGT129\_TX0\_P|V31|
|A32|MGT129\_RX0\_N|Y37|B32|MGT129\_TX0\_N|V32|
|A33|GND|-|B33|GND|-|
|A34|MGT129\_CLK0\_P|Y27|B34|MGT129\_CLK1\_P|W29|
|A35|MGT129\_CLK0\_N|Y28|B35|MGT129\_CLK1\_N|W30|
|A36|GND|-|B36|GND|-|
|A37|MGT127\_CLK0\_P|AE29|B37|MGT127\_CLK1\_P|AC29|
|A38|MGT127\_CLK0\_N|AE30|B38|MGT127\_CLK1\_N|AC30|
|A39|GND|-|B39|GND|-|
|A40|MGT127\_RX3\_P|AE38|B40|MGT127\_TX3\_P|AC33|
|A41|MGT127\_RX3\_N|AE39|B41|MGT127\_TX3\_N|AC34|
|A42|GND|-|B42|GND|-|
|A43|MGT127\_RX2\_P|AF36|B43|MGT127\_TX2\_P|AD31|
|A44|MGT127\_RX2\_N|AF37|B44|MGT127\_TX2\_N|AD32|
|A45|GND|-|B45|GND|-|
|A46|MGT127\_RX1\_P|AG38|B46|MGT127\_TX1\_P|AE33|
|A47|MGT127\_RX1\_N|AG39|B47|MGT127\_TX1\_N|AE34|
|A48|GND|-|B48|GND|-|
|A49|MGT127\_RX0\_P|AH36|B49|MGT127\_TX0\_P|AF31|

|A50|MGT127\_RX0\_N|AH37|B50|MGT127\_TX0\_N|AF32|
| :-: | :-: | :-: | :-: | :-: | :-: |
|A51|GND|-|B51|GND|-|
|A52|FMC2\_VREF\_A\_M2C\_1|AH20|B52|NC|-|
|A53|FMC2\_VREF\_A\_M2C\_2|AH16|B53|NC|-|
|A54|GND|-|B54|GND|-|
|A55|NC|-|B55|NC|-|
|A56|NC|-|B56|NC|-|
|A57|GND|-|B57|GND|-|
|A58|NC|-|B58|NC|-|
|A59|NC|-|B59|NC|-|
|A60|GND|-|B60|GND|-|



|<p>**J3 管**</p><p>**脚**</p>|**信号名称**|<p>**FPGA 引**</p><p>**脚号**</p>|<p>**J3 管**</p><p>**脚**</p>|**信号名称**|**FPGA 引脚号**|
| :- | :- | :- | :- | :- | :-: |
|C1|+12V|-|D1|+12V|-|
|C2|+12V|-|D2|+12V|-|
|C3|GND|-|D3|GND|-|
|C4|VCCIO\_70|<p>B23、</p><p>E22、H21</p>|D4|VCCIO\_69|<p>B28、E27、</p><p>H26</p>|
|C5|FMC1\_VREF\_A\_M 2C\_3|M17|D5|NC|-|
|C6|GND|-|D6|GND|-|
|C7|MGT132\_RX3\_P|C38|D7|MGT132\_TX3\_P|A33|
|C8|MGT132\_RX3\_N|C39|D8|MGT132\_TX3\_N|A34|
|C9|GND|-|D9|GND|-|
|C10|MGT132\_RX2\_P|E38|D10|MGT132\_TX2\_P|B35|
|C11|MGT132\_RX2\_N|E39|D11|MGT132\_TX2\_N|B36|
|C12|GND|-|D12|GND|-|
|C13|MGT132\_RX1\_P|G38|D13|MGT132\_TX1\_P|C33|
|C14|MGT132\_RX1\_N|G39|D14|MGT132\_TX1\_N|C34|

|C15|GND|-|D15|GND|-|
| :-: | :-: | :-: | :-: | :-: | :-: |
|C16|MGT132\_RX0\_P|H36|D16|MGT132\_TX0\_P|D35|
|C17|MGT132\_RX0\_N|H37|D17|MGT132\_TX0\_N|D36|
|C18|GND|-|D18|GND|-|
|C19|MGT132\_CLK0\_P|P27|D19|MGT132\_CLK1\_P|N29|
|C20|MGT132\_CLK0\_N|P28|D20|MGT132\_CLK1\_N|N30|
|C21|GND|-|D21|GND|-|
|C22|MGT130\_RX3\_P|N38|D22|MGT130\_TX3\_P|L33|
|C23|MGT130\_RX3\_N|N39|D23|MGT130\_TX3\_N|L34|
|C24|GND|-|D24|GND|-|
|C25|MGT130\_RX2\_P|P36|D25|MGT130\_TX2\_P|M31|
|C26|MGT130\_RX2\_N|P37|D26|MGT130\_TX2\_N|M32|
|C27|GND|-|D27|GND|-|
|C28|MGT130\_RX1\_P|R38|D28|MGT130\_TX1\_P|N33|
|C29|MGT130\_RX1\_N|R39|D29|MGT130\_TX1\_N|N34|
|C30|GND|-|D30|GND|-|
|C31|MGT130\_RX0\_P|T36|D31|MGT130\_TX0\_P|P31|
|C32|MGT130\_RX0\_N|T37|D32|MGT130\_TX0\_N|P32|
|C33|GND|-|D33|GND|-|
|C34|MGT130\_CLK0\_P|V27|D34|MGT130\_CLK1\_P|U29|
|C35|MGT130\_CLK0\_N|V28|D35|MGT130\_CLK1\_N|U30|
|C36|GND|-|D36|GND|-|
|C37|MGT128\_CLK0\_P|AB27|D37|MGT128\_CLK1\_P|AA29|
|C38|MGT128\_CLK0\_N|AB28|D38|MGT128\_CLK1\_N|AA30|
|C39|GND|-|D39|GND|-|
|C40|MGT128\_RX3\_P|AA38|D40|MGT128\_TX3\_P|W33|
|C41|MGT128\_RX3\_N|AA39|D41|MGT128\_TX3\_N|W34|
|C42|GND|-|D42|GND|-|
|C43|MGT128\_RX2\_P|AB36|D43|MGT128\_TX2\_P|Y31|
|C44|MGT128\_RX2\_N|AB37|D44|MGT128\_TX2\_N|Y32|
|C45|GND|-|D45|GND|-|
|C46|MGT128\_RX1\_P|AC38|D46|MGT128\_TX1\_P|AA33|

|C47|MGT128\_RX1\_N|AC39|D47|MGT128\_TX1\_N|AA34|
| :-: | :-: | :-: | :-: | :-: | :-: |
|C48|GND|-|D48|GND|-|
|C49|MGT128\_RX0\_P|AD36|D49|MGT128\_TX0\_P|AB31|
|C50|MGT128\_RX0\_N|AD37|D50|MGT128\_TX0\_N|AB32|
|C51|GND|-|D51|GND|-|
|C52|NC|-|D52|NC|-|
|C53|NC|-|D53|NC|-|
|C54|GND|-|D54|GND|-|
|C55|NC|-|D55|NC|-|
|C56|NC|-|D56|NC|-|
|C57|GND|-|D57|GND|-|
|C58|NC|-|D58|NC|-|
|C59|NC|-|D59|NC|-|
|C60|GND|-|D60|GND|-|

##### **J4 连接器的引脚分配**

|**J4 管脚**|**信号名称**|<p>**FPGA 引**</p><p>**脚号**</p>|**J4 管脚**|**信号名称**|<p>**FPGA 引**</p><p>**脚号**</p>|
| -: | :- | :- | -: | :- | :- |
|<p></p><p>A1</p>|<p></p><p>VCCO\_90\_91\_93\_94</p>|<p>E2、F5、 B8、F10、 K12、 N11、</p><p>B13、G13</p>|<p></p><p>B1</p>|<p></p><p>POWER\_SCL</p>|<p></p><p>-</p>|
|A2|GND|-|B2|GND|-|
|A3|B94\_L9\_N|C12|B3|B94\_L6\_N|E11|
|A4|B94\_L9\_P|D12|B4|B94\_L6\_P|F11|
|A5|B94\_L8\_N|D13|B5|B94\_L7\_N|F12|
|A6|B94\_L8\_P|E13|B6|B94\_L7\_P|F13|
|A7|GND|-|B7|GND|-|
|A8|B71\_L1\_N|M15|B8|B71\_L10\_N|F14|
|A9|B71\_L1\_P|M16|B9|B71\_L10\_P|G15|
|A10|GND|-|B10|GND|-|

|A11|B71\_L18\_N|D15|B11|B71\_L4\_N|L16|
| :-: | :-: | :-: | :-: | :-: | :-: |
|A12|B71\_L18\_P|D16|B12|B71\_L4\_P|L17|
|A13|GND|-|B13|GND|-|
|A14|B71\_L6\_N|K14|B14|B71\_L5\_N|J16|
|A15|B71\_L6\_P|K15|B15|B71\_L5\_P|K16|
|A16|GND|-|B16|GND|-|
|A17|B71\_L14\_N|F16|B17|B71\_L11\_N|G16|
|A18|B71\_L14\_P|F17|B18|B71\_L11\_P|G17|
|A19|GND|-|B19|GND|-|
|A20|B70\_L11\_N|F21|B20|B70\_L20\_N|B20|
|A21|B70\_L11\_P|G21|B21|B70\_L20\_P|C20|
|A22|GND|-|B22|GND|-|
|A23|B70\_L2\_N|M20|B23|B70\_L18\_N|D20|
|A24|B70\_L2\_P|M19|B24|B70\_L18\_P|E20|
|A25|GND|-|B25|GND|-|
|A26|B70\_L6\_N|K21|B26|B70\_L1\_N|M22|
|A27|B70\_L6\_P|K20|B27|B70\_L1\_P|M21|
|A28|GND|-|B28|GND|-|
|A29|B70\_L7\_N|H22|B29|B70\_L8\_N|J21|
|A30|B70\_L7\_P|J22|B30|B70\_L8\_P|J20|
|A31|GND|-|B31|GND|-|
|A32|B70\_L4\_N|L22|B32|B70\_L17\_N|D21|
|A33|B70\_L4\_P|L21|B33|B70\_L17\_P|E21|
|A34|GND|-|B34|GND|-|
|A35|B70\_L3\_N|L24|B35|B70\_L16\_N|D23|
|A36|B70\_L3\_P|L23|B36|B70\_L16\_P|D22|
|A37|GND|-|B37|GND|-|
|A38|B70\_L14\_N|E24|B38|B70\_L15\_N|D25|
|A39|B70\_L14\_P|E23|B39|B70\_L15\_P|E25|
|A40|GND|-|B40|GND|-|
|A41|B70\_L13\_N|F24|B41|B70\_L9\_N|G24|
|A42|B70\_L13\_P|F23|B42|B70\_L9\_P|H24|

|A43|GND|-|B43|GND|-|
| :-: | :-: | :-: | :-: | :-: | :-: |
|A44|B69\_L3\_N|L27|B44|B69\_L1\_N|M26|
|A45|B69\_L3\_P|L26|B45|B69\_L1\_P|M25|
|A46|GND|-|B46|GND|-|
|A47|B69\_L5\_N|J26|B47|B69\_L4\_N|H25|
|A48|B69\_L5\_P|K26|B48|B69\_L4\_P|J25|
|A49|GND|-|B49|GND|-|
|A50|B69\_L2\_N|H27|B50|B69\_L11\_N|F27|
|A51|B69\_L2\_P|J27|B51|B69\_L11\_P|G27|
|A52|GND|-|B52|GND|-|
|A53|B69\_L24\_N|A29|B53|B69\_L9\_N|H28|
|A54|B69\_L24\_P|A28|B54|B69\_L9\_P|J28|
|A55|GND|-|B55|GND|-|
|A56|B69\_L16\_N|D30|B56|B69\_L8\_N|H30|
|A57|B69\_L16\_P|E30|B57|B69\_L8\_P|H29|
|A58|GND|-|B58|GND|-|
|A59|B69\_L15\_N|D31|B59|B69\_L7\_N|J31|
|A60|B69\_L15\_P|E31|B60|B69\_L7\_P|J30|




|<p>**J4 管**</p><p>**脚**</p>|**信号名称**|<p>**FPGA 引脚**</p><p>**号**</p>|**J4 管脚**|**信号名称**|**FPGA 引脚号**|
| :- | :- | :- | :-: | :- | :-: |
|C1|POWER\_SDA|-|D1|POWER\_ALT|-|
|C2|GND|-|D2|GND|-|
|C3|B94\_L4\_N|G10|D3|B94\_L2\_N|J10|
|C4|B94\_L4\_P|H10|D4|B94\_L2\_P|J11|
|C5|B94\_L1\_N|J12|D5|B94\_L3\_N|H12|
|C6|B94\_L1\_P|J13|D6|B94\_L3\_P|H13|
|C7|GND|-|D7|GND|-|
|C8|B71\_L16\_N|E15|D8|B71\_L24\_N|A16|

|C9|B71\_L16\_P|E16|D9|B71\_L24\_P|B17|
| :-: | :-: | :-: | :-: | :-: | :-: |
|C10|GND|-|D10|GND|-|
|C11|B71\_L20\_N|C14|D11|B71\_L23\_N|A17|
|C12|B71\_L20\_P|C15|D12|B71\_L23\_P|A18|
|C13|GND|-|D13|GND|-|
|C14|B71\_L22\_N|B15|D14|B71\_L9\_N|G14|
|C15|B71\_L22\_P|B16|D15|B71\_L9\_P|H14|
|C16|GND|-|D16|GND|-|
|C17|B71\_L7\_N|H15|D17|B71\_L8\_N|H17|
|C18|B71\_L7\_P|J15|D18|B71\_L8\_P|H18|
|C19|GND|-|D19|GND|-|
|C20|B71\_L13\_N|F18|D20|B71\_L12\_N|G19|
|C21|B71\_L13\_P|F19|D21|B71\_L12\_P|H19|
|C22|GND|-|D22|GND|-|
|C23|B71\_L3\_N|K18|D23|B71\_L19\_N|C17|
|C24|B71\_L3\_P|L18|D24|B71\_L19\_P|C18|
|C25|GND|-|D25|GND|-|
|C26|B71\_L21\_N|A19|D26|B71\_L17\_N|D17|
|C27|B71\_L21\_P|B19|D27|B71\_L17\_P|D18|
|C28|GND|-|D28|GND|-|
|C29|B71\_L2\_N|K19|D29|B71\_L15\_N|E18|
|C30|B71\_L2\_P|L19|D30|B71\_L15\_P|E19|
|C31|GND|-|D31|GND|-|
|C32|B70\_L10\_N|G20|D32|B70\_L21\_N|A21|
|C33|B70\_L10\_P|H20|D33|B70\_L21\_P|B21|
|C34|GND|-|D34|GND|-|
|C35|B70\_L12\_N|F22|D35|B70\_L22\_N|A22|
|C36|B70\_L12\_P|G22|D36|B70\_L22\_P|B22|
|C37|GND|-|D37|GND|-|
|C38|B70\_L24\_N|A24|D38|B70\_L5\_N|K24|
|C39|B70\_L24\_P|A23|D39|B70\_L5\_P|K23|
|C40|GND|-|D40|GND|-|

|C41|B70\_L19\_N|C23|D41|B70\_L23\_N|B25|
| :-: | :-: | :-: | :-: | :-: | :-: |
|C42|B70\_L19\_P|C22|D42|B70\_L23\_P|B24|
|C43|GND|-|D43|GND|-|
|C44|B69\_L6\_N|G26|D44|B69\_L13\_N|F29|
|C45|B69\_L6\_P|G25|D45|B69\_L13\_P|F28|
|C46|GND|-|D46|GND|-|
|C47|B69\_L17\_N|D26|D47|B69\_L14\_N|E29|
|C48|B69\_L17\_P|E26|D48|B69\_L14\_P|E28|
|C49|GND|-|D49|GND|-|
|C50|B69\_L18\_N|D28|D50|B69\_L22\_N|A27|
|C51|B69\_L18\_P|D27|D51|B69\_L22\_P|B27|
|C52|GND|-|D52|GND|-|
|C53|B69\_L20\_N|C28|D53|B69\_L19\_N|B29|
|C54|B69\_L20\_P|C27|D54|B69\_L19\_P|C29|
|C55|GND|-|D55|GND|-|
|C56|B69\_L12\_N|G30|D56|B69\_L23\_N|A26|
|C57|B69\_L12\_P|G29|D57|B69\_L23\_P|B26|
|C58|GND|-|D58|GND|-|
|C59|B69\_L10\_N|F31|D59|B69\_L21\_N|A31|
|C60|B69\_L10\_P|G31|D60|B69\_L21\_P|B31|

## **三、	<a name="三、扩展板"></a><a name="_bookmark13"></a>扩展板**
### **(一) 简介**
通过前面的功能简介，我们可以了解到扩展板部分的功能

- PCIe3.0 x16 接口
- 1 路千兆网接口
- 2 路 FMC HPC 接口
- 2 路 MIPI 输入接口
- USB Uart 接口
- Micro SD 卡座
- 2 路 STATA 接口
- 40 针扩展口
- JTAG 调试口
- LED 灯
- 按键
### **(二) <a name="_bookmark15"></a>PCIe 插槽**
AXKU15 扩展板上有一个 PCIe x16 的接口，支持 PCIe Gen3.0 协议， 8 对收发器连接到 PCIEx16 的金手指上进行数据通信。

PCIe 接口的收发信号直接跟 FPGA BANK228~231 收发器相连接，16 路 TX 信号和 RX信号都是以差分信号方式连接到 FPGA 的收发器上，单通道通信速率可高达 8G bit 带宽。

开发板的 PCIe 接口的设计示意图如下图 3-2-1 所示,其中 TX 发送信号用 AC 耦合模式连接。



图 3-2-1 PCIe 插槽设计示意图
##### **PCIe x16 接口 FPGA 引脚分配如下：**

|**信号名称**|**FPGA 引脚名**|**引脚号**|**备注**|
| :-: | :-: | :-: | :-: |
|PCIE\_RX0\_P|MGT231\_RX3\_P|H2|PCIE 通道 0 数据接收正|
|PCIE\_RX0\_N|MGT231\_RX3\_N|H1|PCIE 通道 0 数据接收负|
|PCIE\_RX1\_P|MGT231\_RX2\_P|J4|PCIE 通道 1 数据接收正|
|PCIE\_RX1\_N|MGT231\_RX2\_N|J3|PCIE 通道 1 数据接收负|
|PCIE\_RX2\_P|MGT231\_RX1\_P|K2|PCIE 通道 2 数据接收正|
|PCIE\_RX2\_N|MGT231\_RX1\_N|K1|PCIE 通道 2 数据接收负|
|PCIE\_RX3\_P|MGT231\_RX0\_P|L4|PCIE 通道 3 数据接收正|
|PCIE\_RX3\_N|MGT231\_RX0\_N|L3|PCIE 通道 3 数据接收负|
|PCIE\_RX4\_P|MGT230\_RX3\_P|M2|PCIE 通道 4 数据接收正|
|PCIE\_RX4\_N|MGT230\_RX3\_N|M1|PCIE 通道 4 数据接收负|
|PCIE\_RX5\_P|MGT230\_RX2\_P|N4|PCIE 通道 5 数据接收正|
|PCIE\_RX5\_N|MGT230\_RX2\_N|N3|PCIE 通道 5 数据接收负|
|PCIE\_RX6\_P|MGT230\_RX1\_P|P2|PCIE 通道 6 数据接收正|
|PCIE\_RX6\_N|MGT230\_RX1\_N|P1|PCIE 通道 6 数据接收负|
|PCIE\_RX7\_P|MGT230\_RX0\_P|R4|PCIE 通道 7 数据接收正|
|PCIE\_RX7\_N|MGT230\_RX0\_N|R3|PCIE 通道 7 数据接收负|

|PCIE\_RX8\_P|MGT229\_RX3\_P|T2|PCIE 通道 8 数据发送正|
| :-: | :-: | :-: | :-: |
|PCIE\_RX8\_N|MGT229\_RX3\_N|T1|PCIE 通道 8 数据发送负|
|PCIE\_RX9\_P|MGT229\_RX2\_P|U4|PCIE 通道 9 数据发送正|
|PCIE\_RX9\_N|MGT229\_RX2\_N|U3|PCIE 通道 9 数据发送负|
|PCIE\_RX10\_P|MGT229\_RX1\_P|V2|PCIE 通道 10 数据发送正|
|PCIE\_RX10\_N|MGT229\_RX1\_N|V1|PCIE 通道 10 数据发送负|
|PCIE\_RX11\_P|MGT229\_RX0\_P|W4|PCIE 通道 11 数据发送正|
|PCIE\_RX11\_N|MGT229\_RX0\_N|W3|PCIE 通道 11 数据发送负|
|PCIE\_RX12\_P|MGT228\_RX3\_P|Y2|PCIE 通道 12 数据发送正|
|PCIE\_RX12\_N|MGT228\_RX3\_N|Y1|PCIE 通道 12 数据发送负|
|PCIE\_RX13\_P|MGT228\_RX2\_P|AA4|PCIE 通道 13 数据发送正|
|PCIE\_RX13\_N|MGT228\_RX2\_N|AA3|PCIE 通道 13 数据发送负|
|PCIE\_RX14\_P|MGT228\_RX1\_P|AB2|PCIE 通道 14 数据发送正|
|PCIE\_RX14\_N|MGT228\_RX1\_N|AB1|PCIE 通道 14 数据发送负|
|PCIE\_RX15\_P|MGT228\_RX0\_P|AC4|PCIE 通道 15 数据发送正|
|PCIE\_RX15\_N|MGT228\_RX0\_N|AC3|PCIE 通道 15 数据发送负|
|PCIE\_TX0\_P|MGT231\_TX3\_P|H6|PCIE 通道 0 数据发送正|
|PCIE\_TX0\_N|MGT231\_TX3\_N|H5|PCIE 通道 0 数据发送负|
|PCIE\_TX1\_P|MGT231\_TX2\_P|J8|PCIE 通道 1 数据发送正|
|PCIE\_TX1\_N|MGT231\_TX2\_N|J7|PCIE 通道 1 数据发送负|
|PCIE\_TX2\_P|MGT231\_TX1\_P|K6|PCIE 通道 2 数据发送正|
|PCIE\_TX2\_N|MGT231\_TX1\_N|K5|PCIE 通道 2 数据发送负|
|PCIE\_TX3\_P|MGT231\_TX0\_P|L8|PCIE 通道 3 数据发送正|
|PCIE\_TX3\_N|MGT231\_TX0\_N|L7|PCIE 通道 3 数据发送负|
|PCIE\_TX4\_P|MGT230\_TX3\_P|M6|PCIE 通道 4 数据发送正|
|PCIE\_TX4\_N|MGT230\_TX3\_N|M5|PCIE 通道 4 数据发送负|
|PCIE\_TX5\_P|MGT230\_TX2\_P|N8|PCIE 通道 5 数据发送正|
|PCIE\_TX5\_N|MGT230\_TX2\_N|N7|PCIE 通道 5 数据发送负|
|PCIE\_TX6\_P|MGT230\_TX1\_P|P6|PCIE 通道 6 数据发送正|
|PCIE\_TX6\_N|MGT230\_TX1\_N|P5|PCIE 通道 6 数据发送负|
|PCIE\_TX7\_P|MGT230\_TX0\_P|R8|PCIE 通道 7 数据发送正|
|PCIE\_TX7\_N|MGT230\_TX0\_N|R7|PCIE 通道 7 数据发送负|

|PCIE\_TX8\_P|MGT229\_TX3\_P|T6|PCIE 通道 8 数据发送正|
| :-: | :-: | :-: | :-: |
|PCIE\_TX8\_N|MGT229\_TX3\_N|T5|PCIE 通道 8 数据发送负|
|PCIE\_TX9\_P|MGT229\_TX2\_P|U8|PCIE 通道 9 数据发送正|
|PCIE\_TX9\_N|MGT229\_TX2\_N|U7|PCIE 通道 9 数据发送负|
|PCIE\_TX10\_P|MGT229\_TX1\_P|V6|PCIE 通道 10 数据发送正|
|PCIE\_TX10\_N|MGT229\_TX1\_N|V5|PCIE 通道 10 数据发送负|
|PCIE\_TX11\_P|MGT229\_TX0\_P|W8|PCIE 通道 11 数据发送正|
|PCIE\_TX11\_N|MGT229\_TX0\_N|W7|PCIE 通道 11 数据发送负|
|PCIE\_TX12\_P|MGT228\_TX3\_P|Y6|PCIE 通道 12 数据发送正|
|PCIE\_TX12\_N|MGT228\_TX3\_N|Y5|PCIE 通道 12 数据发送负|
|PCIE\_TX13\_P|MGT228\_TX2\_P|AA8|PCIE 通道 13 数据发送正|
|PCIE\_TX13\_N|MGT228\_TX2\_N|AA7|PCIE 通道 13 数据发送负|
|PCIE\_TX14\_P|MGT228\_TX1\_P|AB6|PCIE 通道 14 数据发送正|
|PCIE\_TX14\_N|MGT228\_TX1\_N|AB5|PCIE 通道 14 数据发送负|
|PCIE\_TX15\_P|MGT228\_TX0\_P|AC8|PCIE 通道 15 数据发送正|
|PCIE\_TX15\_N|MGT228\_TX0\_N|AC7|PCIE 通道 15 数据发送负|
|PCIE\_CLK\_P|MGT229\_CLK0\_P|AA12|PCIE 通道参考时钟正|
|PCIE\_CLK\_N|MGT229\_CLK0\_N|AA11|PCIE 通道参考时钟负|
|FPGA\_PCIE\_PERST\_n|B65\_T3U|AP10|PCIE 复位信号|
### **(三) 千兆网接口**
开发板上通过一片JL21221D 以太网 PHY 芯片为用户提供网络通信服务。以太网 PHY 芯片是连接到 FPGA 的 IO 接口上。JL21221D 芯片支持 10/100/1000 Mbps 网络传输速率，通过 RGMII 接口跟 FPGA 进行数据通信。JL21221D 芯片支持ＭDI/MDX 自适应，各种速度自适应，Master/Slave 自适应，支持 MDIO 总线进行 PHY 的寄存器管理。

JL21221D 上电会检测一些特定的 IO 的电平状态，从而确定自己的工作模式。表 3-2-1 描述了 GPHY 芯片上电之后的默认设定信息。

表 3-2-1 PHY 芯片默认配置值

|**配置 Pin 脚**|**说明**|**配置值**|
| :- | :-: | :-: |
|<p>RXD3\_ADR0</p><p>RXC\_ADR1</p>|<p>MDIO/MDC 模式的</p><p>PHY 地址</p>|PHY Address 为 001|

|RXCTL\_ADR2|||
| :-: | :- | :- |
|RXD1\_TXDLY|TX 时钟 2ns 延时|延时|
|RXD0\_RXDLY|RX 时钟 2ns 延时|延时|

当网络连接到千兆以太网时，FPGA 和 PHY 芯片 JL2121 的数据传输时通过 RGMII 总线通信，传输时钟为 125Mhz，数据在时钟的上升沿和下降样采样。

当网络连接到百兆以太网时，FPGA 和 PHY 芯片 JL2121 的数据传输时通过 RMII 总线通信，传输时钟为 25Mhz。数据在时钟的上升沿和下降样采样。

图 3-3-1 为 FPGA 与以太网 PHY 芯片连接示意图:



图 3-3-1 千兆网接口连接原理图

图 3-3-2 为以太网 PHY 芯片的实物图


|||||
| :-: | :-: | :-: | :-: |
|||||


图 3-3-2 以太网 PHY 芯片实物图以太网PHY 的 FPGA 引脚分配如下：

|ETH\_MDIO|B65\_L1\_P|AW11|MDIO 管理数据|
| :-: | :-: | :-: | :-: |
|ETH\_RESET|B64\_L24\_P|AM18|PHY 芯片复位|
|ETH\_RXCK|B65\_L16\_P|AK17|RGMII 接收时钟|
|ETH\_RXCTL|B65\_L16\_N|AL17|接收数据有效信号|
|ETH\_RXD0|B65\_L18\_N|AL16|接收数据 Bit0|
|ETH\_RXD1|B65\_L18\_P|AK16|接收数据 Bit1|
|ETH\_RXD2|B65\_L20\_N|AP13|接收数据 Bit2|
|ETH\_RXD3|B65\_L20\_P|AN13|接收数据 Bit3|
|ETH\_TXCK|B65\_L23\_P|AP11|RGMII 发送时钟|
|ETH\_TXCTL|B65\_L23\_N|AR11|发送使能信号|
|ETH\_TXD0|B65\_L15\_P|AJ14|发送数据 bit0|
|ETH\_TXD1|B65\_L15\_N|AK14|发送数据 bit1|
|ETH\_TXD2|B65\_L6\_P|AU14|发送数据 bit2|
|ETH\_TXD3|B65\_L6\_N|AU13|发送数据 bit3|
### **(四) <a name="_bookmark17"></a>FMCHPC 接口**
开发板带有 2 路 FMC HPC 扩展口，分别为 FMC1（J12）和 FMC2（J13），可以外接 XILINX 或者我们黑金的各种 FMC 模块（HDMI 输入输出模块，双目摄像头模块，高速 AD模块等等）。

FMC1 扩展口包含 34 对LA 信号差分对、2 对时钟信号及 24 对HA 信号，分别连接 FPGA芯片 BANK69，BANK70，BANK71，电平标准默认为 1.8V。8 路高速 GTH 收发信号连接 FPGA 芯片 BANK226，BANK227 的 IO 上。

FPGA 和 FMC HPC 连接器的原理图如图 3-4-1 所示：


##### **FMC HPC J12 连接器引脚分配如下：**

|**信号名**|**FPGA 引脚名**|<p>**FPGA 引**</p><p>**脚号**</p>|**备注**|
| :-: | :- | :-: | :-: |
|FMC1\_CLK0\_N|B70\_L11\_N|F21|FMC 第 0 路输入参考时钟N|
|FMC1\_CLK0\_P|B70\_L11\_P|G21|FMC 第 0 路输入参考时钟P|
|FMC1\_CLK1\_N|B69\_L12\_N|G30|FMC 第 1 路输入参考时钟N|
|FMC1\_CLK1\_P|B69\_L12\_P|G29|FMC 第 1 路输入参考时钟P|
|FMC1\_LA00\_CC\_N|B70\_L14\_N|E24|FMC LA 第 0 路数据（时钟）N|
|FMC1\_LA00\_CC\_P|B70\_L14\_P|E23|FMC LA 第 0 路数据（时钟）P|
|FMC1\_LA01\_CC\_N|B70\_L13\_N|F24|FMC LA 第 1 路数据（时钟）N|
|FMC1\_LA01\_CC\_P|B70\_L13\_P|F23|FMC LA 第 1 路数据（时钟）P|
|FMC1\_LA02\_N|B70\_L17\_N|D21|FMC LA 第 2 路数据N|
|FMC1\_LA02\_P|B70\_L17\_P|E21|FMC LA 第 2 路数据P|
|FMC1\_LA03\_N|B70\_L24\_N|A24|FMC LA 第 3 路数据N|
|FMC1\_LA03\_P|B70\_L24\_P|A23|FMC LA 第 3 路数据P|
|FMC1\_LA04\_N|B70\_L12\_N|F22|FMC LA 第 4 路数据N|
|FMC1\_LA04\_P|B70\_L12\_P|G22|FMC LA 第 4 路数据P|
|FMC1\_LA05\_N|B70\_L6\_N|K21|FMC LA 第 5 路数据N|
|FMC1\_LA05\_P|B70\_L6\_P|K20|FMC LA 第 5 路数据P|
|FMC1\_LA06\_N|B70\_L5\_N|K24|FMC LA 第 6 路数据P|
|FMC1\_LA06\_P|B70\_L5\_P|K23|FMC LA 第 6 路数据P|

|FMC1\_LA07\_N|B70\_L4\_N|L22|FMC LA 第 7 路数据N|
| :- | :- | :- | :- |
|FMC1\_LA07\_P|B70\_L4\_P|L21|FMC LA 第 7 路数据P|
|FMC1\_LA08\_N|B70\_L3\_N|L24|FMC LA 第 8 路数据N|
|FMC1\_LA08\_P|B70\_L3\_P|L23|FMC LA 第 8 路数据P|
|FMC1\_LA09\_N|B70\_L2\_N|M20|FMC LA 第 9 路数据N|
|FMC1\_LA09\_P|B70\_L2\_P|M19|FMC LA 第 9 路数据P|
|FMC1\_LA10\_N|B70\_L18\_N|D20|FMC LA 第 10 路数据 N|
|FMC1\_LA10\_P|B70\_L18\_P|E20|FMC LA 第 10 路数据 P|
|FMC1\_LA11\_N|B70\_L23\_N|B25|FMC LA 第 11 路数据 N|
|FMC1\_LA11\_P|B70\_L23\_P|B24|FMC LA 第 11 路数据 P|
|FMC1\_LA12\_N|B70\_L1\_N|M22|FMC LA 第 12 路数据 N|
|FMC1\_LA12\_P|B70\_L1\_P|M21|FMC LA 第 12 路数据 P|
|FMC1\_LA13\_N|B70\_L21\_N|A21|FMC LA 第 13 路数据 N|
|FMC1\_LA13\_P|B70\_L21\_P|B21|FMC LA 第 13 路数据 P|
|FMC1\_LA14\_N|B70\_L19\_N|C23|FMC LA 第 14 路数据 N|
|FMC1\_LA14\_P|B70\_L19\_P|C22|FMC LA 第 14 路数据 P|
|FMC1\_LA15\_N|B70\_L20\_N|B20|FMC LA 第 15 路数据 N|
|FMC1\_LA15\_P|B70\_L20\_P|C20|FMC LA 第 15 路数据 P|
|FMC1\_LA16\_N|B70\_L22\_N|A22|FMC LA 第 16 路数据 N|
|FMC1\_LA16\_P|B70\_L22\_P|B22|FMC LA 第 16 路数据 P|
|FMC1\_LA17\_CC\_N|B69\_L14\_N|E29|FMC LA 第 17 路数据（时钟）N|
|FMC1\_LA17\_CC\_P|B69\_L14\_P|E28|FMC LA 第 17 路数据（时钟）P|
|FMC1\_LA18\_CC\_N|B69\_L13\_N|F29|FMC LA 第 18 路数据（时钟）N|
|FMC1\_LA18\_CC\_P|B69\_L13\_P|F28|FMC LA 第 18 路数据（时钟）P|
|FMC1\_LA19\_N|B70\_L7\_N|H22|FMC LA 第 19 路数据 N|
|FMC1\_LA19\_P|B70\_L7\_P|J22|FMC LA 第 19 路数据 P|
|FMC1\_LA20\_N|B69\_L17\_N|D26|FMC LA 第 20 路数据 N|
|FMC1\_LA20\_P|B69\_L17\_P|E26|FMC LA 第 20 路数据 P|
|FMC1\_LA21\_N|B69\_L2\_N|H27|FMC LA 第 21 路数据 N|
|FMC1\_LA21\_P|B69\_L2\_P|J27|FMC LA 第 21 路数据 P|
|FMC1\_LA22\_N|B69\_L4\_N|H25|FMC LA 第 22 路数据 N|
|FMC1\_LA22\_P|B69\_L4\_P|J25|FMC LA 第 22 路数据 P|
|FMC1\_LA23\_N|B69\_L5\_N|J26|FMC LA 第 23 路数据 N|
|FMC1\_LA23\_P|B69\_L5\_P|K26|FMC LA 第 23 路数据 P|
|FMC1\_LA24\_N|B69\_L15\_N|D31|FMC LA 第 24 路数据 N|

|FMC1\_LA24\_P|B69\_L15\_P|E31|FMC LA 第 24 路数据 P|
| :- | :- | :- | :- |
|FMC1\_LA25\_N|B70\_L8\_N|J21|FMC LA 第 25 路数据 N|
|FMC1\_LA25\_P|B70\_L8\_P|J20|FMC LA 第 25 路数据 P|
|FMC1\_LA26\_N|B69\_L1\_N|M26|FMC LA 第 26 路数据 N|
|FMC1\_LA26\_P|B69\_L1\_P|M25|FMC LA 第 26 路数据 P|
|FMC1\_LA27\_N|B69\_L3\_N|L27|FMC LA 第 27 路数据 N|
|FMC1\_LA27\_P|B69\_L3\_P|L26|FMC LA 第 27 路数据 P|
|FMC1\_LA28\_N|B69\_L16\_N|D30|FMC LA 第 28 路数据 N|
|FMC1\_LA28\_P|B69\_L16\_P|E30|FMC LA 第 28 路数据 P|
|FMC1\_LA29\_N|B69\_L7\_N|J31|FMC LA 第 29 路数据 N|
|FMC1\_LA29\_P|B69\_L7\_P|J30|FMC LA 第 29 路数据 P|
|FMC1\_LA30\_N|B69\_L11\_N|F27|FMC LA 第 30 路数据 N|
|FMC1\_LA30\_P|B69\_L11\_P|G27|FMC LA 第 30 路数据 P|
|FMC1\_LA31\_N|B69\_L9\_N|H28|FMC LA 第 31 路数据 N|
|FMC1\_LA31\_P|B69\_L9\_P|J28|FMC LA 第 31 路数据 P|
|FMC1\_LA32\_N|B69\_L10\_N|F31|FMC LA 第 32 路数据 N|
|FMC1\_LA32\_P|B69\_L10\_P|G31|FMC LA 第 32 路数据 P|
|FMC1\_LA33\_N|B69\_L8\_N|H30|FMC LA 第 33 路数据 N|
|FMC1\_LA33\_P|B69\_L8\_P|H29|FMC LA 第 33 路数据 P|
|FMC1\_SCL|B90\_L1\_P|E5|FMC I2C 总线时钟|
|FMC1\_SDA|B90\_L1\_N|E4|FMC I2C 总线数据|
|FMC1\_HA00\_CC\_N|B71\_L13\_N|F18|FMC HA 第 0 路数据（时钟）N|
|FMC1\_HA00\_CC\_P|B71\_L13\_P|F19|FMC HA 第 0 路数据（时钟）P|
|FMC1\_HA01\_CC\_N|B71\_L11\_N|G16|FMC HA 第 1 路数据（时钟）N|
|FMC1\_HA01\_CC\_P|B71\_L11\_P|G17|FMC HA 第 1 路数据（时钟）P|
|FMC1\_HA02\_N|B71\_L21\_N|A19|FMC HA 第 2 路数据N|
|FMC1\_HA02\_P|B71\_L21\_P|B19|FMC HA 第 2 路数据P|
|FMC1\_HA03\_N|B71\_L12\_N|G19|FMC HA 第 3 路数据N|
|FMC1\_HA03\_P|B71\_L12\_P|H19|FMC HA 第 3 路数据N|
|FMC1\_HA04\_N|B71\_L22\_N|B15|FMC HA 第 4 路数据N|
|FMC1\_HA04\_P|B71\_L22\_P|B16|FMC HA 第 4 路数据P|
|FMC1\_HA05\_N|B71\_L19\_N|C17|FMC HA 第 5 路数据N|
|FMC1\_HA05\_P|B71\_L19\_P|C18|FMC HA 第 5 路数据P|
|FMC1\_HA06\_N|B71\_L9\_N|G14|FMC HA 第 6 路数据N|
|FMC1\_HA06\_P|B71\_L9\_P|H14|FMC HA 第 6 路数据P|

|FMC1\_HA07\_N|B71\_L6\_N|K14|FMC HA 第 7 路数据N|
| :- | :- | :- | :- |
|FMC1\_HA07\_P|B71\_L6\_P|K15|FMC HA 第 7 路数据P|
|FMC1\_HA08\_N|B71\_L15\_N|E18|FMC HA 第 8 路数据N|
|FMC1\_HA08\_P|B71\_L15\_P|E19|FMC HA 第 8 路数据P|
|FMC1\_HA09\_N|B71\_L17\_N|D17|FMC HA 第 9 路数据N|
|FMC1\_HA09\_P|B71\_L17\_P|D18|FMC HA 第 9 路数据P|
|FMC1\_HA10\_N|B71\_L8\_N|H17|FMC HA 第 10 路数据N|
|FMC1\_HA10\_P|B71\_L8\_P|H18|FMC HA 第 10 路数据P|
|FMC1\_HA11\_N|B71\_L16\_N|E15|FMC HA 第 11 路数据N|
|FMC1\_HA11\_P|B71\_L16\_P|E16|FMC HA 第 11 路数据P|
|FMC1\_HA12\_N|B71\_L18\_N|D15|FMC HA 第 12 路数据N|
|FMC1\_HA12\_P|B71\_L18\_P|D16|FMC HA 第 12 路数据P|
|FMC1\_HA13\_N|B71\_L10\_N|F14|FMC HA 第 13 路数据N|
|FMC1\_HA13\_P|B71\_L10\_P|G15|FMC HA 第 13 路数据P|
|FMC1\_HA14\_N|B71\_L23\_N|A17|FMC HA 第 14 路数据N|
|FMC1\_HA14\_P|B71\_L23\_P|A18|FMC HA 第 14 路数据P|
|FMC1\_HA15\_N|B71\_L24\_N|A16|FMC HA 第 15 路数据N|
|FMC1\_HA15\_P|B71\_L24\_P|B17|FMC HA 第 15 路数据P|
|FMC1\_HA16\_N|B71\_L20\_N|C14|FMC HA 第 16 路数据N|
|FMC1\_HA16\_P|B71\_L20\_P|C15|FMC HA 第 16 路数据P|
|FMC1\_HA17\_CC\_N|B71\_L14\_N|F16|FMC HA 第 17 路数据（时钟）N|
|FMC1\_HA17\_CC\_P|B71\_L14\_P|F17|FMC HA 第 17 路数据（时钟）P|
|FMC1\_HA18\_N|B70\_L9\_N|G24|FMC HA 第 18 路数据N|
|FMC1\_HA18\_P|B70\_L9\_P|H24|FMC HA 第 18 路数据P|
|FMC1\_HA19\_N|B70\_L10\_N|G20|FMC HA 第 19 路数据N|
|FMC1\_HA19\_P|B70\_L10\_P|H20|FMC HA 第 19 路数据P|
|FMC1\_HA20\_N|B71\_L7\_N|H15|FMC HA 第 20 路数据N|
|FMC1\_HA20\_P|B71\_L7\_P|J15|FMC HA 第 20 路数据P|
|FMC1\_HA21\_N|B70\_L15\_N|D25|FMC HA 第 21 路数据N|
|FMC1\_HA21\_P|B70\_L15\_P|E25|FMC HA 第 21 路数据P|
|FMC1\_HA22\_N|B70\_L16\_N|D23|FMC HA 第 22 路数据N|
|FMC1\_HA22\_P|B70\_L16\_P|D22|FMC HA 第 22 路数据P|
|FMC1\_HA23\_N|B69\_L24\_N|A29|FMC HA 第 23 路数据N|
|FMC1\_HA23\_P|B69\_L24\_P|A28|FMC HA 第 23 路数据P|
|FMC1\_HPC\_GBTCLK0\_M2C\_C\_P|MGT226\_CLK0\_P|AG12|收发器参考时钟 0 输入P|

|FMC1\_HPC\_GBTCLK0\_M2C\_C\_N|MGT226\_CLK0\_N|AG11|收发器参考时钟 0 输入N|
| :- | :- | :- | :- |
|CLK7\_P|MGT226\_CLK1\_P|AF10|收发器参考时钟 1 输入P|
|CLK7\_N|MGT226\_CLK1\_N|AF9|收发器参考时钟 1 输入N|
|FMC1\_DP0\_M2C\_P|MGT226\_RX0\_P|AL4|收发器数据 0 输入P|
|FMC1\_DP0\_M2C\_N|MGT226\_RX0\_N|AL3|收发器数据 0 输入N|
|FMC1\_DP1\_M2C\_P|MGT226\_RX1\_P|AK2|收发器数据 1 输入P|
|FMC1\_DP1\_M2C\_N|MGT226\_RX1\_N|AK1|收发器数据 1 输入N|
|FMC1\_DP2\_M2C\_P|MGT226\_RX2\_P|AJ4|收发器数据 2 输入P|
|FMC1\_DP2\_M2C\_N|MGT226\_RX2\_N|AJ3|收发器数据 2 输入N|
|FMC1\_DP3\_M2C\_P|MGT226\_RX3\_P|AH2|收发器数据 3 输入P|
|FMC1\_DP3\_M2C\_N|MGT226\_RX3\_N|AH1|收发器数据 3 输入N|
|FMC1\_DP4\_M2C\_P|MGT227\_RX0\_P|AG4|收发器数据 4 输入P|
|FMC1\_DP4\_M2C\_N|MGT227\_RX0\_N|AG3|收发器数据 4 输入N|
|FMC1\_DP5\_M2C\_P|MGT227\_RX1\_P|AF2|收发器数据 5 输入P|
|FMC1\_DP5\_M2C\_N|MGT227\_RX1\_N|AF1|收发器数据 5 输入N|
|FMC1\_DP6\_M2C\_P|MGT227\_RX2\_P|AE4|收发器数据 6 输入P|
|FMC1\_DP6\_M2C\_N|MGT227\_RX2\_N|AE3|收发器数据 6 输入N|
|FMC1\_DP7\_M2C\_P|MGT227\_RX3\_P|AD2|收发器数据 7 输入P|
|FMC1\_DP7\_M2C\_N|MGT227\_RX3\_N|AD1|收发器数据 7 输入N|
|FMC1\_DP0\_C2M\_P|MGT226\_TX0\_P|AL8|收发器数据 0 输出P|
|FMC1\_DP0\_C2M\_N|MGT226\_TX0\_N|AL7|收发器数据 0 输出N|
|FMC1\_DP1\_C2M\_P|MGT226\_TX1\_P|AK6|收发器数据 1 输出P|
|FMC1\_DP1\_C2M\_N|MGT226\_TX1\_N|AK5|收发器数据 1 输出N|
|FMC1\_DP2\_C2M\_P|MGT226\_TX2\_P|AJ8|收发器数据 2 输出P|
|FMC1\_DP2\_C2M\_N|MGT226\_TX2\_N|AJ7|收发器数据 2 输出N|
|FMC1\_DP3\_C2M\_P|MGT226\_TX3\_P|AH6|收发器数据 3 输出P|
|FMC1\_DP3\_C2M\_N|MGT226\_TX3\_N|AH5|收发器数据 3 输出N|
|FMC1\_DP4\_C2M\_P|MGT227\_TX0\_P|AG8|收发器数据 4 输出P|
|FMC1\_DP4\_C2M\_N|MGT227\_TX0\_N|AG7|收发器数据 4 输出N|
|FMC1\_DP5\_C2M\_P|MGT227\_TX1\_P|AF6|收发器数据 5 输出P|
|FMC1\_DP5\_C2M\_N|MGT227\_TX1\_N|AF5|收发器数据 5 输出N|
|FMC1\_DP6\_C2M\_P|MGT227\_TX2\_P|AE8|收发器数据 6 输出P|
|FMC1\_DP6\_C2M\_N|MGT227\_TX2\_N|AE7|收发器数据 6 输出N|
|FMC1\_DP7\_C2M\_P|MGT227\_TX3\_P|AD6|收发器数据 7 输出P|
|FMC1\_DP7\_C2M\_N|MGT227\_TX3\_N|AD5|收发器数据 7 输出N|

|FMC1\_HPC\_GBTCLK1\_M2C\_C\_P|MGT227\_CLK0\_P|AE12|收发器参考时钟 0 输入P|
| :- | :- | :- | :- |
|FMC1\_HPC\_GBTCLK1\_M2C\_C\_N|MGT227\_CLK0\_N|AE11|收发器参考时钟 0 输入N|
|CLK2\_P|MGT227\_CLK1\_P|AD10|收发器参考时钟 1 输入P|
|CLK2\_N|MGT227\_CLK1\_N|AD9|收发器参考时钟 1 输入N|

FMC2 扩展口包含 34 对 LA 信号差分对、2 对时钟信号，分别连接 FPGA 芯片 BANK64， BANK65，电平标准默认为 1.8V。8 路高速 GTH 收发信号连接 FPGA 芯片 BANK224， BANK225 的 IO 上。

FPGA 和 FMC HPC 连接器的原理图如图 3-4-2 所示：



图 3-4-2 HPC FMC 连接示意图
##### **FMC HPC J13 连接器引脚分配如下：**

|**信号名**|**FPGA 引脚名**|<p>**FPGA 引脚**</p><p>**号**</p>|**备注**|
| :-: | :- | :-: | :-: |
|FMC2\_CLK0\_M2C\_N|B65\_L12\_N|AP14|FMC 第 0 路输入参考时钟 N|
|FMC2\_CLK0\_M2C\_P|B65\_L12\_P|AP15|FMC 第 0 路输入参考时钟 P|
|FMC2\_CLK1\_M2C\_N|B64\_L12\_N|AM20|FMC 第 1 路输入参考时钟 N|
|FMC2\_CLK1\_M2C\_P|B64\_L12\_P|AL20|FMC 第 1 路输入参考时钟 P|
|FMC2\_LA00\_CC\_N|B65\_L14\_N|AN15|FMC LA 第 0 路数据（时钟）N|
|FMC2\_LA00\_CC\_P|B65\_L14\_P|AM15|FMC LA 第 0 路数据（时钟）P|
|FMC2\_LA01\_CC\_N|B65\_L13\_N|AL14|FMC LA 第 1 路数据（时钟）N|

|FMC2\_LA01\_CC\_P|B65\_L13\_P|AL15|FMC LA 第 1 路数据（时钟）P|
| :- | :- | :- | :- |
|FMC2\_LA02\_N|B65\_L17\_N|AJ15|FMC LA 第 2 路数据N|
|FMC2\_LA02\_P|B65\_L17\_P|AJ16|FMC LA 第 2 路数据P|
|FMC2\_LA03\_N|B65\_L5\_N|AV12|FMC LA 第 3 路数据N|
|FMC2\_LA03\_P|B65\_L5\_P|AV13|FMC LA 第 3 路数据P|
|FMC2\_LA04\_N|B65\_L19\_N|AT11|FMC LA 第 4 路数据N|
|FMC2\_LA04\_P|B65\_L19\_P|AT12|FMC LA 第 4 路数据P|
|FMC2\_LA05\_N|B65\_L24\_N|AM13|FMC LA 第 5 路数据N|
|FMC2\_LA05\_P|B65\_L24\_P|AM14|FMC LA 第 5 路数据P|
|FMC2\_LA06\_N|B65\_L8\_N|AU15|FMC LA 第 6 路数据P|
|FMC2\_LA06\_P|B65\_L8\_P|AT15|FMC LA 第 6 路数据P|
|FMC2\_LA07\_N|B65\_L10\_N|AR16|FMC LA 第 7 路数据N|
|FMC2\_LA07\_P|B65\_L10\_P|AP16|FMC LA 第 7 路数据P|
|FMC2\_LA08\_N|B65\_L11\_N|AT14|FMC LA 第 8 路数据N|
|FMC2\_LA08\_P|B65\_L11\_P|AR14|FMC LA 第 8 路数据P|
|FMC2\_LA09\_N|B65\_L9\_N|AW15|FMC LA 第 9 路数据N|
|FMC2\_LA09\_P|B65\_L9\_P|AV15|FMC LA 第 9 路数据P|
|FMC2\_LA10\_N|B65\_L4\_N|AV10|FMC LA 第 10 路数据N|
|FMC2\_LA10\_P|B65\_L4\_P|AU10|FMC LA 第 10 路数据P|
|FMC2\_LA11\_N|B64\_L10\_N|AL21|FMC LA 第 11 路数据N|
|FMC2\_LA11\_P|B64\_L10\_P|AK21|FMC LA 第 11 路数据P|
|FMC2\_LA12\_N|B65\_L7\_N|AW16|FMC LA 第 12 路数据N|
|FMC2\_LA12\_P|B65\_L7\_P|AV16|FMC LA 第 12 路数据P|
|FMC2\_LA13\_N|B64\_L9\_N|AP20|FMC LA 第 13 路数据N|
|FMC2\_LA13\_P|B64\_L9\_P|AP21|FMC LA 第 13 路数据P|
|FMC2\_LA14\_N|B64\_L7\_N|AR21|FMC LA 第 14 路数据N|
|FMC2\_LA14\_P|B64\_L7\_P|AR22|FMC LA 第 14 路数据P|
|FMC2\_LA15\_N|B64\_L11\_N|AN20|FMC LA 第 15 路数据N|
|FMC2\_LA15\_P|B64\_L11\_P|AN21|FMC LA 第 15 路数据P|
|FMC2\_LA16\_N|B64\_L8\_N|AM22|FMC LA 第 16 路数据N|
|FMC2\_LA16\_P|B64\_L8\_P|AL22|FMC LA 第 16 路数据P|
|FMC2\_LA17\_CC\_N|B64\_L14\_N|AP18|FMC LA 第 17 路数据（时钟）N|
|FMC2\_LA17\_CC\_P|B64\_L14\_P|AN18|FMC LA 第 17 路数据（时钟）P|
|FMC2\_LA18\_CC\_N|B64\_L13\_N|AR19|FMC LA 第 18 路数据（时钟）N|
|FMC2\_LA18\_CC\_P|B64\_L13\_P|AP19|FMC LA 第 18 路数据（时钟）P|

|FMC2\_LA19\_N|B64\_L6\_N|AW18|FMC LA 第 19 路数据N|
| :- | :- | :- | :- |
|FMC2\_LA19\_P|B64\_L6\_P|AV18|FMC LA 第 19 路数据P|
|FMC2\_LA20\_N|B64\_L16\_N|AU17|FMC LA 第 20 路数据N|
|FMC2\_LA20\_P|B64\_L16\_P|AT17|FMC LA 第 20 路数据P|
|FMC2\_LA21\_N|B64\_L20\_N|AM19|FMC LA 第 21 路数据N|
|FMC2\_LA21\_P|B64\_L20\_P|AL19|FMC LA 第 21 路数据P|
|FMC2\_LA22\_N|B64\_L21\_N|AJ19|FMC LA 第 22 路数据N|
|FMC2\_LA22\_P|B64\_L21\_P|AJ20|FMC LA 第 22 路数据P|
|FMC2\_LA23\_N|B64\_L23\_N|AJ18|FMC LA 第 23 路数据N|
|FMC2\_LA23\_P|B64\_L23\_P|AH18|FMC LA 第 23 路数据P|
|FMC2\_LA24\_N|B64\_L15\_N|AT19|FMC LA 第 24 路数据N|
|FMC2\_LA24\_P|B64\_L15\_P|AT20|FMC LA 第 24 路数据P|
|FMC2\_LA25\_N|B64\_L18\_N|AR17|FMC LA 第 25 路数据N|
|FMC2\_LA25\_P|B64\_L18\_P|AR18|FMC LA 第 25 路数据P|
|FMC2\_LA26\_N|B64\_L19\_N|AJ21|FMC LA 第 26 路数据N|
|FMC2\_LA26\_P|B64\_L19\_P|AH21|FMC LA 第 26 路数据P|
|FMC2\_LA27\_N|B64\_L22\_N|AK18|FMC LA 第 27 路数据N|
|FMC2\_LA27\_P|B64\_L22\_P|AK19|FMC LA 第 27 路数据P|
|FMC2\_LA28\_N|B64\_L17\_N|AU18|FMC LA 第 28 路数据N|
|FMC2\_LA28\_P|B64\_L17\_P|AU19|FMC LA 第 28 路数据P|
|FMC2\_LA29\_N|B64\_L1\_N|AV22|FMC LA 第 29 路数据N|
|FMC2\_LA29\_P|B64\_L1\_P|AU22|FMC LA 第 29 路数据P|
|FMC2\_LA30\_N|B64\_L3\_N|AW21|FMC LA 第 30 路数据N|
|FMC2\_LA30\_P|B64\_L3\_P|AV21|FMC LA 第 30 路数据P|
|FMC2\_LA31\_N|B64\_L5\_N|AT21|FMC LA 第 31 路数据N|
|FMC2\_LA31\_P|B64\_L5\_P|AT22|FMC LA 第 31 路数据P|
|FMC2\_LA32\_N|B64\_L4\_N|AW19|FMC LA 第 32 路数据N|
|FMC2\_LA32\_P|B64\_L4\_P|AW20|FMC LA 第 32 路数据P|
|FMC2\_LA33\_N|B64\_L2\_N|AV20|FMC LA 第 33 路数据N|
|FMC2\_LA33\_P|B64\_L2\_P|AU20|FMC LA 第 33 路数据P|
|FMC2\_SCL|B90\_L2\_P|F4|FMC I2C 总线时钟|
|FMC2\_SDA|B90\_L2\_N|E3|FMC I2C 总线数据|
|FMC2\_HPC\_GBTCLK0\_M2C\_C\_N|MGT224\_CLK0\_N|AM9|收发器参考时钟 0 输入N|
|FMC2\_HPC\_GBTCLK0\_M2C\_C\_P|MGT224\_CLK0\_P|AM10|收发器参考时钟 0 输入P|
|MGT\_A\_CLOCK\_N|MGT224\_CLK1\_N|AK9|收发器参考时钟 1 输入N|

|MGT\_A\_CLOCK\_P|MGT224\_CLK1\_P|AK10|收发器参考时钟 1 输入P|
| :- | :- | :- | :- |
|FMC2\_DP0\_M2C\_P|MGT224\_RX0\_P|AW4|收发器数据 0 输入P|
|FMC2\_DP0\_M2C\_N|MGT224\_RX0\_N|AW3|收发器数据 0 输入N|
|FMC2\_DP1\_M2C\_P|MGT224\_RX3\_P|AT2|收发器数据 1 输入P|
|FMC2\_DP1\_M2C\_N|MGT224\_RX3\_N|AT1|收发器数据 1 输入N|
|FMC2\_DP2\_M2C\_P|MGT224\_RX2\_P|AU4|收发器数据 2 输入P|
|FMC2\_DP2\_M2C\_N|MGT224\_RX2\_N|AU3|收发器数据 2 输入N|
|FMC2\_DP3\_M2C\_P|MGT224\_RX1\_P|AV2|收发器数据 3 输入P|
|FMC2\_DP3\_M2C\_N|MGT224\_RX1\_N|AV1|收发器数据 3 输入N|
|FMC2\_DP4\_M2C\_P|MGT225\_RX1\_P|AP2|收发器数据 4 输入P|
|FMC2\_DP4\_M2C\_N|MGT225\_RX1\_N|AP1|收发器数据 4 输入N|
|FMC2\_DP5\_M2C\_P|MGT225\_RX3\_P|AM2|收发器数据 5 输入P|
|FMC2\_DP5\_M2C\_N|MGT225\_RX3\_N|AM1|收发器数据 5 输入N|
|FMC2\_DP6\_M2C\_P|MGT225\_RX2\_P|AN4|收发器数据 6 输入P|
|FMC2\_DP6\_M2C\_N|MGT225\_RX2\_N|AN3|收发器数据 6 输入N|
|FMC2\_DP7\_M2C\_P|MGT225\_RX0\_P|AR4|收发器数据 7 输入P|
|FMC2\_DP7\_M2C\_N|MGT225\_RX0\_N|AR3|收发器数据 7 输入N|
|FMC2\_DP0\_C2M\_P|MGT224\_TX0\_P|AW8|收发器数据 0 输出P|
|FMC2\_DP0\_C2M\_N|MGT224\_TX0\_N|AW7|收发器数据 0 输出N|
|FMC2\_DP1\_C2M\_P|MGT224\_TX3\_P|AT6|收发器数据 1 输出P|
|FMC2\_DP1\_C2M\_N|MGT224\_TX3\_N|AT5|收发器数据 1 输出N|
|FMC2\_DP2\_C2M\_P|MGT224\_TX2\_P|AU8|收发器数据 2 输出P|
|FMC2\_DP2\_C2M\_N|MGT224\_TX2\_N|AU7|收发器数据 2 输出N|
|FMC2\_DP3\_C2M\_P|MGT224\_TX1\_P|AV6|收发器数据 3 输出P|
|FMC2\_DP3\_C2M\_N|MGT224\_TX1\_N|AV5|收发器数据 3 输出N|
|FMC2\_DP4\_C2M\_P|MGT225\_TX1\_P|AP6|收发器数据 4 输出P|
|FMC2\_DP4\_C2M\_N|MGT225\_TX1\_N|AP5|收发器数据 4 输出N|
|FMC2\_DP5\_C2M\_P|MGT225\_TX3\_P|AM6|收发器数据 5 输出P|
|FMC2\_DP5\_C2M\_N|MGT225\_TX3\_N|AM5|收发器数据 5 输出N|
|FMC2\_DP6\_C2M\_P|MGT225\_TX2\_P|AN8|收发器数据 6 输出P|
|FMC2\_DP6\_C2M\_N|MGT225\_TX2\_N|AN7|收发器数据 6 输出N|
|FMC2\_DP7\_C2M\_P|MGT225\_TX0\_P|AR8|收发器数据 7 输出P|
|FMC2\_DP7\_C2M\_N|MGT225\_TX0\_N|AR7|收发器数据 7 输出N|
|FMC2\_HPC\_GBTCLK1\_M2C\_C\_N|MGT225\_CLK0\_N|AJ11|收发器参考时钟 0 输入N|
|FMC2\_HPC\_GBTCLK1\_M2C\_C\_P|MGT225\_CLK0\_P|AJ12|收发器参考时钟 0 输入P|

|-|MGT225\_CLK1\_N|AH9|收发器参考时钟 1 输入N|
| :- | :- | :- | :- |
|-|MGT225\_CLK1\_P|AH10|收发器参考时钟 1 输入P|
### **(五) <a name="_bookmark18"></a>MIPI 接口**
AXKU15 扩展板上带有 2 路 MIPI lanex4 摄像头输入接口。MIPI1 对应 J9，与 FPGA 的 BANK69 和BANK90 相连。MIPI2 对应J10，与 FPGA 的BANK66 和BANK84 相连，与 FPGA

的 BANK71 和 BANK90 相连， 连接的设计示意图如下图 3-5-1，3-5-2 所示:



图 3-5-1 MIPI1 接口设计原理图



图 3-5-1 MIPI2 接口设计原理图
##### **MIPI1 接口引脚分配**

|**信号名称**|**FPGA 引脚名**|**引脚号**|**备注**|
| :- | :- | :- | :-: |
|MIPI1\_CLK\_P|B69\_L19\_P|C29|MIPI 输入时钟正|
|MIPI1\_CLK\_N|B69\_L19\_N|B29|MIPI 输入时钟负|
|MIPI1\_LAN0\_P|B69\_L21\_P|B31|MIPI 输入的数据LANE0 正|
|MIPI1\_LAN0\_N|B69\_L21\_N|A31|MIPI 输入的数据LANE0 负|
|MIPI1\_LAN1\_P|B69\_L23\_P|B26|MIPI 输入的数据LANE1 正|
|MIPI1\_LAN1\_N|B69\_L23\_N|A26|MIPI 输入的数据LANE1 负|
|MIPI1\_LAN2\_P|B69\_L20\_P|C27|MIPI 输入的数据LANE2 正|
|MIPI1\_LAN2\_N|B69\_L20\_N|C28|MIPI 输入的数据LANE2 负|
|MIPI1\_LAN3\_P|B69\_L22\_P|B27|MIPI 输入的数据LANE3 正|
|MIPI1\_LAN3\_N|B69\_L22\_N|A27|MIPI 输入的数据LANE3 负|
|MIPI1\_CLK|B90\_L8\_P|C5|摄像头的时钟输入|
|MIPI1\_GPIO|B90\_L8\_N|C4|摄像头的GPIO 控制|
|MIPI1\_I2C\_SCL|B90\_L3\_P|F3|摄像头的I2C 时钟|
|MIPI1\_I2C\_SDA|B90\_L3\_N|F2|摄像头的I2C 数据|

##### **MIPI2 接口引脚分配**

|**信号名称**|**FPGA 引脚名**|**引脚号**|**备注**|
| :- | -: | :- | :-: |
|MIPI2\_CLK\_P|B71\_L1\_P|M16|MIPI 输入时钟正|
|MIPI2\_CLK\_N|B71\_L1\_N|M15|MIPI 输入时钟负|
|MIPI2\_LAN0\_P|B71\_L2\_P|L19|MIPI 输入的数据LANE0 正|
|MIPI2\_LAN0\_N|B71\_L2\_N|K19|MIPI 输入的数据LANE0 负|
|MIPI2\_LAN1\_P|B71\_L3\_P|L18|MIPI 输入的数据LANE1 正|
|MIPI2\_LAN1\_N|B71\_L3\_N|K18|MIPI 输入的数据LANE1 负|
|MIPI2\_LAN2\_P|B71\_L4\_P|L17|MIPI 输入的数据LANE2 正|
|MIPI2\_LAN2\_N|B71\_L4\_N|L16|MIPI 输入的数据LANE2 负|
|MIPI2\_LAN3\_P|B71\_L5\_P|K16|MIPI 输入的数据LANE3 正|
|MIPI2\_LAN3\_N|B71\_L5\_N|J16|MIPI 输入的数据LANE3 负|
|MIPI2\_CLK|B90\_L7\_P|D3|摄像头的时钟输入|
|MIPI2\_GPIO|B90\_L7\_N|C3|摄像头的GPIO 控制|

|MIPI2\_I2C\_SCL|B90\_L4\_P|F1|摄像头的I2C 时钟|
| -: | -: | :- | :- |
|MIPI2\_I2C\_SDA|B90\_L4\_N|E1|摄像头的I2C 数据|
### **(六) <a name="_bookmark19"></a>USB 转串口**
AXKU15 扩展板上配备了一个 Uart 转 USB 接口，用于系统调试。转换芯片采用 Silicon Labs CP2102GM 的 USB-UAR 芯片, USB 接口采用 MINI USB 接口，可以用一根 USB 线将它连接到上 PC 的 USB 口进行核心板的单独供电和串口数据通信 。

USB Uart 电路设计的示意图如下图所示:



3-6-1 USB 转串口示意图

##### **USB 转串口的 FPGA 引脚分配：**

|**信号名称**|**FPGA 引脚名**|**引脚号**|**备注**|
| :- | -: | :- | :-: |
|UART\_RXD|B90\_L6\_N|D1|Uart 数据输入|
|UART\_TXD|B90\_L6\_P|D2|Uart 数据输出|

### **(七) <a name="_bookmark20"></a>SD 卡槽**
AXKU15 底板包含了一个 Micro 型的 SD 卡接口，以提供用户访问 SD 卡存储器，用于用户数据文件。SDIO 信号与 FPGA 的 IO 信号相连，支持 SPI 模式和 SD 模式，使用的 SD 卡为 MicroSD 卡。FPGA 和 SD 卡连接器的原理图如下图 3-7-1 所示。



图 3-7-1 SD 卡槽原理图
##### **SD 卡槽引脚分配**

|**信号名称**|**FPGA 引脚名**|**引脚号**|**备注**|
| :-: | :-: | :-: | :-: |
|SD\_CD|B90\_L11\_N|A3|SD 片选信号|
|SD\_CLK|B91\_L8\_P|C10|SD 时钟信号|
|SD\_CMD|B91\_L8\_N|C9|SD 命令信号|
|SD\_D0|B90\_L12\_N|A6|SD 数据 Data0|
|SD\_D1|B90\_L12\_P|B6|SD 数据 Data1|
|SD\_D2|B91\_L7\_N|C7|SD 数据 Data2|
|SD\_D3|B91\_L7\_P|C8|SD 数据 Data3|

### **(八) <a name="_bookmark21"></a>SATA 接口**
板上配备了 2 路 SATA 接口， SATA 的差分信号连接到 GTY BANK131 上。

SATA 的参考时钟 150Mhz 由可编程时钟芯片 Si5332BD11025-4 提供。SATA 接口设计的示意图如下图 3-8-1 所示:



图 3-8-1 SATA 接口设计示意图

##### **SATA 接口 FPGA 引脚分配如下：**

|**信号名称**|**引脚名**|**引脚号**|**备注**|
| :- | :-: | :- | :-: |
|SATA1\_RX\_N|MGT131\_RX0\_N|M37|SATA1 数据接收负|
|SATA1\_RX\_P|MGT131\_RX0\_P|M36|SATA1 数据接收正|
|SATA2\_RX\_N|MGT131\_RX1\_N|L39|SATA2 数据接收负|
|SATA2\_RX\_P|MGT131\_RX1\_P|L38|SATA2 数据接收正|
|SATA1\_TX\_N|MGT131\_TX0\_N|J34|SATA1 数据发送负|
|SATA1\_TX\_P|MGT131\_TX0\_P|J33|SATA1 数据发送正|
|SATA2\_TX\_N|MGT131\_TX1\_N|G34|SATA2 数据发送负|
|SATA2\_TX\_P|MGT131\_TX1\_P|G33|SATA2 数据发送正|
|SATACLK\_N|MGT131\_CLK0\_N|T28|SATA 参考时钟负|
|SATACLK\_P|MGT131\_CLK0\_P|T27|SATA 参考时钟正|

### **(九) 按键和LED 灯**
AXKU15 底板上有 7 个发光二极管 LED, 1 个电源指示灯； 2 个串口通信指示灯， 4 个用户 LED 灯。当开发板上电后电源指示灯会亮起；4 个 LED 灯连接到 FPGA 的 IO 上，用户可以通过程序来控制亮和灭，当连接用户 LED 灯的 IO 电压为高时，用户 LED 灯点亮，当连接 IO 电压为低时，用户 LED 会被熄灭。另外板上还有 4 个用户按键，默认按键信号为高，当按键按下时，按键电平为低。用户 LED 灯和按键的硬件连接示意图如图 3-9-1 所示：




图 3-9-1 用户 LED 灯和按键硬件连接示意图

##### **用户 LED 灯和按键的引脚分配**

|**信号名称**|**FPGA 引脚名**|**管脚号**|**备注**|
| :- | :- | :- | :-: |
|KEY1|B91\_L10\_N|A8|用户按键 1|
|KEY2|B91\_L10\_P|B9|用户按键 2|
|KEY3|B91\_L9\_N|A7|用户按键 3|
|KEY4|B91\_L9\_P|B7|用户按键 4|
|LED1|B91\_L5\_P|D8|用户LED1 灯|
|LED2|B91\_L5\_N|D7|用户LED2 灯|
|LED3|B91\_L6\_P|D11|用户LED3 灯|
|LED4|B91\_L6\_N|D10|用户LED4 灯|
### **(十) <a name="_bookmark23"></a>EEPROM**
AXKU15 开发板板载了一片 EEPROM，型号为 24LC04,容量为：4Kbit（2\*256\*8bit），由 2 个 256byte 的 block 组成,通过 IIC 总线进行通信。板载 EEPROM 就是为了学习 IIC 总线的通信方式。EEPROM 的 I2C 信号连接的 FPGA 端的 BANK B1 IO 口上。下图 3-10-1 为 EEPROM 的设计示意图




图 3-10-1 EEPROM 原理图部分
##### **EEPROM 引脚分配：**

|**引脚名称**|**FPGA 引脚**|
| :-: | :-: |
|EEPROM\_RTC\_I2C\_SCL|B2|
|EEPROM\_RTC\_I2C\_SDA|C2|

### **(十一) 温度传感器**
AXKU15 开发板上安装了一个高精度、低功耗、数字温度传感器芯片， 型号为 ON Semiconductor 公司的 LM75A。LM75A 芯片的温度精度为 0.125 度,传感器和 FPGA 直接为I2C 数字接口，FPGA 通过I2C 接口来读取当前开发板附近的温度。下图 3-11-1 为LM75A传感器芯片的设计示意图



图 3-11-1 LM75A 传感器原理图部分


LM75A 传感器引脚分配：

|**引脚名称**|**FPGA 引脚**|
| :-: | :-: |
|LM75A\_SCL|B5|
|LM75A\_SDA|B4|

### **(十二) 光纤接口**
扩展板上有2路QSFP28光纤接口，用户可以购买QSFP光模块插入到这4个光纤接口中进行光纤数据通信。2路光纤接口分别跟FPGA的BANK127-128的GTY收发器的4路RX/TX相连接。BANK127-128的参考时钟可选择由Si5332BD11025-4芯片提供或或独立的晶振提供。

FPGA 和光纤设计示意图如下图 12-1 所示:



图 12-1 光纤设计示意图
##### **2 路光纤接口引脚分配如下：**

|**信号名称**|**网格标号**|**FPGA 引脚号**|**备注**|
| -: | :- | :- | :-: |
|QSFP1\_RX1\_N|MGT127\_RX0\_N|AH37|光模块 1 数据接收负 1|
|QSFP1\_RX1\_P|MGT127\_RX0\_P|AH36|光模块 1 数据接收正 1|
|QSFP1\_RX2\_N|MGT127\_RX1\_N|AG39|光模块 1 数据接收负 2|
|QSFP1\_RX2\_P|MGT127\_RX1\_P|AG38|光模块 1 数据接收正 2|
|QSFP1\_RX3\_N|MGT127\_RX2\_N|AF37|光模块 1 数据接收负 3|

|QSFP1\_RX3\_P|MGT127\_RX2\_P|AF36|光模块 1 数据接收正 3|
| :- | :- | :- | :- |
|QSFP1\_RX4\_N|MGT127\_RX3\_N|AE39|光模块 1 数据接收负 4|
|QSFP1\_RX4\_P|MGT127\_RX3\_P|AE38|光模块 1 数据接收正 4|
|QSFP1\_TX1\_N|MGT127\_TX0\_N|AF32|光模块 1 数据发送负 1|
|QSFP1\_TX1\_P|MGT127\_TX0\_P|AF31|光模块 1 数据发送正 1|
|QSFP1\_TX2\_N|MGT127\_TX1\_N|AE34|光模块 1 数据发送负 2|
|QSFP1\_TX2\_P|MGT127\_TX1\_P|AE33|光模块 1 数据发送正 2|
|QSFP1\_TX3\_N|MGT127\_TX2\_N|AD32|光模块 1 数据发送负 3|
|QSFP1\_TX3\_P|MGT127\_TX2\_P|AD31|光模块 1 数据发送正 3|
|QSFP1\_TX4\_N|MGT127\_TX3\_N|AC34|光模块 1 数据发送负 4|
|QSFP1\_TX4\_P|MGT127\_TX3\_P|AC33|光模块 1 数据发送正 4|
|CLK0\_N|MGT127\_CLK0\_N|AE30|BANK127 参考时钟 0 负|
|CLK0\_P|MGT127\_CLK0\_P|AE29|BANK127 参考时钟 0 正|
|MGT\_B\_CLOCK\_N|MGT127\_CLK1\_N|AC30|BANK127 参考时钟 1 负|
|MGT\_B\_CLOCK\_P|MGT127\_CLK1\_P|AC29|BANK127 参考时钟 1 正|
|QSFP1\_SCL|B91\_L1\_P|F6|光模块 1 的I2C 时钟|
|QSFP1\_SDA|B91\_L2\_P|F8|光模块 1 的I2C 数据|
|QSFP1\_INTL|B93\_L10\_P|L13|光模块 1 的中断信号|
|QSFP1\_LPMODE|B91\_L2\_N|F7|光模块 1 低功耗选择信号|
|QSFP1\_MODPRSL|B93\_L10\_N|K13|光模块 1 存在指示信号|
|QSFP1\_MODSELL|B93\_L9\_N|M10|光模块 1 模块选择信号|
|QSFP1\_RESETL|B93\_L9\_P|N10|光模块 1 复位信号|
|QSFP2\_RX1\_N|MGT128\_RX0\_N|AD37|光模块 2 数据接收负 1|
|QSFP2\_RX1\_P|MGT128\_RX0\_P|AD36|光模块 2 数据接收正 1|
|QSFP2\_RX2\_N|MGT128\_RX1\_N|AC39|光模块 2 数据接收负 2|
|QSFP2\_RX2\_P|MGT128\_RX1\_P|AC38|光模块 2 数据接收正 2|
|QSFP2\_RX3\_N|MGT128\_RX2\_N|AB37|光模块 2 数据接收负 3|
|QSFP2\_RX3\_P|MGT128\_RX2\_P|AB36|光模块 2 数据接收正 3|
|QSFP2\_RX4\_N|MGT128\_RX3\_N|AA39|光模块 2 数据接收负 4|
|QSFP2\_RX4\_P|MGT128\_RX3\_P|AA38|光模块 2 数据接收正 4|
|QSFP2\_TX1\_N|MGT128\_TX0\_N|AB32|光模块 2 数据发送负 1|
|QSFP2\_TX1\_P|MGT128\_TX0\_P|AB31|光模块 2 数据发送正 1|
|QSFP2\_TX2\_N|MGT128\_TX1\_N|AA34|光模块 2 数据发送负 2|
|QSFP2\_TX2\_P|MGT128\_TX1\_P|AA33|光模块 2 数据发送正 2|
|QSFP2\_TX3\_N|MGT128\_TX2\_N|Y32|光模块 2 数据发送负 3|

|QSFP2\_TX3\_P|MGT128\_TX2\_P|Y31|光模块 2 数据发送正 3|
| :- | :- | :- | :- |
|QSFP2\_TX4\_N|MGT128\_TX3\_N|W34|光模块 2 数据发送负 4|
|QSFP2\_TX4\_P|MGT128\_TX3\_P|W33|光模块 2 数据发送正 4|
|CLK1\_N|MGT128\_CLK0\_N|AB28|BANK128 参考时钟 0 负|
|CLK1\_P|MGT128\_CLK0\_P|AB27|BANK128 参考时钟 0 正|
|CLK3\_N|MGT128\_CLK1\_N|AA30|BANK128 参考时钟 1 负|
|CLK3\_P|MGT128\_CLK1\_P|AA29|BANK128 参考时钟 1 正|
|QSFP2\_SCL|B93\_L5\_N|N14|光模块 2 的I2C 时钟|
|QSFP2\_SDA|B93\_L5\_P|N15|光模块 2 的I2C 数据|
|QSFP2\_INTL|B91\_L1\_P|R15|光模块 2 的中断信号|
|QSFP2\_LPMODE|B91\_L2\_P|N12|光模块 2 低功耗选择信号|
|QSFP2\_MODPRSL|B93\_L1\_P|P15|光模块 2 存在指示信号|
|QSFP2\_MODSELL|B93\_L6\_N|R13|光模块 2 模块选择信号|
|QSFP2\_RESETL|B93\_L1\_N|R14|光模块 2 复位信号|

### **(十三) <a name="_bookmark26"></a>JTAG 调试口**
在 AXKU15 底板上预留了一个 10PIN 的 JTAG 接口，用于下载 FPGA 程序或者固化程序到 FLASH。为了带电插拔造成对 FPGA 芯片的损坏，我们在 JTAG 信号上添加了保护二极管来保证信号的电压在 FPGA 接受的范围，避免芯片的损坏。



图3-13-1 原理图中JTAG接口部分
### **(十四) 电源**
开发板的电源输入电压为 DC12V，可以通过 PCIE 插槽或者外接+12V 电源给板子供电。外接电源供电时请使用开发板自带的电源,不要用其他规格的电源，以免损坏开发板。3 路 DC/DC 电源芯片 SGM61163 分别输出+5V、FMC2\_VADJ 和 3.3V 电压；ETA1471 输出 FMC1\_VADJ 调整电压。同时输出的+3.3V 给多路 LDO 输出 JTAG 各 FPGABANK 所需的电压。

板上的电源设计示意图如下图 3-14-1 所示:




图 3-14-1 原理图中电源接口部分各个电源分配的功能如下表所示：

|**电源**|**功能**|
| :-: | :-: |
|+5.0V|扩展模块供电电源|
|FMC1\_VADJ|FMC1 调整电压|
|FMC2\_VADJ|FMC2 调整电压|
|+3.3V|底板外设电源|
|VDD\_REF|JTAG 电源|
|VCCIO\_65|FPGA BANK 电压|
|VCCIO\_90\_91\_93\_94\_ADJ@1A|FPGA BANK 电压|
|VCCIO\_69\_70\_71\_ADJ@1A|FPGA BANK 电压|
