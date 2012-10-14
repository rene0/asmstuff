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

; ==============================================================================
; PixDemo - 1999-06-23 -- 1999-06-25
; Programma dat een symmetrisch patroon genereert, met piepjes.
; ==============================================================================

[SEGMENT .text]
EXTERN PutVGA,RestoreMode,PutPixel,ActKey,GetParameters,StrToDec,Sound,NoSound
EXTERN Randomize,RandWord,ShowCopy,GetVidSegment,InitDelay,Delay

; ------------------------------------------------------------------------------
; SetPoints - 1999-06-26
; DOEL      : Zet 4 puntjes van het patroon op het scherm.
; LEEST     : XP (originele x-positie, 0..319)
; SCHRIJFT  : CX (x-positie), DX (y-positie)
; ROEPT AAN : PutPixel
; ------------------------------------------------------------------------------
SetPoints:
  CALL PutPixel ; in driehoek 2,1
  neg CX
  add CX,639    ; X4=639-X1, Y4=Y1
  CALL PutPixel ; in driehoek 3,4
  mov CX,[XP]     ; restore
  neg DX
  add DX,479    ; X5=X1, Y5=479-Y1
  CALL PutPixel ; in driehoek 6,5
  neg CX
  add CX,639    ; X8=639-X1, Y8=479-Y1
  CALL PutPixel ; in driehoek 7,8
  RET

; ------------------------------------------------------------------------------
; GetRandSeed - 1999-06-25
; DOEL      : Initialiseert de RNG met de systeemklok of met paramstr(1)
; SCHRIJFT  : CX,EDX,SI,Params,RandSeed
; ROEPT AAN : GetParameters,StrToDec
; ------------------------------------------------------------------------------
%MACRO GetRandSeed 0
  CALL GetParameters
  JCXZ DoRandomize ; Geen parameters
  lea SI,[Params]    ; EDX = val(DS:SI) met lengte CX
  CALL StrToDec
  mov [RandSeed],EDX
  JMP SHORT EndSeed
DoRandomize:
  CALL Randomize   ; RandSeed via timer
EndSeed:
%ENDMACRO

; ------------------------------------------------------------------------------
; InitProg - 1999-06-25
; DOEL      : Odds 'n ends
; LEEST     : LGuide
; SCHRIJFT  : CX
; ROEPT AAN : GetVidSegment,ShowCopy,PutVGA
; ------------------------------------------------------------------------------
%MACRO InitProg 0
  CALL InitDelay
  CALL GetVidSegment
  mov CL,LGuide
  CALL ShowCopy
  CALL PutVGA
  mov CX,2500 ; wacht op scherm
  CALL Delay
%ENDMACRO

; ------------------------------------------------------------------------------
; GetValues - 1999-06-26
; DOEL      : Bepaalt XP (0..319), YP (0..3/4*XP) en de kleur v/d pixel
; LEEST     : RandRes
; SCHRIJFT  : AX,CX,DX,XP,YP,RandVal
; ------------------------------------------------------------------------------
%MACRO GetValues 0
  mov WORD [RandVal],320 ; 0..319
  CALL RandWord
  mov AX,[RandRes]  ; x-coordinaat
  mov [XP],AX
  xor DX,DX       ; voor idiv
  mov CX,4        ;   "    "
  idiv CX         ; AX=DX:AX/3, DX=DX:AX%3
  cmp DX,2        ; Fractie >= 1/2 ?
  JB NoIncAX      ; Nee
  inc AX          ; Naar boven afronden
NoIncAX:
  imul AX,3       ; AX*=3
  mov [RandVal],AX  ; 0..(3/4)*XP
  CALL RandWord
  mov DX,[RandRes]  ; y-coordinaat
  mov [YP],DX
  mov CX,[XP]       ; herladen
  mov WORD [RandVal],16  ; 0..15
  CALL RandWord
  mov AX,[RandRes]  ; kleur
%ENDMACRO

; ------------------------------------------------------------------------------
; MirrorCoords - 1999-06-26
; DOEL      : Spiegelt XP en YP en past de bereiken aan
; LEEST     : XP,YP
; GEBRUIKT  : AX
; SCHRIJFT  : CX,DX,XP,YP
; ------------------------------------------------------------------------------
%MACRO MirrorCoords 0
  push AX    ; voor idiv
  mov AX,[YP]  ;   "    "
  xor DX,DX  ;   "    "
  shl AX,2   ; AX*=2
  mov CX,3   ; voor idiv
  idiv CX    ; AX=DX:AX/3, DX=DX:AX%3
  cmp DX,2   ; Fractie >= 2/3 ?
  JB NoRndAX ; Nee
  inc AX     ; Naar boven afronden
