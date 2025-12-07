.386
.model small
.stack 100h

data segment use16
    ; ---------------- 游戏变量 ----------------
    score       dw 0                ; 玩家得分
    lives       db 3                ; 玩家生命值 (允许漏掉 3 个金币)
    game_active db 1                ; 游戏状态开关

    ; ---------------- 玩家(聚宝盆) ----------------
    player_x    dw 140              ; 玩家 X 坐标 (初始居中)
    player_y    dw 180              ; 玩家 Y 坐标 (固定在底部)
    player_w    equ 16              ; 玩家宽度
    player_h    equ 8               ; 玩家高度

    ; ---------------- 金币(掉落物) ----------------
    ; 定义 5 个金币槽位: [状态, X坐标, Y坐标, 速度]
    ; 状态: 0=未激活, 1=激活
    ; 每个金币占用 8 字节
    coins       dw 0,0,0,0          ; Coin 1
                dw 0,0,0,0          ; Coin 2
                dw 0,0,0,0          ; Coin 3
                dw 0,0,0,0          ; Coin 4
                dw 0,0,0,0          ; Coin 5
    coins_cnt   equ 5               ; 最大同时存在的金币数
    
    rand_seed   dw 1234h            ; 伪随机数种子

    ; ---------------- 图形模型 ----------------
    ; 0:透明(不画), 其他数值:颜色索引
    ; 颜色参考: E=黄色(金币), 6=棕色(盆), 4=红色(心), F=白色

    ; 聚宝盆模型 (16x8)
    bowl_model  db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0  ; 空行
                db 6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6
                db 6,6,0,0,0,0,0,0,0,0,0,0,0,0,6,6
                db 6,6,6,0,0,0,0,0,0,0,0,0,0,6,6,6
                db 6,6,6,6,0,0,0,0,0,0,0,0,6,6,6,6
                db 0,6,6,6,6,6,6,6,6,6,6,6,6,6,6,0
                db 0,0,6,6,6,6,6,6,6,6,6,6,6,6,0,0
                db 0,0,0,6,6,6,6,6,6,6,6,6,6,0,0,0

    ; 金币模型 (8x8)
    coin_model  db 0,0,0,14,14,0,0,0    ; 14 = Yellow
                db 0,0,14,14,14,14,0,0
                db 0,14,14,15,15,14,14,0
                db 14,14,15,14,14,15,14,14
                db 14,14,15,14,14,15,14,14
                db 0,14,14,15,15,14,14,0
                db 0,0,14,14,14,14,0,0
                db 0,0,0,14,14,0,0,0

    ; ---------------- 文本信息 ----------------
    STR_START   db "CATCH THE GOLD", 0
    STR_AUTHOR  db "Assembly Final Project", 0
    STR_HINT    db "Press SPACE to Start", 0
    STR_OVER    db "GAME OVER", 0
    STR_SCORE   db "Score: ", '$'       ; 字符串以 $ 结尾用于 int 21h/09h
    STR_LIVES   db "Lives: ", '$'

data ends

code segment use16
    assume cs:code, ds:data

start:
    mov ax, data
    mov ds, ax
    mov es, ax

    ; 初始化随机种子 (利用系统时间)
    mov ah, 00h
    int 1Ah             ; 获取时钟滴答数 -> DX
    mov rand_seed, dx

    ; ------------------------------------------
    ; 1. 欢迎界面
    ; ------------------------------------------
    mov ax, 0013h       ; 进入 VGA 320x200 256色模式
    int 10h

    ; 打印标题 (利用 BIOS 中断简单打印)
    mov ah, 02h         ; 设置光标位置
    mov bh, 0           ; 页码
    mov dh, 8           ; 行
    mov dl, 12          ; 列 (近似居中)
    int 10h
    
    lea dx, STR_START   ; 注意：这里为了简化直接用字符串地址，实际需循环输出或用DOS功能
    call print_string_bios_title

    mov dh, 12
    mov dl, 10
    call set_cursor
    lea dx, STR_HINT
    call print_string_bios_title

wait_start:
    mov ah, 00h
    int 16h
    cmp al, 20h         ; 空格键开始
    jne check_esc_start
    jmp init_game
check_esc_start:
    cmp al, 1Bh         ; ESC 退出
    je exit_program_label
    jmp wait_start

