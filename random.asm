[SEGMENT .text]
GLOBAL Randomize,RandWord

;                  De methodes zijn afkomstig van Turbo Pascal 7.0

; ------------------------------------------------------------------------------
; Randomize - 1999-06-18
; DOEL     : Initialiseert RandSeed met een waarde van de systeemklok
; LEEST    : systeemklok
; SCHRIJFT : RandSeed
; ------------------------------------------------------------------------------
Randomize:
; Turbo Pascal code...
  RET

; ------------------------------------------------------------------------------
; RandWord - 1999-06-19
; DOEL      : Genereert een random-woord-waarde in RandRes
; SCHRIJFT  : RandRes
; ------------------------------------------------------------------------------
RandWord:
; Turbo Pascal code...  
  RET

[SEGMENT .data]
GLOBAL RandSeed
  RandSeed DD 0

COMMON RandVal 2
COMMON RandRes 2
