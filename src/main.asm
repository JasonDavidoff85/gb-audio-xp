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


SECTION "BPM Counter", HRAM
hBPMCounter:
	ds 2

SECTION "Variables", WRAM0[$C022]
wVol:
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
	ld hl, hBPMCounter

	ld a, [hli]
	ld b, a
	ld a, [hld]
	ld c, a

	inc bc

	bit 4, b

	; if at bpm play note and change pallet
	jr z, .skipReset

	; check input
	call ReadJoypad
	ld a, [bJoypadDown]
	and a, BUTTON_UP
	jr z, .skipNote

	ld a, [rNR10]
	inc a
	ld [rNR10], a
	; call PlayCH2
	; call PlayCH2
.skipNote

	; prepare to reset counter
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

	; load counter and increment
	ldh a, [hBPMCounter + 1]
	
	; check bit (bpm)
	bit 5, a

	; if at bpm play note and change pallet
	jr z, .skipCpl

	; get pallet and invert and reset
	ld a, [rBGP]
	cpl
	ld [rBGP], a

.skipCpl
	
	reti

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


SetupCh1:
	; Channel 1 sweep.
	; %00111100
	ld a, %00000111 ; turn on off as param?
	ld [rNR10], a

	; Set wave duty.
	; %01000010 $80
	ld a, %10000000 ; change wave size as param? or length timer?
	ld [rNR11], a

	; Set the vol envolope.
	; %01110011
	ld a, %11001000
	ld [rNR12], a

	; Freq lsb
	; %110_ %11010110
	ld a, %11010110
	ld [rNR13], a

	ret

SetupCh2:
	; Set wave duty.
	; %01000010
	ld a, %10000000
	ld [rNR21], a

	; Set the vol envolope.
	; %01110011
	ld a, %11000000
	ld [rNR22], a

	; Freq lsb
	; %110_ %11010110
	ld a, %11010110
	ld [rNR23], a

	ret

SetupCh3:
	; turn on dac
	ld a, %10000000
	ld [rNR30], a

	; Set length timer to 0
	ld a, %00000000
	ld [rNR31], a

	; Set the vol to 100%.
	ld a, %00100000
	ld [rNR32], a

	; Freq lsb
	; %110_ %11010110
	ld a, %11010110
	ld [rNR33], a

	ret


SetupCh4:

	; Set length timer to 0
	ld a, %00000000
	ld [rNR41], a

	; Set the vol to 100%.
	ld a, %00100000
	ld [rNR42], a

	; Freq lsb
	; %110_ %11010110
	ld a, %01101001
	ld [rNR43], a

	ret

PlayCH1:
	; Freq msb and trigger
	; %10000110
	ld a, %10000001 ;C3
	ld [rNR14], a

	ret

PlayCH2:
	; Freq msb and trigger
	; %10000110
	ld a, %10000010 ;C3
	ld [rNR24], a

	ret

PlayCH3:
	; Trigger freq msb
	; %110_ %11010110
	ld a, %10000110
	ld [rNR34], a

	ret

PlayCH4:
	; Trigger
	ld a, %10000000
	ld [rNR44], a

	ret

Setup:
	; turn off display
	xor a, a
	ld [rLCDC], a

	ldh [hBPMCounter], a
	ldh [hBPMCounter + 1], a

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
	ld a, IEF_TIMER ;| IEF_VBLANK 
	ldh [rIE], a

	; Clear iterupt flags
	xor a, a ; This is equivalent to `ld a, 0`!
	ldh [rIF], a

	; set b to 0 to use as bpm counter
	;ld bc, $0000

	call LoadLevel

	call SetupCh1
	call SetupCh2
	call SetupCh3
	call SetupCh4


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
	xor a, a
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
Tileset:: INCBIN "bin/tiles.bin"

; ------------------------------------------------------------------------------
; `binary data LevelTilemap`
;
; This is the 32 x 32 tile data for the background tiles representing the game's
; level. For this project I kept things simple by using the binary tilemap data
; directly. In more advanced projects one would have much larger runs of data
; representing levels and use an encoding scheme (e.g. run-length encoding) to
; minimize ROM data usage.
; ------------------------------------------------------------------------------
LevelTilemap:: INCBIN "bin/test1.bin"

