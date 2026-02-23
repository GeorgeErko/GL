program EDFReader;

{$mode objfpc}{$H+}

uses
 {$IFDEF UNIX}
 cthreads,
 {$ENDIF}
 Classes, SysUtils, Math;

type
 TEDFFixedHeader = record
  Version: AnsiString;
  Patient: AnsiString;
  Recording: AnsiString;
  StartDate: AnsiString;
  StartTime: AnsiString;
  HeaderBytes: Integer;
  NumRecords: Integer;
  RecordDuration: Double;
  NS: Integer;
 end;

function ReadAscii(const FS: TFileStream; const Count: Integer): AnsiString;
var
 Buf: array of Byte;
begin
 SetLength(Buf, Count);
 if Count > 0 then
  FS.ReadBuffer(Buf[0], Count);
 SetString(Result, PAnsiChar(@Buf[0]), Count);
end;

function ReadAsciiAt(const FS: TFileStream; const Pos: Int64; const Count: Integer): AnsiString;
begin
 FS.Position := Pos;
 Result := ReadAscii(FS, Count);
end;

function Field(const S: AnsiString; const Offset0, Len: Integer): AnsiString;
begin
 Result := TrimRight(Copy(S, Offset0 + 1, Len));
end;

function ParseIntField(const S: AnsiString): Integer;
var
 T: AnsiString;
begin
 T := Trim(S);
 if T = '' then
  Result := 0
 else
  Result := StrToInt(string(T));
end;

function ParseFloatField(const S: AnsiString): Double;
var
 T: AnsiString;
begin
 T := Trim(S);
 if T = '' then
  Result := 0
 else
  Result := StrToFloat(string(T), DefaultFormatSettings);
end;

procedure ReadFixedHeader(const FS: TFileStream; out H: TEDFFixedHeader);
var
 Hdr: AnsiString;
begin
 Hdr := ReadAsciiAt(FS, 0, 256);
 H.Version := Field(Hdr, 0, 8);
 H.Patient := Field(Hdr, 8, 80);
 H.Recording := Field(Hdr, 88, 80);
 H.StartDate := Field(Hdr, 168, 8);
 H.StartTime := Field(Hdr, 176, 8);
 H.HeaderBytes := ParseIntField(Field(Hdr, 184, 8));
 H.NumRecords := ParseIntField(Field(Hdr, 236, 8));
 H.RecordDuration := ParseFloatField(Field(Hdr, 244, 8));
 H.NS := ParseIntField(Field(Hdr, 252, 4));
end;

procedure ReadChannelLabels(const FS: TFileStream; const NS: Integer; out Labels: TStringArray);
var
 Buf: AnsiString;
 I: Integer;
begin
 SetLength(Labels, NS);
 Buf := ReadAsciiAt(FS, 256, 16 * NS);
 for I := 0 to NS - 1 do
  Labels[I] := string(TrimRight(Copy(Buf, I * 16 + 1, 16)));
end;

procedure ReadSamplesPerRecord(const FS: TFileStream; const NS: Integer; out SPR: array of Integer);
var
 PosSamples: Int64;
 Buf: AnsiString;
 I: Integer;
begin
 PosSamples := 256 + Int64(224) * NS;
 Buf := ReadAsciiAt(FS, PosSamples, 8 * NS);
 for I := 0 to NS - 1 do
  SPR[I] := ParseIntField(Copy(Buf, I * 8 + 1, 8));
end;

function AllEqual(const A: array of Integer): Boolean;
var
 I: Integer;
begin
 if Length(A) <= 1 then
  Exit(True);
 for I := Low(A) + 1 to High(A) do
  if A[I] <> A[Low(A)] then
   Exit(False);
 Result := True;
end;

function MaxIntArray(const A: array of Integer): Integer;
var
 I: Integer;
begin
 Result := 0;
 for I := Low(A) to High(A) do
  if A[I] > Result then
   Result := A[I];
end;

