ld hl, #0xF000
ld de, #0x1000
loop_clear:
ld (hl), #' '
inc hl
dec de
ld a, d
or e
jp nz, loop_clear

ld hl, #0xF080
ld a, #0
ld b, #16
loop0:
inc hl
ld (hl), a
inc hl
inc a
djnz loop0

ld hl, #0xF180
ld b, #16
loop1:
inc hl
ld (hl), a
inc hl
inc a
djnz loop1

ld hl, #0xF280
ld b, #16
loop2:
inc hl
ld (hl), a
inc hl
inc a
djnz loop2

ld hl, #0xF380
ld b, #16
loop3:
inc hl
ld (hl), a
inc hl
inc a
djnz loop3

ld hl, #0xF480
ld b, #16
loop4:
inc hl
ld (hl), a
inc hl
inc a
djnz loop4

ld hl, #0xF580
ld b, #16
loop5:
inc hl
ld (hl), a
inc hl
inc a
djnz loop5

ld hl, #0xF680
ld b, #16
loop6:
inc hl
ld (hl), a
inc hl
inc a
djnz loop6

ld hl, #0xF780
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
