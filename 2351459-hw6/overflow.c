/* overflow.c - 溢出中断服务程序测试程序
 * 通过内联汇编触发溢出，调用INT0中断处理程序 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// 全局变量，用于存储溢出信息
char overflow_msg[] = "Overflow detected! Interrupt 0 handled.\n";
int overflow_count = 0;

int main() {
    printf("=== 溢出中断服务程序测试 ===\n");
    printf("即将执行可能产生溢出的运算...\n\n");
    
    // 测试1：有符号字节溢出
    printf("测试1: 有符号字节运算\n");
    signed char a = 100;
    signed char b = 50;
    signed char result;
    
    printf("%d + %d = ", a, b);
    
    // 使用内联汇编执行加法，可能触发溢出
    asm volatile (
        "movb %1, %%al\n"      // 将a加载到AL寄存器
        "addb %2, %%al\n"      // AL = AL + b，可能溢出
        "movb %%al, %0\n"      // 将结果存储到result
        : "=m" (result)        // 输出操作数
        : "m" (a), "m" (b)     // 输入操作数
        : "al", "cc"           // 被修改的寄存器和标志位
    );
    
    printf("%d\n", result);
    
    // 测试2：有符号字溢出
    printf("\n测试2: 有符号字运算\n");
    signed short x = 30000;
    signed short y = 5000;
    signed short result2;
    
    printf("%d + %d = ", x, y);
    
    asm volatile (
        "movw %1, %%ax\n"      // 将x加载到AX寄存器
        "addw %2, %%ax\n"      // AX = AX + y，可能溢出
        "movw %%ax, %0\n"      // 将结果存储到result2
        : "=m" (result2)       // 输出操作数
        : "m" (x), "m" (y)     // 输入操作数
        : "ax", "cc"           // 被修改的寄存器和标志位
    );
    
    printf("%d\n", result2);
    
    // 测试3：检测溢出并模拟INT0处理
    printf("\n测试3: 检测溢出并模拟INT0处理\n");
    signed char max_val = 127;
    signed char add_val = 10;
    signed char overflow_result;
    int overflow_detected = 0;
    
    printf("%d + %d (预期溢出) = ", max_val, add_val);
    
    // 使用汇编检测溢出标志 (简化版本)
    asm volatile (
        "movb %2, %%al\n"      // 加载最大值到AL
        "addb %3, %%al\n"      // 加法运算，可能设置溢出标志
        "seto %b1\n"           // 如果溢出，设置overflow_detected为1
        "movb %%al, %0\n"      // 存储结果
        : "=m" (overflow_result), "=q" (overflow_detected)
        : "m" (max_val), "m" (add_val)
        : "al", "cc"
    );
    
    printf("%d\n", overflow_result);
    
    // 如果检测到溢出，模拟INT0处理
    if (overflow_detected) {
        printf("检测到溢出! 模拟INT0中断处理...\n");
        overflow_count++;
        printf("%s", overflow_msg);
    }
    
    printf("\n=== 测试结果 ===\n");
    printf("溢出发生次数: %d\n", overflow_count);
    
    return 0;
}