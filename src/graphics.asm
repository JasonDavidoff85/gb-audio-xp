INCLUDE "hardware.inc"
INCLUDE "definitions.inc"

SECTION "Graphics", ROM0

SetupSprites::
	ld hl, pSpriteOAM
	ld c, 8
	ld b, 4
.ch1SquareLoop:
	ld a, b
	bit 0, a
	jr z, .yStart0
	ld e, 160
	jr .gotY
.yStart0:
	ld e, 0
.gotY:
	ld a, e
	ld [hli], a
	ld a, c
	ld [hli], a
	ld a, 24
	ld [hli], a
	xor a
	ld [hli], a
	ld a, e
	ld [hli], a
	ld a, c
	add a, 8
	ld [hli], a
	ld a, 24
	ld [hli], a
	xor a
	ld [hli], a
	ld a, c
	add a, 40
	ld c, a
	dec b
	jr nz, .ch1SquareLoop
	ret

IncCh1Squares::
	ld a, [wCh1SquareCounter]
	inc a
	cp CH1_SQUARE_THRESHOLD
	jr nz, .updateCounter
	xor a
	ld [wCh1SquareCounter], a
	jr .doInc
.updateCounter:
	ld [wCh1SquareCounter], a
	ret
.doInc:
	ld hl, pSpriteOAM
	ld de, 4
	ld b, 8
	ld c, 0
.ch1SquareLoop:
	ld a, c
	bit 1, a
	jr nz, .decEntry
	inc [hl]
	jr .nextEntry
.decEntry:
	dec [hl]
.nextEntry:
	inc c
	add hl, de
	dec b
	jr nz, .ch1SquareLoop
	ret

DecCh1Squares::
	ld a, [wCh1SquareDecCounter]
	inc a
	cp CH1_SQUARE_THRESHOLD
	jr nz, .updateCounter
	xor a
	ld [wCh1SquareDecCounter], a
	jr .doDec
.updateCounter:
	ld [wCh1SquareDecCounter], a
	ret
.doDec:
	ld hl, pSpriteOAM
	ld de, 4
	ld b, 8
	ld c, 0
.ch1SquareLoop:
	ld a, c
	bit 1, a
	jr nz, .incEntry
	ld a, [hl]
	and a
	jr z, .nextEntry
	dec [hl]
	jr .nextEntry
.incEntry:
	inc [hl]
.nextEntry:
	inc c
	add hl, de
	dec b
	jr nz, .ch1SquareLoop
	ret


Ch12VBlankHandler::
	ld a, [wFillTilemapPending]
	or a
	jr z, .skipFill
	xor a
	ld [wFillTilemapPending], a
	xor a
	ld [rLCDC], a
	ld a, [wCurrentChannel]
	or a
	jr nz, .ch2Fill
	ld a, [wCh1TileIndex]
	jr .doFill
.ch2Fill:
	ld a, [wCh2TileIndex]
.doFill:
	ld e, a
	call FillTilemap
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ8 | LCDCF_BG8000
	ld [rLCDC], a
.skipFill

	ld a, [wCurrentChannel]
	or a
	jr nz, .ch2Scroll

	ld a, [wCh1ScrollCounter]
	inc a
	ld b, a
	ld a, [wCh1ScrollThreshold]
	cp b
	jr nz, .updateCh1Counter
	xor a
	ld [wCh1ScrollCounter], a
	jr .doScroll
.updateCh1Counter:
	ld a, b
	ld [wCh1ScrollCounter], a
	jr .continueVBlank

.ch2Scroll:
	ld a, [wCh2ScrollCounter]
	inc a
	ld b, a
	ld a, [wCh2ScrollThreshold]
	cp b
	jr nz, .updateCh2Counter
	xor a
	ld [wCh2ScrollCounter], a
	jr .doScroll
.updateCh2Counter:
	ld a, b
	ld [wCh2ScrollCounter], a
	jr .continueVBlank

.doScroll:
	ld a, [wScrollX]
	inc a
	ld [wScrollX], a
	ld [rSCX], a

	ld a, [wScrollY]
	inc a
	ld [wScrollY], a
	ld [rSCY], a

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

	call DMATransfer
	reti

