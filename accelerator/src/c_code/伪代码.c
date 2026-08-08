int32_t tileSize = 16;
int32_t colSize = 64; // 每个核的列数
int32_t rowSize = 64; // 每个核的行数

int32_t w,h,co,ci,k; // 卷积核的行数、列数、输出通道数、输入通道数、卷积核大小

int32_t configArray[2*tileSize];
int32_t featureMapAddr = 0x0000000; // 外存中特征图的存储首地址
int32_t outputMapAddr = 0x4000000; // 外存中结果图的存储首地址
int32_t kernelMapAddr = 0x8000000; // 外存中卷积核的存储首地址

int32_t weightSramAddr = 0xB000000; // 片上缓存中卷积核sram的地址
int32_t featureSramAddr = 0xD000000; // 片上缓存中特征图sram的地址
int32_t outputSramAddr = 0xF000000; // 片上缓存中结果图sram的地址

int32_t DMA_clusterFlag = 0; // DMA_clusterFlag = 0 表示DMA_cluster空闲，DMA_clusterFlag = 1 表示DMA_cluster正在传输
int32_t DMA_outputSramFlag = 0; // DMA_outputSramFlag = 0 表示DMA_outputSram空闲，DMA_outputSramFlag = 1 表示DMA_outputSram正在传输
int32_t DMA_weightSramFlag = 0; // DMA_weightSramFlag = 0 表示DMA_weightSram空闲，DMA_weightSramFlag = 1 表示DMA_weightSram正在传输
int32_t MacMachineBusy = 0; // MacMachineBusy = 0 表示MacMachine空闲，MacMachineBusy = 1 表示MacMachine正在工作
int32_t 2DProcessBusy = 0; // 2D_PROCESS_Busy = 0 表示2D_PROCESS空闲，2D_PROCESS_Busy = 1 表示2D_PROCESS正在工作

// 启用全局中断
void enable_interrupts(void) {
    __asm__ volatile ("csrs mstatus, 0x8");  // 设置MIE位
}

// 定义中断向量表（假设使用机器模式，32个入口）
void (*interrupt_vector_table[32])(void);

// 初始化向量表
void init_vector_table() {
    for (int i = 0; i < 32; i++) {
        interrupt_vector_table[i] = default_handler;
    }
}

// 默认处理程序
void default_handler() {
    uint32_t cause;
    __asm__ volatile ("csrr %0, mcause" : "=r"(cause));
    printf("未处理的中断/异常: %d\n", cause & 0x1F);
    while(1); // 挂起系统或采取其他措施
}

void external_DMA_cluster_handler() {
    // 处理DMA_cluster中断
    printf("DMA_cluster中断触发\n");
    DMA_clusterFlag = 0;
    // 清除中断标志

    // 拉起结果传输DMA
    WRITE_APB("DMA_outputSram"); // 拉起结果传输DMA
    DMA_outputSramFlag = 1; // 标记DMA_outputSram正在传输
}

void external_DMA_weightSram_handler() {
    // 处理DMA_weightSram中断
    printf("DMA_weightSram中断触发\n");
    DMA_weightSramFlag = 0;
    // 清除中断标志
}

void external_DMA_outputSram_handler() {
    // 处理DMA_outputSram中断
    printf("DMA_outputSram中断触发\n");
    DMA_outputSramFlag = 0;
    // 清除中断标志

    // 拉起2D平面模块
    WRITE_APB("2D_PROCESS"); // 拉起2D平面模块, 相关的配置信息位于configArray[2dProcess]中
    2DProcessBusy = 1; // 标记2D_PROCESS正在工作
}

void external_MacMachine_handler() {
    // 处理MacMachine中断
    printf("MacMachine中断触发\n");
    MacMachineBusy = 0;
    // 清除中断标志
}

void external_2D_PROCESS_handler() {
    // 处理2D平面处理中断
    printf("2D平面处理中断触发\n");
    2DProcessBusy = 0; // 对外存内数据进行平面处理，补全输入通道，补全行向、补全列向（从configArray中获取配置信息）
    // 清除中断标志
}

// 注册中断处理程序
void register_interrupt_handlers() {
    interrupt_vector_table[7] = external_DMA_cluster_handler;    // DMA_cluster中断
    interrupt_vector_table[11] = external_DMA_weightSram_handler; // DMA_weightSram中断
    interrupt_vector_table[13] = external_DMA_outputSram_handler; // DMA_outputSram中断
    interrupt_vector_table[15] = external_MacMachine_handler; // MacMachine中断
    interrupt_vector_table[17] = external_2D_PROCESS_handler; // 2D_PROCESS中断
}

void enable_specific_interrupts() {
    // 启用机器模式下的中断
    __asm__ volatile ("csrs mstatus, 0x8"); // 设置MIE位
    
    // 启用特定中断源
    uint32_t mie_mask = (1 << 7) |    // 定时器中断
                       (1 << 11) |   // 外部中断A
                       (1 << 13);    // 外部中断B
    __asm__ volatile ("csrs mie, %0" : : "r"(mie_mask));
}

