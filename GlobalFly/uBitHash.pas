unit uBitHash;

{$mode ObjFPC}{$H+}

interface

uses Classes, SysUtils, Graphics, ogcRegistry;

type

 { TBitHashItem }

 TBitHashItem = class
  Caption: String;
  Bitmap: TBitmap;
  GlyphData: AnsiString;
  Hash: String;
  KeyCode: TShortCut;
  Hint: String;
 //
  SectionName: String;
  constructor Create(Caption_: String; Bitmap_: TBitmap);
  constructor CreateAs(Item_: TBitHashItem);
  destructor Destroy; override;
 end;

 { TBitHashSection }

 TBitHashSection = class(TList)
  SectionName: String;
  private
   function GetItem(Index: Integer): TBitHashItem;
  public
   destructor Destroy; override;
   property Item[Index: Integer]: TBitHashItem read GetItem; default;
 end;

 { TBitHashCollect }

 TBitHashCollect = class(TList)
  private
   function GetSection(Index: Integer): TBitHashSection;
  public
   destructor Destroy; override;
   procedure LoadSettings(Reg: TogsVarRegistry);
   procedure SaveSettings(Reg: TogsVarRegistry);
  //
   function FindHash(Hash: String): Integer;
   function FindItemByHash(const Hash: String): TBitHashItem;
   function FindKeyCode(KeyCode: TShortCut): Integer;
   property Section[Index: Integer]: TBitHashSection read GetSection; default;
 end;

var
 BitHashCollect: TBitHashCollect;

procedure LoadBitHashCollectFromRegFile;
procedure FreeBitHashCollect;

implementation uses ogcProcs, Forms, ogcBasic;


procedure LoadBitHashCollectFromRegFile;
var
 Reg: TogsVarRegistry;
 St: TogsStream;
 RegFile: String;
begin
 if BitHashCollect = nil then
  BitHashCollect := TBitHashCollect.Create;
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
  BitHashCollect.LoadSettings(Reg);
 finally
  Reg.Free;
 end;
end;

procedure FreeBitHashCollect;
begin
 If Assigned(BitHashCollect) then
  FreeAndNil(BitHashCollect);
end;

{ TBitHashItem }

constructor TBitHashItem.Create(Caption_: String; Bitmap_: TBitmap);
begin
 inherited Create;
 Caption := Caption_;
 Bitmap := Bitmap_;
 GlyphData := '';
 Hash := '';
 KeyCode := 0;
 Hint := '';
 SectionName := '';
end;

constructor TBitHashItem.CreateAs(Item_: TBitHashItem);
begin
 inherited Create;
 Caption := Item_.Caption;
 Bitmap := Item_.Bitmap;
 GlyphData := Item_.GlyphData;
 Hash := Item_.Hash;
 KeyCode := Item_.KeyCode;
 Hint := Item_.Hint;
 SectionName := Item_.SectionName;
end;

destructor TBitHashItem.Destroy;
begin
 if Bitmap <> nil then
  Bitmap.Free;
 inherited Destroy;
end;

{ TBitHashSection }

function TBitHashSection.GetItem(Index: Integer): TBitHashItem;
begin
 Result := TBitHashItem(Items[Index]);
end;

destructor TBitHashSection.Destroy;
var
 I: Integer;
begin
 for I := Count - 1 downto 0 do
  TObject(Items[I]).Free;
 inherited Destroy;
end;

{ TBitHashCollect }

function TBitHashCollect.FindHash(Hash: String): Integer;
var
 I, J, K: Integer;
 Sec: TBitHashSection;
 Itm: TBitHashItem;
begin
 K := 0;
 for I := 0 to Count - 1 do begin
  Sec := Section[I];
  if Sec = nil then Continue;
  for J := 0 to Sec.Count - 1 do begin
   Itm := Sec.Item[J];
   if (Itm <> nil) and (Itm.Hash = Hash) then Exit(K);
   Inc(K);
  end;
 end;
 Result := -1;
end;

function TBitHashCollect.FindItemByHash(const Hash: String): TBitHashItem;
var
 I, J: Integer;
 Sec: TBitHashSection;
 Itm: TBitHashItem;
begin
 Result := nil;
 if Hash = '' then Exit;
 for I := 0 to Count - 1 do begin
  Sec := Section[I];
  if Sec = nil then Continue;
  for J := 0 to Sec.Count - 1 do begin
   Itm := Sec.Item[J];
   if (Itm <> nil) and (Itm.Hash = Hash) then Exit(Itm);
  end;
 end;
end;

procedure TBitHashCollect.LoadSettings(Reg: TogsVarRegistry);
var
 Pfx: AnsiString;
 SecCnt: Integer;
 ItemCnt: Integer;
 S, I: Integer;
 SecPfx: AnsiString;
 ItmPfx: AnsiString;
 Sec: TBitHashSection;
 Itm: TBitHashItem;
 Cap: String;
 Hnt: String;
 KeyS: String;
 KeyCodeI: Integer;
 HashS: String;
 GlyphDataS: AnsiString;
 GlyphFileS: String;
 Bmp: TBitmap;
 SC: TShortCut;
