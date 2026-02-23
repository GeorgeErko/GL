unit FlyShortcuts;

{$mode ObjFPC}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids, StdCtrls,
 Buttons, Menus, LCLIntf, LCLType,
 ogcRegistry, ogcBasic, ogcProcs, uBitHash;


type
{ TShortCutsForm }
 TShortCutsForm = class(TForm)
  Button1: TButton;
  Button2: TButton;
  Button3: TButton;
  Label1: TLabel;
  sbAdd: TSpeedButton;
  sbDelete: TSpeedButton;
  StringGrid1: TStringGrid;
  procedure Button1Click(Sender: TObject);
  procedure Button2Click(Sender: TObject);
  procedure CancelClick(Sender: TObject);
  procedure sbAddClick(Sender: TObject);
  procedure sbDeleteClick(Sender: TObject);
  procedure SpeedButton1Click(Sender: TObject);
  procedure SpeedButton2Click(Sender: TObject);
  procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  procedure FormCreate(Sender: TObject);
  procedure StringGrid1DrawCell(Sender: TObject; aCol, aRow: Integer;
   aRect: TRect; aState: TGridDrawState);
  procedure StringGrid1KeyDown(Sender: TObject; var Key: Word;
   Shift: TShiftState);
  procedure StringGrid1MouseDown(Sender: TObject; Button: TMouseButton;
   Shift: TShiftState; X, Y: Integer);
  procedure StringGrid1SelectCell(Sender: TObject; aCol, aRow: Integer;
   var CanSelect: Boolean);
 private
  type
   TRowKind = (rkSection, rkItem);
   TRowRec = record
    Kind: TRowKind;
    Section: TBitHashSection;
    Item: TBitHashItem;
   end;
  private
  FRowMap: array of TRowRec;
  function RowRec(ARow: Integer): TRowRec;
  function RowItem(ARow: Integer): TBitHashItem;
  function RowIsSection(ARow: Integer): Boolean;
  function RowSection(ARow: Integer): TBitHashSection;
  procedure RebuildGrid;
 public
  BHCollect: TBitHashCollect;
  Selection: TBitHashItem;
  Modified: boolean;
  function Execute(var BHCollect_: TBitHashCollect): boolean;
 end;

var
 ShortCutsForm: TShortCutsForm;

implementation uses uChildSpeedButtonForm, uBitHashItemCreateForm;

{$R *.frm}

{ TShortCutsForm }

function TShortCutsForm.Execute(var BHCollect_: TBitHashCollect): boolean;
var
 Reg: TogsVarRegistry;
 St: TogsStream;
 RegFile: String;
begin
 BHCollect := BHCollect_;

 RegFile := ExtractFilePath(Application.ExeName) + 'theGrapher.reg';
 Reg := TogsVarRegistry.Create;
 try
  if FileExists(RegFile) then begin
   St := TogsStream.CreateFileStream(RegFile, fmOpenRead or fmShareDenyWrite, nil);
   try
    if St.Size > 0 then
     Reg.LoadFromStream(St);
   finally
    St.Free;
   end;
  end;
  BHCollect.LoadSettings(Reg);
 finally
  Reg.Free;
 end;
 RebuildGrid;
 Result := ShowModal = mrOk;
end;

procedure TShortCutsForm.StringGrid1DrawCell(Sender: TObject; aCol,
 aRow: Integer; aRect: TRect; aState: TGridDrawState);
var
 bRect: TRect;
 S: String;
begin
 Sender := Sender;
 aState := aState;
 if (aRow < 0) or (aRow >= Length(FRowMap)) then Exit;

 if RowIsSection(aRow) then begin
  aRect.Left := 0;
  aRect.Right := StringGrid1.Width - 2;
  StringGrid1.Canvas.Brush.Color := rgb(200, 200, 200);
  StringGrid1.Canvas.FillRect(aRect);
  S := RowSection(aRow).SectionName;
  StringGrid1.Canvas.TextRect(aRect, aRect.Left + 2, aRect.Top + 5, ' Группа: ' + S);
  Exit;
 end;

 if (aCol = 0) and (RowItem(aRow).Bitmap <> nil) then begin
  bRect.Left := 0;
  bRect.Top := 0;
  bRect.Right := RowItem(aRow).Bitmap.Width;
  bRect.Bottom := RowItem(aRow).Bitmap.Height;
  InflateRect(aRect, -3, -2);
  StringGrid1.Canvas.CopyRect(aRect, RowItem(aRow).Bitmap.Canvas, bRect);
 end;

 if aCol = 3 then begin
  InflateRect(aRect, -4, -4);
  StringGrid1.Canvas.Brush.Color := clBtnFace;
  StringGrid1.Canvas.FillRect(aRect);
  StringGrid1.Canvas.TextRect(aRect, aRect.Left + 4, aRect.Top + 2, '...');
 end;
