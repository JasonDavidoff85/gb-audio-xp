INCLUDE "hardware.inc"
INCLUDE "definitions.inc"

SECTION "Graphics", ROM0
DefaultVBlankHandler::
	ld a, [wFillTilemapPending]
	or a
	jr z, .skipFill
	xor a
	ld [wFillTilemapPending], a
	xor a
	ld [rLCDC], a
	call FillTilemap
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ16 | LCDCF_BG8000
	ld [rLCDC], a
.skipFill

	; Update scroll position for infinite scrolling
	; Only update every 4 frames for slower speed
	ld a, [wScrollCounter]
	inc a
	cp 4                 ; Update every 4 frames
	jr nz, .updateCounter

	; Reset counter and update scroll
	xor a, a
	ld [wScrollCounter], a

	ld a, [wScrollX]
	inc a                ; Increment X scroll
	ld [wScrollX], a
	ld [rSCX], a         ; Write to hardware scroll register

	ld a, [wScrollY]
	inc a                ; Increment Y scroll
	ld [wScrollY], a
	ld [rSCY], a         ; Write to hardware scroll register
	jr .continueVBlank

.updateCounter:
	ld [wScrollCounter], a

.continueVBlank:

	; load counter and increment
	ldh a, [hBPMCounter + 1]

	; check bit (bpm)
	bit 5, a

	; if at bpm play note and change pallet
	jr z, .skipCpl

	; get pallet and invert and reset (flashing effect)
	; ld a, [rBGP]
	; cpl
	; ld [rBGP], a

	.skipCpl

	reti

; ------------------------------------------------------------------------------
; `func FillTilemap()`
;
; Fills the entire 32x32 BG tilemap ($9800-$9BFF) with the tile index
; stored in wTileIndex.
; ------------------------------------------------------------------------------
FillTilemap::
	ld a, [wCurrentChannel]
	ld e, a
	ld hl, $9800
	ld bc, $0400
.loop
	ld a, e
	ld [hli], a
	dec bc
	ld a, b
	or a, c
	jr nz, .loop
	ret

; ------------------------------------------------------------------------------
; `binary data Tileset`
;
; This is the tileset data for the game. Since it is just a demo, I was able to
; fit all the graphics I need into the GameBoy's 6144 byte character RAM region.
; Bigger games will need to swap out graphics during runtime based on what needs
; to be rendered at a given time.
; ------------------------------------------------------------------------------
Tileset::
    db $01,$00,$02,$00,$04,$00,$08,$00,$10,$00,$20,$00,$40,$00,$80,$00
    db $FF,$00,$FF,$00,$FF,$00,$FF,$00,$00,$00,$FF,$00,$FF,$00,$FF,$00
    db $81,$81,$42,$42,$24,$24,$18,$18,$18,$18,$24,$24,$42,$42,$81,$81
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $01,$00,$02,$05,$04,$00,$08,$14,$10,$00,$20,$50,$40,$00,$80,$40
    db $FF,$00,$FF,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$FF,$00,$FF,$00
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $03,$02,$02,$05,$0E,$0A,$08,$14,$38,$28,$20,$50,$E0,$A0,$80,$40
    db $FF,$00,$FF,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$FF,$00,$FF,$00
    db $99,$99,$42,$42,$24,$24,$99,$99,$99,$99,$24,$24,$42,$42,$99,$99
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $C7,$82,$8A,$05,$1F,$0A,$2A,$14,$7C,$28,$A8,$50,$F1,$A0,$A2,$41
    db $00,$00,$FF,$00,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$00
    db $F9,$99,$43,$42,$25,$24,$99,$99,$99,$99,$A4,$24,$C2,$42,$9F,$99
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $C7,$92,$CA,$65,$3F,$6A,$2A,$94,$7C,$29,$AC,$56,$F3,$A6,$A2,$49
    db $FF,$00,$FF,$FF,$00,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$FF,$00
    db $F9,$9F,$43,$FE,$25,$FE,$99,$FF,$99,$FF,$A4,$7F,$C2,$7F,$9F,$F9
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00