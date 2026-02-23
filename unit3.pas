unit Unit3;

{$mode Delphi}

interface

uses Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Unit1,
     ogcBasic, TTFGeometry, feFontEngineObjects;

type

 { TFormTTF }

 TFormTTF = class(TForm1)
  Button6: TButton;
  Edit2: TEdit;
  Edit3: TEdit;
  Label4: TLabel;
  Index: TLabel;
  FontDlg: TOpenDialog;
  procedure Button6Click(Sender: TObject);
  procedure Edit2Change(Sender: TObject);
  procedure Edit3Change(Sender: TObject);
 public
  FontCollect: TFontCollect;
 end;

var
 FormTTF: TFormTTF;

implementation uses ogcWriter, LCLType, lazUTF8;

{$R *.frm}

{ TFormTTF }

procedure TFormTTF.Button6Click(Sender: TObject);
var I: Integer;
begin
// DisableIn;
 ogsFontManager.FreeAll;
 ogsFontManager.LoadFontList(Selector);
 WriteIn([TimeToStr(Now)]);
 For I := 0 to ogsFontManager.Count - 1 do begin
 // ogsFontManager.Item[I].fontCollect.LoadModeComplete;
  WriteIn([TimeToStr(Now)]);
 end;
 exit;
{ FontDlg.InitiAlDir := ExtractFilePath(ParamStr(0));
 WriteIn([FontDlg.InitiAlDir]);
 If FontDlg.Execute then begin
  FontCollect := TFontCollect.Create(Selector, FontDlg.FileName);
  FontCollect.Calculate([calcSquare, calcbBox, calcRelation]);
  Edit2Change(Edit2);
 end;
}
 EnableIn;
end;

procedure TFormTTF.Edit2Change(Sender: TObject);
var
   S: String;
   Ch: UnicodeChar;
   Index: Integer;
   Symbol: TFontSymbol;
   I: Integer;
   uChar: TUTF8Char;
   P: PChar;
   ogsText: TogsTextString;
begin
// DisableIn;
 EnableIn;
 ogsText := TogsTextString.Create(Selector, FontCollect, 0, 0, 0, 10, 0, 1, [], Edit2.Text, '', False);
 ogsText.Calculate([calcbBox]);
 Selector.Clear;
 For I := 0 to ogsText.Count - 1 do begin
  With ogsText.Symbol[I].ogsRect do WriteIn([XMin,YMin,XMAx, YMax]);
  Selector.AddPrim(ogsText.Symbol[I]);
 end;
 WriteIn(['Rect=',Selector.ogsRect.XMin,Selector.ogsRect.YMin,
                     Selector.ogsRect.XMax,Selector.ogsRect.YMax]);
 Prims.DeleteAll;
 Prims.Add(ogsText);
 Selector.UpdateRects(True);
 Button2Click(nil);
 EnableIn;
exit;
//
 If Sender = Edit2 then begin
  If Edit2.Text = '' then exit;
  S := Edit2.Text;
  Ch := S[1];
  Index := Ord(Ch);
  Edit3.Text := IntToStr(Index);
 end else
 If Sender = Edit3 then begin
  If Edit3.Text = '' then exit;
  Index := StrToInt(Edit3.Text);
  Edit2.Text := Chr(Index);
 end;
//
 WriteIn(['Index = ', Index, FontCollect.Count]);
 Symbol := FontCollect.SymbolByIndex(Index) as TFontSymbol;
 Selector.Clear;
 Selector.AddCoord(Symbol.Rect.Left, Symbol.Rect.Top);
 Selector.AddCoord(Symbol.Rect.Right, Symbol.Rect.Bottom);
 Prims.DeleteAll;
 Prims.Add(Symbol);
 Selector.UpdateRects(True);
 Button2Click(nil);
{ проверка на состав мультиполигона из неаскольких полигонов
  With Symbol do begin
  If Count > 1 then begin
   WriteIn(['Poly=',Count, FontCollect.CharIndex(Index)]);
   For I := 0 to Count - 1 do begin
    WriteIn([I, Count,Polygon[I].ClassName]);
    WriteIn(['I=',I,Polygon[I].Square]);
    WriteIn([I, Count]);
   end;
  end;
 end;
}
end;

procedure TFormTTF.Edit3Change(Sender: TObject);
begin

end;

end.

