; boot sector of lgyos

org 0x7c00

; 常量定义
BASE_OF_STACK          equ 0x7c00
BASE_OF_FAT            equ 0x07e0 ; FAT表加载的位置
BASE_OF_ROOT_DIR       equ 0x0900 ; 根目录区加载到内存的位置
BASE_OF_LOADER         equ 0x0ac0 ; loader.bin加载内存位置
; 根目录占用的引导扇区数
ROOT_DIR_SECTORS_COUNT equ 14 ; 根据BPB_RootEntCnt，并且每条目32字节算出
LOADER_NAME_LEN        equ 11 ; loader.bin的文件名和扩展名的总长度
NUMBER_OF_FAT_START_SECTOR  equ 1 ; fat表起始扇区号
ROOT_DIR_START_SECTOR  equ 19 ; 根目录起始扇区号

    jmp short entry ; start to boot
    nop ; 0x90

    ; FAT12磁盘头
    BS_OEMName     db 'lgyos   ' ; oem string, 必须8字节
    BPB_BytsPerSec dw 512        ; 每扇区字节数
    BPB_SecPerClus db 1          ; 每簇扇区数
    BPB_RsvdSecCnt dw 1          ; boot记录占用的扇区数 
    BPB_NumFATs    db 2          ; 共有多少FAT表
    BPB_RootEntCnt dw 224        ; 根目录文件数最大值
    BPB_TotSec16   dw 2880       ; 逻辑扇区总数 
    BPB_Media      db 0xf0       ; 媒体描述符
    BPB_FATSz16    dw 9          ; 每个FAT表占用的扇区数
    BPB_SecPerTrk  dw 18         ; 每个磁道扇区数 
    BPB_NumHeads   dw 2          ; 磁头数(面数)
    BPB_HiddSec    dd 0          ; 隐藏扇区数
    BPB_TotSec32   dd 0          ; 如果BPB_TotSec16是0,则这里记录扇区总数
    BS_DrvNum      db 0          ; 中断13的驱动器号
    BS_Reserved1   db 0          ; 未使用
    BS_BootSig     db 29h        ; 扩展引导标记(29h)
    BS_VolID       dd 0          ; 卷序列号
    BS_VolLab      db 'lgyosdisk  ' ; 卷标，必须11个字节
    BS_FileSysType db 'FAT12   ' ; 文件系统类型, 必须8个字节

LOADER_NAME db 'LOADER  BIN' ; loader.bin在FAT12根目录中的文件名形式
; 变量
err_not_found db 'loader.bin is not found!', 0

entry:
    ; 初始化寄存器
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov gs, ax
    mov fs, ax
    mov ss, ax
    mov sp, BASE_OF_STACK

; 加载FAT表到0x7e00-0x8fff
    mov ax, BASE_OF_FAT
    mov es, ax
    mov bx, 0
    mov ax, NUMBER_OF_FAT_START_SECTOR
    mov dl, [BPB_FATSz16]
    call read_sector

; 加载根目录区0x9000-0xabff
    mov cx, ROOT_DIR_SECTORS_COUNT ; 根目录占用扇区最大值,作为循环次数
    mov ax, BASE_OF_ROOT_DIR ; es:bx缓冲区
    mov es, ax
    mov bx, 0
    mov ax, ROOT_DIR_START_SECTOR ; read_sector参数1,起始扇区号
    mov dl, 1                     ; read_sector参数2,读取扇区数量
load_root_dir:
    call read_sector
    inc ax
    add bx, 512
    loop load_root_dir

; 在根目录中查找loader.bin
    mov cx, [BPB_RootEntCnt] ; 根目录文件条目数最大值,作为循环次数
    mov bx, 0 ; es:bx缓冲区
find_loader: ; start of outer loop

    push cx
    mov cx, LOADER_NAME_LEN
    mov si, LOADER_NAME
compare_next_byte:
    mov al, [si]
    cmp al, [es:bx]
    jne continue
    inc si
    inc bx
    loop compare_next_byte
    jmp load_loader

continue:
    mov ax, 32 ; 指向下一条目, 每条目是32字节
    sub ax, bx ; 要想指向下一条目,需要32-bx，然后在用bx加上32-bx的差
    add bx, ax

    pop cx
    loop find_loader ; end of outer loop

