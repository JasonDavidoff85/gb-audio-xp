INCLUDE "hardware.inc"
INCLUDE "definitions.inc"

SECTION "Timer Interrupt", ROM0[$0050]
TimerInterrupt:
	push af
	push bc
	push hl
	jp TimerHandler

SECTION "VBlank Interrupt", ROM0[$0040]
VBlankInterupt:
	jp VBlankHandler

SECTION "STAT Interrupt", ROM0[$0048]
StatInterrupt:
	jp StatZoomHandler


SECTION "BPM Counter", HRAM
hBPMCounter::
	ds 2

; Raster-zoom state for channel 3. Lives in HRAM so the per-scanline STAT
; handler can use fast `ldh` access. The accumulator is 8.8 fixed point; its
; high byte is written to rSCY each HBlank, and `step` (also 8.8, signed) is the
; per-scanline increment that stretches/squashes the background vertically.
SECTION "Zoom State", HRAM
hZoomAccLo::    ds 1
hZoomAccHi::    ds 1
hZoomStepLo::   ds 1
hZoomStepHi::   ds 1

; OAM DMA must run from HRAM (ROM/WRAM are inaccessible while the transfer is
; active). Setup copies DMATransferSrc here; the linker allocates this so it
; never overlaps the other HRAM variables above.
SECTION "OAM DMA Routine", HRAM
DMATransfer::   ds 16

SECTION "Variables", WRAM0[$C022]
wVol:					ds 1
wChannelVolumes:    	ds 4    ; Current volume for each channel
wCurrentChannel::   	ds 1    ; Currently active/selected channel (0-3)
wChannel1Freq::     	ds 2    ; Channel 1 frequency (11 bits, stored in 2 bytes)
wChannel2Freq::     	ds 2    ; Channel 2 frequency (11 bits, stored in 2 bytes)
wChannel3Freq::     	ds 2    ; Channel 3 frequency (11 bits, stored in 2 bytes)
wSweepPace::		 	ds 1    ; Sweep pace for channel 1, set randomly
wScrollX::          	ds 1    ; Horizontal scroll position
wScrollY::          	ds 1    ; Vertical scroll position
wScrollCounter::    	ds 1    ; Scroll counter for ch3/ch4
wScrollThreshold::  	ds 1    ; Scroll frames-per-step for ch3/ch4
wTileIndex::        	ds 1    ; Tile index used by SetChNTilemap routines
wCh1TileIndex::     	ds 1    ; Tile index for channel 1 display
wCh2TileIndex::     	ds 1    ; Tile index for channel 2 display
wCh3TileIndex:: 		ds 1	; Tile index for channel 3 display
wCh4TileIndex:: 		ds 1	; Tile index for channel 4 display
wCh1ScrollThreshold:: 	ds 1  ; Scroll frames-per-step for channel 1
wCh2ScrollThreshold:: 	ds 1  ; Scroll frames-per-step for channel 2
wCh1ScrollCounter:: 	ds 1    ; Scroll counter for channel 1
wCh2ScrollCounter:: 	ds 1    ; Scroll counter for channel 2
wZoomPhase::        	ds 1    ; CH3 zoom pulse phase (advances each frame)
wVBlankFunc::       	ds 2    ; Pointer to routine called each VBlank
wFillTilemapPending::	ds 1  ; Non-zero triggers a full tilemap fill next VBlank
wRandomSeed::       	ds 1    ; State byte for the Rand8 pseudo-random generator
wCh1SquareCounter::		ds 1    ; Calls to IncCh1Squares since the last actual move
wCh1SquareDecCounter::	ds 1    ; Calls to DecCh1Squares since the last actual move
wScrollDirection::		ds 1    ; CH4 scroll direction, cycles 0=right,1=down,2=left,3=up

SECTION "Header", ROM0[$100]

	jp Main

	; Make sure to allocate some space for the header, so no important
	; code gets put there and later overwritten by RGBFIX.
	; RGBFIX is designed to operate over a zero-filled header, so make
	; sure to put zeros regardless of the padding value. (This feature
	; was introduced in RGBDS 0.4.0, but the -MG etc flags were also
	; introduced in that version.)
	ds $150 - @, 0

SECTION "Timer Handler", ROM0
TimerHandler:
	ld hl, hBPMCounter

	ld a, [hli]
	ld b, a
	ld a, [hld]
	ld c, a

	inc bc

	bit 4, b

	; if at bpm play note and change pallet
	jr z, .skipReset

	; handle all input
	push hl
	call HandleInput
	pop hl

	; reset counter if at bpm
	ld bc, 0
