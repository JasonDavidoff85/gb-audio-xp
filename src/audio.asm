INCLUDE "definitions.inc"
INCLUDE "hardware.inc"

SECTION "AUDIO", ROMX

SetupCh1::
	; Channel 1 sweep.
	; %00111100
	ld a, %00000111 ; turn on off as param?
	ld [rNR10], a

	; TODO random sweep direction, individual step and sweep pace

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
	; Store NR13 value to wChannel1Freq variable (low byte)
	ld [wChannel1Freq], a
	; Initialize high byte of frequency variable  
	ld a, %00000000
	ld [wChannel1Freq + 1], a

	ret

SetupCh2::
	; TODO random sweep direction, individual step and sweep pace

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
	; Initialize frequency variable (both bytes)
	ld [wChannel2Freq], a       ; Store low byte
	ld a, %00000000             ; set high byte to 0 and no trigger
	ld [wChannel2Freq + 1], a

	ret

SetupCh3::
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
	; Initialize frequency variable (both bytes)
	ld [wChannel3Freq], a       ; Store low byte
	ld a, %00000000             ; clear high byte
	ld [wChannel3Freq + 1], a   ; Store high byte

	ret


SetupCh4::
	; Set length timer to 0
	ld a, %00000000
	ld [rNR41], a

	; Set the vol to 100%.
	ld a, %00100000
	ld [rNR42], a

	; Frequency
	; %110_ %11010110
	ld a, %01101001 ; TODO change this to something significant
	ld [rNR43], a

	ret


; Trigger channel 1 with no length enabled
; and preserves 3 bits of frequency in high byte
PlayCH1::
	ld a, [wChannel1Freq + 1]
	and %00000111
	or %10000000 ; Set bit 7 (trigger)
	ld [rNR14], a

	ret

; Trigger channel 2 with no length enabled
; and preserves 3 bits of frequency in high byte
PlayCH2::
	ld a, [wChannel2Freq + 1]
	and %00000111
	or %10000000 ; Set bit 7 (trigger)
	ld [rNR24], a

	ret

; Trigger channel 3 with no length enabled
; and preserves 3 bits of frequency in high byte
PlayCH3::
	ld a, [wChannel3Freq + 1]
	and %00000111
	or %10000000 ; Set bit 7 (trigger)
	ld [rNR34], a

	ret

; Trigger channel 4 with no length enabled
PlayCH4::
	ld a, %10000000 ; Trigger and no length enabled
	ld [rNR44], a

	ret

PlayCurrentChannel::
	ld a, [wCurrentChannel] ; Assume wCurrentChannel holds 1-4
	cp 0
	jr z, .ch1
	cp 1
	jr z, .ch2
	cp 2
	jr z, .ch3
	cp 3
	jr z, .ch4
	ret
.ch1
	call PlayCH1
	ret
.ch2
	call PlayCH2
	ret
.ch3
	call PlayCH3
	ret
.ch4
	call PlayCH4
	ret


; Assumes GetChannelVolumeReg returns DE pointing to the desired volume register
IncChannelVol::
	call GetChannelVolumeReg
	ld a, [de]
	; Extract upper 4 bits (volume)
	and %11110000
	swap a
	and %00001111
	; Check if already at max (15)
	cp 15
	jr z, .done
	
	inc a ; Increment
	; Reassign
	swap a
	and %11110000

	ld b, a           ; store new upper 4 bits in b
	ld a, [de]
	and %00001111     ; get lower 4 bits
	or b              ; combine with new upper 4 bits
	ld [de], a
	call PlayCurrentChannel
.done
	ret

; Mute the current channel by setting the high 4 bits (volume) to 0
; Assumes GetChannelVolumeReg returns DE pointing to the desired volume register
MuteChannel::
	call GetChannelVolumeReg
	ld a, [de]
	and %00001111     ; clear upper 4 bits (volume), keep lower 4 bits
	ld [de], a
	call PlayCurrentChannel
	ret

; Channel 3 specific volume control using NR32 bits 5-6
; Volume levels: 00=mute, 11=25%, 10=50%, 01=100% (loudest)
; Progression: 00 → 11 → 10 → 01 → 00 (wrap)
IncChannel3Vol::
	ld a, [rNR32]
	; Extract bits 5 and 6 (volume control)
	and %01100000
	; Shift right to get value in lower bits
	swap a
	rrca
	and %00000011
	; Increment through the specific volume sequence
	cp 0 ; 00 (mute)
	jr nz, .check11
	ld a, 3
	jr .setVolume
