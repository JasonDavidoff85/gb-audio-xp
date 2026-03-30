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
	jr z, .checkRightAndSelect

	; Check if current channel is channel 4`
	ld a, [wCurrentChannel]
	cp 3
	jr nz, .normalDecFreq
	call DecChannel4Freq
	jr .checkRightAndSelect
.normalDecFreq
	call DecChannelFreq11Bit

.checkRightAndSelect
	ld a, [bJoypadDown]
	and a, BUTTON_SELECT | BUTTON_RIGHT
	cp BUTTON_SELECT | BUTTON_RIGHT
	jr nz, .checkLeftAndSelect
	
	; Cycle to next channel
	ld a, [wCurrentChannel]
	inc a
	cp 4                    ; check if past last channel
	jr nz, .setChannel
	ld a, 0                 ; wrap around to channel 0
.setChannel:
	ld [wCurrentChannel], a
	ld a, [rBGP] ; change pallet for visual feedback
	cpl
	ld [rBGP], a

.checkLeftAndSelect
	ld a, [bJoypadDown]
	and a, BUTTON_SELECT | BUTTON_LEFT
	cp BUTTON_SELECT | BUTTON_LEFT
	jr nz, .checkB
	
	ld a, [wCurrentChannel]
	dec a
	cp $FF                  ; check for underflow
	jr nz, .setPrevChannel
	ld a, 3                 ; wrap around to channel 3
.setPrevChannel:
	ld [wCurrentChannel], a
	ld a, [rBGP] ; change pallet for visual feedback
	cpl
	ld [rBGP], a

.checkB
	ld a, [bJoypadDown]
	and a, BUTTON_B
	jr z, .endCheck
	
	call CycleWaveDuty

.endCheck
	ret