end;

procedure TShortCutsForm.Button2Click(Sender: TObject);
begin
 ModalResult := mrOk;
 Selection := RowItem(StringGrid1.Row);
 if Modified then
  Button1Click(Sender);
end;

procedure TShortCutsForm.CancelClick(Sender: TObject);
begin
 Close;
end;

procedure TShortCutsForm.sbAddClick(Sender: TObject);
begin
 SpeedButton1Click(Sender);
end;

procedure TShortCutsForm.sbDeleteClick(Sender: TObject);
begin
 SpeedButton2Click(Sender);
end;

procedure TShortCutsForm.SpeedButton1Click(Sender: TObject);
var
 Cap: String;
 Hnt: String;
 GlyphData: AnsiString;
 GlyphHash: String;
 Sec: TBitHashSection;
 Itm: TBitHashItem;
 R: TRowRec;
 GroupName: String;
 KeyCode: TShortCut;
 Dlg: TBitHashItemCreateForm;

 function FindSectionByName(const AName: String): TBitHashSection;
 var
  I: Integer;
 begin
  Result := nil;
  if BHCollect = nil then Exit;
  for I := 0 to BHCollect.Count - 1 do
   if (BHCollect.Section[I] <> nil) and (BHCollect.Section[I].SectionName = AName) then
    Exit(BHCollect.Section[I]);
 end;

 function GroupListDelimited: String;
 var
  I: Integer;
 begin
  Result := '';
  if BHCollect = nil then Exit;
  for I := 0 to BHCollect.Count - 1 do begin
  if (BHCollect.Section[I] = nil) or (BHCollect.Section[I].SectionName = '') then Continue;
  if Result <> '' then Result := Result + ';';
  Result := Result + BHCollect.Section[I].SectionName;
 end;
 end;
begin
 Sender := Sender;
 if BHCollect = nil then Exit;

 if Length(FRowMap) > 0 then
  R := RowRec(StringGrid1.Row)
 else
  FillChar(R, SizeOf(R), 0);

 if R.Kind = rkSection then
  Sec := R.Section
 else if R.Kind = rkItem then
  Sec := R.Section
 else
  Sec := nil;

 if Sec = nil then begin
  if BHCollect.Count > 0 then
   Sec := BHCollect.Section[0]
  else
   Sec := nil;
 end;

 Cap := '';
 Hnt := '';
 GlyphData := '';
 GlyphHash := '';
 GroupName := '';
 KeyCode := 0;

 if Sec <> nil then
  GroupName := Sec.SectionName;
 if GroupName = '' then
  GroupName := GroupListDelimited;
 Dlg := TBitHashItemCreateForm.Create(Self);
 try
  if not Dlg.Execute(BHCollect, GroupName, Cap, Hnt, KeyCode, GlyphData, GlyphHash) then Exit;
 finally
  Dlg.Free;
 end;

 GroupName := Trim(GroupName);
 if GroupName = '' then Exit;
 Sec := FindSectionByName(GroupName);
 if Sec = nil then begin
  Sec := TBitHashSection.Create;
  Sec.SectionName := GroupName;
  BHCollect.Add(Sec);
 end;

 Itm := TBitHashItem.Create(Cap, nil);
 Itm.Hash := GlyphHash;
 Itm.GlyphData := GlyphData;
 Itm.Hint := Hnt;
 Itm.KeyCode := KeyCode;
 Itm.SectionName := Sec.SectionName;
 Sec.Add(Itm);

 Modified := True;
 RebuildGrid;
end;

procedure TShortCutsForm.SpeedButton2Click(Sender: TObject);
var
 R: TRowRec;
 Sec: TBitHashSection;
 Itm: TBitHashItem;
 I: Integer;
begin
 Sender := Sender;
 if BHCollect = nil then Exit;
 if (StringGrid1.Row < 0) or (StringGrid1.Row >= Length(FRowMap)) then Exit;

 R := RowRec(StringGrid1.Row);
 if R.Kind = rkSection then begin
  if (R.Section <> nil) and (MessageConfirm('Удалить группу') = mrYes) then begin
   I := BHCollect.IndexOf(R.Section);
   if I >= 0 then
    BHCollect.Delete(I);
   R.Section.Free;
   Modified := True;
   RebuildGrid;
  end;
 end else if R.Kind = rkItem then begin
  Sec := R.Section;
  Itm := R.Item;
  if (Sec <> nil) and (Itm <> nil) and (MessageConfirm('Удалить кнопку') = mrYes) then begin
   I := Sec.IndexOf(Itm);
   if I >= 0 then
    Sec.Delete(I);
   Itm.Free;
   Modified := True;
   RebuildGrid;
  end;
 end;