exit_program_label:
    jmp exit_program

    ; ------------------------------------------
    ; 2. 游戏初始化
    ; ------------------------------------------
init_game:
    mov score, 0
    mov lives, 3
    
    ; 清空所有金币
    lea di, coins
    mov cx, 20          ; 5个金币 * 4个字 = 20个字
    xor ax, ax
    rep stosw

    ; 设置显存段地址
    mov ax, 0A000h
    mov es, ax

    ; ------------------------------------------
    ; 3. 主循环 (Main Loop)
    ; ------------------------------------------
main_loop:
    ; A. 垂直同步 (限制帧率)
    mov dx, 3DAh
vsync_wait1:
    in al, dx
    test al, 8
    jz vsync_wait1
vsync_wait2:
    in al, dx
    test al, 8
    jnz vsync_wait2

    ; B. 清屏 (背景填充黑色)
    xor di, di
    xor eax, eax        ; 颜色 0 (黑)
    mov cx, 16000       ; 320*200 / 4 = 16000 dwords
    rep stosd

    ; C. 输入处理
    mov ah, 01h         ; 检查缓冲区
    int 16h
    jz logic_update     ; 无按键，跳去更新逻辑

    mov ah, 00h         ; 读取按键
    int 16h
    
    cmp al, 1Bh         ; ESC
    je game_over

    ; 左右移动处理
    cmp ah, 4Bh         ; 左箭头扫描码
    jne check_right
    cmp player_x, 5
    jl logic_update
    sub player_x, 5     ; 移动速度
    jmp logic_update

check_right:
    cmp ah, 4Dh         ; 右箭头扫描码
    jne logic_update
    cmp player_x, 300   ; 320 - 宽16 ≈ 304
    jg logic_update
    add player_x, 5

; D. 游戏逻辑更新
logic_update:
    ; 1. 尝试生成新金币
    call rand
    and ax, 0FFh
    cmp al, 60              ; 概率改为 60，让金币掉落更频繁
    ja update_coins
    call spawn_coin

update_coins:
    lea bx, coins           ; BX 指向金币数组
    mov cx, coins_cnt       ; 循环 5 次

coin_loop:
    cmp word ptr [bx], 0    ; 检查 active 状态
    je next_coin

    ; 金币下落
    mov ax, [bx+4]          ; 获取 Y
    add ax, 2               ; 下落速度
    mov [bx+4], ax

    ; --- 碰撞检测 ---
    cmp ax, player_y        ; Y 轴判定 (是否到达玩家高度)
    jl check_ground         ; 没到高度，检查是否落地

    ; Y轴重合，检查 X 轴
    mov dx, [bx+2]          ; coin_x
    mov si, player_x
    sub si, 8               ; 左侧容差
    cmp dx, si
    jl check_ground         ; 偏左
    
    add si, 24              ; 右侧容差
    cmp dx, si
    jg check_ground         ; 偏右

    ; ** 接住了! **
    inc score
    mov word ptr [bx], 0    ; 移除金币
    jmp next_coin

check_ground:
    cmp ax, 190             ; 是否触底
    jl next_coin            ; 未触底，继续

    ; ** 漏掉了! **
    dec lives
    mov word ptr [bx], 0    ; 移除金币
    cmp lives, 0
    jz game_over            ; 生命归零

next_coin:
    add bx, 8               ; 移动到下一个金币结构体
    dec cx
    jnz coin_loop
    ; E. 绘制画面
draw_phase:
    ; 1. 绘制玩家 (聚宝盆)
    mov si, offset bowl_model
    mov di, player_y
    imul di, 320            ; Y * 320
    add di, player_x        ; + X
    mov cx, 8               ; 高度 8 行
    mov dx, 16              ; 宽度 16 像素
    call draw_sprite_block

    ; 2. 绘制金币
    lea bx, coins
    mov cx, coins_cnt

draw_coins_loop:
    cmp word ptr [bx], 0
    je skip_draw_coin
    
    push cx                 ; 保存外层循环计数
    
    mov si, offset coin_model
    mov di, [bx+4]          ; Y
    imul di, 320
    add di, [bx+2]          ; X
    
    mov cx, 8               ; 高度
    mov dx, 8               ; 宽度
    call draw_sprite_block
    
    pop cx                  ; 恢复
