ORG 0x7C00
BITS 16

JMP SHORT main
NOP

bdb_oem:    DB  'MSWIN4.1'
bdb_bytes_per_sector:   DW 512
bdb_sectors_per_cluster:    DB 1
bdb_reserved_sectors:   DW 1
bdb_fat_count:  DB 2
bdb_dir_entries_count:  DW 0E0h
bdb_total_sectors:  DW 2880
bdb_media_descriptor_type:  DB 0F0h
bdb_sectors_per_fat:    DW 9
bdb_sectors_per_track:  DW 18
bdb_heads:  DW 2
bdb_hidden_sectors: DD 0
bdb_large_sector_count: DD 0

ebr_drive_number:   DB 0
                    DB 0
ebr_signature:  DB 29h
ebr_volume_id:  DB 12h,34h,56h,78h
ebr_volume_label:   DB 'JAZZ OS    '
ebr_system_id:  DB 'FAT12   '

main:
    MOV ax,0
    MOV ds,ax
    MOV es,ax
    MOV ss,ax

    MOV sp,0x7c00

    MOV si,os_boot_msg
    CALL print
    
    MOV ax,[bdb_sectors_per_fat]
    MOV bl,[bdb_fat_count]
    XOR bh,bh
    MUL bx
    ADD ax,[bdb_reserved_sectors]
    PUSH ax

    MOV ax, [bdb_dir_entries_count]
    SHL ax,5
    XOR dx,dx 
    DIV word [bdb_bytes_per_sector]

    TEST dx,dx 
    JZ rootDirAfter
    INC ax

rootDirAfter:
    MOV cl,al
    POP ax
    MOV dl,[ebr_drive_number]
    MOV bx,buffer
    CALL disk_read

    XOR bx,bx
    MOV di,buffer

searchKernel:
    MOV si,file_kernel_bin
    MOV cx,11
    PUSH di
    REPE CMPSB
    POP di
    JE foundKernel

    ADD di,32
    INC bx
    CMP bx,[bdb_dir_entries_count]
    JL searchKernel

    JMP kernelNotFound

kernelNotFound:
    MOV si,file_kernel_not_found
    call print

    HLT
    JMP halt

foundKernel:
    MOV ax,[di+26]
    MOV [kernel_cluster],ax
    
    MOV ax,[bdb_reserved_sectors]
    MOV bx,buffer
    MOV cl,[bdb_sectors_per_fat]
    MOV dl,[ebr_drive_number]

    CALL disk_read

    MOV bx,kernel_load_segment
    MOV es,bx
    MOV bx,kernel_load_offset

loadKenelLoop:
    MOV ax,[kernel_cluster]
    ADD ax,31
    MOV cl,1
    MOV dl,[ebr_drive_number]

    CALL disk_read

    ADD bx, [bdb_bytes_per_sector]

    MOV ax,[kernel_cluster]
    MOV cx,3
    MUL cx
    DIV cx

    MOV si, buffer 
    ADD si,ax
    MOV ax,[ds:si]

    OR dx,dx,
    JZ even

odd: 
    SHR ax,4
    JMP nextClusterAfter

even:
    AND ax,0x0FFF

nextClusterAfter:
    CMP ax,0x0FF8
    JAE readFinish

    MOV [kernel_cluster],ax
    JMP loadKenelLoop

readFinish:
    MOV dl,[ebr_drive_number]
    MOV ax,kernel_load_segment
    MOV ds,ax
    MOV es,ax

    JMP kernel_load_segment:kernel_load_offset
    HLT

halt:
    JMP halt

lba_to_chs:
    PUSH ax
    PUSH dx

    XOR dx,dx
    DIV word [bdb_sectors_per_track] 
    INC dx
    MOV cx,dx

    XOR dx,dx 
    DIV word [bdb_heads]
    
    MOV dh,dl
    MOV ch,al
    SHL ah, 6
    OR cl,ah

    POP ax
    MOV dl,al
    POP ax

    RET

disk_read:
    PUSH ax
    PUSH bx
    PUSH cx
    PUSH dx
    PUSH di

    CALL lba_to_chs

    MOV ah,02h
    MOV di,3

retry:
    STC
    INT 13h
    JNC doneRead

    call diskReset

    DEC di
    TEST di,di
    JNZ retry

failDiskRead:
    MOV si, read_failute
    CALL print
    HLT
    JMP halt

diskReset:
    pusha
    MOV ah,0
    STC
    INT 13h
    JC failDiskRead
    POPA
    RET

doneRead:
    POP di
    POP dx
    POP cx
    POP bx
    POP ax 

    RET

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

os_boot_msg: DB "KaSoft is booting...", 0x0D, 0x0A,0
read_failute DB 'Failed to read disk', 0x0D, 0x0A,0

file_kernel_bin DB 'KERNEL  BIN'
file_kernel_not_found DB 'not found'

kernel_load_segment EQU 0X2000
kernel_load_offset EQU 0
kernel_cluster DW 0

TIMES 510-($-$$) DB 0
DW 0AA55h

buffer: