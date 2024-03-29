INCLUDE "hardware.inc"
INCLUDE "definitions.inc"

SECTION "Timer Interrupt", ROM0[$0050]
TimerInterrupt:
	jp TimerHandler

SECTION "VBlank Interrupt", ROM0[$0040]
VBlankInterupt:
	jp VBlankHandler


SECTION "BPM Counter", HRAM
hBPMCounter:
	ds 1

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
	; load pointer in hl
	ld hl, hBPMCounter
	; set bc to pointer
	ld b, [hl]
	inc [hl]
	ld c, [hl]

	; increment pointer
	inc bc

	
	; check if 4096 (120 bpm)
	bit 3, b

	; skip reset if not desired bpm
	jr z, .skipReset

	call PlayNote

	; set counter back to 0
	xor a, a
	ldh [hBPMCounter], a

	; ; get pallet and invert and reset
	; ld a, [rBGP]
	; cpl
	; ld [rBGP], a

.skipReset

	; This instruction is equivalent to `ret` and `ei`
	reti

SECTION "VBlank Handler", ROM0
VBlankHandler:

	; load counter and increment
	ldh a, [hBPMCounter]
	inc a
	
	; check bit (bpm)
	bit 5, a

	; if at bpm play note and change pallet
	jr z, .skipCpl

	call PlayNote

	; get pallet and invert and reset
	ld a, [rBGP]
	cpl
	ld [rBGP], a

	; prepare to reset counter
	xor a, a

.skipCpl
	; load counter
	ldh [hBPMCounter], a
	
	reti

SECTION "Main", ROM0
Main:
	call Setup

Loop:
	WaitForVblank
	WaitForVblankEnd
	jr Loop


PlayNote:
	; Channel 1 sweep.
	; %00111100
	ld a, $3C
	ld [rNR10], a

	; Set wave duty.
	; %01000010
	ld a, $00
	ld [rNR21], a

	; Set the vol envolope.
	; %01110011
	ld a, $73
	ld [rNR22], a

	; Freq lsb
	; %110_ %11010110
	ld a, $D6
	ld [rNR23], a

	; Freq msb and trigger
	; %10000110
	ld a, $86 ;C3
	ld [rNR24], a

	ret

Setup:
	; turn off display
	xor a, a
	ld [rLCDC], a

	call ClearWRAM

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

	; Set Timer Control to 496Hz
	ld a, $04
	ld [rTAC], a

	; Interupt timer and vblank enable
	ld a, IEF_VBLANK ;IEF_TIMER 
	ldh [rIE], a

	; Clear iterupt flags
	xor a, a ; This is equivalent to `ld a, 0`!
	ldh [rIF], a

	; set b to 0 to use as bpm counter
	;ld bc, $0000

	call LoadLevel

	; Initialize the background palettes
	ld a, %11100100
	ld [rBGP], a

	; turn on display
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ16 | LCDCF_BG8000
  	ld [rLCDC], a

	reti	

ClearWRAM:
	ld bc, $2000
	ld hl, $C000
  .clear_loop
	ld a, 0
	ld [hli], a
	dec bc
	ld a, b
	or a, c
	jr nz, .clear_loop
	ret

; ------------------------------------------------------------------------------
; `func LoadLevel()`
;
; Copies level data from the ROM into RAM and initializes level variables.
; ------------------------------------------------------------------------------
LoadLevel:
	ld bc, len_Tileset
	ld de, Tileset
	ld hl, $8000
	call LoadData
	ld bc, len_LevelTilemap
	ld de, LevelTilemap
	ld hl, $9800
	call LoadData
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

; ------------------------------------------------------------------------------
; `binary data Tileset`
;
; This is the tileset data for the game. Since it is just a demo, I was able to
; fit all the graphics I need into the GameBoy's 6144 byte character RAM region.
; Bigger games will need to swap out graphics during runtime based on what needs
; to be rendered at a given time.
; ------------------------------------------------------------------------------
Tileset:: INCBIN "tiles.bin"

; ------------------------------------------------------------------------------
; `binary data LevelTilemap`
;
; This is the 32 x 32 tile data for the background tiles representing the game's
; level. For this project I kept things simple by using the binary tilemap data
; directly. In more advanced projects one would have much larger runs of data
; representing levels and use an encoding scheme (e.g. run-length encoding) to
; minimize ROM data usage.
; ------------------------------------------------------------------------------
LevelTilemap:: INCBIN "test1.bin"

