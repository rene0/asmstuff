; Copyright (c) 1997-2000 René Ladan. All rights reserved.
;
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions
; are met:
; 1. Redistributions of source code must retain the above copyright
;    notice, this list of conditions and the following disclaimer.
; 2. Redistributions in binary form must reproduce the above copyright
;    notice, this list of conditions and the following disclaimer in the
;    documentation and/or other materials provided with the distribution.
;
; THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
; ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
; ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
; OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
; HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
; LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
; OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
; SUCH DAMAGE.

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
