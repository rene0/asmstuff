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

;-------------------------------------------------------------------------------
; ShowDaTi - Programma dat de datum en tijd vergroot laat zien op het scherm.
; (c) René Ladan, 1997-08-28 -- 2000-01-21 NetWide Assembler 0.98
;-------------------------------------------------------------------------------

[SEGMENT .text]
EXTERN SaveCursor,SetCursor,ShowCopy,WriteString,GetDaTi,DecToStr
EXTERN PutDaTiString,NewSec,GetKey,LoadChar,WriteBigChar,GetVidSegment
EXTERN ActKey,InitDelay,Delay,Sound,NoSound

; ------------------------------------------------------------------------------
; InitChars - 1999-07-01
; DOEL      : Leest de gewenste tekens (0..9,-,:) in CharArray in. Het
;             feitelijke uitleeswerk wordt gedaan door LoadChar. ES:DI wordt
;             naar het BIOS-teken-geheugen gezet en later weer hersteld.
; LEEST     : Adres CharArray
; SCHRIJFT  : DX,SI,Flags
; ROEPT AAN : LoadChar
; ------------------------------------------------------------------------------
%MACRO InitChars 0
  lea SI,[CharArray] ; SI bevat de offset van CharArray

  mov DL,'0'      ; Eerste teken = '0'
  xor DH,DH       ; Vul teken op met zichzelf
  LoadThem:
    CALL LoadChar ; Laad het teken wat in DL staat
    inc DX        ; Het volgende teken
    cmp DL,':'    ; Hebben we het laatste teken gedaan?
  JBE LoadThem    ; Nee,terug

  mov DL,'-'    ; Laad de '-', de offset in de string al goed
  CALL LoadChar ; Laad DL
%ENDMACRO

; ------------------------------------------------------------------------------
; DrawBigChar - 1999-07-01
; DOEL      : Stuurt WriteBigChar aan om binnen dit programma een vergroot teken
;             op het scherm af te beelden.
; LEEST     : adres CharArray
; GEBRUIKT  : SI
; SCHRIJFT  : Flags
; ROEPT AAN : WriteBigChar
; ------------------------------------------------------------------------------
DrawBigChar:
  push SI ; Bewaar het register

  cmp SI,BYTE '-'   ; De '-' moet anders berekend worden
  JNE DoBig
    mov SI,';'      ; De '-' heeft offset 11 (12e teken in array)
  DoBig:
  sub SI,BYTE '0'   ; Zet SI om naar arrayindex
  shl SI,6          ; 64=2<<6,bevat nu de index
  add SI,CharArray  ; SI wijst nu naar de arrayindex

  CALL WriteBigChar

  pop SI ; Herstel het register
  RET

; ------------------------------------------------------------------------------
; InitScreen - 1999-07-01.
; DOEL      : Beeldt de weekdagindicatoren en de datum en tijd af.
; LEEST     : WeekDag,(adres) WkDTabl,DaTiStr,LDaTiStr
; SCHRIJFT  : AX,BX,CX,DX,SI,Flags,XPos,YPos,Attr
; ROEPT AAN : WriteString,GetDaTi,PutDaTiString,DrawBigChar
; ------------------------------------------------------------------------------
%MACRO InitScreen 0
  mov BYTE [XPos],75  ; 76e kolom
  mov BYTE [YPos], 4  ;  5e regel
  lea SI,[WkDTabl]    ; Adres WkDTabel in SI
  mov CX,2            ; Alle items zijn 2 tekens lang
  mov DX,1            ; Teller op één
  PrintWeekDag:
    mov BYTE [Attr],2    ; Als het niet deze weekdag is
    cmp [WeekDag],DL
    JNE NotThisWkD       ; Nee, Attr blijft 7
      mov BYTE [Attr],11 ; Als het deze weekdag is
    NotThisWkD:
    CALL WriteString ; Weekdag naar scherm
    add SI,BYTE 2    ; Volgende item in de tabel
    inc BYTE [YPos]  ; Volgende regel
    inc DX           ; Teller verhoogd
    cmp DL,8         ; De laatste gehad?
  JB PrintWeekDag    ; Nee,nog een keer

  lea BX,[DaTiStr]
  add BX,LDaTiStr-1  ; BX wijst nu naar het laatste teken van DaTiStr (seconde)
  mov CX,LDaTiStr    ; De datum/tijd-string is 19 tekens lang
  mov BYTE [YPos],4  ;  5e regel
  mov BYTE [XPos],64 ; 65e kolom naar 72e
  PrintTime:
    mov DL,[BX]
    xor DH,DH            ; Trucje om een bytevariabele in SI te krijgen !
    mov SI,DX            ; SI bevat de ASCII-code van locatie BX
    mov BYTE [Attr],14   ; Kleur geel-op-zwart
    cmp SI,BYTE '-'      ; De - wordt rood-op-zwart
    JNE TestB            ; Geen -
      mov BYTE [Attr],12 ; Pas de kleur aan
    TestB:
    cmp SI,BYTE ':'      ; De : wordt rood-op-zwart
    JNE WriteIt          ; Geen :
      mov BYTE [Attr],12 ; Pas de kleur aan

    WriteIt:
    CALL DrawBigChar     ; Vergroot op scherm
    dec BX               ; 1 naar links in de string
    sub BYTE [XPos],8    ; 8 naar links op het scherm
    cmp CX,12            ; Staan we op de spatie?
    JNE SkipAdjust       ; Nee
      dec BX             ; Anders klopt de index niet
      dec CX             ; Meteen 1 extra naar links
      mov BYTE [YPos],13 ; 14e regel
      mov BYTE [XPos],72 ; 73e kolom naar 80e
    SkipAdjust:
  LOOP PrintTime ; CX-1,CX>0->PrintTime