.skipReset

	ld [hl], b
	inc hl
	ld [hl], c

	pop hl
	pop bc
	pop af
	; This instruction is equivalent to `ret` and `ei`
	reti

SECTION "VBlank Handler", ROM0
VBlankHandler:
	ld a, [wVBlankFunc]
	ld l, a
	ld a, [wVBlankFunc + 1]
	ld h, a
	jp hl

SECTION "Main", ROM0
Main:
	call Setup

	ld a, %00100000
	ld [rP1], a

	call PlayCH1
	; call PlayCH2
	; call PlayCH3
	; call PlayCH4

Loop:
	jr Loop


; Get channel volume register address
; Output: DE = register address for current channel
GetChannelVolumeReg::
	push bc
	push hl
	ld a, [wCurrentChannel] ; get current channel (0-3)
	ld hl, ChannelVolumeRegs
	ld b, 0
	ld c, a
	sla c                   ; multiply by 2 (each entry is 2 bytes)
	add hl, bc              ; hl points to correct entry
	ld a, [hli]             ; load low byte
	ld e, a
	ld a, [hl]              ; load high byte
	ld d, a                 ; de now contains the register address
	pop hl
	pop bc
	ret

; Get channel frequency variable address
; Output: HL = address of current channel's frequency variable
GetChannelFreqVar::
	ld a, [wCurrentChannel] ; get current channel (0-3)
	ld hl, wChannel1Freq
	sla a                   ; multiply by 2 (each freq is 2 bytes)
	add l
	ld l, a
	jr nc, .done
	inc h
.done
	ret

; Get channel trigger register address
; Output: DE = register address for current channel
GetChannelTriggerReg::
	push bc
	push hl
	ld a, [wCurrentChannel] ; get current channel (0-3)
	ld hl, ChannelTriggerRegs
	ld b, 0
	ld c, a
	sla c                   ; multiply by 2 (each entry is 2 bytes)
	add hl, bc              ; hl points to correct entry
	ld a, [hli]             ; load low byte
	ld e, a
	ld a, [hl]              ; load high byte
	ld d, a                 ; de now contains the register address
	pop hl
	pop bc
	ret

; Get channel period low register address
; Output: DE = register address for current channel
GetChannelPeriodLowReg::
	push bc
	push hl
	ld a, [wCurrentChannel] ; get current channel (0-3)
	ld hl, ChannelPeriodLowRegs
	ld b, 0
	ld c, a
	sla c                   ; multiply by 2 (each entry is 2 bytes)
	add hl, bc              ; hl points to correct entry
	ld a, [hli]             ; load low byte
	ld e, a
	ld a, [hl]              ; load high byte
	ld d, a                 ; de now contains the register address
	pop hl
	pop bc
	ret


Setup:
	; turn off display
	xor a, a
	ld [rLCDC], a

	ldh [hBPMCounter], a
	ldh [hBPMCounter + 1], a

	call ClearWRAM

	; Initialize scroll position
	xor a, a
	ld [wScrollX], a
	ld [wScrollY], a
	ld [wScrollCounter], a

	; Initialize channel variables
	xor a, a
	ld [wCurrentChannel], a  ; start with channel 0
	ld [wCh1TileIndex], a    ; ch1 = tile 0
	ld a, 1
	ld [wCh2TileIndex], a    ; ch2 = tile 1
	ld a, 2
	ld [wCh3TileIndex], a    ; ch3 = tile 2
	ld a, 3
	ld [wCh4TileIndex], a    ; ch4 = tile 3

	; Initialize CH3 raster-zoom state (STAT interrupt stays off until CH3)
	xor a, a
	ld [wZoomPhase], a
	ldh [hZoomStepLo], a
	ldh [hZoomStepHi], a
	ldh [hZoomAccLo], a
	ldh [hZoomAccHi], a

	; Seed the LFSR with a non-zero value (0 is a dead state for the Galois generator).
	ld a, $01
	ld [wRandomSeed], a

	; Master audio on.
	ld a, $80
	ld [rNR52], a 

	; Left and right channel max vol.
	ld a, $77
	ld [rNR50], a

	; Enable all channels on each pan.
	ld a, $FF
	ld [rNR51], a

	; Timer clock speed
	ld a, $FF
	ld [rTMA], a

	; Set Timer Control to max
	ld a, $07
	ld [rTAC], a

	; Interupt timer and vblank enable
	ld a, IEF_TIMER | IEF_VBLANK 
	ldh [rIE], a

	; Clear iterupt flags
	xor a, a ; This is equivalent to `ld a, 0`!
	ldh [rIF], a

	; set b to 0 to use as bpm counter
	;ld bc, $0000

	call LoadSingleTileBackground

	; Install the OAM DMA routine into HRAM; it must execute from there since
	; ROM/WRAM are inaccessible to the CPU while the DMA transfer is active.
	ld bc, DMATransferSrcEnd - DMATransferSrc
	ld de, DMATransferSrc
	ld hl, DMATransfer
	call LoadData

	call SetupCh1
	call SetupCh2
	call SetupCh3
	call SetupCh4
	call SetupCh1Sprites
	call SetupCh2Sprites
	call SetupCh3Sprites
	call UpdateScrollThreshold
	call UpdateChannelTile        ; set the starting channel's tile from its volume


	; Initialize the background palettes
	ld a, %11100100
	ld [rBGP], a

	; Initialize VBlank function pointer
	ld hl, Ch12VBlankHandler
	ld a, l
	ld [wVBlankFunc], a
	ld a, h
	ld [wVBlankFunc + 1], a

	; turn on display
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ16 | LCDCF_BG8000
  	ld [rLCDC], a

	reti

