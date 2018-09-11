MyData segment
    g_strHex2Bin    db '0000$'
                    db '0001$'
                    db '0010$'
                    db '0011$'
                    db '0100$'
                    db '0101$'
                    db '0110$'
                    db '0111$'
                    db '1000$'
                    db '1001$' ; 0x9
                    db 'xxxx$'
                    db 'xxxx$'
                    db 'xxxx$'
                    db 'xxxx$'
                    db 'xxxx$'
                    db 'xxxx$'
                    db 'xxxx$'
                    db '1010$' ; 0xa   如果是字母,不管大小写,都补我们转成了大写,所以,以处理16进制A为例: 'A' - '0' = 17  具体代码在 NEXT: 代码块里
                    db '1011$' ; 0xb
                    db '1100$'
                    db '1101$'
                    db '1110$'
                    db '1111$'


MyData ends


MyCode2 segment

ShowBin proc far ;near
    ;进堆栈的顺序依次是  参数ax->后面几个是系统自己保存到堆栈里面的->cs->ip->bp->local->regs
    argHexAsc = word ptr 6       ;全局变量写法
    @wRetVal = word ptr -2       ;局部变量写法
    push bp       ;保存之前的bp,因为bp会被覆盖
    mov bp, sp    ;栈顶给栈底,保存栈
    sub sp, 2     ;sp = sp -2 栈顶往后移2个字节,用来存放返回值
    
	;保存环境
    push ds
    push dx
    push di
    push bx
    
    ;---------设置数据段
    mov ax, MyData
    mov ds, ax
    
	;如果 [bp+@wRetVal] 值最后为0:当前处理的16进制字符非法    如果 [bp+@wRetVal] 值最后为 1:当前处理的16进制字节合法
    mov [bp+@wRetVal], 0
    
    xor ax, ax     ;传入的16进制数只占1位,也就是说ah位不能有数据,如果有的话, 后面就不能直接用ax,而要用al,所以这里要将ah也置为0
    mov ax, [bp+argHexAsc]       ;[bp+argHexAsc] 得到的是传入的参数 即 要转换成2进制的16进制数
    
	;------判断是否不为 0~9 的数值
    cmp al, '0'
    jb UNMAT1       ;小于
    cmp al, '9'
    ja UNMAT1       ;大于
        mov [bp+@wRetVal], 1    ;当前处理的16进制字节合法
        jmp NEXT

;------------判断是否在 A~F 区间
UNMAT1:
    cmp al, 'A'
    jb UNMAT2       ;小于    不在 A~F 区间,跳转到 UNMAT2 -> (判断是否在 a~f 区间)
    cmp al, 'F'
    ja UNMAT2       ;大于    不在 A~F 区间,跳转到 UNMAT2 -> (判断是否在 a~f 区间)
        mov [bp+@wRetVal], 1    ;当前处理的16进制字节合法
        jmp NEXT
        
;------------判断是否在 a~f 区间
UNMAT2:
    cmp al, 'a'
    jb UNMAT3       ;小于
    cmp al, 'f'
    ja UNMAT3       ;大于
        mov [bp+@wRetVal], 1    ;当前处理的16进制字节合法
        sub al, 'a' - 'A'       ;'a' - 'A' = 97-65 = 32  -> 最后结果: al = al - 32;  -> 将小写字母的al数值改成跟大写字母的al数值相同,这样就可以只处理大写的情况
        jmp NEXT
        
UNMAT3:
    jmp EXIT_PROC

NEXT:   ;执行完 NEXT 段,还是会继续往下执行 EXIT_PROC 段的
    
    sub ax, '0' ; ax = ax - '0'   转成了10进制   如果是字母,不管大小写,都补我们转成了大写,所以,以处理16进制A为例: 'A' - '0' = 17
    mov dl, 5
    mul dl      ; ax = ax*5      16进制的1位,2进制要输出4位,加上后面的结束符$ 如-> '0000$' ,总共是5个字节,所以偏移是5的位数
    mov bx, offset g_strHex2Bin
    mov di, ax
	
	;打印字符串到屏幕  , 这里没有循环,只处理参数传入的其中一个16进制字符 , 循环在函数调用处
    lea dx, [bx+di]
    mov ah, 9
    int 21h
    
EXIT_PROC: 
    mov ax, [bp+@wRetVal]    ;在函数返回的时候,ax存放着返回值 1:表示当前处理的16进制中的当前处理位合法  0:表示当前处理的16进制中的当前处理位非法
    
    pop bx
    pop di
    pop dx
    pop ds
    
    mov sp, bp
    pop bp
    
    ret 2      ;在执行ret指令的基础上sp再加2. 用来平栈,因为调用该函数的地方有一个 push ax 操作.
ShowBin endp
    
MyCode2 ends

end