.check11
	cp 3 ; 11 (25%)
	jr nz, .check10
	ld a, 2
	jr .setVolume
.check10
	cp 2 ; 10 (50%)
	jr nz, .check01
	ld a, 1
	jr .setVolume
.check01           
	ld a, 1 ; stay at 100%
.setVolume
	; Re assign
	rlca
	swap a
	and %01100000
	
	ld b, a                 ; store new volume bits in b
	ld a, [rNR32]
	and %10011111           ; clear bits 5 and 6
	or b                    ; combine with new volume bits
	ld [rNR32], a
	call PlayCurrentChannel
	ret


; Channel 3 specific volume control using NR32 bits 5-6
; Volume levels: 00=mute, 11=25%, 10=50%, 01=100% (loudest)
; Progression: 01 → 10 → 11 → 00 → 01 (reverse of increment)
DecChannel3Vol::
	ld a, [rNR32]
	; Extract bits 5 and 6 (volume control)
	and %01100000
	; Shift right to get value in lower bits
	swap a
	rrca
	and %00000011

	cp 1 ; 01 (100%)
	jr nz, .check10
	ld a, 2
	jr .setVolume
.check10
	cp 2 ; 10 (50%)
	jr nz, .check11
	ld a, 3
	jr .setVolume
.check11
	cp 3 ; 11 (25%)
	jr nz, .check00
	ld a, 0
	jr .setVolume
.check00
	ld a, 0 ; stay at mute
.setVolume
	; Re assign
	rlca
	swap a
	and %01100000

	ld b, a                 ; store new volume bits in b
	ld a, [rNR32]
	and %10011111           ; clear bits 5 and 6
	or b                    ; combine with new volume bits
	ld [rNR32], a
	call PlayCurrentChannel
	ret


; Assumes GetChannelVolumeReg returns DE pointing to the desired volume register
DecChannelVol::
	call GetChannelVolumeReg
	ld a, [de]
	; Extract upper 4 bits (volume)
	and %11110000
	swap a
	and %00001111
	; Check if already at min (0)
	cp 0
	jr z, .done
	
	dec a ; Decrement
	
	swap a ; re assign
	and %11110000

	ld b, a           ; store new upper 4 bits in b
	ld a, [de]
	and %00001111     ; get lower 4 bits
	or b              ; combine with new upper 4 bits
	ld [de], a
	call PlayCurrentChannel
.done
	ret

; Assumes GetChannelPeriodLowReg returns DE pointing to the desired period (frequency LSB) register
IncChannelPeriod::
	call GetChannelPeriodLowReg
	ld a, [de]
	inc a
	ld [de], a
	call PlayCurrentChannel
	ret

; Assumes GetChannelPeriodLowReg returns DE pointing to the desired period (frequency LSB) register
DecChannelPeriod::
	call GetChannelPeriodLowReg
	ld a, [de]
	dec a
	ld [de], a
	call PlayCurrentChannel
	ret

; Increment 11-bit frequency stored in RAM variables for ch 1-3
; Uses wChannelxFreq variables to track frequency values
; Assumes GetChannelFreqVar returns HL pointing to 16-bit frequency variable
IncChannelFreq11Bit::
	push hl
	; Get pointer to frequency variable in RAM
	call GetChannelFreqVar      ; HL points to wChannelxFreq
	
	; Load current 16-bit frequency value
	ld a, [hli]                 ; Load low byte, increment HL
	ld b, [hl]                  ; Load high byte
	ld l, a                     ; Put low byte back in L
	ld h, b                     ; Put high byte in H
	
	; Increment the frequency
	ld de, 16
	add hl, de
	
	; Check for 11-bit overflow (frequency > $7FF)
	ld a, h
	and %11111000               ; Check if any bits above bit 2 are set
	jr nz, .overflow            ; If so, we've overflowed 11 bits
	
	; Store updated frequency back to RAM
	; Save updated frequency value before calling GetChannelFreqVar
	ld d, l                     ; Store low byte in D
	ld e, h                     ; Store high byte in E
	call GetChannelFreqVar      ; HL points to wChannelxFreq again
	ld [hl], d                  ; Store low byte
	inc hl
	ld [hl], e                  ; Store high byte
	
	; Update hardware registers from RAM value
	call UpdateChannelFreqRegisters
	pop hl
	ret
	
.overflow:
	; Handle overflow - stay at max, don't apply increment
	ld hl, $07FF                ; Set to max 11-bit value
	
	; Store max value to RAM
	call GetChannelFreqVar
	ld [hl], $FF                ; Store low byte (max)
	inc hl  
	ld [hl], $07                ; Store high byte (max)
	
	; Update hardware registers
	call UpdateChannelFreqRegisters
	pop hl
	ret

