; Clear with spaces
ld hl, #0xF000
ld de, #0x1000
loop_clear:
ld (hl), #' '
inc hl
dec de
ld a, d
or e
jp nz, loop_clear

; Fill in corners with 0x7F
ld hl, #0xF000
ld (hl), #0x7F
ld hl, #0xF033
ld (hl), #0x7F
ld hl, #0xFB80
ld (hl), #0x7F
ld hl, #0xFBB3
ld (hl), #0x7F

; Fill in around corners with 0x16
ld hl, #0xF001
ld (hl), #0x16
ld hl, #0xF032
ld (hl), #0x16
ld hl, #0xF080
ld (hl), #0x16
ld hl, #0xF0B3
ld (hl), #0x16
ld hl, #0xFB81
ld (hl), #0x16
ld hl, #0xFBB2
ld (hl), #0x16
ld hl, #0xFB00
ld (hl), #0x16
ld hl, #0xFB33
ld (hl), #0x16

; Char map
ld hl, #0xF101
ld a, #0
ld b, #16
loop0:
inc hl
ld (hl), a
inc hl
inc a
djnz loop0

ld hl, #0xF201
ld b, #16
loop1:
inc hl
ld (hl), a
inc hl
inc a
djnz loop1

ld hl, #0xF301
ld b, #16
loop2:
inc hl
ld (hl), a
inc hl
inc a
djnz loop2

ld hl, #0xF401
ld b, #16
loop3:
inc hl
ld (hl), a
inc hl
inc a
djnz loop3

ld hl, #0xF501
ld b, #16
loop4:
inc hl
ld (hl), a
inc hl
inc a
djnz loop4

ld hl, #0xF601
ld b, #16
loop5:
inc hl
ld (hl), a
inc hl
inc a
djnz loop5

ld hl, #0xF701
ld b, #16
loop6:
inc hl
ld (hl), a
inc hl
inc a
djnz loop6

ld hl, #0xF801
ld b, #16
loop7:
inc hl
ld (hl), a
inc hl
inc a
djnz loop7

ld a, #0
out (#0), a
di
halt
.area _DATA (ABS)
