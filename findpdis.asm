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
EXTERN OpenFile,CloseFile,GetVidSegment,WipeScreen,Sound,NoSound
EXTERN DecToStr,StrToDec,InitDelay,Delay

; ------------------------------------------------------------------------------
; CheckNumber - 1999-07-12
; DOEL : Kijkt of EDX een PDI is (ZF=1) en schrijft EDX naar het scherm (CX=len)
; ------------------------------------------------------------------------------
%MACRO CheckNumber 0
  push EDX       ; Bewaar het origineel
  mov EAX,EDX    ; EAX wordt gedeeld
  mov EBX,10     ; Deelfactor
  mov CX,0       ; Teller 0
  mov DI,18      ; Positie 10 (0-based)
NonZero:
  mov EDX,0      ; Hoogste dubbelwoord van N = 0, wis de rest
  div EBX        ; Deel EAX (=N) door 10
  push EDX
  add DX,0730h   ; Attribuut, naar cijfer
  mov [ES:DI],DX
  dec DI
  dec DI
  inc CX         ; Weer een cijfer gedaan
  test EAX,EAX   ; N al 0 ?
  JNZ NonZero    ; Nee, terug

  mov EBX,0      ; controlesom = 0
  mov DX,CX      ; Kopieer count
PutDigit:
  pop EAX
  test AL,AL     ; Nul?
  JZ NextDigit   ; Er valt niets op te tellen
  cmp AL,1
  JNE DoCalc     ; PDI berekenen als EAX > 1
  inc EBX        ; 1 optellen bij controlesom
  JMP SHORT NextDigit

DoCalc:
  mov ESI,1      ; Mult=1
  push CX        ; bewaar buitenste count
  mov CX,DX      ; Tijdelijk buitenste count
AddLoop:
  imul ESI,EAX    ; CX maal, dus ESI=EAX^CX
  dec CX
  JNZ AddLoop
  pop CX         ; hersteld
  add EBX,ESI
NextDigit:
  dec CX         ; sneller dan LOOP
  JNZ PutDigit   ; ivm pairing
  mov CX,DX      ; Count weer in CX
  pop EDX        ; origineel hersteld
  cmp EBX,EDX    ; ZF=1 -> PDI
%ENDMACRO

; ------------------------------------------------------------------------------
; MoveFilePointer - 1999-07-10
; DOEL     : Verplaatst de filepointer naar de code in AL met offset 0.
; LEEST    : AL,BX
; GEBRUIKT : DX
; SCHRIJFT : AX,CX,CF
; ------------------------------------------------------------------------------
MoveFilePointer:
  push DX        ; Bewaar lo(PDICount)
  mov AH,0x42    ; Move file pointer (BX=FHandle)
  mov CX,0       ; Geen offset
  mov DX,0       ;  "     "
  INT 0x21       ; roep DOS aan
  pop DX         ; Herstel lo(PDICount)
  RET

; ------------------------------------------------------------------------------
; WriteNum - 1999-07-09
; DOEL     : Schrijft EDX+CRLF naar FindPDIs.LST (formaat in SI, lengte in CX)
; LEEST    : CX,EDX,SI,BufNumb
; SCHRIJFT : AX,CX,DI,CF,BufNumb
; GEBRUIKT : DX
; ------------------------------------------------------------------------------
WriteNum:
  push DX        ; Bewaar lo(PDICount)
  lea DI,[BufNumb] ; EDX -> DS:DI
  CALL DecToStr
  mov AH,0x40    ; Write to file/device
  lea DX,[BufNumb] ; van DS:DX
  INT 0x21       ; roep DOS aan
  mov CX,2       ; lengte CRLF
  lea DX,[CRLF]
  mov AH,0x40    ; in AX staat het aantal geschreven bytes
  INT 0x21       ; roep DOS aan
  pop DX         ; Herstel lo(PDICount)
  RET