; Decrement 11-bit frequency stored in RAM variables just for ch 1-3
; Uses wChannelxFreq variables to track frequency values
; Assumes GetChannelFreqVar returns HL pointing to 16-bit frequency variable
DecChannelFreq11Bit::
	push hl
	; Get pointer to frequency variable in RAM
	call GetChannelFreqVar      ; HL points to wChannelxFreq
	
	; Load current 16-bit frequency value
	ld a, [hli]                 ; Load low byte, increment HL
	ld b, [hl]                  ; Load high byte
	ld l, a                     ; Put low byte back in L
	ld h, b                     ; Put high byte in H
	
	; Check for underflow before decrementing
	ld de, 16                   ; Changed back to 16 from 1
	ld a, l                     ; Get low byte
	sub e                       ; Subtract 16 from low byte
	ld c, a                     ; Save result in C
	ld a, h                     ; Get high byte
	sbc 0                       ; Subtract borrow from high byte
	jr c, .underflow            ; If carry set, we have underflow
	
	; No underflow, store decremented value
	ld h, a                     ; High byte result
	ld l, c                     ; Low byte result
	
	; Store updated frequency back to RAM
	ld d, l                     ; Store low byte in D
	ld e, h                     ; Store high byte in E
	call GetChannelFreqVar      ; HL points to wChannelxFreq again
	ld [hl], d                  ; Store low byte
	inc hl
	ld [hl], e                  ; Store high byte
	
	; Update hardware registers from RAM value
	call UpdateChannelFreqRegisters
	pop hl
	ret
	
.underflow:
	; Handle underflow - stay at minimum, don't apply decrement
	ld hl, $0000                ; Set to min value (0)
	
	; Store min value to RAM
	call GetChannelFreqVar
	ld [hl], $00                ; Store low byte (min)
	inc hl  
	ld [hl], $00                ; Store high byte (min)
	
	; Update hardware registers
	call UpdateChannelFreqRegisters
	pop hl
	ret

; Update hardware frequency registers from RAM frequency variable
; Assumes GetChannelFreqVar returns HL pointing to frequency variable
; and GetChannelPeriodLowReg/GetChannelTriggerReg work as before
UpdateChannelFreqRegisters::
	; Get frequency value from RAM
	call GetChannelFreqVar      ; HL points to wChannelxFreq
	ld a, [hli]                 ; Load low byte
	ld b, [hl]                  ; Load high byte into B
	
	; Write low 8 bits to NRx3
	push af
	call GetChannelPeriodLowReg ; DE points to NRx3
	pop af
	ld [de], a                  ; Write low byte
	
	; Write high 3 bits to NRx4 (preserving other bits, but force highest bit to 0)
	call GetChannelTriggerReg   ; DE points to NRx4
	ld a, [de]                  ; Get current NRx4 value
	and %01111000               ; Clear frequency bits and highest bit (bit 7)
	ld c, a                     ; Store non-frequency bits with bit 7 cleared
	ld a, b                     ; Get high byte from RAM
	and %00000111               ; Mask to only 3 bits
	or c                        ; Combine with preserved bits, bit 7 is 0
	ld [de], a                  ; Write back to NRx4
	ret

; Increment Channel 4 frequency (NR43 bits 4-7)
; decrements the shift clock frequency 
IncChannel4Freq::
	; get current value and isolate clock shift bits
	ld a, [rNR43]
	and %11110000
	swap a
	; Check if already at 0
	cp 0
	jr z, .done

	dec a
	; reshift
	swap a
	and %11110000

	ld b, a  ; store new upper 4 bits in b
	ld a, [rNR43]
	and %00001111               
	or b
	ld [rNR43], a ; push back
	call PlayCurrentChannel
.done
	ret

; Decrement Channel 4 frequency (NR43 bits 4-7)
; Increments the shift clock frequency
DecChannel4Freq::
	ld a, [rNR43] ; get current value and isolate clock shift bits
	and %11110000
	swap a
	; Check if already at max (15)
	cp 15
	jr z, .done

	inc a
	; reshift
	swap a
	and %11110000

	ld b, a ; store new upper 4 bits in b
	ld a, [rNR43]
	and %00001111
	or b
	ld [rNR43], a
	call PlayCurrentChannel
.done
	ret

