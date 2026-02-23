unit uFlyControlCreateForm;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Spin, ExtCtrls;

type

 { TFlyControlCreateForm }

 TFlyControlCreateForm = class(TForm)
  btnCancel: TButton;
  btnSelect: TButton;
  btnOK: TButton;
  cbKind: TComboBox;
  ECaption: TEdit;
  EHint: TEdit;
  EName: TEdit;
  ImageGlyph: TImage;
  Label1: TLabel;
  Label6: TLabel;
  Label7: TLabel;
  Label2: TLabel;
  Label3: TLabel;
  Label4: TLabel;
  Label5: TLabel;
  lblGlyphHash: TLabel;
  OpenDialog1: TOpenDialog;
  seW: TSpinEdit;
  seH: TSpinEdit;
  procedure btnGlyphClick(Sender: TObject);
  procedure btnOKClick(Sender: TObject);
  procedure btnSelectClick(Sender: TObject);
  procedure FormCreate(Sender: TObject);
 private
  procedure SetShortCutLock(ALock: Boolean);
 public
  function Execute(var Nm, Cap, Hnt: String; var BtnW, BtnH: Integer; var Kind: Integer;
                   var GlyphData: AnsiString; var GlyphHash: String): Boolean;
 end;

implementation uses uBitHash, FlyShortcuts, ogcProcs;

{$R *.frm}

{ TFlyControlCreateForm }

procedure TFlyControlCreateForm.SetShortCutLock(ALock: Boolean);
begin
 if EName <> nil then
  EName.ReadOnly := ALock;
 if ECaption <> nil then
  ECaption.ReadOnly := ALock;
 if EHint <> nil then
  EHint.ReadOnly := ALock;
 if cbKind <> nil then
  cbKind.Enabled := not ALock;
end;

procedure TFlyControlCreateForm.btnSelectClick(Sender: TObject);
var
 F: TShortCutsForm;
 Itm: TBitHashItem;
 Bmp: TBitmap;
begin
 Sender := Sender;

 if BitHashCollect = nil then
  LoadBitHashCollectFromRegFile;
 if BitHashCollect = nil then Exit;

 F := TShortCutsForm.Create(Self);
 try
  F.Selection := nil;
  If not F.Execute(BitHashCollect) then exit;
  Itm := F.Selection;
  if Itm = nil then Exit;
  if cbKind <> nil then
   cbKind.ItemIndex := 0;
  if seW <> nil then
   seW.Value := 1;
  if seH <> nil then
   seH.Value := 1;

  if ECaption <> nil then
   ECaption.Text := Itm.Caption;
  if EHint <> nil then
   EHint.Text := Itm.Hint;
  if lblGlyphHash <> nil then
   lblGlyphHash.Caption := Itm.Hash;

  if ImageGlyph <> nil then begin
   if Itm.Bitmap <> nil then
    ImageGlyph.Picture.Bitmap.Assign(Itm.Bitmap)
   else if Itm.GlyphData <> '' then begin
    Bmp := TBitmap.Create;
    try
     try
      LoadBitmapFromHex(Bmp, Itm.GlyphData);
      ImageGlyph.Picture.Bitmap.Assign(Bmp);
     except
      ImageGlyph.Picture.Bitmap.Clear;
     end;
    finally
     Bmp.Free;
    end;
   end else
    ImageGlyph.Picture.Bitmap.Clear;
  end;

   SetShortCutLock(True);
 finally
  F.Free;
 end;
end;

procedure TFlyControlCreateForm.btnOKClick(Sender: TObject);
var
 CapName: String;
 K: Integer;
begin
 Sender := Sender;
 CapName := '';
 if ECaption <> nil then
  CapName := Trim(ECaption.Text);
 if CapName = '' then begin
  MessageError('Не задано имя');
  if ECaption <> nil then
   ECaption.SetFocus;
  Exit;
 end;
 if not (CapName[1] in ['A'..'Z', 'a'..'z']) then begin
  MessageError('Имя должно начинаться с английской буквы');
  if ECaption <> nil then
   ECaption.SetFocus;
  Exit;
 end;
 for K := 1 to Length(CapName) do
  if not (CapName[K] in ['A'..'Z', 'a'..'z', '0'..'9', '_']) then begin
   MessageError('Имя должно состоять только из английских символов, цифр или "_"');
   if ECaption <> nil then
    ECaption.SetFocus;
   Exit;
  end;
 ModalResult := mrOk;
end;

procedure TFlyControlCreateForm.btnGlyphClick(Sender: TObject);
var
 Bmp: TBitmap;
 S: String;
begin
 Sender := Sender;
 if OpenDialog1 = nil then Exit;
 if not OpenDialog1.Execute then Exit;
 if ImageGlyph = nil then Exit;

 Bmp := TBitmap.Create;
 try
  Bmp.LoadFromFile(OpenDialog1.FileName);
  ImageGlyph.Picture.Bitmap.Assign(Bmp);
  S := HashBitmapRaster(Bmp);
  if lblGlyphHash <> nil then
   lblGlyphHash.Caption := S;
 finally
  Bmp.Free;
 end;
end;

procedure TFlyControlCreateForm.FormCreate(Sender: TObject);
begin
 if btnSelect <> nil then
  btnSelect.Caption := 'Short-Cut кнопка';
end;

function TFlyControlCreateForm.Execute(var Nm, Cap, Hnt: String; var BtnW, BtnH: Integer;
 var Kind: Integer; var GlyphData: AnsiString; var GlyphHash: String): Boolean;
var
 Bmp: TBitmap;
 S: String;
begin
 if cbKind.Items.Count = 0 then begin
  cbKind.Items.Add('TSpeedButton');
  cbKind.Items.Add('TPanel');
 end;

 SetShortCutLock(False);

 EName.Text := Nm;
 if ECaption <> nil then
  ECaption.Text := Cap;
 if EHint <> nil then
  EHint.Text := Hnt;
 seW.Value := BtnW;
 seH.Value := BtnH;
 if (Kind >= 0) and (Kind < cbKind.Items.Count) then
  cbKind.ItemIndex := Kind
 else
  cbKind.ItemIndex := 0;

 if lblGlyphHash <> nil then
  lblGlyphHash.Caption := GlyphHash;

 if (GlyphData <> '') and (ImageGlyph <> nil) then begin
  Bmp := TBitmap.Create;
  try
   try
    LoadBitmapFromHex(Bmp, GlyphData);
    ImageGlyph.Picture.Bitmap.Assign(Bmp);
    if (lblGlyphHash <> nil) and (lblGlyphHash.Caption = '') then begin
     S := HashBitmapRaster(Bmp);
     lblGlyphHash.Caption := S;
    end;
   except
   end;
  finally
   Bmp.Free;
  end;
 end;

 Result := ShowModal = mrOk;
 if not Result then Exit;

 Nm := EName.Text;
 if ECaption <> nil then
  Cap := ECaption.Text;
 if EHint <> nil then
  Hnt := EHint.Text;
 BtnW := seW.Value;
 BtnH := seH.Value;
 Kind := cbKind.ItemIndex;
 if ImageGlyph <> nil then
  GlyphData := BitmapToHex(ImageGlyph.Picture.Bitmap);
 if lblGlyphHash <> nil then
  GlyphHash := lblGlyphHash.Caption;
end;

end.