%ENDMACRO

; ------------------------------------------------------------------------------
; DispWkD - 1999-05-31
; DOEL     : Beeld de gewenste status van de gewenste weekdag af.
;            De status staat in Attr (7=uit,15=aan), het weekdagnummer in CL.
; LEEST    : DI,Attr
; GEBRUIKT : CX
; SCHRIJFT : AX,DI
; ------------------------------------------------------------------------------
DispWkD:
  push CX            ; Bewaar het register

  add CL,3           ; CL wijst naar de Y-positie
  imul AX,CX,160     ; AX = CX*160
  add AX,151         ; Kolomnummer van het attribuut
  mov DI,AX          ; DI wijst naar de goede schermpositie
  mov AL,[Attr]      ; AL bevat de kleurcode
  stosb              ; Verander de kleur
  inc DI             ; Volgende attribuutpositie (al 1 door stosb !)
  stosb              ; Verander de kleur

  pop CX             ; Herstel het register
  RET

; ------------------------------------------------------------------------------
; SetWeekDag - 1999-07-01.
; DOEL      : Zet de weekdagindicatoren goed. Het aan/uitzetten wordt door
;             DispWkD gedaan. SetWeekDag wordt door PrintDaTi aangeroepen.
; LEEST     : WeekDag
; SCHRIJFT  : CX,Flags,Attr
; ROEPT AAN : DispWkD
; ------------------------------------------------------------------------------
%MACRO SetWeekDag 0
  mov CL,[WeekDag]   ; CL bevat het weekdagnummer
  mov BYTE [Attr],11 ; Indicator aan
  CALL DispWkD       ; Zet de indicator aan

  dec CX            ; Vorige weekdag,dec cl = 2 bytes, dec cx 1 !
  JNZ SkipAdj       ; Over aanpassing heen als die niet maandag was
    mov CL,7        ; Anders wordt het dag 7 (zondag)
  SkipAdj:
  mov BYTE [Attr],2 ; Indicator uit
  CALL DispWkD      ; Zet de indicator uit
%ENDMACRO