NoRndAX:
  mov CX,AX
  mov AX,[XP]
  mov [XP],CX  ; XP=(4/3)*YP

  xor DX,DX  ; voor idiv
  mov CX,4   ;   "    "
  idiv CX    ; AX=DX:AX/3, DX=DX:AX%3
  cmp DX,2   ; Fractie >= 1/2 ?
  JB NoAdjAX ; Nee
  inc AX     ; Naar boven afronden
NoAdjAX:
  imul AX,3
  mov DX,AX
  mov [YP],DX  ; YP=(3/4)*XP
  mov CX,[XP]  ; herladen
  pop AX     ; voor idiv
%ENDMACRO

; ------------------------------------------------------------------------------
; CalcFreq - 1999-06-25
; DOEL      : Berekent de frequentie van het piepje kleur*512+(x/16*y/16*2)
; LEEST     : XP,YP
; SCHRIJFT  : AX,CX,DX,Freq
; ------------------------------------------------------------------------------
%MACRO CalcFreq 0
  shl AX,9    ; AX*=512
  mov CX,[XP]
  shr CX,4    ; CX/=16
  mov DX,[YP]
  shr DX,4    ; DX/=16
  imul DX,CX
  mov WORD [Freq],DX ; imul Freq,DX -> imul SI,DX !
  shl WORD [Freq],1  ; Freq*=2
  add WORD [Freq],AX
%ENDMACRO

; ------------------------------------------------------------------------------
; EmitBeep - 1999-06-25
; DOEL      : Zendt het piepje van Speed/2 ms uit als het aanstaat (anders stil)
; LEEST     : Speed,Status
; SCHRIJFT  : CX
; ------------------------------------------------------------------------------
%MACRO EmitBeep 0
  xor CH,CH
  mov CL,[Speed] ; Speed ms rust
  cmp BYTE [Status],1 ; piepje aan?
  JNE SkipBeep ; nee
  shr CX,1     ; Speed/2 ms rust
  CALL Sound
  CALL Delay
  CALL NoSound
SkipBeep:
  CALL Delay
%ENDMACRO

; ------------------------------------------------------------------------------
; AdjustSpeed - 1999-06-25
; DOEL      : Stelt de snelheid bij
; LEEST     : AL (toets)
; SCHRIJFT  : Speed
; ------------------------------------------------------------------------------
%MACRO AdjustSpeed 0
  cmp AL,'-'    ; Langzamer?
  JNE TestInc   ; Nee
  cmp BYTE [Speed],255 ; Minimaal?
  JE TestInc    ; ja
  inc BYTE [Speed]     ; 1 ms langzamer
TestInc:
  cmp AL,'+'    ; Sneller?
  JNE SkipSpeed ; Nee
  cmp BYTE [Speed],0   ; Maximaal?
  JE SkipSpeed  ; Ja
  dec BYTE [Speed]     ; 1 ms sneller
%ENDMACRO

; ------------------------------------------------------------------------------
; Main - 1999-06-25
; DOEL      : Dit is het hoofdprogramma.
; LEEST     : DGroup
; SCHRIJFT  : AX,DS,Status
; ROEPT AAN : SetPoints,ActKey,RestoreMode
; MACROS    : GetRandSeed,InitProg,GetValues,MirrorCoords,CalcFreq,EmitBeep
;             AdjustSpeed
; ------------------------------------------------------------------------------
..start:
  mov AX,DGroup    ; Zet eigen datasegment in DS op
  mov DS,AX        ; Dit moet via een GP-register
  mov BYTE [Status],0 ; Piepje uit
  GetRandSeed
  InitProg
  PixLus:
    GetValues      ; XP,YP,kleur
    CALL SetPoints ; Teken de 4 puntjes van 1,4,5,8
    MirrorCoords   ; in Y=X
    CALL SetPoints ; Teken de 4 puntjes van 2,3,6,7
    cmp BYTE [Status],1 ; Piepje aan?
    JNE SkipCalc   ; Nee, dan geen frequentie berekenen
    CalcFreq
  SkipCalc:
    EmitBeep
    CALL ActKey
    or AH,AH       ; Toets ingedrukt?
    JZ SkipSpeed   ; Nee
    AdjustSpeed    ; Eventueel bijstellen
  SkipSpeed:
    cmp BYTE [Halted],0   ; Doorgaan?
  JE PixLus        ; Ja

  CALL RestoreMode
  mov AX,0x4C00    ; Terminate process DOS Service,no error
  INT 0x21         ; Roep DOS aan

[SEGMENT .data]
EXTERN RandSeed,Status,Halted
GLOBAL FileName,Guide
FileName DB  'pixdemo.exe',0
Guide    DB  'Esc : stoppen, Tab : piepje aan/uit, - : langzamer, + : sneller'
LGuide   EQU $-Guide
Speed DB 50 ; 50 ms tussen 2 plaatsingen

[SEGMENT .bss]
EXTERN RandVal,RandRes,Params,Freq
XP RESW 1
YP RESW 1

[SEGMENT .stack stack]
RESB 1024

GROUP DGroup data bss stack
