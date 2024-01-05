INCLUDE "hardware.inc"

; ------------------------------------------------------------------------------
; `macro WaitForVblank()`
;
; Loops until the LCD enters the vertical blanking period.
; ------------------------------------------------------------------------------
MACRO WaitForVblank
: ld a, [rLY]
  cp a, 144
  jr c, :-
ENDM

; ------------------------------------------------------------------------------
; `macro WaitForVblankEnd()`
;
; Loops until the LCD exits the vertical blanking period.
; ------------------------------------------------------------------------------
MACRO WaitForVblankEnd
: ld a, [rLY]
  cp 144
  jr nc, :-
ENDM

SECTION "Timer Interrupt", ROM0[$0050]
TimerInterrupt:
	; push af
	; push bc
	; push de
	; push hl
	jp TimerHandler
	

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
	inc bc

	; check if 2048
	bit 3, b

	; skip reset if not 2048
	jr z, .skipReset

	call PlayNote
	
	; reset b if equal
	ld b, $0000

.skipReset
	; pop hl
	; pop de
	; pop bc
	; pop af

	; This instruction is equivalent to `ret` and `ei`
	reti

SECTION "Main", ROM0

Main:
	; call ClearWRAM
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ16
  	ld [rLCDC], a

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

	; Interupt enable
	ld a, IEF_TIMER
	ld [rIE], a

	; Clear iterupt flags
	xor a, a ; This is equivalent to `ld a, 0`!
	ldh [rIF], a

	; set b to 0 to use as bpm counter
	ld bc, $0000

	ei

	call PlayNote

Loop:
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


