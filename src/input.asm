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
	ld a, [bJoypadPressed]   ; edge-triggered: one switch per physical press
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

	; Update VBlank handler pointer based on new channel
	ld a, [wCurrentChannel]
	cp 2
	jr z, .setCh3Handler
	cp 3
	jr z, .setCh4Handler
	ld hl, Ch12VBlankHandler
	jr .setHandler
.setCh3Handler:
	ld hl, Ch3VBlankHandler
	jr .setHandler
.setCh4Handler:
	ld hl, Ch4VBlankHandler
.setHandler:
	ld a, l
	ld [wVBlankFunc], a
	ld a, h
	ld [wVBlankFunc + 1], a
	call UpdateScrollThreshold
	call UpdateChannelTile       ; show the new channel's volume-based tile

	; Enable the per-scanline raster-zoom STAT interrupt only on CH3 (index 2)
	ld a, [wCurrentChannel]
	cp 2
	jr z, .enableZoom
	; Leaving CH3: turn the STAT interrupt off; next VBlank restores rSCY
	ld a, [rIE]
	res 1, a                    ; clear IEF_STAT
	ld [rIE], a
	jr .zoomDone
.enableZoom:
	; Start flat (step 0, centered on current scroll) until CH3's VBlank
	; computes the real values, so no garbage SCY shows for a partial frame.
	xor a
	ldh [hZoomStepLo], a
	ldh [hZoomStepHi], a
	ldh [hZoomAccLo], a
	ld a, [wScrollY]
	ldh [hZoomAccHi], a
	ld a, STATF_MODE00          ; interrupt at the start of each HBlank
	ldh [rSTAT], a
	ld a, [rIE]
	set 1, a                    ; set IEF_STAT
	ld [rIE], a
.zoomDone:

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
	call IncCh1Squares
	ret
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
	call DecCh1Squares
	ret