end;

procedure TShortCutsForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
 CanClose := True;
 If ModalResult = mrCancel then exit;
 If Modified then
  If MessageConfirm('Сохранить изменения') = mrYes then Button1Click(Sender);
end;

procedure TShortCutsForm.FormCreate(Sender: TObject);
begin
 Sender := Sender;
end;

procedure TShortCutsForm.Button1Click(Sender: TObject);
var
 Reg: TogsVarRegistry;
 St: TogsStream;
 RegFile: String;
begin
 if BHCollect = nil then Exit;
 RegFile := ExtractFilePath(Application.ExeName) + 'theGrapher.reg';
 Reg := TogsVarRegistry.Create;
 try
  if FileExists(RegFile) then begin
   St := TogsStream.CreateFileStream(RegFile, fmOpenRead or fmShareDenyWrite, nil);
   try
    if St.Size > 0 then
     Reg.LoadFromStream(St);
   finally
    St.Free;
   end;
  end;
  BHCollect.SaveSettings(Reg);
  St := TogsStream.CreateFileStream(RegFile, fmCreate or fmShareDenyWrite, nil);
  try
   Reg.SaveToStream(St);
  finally
   St.Free;
  end;
 finally
  Reg.Free;
 end;
 Modified := False;
end;

procedure TShortCutsForm.StringGrid1KeyDown(Sender: TObject; var Key: Word;
 Shift: TShiftState);
Function Found(SC: TShortCut): Integer;
var
 R: Integer;
begin
 Result := -1;
 for R := 0 to Length(FRowMap) - 1 do begin
  if FRowMap[R].Kind <> rkItem then Continue;
  if (FRowMap[R].Item <> nil) and (FRowMap[R].Item.KeyCode = SC) then Exit(R);
 end;
end;
var
 SC: TShortCut;
 RowFound: Integer;
begin
 If Key = VK_Escape then Close;
 if RowIsSection(StringGrid1.Row) then Exit;
 If (StringGrid1.Col = 1) and (RowItem(StringGrid1.Row) <> nil) then
  If (Key = 8) then RowItem(StringGrid1.Row).KeyCode := 0;

 if (StringGrid1.Col = 1) and (RowItem(StringGrid1.Row) <> nil) and ShortCutFromKey(Key, Shift, SC) then begin
  RowFound := Found(SC);
  if (RowFound = -1) or (RowFound = StringGrid1.Row) then begin
   StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := ShortCutToText(SC);
   RowItem(StringGrid1.Row).KeyCode := SC;
   Modified := True;
  end else
   MessageError('Повтор: ' + StringGrid1.Cells[StringGrid1.Col, RowFound]);
 end;
end;

procedure TShortCutsForm.StringGrid1SelectCell(Sender: TObject; aCol,
 aRow: Integer; var CanSelect: Boolean);
begin
 Sender := Sender;
 CanSelect := (not RowIsSection(aRow)) and (aCol <> 0);
end;

