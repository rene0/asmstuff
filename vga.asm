[SEGMENT .text]
GLOBAL PutPixel,PutVGA,RestoreMode,SetPalEntry

; ------------------------------------------------------------------------------
; PutVGA - 1999-06-23
; DOEL     : Bewaart de huidige videomodus en schakelt om naar VGA
; GEBRUIKT : AX,BX,Flags
; SCHRIJFT : OldMode,NrCols,APage
; ------------------------------------------------------------------------------
PutVGA:
  push AX
  push BX
  pushf

  mov AH,0x0F ; Get video mode
  INT 0x10
  mov [OldMode],AL
  mov [NrCols],AH
  mov [APage],BH

  mov AX,0x0012 ; Set video mode, VGA, 640x480,80x30,16 col
  INT 0x10

  popf
  pop BX
  pop AX
  RET

; ------------------------------------------------------------------------------
; PutPixel - 1999-06-23
; DOEL     : Schrijft een pixel naar (CX,DX) met kleur AL op de actieve pagina
; LEEST    : APage
; GEBRUIKT : AX,BX
; ------------------------------------------------------------------------------
PutPixel:
  push AX
  push BX

  mov AH,0x0C     ; write pixel
  mov BH,[APage]
  INT 0x10

  pop BX
  pop AX
  RET

; ------------------------------------------------------------------------------
; RestoreMode - 1999-06-23
; DOEL     : Herstelt de modus naar OldMode
; LEEST    : OldMode
; GEBRUIKT : AX,Flags
; ------------------------------------------------------------------------------
RestoreMode:
  push AX
  pushf

  mov AL,[OldMode]   ; restore video mode
  xor AH,AH          ; set video mode
  INT 0x10

  popf
  pop AX
  RET

; ------------------------------------------------------------------------------
; SetPalEntry - 1999-06-23
; DOEL     : Stelt een 16M-kleur in in de palette op kleurnummer PalEntry
; LEEST    : PalEntry,RedV,GreenV,BlueV
; GEBRUIKT : AX,BX,CX,DX
; ------------------------------------------------------------------------------
SetPalEntry:
  push AX
  push BX
  push CX
  push DX

  mov AX,0x1010    ; Set individual palette
  mov BX,[PalEntry]
  mov DH,[RedV]
  mov CH,[GreenV]
  mov CL,[BlueV]
  INT 0x10

  pop DX
  pop CX
  pop BX
  pop AX
  RET

COMMON OldMode  1
COMMON NrCols   1
COMMON APage    1
COMMON RedV     1
COMMON GreenV   1
COMMON BlueV    1
COMMON PalEntry 2
