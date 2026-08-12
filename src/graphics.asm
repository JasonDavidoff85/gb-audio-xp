INCLUDE "hardware.inc"
INCLUDE "definitions.inc"

SECTION "Graphics", ROM0

SetupCh1Sprites::
	ld hl, pSpriteOAM
	ld c, 56
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
	add a, 16
	ld c, a
	dec b
	jr nz, .ch1SquareLoop
	ret

SetupCh2Sprites::
	ld hl, pSpriteOAM + 32
	ld b, 3 ; loop for 3 rows of 8x16 sprites
.ch2BoxRowLoop:
	ld c, 64 ; box x position
	ld d, 6
.ch2BoxColLoop:
	xor a
	ld [hli], a
	ld a, c
	ld [hli], a
	xor a
	ld [hli], a          ; tile index is set later via UpdateCh2Box's WRAM variables
	xor a
	ld [hli], a
	ld a, c
	add a, 8
	ld c, a
	dec d
	jr nz, .ch2BoxColLoop
	dec b
	jr nz, .ch2BoxRowLoop
	ret

; ------------------------------------------------------------------------------
; Row-major table of the tile index for each of the 18 box cells (3 rows x 6
; columns). Row 1 columns 3-4 and row 3 columns 3-4 share a tile. UpdateCh2Box
; walks this table in lockstep with the OAM loop below.
; ------------------------------------------------------------------------------
Ch2BoxTileTable::
	db CH2_R1C1_TILE, CH2_R1C2_TILE, CH2_R1C3C4_TILE, CH2_R1C3C4_TILE, CH2_R1C5_TILE, CH2_R1C6_TILE
	db CH2_R2C1_TILE, CH2_R2C2_TILE, CH2_R2C3_TILE, CH2_R2C4_TILE, CH2_R2C5_TILE, CH2_R2C6_TILE
	db CH2_R3C1_TILE, CH2_R3C2_TILE, CH2_R3C3C4_TILE, CH2_R3C3C4_TILE, CH2_R3C5_TILE, CH2_R3C6_TILE

UpdateCh2Box::
	ld a, [wCurrentChannel]
	cp 1
	jp nz, .hideBox
	ld a, [bJoypadDown]
	and a, BUTTON_A
	jp z, .hideBox

	ld hl, pSpriteOAM + 32
	ld de, Ch2BoxTileTable
	ld a, 60
	ld b, 3
.rowLoop:
	ld c, 6
.colLoop:
	ld [hl], a              ; Y
	inc hl
	inc hl                  ; skip X, now at tile byte
	push af

	ld a, [rNR51]
	cp %11111101             ; CH2 panned left only (SO1/right bit cleared)
	jr z, .checkLeftHalf
	cp %11011111             ; CH2 panned right only (SO2/left bit cleared)
	jr z, .checkRightHalf
	jr .overrideTile         ; centered -> every cell is the pan tile

.checkLeftHalf:
	ld a, c
	cp 4
	jr c, .useDefaultTile    ; c=3,2,1 -> columns 4-6, not the active half
	jr .overrideTile         ; c=6,5,4 -> columns 1-3, the active half

.checkRightHalf:
	ld a, c
	cp 4
	jr c, .overrideTile      ; c=3,2,1 -> columns 4-6, the active half
.useDefaultTile:
	ld a, [de]
	inc de
	jr .gotTile
.overrideTile:
	ld a, CH2_BOX_PAN_TILE
	inc de                   ; keep the table pointer advancing in lockstep
.gotTile:
	ld [hl], a               ; write tile value into OAM

	pop af
	inc hl
	inc hl                  ; skip attr, now at next entry's Y byte
	dec c
	jr nz, .colLoop
	add a, 16
	dec b
	jr nz, .rowLoop
	ret

.hideBox:
	xor a
	ld hl, pSpriteOAM + 32
	ld de, 4
	ld b, 18
.hideLoop:
	ld [hl], a
	add hl, de
	dec b
	jr nz, .hideLoop
	ret

SetupCh3Sprites::
	ld hl, pSpriteOAM + 104
	ld c, 8
	ld b, 4
.ch3CircleLoop:
	xor a
	ld [hli], a
	ld a, c
	ld [hli], a
	ld a, 20
	ld [hli], a
	xor a
	ld [hli], a
	xor a
	ld [hli], a
	ld a, c
	add a, 8
	ld [hli], a
	ld a, 22
	ld [hli], a
	xor a
	ld [hli], a
	ld a, c
	add a, 40
	ld c, a
	dec b
	jr nz, .ch3CircleLoop
	ret

ShowCircles::
	ld hl, pSpriteOAM + 104
	ld b, 4
.circleLoop:
	call Rand8
	and %01111111
	add 16
	ld c, a
	call Rand8
	and %01111111
	add 8
	ld d, a

	ld a, c
	ld [hli], a
	ld a, d
	ld [hli], a
	inc hl
	inc hl
	ld a, c
	ld [hli], a
	ld a, d
	add 8
	ld [hli], a
	inc hl
	inc hl

	dec b
	jr nz, .circleLoop
	ret

UpdateCh3Circles::
	ld a, [wCurrentChannel]
	cp 2
	jr nz, .hideCircles
	ld a, [bJoypadDown]
	and a, BUTTON_A
	jr z, .hideCircles
	call ShowCircles
	ret

