[SEGMENT .text]
GLOBAL ShowCopy
EXTERN OpenFile,CloseFile,GetFDaTi,PutDaTiString,PrintChar,WriteString
EXTERN LoadChar,WriteBigChar,Delay,SaveCursor,WipeScreen,SetCursor

; ------------------------------------------------------------------------------
; InitLine - 1999-06-08
; DOEL      : Zet de lijntekens in HLine
; SCHRIJFT  : HLine,AX,CX,DI,Flags
; ------------------------------------------------------------------------------
%MACRO InitLine 0
  mov AL,'Í'
  mov DI,HLine
  mov CX,66 ; maximale lengte
  DoFill:
    mov [DI],AL
    inc DI
  LOOP DoFill
%ENDMACRO

; ------------------------------------------------------------------------------
; DrawVerticals - 1999-06-08
; DOEL      : Tekent twee verticale lijnen op XPos,YPos en XPos+CX,YPos van AL
;             tekens hoog
; LEEST     : CL
; GEBRUIKT  : XPos
; SCHRIJFT  : AX,YPos,Flags
; ROEPT AAN : PrintChar
; ------------------------------------------------------------------------------
DrawVerticals:

  DoBars:
    CALL PrintChar ; links
    add [XPos],CL
    CALL PrintChar ; rechts
    sub [XPos],CL
    inc BYTE [YPos]
    dec AX         ; volgende regel
  JNZ DoBars

  RET

; ------------------------------------------------------------------------------
; RetrieveFDaTi - 1999-06-08
; DOEL      : Haalt de datum en tijd van de executable op.
; LEEST     : Adres FileName
; SCHRIJFT  : Jaar,Maand,Dag,Uur,Minuut,Seconde,AX,CX,SI,Flags
; ROEPT AAN : PutDaTiString,OpenFile,CloseFile,GetFDaTi
; ------------------------------------------------------------------------------
%MACRO RetrieveFDaTi 0
  CALL OpenFile       ; DOS wijst nu naar het bestand
  JNC OK              ; Als er geen fout is opgetreden
    mov WORD [Jaar]   ,-1    ; Jaar wordt 'xxxx'
    mov BYTE [Maand]  ,-1
    mov BYTE [Dag]    ,-1
    mov BYTE [Uur]    ,-1
    mov BYTE [Minuut] ,-1
    mov BYTE [Seconde],-1
    JMP SHORT PutFDaTi
  OK:
  CALL GetFDaTi      ; Zet de datum/tijd in Jaar..Seconde
  CALL CloseFile     ; Sluit het bestand

  PutFDaTi:
  CALL PutDaTiString ; Zet de datum en tijd in DaTiStr
%ENDMACRO

; ------------------------------------------------------------------------------
; InitChars - 1999-06-08
; DOEL      : Laad m.b.v. LoadChar de tekens van FileName in PrName in.
; LEEST     : (adres) FileName
; SCHRIJFT  : PrName,PrLen,BX,DX,SI,Flags
; ROEPT AAN : LoadChar
; ------------------------------------------------------------------------------
%MACRO InitChars 0
  mov SI,PrName    ; SI bevat de offset van PrName
  mov DH,'±'       ; Opvulteken
  mov BX,FileName  ; BX bevat de offset van FileName (null-terminated)

  LoadThem:
    mov DL,[BX]    ; laad teken in
    cmp DL,'.'     ; Punt van de extensie tegenkomen?
    JE LoadReady   ; ja
    CALL LoadChar
    inc BX         ; Volgende teken
    inc BYTE [PrLen] ; teken gedaan
  JMP SHORT LoadThem

  LoadReady:
%ENDMACRO

; ------------------------------------------------------------------------------
; DrawFrame - 1999-06-08
; DOEL      : Tekent een blauw kader in het midden van het scherm.
; LEEST     : PrLen,LCopyStr
; SCHRIJFT  : CX,XPos,YPos,Attr,Teken,AX,SI,Flags
; ROEPT AAN : PrintChar,DrawVerticals
; ------------------------------------------------------------------------------
%MACRO DrawFrame 0
  xor CH,CH
  mov CL,[PrLen]    ; lengte programmanaam
  shl CX,3          ; *8, breedte
  cmp CX,38         ; Lang genoeg ?
  JAE LenOK         ; ja
    mov CX,38
  LenOK:
  add CX,2          ; de lijnen zijn 2 langer dan de tekst
  mov BYTE [XPos],80
  sub [XPos],CL     ; -kleinste lengte
  shr BYTE [XPos],1      ; linkse positie kader

  mov SI,HLine
  mov BYTE [Attr],1        ; Donkerblauw-op-zwart
  mov BYTE [YPos],5        ; bovenste regel kader
  CALL WriteString
  mov BYTE [YPos],16       ; middenregel kader
  CALL WriteString
  mov BYTE [YPos],19       ; onderste regel kader
  CALL WriteString

  dec BYTE [XPos]          ; randpositie
  inc CX            ; met randen 1 verder naar rechts
  mov BYTE [Teken],'º'     ; randteken
  mov BYTE [YPos],6        ; eerste deel verticale rand
  mov AX,10         ; aantal regels
  CALL DrawVerticals
  mov BYTE [YPos],17       ; tweede deel verticale rand
  mov AX,2          ; aantal regels
  CALL DrawVerticals

  ; Vul de gaten op :
  mov BYTE [Teken],'É'
  mov BYTE [YPos],5
  CALL PrintChar
  mov BYTE [Teken],'»'
  add [XPos],CL
  CALL PrintChar
  mov BYTE [Teken],'Ì'
  sub [XPos],CL
  mov BYTE [YPos],16
  CALL PrintChar
  mov BYTE [Teken],'¹'
  add [XPos],CL
  CALL PrintChar
  mov BYTE [Teken],'È'
  sub [XPos],CL
  mov BYTE [YPos],19
  CALL PrintChar
  mov BYTE [Teken],'¼'
  add [XPos],CL
  CALL PrintChar
