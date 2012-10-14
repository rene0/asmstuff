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
GLOBAL DecToStr,PutDaTiString,LoadChar,StrToDec

; ------------------------------------------------------------------------------
; DecToStr - 1998-04-01.
; DOEL      : Schrijft een teken decimaal naar een string op DS:DI.
;             Het getal wat omgezet moet worden staat in EDX en de lengte in SI.
; GEBRUIKT  : EAX,EBX,CX,EDX,SI,Flags
; SCHRIJFT  : DI
; ------------------------------------------------------------------------------
DecToStr:

  push EAX      ; Bewaar registers op stack
  push EBX
  push  CX
  push EDX
  push  SI
  pushf         ; Bewaar Flags op stack

  mov EAX,EDX   ; EAX wordt gedeeld
  mov EBX,10    ; Deelfactor
  xor  CX, CX   ; Teller 0

NonZero:
  xor EDX,EDX   ; Hoogste dubbelwoord van N = 0, wis de rest
  div EBX       ; Deel EAX (=N) door 10
  push EDX      ; Cijfer, de rest van de deling, op stack
  inc CX        ; Weer een cijfer gedaan
  or EAX,EAX    ; N al 0 ?
JNZ NonZero     ; Nee, terug

  mov DL,'0'    ; Stel dat SI > -1
  cmp SI,-1     ; Is dat wel zo?
  JG SkipAdj    ; Ja
  mov DL,' '    ; Nee
  neg SI        ; En maak SI positief
SkipAdj:
  cmp SI,CX     ; Veldbreedte-cijfers = aantal nullen/spaties?
  JNA PutDigit  ; Er zijn geen voorlopende tekens (CX >= SI)
  sub SI,CX     ; Doe de aftrekking

PutLeadChar:
  mov [DI],DL   ; Plaats het teken in de string
  inc DI        ; Schuif 1 positie op
  dec SI        ; Weer een voorlopend teken gedaan
JNZ PutLeadChar ; Als SI>0

PutDigit:
  pop EDX       ; Cijfer van stack
  add DL,'0'    ; Naar cijfer
  mov [DI],DL   ; Cijfer in de string
  inc DI        ; DI wijst naar het volgende teken in de string
LOOP PutDigit   ; Als CX > 0

  popf          ; Herstel Flags
  pop  SI       ; Registers van stack (herstellen)
  pop EDX
  pop  CX
  pop EBX
  pop EAX

  RET

; ------------------------------------------------------------------------------
; PutDaTiString - 1998-04-04
; DOEL      : Zet de datum- en tijdvariabelen in DaTiStr. De getal-naar-string-
;             omzetting wordt gedaan door DecToStr. Waarden die niet in de
;             string passen worden er als 'x'-en ingezet.
; LEEST     : Jaar,adressen van Maand,Dag,Uur,Minuut,Seconde,DaTiStr
; GEBRUIKT  : EAX,CX,EDX,SI,DI,Flags
; ROEPT AAN : DecToStr
; ------------------------------------------------------------------------------
PutDaTiString:

  push EAX               ; Bewaar de gebruikte registers
  push  CX
  push EDX
  push  SI
  push  DI
  pushf                  ; Bewaar de Flags

  mov DI,DaTiStr         ; SI wijst naar adres DaTiStr
  xor EDX,EDX            ; Wis EDX vooraf
  mov EAX,'xxxx'         ; Opvulwaarde als het niet past

  mov DX,[Jaar]          ; DecToStr gebruikt EDX als invoer
  cmp DX,9999            ; Past het jaar?
  JA NoYear              ; Nee
    mov SI,4             ; 4 tekens breed,voorlopende nul
    CALL DecToStr        ; Zet het getal in de string
    JMP SHORT YearOK     ; Bewaar het jaar
  NoYear:
  mov [DI],EAX           ; Eeuw en jaar = xx
  add DI,4               ; Zorg dat de stringpositie klopt
  YearOK:

  lea SI,[Maand]         ; SI wijst naar de maandgeheugenplaats
  mov CX,5               ; Teller van 5 t/m 1 (maand t/m seconde)
  xor DH,DH              ; We bekijken slechts een byte
  PrLoop:
    inc DI               ; Eén naar rechts in de string (over '-'/' '/':' heen)
    mov DL,[SI]          ; DecToStr heeft zijn invoer in EDX
    cmp DL,99            ; Past de tijdseenheid?
    JA NoPlace           ; Nee
      push SI            ; Bewaar de adrescursor
      mov SI,2           ; 2 tekens breed,voorlopende nul
      CALL DecToStr      ; Zet het getal in de string
      pop SI             ; Herstel de adrescursor
      JMP SHORT DaTiOK   ; Bewaar de tijdseenheid
    NoPlace:
    mov [DI],AX          ; Tijdseenheid = 00
    add DI,2             ; Zorg dat de stringpositie klopt
    DaTiOK:
    inc SI               ; Een byte verder in het geheugen
  LOOP PrLoop            ; Als CX > 0

  popf                   ; Herstel de Flags
  pop  DI                ; Herstel de gebruikte registers
  pop  SI
  pop EDX
  pop  CX
  pop EAX

  RET