function CsvEscape(const S: string): string;
begin
 if (Pos(',', S) > 0) or (Pos('"', S) > 0) or (Pos(#10, S) > 0) or (Pos(#13, S) > 0) then
  Result := '"' + StringReplace(S, '"', '""', [rfReplaceAll]) + '"'
 else
  Result := S;
end;

procedure WriteLine(var F: TextFile; const S: string);
begin
 System.WriteLn(F, S);
end;

procedure ExportCsvFirstSecondsRawInt16(const InputPath, OutputPath: string; const Seconds: Double);
var
 FS: TFileStream;
 H: TEDFFixedHeader;
 Labels: TStringArray;
 SPR: array of Integer;
 SumSPR: Integer;
 BytesPerRecord: Integer;
 RecordsToRead: Integer;
 NeedSamples: Integer;
 BaseFs: Double;
 MaxSPR: Integer;
 Buf: array of Byte;
 ChData: array of array of SmallInt;
 Ch, I, K, RecIdx, SampleIndex: Integer;
 P: PSmallInt;
 T: Double;
 F: TextFile;
 FSSettings: TFormatSettings;
 S: string;
begin
 FSSettings := DefaultFormatSettings;
 FSSettings.DecimalSeparator := '.';

 FS := TFileStream.Create(InputPath, fmOpenRead or fmShareDenyNone);
 try
  ReadFixedHeader(FS, H);
  if H.NS <= 0 then
   raise Exception.Create('NS <= 0');

  ReadChannelLabels(FS, H.NS, Labels);
  SetLength(SPR, H.NS);
  ReadSamplesPerRecord(FS, H.NS, SPR);

  if H.RecordDuration <= 0 then
   raise Exception.Create('RecordDuration <= 0');

  MaxSPR := MaxIntArray(SPR);
  BaseFs := MaxSPR / H.RecordDuration;
  NeedSamples := Floor(Seconds * BaseFs);
  if NeedSamples <= 0 then
   NeedSamples := 1;

  RecordsToRead := Ceil(Seconds / H.RecordDuration);
  if RecordsToRead < 1 then
   RecordsToRead := 1;
  if (H.NumRecords > 0) and (RecordsToRead > H.NumRecords) then
   RecordsToRead := H.NumRecords;

  SumSPR := 0;
  for I := 0 to H.NS - 1 do
   SumSPR += SPR[I];
  BytesPerRecord := 2 * SumSPR;
  SetLength(Buf, BytesPerRecord);

  AssignFile(F, OutputPath);
  Rewrite(F);
  try
   WriteLine(F, 'version,' + CsvEscape(string(H.Version)));
   WriteLine(F, 'patient,' + CsvEscape(string(H.Patient)));
   WriteLine(F, 'recording,' + CsvEscape(string(H.Recording)));
   WriteLine(F, 'startdate,' + CsvEscape(string(H.StartDate)));
   WriteLine(F, 'starttime,' + CsvEscape(string(H.StartTime)));
   WriteLine(F, 'headerBytes,' + IntToStr(H.HeaderBytes));
   WriteLine(F, 'numRecords,' + IntToStr(H.NumRecords));
   WriteLine(F, 'recordDuration,' + FloatToStr(H.RecordDuration, FSSettings));
   WriteLine(F, 'ns,' + IntToStr(H.NS));
   WriteLine(F, 'totalSeconds,' + FloatToStr(H.NumRecords * H.RecordDuration, FSSettings));
   WriteLine(F, '');

   WriteLine(F, 'idx,label,samplesPerRecord,fsHz');
   for I := 0 to H.NS - 1 do
    WriteLine(F, IntToStr(I + 1) + ',' + CsvEscape(Labels[I]) + ',' + IntToStr(SPR[I]) + ',' + FloatToStr(SPR[I] / H.RecordDuration, FSSettings));
   WriteLine(F, '');

   S := 't';
   for I := 0 to H.NS - 1 do
    S += ',' + CsvEscape(Labels[I]);
   WriteLine(F, S);

   SetLength(ChData, H.NS);
   FS.Position := H.HeaderBytes;

   SampleIndex := 0;
   for RecIdx := 0 to RecordsToRead - 1 do
   begin
    if SampleIndex >= NeedSamples then
     Break;
    if FS.Read(Buf[0], BytesPerRecord) <> BytesPerRecord then
     Break;

    for Ch := 0 to H.NS - 1 do
     SetLength(ChData[Ch], SPR[Ch]);

    P := PSmallInt(@Buf[0]);
    for Ch := 0 to H.NS - 1 do
     for K := 0 to SPR[Ch] - 1 do
     begin
      ChData[Ch][K] := P^;
      Inc(P);
     end;

    for I := 0 to MaxSPR - 1 do
    begin
     if SampleIndex >= NeedSamples then
      Break;
     T := SampleIndex / BaseFs;
     S := FloatToStr(T, FSSettings);
     for Ch := 0 to H.NS - 1 do
     begin
      S += ',';
      if I < Length(ChData[Ch]) then
       S += IntToStr(ChData[Ch][I]);
     end;
     WriteLine(F, S);
     Inc(SampleIndex);
    end;
   end;
  finally
   CloseFile(F);
  end;
 finally
  FS.Free;
 end;
end;

procedure PrintUsage;
begin
 WriteLn('Usage: EDFReader <input.edf> [output.csv]');
end;

begin
 if ParamCount < 1 then
 begin
  PrintUsage;
  Halt(2);
 end;

 if ParamCount >= 2 then
  ExportCsvFirstSecondsRawInt16(ParamStr(1), ParamStr(2), 5)
 else
  ExportCsvFirstSecondsRawInt16(ParamStr(1), ChangeFileExt(ParamStr(1), '') + '_first5s_raw.csv', 5);
end.