Ch3VBlankHandler::
	ld a, [wFillTilemapPending]
	or a
	jr z, .skipFill
	xor a
	ld [wFillTilemapPending], a
	xor a
	ld [rLCDC], a
	ld a, [wCh3TileIndex]
	ld e, a
	call FillTilemap
	; OBJ off for CH3 so Mode 3 stays short and the per-scanline zoom handler
	; has a comfortable HBlank window to write rSCY.
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_BG8000
	ld [rLCDC], a
.skipFill

	; --- horizontal scroll (gated by threshold); zoom owns the Y axis ---
	ld a, [wScrollCounter]
	inc a
	ld b, a
	ld a, [wScrollThreshold]
	cp b
	jr nz, .updateCounter

	xor a, a
	ld [wScrollCounter], a

	ld a, [wScrollX]
	inc a
	ld [wScrollX], a
	ld [rSCX], a

	ld a, [wScrollY]            ; advances the zoom center vertically
	inc a
	ld [wScrollY], a
	jr .zoomSetup

.updateCounter:
	ld a, b
	ld [wScrollCounter], a

.zoomSetup:
	; Advance the pulse phase by a speed derived from CH3's frequency: the top
	; 3 period bits (0-7) map to a step of 1,3,..,15, so higher pitch pulses faster.
	ld a, [wChannel3Freq + 1]
	and %00000111
	add a, a
	inc a
	ld b, a
	ld a, [wZoomPhase]
	add b
	ld [wZoomPhase], a

	; Triangle wave from the phase -> stepLo in -128..126 (8.8 fraction, signed).
	; scale = 1 + step ranges ~0.5..1.5, i.e. zoom in to out.
	bit 7, a
	jr z, .triUp
	cpl                         ; fold 128..255 down to 127..0
.triUp:
	and %01111111               ; 0..127
	sub 64                      ; -64..63
	add a, a                    ; -128..126

	; Sign-extend stepLo into HL = step16, then stash it for the STAT handler.
	ld l, a
	ld h, 0
	bit 7, a
	jr z, .stepPos
	ld h, $FF
.stepPos:
	ld a, l
	ldh [hZoomStepLo], a
	ld a, h
	ldh [hZoomStepHi], a

	; offset = step16 * 64 (anchors the zoom at screen line 64)
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl

	; accStart = (wScrollY << 8) - offset  -> SCY for line 0 is its high byte
	ld a, [wScrollY]
	ld d, a
	xor a
	sub l
	ldh [hZoomAccLo], a
	ld a, d
	sbc h
	ldh [hZoomAccHi], a
	ld [rSCY], a

	call DMATransfer
	reti

; ------------------------------------------------------------------------------
; `func StatZoomHandler()`  (LCD STAT / HBlank interrupt, CH3 only)
;
; Runs once per visible scanline. Adds the signed 8.8 `step` to the accumulator
; and writes the new integer part to rSCY, so each scanline samples a slightly
; different background row. step<0 repeats rows (zoom in); step>0 skips rows
; (zoom out). Only ever interrupts the idle main loop, but preserves AF/BC anyway.
; ------------------------------------------------------------------------------
StatZoomHandler::
	push af
	push bc
	ldh a, [hZoomStepLo]
	ld b, a
	ldh a, [hZoomAccLo]
	add b
	ldh [hZoomAccLo], a
	ldh a, [hZoomStepHi]
	ld b, a
	ldh a, [hZoomAccHi]
	adc b
	ldh [hZoomAccHi], a
	ldh [rSCY], a
	pop bc
	pop af
	reti

Ch4VBlankHandler::
	ld a, [wFillTilemapPending]
	or a
	jr z, .skipFill
	xor a
	ld [wFillTilemapPending], a
	xor a
	ld [rLCDC], a
	ld a, [wCh4TileIndex]
	ld e, a
	call FillTilemap
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ16 | LCDCF_BG8000
	ld [rLCDC], a
