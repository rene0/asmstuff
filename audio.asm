[SEGMENT .text]	;Main code segment
GLOBAL Sound,NoSound

; ------------------------------------------------------------------------------
; Sound - 1999-12-17.
; DOEL     : Activeert de PC-luidspreker. De methode is afkomstig van de Sound-
;            procedure uit de CRT-unit van Borland Turbo Pascal 7.00.
; LEEST    : Freq
; ------------------------------------------------------------------------------
Sound:
; Turbo Pascal code...
  RET

; ------------------------------------------------------------------------------
; NoSound - 1999-12-17.
; DOEL     : Zet de PC-luidspreker uit. De methode is afkomstig van de
;            NoSound-procedure uit de CRT-unit van Borland Turbo Pascal 7.00.
; ------------------------------------------------------------------------------
NoSound:
; Turbo Pascal code...
  RET

COMMON Freq 2 ; 2 bytes in .bss