; ------------------------------------------------------------------------------
; PrintDaTi - 2000-01-21.
; DOEL      : Beeld de datum/tijd-string vergroot op het scherm af.
; LEEST     : adres DaTiStr,LDaTiStr
; SCHRIJFT  : BX,CX,DX,SI,Flags,XPos,YPos
; ROEPT AAN : DrawBigChar
; MACRO'S   : SetWeeKDag
; ------------------------------------------------------------------------------
%MACRO PrintDaTi 0
  mov BYTE [XPos],64 ; 65..72 = seconde
  mov BYTE [YPos], 4 ; 1e regel v/d tijdregels
  lea BX,[DaTiStr]   ; BX wijst naar het 1e teken van DaTiStr
  mov BYTE [StrPos],LDaTiStr-1 ; Initieel

  PrDaTi:
    mov DL,[StrPos]
    xor DH,DH       ; DH is leeg
    mov SI,DX       ; SI wijst nu naar een BYTE in DaTiStr !
    mov DL,[BX+SI]  ; DL bevat de byte waar BX+StrPos naar wijst
    xor DH,DH       ; DH is leeg
    mov SI,DX       ; SI wijst nu naar een BYTE in DaTiStr !

    cmp SI,BYTE '-' ; Is het huidige teken een '-' ?
    JE NoPrint      ; Ja, dan staat het al goed !
    cmp SI,BYTE ':' ; Of een ':' ?
    JE NoPrint      ; Dan staat het ook goed !
    cmp SI,BYTE ' ' ; Of een ' ' ?
    JE NoPrint      ; Dan staat het eveneens goed !
      CALL DrawBigChar
    NoPrint:
    sub BYTE [XPos],8 ; Eén naar links op het scherm

    cmp BYTE [StrPos],11 ; Staan we vóór de spatie?
    JNE NoAdapt          ; Boven/onder -> geen coördinatenaanpassing
      mov BYTE [XPos],80 ; 73..80=dag,later wordt er automatisch 8 van afgetrokken
      mov BYTE [YPos],13 ; 1e regel datumregels
      SetWeekDag         ; Met de dag verandert de weekdag
      mov BYTE [Attr],14 ; SetWeekDag verandert Attr
    NoAdapt:
    dec BYTE [StrPos]    ; 1 terug in DaTiStr

    xor CX,CX           ; Loopvlag op 0
    cmp BYTE [StrPos],5 ; Staan we op de maand?
    JNE TestDay         ; Nee
      cmp SI,BYTE '1'   ; Is de maand 1 ?
      JA TestDay        ; Nee,hoger
      inc CX            ; Blijf in de loop
  TestDay:
    cmp BYTE [StrPos],8 ; Staan we op de dag?
    JNE TestOthers      ; Nee
      cmp SI,BYTE '1'   ; Is de dag 1 ?
      JA TestOthers     ; Nee,hoger
      inc CX            ; Blijf in de loop
  TestOthers:
     cmp SI,BYTE '0' ; Is de waarde 0 ?
     JA Test2        ; Nee,hoger
     inc CX          ; Blijf in de loop
  Test2:
    cmp SI,BYTE '-' ; Of is het een '-' ?
    JNE Test3       ; Nee
    inc CX          ; Anders in loop blijven
  Test3:
    cmp SI,BYTE ':' ; Of een ':' ?
    JNE Test4       ; Nee
    inc CX          ; Anders in loop blijven
  Test4:
    cmp SI,BYTE ' ' ; Of een ' ' ?
    JNE TestIt      ; Nee
    inc CX          ; Anders in loop blijven
  TestIt:
  JCXZ ExitPrint        ; Als 1..9 -> klaar
  JMP PrDaTi            ; Anders nog een keer printen
    cmp BYTE [StrPos],0 ; Is de teller al 0 (daaraan gelijk) ?
  JA NEAR PrDaTi        ; Nee,dan ook printen

  ExitPrint:
%ENDMACRO

; ------------------------------------------------------------------------------
; EmitBeep - 1999-07-01.
; DOEL      : Zendt een piepje van 0,1 seconde uit. De frequentie staat in Freq.
;             Deze is afhankelijk van de datum en tijd berekent.
; LEEST     : Seconde,Minuut,Uur,Dag,Maand
; SCHRIJFT  : CX,Flags,Freq
; ------------------------------------------------------------------------------
%MACRO EmitBeep 0
  mov WORD [Freq],100          ; Nieuwe seconde
  cmp BYTE [Seconde],0
  JA Beep                      ; Geen hele minuut
    mov WORD [Freq],200        ; Nieuwe minuut
    cmp BYTE [Minuut],0
    JA Beep                    ; Geen heel uur
      mov WORD [Freq],300      ; Nieuw uur
      cmp BYTE [Uur],0
      JA Beep                  ; Geen hele dag
        mov WORD [Freq],500    ; Nieuwe dag
        cmp BYTE [Dag],1
        JA Beep                ; Geen hele maand
          mov WORD [Freq],600  ; Nieuwe maand
          cmp BYTE [Maand],1
          JA Beep              ; Geen heel jaar
           mov WORD [Freq],700 ; Nieuw jaar

  Beep:      ; De frequentie is berekend
  CALL Sound
  mov CX,100 ; Wacht 100 ms
  CALL Delay
  CALL NoSound
