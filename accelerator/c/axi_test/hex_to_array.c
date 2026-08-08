#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// 定义行数
#define NUM_ROWS 144

/*
 * 将一行hex字符串转换为C数组初始化格式
 * 直接当作字符串处理，不转换为整数
 */
void convert_line_to_c_format(const char *line, char *output, size_t output_size) {
    if (strlen(line) != 64) {
        snprintf(output, output_size, "// 错误：行长度不正确，期望64字符，实际%d字符", (int)strlen(line));
        return;
    }
    
    // 开始构建输出字符串
    char *ptr = output;
    ptr += snprintf(ptr, output_size - (ptr - output), "{");
    
    for (int i = 0; i < 64; i += 8) {
        // 提取8个字符
        char chunk[9];
        strncpy(chunk, &line[i], 8);
        chunk[8] = '\0';
        
        // 添加0x前缀
        ptr += snprintf(ptr, output_size - (ptr - output), "0x%s", chunk);
        
        // 如果不是最后一个，添加逗号和空格
        if (i + 8 < 64) {
            ptr += snprintf(ptr, output_size - (ptr - output), ", ");
        }
    }
    
    ptr += snprintf(ptr, output_size - (ptr - output), "}");
}

/*
 * 读取hex文件并转换为C格式
 */
int convert_hex_file(const char *input_file, const char *output_file) {
    FILE *fp_in = NULL;
    FILE *fp_out = NULL;
    char line[256];
    char output_line[1024];
    int line_count = 0;
    
    // 打开输入文件
    fp_in = fopen(input_file, "r");
    if (fp_in == NULL) {
        printf("错误：无法打开输入文件 %s\n", input_file);
        return -1;
    }
    
    // 打开输出文件
    fp_out = fopen(output_file, "w");
    if (fp_out == NULL) {
        printf("错误：无法打开输出文件 %s\n", output_file);
        fclose(fp_in);
        return -1;
    }
    
    printf("开始转换文件: %s -> %s\n", input_file, output_file);
    
    // 写入文件头
    fprintf(fp_out, "// 从 %s 转换而来的权重数据\n", input_file);
    fprintf(fp_out, "// 每行格式: {0xXXXXXXXX, 0xXXXXXXXX, 0xXXXXXXXX, 0xXXXXXXXX, 0xXXXXXXXX, 0xXXXXXXXX, 0xXXXXXXXX, 0xXXXXXXXX}\n\n");
    
    // 处理每一行
    while (fgets(line, sizeof(line), fp_in) != NULL) {
        line_count++;
        
        // 移除换行符
        line[strcspn(line, "\r\n")] = 0;
        
        // 跳过空行
        if (strlen(line) == 0) {
            continue;
        }
        
        // 验证行长度
        if (strlen(line) != 64) {
            printf("警告：第%d行长度不正确，期望64字符，实际%d字符，跳过此行\n", 
                   line_count, (int)strlen(line));
            continue;
        }
        
        // 转换格式
        convert_line_to_c_format(line, output_line, sizeof(output_line));
        
        // 写入输出文件
        fprintf(fp_out, "%s,\n", output_line);
        
        printf("处理第%d行完成\n", line_count);
    }
    
    // 移除最后一行末尾的逗号
    if (line_count > 0) {
        fseek(fp_out, -2, SEEK_END);  // 回到倒数第二个字符
        fprintf(fp_out, "\n");         // 替换为换行符
    }
    
    fclose(fp_in);
    fclose(fp_out);
    
    printf("转换完成！处理了%d行数据\n", line_count);
    printf("输出文件: %s\n", output_file);
    
    return 0;
}

int main(void) {
    // 指定输入和输出文件的绝对路径
    const char *input_file = "f:\\Flood\\e203_asic_c\\flood_accelerator\\tb\\weights_ping.hex";
    const char *output_file = "f:\\Flood\\e203_asic_c\\flood_accelerator\\c\\axi_test\\weights_array.txt";
    
    printf("输入文件路径: %s\n", input_file);
    printf("输出文件路径: %s\n", output_file);
    
    // 执行转换
    if (convert_hex_file(input_file, output_file) != 0) {
        printf("转换失败\n");
        return 1;
    }
    
    return 0;
}