ClearWRAM:
	ld bc, $2000
	ld hl, $C000
  .clear_loop
	xor a, a
	ld [hli], a
	dec bc
	ld a, b
	or a, c
	jr nz, .clear_loop
	ret

; ------------------------------------------------------------------------------
; `func LoadSingleTileBackground()`
;
; Copies the first 16 bytes (one tile) of test1.bin into tile 0 of VRAM tile
; data, then fills the entire 32x32 background tilemap with index 0 so every
; background tile renders as that single tile.
; ------------------------------------------------------------------------------
LoadSingleTileBackground:
	ld bc, len_Tileset
	ld de, Tileset
	ld hl, $8000
	call LoadData

	ld bc, $1800 - len_Tileset
.clear_tiles
	xor a, a
	ld [hli], a
	dec bc
	ld a, b
	or a, c
	jr nz, .clear_tiles

	ld bc, $0400
	ld hl, $9800
.fill_loop
	xor a, a
	ld [hli], a
	dec bc
	ld a, b
	or a, c
	jr nz, .fill_loop
	ret

; ------------------------------------------------------------------------------
; `func SetCh1Tilemap()`
;
; Fills the top-left 16x16 quadrant of the BG tilemap ($9800) with the
; tile index stored in wTileIndex.
; ------------------------------------------------------------------------------
SetCh1Tilemap:
    ret

; ------------------------------------------------------------------------------
; `func SetCh2Tilemap()`
;
; Fills the top-right 16x16 quadrant of the BG tilemap ($9800) with the
; tile index stored in wTileIndex.
; ------------------------------------------------------------------------------
SetCh2Tilemap:
    ret

; ------------------------------------------------------------------------------
; `func SetCh3Tilemap()`
;
; Fills the bottom-left 16x16 quadrant of the BG tilemap ($9800) with the
; tile index stored in wTileIndex.
; ------------------------------------------------------------------------------
SetCh3Tilemap:
    ret

; ------------------------------------------------------------------------------
; `func SetCh4Tilemap()`
;
; Fills the bottom-right 16x16 quadrant of the BG tilemap ($9800) with the
; tile index stored in wTileIndex.
; ------------------------------------------------------------------------------
SetCh4Tilemap:
    ret

; ------------------------------------------------------------------------------
; `func LoadData(bc, de, hl)`
;
; This function loads data directly from the ROM into RAM using three 16-bit
; registers:
;
; - `bc` - The number of bytes to load
; - `de` - The start address for retrieving the bytes from the ROM
; - `hl` - The start address for storing the bytes in RAM
; ------------------------------------------------------------------------------
LoadData:
	ld a, [de]
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or a, c
	jp nz, LoadData
	ret

SECTION "Game Data", ROM0

; Channel volume register addresses
ChannelVolumeRegs:
    dw rNR12    ; Channel 1
    dw rNR22    ; Channel 2
	dw rNR32    ; Channel 3 (special case)
    dw rNR42    ; Channel 4 (Channel 3 uses different volume control)

; Channel period low register addresses
ChannelPeriodLowRegs:
    dw rNR13    ; Channel 1
    dw rNR23    ; Channel 2
	dw rNR33    ; Channel 3 (special case)
    dw rNR43    ; Channel 4 

; Channel trigger register addresses
ChannelTriggerRegs:
    dw rNR14    ; Channel 1
    dw rNR24    ; Channel 2
	dw rNR34    ; Channel 3 (special case)
    dw rNR44    ; Channel 4

