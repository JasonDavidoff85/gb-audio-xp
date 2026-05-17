INCLUDE "definitions.inc"
INCLUDE "hardware.inc"

SECTION "INPUT", ROMX

; Handle all input for audio controls
; Called during timer interrupt when BPM counter triggers
HandleInput::
	; check input
	call ReadJoypad
	ld a, [bJoypadDown]
	and a, BUTTON_UP
	jr z, .checkDown

	; Check if current channel is channel 3
	ld a, [wCurrentChannel]
	cp 2
	jr nz, .normalIncVol
	call IncChannel3Vol
	jr .checkDown
.normalIncVol
	call IncChannelVol
.checkDown
	ld a, [bJoypadDown]
	and a, BUTTON_DOWN
	jr z, .checkRight

	; Check if current channel is channel 3
	ld a, [wCurrentChannel]
	cp 2
	jr nz, .normalDecVol
	call DecChannel3Vol
	jr .checkRight
.normalDecVol
	call DecChannelVol

.checkRight
	ld a, [bJoypadDown]
	and a, BUTTON_RIGHT
	jr z, .checkLeft

	; Check if current channel is channel 4
	ld a, [wCurrentChannel]
	cp 3
	jr nz, .normalIncFreq
	call IncChannel4Freq
	jr .checkLeft
.normalIncFreq
	call IncChannelFreq11Bit

.checkLeft
	ld a, [bJoypadDown]
	and a, BUTTON_LEFT
	jr z, .checkSelect

	; Check if current channel is channel 4`
	ld a, [wCurrentChannel]
	cp 3
	jr nz, .normalDecFreq
	call DecChannel4Freq
	jr .checkSelect
.normalDecFreq
	call DecChannelFreq11Bit

.checkSelect
	ld a, [bJoypadDown]
	and a, BUTTON_SELECT
	jr z, .checkB

	ld a, [wCurrentChannel]
	inc a
	cp 4                    ; wrap after channel 3
	jr nz, .setChannel
	ld a, 0
.setChannel:
	ld [wCurrentChannel], a
	ld a, 1
	ld [wFillTilemapPending], a

.checkB
	ld a, [bJoypadDown]
	and a, BUTTON_B
	jr z, .checkA

	ld a, [rBGP] ; change palette for visual feedback
	rlca
	rlca
	ld [rBGP], a

	call CycleWaveDuty

.checkA
	ld a, [bJoypadDown]
	and a, BUTTON_A
	jr z, .endCheck

	call TriggerSweep

.endCheck
	ret

