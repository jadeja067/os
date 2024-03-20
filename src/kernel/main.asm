ORG 0x7C00
BITS 16

start:
    MOV si,os_boot_msg
    CALL print
    HLT

halt:
    JMP halt

print:
    PUSH si
    PUSH ax
    PUSH bx

print_loop:
    LODSB 
    OR al,al
    JZ done

    MOV ah,0x0E
    MOV bh,0
    INT 0x10

    JMP print_loop

done:
    POP bx
    POP ax
    POP si
    RET

os_boot_msg: DB "KaSoft is booted", 0x0D, 0x0A,0

TIMES 510-($-$$) DB 0
DW 0AA55h