;; Cycle wave duty for current channel (only applies to channels 1 and 2)
CycleWaveDuty::
	ld a, [wCurrentChannel]
	cp 0
	jr z, .useNR11
	cp 1
	jr z, .useNR21
	ret ; Channels 3 and 4 don't have wave duty

.useNR11:
	ld a, [rNR11]
	jr .processDuty

.useNR21:
	ld a, [rNR21]

.processDuty:
	; Extract bits 6 and 7 (wave duty)
	and %11000000
	swap a
	rrca
	rrca
	; Increment and re swap
	inc a
	and %00000011
	swap a
	rlca 
	rlca
	
	ld c, a ; Save new duty bits in C
	
	; Get current channel and write back to correct register
	ld a, [wCurrentChannel]
	cp 0
	jr z, .writeNR11
	
	ld a, [rNR21]
	and %00111111
	or c ; Set new duty bits
	ld [rNR21], a
	ret

.writeNR11:
	ld a, [rNR11]  
	and %00111111
	or c ; Set new duty bits
	ld [rNR11], a
	ret

; Trigger a sweep for channel 1 (NR10 bits 6-4)
TriggerSweep::
	ld a, [rNR12]
	and %00000111       ; isolate bits 2-0
	cp %00000001        ; check if 001 (make this a variable and have it be random)
	jr z, .setZero
	cp %00000000        ; check if 000
	jr z, .setMax
	jr .done            ; neither 000 nor 001, do nothing
.setZero
	ld a, %00000000
	jr .writeback
.setMax
	ld a, %00000001
.writeback
	ld b, a
	ld a, [rNR12]
	and %11111000       ; clear bits 2-0
	or b
	ld [rNR12], a
.done
	ret

; Cycle NR51 panning between three states each call:
;   %11111111 -> %11011111 -> %11111101 -> (wrap)
CyclePanning::
	ld a, [rNR51]
	cp %11111111
	jr nz, .check2
	ld a, %11011111
	jr .writeback
.check2
	cp %11011111
	jr nz, .default
	ld a, %11111101
	jr .writeback
.default
	ld a, %11111111
.writeback
	ld [rNR51], a
	call PlayCurrentChannel
	ret


WriteRandomWaveByte::
	; Pseudo-random byte from DIV -> $FF30
	ldh a, [rDIV]
	ldh [_AUD3WAVERAM], a
	call PlayCurrentChannel
	ret

; Set channel 3's frequency low byte (NR33) to a pseudo-random value from rDIV,
; like WriteRandomWaveByte but driving CH3's pitch. The new period takes effect
; without a trigger, so CH3 is not retriggered (avoids wave-RAM corruption).
RandomizeCh3Freq::
	call Rand8
	ld [rNR33], a           ; CH3 frequency LSB
	ld [wChannel3Freq], a   ; keep the RAM copy of the frequency in sync

	; Randomize the high 3 bits of the 11-bit frequency (NR34 bits 2-0)
	call Rand8
	and %00000111           ; keep only the 3 high frequency bits
	ld [wChannel3Freq + 1], a ; keep the RAM copy in sync
	ld b, a
	ld a, [rNR34]
	and %01111000           ; clear freq bits and trigger (bit 7); keep others
	or b                    ; merge in new high freq bits
	ld [rNR34], a           ; no trigger, so no wave-RAM corruption
	ret

; 8-bit maximal-length Galois LFSR (period 255). Returns the next byte in A.
; Uses wRandomSeed as state and self-seeds if it is ever 0 (0 is a dead state).
Rand8::
	ld a, [wRandomSeed]
	or a
	jr nz, .shift
	ld a, $01           ; seed must be non-zero
.shift
	srl a               ; shift right; old bit 0 -> carry
	jr nc, .store
	xor %10111000       ; tap mask $B8 for a maximal-length 8-bit LFSR
.store
	ld [wRandomSeed], a
	ret

; Toggle bit 3 of NR43 (CH4 noise LFSR width: 15-bit vs 7-bit).
ToggleNoiseWidth::
	ld a, [rNR43]
	xor %00001000           ; toggle bit 3
	ld [rNR43], a
	ret

; Increment the low 3 bits of NR43 (CH4 clock divisor), wrapping 111 -> 000.
CycleNoiseDivisor::
	ld a, [rNR43]
	and %00000111           ; isolate bits 2-0
	inc a
	and %00000111           ; wrap: 111+1 -> 000
	ld b, a
	ld a, [rNR43]
	and %11111000           ; clear bits 2-0
	or b                    ; set new divisor bits
	ld [rNR43], a
	ret