.hideCircles:
	xor a
	ld hl, pSpriteOAM + 104
	ld de, 4
	ld b, 8
.hideLoop:
	ld [hl], a
	add hl, de
	dec b
	jr nz, .hideLoop
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
	ld a, [hl]
	and a
	jr z, .nextEntry
	dec [hl]
.nextEntry:
	inc c
	add hl, de
	dec b
	jr nz, .ch1SquareLoop
	ret

DecCh1Squares::
	ld a, [rNR12]
	and %00000111
	cp 0
	ret nz
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
	ld a, [hl]
	cp 160
	jr nc, .nextEntry
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
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ16 | LCDCF_BG8000
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
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ16 | LCDCF_BG8000
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

	; --- scroll direction cycles right/down/left/up (gated by threshold) ---
	ld a, [wScrollCounter]
	inc a
	ld b, a
	ld a, [wScrollThreshold]
	cp b
	jr nz, .updateCounter

	xor a
	ld [wScrollCounter], a
	ld a, [wScrollDirection]
	cp 0
	jr z, .moveRight
	cp 1
	jr z, .moveDown
	cp 2
	jr z, .moveLeft
	ld a, [wScrollY]
	dec a
	ld [wScrollY], a
	jr .writeScroll
.moveRight:
	ld a, [wScrollX]
	inc a
	ld [wScrollX], a
	jr .writeScroll
.moveDown:
	ld a, [wScrollY]
	inc a
	ld [wScrollY], a
	jr .writeScroll
.moveLeft:
	ld a, [wScrollX]
	dec a
	ld [wScrollX], a
	jr .writeScroll

.updateCounter:
	ld a, b
	ld [wScrollCounter], a

.writeScroll:
	ld a, [wScrollX]
	ld [rSCX], a
	ld a, [wScrollY]
	ld [rSCY], a
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
    db $83,$82,$02,$05,$0E,$0A,$08,$14,$38,$28,$20,$50,$E0,$A0,$81,$40
    db $FF,$00,$FF,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$FF,$00,$FF,$00
    db $99,$99,$42,$42,$24,$24,$99,$99,$99,$99,$24,$24,$42,$42,$99,$99
    db $10,$10,$42,$42,$00,$00,$10,$10,$80,$80,$02,$02,$20,$20,$04,$04
    db $C7,$82,$8A,$05,$1F,$0A,$2A,$14,$7C,$28,$A8,$50,$F1,$A0,$A2,$41
    db $00,$00,$FF,$00,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$00
    db $F9,$99,$43,$42,$25,$24,$99,$99,$99,$99,$A4,$24,$C2,$42,$9F,$99
    db $8A,$8A,$55,$55,$AA,$AA,$45,$45,$2A,$2A,$51,$51,$AA,$AA,$45,$45
    db $E7,$A2,$CA,$45,$9F,$8A,$2A,$14,$7C,$28,$A9,$51,$F3,$A2,$A6,$45
    db $FF,$00,$FF,$FF,$00,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$FF,$00
    db $F9,$9F,$43,$FE,$25,$FE,$99,$FF,$99,$FF,$A4,$7F,$C2,$7F,$9F,$F9
    db $D6,$12,$5D,$5D,$EA,$E2,$5F,$5D,$F2,$B2,$5B,$59,$AA,$AA,$77,$67
    db $3F,$3F,$60,$60,$C0,$C0,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
    db $80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$C0,$C0,$60,$60,$3F,$3F
    db $FC,$FC,$06,$06,$03,$03,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
    db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$03,$03,$06,$06,$FC,$FC
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $00,$00,$00,$00,$3F,$3F,$20,$20,$20,$20,$20,$20,$20,$20,$21,$21
    db $21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21
    db $21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21
    db $21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21
    db $21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21
    db $21,$21,$20,$20,$20,$20,$20,$20,$20,$20,$3F,$3F,$00,$00,$00,$00
    db $00,$00,$00,$00,$FC,$FC,$04,$04,$04,$04,$04,$04,$04,$04,$84,$84
    db $84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84
    db $84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84
    db $84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84
    db $84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84
    db $84,$84,$04,$04,$04,$04,$04,$04,$04,$04,$FC,$FC,$00,$00,$00,$00
    db $00,$00,$00,$00,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF
    db $00,$00,$00,$00,$00,$00,$1F,$1F,$10,$10,$10,$10,$10,$10,$11,$11
    db $11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
    db $11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
    db $11,$11,$10,$10,$10,$10,$10,$10,$1F,$1F,$00,$00,$00,$00,$00,$00
    db $FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$00,$00,$00,$00
    db $00,$00,$00,$00,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF
    db $00,$00,$00,$00,$00,$00,$FF,$FF,$00,$00,$00,$00,$00,$00,$FF,$FF
    db $00,$00,$00,$00,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF
    db $00,$00,$00,$00,$00,$00,$F8,$F8,$08,$08,$08,$08,$08,$08,$88,$88
    db $88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88
    db $88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88,$88
    db $88,$88,$08,$08,$08,$08,$08,$08,$F8,$F8,$00,$00,$00,$00,$00,$00
    db $FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$00,$00,$00,$00
    db $FF,$FF,$00,$00,$00,$00,$00,$00,$FF,$FF,$00,$00,$00,$00,$00,$00
    db $FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$00,$00,$00,$00
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00