.code16
start:
    movw %cs,%ax
    movw %ax,%ss
    movw %ax,%es
#cls
    movb $0x7,%ah
    movb $0,%al
    int $0x10

    mov $0x9000,%ax
    mov %ax,%es
    mov $0,%di
    mov $0x4f00,%ax
    int $0x10
    cmp $0x004f,%ax
    jne vga
vbe:
#version must > 0x200
    mov %es:4(%di),%ax
    cmp $0x200,%ax
    jb vga
#mode
    mov $VBEMODE,%cx
    mov $0x4f01,%ax
    int $0x10
    cmp $0x004f,%ax
    jne vga
    cmpb $8,%es:0x19(%di) #color bits
    jne vga
    cmpb $4,%es:0x1b(%di) #color specify method
    jne vga
    mov %es:0x00(%di),%ax #mode attr
    and $0x0080,%ax
    jz vga
    mov $VBEMODE+0x4000,%bx
    mov $0x4f02,%ax
    int $0x10
    movw $0,%ax
    movw %ax,%ds
    movb $8,%ds:VMODE
    movw %es:0x12(%di),%ax
    movw %ax,%ds:SCRNX
    movw %es:0x14(%di),%ax
    movw %ax,%ds:SCRNY
    movl %es:0x28(%di),%eax
    movl %eax,%ds:VRAM
    jmp con
vga:
#VGA,320*200*8bit
    movb $0x13,%al
    movb $0x00,%ah
    int $0x10
#comment for r2p test
    movw $0,%ax
    movw %ax,%ds
    movb $8,%ds:VMODE
    movw $320,%ds:SCRNX
    movw $200,%ds:SCRNY
    movl $0xa0000,%ds:VRAM
    
con:
    mov %cs,%ax
    mov %ax,%es

#LEDS STATE
    movb $0x02,%ah
    int $0x16
    movb %al,%ds:LEDS

#GDT_LIMIT&GDT_BASE
    movw $GDTR0SEG,%ax
    movw %ax,%ss
    movw $0,%bp
    movw $5*8-1,(%bp)
    movw $GDTR0BASE,%ax
    movw %ax,2(%bp)
    movw $0x0000,4(%bp)
#NULL_SEG selector:0x8 
    movw $0,6(%bp)
    movw $0,8(%bp)
    movw $0,10(%bp)
    movw $0,12(%bp)
#CODE_SEG selector:1*8 base:0x000000
    movw $0xffff,14(%bp)
    movw $0x0000,16(%bp)
    movw $0x9a00,18(%bp)            #a WEXEC
    movw $0x00cf,20(%bp)        
#DATA_SEG selector:2*8 base:0x00000
    movw $0xffff,22(%bp)
    movw $0x0000,24(%bp)
    movw $0x9200,26(%bp)            #2 RW
    movw $0x00cf,28(%bp)            #4kb-4gb
#VIDEO_SEG selector:3*8 base:0xb8000
    movw $0xffff,30(%bp)
    movw $0x8000,32(%bp)
    movw $0x920b,34(%bp)
    movw $0x00cf,36(%bp)
#CODE_DSEG selector:4*8 base:0x00000
    movw $0xffff,38(%bp)
    movw $0x0000,40(%bp)
    movw $0x9200,42(%bp)
    movw $0x00cf,44(%bp)

    movb $0xff,%al
    outb %al,$0x21
    nop
    outb %al,$0xa1
    cli
    cld

    call openA20Gate

    movw $0,%ax
    movw %ax,%ds
    lgdtw GDTR0 #实模式下计算的物理地址是(%ds<<4)+GDTR0

openPMode:
    movl %cr0,%eax
    andl $0x7fffffff,%eax
    orl $0x1,%eax
    movl %eax,%cr0
    jmp pipelineflush

pipelineflush:
    movw $2*8,%ax
    movw %ax,%ds
    movw %ax,%es
    movw %ax,%fs
    movw %ax,%gs
    movw %ax,%ss

CBINMAP:
    movl $CBIN,%esi
    movl $CSTART,%edi
    movl $0x20000,%ecx
    call memcpy

fl2mem:
    movl $FLOPPY,%esi
    movl $MEMCAC,%edi
    movl $0x20000,%ecx
    call memcpy

    movw $4*8,%ax
    movw %ax,%ds
    movw %ax,%es
    movw %ax,%fs
    movw %ax,%gs
    movw %ax,%ss
    movl $0x310000,%esp 
    ljmpl $1*8,$0x280000
    
openA20Gate:
    call waitkbdout
    movb $0xd1,%al
    outb %al,$0x64
    call waitkbdout
    movb $0xdf,%al
    outb %al,$0x60
    call waitkbdout
    ret
openA20Gate1:
    in $0x92,%al
    or $0x2,%al
    out %al,$0x92
    ret

waitkbdout:
    in $0x64,%al
    testb $0x02,%al
    jnz waitkbdout
    ret

memcpy:
    movl (%esi),%eax
    addl $4,%esi
    movl %eax,(%edi)
    addl $4,%edi
    subl $1,%ecx
    jnz memcpy
    ret

.set LEDS,0x7ef0
.set VMODE,0x7ef1
.set SCRNX,0x7ef4
.set SCRNY,0x7ef6
.set VRAM, 0x7ef8
#0x101 640*480*8
#0x103 800*600*8
#0x105 1024*768*8
#0x107 1280*1024*8
.set VBEMODE,0x105
.set GDTR0SEG,0x07e0
.set GDTR0,0x7e00
.set GDTR0BASE,0x7e06
.set MEMCAC,0x00100000
.set FLOPPY,0x00010000
.set CSTART,0x00280000
.set CBIN,.-start+0x14400
#.code32
#mov $3*8,%ax
#mov %ax,%gs
#movl $((80*10+0)*2),%edi #10行,0列
#movb $0xC,%ah            #黑底红字
#movb $'T',%al
#
#mov %ax,%gs:(%edi)
#
#loop:
#hlt
#jmp loop
