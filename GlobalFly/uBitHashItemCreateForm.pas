unit uBitHashItemCreateForm;

{$mode objfpc}{$H+}

interface

uses Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
     uBitHash, LCLType, Buttons;

type

 { TBitHashItemCreateForm }

 TBitHashItemCreateForm = class(TForm)
  btnCancel: TButton;
  btnGlyph: TButton;
  btnOK: TButton;
  cbGroup: TComboBox;
  ECaption: TEdit;
  EHint: TEdit;
  EHotKey: TEdit;
  ImageGlyph: TImage;
  Label1: TLabel;
  Label2: TLabel;
  Label3: TLabel;
  Label4: TLabel;
  Label5: TLabel;
  lblGlyphHash: TLabel;
  OpenDialog1: TOpenDialog;
  SpeedButton2: TSpeedButton;
  procedure btnGlyphClick(Sender: TObject);
  procedure EHotKeyKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  procedure EHotKeyKeyPress(Sender: TObject; var Key: Char);
  procedure btnOKClick(Sender: TObject);
  procedure FormCreate(Sender: TObject);
 private
  FBHCollect: TBitHashCollect;
  procedure ApplyToVars(var GroupName, Cap, Hnt: String; var KeyCode: TShortCut;
                       var GlyphData: AnsiString; var GlyphHash: String);
  function ValidateInput: Boolean;
 public
  function Execute(BHCollect: TBitHashCollect; var GroupName, Cap, Hnt: String;
                   var KeyCode: TShortCut; var GlyphData: AnsiString;
                   var GlyphHash: String): Boolean;
 end;

implementation

{$R *.frm}

uses ogcProcs, FlyShortcuts;

procedure TBitHashItemCreateForm.btnGlyphClick(Sender: TObject);
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

procedure TBitHashItemCreateForm.FormCreate(Sender: TObject);
begin
 Sender := Sender;
 if btnGlyph <> nil then
  btnGlyph.Caption := '...';
 if EHotKey <> nil then begin
  EHotKey.ReadOnly := True;
  EHotKey.Text := '';
 end;
end;

procedure TBitHashItemCreateForm.EHotKeyKeyDown(Sender: TObject; var Key: Word;
 Shift: TShiftState);
var
 SC: TShortCut;
begin
 Sender := Sender;
 if EHotKey = nil then Exit;
 if (Key = VK_BACK) or (Key = VK_DELETE) then begin
  EHotKey.Text := '';
  Key := 0;
  Exit;
 end;
 if ShortCutFromKey(Key, Shift, SC) then begin
  EHotKey.Text := ShortCutToText(SC);
  Key := 0;
 end;
end;

procedure TBitHashItemCreateForm.EHotKeyKeyPress(Sender: TObject; var Key: Char);
begin
 Sender := Sender;
 Key := #0;
end;

procedure TBitHashItemCreateForm.ApplyToVars(var GroupName, Cap, Hnt: String;
 var KeyCode: TShortCut; var GlyphData: AnsiString; var GlyphHash: String);
var
 Bmp: TBitmap;
begin
 if cbGroup <> nil then
  GroupName := Trim(cbGroup.Text);
 if ECaption <> nil then
  Cap := ECaption.Text;
 if EHint <> nil then
  Hnt := Trim(EHint.Text);
 KeyCode := 0;
 if EHotKey <> nil then
  ParseAllowedShortCut(EHotKey.Text, KeyCode);
 if ImageGlyph <> nil then
  GlyphData := BitmapToHex(ImageGlyph.Picture.Bitmap);
 Bmp := nil;
 if (ImageGlyph <> nil) and (ImageGlyph.Picture <> nil) then
  Bmp := ImageGlyph.Picture.Bitmap;
 GlyphHash := HashBitmapRaster(Bmp);
 if lblGlyphHash <> nil then
  lblGlyphHash.Caption := GlyphHash;
end;

function TBitHashItemCreateForm.ValidateInput: Boolean;
var
 GroupName: String;
 CapName: String;
 Hnt: String;
 SC: TShortCut;
 GlyphHash: String;
 I, J: Integer;
 Sec: TBitHashSection;
 Itm: TBitHashItem;
 Bmp: TBitmap;
 K: Integer;