begin
 if Reg = nil then Exit;
 // clear existing
 while Count > 0 do begin
  TObject(Items[Count - 1]).Free;
  Delete(Count - 1);
 end;

 Pfx := 'FlyWindows\ShortCuts\';
 SecCnt := Reg.GetInt(Pfx + 'SectionCount', 0);
 for S := 0 to SecCnt - 1 do begin
  Sec := TBitHashSection.Create;
  SecPfx := Pfx + 'Sections\S' + AnsiString(IntToStr(S)) + '\';
  Sec.SectionName := String(Reg.GetStr(SecPfx + 'Name', ''));
  Add(Sec);

  ItemCnt := Reg.GetInt(SecPfx + 'ItemCount', 0);
  for I := 0 to ItemCnt - 1 do begin
   ItmPfx := SecPfx + 'Items\I' + AnsiString(IntToStr(I)) + '\';
   Cap := String(Reg.GetStr(ItmPfx + 'Caption', ''));
   Hnt := String(Reg.GetStr(ItmPfx + 'Hint', ''));
   KeyS := String(Reg.GetStr(ItmPfx + 'Key', ''));
   KeyCodeI := Reg.GetInt(ItmPfx + 'KeyCode', 0);
   HashS := String(Reg.GetStr(ItmPfx + 'Hash', ''));
   GlyphDataS := Reg.GetStr(ItmPfx + 'GlyphData', '');
   GlyphFileS := String(Reg.GetStr(ItmPfx + 'GlyphFile', ''));

   Bmp := nil;
   if GlyphDataS <> '' then begin
    Bmp := TBitmap.Create;
    try
     LoadBitmapFromHex(Bmp, GlyphDataS);
    except
     Bmp.Free;
     Bmp := nil;
    end;
   end else if GlyphFileS <> '' then begin
    Bmp := TBitmap.Create;
    try
     Bmp.LoadFromFile(GlyphFileS);
    except
     Bmp.Free;
     Bmp := nil;
    end;
   end;

   Itm := TBitHashItem.Create(Cap, Bmp);
   Itm.Hint := Hnt;
   SC := 0;
   if KeyCodeI <> 0 then
    SC := TShortCut(KeyCodeI)
   else if KeyS <> '' then begin
    SC := TextToShortCut(KeyS);
   end;
   Itm.KeyCode := SC;
   Itm.Hash := HashS;
   Itm.GlyphData := GlyphDataS;
   Itm.SectionName := Sec.SectionName;
   Sec.Add(Itm);
  end;
 end;
end;

procedure TBitHashCollect.SaveSettings(Reg: TogsVarRegistry);
var
 Pfx: AnsiString;
 S, I: Integer;
 Sec: TBitHashSection;
 Itm: TBitHashItem;
 SecPfx: AnsiString;
 ItmPfx: AnsiString;
begin
 if Reg = nil then Exit;
 Pfx := 'FlyWindows\ShortCuts\';
 Reg.SetInt(Pfx + 'SectionCount', Count);
 for S := 0 to Count - 1 do begin
  Sec := Section[S];
  if Sec = nil then Continue;
  SecPfx := Pfx + 'Sections\S' + AnsiString(IntToStr(S)) + '\';
  Reg.SetStr(SecPfx + 'Name', AnsiString(Sec.SectionName));
  Reg.SetInt(SecPfx + 'ItemCount', Sec.Count);
  for I := 0 to Sec.Count - 1 do begin
   Itm := Sec.Item[I];
   if Itm = nil then Continue;
   ItmPfx := SecPfx + 'Items\I' + AnsiString(IntToStr(I)) + '\';
   Reg.SetStr(ItmPfx + 'Caption', AnsiString(Itm.Caption));
   Reg.SetStr(ItmPfx + 'Hint', AnsiString(Itm.Hint));
   Reg.SetInt(ItmPfx + 'KeyCode', Integer(Itm.KeyCode));
   Reg.SetStr(ItmPfx + 'Key', AnsiString(ShortCutToText(Itm.KeyCode)));
   Reg.SetStr(ItmPfx + 'Hash', AnsiString(Itm.Hash));
   Reg.SetStr(ItmPfx + 'GlyphData', AnsiString(Itm.GlyphData));
  end;
 end;
end;

function TBitHashCollect.FindKeyCode(KeyCode: TShortCut): Integer;
var
 I, J, K: Integer;
 Sec: TBitHashSection;
 Itm: TBitHashItem;
begin
 K := 0;
 for I := 0 to Count - 1 do begin
  Sec := Section[I];
  if Sec = nil then Continue;
  for J := 0 to Sec.Count - 1 do begin
   Itm := Sec.Item[J];
   if (Itm <> nil) and (Itm.KeyCode = KeyCode) then Exit(K);
   Inc(K);
  end;
 end;
 Result := -1;
end;

function TBitHashCollect.GetSection(Index: Integer): TBitHashSection;
begin
 Result := TBitHashSection(Items[Index]);
end;

destructor TBitHashCollect.Destroy;
var
 I: Integer;
begin
 for I := Count - 1 downto 0 do
  TObject(Items[I]).Free;
 inherited Destroy;
end;

end.

