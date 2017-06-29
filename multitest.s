; os memory map
CLRTEXT = $c050
SETTEXT = $c051
CLRMIXED = $c052
SETMIXED = $c053
TXTPAGE1 = $c054
TXTPAGE2 = $c055
CLRHIRES = $c056
SETHIRES = $c057

; ROM entry points
COUT = $fded
ROMWAIT = $fca8

; Zero page locations we use (unused by Monitor, Applesoft, or ProDOS)
PARAM0          = $06
PARAM1          = $07
PARAM2          = $08
PARAM3          = $09
SCRATCH0        = $19
SCRATCH1        = $1a
SPRITEPTR_L     = $1b
SPRITEPTR_H     = $1c

BGTOP = $c0       ; page number of first byte beyond top of backing store stack
bgstore = $80
bgline = $82

; constants
MAXPOSX                 = 127   ; This demo doesn't wanna do 16 bit math
MAXPOSY                 = 127


    *= $6000

start
    bit CLRTEXT     ; start with HGR page 1, full screen
    bit CLRMIXED
    bit TXTPAGE1
    bit SETHIRES

    ;jsr clrscr
    jsr initsprites

gameloop
    jsr renderstart
    jsr movestart
    jsr wait
    jsr restorebg_driver
    jmp gameloop


initsprites
    jsr restorebg_init
    rts


; Draw sprites by looping through the list of sprites
renderstart
    ldy #0

renderloop
    lda sprite_active,y
    bmi renderend       ; end of list if negative
    beq renderskip      ; skip if zero
    lda sprite_l,y
    sta jsrsprite+1
    lda sprite_h,y
    sta jsrsprite+2
    lda sprite_x,y
    sta PARAM0
    lda sprite_y,y
    sta PARAM1

jsrsprite
    jsr $ffff           ; wish you could JSR ($nnnn)
renderskip
    iny
    bne renderloop      ; branch always because always positive; otherwise limited to 255 sprites (haha)

renderend
    rts


movestart
    ldy #0

moveloop
    lda sprite_active,y
    bmi moveend
    beq movenext

movex
    ; Apply X velocity to X coordinate
    clc
    lda sprite_x,y
    adc sprite_dx,y
    bmi flipX
    cmp #MAXPOSX
    bpl flipX

    ; Store the new X
    sta sprite_x,y

movey
    ; Apply Y velocity to Y coordinate
    clc
    lda sprite_y,y
    adc sprite_dy,y
    bmi flipY
    cmp #MAXPOSY
    bpl flipY

    ; Store the new Y
    sta sprite_y,y

movenext
    iny
    bne moveloop

moveend
    rts


flipX
    lda sprite_dx,y
    eor #$ff
    clc
    adc #1
    sta sprite_dx,y
    jmp movey

flipY
    lda sprite_dy,y
    eor #$ff
    clc
    adc #1
    sta sprite_dy,y
    jmp movenext



wait
    ldy     #$06    ; Loop a bit
wait_outer
    ldx     #$ff
wait_inner
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    dex
    bne     wait_inner
    dey
    bne     wait_outer
    rts


clrscr
    lda #0
    sta clr1+1
    lda #$20
    sta clr1+2
clr0
    lda #$81
    ldy #0
clr1
    sta $ffff,y
    iny
    bne clr1
    inc clr1+2
    ldx clr1+2
    cpx #$40
    bcc clr1
    rts

; Sprite data is interleaved so a simple indexed mode can be used. This is not
; convenient to set up but makes faster accessing because you don't have to 
; increment the index register. For example, all the info about sprite #2 can
; be indexed using Y = 2 on the indexed operators, e.g. "lda sprite_active,y",
; "lda sprite_x,y", etc.

sprite_active
    .byte 1, 1, 1, 1, 1, 1, 1, 1, $ff  ; 1 = active, 0 = skip, $ff = end of list

sprite_l
    .byte <BWSPRITE, <BWSPRITE, <BWSPRITE, <BWSPRITE, <BWSPRITE, <BWSPRITE, <BWSPRITE, <BWSPRITE

sprite_h
    .byte >BWSPRITE, >BWSPRITE, >BWSPRITE, >BWSPRITE, >BWSPRITE, >BWSPRITE, >BWSPRITE, >BWSPRITE

sprite_x
    .byte 80, 64, 33, 83, 4, 9, 55, 18

sprite_y
    .byte 116, 126, 40, 60, 80, 100, 120, 140

sprite_dx
    .byte -1, -2, -3, -4, 1, 2, 3, 4

sprite_dy
    .byte -4, -3, -2, -1, 4, 3, 2, 1


    .include colorsprite.s
    .include bwsprite.s
    .include rowlookup.s
    .include collookupbw.s
    .include collookupcolor.s
    .include backingstore.s
    .include backingstore-3x11.s
