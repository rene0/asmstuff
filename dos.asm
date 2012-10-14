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
GLOBAL OpenFile,CloseFile,GetFDaTi,GetParameters,AppendFile,FlushBuf

; ------------------------------------------------------------------------------
; OpenFile - 1998-04-01
; DOEL     : Opent een bestand. In AL komt de foutcode (0=ok), die geldig is
;            als CF=1.
; LEEST    : Adres FileName
; GEBRUIKT : DX
; SCHRIJFT : AX,Flags,FHandle
; ------------------------------------------------------------------------------
OpenFile:

  push DX         ; Bewaar het register

  mov DX,FileName ; Offset FileName in DX
  mov AX,0x3D02   ; Open bestand,read/write
  INT 0x21        ; Roep DOS aan
  mov [FHandle],AX

  pop DX          ; Herstel het register

  RET

; ------------------------------------------------------------------------------
; CloseFile - 1999-06-08
; DOEL     : Sluit een bestand. In AL komt de foutcode (0=ok), die geldig is
;            als CF=1.
; LEEST    : FHandle
; GEBRUIKT : BX
; SCHRIJFT : AX,Flags
; ------------------------------------------------------------------------------
CloseFile:

  push BX         ; Bewaar de registers
  push DX

  mov BX,[FHandle] ; Waarde van openen
  mov AH,0x3E      ; Sluit bestand
  INT 0x21         ; Roep DOS aan

  pop DX          ; Herstel de registers
  pop BX

  RET

; ------------------------------------------------------------------------------
; GetFDaTi - 1999-06-08
; DOEL     : Haalt de datum en tijd van een geopend bestand op.
; LEEST    : FHandle
; GEBRUIKT : BX,CX,DX
; SCHRIJFT : Jaar,Maand,Dag,Uur,Minuut,Seconde,AX,Flags
; ------------------------------------------------------------------------------
GetFDaTi:

  push BX         ; Bewaar de gebruikte registers
  push CX
  push DX

  mov BX,[FHandle]
  mov AX,0x5700    ; Lees datum/tijd van bestand
  INT 0x21         ; Roep DOS aan

  mov BX,DX       ; DX bevat o.a. het jaar
  shr BX,9        ; Delen door 2^9 (512)
  add BX,1980     ; 1980 = eerste jaartal
  mov [Jaar],BX ; In BX staat nu het jaar

  mov BX,DX       ; DX bevat ook de maand
  shr BX,5        ; Delen door 2^5 (32)
  and BX,0x0F      ; Alleen de lage nibble overhouden
  mov [Maand],BL    ; In BL staat nu de maand

  mov BX,DX       ; En DX bevat de maand
  and BX,0x1F      ; Alleen bits 1 t/m 5 overhouden
  mov [Dag],BL      ; In BL staat nu de dag

  mov BX,CX       ; Bereken het uur
  shr BX,11       ; Deel de tijd door 2^11 (=2048)
  mov [Uur],BL      ; In BL staat nu het uur

  mov BX,CX       ; Bereken de minuut
  shr BX,5        ; Deel de tijd door 2^5 (=32)
  and BX,0x3F      ; Alleen bits 1 t/m 6 overhouden
  mov [Minuut],BL   ; In BL staat nu de minuut

  mov BX,CX       ; Bereken de seconde
  and BX,0x1F      ; Alleen bits 1 t/m 5 overhouden
  shl BX,1        ; Vermenigvuldig te tijd met 2^1 (=2)
  mov [Seconde],BL  ; In BL staat nu de seconde

  pop DX          ; Herstel de gebruikte registers
  pop CX
  pop BX

  RET

; ------------------------------------------------------------------------------
; GetParameters - 1999-05-27
; DOEL     : Haalt de parameters op uit de Program Segment Prefix. Bij de
;            aanroep moet de waarde van ES oorspronkelijk zijn, anders wordt er
;            uit een verkeerd stuk geheugen gelezen.
; LEEST    : PSP
; GEBRUIKT : AX,SI,DI,Flags
; SCHRIJFT : Params (in DS),CX
; ------------------------------------------------------------------------------
GetParameters:

  push AX            ; Bewaar de registers
  push SI
  push DI
  pushf              ; Bewaar de Flags

  push DS
  push ES
  pop  DS
  pop  ES

  mov DI,Params ; Offset lokale data
  mov SI,0x81         ; Start parameters
  mov CL,[SI-1] ; Teller, kopieer alleen de ware data
  xor CH,CH          ; Voor de zekerheid
  JCXZ Einde         ; Er zijn geen parameters, dan geen loop (klapt dan om)!

  push CX            ; Bewaar CX,zo kan een programma de lengte zien
  cld                ; Vooruit in geheugen
  REP movsb          ; Kopieer de parameter(s)
  pop CX             ; CX = paramlengte

Einde:
  push DS
  push ES
  pop  DS
  pop  ES

  popf               ; Herstel de Flags
  pop DI             ; Herstel de registers
  pop SI
  pop AX

  RET

; ------------------------------------------------------------------------------
; AppendFile - 1999-06-08
; DOEL      : Opent een bestand en laat de pointer naar het einde wijzen.
;             In AL komt de foutcode (0=ok), die geldig is als CF=1.
; LEEST     : FileName
; GEBRUIKT  : BX,CX,EDX
; SCHRIJFT  : FHandle,FSize,EAX,Flags
; ROEPT AAN : OpenFile
; ------------------------------------------------------------------------------
AppendFile:

  push BX        ; Bewaar de registers
  push CX
  push EDX

  CALL OpenFile
  JC NoAppend    ; Kan het bestand niet openen
  mov EAX,0x4202  ; Naar einde bestand
  mov BX,[FHandle]
  xor CX,CX
  xor EDX,EDX    ; CX:DX = 32-bits offset naar begin toe
  INT 0x21        ; Roep DOS aan, verplaats de pointer
  mov [FSize],EDX
  shl DWORD [FSize],16  ; Naar hoge woord (*65536)
  add [FSize],EAX ; Filesize = DX:AX

NoAppend:
  pop EDX       ; Herstel de registers
  pop CX
  pop BX

  RET

; ------------------------------------------------------------------------------
; FlushBuf - 1998-10-09
; DOEL     : Schrijft een buffer op locatie BufString van BufLen tekens naar
;            een bestand. In AL komt de foutcode (0=ok), die geldig is als CF=1.
; LEEST    : FHandle,BufLen,BufString
; GEBRUIKT : BX,CX,DX
; SCHRIJFT : AX,Flags
; ------------------------------------------------------------------------------
FlushBuf:

  push BX        ; Bewaar de registers
  push CX
  push DX

  mov AH,0x40     ; Schrijf naar een bestand
  mov BX,[FHandle]
  mov CL,[BufLen]
  xor CH,CH      ; Aantal tekens < 256
  mov DX,BufString
  INT 0x21        ; Schrijf CX bytes op DS:DX naar het bestand

  pop DX         ; Herstel de registers
  pop CX
  pop BX
  RET

COMMON FHandle   2
COMMON FSize     4
COMMON Params  128
[SEGMENT .bss]
EXTERN FileName,BufLen,BufString,Jaar,Maand,Dag,Uur,Minuut,Seconde
