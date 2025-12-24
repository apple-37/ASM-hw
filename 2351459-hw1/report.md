# DOSBox 环境搭建与 Hello World 程序编写

**姓名**：[滕其峰]

**学号**：[2351459]

**日期**：2025/12/7

---

## 一、 实验目的

1.  **掌握 DOSBox 的安装与配置**：了解如何在现代 64 位操作系统（Windows/macOS）中模拟 16 位 DOS 环境。
2.  **熟悉汇编开发工具链**：学会配置和使用编辑器（Edit/Notepad++）、汇编器（MASM.EXE）、链接器（LINK.EXE）和调试器（DEBUG.EXE）。
3.  **掌握汇编程序的基本流程**：编辑源码 -> 汇编 -> 链接 -> 运行。
4.  **编写并运行第一个汇编程序**：理解汇编语言的段结构、DOS 功能调用（INT 21H）及程序退出机制。

## 二、 实验环境

- **操作系统**：Windows 10 / Windows 11
- **模拟软件**：DOSBox 0.74-3 (或 DOSBox-X)
- **汇编工具包**：MASM 5.0 (包含 MASM.EXE, LINK.EXE, EDIT.COM 等)

## 三、 实验内容与步骤

### 1. DOSBox 环境搭建

由于现代操作系统不再原生支持 16 位 DOS 程序，我们需要搭建虚拟环境。

1.  **下载与安装**：从官网下载 DOSBox 安装包并完成安装。
2.  **建立工作目录**：

    - 在硬盘（如 D 盘）根目录下新建文件夹 `ASM`（路径：`D:\ASM`）。
    - 将汇编工具（`MASM.EXE`, `LINK.EXE` 等）复制到该目录下。
    - 本实验的源代码文件 `HELLO.ASM` 也保存在此目录下。

3.  **挂载虚拟磁盘（MOUNT）**：
    打开 DOSBox，在命令行窗口输入以下命令，将本地目录映射为 DOSBox 内的 C 盘：

    ```bash
    Z:\> mount c d:\asm
    Drive C is mounted as local directory d:\asm\

    Z:\> c:
    C:\>
    ```

    _(注：此时 DOSBox 内的 C: 盘即对应物理机 D:\ASM 文件夹)_

4.  **配置自动挂载（可选优化）**：
    为了避免每次启动都要输入挂载命令，编辑 DOSBox 安装目录下的配置文件（`DOSBox 0.74 Options.bat` 或 `dosbox.conf`），在 `[autoexec]` 段末尾添加：
    ```text
    mount c d:\asm
    c:
    ```

### 2. 编写汇编源代码

使用文本编辑器编写如下代码，并保存为 `HELLO.ASM`。

```assembly
.MODEL SMALL
.STACK 100h

.DATA
    ; 定义字符串，0dh(回车), 0ah(换行), '$'(结束符)
    Hello DB 'Hello world!', 0dh, 0ah, '$'

.CODE
START:
    ; 1. 初始化数据段
    MOV AX, @DATA
    MOV DS, AX

    ; 2. 调用 DOS 9号功能输出字符串
    MOV DX, offset Hello    ; DX 指向字符串首地址
    MOV AH, 9               ; AH = 09H (显示字符串功能)
    INT 21H                 ; 调用 DOS 中断

    ; 3. 返回操作系统
    MOV AX, 4C00H           ; AH = 4CH (带返回码结束)
    INT 21h

END START
```

### 3. 汇编（Assembling）

在 DOSBox 命令行中输入以下命令，将源文件 (`.ASM`) 转换为目标文件 (`.OBJ`)：

```bash
C:\> masm hello.asm
```

**执行结果**：
如果代码无误，屏幕显示 `0 Warning Errors`, `0 Severe Errors`。

### 4. 链接（Linking）

输入以下命令，将目标文件 (`.OBJ`) 转换为可执行文件 (`.EXE`)：

```bash
C:\> link hello.obj
```

**执行结果**：
系统生成 `HELLO.EXE`。可能会提示 "No stack segment"，因为本代码使用了 `.STACK` 简写方式，该警告通常可忽略。

### 5. 运行程序

输入编译好的文件名直接运行：

```bash
C:\> hello.exe
```

**执行结果**：
屏幕输出：

```text
Hello world!
```

## 四、 代码分析

1.  **`.MODEL SMALL`**：定义程序的存储模式为“小模式”，即代码段和数据段各占不超过 64KB，这是初学者最常用的模式。
2.  **段寄存器初始化**：
    ```assembly
    MOV AX, @DATA
    MOV DS, AX
    ```
    程序开始时，必须显式地将数据段地址加载到 `DS` 寄存器中，否则程序无法正确读取定义的变量 `Hello`。
3.  **DOS 中断调用 `INT 21H`**：
    - **功能 09H (输出)**：要求 `DS:DX` 指向以 `$` 结尾的字符串。
    - **功能 4CH (退出)**：这是标准的程序退出方式，能将控制权安全交还给 DOS 系统，避免程序跑飞或死机。

## 五、 实验总结

通过本次实验，我成功在 Windows 环境下搭建了 DOSBox 汇编开发环境。

1.  **理解了挂载机制**：DOSBox 是一个独立的虚拟环境，必须通过 `mount` 指令打通虚拟盘符与物理文件的联系。
2.  **掌握了开发流程**：明确了汇编语言开发必须经历“编辑 -> 汇编(MASM) -> 链接(LINK) -> 运行”这四个步骤，缺一不可。
3.  **验证了程序逻辑**：成功运行了 Hello World 程序，验证了数据段初始化和 DOS 系统调用的正确性。

这次实验为后续学习更复杂的指令系统和中断处理打下了基础。
