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
	jr z, .checkStart

	; Check if current channel is channel 4`
	ld a, [wCurrentChannel]
	cp 3
	jr nz, .normalDecFreq
	call DecChannel4Freq
	jr .checkStart
.normalDecFreq
	call DecChannelFreq11Bit

.checkStart
	ld a, [bJoypadDown]
	and a, BUTTON_START
	jr z, .checkSelect

	call MuteChannel

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

	ld a, [wCurrentChannel]
	cp 0
	jr nz, .bNot0
	call CycleWaveDuty      ; channel 0 (CH1)
	jr .checkA
.bNot0
	cp 1
	jr nz, .bNot1
	call CycleWaveDuty      ; channel 1 (CH2)
	jr .checkA
.bNot1
	cp 2
	jr nz, .bNot2
	call WriteRandomWaveByte ; channel 2 (CH3)
	jr .checkA
.bNot2
	call CycleNoiseDivisor  ; channel 3 (CH4)

.checkA
	ld a, [bJoypadDown]
	and a, BUTTON_A
	jr z, .endCheck

	ld a, [wCurrentChannel]
	cp 0
	jr nz, .aNot0
	call TriggerSweep       ; channel 0 (CH1)
	jr .endCheck
.aNot0
	cp 1
	jr nz, .aNot1
	call CyclePanning       ; channel 1 (CH2)
	jr .endCheck
.aNot1
	cp 2
	jr nz, .aNot2
	call RandomizeCh3Freq   ; channel 2 (CH3)
	jr .endCheck
.aNot2
	call ToggleNoiseWidth   ; channel 3 (CH4)

.endCheck
	ret