procedure TShortCutsForm.StringGrid1MouseDown(Sender: TObject;
 Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
 aCol, aRow: Integer;
 R: TRowRec;
 SecSrc: TBitHashSection;
 SecDst: TBitHashSection;
 Itm: TBitHashItem;
 I: Integer;
 GroupName: String;
 Cap: String;
 Hnt: String;
 KeyCode: TShortCut;
 GlyphData: AnsiString;
 GlyphHash: String;
 Dlg: TBitHashItemCreateForm;

function FindSectionByName(const AName: String): TBitHashSection;
var
 I: Integer;
begin
 Result := nil;
 if BHCollect = nil then Exit;
 for I := 0 to BHCollect.Count - 1 do
  if (BHCollect.Section[I] <> nil) and (BHCollect.Section[I].SectionName = AName) then
   Exit(BHCollect.Section[I]);
end;
begin
 Sender := Sender;
 Shift := Shift;
 if StringGrid1 = nil then Exit;
 if Button <> mbLeft then Exit;

 StringGrid1.MouseToCell(X, Y, aCol, aRow);
 if (aCol <> 3) then Exit;
 if BHCollect = nil then Exit;
 if (aRow < 0) or (aRow >= Length(FRowMap)) then Exit;

 R := RowRec(aRow);
 if R.Kind <> rkItem then Exit;
 Itm := R.Item;
 SecSrc := R.Section;
 if (Itm = nil) or (SecSrc = nil) then Exit;

 GroupName := SecSrc.SectionName;
 Cap := Itm.Caption;
 Hnt := Itm.Hint;
 KeyCode := Itm.KeyCode;
 GlyphData := Itm.GlyphData;
 GlyphHash := Itm.Hash;

 I := SecSrc.IndexOf(Itm);
 if I >= 0 then
  SecSrc.Delete(I);

 Dlg := TBitHashItemCreateForm.Create(Self);
 try
  if not Dlg.Execute(BHCollect, GroupName, Cap, Hnt, KeyCode, GlyphData, GlyphHash) then begin
   SecSrc.Add(Itm);
   Exit;
  end;
 finally
  Dlg.Free;
 end;

 GroupName := Trim(GroupName);
 if GroupName = '' then begin
  SecSrc.Add(Itm);
  Exit;
 end;
 SecDst := FindSectionByName(GroupName);
 if SecDst = nil then begin
  SecDst := TBitHashSection.Create;
  SecDst.SectionName := GroupName;
  BHCollect.Add(SecDst);
 end;

 Itm.Caption := Cap;
 Itm.Hint := Hnt;
 Itm.KeyCode := KeyCode;
 Itm.GlyphData := GlyphData;
 Itm.Hash := GlyphHash;
 Itm.SectionName := SecDst.SectionName;
 SecDst.Add(Itm);

 Modified := True;
 RebuildGrid;
end;

function TShortCutsForm.RowItem(ARow: Integer): TBitHashItem;
begin
 Result := nil;
 if (ARow < 0) or (ARow >= Length(FRowMap)) then Exit;
 if FRowMap[ARow].Kind <> rkItem then Exit;
 Result := FRowMap[ARow].Item;
end;

function TShortCutsForm.RowRec(ARow: Integer): TRowRec;
begin
 FillChar(Result, SizeOf(Result), 0);
 if (ARow < 0) or (ARow >= Length(FRowMap)) then Exit;
 Result := FRowMap[ARow];
end;

function TShortCutsForm.RowIsSection(ARow: Integer): Boolean;
begin
 Result := (ARow >= 0) and (ARow < Length(FRowMap)) and (FRowMap[ARow].Kind = rkSection);
end;

function TShortCutsForm.RowSection(ARow: Integer): TBitHashSection;
begin
 Result := nil;
 if (ARow < 0) or (ARow >= Length(FRowMap)) then Exit;
 Result := FRowMap[ARow].Section;
end;

procedure TShortCutsForm.RebuildGrid;
var
 I, J, Row, TotalRows: Integer;
 Sec: TBitHashSection;
 Itm: TBitHashItem;
begin
 if BHCollect = nil then Exit;

 TotalRows := 0;
 for I := 0 to BHCollect.Count - 1 do begin
  Sec := BHCollect.Section[I];
  Inc(TotalRows);
  if Sec <> nil then
   Inc(TotalRows, Sec.Count);
 end;

 SetLength(FRowMap, TotalRows);
 Row := 0;
 for I := 0 to BHCollect.Count - 1 do begin
  Sec := BHCollect.Section[I];
  FRowMap[Row].Kind := rkSection;
  FRowMap[Row].Section := Sec;
  FRowMap[Row].Item := nil;
  Inc(Row);
  if Sec = nil then Continue;
  for J := 0 to Sec.Count - 1 do begin
   Itm := Sec.Item[J];
   FRowMap[Row].Kind := rkItem;
   FRowMap[Row].Section := Sec;
   FRowMap[Row].Item := Itm;
   Inc(Row);
  end;
 end;

 StringGrid1.RowCount := Length(FRowMap);
 for Row := 0 to Length(FRowMap) - 1 do begin
  if FRowMap[Row].Kind = rkSection then begin
   StringGrid1.Cells[0, Row] := '';
   StringGrid1.Cells[1, Row] := '';
   StringGrid1.Cells[2, Row] := '';
   StringGrid1.Cells[3, Row] := '';
  end else begin
   StringGrid1.Cells[1, Row] := ShortCutToText(FRowMap[Row].Item.KeyCode);
   StringGrid1.Cells[2, Row] := FRowMap[Row].Item.Hint;
   StringGrid1.Cells[3, Row] := '';
  end;
 end;
end;

end.