; ------------------------------------------------------------------------------
; LoadChar - 1999-05-31
; DOEL     : Leest een teken uit het BIOS-geheugen en zet deze in [SI].
;            De 0-en als spaties en de 1-en als het gewenste teken, waarvan de
;            ASCII-code in DL staat. DH=0 -> teken van DL, DH > 0 -> teken DH
; LEEST    : DX,SI,BIOS-geheugen
; GEBRUIKT : AX,BX,CX,DX,DI,ES,Flags
; SCHRIJFT : SI,[SI]
; ------------------------------------------------------------------------------
LoadChar:

  push AX             ; Bewaar de gebruikte registers
  push BX
  push CX
  push DX
  push DI
  push ES
  pushf               ; Bewaar de Flags

  cmp DL,127          ; Geldig? (De:
  JA EndChar          ; Nee
  mov AL,DL           ; Kopieer ASCII-code in AX
  xor AH,AH           ; Anders klopt DI niet
  shl AX,3            ; Vermenigvuldig die met 8 (2<<3)
  mov DI,0xFA6E       ; Offset teken 0
  add DI,AX           ; DI wijst nu naar teken van DX

  mov AX,0xF000       ; Segment BIOS-teken-informatie
  mov ES,AX           ; Mag niet direct
  or DH,DH            ; Met zichzelf opvullen?
  JA FillOther        ; Nee
    mov DH,DL         ; Ja
  FillOther:

  mov AH,' '          ; Spatie
  xor BX,BX           ; Teller verticaal van 0 naar 8
  LoadIt:
    mov AL,[ES:DI+BX] ; AL bevat tekeninformatie BX/8 (lodsb -> AL=DS:[SI] !)
    mov CX,8          ; Teller horizontaal van 8 naar 0
    ScanIt:
      mov [SI],DH     ; We gaan ervan uit dat bit 8 een 1 is
      test AL,80h     ; Is de bit op de 8e positie wel een 1?
      JNZ IsOne
        mov [SI],AH   ; Nee, een 0 (spatie)
      IsOne:
      shl AL,1        ; Schuif AL 1 naar links (bit 7 => bit 8)
      inc SI          ; Wijst naar volgend teken in de resulterende string
    LOOP ScanIt       ; CX-1, CX>0 -> ScanIt
    inc BX            ; Weer een regel gedaan
    cmp BX,8
  JB LoadIt           ; Nog niet allemaal

  EndChar:
  popf                ; Herstel de Flags
  pop ES              ; Herstel de gebruikte registers
  pop DI
  pop DX
  pop CX
  pop BX
  pop AX

  RET

; ------------------------------------------------------------------------------
; StrToDec - 1998-01-17
; DOEL     : Zet een string die in DS:SI staat om in een geheel getal in EDX.
;            Alleen met '0'..'9' wordt rekening gehouden. In CX staat de lengte
;            van de gehele string.
; LEEST    : [SI]
; GEBRUIKT : AX,CX,SI,Flags
; SCHRIJFT : EDX
; ------------------------------------------------------------------------------
StrToDec:

  push AX       ; Bewaar de registers
  push CX
  push SI       ; Voor lodsb
  pushf

  cld           ; Vooruit in het geheugen
  xor EDX,EDX   ; Resultaat = 0
  DoChar:
    lodsb       ; DS:[SI++] -> AL
    cmp AL,'0'
    JB SkipChar ; Kleiner dan '0'
    cmp AL,'9'
    JA SkipChar ; Groter dan '9'
    imul EDX,10 ; EDX*=10
    sub AL,'0'  ; Maak er een getal van
    add DL,AL   ; Tel het getal (0..9) bij EDX op
    SkipChar:   ; Ongeldig teken
  LOOP DoChar

  popf        ; Herstel de registers
  pop SI
  pop CX
  pop AX

  RET

[SEGMENT .bss]
EXTERN Jaar,Maand,Dag,Uur,Minuut,Seconde,DaTiStr