; ------------------------------------------------------------------------------
; ReadCounter - 1999-07-12
; DOEL      : Haalt de teller op uit de 1e regel van FindPDIs.LST in EDX
; LEEST     : AX,(adres) BufNumb
; SCHRIJFT  : BX,AH,CX,EDX,SI,CF
; ROEPT AAN : StrToDec
; ------------------------------------------------------------------------------
%MACRO ReadCounter 0
  mov BX,AX      ; Copy FHandle
  mov AH,0x3F    ; Read file/device
  mov CX,10      ; aantal bytes
  lea DX,[BufNumb] ; buffer op DS:DX
  INT 0x21       ; roep DOS aan
  JC Close       ; Bij fout proberen te sluiten
  lea SI,[BufNumb]
  CALL StrToDec  ; DS:SI -> EDX
%ENDMACRO

; ------------------------------------------------------------------------------
; WriteCounter - 1999-07-12
; DOEL      : Schrijft EDX naar de 1e regel van FindPDIs.LST
; LEEST     : EDX,(adres) BufNumb,FHandle
; SCHRIJFT  : AX,CX,DX,SI,DI,CF
; ROEPT AAN : DecToStr,MoveFilePointer
; ------------------------------------------------------------------------------
%MACRO WriteCounter 0
  mov BX,FHandle ; Vernietigd door CheckNumber
  mov AL,0       ; Move file pointer to top
  CALL MoveFilePointer
  JC Close       ; Bij fout proberen te sluiten

  mov CX,9       ; aantal bytes
  mov SI,10      ; 10 lang, voorlopende 0
  CALL WriteNum  ; hierna bestand gesloten
%ENDMACRO

; ------------------------------------------------------------------------------
; WritePDI - 1999-07-09
; DOEL : Voegt EDX toe aan FindPDIs.LST
; ------------------------------------------------------------------------------
%MACRO WritePDI 0
  mov BX,FHandle ; Vernietigd door CheckNumber
  mov SI,0       ; eigen lengte
  CALL WriteNum
  JC Close       ; bij fout proberen te sluiten
%ENDMACRO

; ------------------------------------------------------------------------------
; Main - 1999-07-10
; DOEL      : Dit is het hoofdprogramma
; LEEST     : DGroup,AX
; SCHRIJFT  : AX,EDX,DS,CF,ZF,Freq
; ROEPT AAN : GetVidSegment,WipeScreen,OpenFile,CloseFile,MoveFilePointer
; MACRO'S   : ReadCounter,WriteCounter,CheckNumber,WritePDI
; ------------------------------------------------------------------------------
..start:
  mov AX,DGroup ; Zet eigen datasegment in DS op
  mov DS,AX     ; via een GP-register

  CALL GetVidSegment
  CALL WipeScreen
  CALL InitDelay

  CALL OpenFile
  JC Einde      ; Kon het bestand niet openen
  ReadCounter
  mov AL,2      ; File pointer naar einde
  CALL MoveFilePointer
CheckNumb:
  mov AH,0x11   ; 1 cyclus, net als xor
  INT 0x16      ; Check keyboard
  JNZ Abort     ; Geen toets -> ZF=1
  CheckNumber
  JNZ NextNumb  ; Getal is geen PDI
  WritePDI
  mov WORD [Freq],1000 ; Hz
  CALL Sound
  mov CX,500   ; ms wachten
  CALL Delay
  CALL NoSound
NextNumb:
  inc EDX
  JNZ CheckNumb ; 0xFFFFFFFF + 1 = 0
Abort:
  WriteCounter
Close:
  CALL CloseFile
Einde:
  mov AH,0x4C   ; Terminate process DOS Service
  INT 0x21      ; Roep DOS aan

[SEGMENT .data]
GLOBAL FileName
FileName DB 'findpdis.lst',0
CRLF DB 13,10

[SEGMENT .bss]
EXTERN FHandle,Freq
BufNumb RESB 10

[SEGMENT .stack stack]
RESB 1024

GROUP DGroup data bss stack
