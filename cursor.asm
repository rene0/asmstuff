[SEGMENT .text]
GLOBAL SaveCursor,SetCursor,MoveCursor

; ------------------------------------------------------------------------------
; SaveCursor - 1998-06-08.
; DOEL     : Bewaart de huidige cursor in Cursor (word-variable). De cursor
;            wordt gelezen d.m.v. INTerrupt 10h, functie 3.
; GEBRUIKT : AX,BX,CX,DX,Flags
; SCHRIJFT : Cursor,YPos,XPos
; ------------------------------------------------------------------------------
SaveCursor:

  push AX   ; Bewaar de gebruikte registers
  push BX
  push CX
  push DX
  pushf

  mov AH,3  ; Vraag cursorinformatie
  xor BH,BH ; Pagina 0
  INT 10h   ; Roep BIOS aan
  mov [Cursor],CX
  mov [YPos],DH
  mov [XPos],DL

  popf      ; Herstel de gebruikte registers
  pop DX
  pop CX
  pop BX
  pop AX

  RET

; ------------------------------------------------------------------------------
; SetCursor - 1999-06-08.
; DOEL     : Stelt een nieuwe cursor in d.m.v. INTerrupt 10h, functie 1.
;            In hi(Cursor) staat de startregel, in lo(Cursor) de eindregel.
; LEEST    : Cursor
; GEBRUIKT : AX,BX,CX,Flags
; ------------------------------------------------------------------------------
SetCursor:

  push AX   ; Bewaar de gebruikte registers
  push BX
  push CX
  pushf

  mov AH,1  ; Stel cursor in
  xor BH,BH ; Op pagina 0
  mov CX,[Cursor]
  INT 0x10  ; Roep BIOS aan

  popf      ; Herstel de gebruikte registers
  pop CX
  pop BX
  pop AX

  RET

; ------------------------------------------------------------------------------
; MoveCursor - 1999-06-08
; DOEL     : Verplaatst de cursor d.m.v. INTerrupt 10h, functie 2.
; LEEST    : XPos,YPos
; GEBRUIKT : AX,BX,DX,Flags
; ------------------------------------------------------------------------------
MoveCursor:

  push AX       ; Bewaar de registers
  push BX
  push DX
  pushf

  mov AH,2      ; 2 = Set cursor position
  mov DH,[YPos] ; Regel
  mov DL,[XPos] ; Kolom
  xor BH,BH     ; Pagina 0
  INT 0x10      ; Roep BIOS aan

  popf          ; Herstel de registers
  pop DX
  pop BX
  pop AX

  RET

COMMON Cursor 2 ; 2 bytes
[SEGMENT .bss]
EXTERN XPos,YPos
