.code16
.byte 0xeb,0x3c,0x90,0x6d,0x6b,0x66,0x73,0x2e,0x66,0x61,0x74,0x00,0x02,0x01,0x01,0x00,0x02,0xe0,0x00,0x40,0x0b,0xf0,0x09,0x00,0x12,0x00,0x02,0x00,0x00,0x00,0x00,0xe0,0x00,0x40,0x0b,0x00,0x00,0x00,0x29,0x98,0x41,0xfa,0xe5,0x4e,0x4f,0x20,0x4e,0x41,0x4d,0x45,0x20,0x20,0x20,0x20,0x46,0x41,0x54,0x31,0x32,0x20,0x00,0x00
.globl _start
BOOTSEG=0x07c0
#软盘在内存中的位置0x1000:0x0000
SYSSEG=0x0900
_start:
    movw $BOOTSEG,%ax
    movw %ax,%ds
    movw %ax,%es
    movw %ax,%ss
    movw $SYSSEG,%ax
    movw %ax,%es
readdisk:
    movb $-1,%ch     #柱面0
    movb $-1,%dh     #磁头0
    movb $-1,%cl     #扇区1
    mov $0,%bx
    mov $0x00,%dl  #A驱动器
    mov $0,%di

    next:
    inc %di
    cmp $8,%di #从软盘读入8*64=512kB
    ja fin
    movw %es,%ax
    add $0x0700,%ax
    movw %ax,%es
    add $2,%cl
    cmp $19,%cl
    je resetcl
    jmp inchead
    resetcl:
    mov $1,%cl
    inc %dh
    inchead:
    inc %dh
    cmp $2,%dh
    je resetdh
    jmp inccylinder
    resetdh:
    mov $0,%dh
    inc %ch
    inccylinder:
    inc %ch

    halftop:
    mov $72,%al     #72个扇区
    mov $0,%si #记录失败次数的寄存器
    retry1:
        mov $0x02,%ah  #读盘
        int  $0x13      #调用磁盘bios
        jnc halfbottom
        inc %si
        cmp %si,5
        jae error
        mov $0x00,%ah
        mov $0x00,%dl
        int $0x13
        jmp retry1
    halfbottom:
        mov %es,%ax
        add $0x0900,%ax
        mov %ax,%es
        mov $0,%si
        add $2,%ch
        mov $56,%al  #56个扇区
    retry2:
        mov $0x02,%ah  #读盘
        int  $0x13      #调用磁盘bios
        jnc next
        inc %si
        cmp %si,5
        jae error
        mov $0x00,%ah
        mov $0x00,%dl
        int $0x13
        jmp retry2


        error:
        movw $errorMsg,%bp       #输出字符位置
        movw $errorMsgLen,%cx    #输出的字符长度
        call print_msg
        jmp hang

        fin:
        movw $bootMsg,%bp       #输出字符位置
        movw $bootMsgLen,%cx          #输出的字符长度
        call print_msg
        jmp os

        print_msg:
        movw $0,%ax
        movw %ax,%ds
        movw %ax,%es
        movw $0x1301,%ax        #中断功能号
        movw $0x14,%bx          #显示属性：背景及字体颜色bh:背景颜色,bl:字体颜色
        movb $0x15,%dl          #显示到列的位置
        movb $0x00,%dh          #显示到行的位置
        int $0x10
        ret

hang:
call loop
loop:
    jmp loop

os:
    ljmp $0x1000,$0x4400

bootMsg:
    .ascii "Hello,DiskReader!"
    bootMsgLen=.-bootMsg
errorMsg:
    .ascii "Error!"
    errorMsgLen=.-errorMsg

.org 510
.word 0xaa55
