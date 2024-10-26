
defc ROM_TRANSFER   = 0x8C00

defc RMM_DATA       = 0xF8
defc RMM_ADDR_LO    = 0xF9
defc RMM_ADDR_HI    = 0xFA
defc RMM_CONTROL    = 0xFB

defc BANNER_DISPLAY = 0xC000 + 80 * 64 + 4
defc BANNER_ROWS    = 32
defc BANNER_BPR     = 40

defc CONFIG_SIZE    = CONFIG_END - CONFIG_START
defc BLOCK_SIZE     = 256
defc CONFIG_BLOCKS  = (CONFIG_SIZE + (BLOCK_SIZE-1)) / BLOCK_SIZE

defc BAR_DISPLAY    = 0xC000 + 127 * 64 + 16
defc BAR_PIXELSIZE  = 96
;defc BAR_SPEEDFACTOR = BAR_PIXELSIZE * 256 / CONFIG_BLOCKS
defc BAR_SPEEDFACTOR = 0x0114

defc prog_offset    = 0x0010
;----------------------------------------------------------------------------

    org 0x7000

;----------------------------------------------------------------------------

PROG_START:
    call    ROM_TRANSFER
    dw      prog_offset
    dw      PROG_END - PROG_START + 0x100
    dw      begin
    jp      begin
; pad to prog_offset size
    dw      0, 0

;----------------------------------------------------------------------------

begin:
ASSERT begin - PROG_START = prog_offset
    di
    ; read banner rows to screen
    ld      de, BANNER - PROG_START
    ld      hl, BANNER_DISPLAY
loop1:
    ld      bc, BANNER_BPR
    call    read_rmm
    ; HL to next display line
    ; skip remaining 4 visible + 16 not visible + 4 on next line
    ld      bc, 24
    add     hl, bc
    ld      bc, rowcount
    ld      a, (bc)
    dec     a
    ld      (bc), a
    jp      nz, loop1

    ; read CONFIG blocks
    ld      de, CONFIG_START - PROG_START
    ld      hl, 0
loop2:
    ld      bc, BLOCK_SIZE
    call    read_rmm
    ; Update progress bar
    push    hl
    call    update_pb
    pop     hl
    ; next block
    ld      bc, blockcount
    ld      a, (bc)
    dec     a
    ld      (bc), a
    jp      nz, loop2

    ; start CONFIG
    jp      0

;----------------------------------------------------------------------------

;; Copy data from ROM Module to memory
; DE = src address in ROM Module
; HL = dst address in memory
; BC = number of bytes to copy
read_rmm:
    ; update BC for loop logic
    ld      a, c
    dec     bc
    inc     b
    ld      c, a
    ; configure ROM Module ports
    ld      a, 0x90
    out     (RMM_CONTROL), a
rmr1:
    ld      a, e
    out     (RMM_ADDR_LO), a
    ld      a, d
    out     (RMM_ADDR_HI), a
    in      a, (RMM_DATA)
    ld      (hl), a
    inc     de
    inc     hl
    dec     c
    jp      nz, rmr1
    dec     b
    jp      nz, rmr1
    ; deactivate ROM Module
    ld      a, 0x80
    out     (RMM_ADDR_HI), a
    ret

;----------------------------------------------------------------------------
;; Update progress bar
update_pb:
    ld      hl, (pbsf)
    ld      c, l
    ld      b, h
    ld      hl, (pbcount)
    add     hl, bc
    ld      (pbcount), hl
    ld      a, h
    or      a
    ret     z
    ld      hl, (pbaddress)
upb1:
    ld      a, (hl)
    scf
    rla
    or      0x40
    and     0x7F
    ld      (hl), a
    cp      0x7F
    jp      nz, upb2
    inc     hl
upb2:
    ld      a, (pbcount+1)
    dec     a
    ld      (pbcount+1), a
    jp      nz, upb1
upb3:
    ld      (pbaddress), hl
    ret

;----------------------------------------------------------------------------
; banner lines
rowcount:
    db      BANNER_ROWS

; progress bar speed factor
pbsf:
    dw      BAR_SPEEDFACTOR

; progress bar counter
pbcount:
    dw      0

; progress bar display address
pbaddress:
    dw      BAR_DISPLAY

; number of CONFIG blocks (256 bytes) to load from ROM Module
blockcount:
    db      CONFIG_BLOCKS

;----------------------------------------------------------------------------

PROG_END:

;----------------------------------------------------------------------------

BANNER:
    incbin "../data/banner.dat"


;----------------------------------------------------------------------------

    align 256

CONFIG_START:
    incbin "../../fujinet-config/build/config.bin"
CONFIG_END:

;----------------------------------------------------------------------------
