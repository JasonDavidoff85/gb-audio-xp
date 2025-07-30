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
wChannelVolumes:    ds 4    ; Current volume for each channel
wCurrentChannel::    ds 1    ; Currently active/selected channel (0-3)

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
	jr z, .checkDown

	call IncChannelVol
.checkDown
	ld a, [bJoypadDown]
	and a, BUTTON_DOWN
	jr z, .checkRight

	call DecChannelVol

.checkRight
	; Check if SELECT + RIGHT is held
	ld a, [bJoypadDown]
	and a, BUTTON_SELECT | BUTTON_RIGHT
	cp BUTTON_SELECT | BUTTON_RIGHT
	jr nz, .checkLeft
	
	; Cycle to next channel
	ld a, [wCurrentChannel]
	inc a
	cp 4                    ; check if past last channel
	jr nz, .setChannel
	ld a, 0                 ; wrap around to channel 0
.setChannel:
	ld [wCurrentChannel], a

.checkLeft
	; Check if SELECT + LEFT is held
	ld a, [bJoypadDown]
	and a, BUTTON_SELECT | BUTTON_LEFT
	cp BUTTON_SELECT | BUTTON_LEFT
	jr nz, .endCheck
	
	; Cycle to previous channel
	ld a, [wCurrentChannel]
	dec a
	cp $FF                  ; check for underflow
	jr nz, .setPrevChannel
	ld a, 3                 ; wrap around to channel 3
.setPrevChannel:
	ld [wCurrentChannel], a
.endCheck

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
	call PlayCH2
	call PlayCH3
	call PlayCH4

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


Setup:
	; turn off display
	xor a, a
	ld [rLCDC], a

	ldh [hBPMCounter], a
	ldh [hBPMCounter + 1], a

	call ClearWRAM

	; Initialize channel variables
	xor a, a
	ld [wCurrentChannel], a  ; start with channel 0
	
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
	ld a, IEF_TIMER | IEF_VBLANK 
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

; Channel volume register addresses
ChannelVolumeRegs:
    dw rNR12    ; Channel 1
    dw rNR22    ; Channel 2
	dw rNR32    ; Channel 3 (special case)
    dw rNR42    ; Channel 4 (Channel 3 uses different volume control)

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