skip_draw_coin:
    add bx, 8
    loop draw_coins_loop

    ; 3. 绘制UI (生命值指示)
    ; 直接画简单的色块代表生命
    mov cx, 0
    mov cl, lives
    cmp cl, 0
    je draw_score_dots_end
    
    mov di, 320*5 + 10      ; 屏幕左上角位置 (Y=5, X=10)
    
draw_life_dots:
    push cx
    mov al, 4               ; 红色
    mov cx, 5               ; 宽5
    rep stosb
    add di, 5               ; 间隔
    pop cx
    loop draw_life_dots

draw_score_dots_end:
    jmp main_loop


    ; ------------------------------------------
    ; 4. 游戏结束
    ; ------------------------------------------
game_over:
    ; 恢复到文本模式或保持图形模式显示 Game Over
    ; 这里简单切回文本模式并输出分数
    mov ax, 0003h
    int 10h

    mov ah, 09h
    lea dx, STR_OVER
    int 21h

    ; 输出换行
    mov ah, 02h
    mov dl, 0Dh
    int 21h
    mov dl, 0Ah
    int 21h

    ; 输出分数 (这里只输出简单的字符串提示，数字转字符略复杂，作业中可选)
    mov ah, 09h
    lea dx, STR_SCORE
    int 21h
    
    ; 简单的将分数低位转换为字符打印(仅示例个位数)
    mov ax, score
    and al, 0Fh
    add al, '0'
    mov dl, al
    mov ah, 02h
    int 21h

    mov ah, 07h             ; 等待任意键
    int 21h

exit_program:
    mov ax, 4C00h
    int 21h


; ------------------------------------------
; 子程序: 绘制 Sprite 块
; 输入: SI=位图数据地址, DI=显存起始偏移, CX=高度, DX=宽度
; ------------------------------------------
draw_sprite_block proc near
    push ax
    push bx
    push di
    push si

row_loop:
    push cx             ; 保存剩余行数
    push di             ; 保存当前行起始显存地址
    mov cx, dx          ; 宽度放入 CX 用于循环
    
col_loop:
    lodsb               ; 读取模型字节到 AL，SI++
    cmp al, 0           ; 是否透明?
    je skip_pixel
    mov es:[di], al     ; 写入显存
skip_pixel:
    inc di
    loop col_loop

    pop di              ; 恢复行首
    add di, 320         ; 下一行
    pop cx              ; 恢复行计数
    loop row_loop

    pop si
    pop di
    pop bx
    pop ax
    ret
draw_sprite_block endp

; ------------------------------------------
; 子程序: 生成新金币
; 寻找一个空闲槽位并初始化
; ------------------------------------------
spawn_coin proc near
    lea bx, coins
    mov cx, coins_cnt
find_slot:
    cmp word ptr [bx], 0    ; 检查 active 位
    je found_slot
    add bx, 8
    loop find_slot
    ret                     ; 没找到空位，返回

found_slot:
    mov word ptr [bx], 1    ; 设置 active = 1
    
    ; 生成随机 X (10 到 300)
    call rand
    xor dx, dx
    mov cx, 290
    div cx
    add dx, 10
    mov [bx+2], dx          ; 存入 X
    
    mov word ptr [bx+4], 0  ; Y = 0 (顶部)
    ret
spawn_coin endp

; ------------------------------------------
; 子程序: 伪随机数生成器 (线性同余法)
; ------------------------------------------
rand proc near
    push dx
    mov ax, rand_seed
    mov dx, 351
    mul dx
    add ax, 45
    mov rand_seed, ax
    pop dx
    ret
rand endp

; ------------------------------------------
; 辅助: BIOS 打印字符串 (以 0 结尾)
; ------------------------------------------
print_string_bios_title proc near
    mov si, dx
ps_loop:
    lodsb
    cmp al, 0
    je ps_exit
    mov ah, 0Eh
    mov bl, 0Fh     ; 白色
    int 10h
    jmp ps_loop
ps_exit:
    ret
print_string_bios_title endp

; ------------------------------------------
; 辅助: 设置光标
; ------------------------------------------
set_cursor proc near
    mov ah, 02h
    mov bh, 0
    int 10h
    ret
set_cursor endp

code ends
end start