begin
 Result := False;
 GroupName := '';
 CapName := '';
 Hnt := '';
 if cbGroup <> nil then
  GroupName := Trim(cbGroup.Text);
 if GroupName = '' then begin
  MessageError('Не задана группа');
  Exit;
 end;

 if ECaption <> nil then
  CapName := Trim(ECaption.Text);
 if CapName = '' then begin
  MessageError('Не задано имя');
  Exit;
 end;
 if not (CapName[1] in ['A'..'Z', 'a'..'z']) then begin
  MessageError('Имя должно начинаться с английской буквы');
  Exit;
 end;
 for K := 1 to Length(CapName) do
  if not (CapName[K] in ['A'..'Z', 'a'..'z', '0'..'9', '_']) then begin
   MessageError('Имя должно состоять только из английских символов, цифр или "_"');
   Exit;
  end;

 if EHint <> nil then
  Hnt := Trim(EHint.Text);
 if Hnt = '' then begin
  MessageError('Не задана подсказка');
  Exit;
 end;
 if FBHCollect <> nil then
  for I := 0 to FBHCollect.Count - 1 do begin
   Sec := FBHCollect.Section[I];
   if Sec = nil then Continue;
   for J := 0 to Sec.Count - 1 do begin
    Itm := Sec.Item[J];
    if Itm = nil then Continue;
    if Trim(Itm.Hint) = Hnt then begin
     MessageError('Повтор подсказки');
     Exit;
    end;
   end;
  end;
 SC := 0;
 if EHotKey <> nil then
  if not ParseAllowedShortCut(EHotKey.Text, SC) then begin
   MessageError('Разрешены только Ctrl/Shift + английская буква или цифра');
   Exit;
  end;
 if SC = 0 then begin
  MessageError('Не задана горячая клавиша');
  Exit;
 end;
 if (FBHCollect <> nil) and (SC <> 0) and (FBHCollect.FindKeyCode(SC) <> -1) then begin
  MessageError('Повтор горячей клавиши');
  Exit;
 end;
 if (ImageGlyph = nil) or (ImageGlyph.Picture = nil) or (ImageGlyph.Picture.Bitmap = nil) or ImageGlyph.Picture.Bitmap.Empty then begin
  MessageError('Не задан глиф');
  Exit;
 end;
 Bmp := ImageGlyph.Picture.Bitmap;
 GlyphHash := HashBitmapRaster(Bmp);
 if lblGlyphHash <> nil then
  lblGlyphHash.Caption := GlyphHash;
 if GlyphHash = '' then begin
  MessageError('Не задан глиф');
  Exit;
 end;
 if (FBHCollect <> nil) and (FBHCollect.FindHash(GlyphHash) <> -1) then begin
  MessageError('Повтор глифа');
  Exit;
 end;
 Result := True;
end;

procedure TBitHashItemCreateForm.btnOKClick(Sender: TObject);
begin
 Sender := Sender;
 if not ValidateInput then Exit;
 ModalResult := mrOk;
end;

function TBitHashItemCreateForm.Execute(BHCollect: TBitHashCollect;
 var GroupName, Cap, Hnt: String; var KeyCode: TShortCut;
 var GlyphData: AnsiString; var GlyphHash: String): Boolean;
var
 Bmp: TBitmap;
 I: Integer;
 Sec: TBitHashSection;
begin
 FBHCollect := BHCollect;
 if cbGroup <> nil then begin
  cbGroup.Items.Clear;
  if BHCollect <> nil then
   for I := 0 to BHCollect.Count - 1 do begin
    Sec := BHCollect.Section[I];
    if (Sec = nil) or (Sec.SectionName = '') then Continue;
    if cbGroup.Items.IndexOf(Sec.SectionName) = -1 then
     cbGroup.Items.Add(Sec.SectionName);
   end;
  cbGroup.Text := GroupName;
 end;
 if ECaption <> nil then
  ECaption.Text := Cap;
 if EHint <> nil then
  EHint.Text := Hnt;
 if EHotKey <> nil then
  EHotKey.Text := ShortCutToText(KeyCode);
 if lblGlyphHash <> nil then
  lblGlyphHash.Caption := GlyphHash;
 if (GlyphData <> '') and (ImageGlyph <> nil) then begin
  Bmp := TBitmap.Create;
  try
   try
    LoadBitmapFromHex(Bmp, GlyphData);
    ImageGlyph.Picture.Bitmap.Assign(Bmp);
   except
   end;
  finally
   Bmp.Free;
  end;
 end;
 Result := ShowModal = mrOk;
 if not Result then Exit;
 ApplyToVars(GroupName, Cap, Hnt, KeyCode, GlyphData, GlyphHash);
end;

end.
