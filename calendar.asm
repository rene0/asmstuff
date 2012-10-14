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
GLOBAL LeapYear,LastDay,AddMinute,AddHour,AddDay

; ------------------------------------------------------------------------------
; LeapYear - 1999-05-27
; DOEL     : Test of een jaar een schrikkeljaar is
;            CX=1 als het een schrikkeljaar is of 2 indien 400 jaar, 0 als geen
;            schrikkeljaar als ((jaar %   4 == 0) && (jaar % 100 != 0)) ||
;                               (jaar % 400 == 0)
;
; LEEST    : Jaar
; GEBRUIKT : AX,BX,DX,Flags
; SCHRIJFT : CX
; ------------------------------------------------------------------------------
LeapYear:

  push AX   ; Bewaar de gebruikte registers
  push BX
  push DX
  pushf

  xor CX,CX    ; Geen schrikkeljaar

  xor DX,DX    ; Geen hoge woord
  mov AX,[Jaar]
  mov BX,400   ; Mag niet direct
  div BX       ; AX=Jaar/400, DX = rest
  cmp DX,0     ; Modulo 400 ?
  JNE NoDiv400 ; Nee
  mov CX,2     ; Ja, dus schrikkeljaar
  JMP SHORT EndLeap

NoDiv400:
  mov AX,[Jaar] ; Herladen
  xor DX,DX     ; Geen hoge word
  mov BX,4      ; Mag niet direct
  div BX        ; AX=Jaar/4, DX = rest
  cmp DX,0      ; Modulo 4 ?
  JE TestMod100 ; Ja
  xor CX,CX     ; Nee
  JMP SHORT EndLeap

TestMod100:
  inc CX      ; Deelbaar door 4
  mov AX,[Jaar] ; Herladen
  xor DX,DX   ; Geen hoge word
  mov BX,100  ; Mag niet direct
  div BX      ; AX=Jaar/100, DX = rest
  cmp DX,0    ; Modulo 100 ?
  JNE EndLeap ; Nee
  dec CX      ; Ja, dus geen schrikkeljaar !

EndLeap:
  popf        ; Herstel de Flags
  pop DX      ; en de registers
  pop BX
  pop AX
  RET

; ------------------------------------------------------------------------------
; LastDay - 1999-05-28
; DOEL      : Geeft de laaste dag van een maand terug in een gegeven jaar.
; LEEST     : Maand,DayTabl
; GEBRUIKT  : Flags,SI,CX,BX
; SCHRIJFT  : AX
; ROEPT AAN : LeapYear
; ------------------------------------------------------------------------------
LastDay:

  push BX        ; Bewaar registers
  push CX
  push SI
  pushf

  mov BL,[Maand]
  xor BH,BH      ; Maand in BX
  dec BX         ; Anders wijst hij 1 te ver in de tabel!
  mov SI,DayTabl ; Laad de offset
  mov AL,[SI+BX] ; AL = LastDay, AH = 0

  cmp AX,28      ; Februari?
  JNE NoLeap     ; Nee
  CALL LeapYear  ; Test
  or CX,CX       ; Schrikkeljaar?
  JZ NoLeap      ; Nee
    inc AX       ; AX = 29
  NoLeap:

  popf           ; Herstel registers
  pop SI
  pop CX
  pop BX
  RET

; ------------------------------------------------------------------------------
; AddMinute - 1998-07-11
; DOEL      : Telt 1 minuut bij de dati op.
; GEBRUIKT  : Flags
; SCHRIJFT  : Minuut
; ROEPT AAN : AddHour (evt.)
; ------------------------------------------------------------------------------
AddMinute:

  pushf          ; Bewaar de Flags

  inc BYTE [Minuut] ; Tel 1 bij de minuten op
  cmp BYTE [Minuut],60  ; Overflow ?
  JB NoMinInc    ; Nee
    mov BYTE [Minuut],0 ; Reset
    CALL AddHour ; Tel 1 bij de uren op
  NoMinInc:

  popf           ; Herstel de Flags
  RET

; ------------------------------------------------------------------------------
; AddHour - 1998-07-11
; DOEL      : Telt 1 uur bij de dati op.
; GEBRUIKT  : Flags
; SCHRIJFT  : Uur
; ROEPT AAN : AddDay (evt.)
; ------------------------------------------------------------------------------
AddHour:

  pushf          ; Bewaar de Flags

  inc BYTE [Uur] ; Tel 1 bij de uren op
  cmp BYTE [Uur],24  ; Overflow ?
  JB NoHourInc   ; Nee
    mov BYTE [Uur],0 ; Reset
    CALL AddDay  ; Tel 1 bij de dagen op

  NoHourInc:
  popf           ; Herstel de Flags
  RET

; ------------------------------------------------------------------------------
; AddDay - 1998-07-11
; DOEL      : Telt 1 dag bij de dati op.
; GEBRUIKT  : AX,Flags
; SCHRIJFT  : Dag,WeekDag
; ROEPT AAN : LastDay
; ------------------------------------------------------------------------------
AddDay:

  push AX         ; Bewaar AX
  pushf           ; en de Flags

  inc BYTE [WeekDag] ; Tel 1 bij de weekdagen op
  cmp BYTE [WeekDag],8 ; Overflow ?
  JB IncDay       ; Nee
    mov BYTE [WeekDag],1 ; Reset

  IncDay:
  inc BYTE [Dag]  ; Tel 1 bij de dagen op
  CALL LastDay    ; Laatste dag in AX
  inc AX
  cmp [Dag],AL ; Overflow ?
  JB EndAddDay    ; Nee
    mov BYTE [Dag],1 ; Reset
    inc BYTE [Maand] ; Tel 1 bij de maanden op
    cmp BYTE [Maand],13 ; Overflow ?
    JB EndAddDay  ; Nee
      mov BYTE [Maand],1 ; Reset
      inc WORD [Jaar] ; Tel 1 bij de jaren op (65535 -> 0)

  EndAddDay:
  popf            ; Herstel de Flags
  pop AX          ; en AX
  RET

[SEGMENT .data]
DayTabl DB 31,28,31,30,31,30,31,31,30,31,30,31

[SEGMENT .bss]
EXTERN Jaar,Maand,Dag,WeekDag,Uur,Minuut