void interrupt_init() { // 初始化中断
    init_vector_table();          // 初始化所有条目为默认处理程序
    register_interrupt_handlers(); // 注册三个特定处理程序
    enable_specific_interrupts();  // 启用中断
    
    // 设置中断向量地址（取决于具体实现）
    // 例如，有些平台可能需要设置mtvec寄存器
    __asm__ volatile ("csrw mtvec, %0" : : "r"(handle_interrupt));
}

void configure_plic() {
    // 设置中断优先级（以外部中断A为例，IRQ编号假设为1）
    volatile uint32_t *priority = (uint32_t*)(PLIC_BASE + 0x4);
    *priority = 1; // 中等优先级
    
    // 启用中断
    volatile uint32_t *enable = (uint32_t*)(PLIC_BASE + 0x2000);
    *enable |= (1 << 1); // 启用IRQ 1
    
    // 设置阈值
    volatile uint32_t *threshold = (uint32_t*)(PLIC_BASE + 0x200000);
    *threshold = 0;
}

void Conv2d(COUT, H, W, CIN, slice_co, delta_co, delta_h, delta_w, delta_ci){
    
    int pingPong = 0; // 设置初始态乒乓信号
    WRITE_APB("pingPong"); // 写入乒乓信号
    for (i=0;i<tileSize;i++) { // 写入配置寄存器
        WRITE_APB("tile"); // 给每个Tile写入配置寄存器
    }
    WRITE_APB("FSM/OutRouter"); // 给FSM/OutRouter写入配置寄存器

    // 加载特征图Block到CLuster内部
    while(DMA_clusterFlag == 1) // 等待DMA_cluster空闲
    WRITE_APB("DMA_outputSramcluster", pingpong); // configArray[DMA_cluster]存储了跳地址模式, 写入ping存储器
    DMA_clusterFlag = 1; // 标记DMA_cluster正在传输

    // 加载卷积核Block到CLuster内部
    while(DMA_weightSramFlag == 1) // 等待DMA_weightSram空闲
    WRITE_APB("DMA_weightSram"); // configArray[DMA_weightSram]存储了跳地址模式
    DMA_weightSramFlag = 1; // 标记DMA_weightSram正在传输

    while(MacMachineBusy == 1) // 等待MacMachine空闲
    for (w = 0, w < W) { // 最后遍历所有输出通道
        for (h = 0, h < H) {
            for (co = 0, co < COUT) {
                for (ci = 0; ci< CIN) { // 最优先遍历所有输入通道
                    while(MacMachineBusy == 1 || 2DProcessBusy == 1)  // 等待MacMachine且2D平面处理模块空闲
                    // 该特征图Block计算完成，结果图内有数据刷新;或者是初次计算
                    if(ci==0 && h==0 && w==0) {
                        // 初次计算
                        // 更新特征图Block
                        while(DMA_featureSramFlag == 1) // 等待DMA_featureSram空闲
                        WRITE_APB("DMA_featureSram", ~pingPong); // 执行cluster的pingpong更新
                        DMA_featureSramFlag = 1; // 标记DMA_featureSram正在传输

                        // 拉起MacMachine内新一次计算
                        WRITE_APB("MacMachine"); // 通过APB总线写入MacMachine控制寄存器，启动一次计算  
                        MacMachineBusy = 1; // 标记MacMachine正在工作
                    } else {
                        // 该特征图Block计算完成，结果图内有数据刷新
                        // 更新特征图Block
                        while(DMA_featureSramFlag == 1 && DMA_outputSramFlag == 1 && ) // 等待DMA_featureSram和DMA_outputSram空闲
                        WRITE_APB("DMA_featureSram", pingpong); // 执行cluster的pingpong更新
                        DMA_featureSramFlag = 1; // 标记DMA_featureSram正在传输

                        // 卷积循环状态推进
                        ci += delta_ci

                        // 更新乒乓信号
                        pingPong = !pingPong; 
                        WRITE_APB("pingPong");  // 乒乓寄存器更新特征图、结果图乒乓切换
                        
                        // 拉起MacMachine内新一次计算
                        WRITE_APB("MacMachine"); // 通过APB总线写入MacMachine控制寄存器，启动一次计算  
                        MacMachineBusy = 1; // 标记MacMachine正在工作
                    }
                }
                ci = 0;
                w += delta_w;
            }
            w = 0;
            h += delta_h;
        }
        h = 0;
        co += delta_co;
        if(co % slice_co == 0) {
            // 更新kernel权重Sram
            while(DMA_weightSramFlag == 1) // 等待DMA_weightSram空闲
            WRITE_APB("DMA_weightSram", size = slice_co*k*k*CIN); // configArray[DMA_weightSram]存储了跳地址模式, 一次仅传输一段数据
            DMA_weightSramFlag = 1; // 标记DMA_weightSram正在传输
        }
    }
}
