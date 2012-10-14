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