; 没找到loader
    mov ax, 0xb800
    mov gs, ax
    mov di, 0
    mov si, err_not_found
    mov ah, 0x0c ; 0000: 黑底 1100: 红字
show_msg:
    mov al, [si]
    cmp al, 0
    je end
    mov [gs:di], ax
    inc si
    add di, 2
    jmp show_msg

; 加载loader.bin文件到内存0xac00
load_loader:
    add bx, 15 ; es:bx指向loader.bin文件对应的开始簇号
    mov ax, [es:bx] ; 将loader.bin文件对应的开始簇号保存到ax
    mov bx, BASE_OF_LOADER ; read_sector的es:bx缓冲区
    mov es, bx
    mov bx, BASE_OF_FAT
    mov fs, bx
    mov bx, 0
next_sector:
    cmp ax, 0xff7 ; FAT项值如果大于等于0xff8
                  ; 则表示当前簇已经是本文件最后一个簇
                  ; 如果为0xff7,表示它是一个坏簇
    je end
    cmp ax, 0xff8
    jnb run_loader

    ; 计算loader.bin所在起始扇区号
    ; 文件的内容存放在软盘的数据区,数据区前面有
    ; 引导扇区，2个fat表扇区，根目录区
    ; 现在得到的ax中的扇区号是在数据区的起始扇区号,而且数据区的起始扇区号
    ; 是从2开始，所以实际算出的扇区号要减2
    mov cx, ax ; 先保存ax的值
    add ax, [BPB_RsvdSecCnt] ; 加上引导扇区占的扇区数
    add ax, [BPB_FATSz16] ; 加上第一个fat表所占的扇区数
    add ax, [BPB_FATSz16] ; 加上第二个fat表所占的扇区数
    add ax, ROOT_DIR_SECTORS_COUNT ; 加上根目录所占的扇区数
    sub ax, 2 ; 得到loader.bin文件数据实际逻辑起始扇区号
    mov dl, 1
    call read_sector
    mov ax, cx ; 还原ax的值
    add bx, 512

    ; 求loader.bin下一个簇号所在内存偏移地址
    ; 如果簇号乘以1.5是个整数则偏移地址就是这个整数和
    ; 之后一个字节的低字节部分
    ; 如果乘以1.5是个小数，则偏移地址是小数的整数部分的字节的高字节部分加上
    ; 之后的一个字节
    mov cx, 3
    mul cx
    mov cx, 2
    div cx

    mov si, ax
    mov al, [fs:si]
    mov ah, [fs:si+1]

    cmp dx, 0
    je ax_is
ax_second_half_is:
    shr ax, 4
    jmp next_sector
ax_is:
    and ah, 0x0f
    jmp next_sector

run_loader:
    jmp BASE_OF_LOADER:0

;;;;; read_sector ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 商y  余数z
; 参数: ax->起始逻辑扇区号, dl->读取扇区的数量
; 逻辑扇区号是0 to (BPB_TotSec16-1), 物理扇区号是每磁道(1-18)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
read_sector:
    push bp
    push ax
    push bx
    push dx
    push cx

    mov bp, sp
    sub esp, 2 ; 辟出两个字节的堆栈区域保存要读的扇区数 : byte [bp-2]
    mov byte [bp-2], dl
    push bx    ; 保存bx
    mov bl, [BPB_SecPerTrk]  ; bl:除数
    div bl ; y在al中，z在ah中
    inc ah ; z++
    mov cl, ah ; 逻辑扇区对应的实际物理起始扇区号
    mov dh, al ; dh <- y
    shr al, 1  ; y >> 1 (y/BPB_NumHeads)
    mov ch, al ; 物理柱面号
    and dh, 1  ; y & 1, 物理磁头号
    pop bx     ; 还原bx
    mov dl, [BS_DrvNum]  ; 驱动器号(0表示A盘)
.GoOnReading:
    mov al, [bp-2] ; 要读取的扇区数
    mov ah, 2      ; 读磁盘数据
    int 0x13
    jc .GoOnReading ; 如果读取错误CF会被置为1, 这时就不停的读，直到正确为止

    add esp, 2
    pop cx
    pop dx
    pop bx
    pop ax
    pop bp
    ret

end:
    hlt
    jmp end

    times 510-($-$$) db 0
    dw 0xaa55