.skipFill

	; --- horizontal scroll (gated by threshold); vertical locked to top ---
	ld a, [wScrollCounter]
	inc a
	ld b, a
	ld a, [wScrollThreshold]
	cp b
	jr nz, .updateCounter

	xor a
	ld [wScrollCounter], a
	ld a, [wScrollX]
	inc a
	ld [wScrollX], a
	ld [rSCX], a
	jr .lockY

.updateCounter:
	ld a, b
	ld [wScrollCounter], a

.lockY:
	xor a
	ld [rSCY], a            ; keep the view flat (clears leftover SCY from CH3 zoom)
	call DMATransfer
	reti

; ------------------------------------------------------------------------------
; `func UpdateScrollThreshold()`
;
; Recomputes wScrollThreshold from the current channel's 11-bit frequency.
; Clamps the top 3 period bits to 0-5, then threshold = 6 - bits (range 1-6).
; Call this whenever the channel frequency changes.
; ------------------------------------------------------------------------------
UpdateScrollThreshold::
	push hl
	push bc
	ld a, [wCurrentChannel]
	cp 3                        ; channel 4 has no 11-bit freq var
	jr z, .ch4Default
	call GetChannelFreqVar      ; HL = &wChannelXFreq low byte
	inc hl                      ; HL = high byte of 11-bit frequency
	ld a, [hl]
	and %00000111               ; top 3 period bits (0-7)
	jr .compute
.ch4Default:
	; CH4 has no 11-bit period; derive its pitch from the NR43 clock shift
	; (bits 7-4). Higher shift = lower pitch, so invert it onto the same 0-5
	; "bits" scale the others use (higher bits = higher pitch = faster scroll).
	ld a, [rNR43]
	swap a
	and %00001111               ; clock shift (0-11)
	cp 6                         ; clamp to 0-5
	jr c, .ch4Clamped
	ld a, 5
.ch4Clamped:
	ld b, a
	ld a, 5
	sub b                       ; bits = 5 - clockShift (low shift -> high bits)
.compute:
	cp 6                        ; clamp to 0-5
	jr c, .inRange
	ld a, 5
.inRange:
	ld b, a
	ld a, 6
	sub b                       ; threshold = 6 - bits (range 1-6)
	ld b, a
	ld a, [wCurrentChannel]
	cp 0
	jr nz, .notCh1
	ld a, b
	ld [wCh1ScrollThreshold], a
	xor a
	ld [wCh1ScrollCounter], a
	jr .doneThreshold
.notCh1:
	cp 1
	jr nz, .notCh2
	ld a, b
	ld [wCh2ScrollThreshold], a
	xor a
	ld [wCh2ScrollCounter], a
	jr .doneThreshold
.notCh2:
	ld a, b
	ld [wScrollThreshold], a
	xor a
	ld [wScrollCounter], a
.doneThreshold:
	pop bc
	pop hl
	ret

; ------------------------------------------------------------------------------
; `func UpdateChannelTile()`
;
; Sets the current channel's display tile from its volume. Tiles are interlaced:
; each channel has 5 levels stepping by 4 from a base equal to the channel index
; (CH1->0,4,8,12,16; CH2->1,5,..; CH3->2,6,..; CH4->3,7,..). Louder = higher tile.
; ------------------------------------------------------------------------------
UpdateChannelTile::
	push hl
	push bc
	push de
	ld a, [wCurrentChannel]
	cp 2
	jr z, .ch3

	; CH1/CH2/CH4: volume is the high nibble of NRx2/NR42 (0-15)
	call GetChannelVolumeReg    ; DE -> NRx2
	ld a, [de]
	swap a
	and %00001111
	; level = (volume * 5) >> 4  -> 0-4 spread evenly across 0-15
	ld b, a
	add a, a
	add a, a
	add b                       ; A = volume * 5
	swap a
	and %00001111               ; A = level (0-4)
	jr .store

.ch3:
	; CH3 volume is NR32 bits 6-5: 00=mute, 01=100%, 10=50%, 11=25%
	ld a, [rNR32]
	and %01100000
	swap a
	rrca
	and %00000011               ; raw field 0-3
	cp 1
	jr nz, .ch3NotFull
	ld a, 4                     ; 01 (100%, loudest) -> level 4
	jr .store