%ENDMACRO

; ------------------------------------------------------------------------------
; Main - 1999-07-01.
; DOEL      : Dit is het hoofdprogramma.
; LEEST     : DGroup,Seconde,adres Thanx,LThanx,Halted,Status
; SCHRIJFT  : AX,CX,DX,DS,SI,XPos,YPos,Attr
; ROEPT AAN : ShowCopy,GetDaTi,PutDaTiString,ActKey,NewSec,SetCursor,SaveCursor
;             WriteString,ShowFDaTi,GetVidSegment
; MACRO'S   : InitChars,InitScreen,PrintDati,EmitBeep
;-------------------------------------------------------------------------------

..start:
  mov AX,DGroup         ; mov DS,DGroup mag niet
  mov DS,AX             ; DS wijst naar DGroup

  CALL GetVidSegment
  CALL InitDelay
  mov CL,LGuide
  CALL ShowCopy

  CALL SaveCursor    ; Bewaar de oude cursor...
  push WORD [Cursor] ; ...op de stack
  mov WORD [Cursor],0x0F00 ; Startregel=15,eindregel=0 -> geen cursor
  CALL SetCursor     ; ...en zet hem uit

  InitChars          ; Laad de vergrote tekens in die we nodig hebben
  CALL GetDaTi       ; Vraag datum en weekdag en tijd en zet ze in variabelen
  CALL PutDaTiString ; Zet de variabelen in de string
  InitScreen         ; Zet strings en initiële uitvoer op het scherm
  mov BYTE [YPos],3  ; Begin op de 4e regel

  Lus:
    cmp BYTE [Status],0 ; Staat het piepje uit?
    JE WaitSec          ; Ja
      EmitBeep          ; Nee,zendt het piepje uit
  WaitSec:
    CALL NewSec         ; Wacht tot deze seconde voorbij is
  Skip:                 ; Alleen tijdens 1e doorloop gebruikt
    CALL GetDaTi        ; Vraag datum en weekdag en tijd en zet ze in variabelen
    CALL PutDaTiString  ; Zet de variabelen in de string
    PrintDaTi           ; Beeld de datum en tijd vergroot af
    CALL ActKey         ; Wordt er op een toets gedrukt en zoja, welke ?
    cmp BYTE [Halted],1 ; Is er op de Esc gedrukt ?
  JNZ NEAR Lus          ; Nee, verder

  mov BYTE [XPos],0  ;  1e kolom
  mov BYTE [YPos],22 ; 23e regel
  mov BYTE [Attr],7  ; De string in wit-op-zwart
  mov CX,LThanx      ; De lengte in CX
  lea SI,[Thanx]     ; Offset in SI
  CALL WriteString   ; En beeld de string af
  pop WORD [Cursor]  ; Oude cursor hersteld
  CALL SetCursor     ; Zet de cursor weer aan (gaat alleen in monochroom uit)

  mov AX,0x4C00 ; Exit EXE-file,ERRORLEVEL = 0
  INT 0x21      ; Roep DOS aan

[SEGMENT .data]
EXTERN WkDTabl,DaTiStr,Halted,Status
GLOBAL FileName,Guide
FileName DB  'ShowDaTi.EXE',0 ; Voor GetFDaTi/ShowCopy
Guide    DB  'Esc : stop ShowDaTi, Tab : piepje aan/uit'
LGuide   EQU $-Guide
Thanx    DB  'Bedankt voor het gebruiken van ShowDaTi.'
LThanx   EQU $-Thanx
LDaTiStr EQU 19

[SEGMENT .bss]
EXTERN Jaar,Maand,Dag,Uur,Minuut,Seconde,CSec,WeekDag,Attr,Cursor,FHandle
EXTERN Freq,XPos,YPos
StrPos    RESB      1
CharArray RESB 12*8*8 ; bevat BIOS-teken-informatie '0'..':','-'

[SEGMENT .stack stack]
RESB 1024

GROUP DGroup data bss stack
