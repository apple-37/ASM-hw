#include <stdio.h>
#include <dos.h>

/* 定义旧的中断处理程序指针，用于恢复 */
void interrupt (*old_int4)(void);

/* 新的中断服务程序：当溢出发生时执行 */
void interrupt new_int4(void) {
    printf("\n[SYSTEM] Overflow Interrupt (Int 4) triggered!\n");
    printf("[SYSTEM] Calculation result is incorrect.\n");
}

int main() {
    int a = 32767; // 16位有符号整数的最大值
    int b = 1;
    
    /* 1. 保存旧的 4号中断向量 (INTO) */
    old_int4 = getvect(0x04);

    /* 2. 设置新的中断向量指向我们的函数 */
    setvect(0x04, new_int4);

    printf("Starting calculation...\n");

    /* 3. 内联汇编部分 */
    asm {
        mov ax, a      ; 将 a 加载到 AX
        add ax, b      ; 执行加法 (32767 + 1 = 32768，发生溢出，OF置1)
        into           ; 检查溢出标志(OF)，如果为1，则触发 4号中断
    }
    
    /* 注意：如果没有触发中断，这里会继续执行 */
    printf("Calculation finished (If no warning above, result was valid).\n");

    /* 4. 恢复旧的中断向量，保持系统稳定性 */
    setvect(0x04, old_int4);

    return 0;
}