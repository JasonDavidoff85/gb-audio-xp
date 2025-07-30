INCLUDE "definitions.inc"
INCLUDE "hardware.inc"

SECTION "AUDIO", ROMX

SetupCh1::
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

SetupCh2::
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

	ret


SetupCh4::
	; Set length timer to 0
	ld a, %00000000
	ld [rNR41], a

	; Set the vol to 100%.
	ld a, %00100000
	ld [rNR42], a

	; Freq lsb
	; %110_ %11010110
	ld a, %01101001 ; change this as custom param
	ld [rNR43], a

	ret


PlayCH1::
	; Freq msb and trigger
	; %10000110
	ld a, %10000001 ;C3
	ld [rNR14], a

	ret

PlayCH2::
	; Freq msb and trigger
	; %10000110
	ld a, %10000010 ;C3
	ld [rNR24], a

	ret

PlayCH3::
	; Trigger freq msb
	; %110_ %11010110
	ld a, %10000110
	ld [rNR34], a

	ret

PlayCH4::
	; Trigger
	ld a, %10000000
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
	; Increment
	inc a
	; Shift left to restore position
	swap a
	and %11110000
	; Preserve lower 4 bits of original value
	ld b, a           ; store new upper 4 bits in b
	ld a, [de]
	and %00001111     ; get lower 4 bits
	or b              ; combine with new upper 4 bits
	ld [de], a
	call PlayCurrentChannel
.done
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
	; Decrement
	dec a
	; Shift left to restore position
	swap a
	and %11110000
	; Preserve lower 4 bits of original value
	ld b, a           ; store new upper 4 bits in b
	ld a, [de]
	and %00001111     ; get lower 4 bits
	or b              ; combine with new upper 4 bits
	ld [de], a
	call PlayCurrentChannel
.done
	ret


;; Test for special function
IncNR11Duty::
	ld a, [rNR11]
	; Extract bits 6 and 7 (wave duty)
	and %11000000
	; Shift right to get value in lower bits
	rrca
	rrca
	; Increment and wrap around after 3 (00, 01, 10, 11)
	inc a
	and %00000011
	; Shift left to put back in bits 6 and 7
	swap a
	and %11000000
	; Preserve lower 6 bits of original value
	ld a, [rNR11]
	ld b, a
	and b
	; Clear bits 6 and 7 in original value
	ld a, [rNR11]
	and %00111111
	; Combine new duty bits with lower bits
	or b
	ld [rNR11], a
	ret