%ENDMACRO

; ------------------------------------------------------------------------------
; DisplayText - 1999-06-23
; DOEL      : Beeld de copyright, de FDaTi en Guide af.
; LEEST     : adres CopyStr,DaTiStr,Guide,CX
; SCHRIJFT  : XPos,YPos,Attr,CX,SI
; ROEPT AAN : WriteString
; ------------------------------------------------------------------------------
%MACRO DisplayText 0
  mov BYTE [Attr],7  ; Grijs-op-zwart
  mov BYTE [XPos],80
  pop WORD [Cursor]  ; Eerst komt de cursor !
  pop CX
  push WORD [Cursor]
  sub [XPos],CL ; lengte Guide
  shr BYTE [XPos],1  ; in midden
  mov BYTE [YPos],23
  mov SI,Guide
  CALL WriteString

  mov BYTE [Attr],4  ; Rood-op-zwart
  mov BYTE [XPos],22 ; 23e positie, de tekst staat altijd op dezelfde plaats !
  mov BYTE [YPos],17 ; Eerste regel onderste kader
  mov SI,CopyStr
  mov CX,38
  CALL WriteString

  mov BYTE [Attr],2  ; Groen-op-zwart
  mov BYTE [XPos],30 ; 31e positie, constant !
  inc BYTE [YPos]    ; Tweede regel
  mov SI,DaTiStr
  mov CX,10
  CALL WriteString
  add BYTE [XPos],11 ; 1 extra naar rechts (11=10+1)
  mov CX,9    ; 1+8
  add SI,10   ; stringpositie klopt
  CALL WriteString
%ENDMACRO

; ------------------------------------------------------------------------------
; DisplayName - 1999-06-08
; DOEL      : Stuurt WriteBigChar aan om binnen dit programma de naam vergroot
;             op het scherm af te beelden (op XPos,YPos).
; LEEST     : (adres) PrName
; SCHRIJFT  : XPos,YPos,Attr,CX,SI,Flags
; ROEPT AAN : WriteBigChar
; ------------------------------------------------------------------------------
%MACRO DisplayName 0
  mov BYTE [Attr],15     ; Wit-op-zwart
  mov CL,[PrLen]
  shl CL,2               ; *4
  mov BYTE [XPos],40
  sub [XPos],CL          ; Tweede kolom grote kader
  mov BYTE [YPos],7      ; Tweede regel grote kader

  mov SI,PrName          ; SI wijst nu naar het 1e teken
  shr CL,2               ; Hersteld
  DispName:
    CALL WriteBigChar
    add BYTE [XPos],8    ; Schuif 1 naar rechts
    add SI,64            ; 1 een verder in de array
  LOOP DispName
%ENDMACRO

; ------------------------------------------------------------------------------
; ShowCopy - 1999-06-23
; DOEL      : Roept de verschillende procedures aan (hoofdroutine).
;             ES moet naar de videobuffer wijzen en LoopsInMs moet gereed zijn.
; GEBRUIKT  : AX,BX,CX,DX,SI,DI,Flags
; SCHRIJFT  : Cursor,Jaar,Maand,Dag,Uur,Minuut,Seconde,XPos,YPos,Attr,Teken,
;             DaTiStr
; ROEPT AAN : RetrieveFDaTi,InitChars,WipeScreen,SaveCursor
;             DrawFrame,DisplayName,DisplayText,Delay,SetCursor
; ------------------------------------------------------------------------------
ShowCopy:

  push AX            ; Bewaar de registers
  push BX
  push CX
  push DX
  push SI
  push DI
  pushf

  CALL WipeScreen    ; Scherm zwart
  push CX            ; Bewaar lengte Guide

  RetrieveFDaTi      ; Zet DaTi van FileName in de string
  InitChars          ; Laad te tekens in (1..8)

  CALL SaveCursor
  push WORD [Cursor]       ; Bewaar de cursor
  mov WORD [Cursor],0x0F00 ; Cursor nu uit
  CALL SetCursor

  InitLine           ; De lijnstring is nu gereed
  DrawFrame          ; Teken het blauwe raamwerk
  DisplayName        ; Zet de witte naam erin
  DisplayText        ; Copyright + FDaTi + Guide

  mov CX,4000        ; ms
  CALL Delay

  CALL WipeScreen
  pop WORD [Cursor] ; Herstel de cursor
  CALL SetCursor

  popf              ; Herstel de registers
  pop DI
  pop SI
  pop DX
  pop CX
  pop BX
  pop AX

  RET

[SEGMENT .data]
EXTERN FileName,Guide,DaTiStr
CopyStr  DB '(c) René Ladan, NetWide Assembler 0.98'
PrLen    DB 0

[SEGMENT .bss]
EXTERN Cursor,XPos,YPos,Attr,Teken,Jaar,Maand,Dag,Uur,Minuut,Seconde
PrName RESB 512 ; opslag vergrote versie FileName
HLine  RESB  66