.ch3NotFull:
	cp 3
	jr nz, .store               ; 00->0 and 10->2 already match loudness
	ld a, 1                     ; 11 (25%) -> level 1

.store:
	; tile = channel + level*4
	add a, a
	add a, a                    ; A = level * 4
	ld b, a
	ld a, [wCurrentChannel]
	ld c, a                     ; C = channel (also the base + table offset)
	add b                       ; A = tile index
	ld hl, wCh1TileIndex
	ld b, 0
	add hl, bc                  ; HL = &wCh(channel+1)TileIndex
	ld [hl], a
	ld a, 1
	ld [wFillTilemapPending], a ; repaint with the new tile next VBlank
.done:
	pop de
	pop bc
	pop hl
	ret



; ------------------------------------------------------------------------------
; `func FillTilemap()`
;
; Fills the entire 32x32 BG tilemap ($9800-$9BFF) with the tile index
; stored in wTileIndex.
; ------------------------------------------------------------------------------
FillTilemap::
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
; `func DMATransfer()`
;
; Copies the 160-byte shadow OAM buffer (pSpriteOAM, WRAM) to real OAM
; ($FE00-$FE9F) via OAM DMA. The DMA unit locks the CPU out of ROM/WRAM while
; it runs, so this code only works from HRAM: Setup copies it byte-for-byte
; into the fixed HRAM slot at DMATransfer ($FF80) once at boot, and every
; VBlank handler calls it from there.
; ------------------------------------------------------------------------------
DMATransferSrc::
	ld a, HIGH(pSpriteOAM)
	ldh [rDMA], a
	ld a, 40
.wait
	dec a
	jr nz, .wait
	ret
DMATransferSrcEnd::

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
    db $00,$00,$00,$00,$00,$00,$10,$10,$00,$00,$00,$00,$00,$00,$00,$00
    db $01,$00,$02,$05,$04,$00,$08,$14,$10,$00,$20,$50,$40,$00,$80,$40
    db $FF,$00,$FF,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$FF,$00,$FF,$00
    db $81,$81,$42,$42,$24,$24,$18,$18,$18,$18,$24,$24,$42,$42,$81,$81
    db $00,$00,$00,$00,$24,$24,$00,$00,$00,$00,$24,$24,$00,$00,$00,$00
    db $03,$02,$02,$05,$0E,$0A,$08,$14,$38,$28,$20,$50,$E0,$A0,$80,$40
    db $FF,$00,$FF,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$FF,$00,$FF,$00
    db $99,$99,$42,$42,$24,$24,$99,$99,$99,$99,$24,$24,$42,$42,$99,$99
    db $10,$10,$42,$42,$00,$00,$10,$10,$80,$80,$02,$02,$20,$20,$04,$04
    db $C7,$82,$8A,$05,$1F,$0A,$2A,$14,$7C,$28,$A8,$50,$F1,$A0,$A2,$41
    db $00,$00,$FF,$00,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$00
    db $F9,$99,$43,$42,$25,$24,$99,$99,$99,$99,$A4,$24,$C2,$42,$9F,$99
    db $92,$92,$55,$55,$E2,$E2,$5D,$5D,$32,$32,$59,$59,$AA,$AA,$67,$67
    db $C7,$92,$CA,$65,$3F,$6A,$2A,$94,$7C,$29,$AC,$56,$F3,$A6,$A2,$49
    db $FF,$00,$FF,$FF,$00,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$FF,$00
    db $F9,$9F,$43,$FE,$25,$FE,$99,$FF,$99,$FF,$A4,$7F,$C2,$7F,$9F,$F9
    db $3F,$3F,$60,$60,$C0,$C0,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
    db $FC,$FC,$06,$06,$03,$03,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
    db $80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$C0,$C0,$60,$60,$3F,$3F
    db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$03,$03,$06,$06,$FC,$FC
    db $7E,$7E,$7E,$7E,$7E,$7E,$7E,$7E,$7E,$7E,$7E,$7E,$7E,$7E,$7E,$7E
    db $3C,$3C,$3C,$3C,$3C,$3C,$3C,$3C,$3C,$3C,$3C,$3C,$3C,$3C,$3C,$3C
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF