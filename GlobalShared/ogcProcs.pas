unit ogcProcs;

{$mode Delphi}

interface uses feFontEngineObjects, Dialogs, Graphics, Sysutils, Classes, LCLType;

 function AlignText(B: Byte): TFEAlignments;
 function ItalicBold(Bl, It: Boolean): TFEStyles;
//

 function MessageInform(S: String): Word;
 function MessageError(S: String): Word;
 function MessageConfirm(S: String): Word;
//
 function BytesToHex(P: PByte; Cnt: Integer): String;
 function HexToBytes(const Hex: AnsiString): TBytes;
 function HashBitmapRaster(Bmp: TBitmap): String;
 procedure LoadBitmapFromHex(ABmp: TBitmap; const Hex: AnsiString);
 function BitmapToHex(Bmp: TBitmap): AnsiString;
//
 function TextToShortCut(const S: String): TShortCut;
 procedure ShortCutToKey(const ShortCut: TShortCut; out Key: Word; out Shift : TShiftState);
 function ShortCutToText(SC: TShortCut): String;
 function IsAllowedShortCut(SC: TShortCut): Boolean;
 function ParseAllowedShortCut(const S: String; out SC: TShortCut): Boolean;
 function ShortCutFromKey(AKey: Word; AShift: TShiftState; out SC: TShortCut): Boolean;

implementation

function AlignText(B: Byte): TFEAlignments;
begin
 Case B of
  0 : Result:= [ftaLeft, ftaBottom];
  1 : Result:= [ftaLeft, ftaBaseLine];
  2 : Result:= [ftaLeft, ftaVerticalCenter];
  3 : Result:= [ftaLeft, ftaTop];
  4 : Result:= [ftaCenter, ftaBottom];
  5 : Result:= [ftaCenter, ftaBaseLine];
  6 : Result:= [ftaCenter, ftaVerticalCenter];
  7 : Result:= [ftaCenter, ftaTop];
  8 : Result:= [ftaRight, ftaBottom];
  9 : Result:= [ftaRight, ftaBaseLine];
  10: Result:= [ftaRight, ftaVerticalCenter];
  11: Result:= [ftaRight, ftaTop];
 end;
end;

function ItalicBold(Bl, It: Boolean): TFEStyles;
begin
 Result := [];
 If It then Result:= Result + [ftsItalic];
 If Bl then Result:= Result + [ftsBold];
end;

function MessageInform(S: String): Word;
begin
 Result := MessageDlg(S, mtInformation, [mbOk], 0);
end;

function MessageError(S: String): Word;
begin
 Result := MessageDlg(S, mtError, [mbOk], 0);
end;

function MessageConfirm(S: String): Word;
begin
 Result := MessageDlg(S, mtConfirmation, [mbYes, mbNo], 0);
end;

function BytesToHex(P: PByte; Cnt: Integer): String;
const
 Hex: PChar = '0123456789abcdef';
var
 I: Integer;
 B: Byte;
begin
 SetLength(Result, Cnt * 2);
 for I := 0 to Cnt - 1 do begin
  B := P[I];
  Result[I * 2 + 1] := Hex[B shr 4];
  Result[I * 2 + 2] := Hex[B and $0F];
 end;
end;

function HashBitmapRaster(Bmp: TBitmap): String;
var
 P: PByte;
 I, Cnt: Integer;
 H: QWord;
 B: array[0..7] of Byte;
begin
 Result := '';
 if (Bmp = nil) or Bmp.Empty then Exit;
 if (Bmp.RawImage.Data = nil) or (Bmp.RawImage.DataSize <= 0) then Exit;
 P := PByte(Bmp.RawImage.Data);
 Cnt := Bmp.RawImage.DataSize;
 H := $CBF29CE484222325;
 for I := 0 to Cnt - 1 do begin
  H := H xor P[I];
  H := H * $00000100000001B3;
 end;
 B[0] := Byte(H and $FF);
 B[1] := Byte((H shr 8) and $FF);
 B[2] := Byte((H shr 16) and $FF);
 B[3] := Byte((H shr 24) and $FF);
 B[4] := Byte((H shr 32) and $FF);
 B[5] := Byte((H shr 40) and $FF);
 B[6] := Byte((H shr 48) and $FF);
 B[7] := Byte((H shr 56) and $FF);
 Result := BytesToHex(@B[0], 8);
end;

function HexToBytes(const Hex: AnsiString): TBytes;
var
 I, N: Integer;
 V: Byte;
 C: AnsiChar;
begin
 SetLength(Result, 0);
 N := Length(Hex);
 if (N = 0) or ((N and 1) <> 0) then Exit;
 SetLength(Result, N div 2);
 for I := 0 to (N div 2) - 1 do begin
  V := 0;
  C := Hex[I * 2 + 1];
  if (C >= '0') and (C <= '9') then V := (Ord(C) - Ord('0')) shl 4 else
   if (C >= 'a') and (C <= 'f') then V := (Ord(C) - Ord('a') + 10) shl 4 else
    if (C >= 'A') and (C <= 'F') then V := (Ord(C) - Ord('A') + 10) shl 4 else
     Exit;
  C := Hex[I * 2 + 2];
  if (C >= '0') and (C <= '9') then V := V or Byte(Ord(C) - Ord('0')) else
   if (C >= 'a') and (C <= 'f') then V := V or Byte(Ord(C) - Ord('a') + 10) else
    if (C >= 'A') and (C <= 'F') then V := V or Byte(Ord(C) - Ord('A') + 10) else
     Exit;
  Result[I] := V;
 end;
end;

procedure LoadBitmapFromHex(ABmp: TBitmap; const Hex: AnsiString);
var
 B: TBytes;
 MS: TMemoryStream;
begin
 if (ABmp = nil) or (Hex = '') then Exit;
 B := HexToBytes(Hex);
 if Length(B) = 0 then Exit;
 MS := TMemoryStream.Create;
 try
  MS.WriteBuffer(B[0], Length(B));
  MS.Position := 0;
  ABmp.LoadFromStream(MS);
 finally
  MS.Free;
 end;
end;

function BitmapToHex(Bmp: TBitmap): AnsiString;
var
 MS: TMemoryStream;
 P: PByte;
begin
 Result := '';
 if (Bmp = nil) or Bmp.Empty then Exit;
 MS := TMemoryStream.Create;
 try
  Bmp.SaveToStream(MS);
  if MS.Size <= 0 then Exit;
  P := MS.Memory;
  Result := AnsiString(BytesToHex(P, MS.Size));
 finally
  MS.Free;
 end;
end;

function TextToShortCut(const S: String): TShortCut;
var
 T: String;
 Part: String;
 P: Integer;
 KeyS: String;
 Sh: TShiftState;
 K: Word;
 C: Char;
begin
 Result := 0;
 T := Trim(S);
 if T = '' then Exit;
 if Pos('Shift+Ctrl+', T) = 1 then
  T := StringReplace(T, 'Shift+Ctrl+', 'Ctrl+Shift+', [rfReplaceAll]);
 Sh := [];
 KeyS := '';
 while T <> '' do begin
  P := Pos('+', T);
  if P > 0 then begin
   Part := Copy(T, 1, P - 1);
   Delete(T, 1, P);
  end else begin
   Part := T;
   T := '';
  end;
  Part := Trim(Part);
  if Part = '' then Continue;
  if SameText(Part, 'Ctrl') then Include(Sh, ssCtrl) else
   if SameText(Part, 'Shift') then Include(Sh, ssShift) else
    if SameText(Part, 'Alt') then Include(Sh, ssAlt) else
     if SameText(Part, 'Meta') then Include(Sh, ssMeta) else
      KeyS := Part;
 end;
 if (KeyS = '') or (Length(KeyS) <> 1) then Exit;
 C := UpCase(KeyS[1]);
 if not (((C >= 'A') and (C <= 'Z')) or ((C >= '0') and (C <= '9'))) then Exit;
 K := Word(Ord(C));
 Result := LCLType.KeyToShortCut(K, Sh);
end;

procedure ShortCutToKey(const ShortCut: TShortCut; out Key: Word;
  out Shift : TShiftState);
begin
  Key := ShortCut and $FF;
  Shift := [];
  if ShortCut and scShift <> 0 then Include(Shift,ssShift);
  if ShortCut and scAlt <> 0 then Include(Shift,ssAlt);
  if ShortCut and scCtrl <> 0 then Include(Shift,ssCtrl);
  if ShortCut and scMeta <> 0 then Include(Shift,ssMeta);
end;

function ShortCutToText(SC: TShortCut): String;
var
 K: Word;
 Sh: TShiftState;
 C: Char;
begin
 Result := '';
 if SC = 0 then Exit;
 ShortCutToKey(SC, K, Sh);
 if ssShift in Sh then Result := Result + 'Shift+';
 if ssAlt in Sh then Result := Result + 'Alt+';
 if ssCtrl in Sh then Result := Result + 'Ctrl+';
 if ssMeta in Sh then Result := Result + 'Meta+';
 if (K > 0) and (K < 256) then begin
  C := Char(K);
  Result := Result + UpCase(C);
 end;
 if (Length(Result) > 0) and (Result[Length(Result)] = '+') then
  Delete(Result, Length(Result), 1);
end;

function IsAllowedShortCut(SC: TShortCut): Boolean;
var
 K: Word;
 Sh: TShiftState;
 C: Char;
begin
 Result := False;
 if SC = 0 then Exit;
 ShortCutToKey(SC, K, Sh);
 if (ssAlt in Sh) then Exit;
 if (not (ssCtrl in Sh)) and (not (ssShift in Sh)) then Exit;
 C := UpCase(Char(K));
 if ((C >= 'A') and (C <= 'Z')) or ((C >= '0') and (C <= '9')) then
  Result := True;
end;

function ParseAllowedShortCut(const S: String; out SC: TShortCut): Boolean;
begin
 SC := TextToShortCut(Trim(S));
 Result := IsAllowedShortCut(SC);
end;

function ShortCutFromKey(AKey: Word; AShift: TShiftState; out SC: TShortCut): Boolean;
var
 C: Char;
 VK: Word;
begin
 SC := 0;
 Result := False;
 if (ssAlt in AShift) then Exit;
 if (not (ssCtrl in AShift)) and (not (ssShift in AShift)) then Exit;
 C := UpCase(Char(AKey));
 if not (((C >= 'A') and (C <= 'Z')) or ((C >= '0') and (C <= '9'))) then Exit;
 VK := Word(Ord(C));
 SC := LCLType.KeyToShortCut(VK, AShift * [ssShift, ssCtrl]);
 Result := IsAllowedShortCut(SC);
end;

end.

