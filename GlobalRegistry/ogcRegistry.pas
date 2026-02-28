unit ogcRegistry;

{$mode Delphi}{$H+}

interface

uses
  Classes, SysUtils, Graphics, ogcBasic;

type
  TogsRegValueType = (rvtNone, rvtInt, rvtFloat, rvtBool, rvtString, rvtColor);

  TogsRegItem = class
  private
    fKey: AnsiString;
    fValueType: TogsRegValueType;
    fIntValue: Integer;
    fFloatValue: Double;
    fBoolValue: Boolean;
    fStrValue: AnsiString;
    fColorValue: TColor;
  public
    constructor Create(const Key_: AnsiString);

    procedure SetInt(Value: Integer);
    procedure SetFloat(Value: Double);
    procedure SetBool(Value: Boolean);
    procedure SetStr(const Value: AnsiString);
    procedure SetColor(Value: TColor);

    function GetInt(Default: Integer = 0): Integer;
    function GetFloat(Default: Double = 0): Double;
    function GetBool(Default: Boolean = False): Boolean;
    function GetStr(const Default: AnsiString = ''): AnsiString;
    function GetColor(Default: TColor = 0): TColor;

    procedure SaveToStream(Stream: TogsStream);
    class function LoadFromStream(Stream: TogsStream): TogsRegItem;

    property Key: AnsiString read fKey;
    property ValueType: TogsRegValueType read fValueType;
  end;

  TogsVarRegistry = class
  private
    fItems: TStringList;
    function GetCount: Integer;
    function GetItemByIndex(Index: Integer): TogsRegItem;
    function FindIndex(const Key: AnsiString): Integer;
    function RequireItem(const Key: AnsiString): TogsRegItem;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;
    function Exists(const Key: AnsiString): Boolean;
    procedure Delete(const Key: AnsiString);

    function GetItem(const Key: AnsiString): TogsRegItem;
    procedure DeleteByPrefix(const Prefix: AnsiString);

    procedure SetInt(const Key: AnsiString; Value: Integer);
    procedure SetFloat(const Key: AnsiString; Value: Double);
    procedure SetBool(const Key: AnsiString; Value: Boolean);
    procedure SetStr(const Key: AnsiString; const Value: AnsiString);
    procedure SetColor(const Key: AnsiString; Value: TColor);

    function GetInt(const Key: AnsiString; Default: Integer = 0): Integer;
    function GetFloat(const Key: AnsiString; Default: Double = 0): Double;
    function GetBool(const Key: AnsiString; Default: Boolean = False): Boolean;
    function GetStr(const Key: AnsiString; const Default: AnsiString = ''): AnsiString;
    function GetColor(const Key: AnsiString; Default: TColor = 0): TColor;

    procedure EnumSubKeys(const Prefix: AnsiString; List: TStrings);

    procedure SaveToStream(Stream: TogsStream);
    procedure LoadFromStream(Stream: TogsStream);

    procedure SaveToFile(const FileName: String);
    procedure LoadFromFile(const FileName: String);

    property Count: Integer read GetCount;
    property Items[Index: Integer]: TogsRegItem read GetItemByIndex;
  end;

implementation

const
  OGS_REGISTRY_VERSION: Byte = 1;

{ TogsRegItem }

constructor TogsRegItem.Create(const Key_: AnsiString);
begin
  inherited Create;
  fKey := Key_;
  fValueType := rvtNone;
  fIntValue := 0;
  fFloatValue := 0;
  fBoolValue := False;
  fStrValue := '';
  fColorValue := 0;
end;

procedure TogsRegItem.SetInt(Value: Integer);
begin
  fValueType := rvtInt;
  fIntValue := Value;
end;

procedure TogsRegItem.SetFloat(Value: Double);
begin
  fValueType := rvtFloat;
  fFloatValue := Value;
end;

procedure TogsRegItem.SetBool(Value: Boolean);
begin
  fValueType := rvtBool;
  fBoolValue := Value;
end;

procedure TogsRegItem.SetStr(const Value: AnsiString);
begin
  fValueType := rvtString;
  fStrValue := Value;
end;

procedure TogsRegItem.SetColor(Value: TColor);
begin
  fValueType := rvtColor;
  fColorValue := Value;
end;

function TogsRegItem.GetInt(Default: Integer): Integer;
begin
  if fValueType = rvtInt then Result := fIntValue else Result := Default;
end;

function TogsRegItem.GetFloat(Default: Double): Double;
begin
  if fValueType = rvtFloat then Result := fFloatValue else Result := Default;
end;

function TogsRegItem.GetBool(Default: Boolean): Boolean;
begin
  if fValueType = rvtBool then Result := fBoolValue else Result := Default;
end;

function TogsRegItem.GetStr(const Default: AnsiString): AnsiString;
begin
  if fValueType = rvtString then Result := fStrValue else Result := Default;
end;

function TogsRegItem.GetColor(Default: TColor): TColor;
begin
  if fValueType = rvtColor then Result := fColorValue else Result := Default;
end;

procedure TogsRegItem.SaveToStream(Stream: TogsStream);
var
  v: Byte;
  s: AnsiString;
  c: Integer;
begin
  if Stream = nil then Exit;

  s := fKey;
  Stream.WriteString(s);

  v := Ord(fValueType);
  Stream.WriteByte(v);

  case fValueType of
    rvtNone: ;
    rvtInt: Stream.WriteInt(fIntValue);
    rvtFloat: Stream.WriteFloat(fFloatValue);
    rvtBool: begin
      if fBoolValue then Stream.WriteByte(1) else Stream.WriteByte(0);
    end;
    rvtString: begin
      s := fStrValue;
      Stream.WriteString(s);
    end;
    rvtColor: begin
      c := Integer(fColorValue);
      Stream.WriteInt(c);
    end;
  end;
end;

class function TogsRegItem.LoadFromStream(Stream: TogsStream): TogsRegItem;
var
  s: AnsiString;
  vt: Byte;
  b: Byte;
  c: Integer;
  f: Double;
  i: Integer;
begin
  Result := nil;
  if Stream = nil then Exit;

  Stream.ReadString(s);
  Result := TogsRegItem.Create(s);

  vt := Stream.ReadByte;
  if vt > Ord(High(TogsRegValueType)) then vt := Ord(rvtNone);
  Result.fValueType := TogsRegValueType(vt);

  case Result.fValueType of
    rvtNone: ;
    rvtInt: begin
      i := Stream.ReadInt;
      Result.fIntValue := i;
    end;
    rvtFloat: begin
      f := Stream.ReadFloat;
      Result.fFloatValue := f;
    end;
    rvtBool: begin
      b := Stream.ReadByte;
      Result.fBoolValue := b <> 0;
    end;
    rvtString: begin
      Stream.ReadString(s);
      Result.fStrValue := s;
    end;
    rvtColor: begin
      c := Stream.ReadInt;
      Result.fColorValue := TColor(c);
    end;
  end;
end;

{ TogsVarRegistry }

constructor TogsVarRegistry.Create;
begin
  inherited Create;
  fItems := TStringList.Create;
  fItems.Sorted := True;
  fItems.Duplicates := dupIgnore;
end;

destructor TogsVarRegistry.Destroy;
var
  i: Integer;
begin
  if fItems <> nil then
  begin
    for i := 0 to fItems.Count - 1 do
      TObject(fItems.Objects[i]).Free;
    FreeAndNil(fItems);
  end;
  inherited Destroy;
end;

function TogsVarRegistry.GetCount: Integer;
begin
  if fItems <> nil then Result := fItems.Count else Result := 0;
end;

function TogsVarRegistry.GetItemByIndex(Index: Integer): TogsRegItem;
begin
  Result := nil;
  if (fItems = nil) or (Index < 0) or (Index >= fItems.Count) then Exit;
  Result := TogsRegItem(fItems.Objects[Index]);
end;

function TogsVarRegistry.FindIndex(const Key: AnsiString): Integer;
begin
  if fItems = nil then Exit(-1);
  if not fItems.Find(Key, Result) then Result := -1;
end;

function TogsVarRegistry.RequireItem(const Key: AnsiString): TogsRegItem;
var
  idx: Integer;
begin
  idx := FindIndex(Key);
  if idx >= 0 then Exit(TogsRegItem(fItems.Objects[idx]));

  Result := TogsRegItem.Create(Key);
  fItems.AddObject(Key, Result);
end;

procedure TogsVarRegistry.Clear;
var
  i: Integer;
begin
  if fItems = nil then Exit;
  for i := 0 to fItems.Count - 1 do
    TObject(fItems.Objects[i]).Free;
  fItems.Clear;
end;

function TogsVarRegistry.Exists(const Key: AnsiString): Boolean;
begin
  Result := FindIndex(Key) >= 0;
end;

procedure TogsVarRegistry.Delete(const Key: AnsiString);
var
  idx: Integer;
  obj: TObject;
begin
  if fItems = nil then Exit;
  idx := FindIndex(Key);
  if idx < 0 then Exit;
  obj := fItems.Objects[idx];
  fItems.Delete(idx);
  obj.Free;
end;

function TogsVarRegistry.GetItem(const Key: AnsiString): TogsRegItem;
var
  idx: Integer;
begin
  Result := nil;
  idx := FindIndex(Key);
  if idx < 0 then Exit;
  Result := TogsRegItem(fItems.Objects[idx]);
end;

procedure TogsVarRegistry.DeleteByPrefix(const Prefix: AnsiString);
var
  p: String;
  i: Integer;
  key: String;
  obj: TObject;
begin
  if fItems = nil then Exit;
  p := String(Prefix);
  if p = '' then Exit;

  i := fItems.Count - 1;
  while i >= 0 do
  begin
    key := fItems[i];
    if (Length(key) >= Length(p)) and (AnsiCompareText(Copy(key, 1, Length(p)), p) = 0) then
    begin
      obj := fItems.Objects[i];
      fItems.Delete(i);
      obj.Free;
    end;
    Dec(i);
  end;
end;

procedure TogsVarRegistry.SetInt(const Key: AnsiString; Value: Integer);
begin
  RequireItem(Key).SetInt(Value);
end;

procedure TogsVarRegistry.SetFloat(const Key: AnsiString; Value: Double);
begin
  RequireItem(Key).SetFloat(Value);
end;

procedure TogsVarRegistry.SetBool(const Key: AnsiString; Value: Boolean);
begin
  RequireItem(Key).SetBool(Value);
end;

procedure TogsVarRegistry.SetStr(const Key: AnsiString; const Value: AnsiString);
begin
  RequireItem(Key).SetStr(Value);
end;

procedure TogsVarRegistry.SetColor(const Key: AnsiString; Value: TColor);
begin
  RequireItem(Key).SetColor(Value);
end;

function TogsVarRegistry.GetInt(const Key: AnsiString; Default: Integer): Integer;
var
  idx: Integer;
begin
  idx := FindIndex(Key);
  if idx < 0 then Exit(Default);
  Result := TogsRegItem(fItems.Objects[idx]).GetInt(Default);
end;

function TogsVarRegistry.GetFloat(const Key: AnsiString; Default: Double): Double;
var
  idx: Integer;
begin
  idx := FindIndex(Key);
  if idx < 0 then Exit(Default);
  Result := TogsRegItem(fItems.Objects[idx]).GetFloat(Default);
end;

function TogsVarRegistry.GetBool(const Key: AnsiString; Default: Boolean): Boolean;
var
  idx: Integer;
begin
  idx := FindIndex(Key);
  if idx < 0 then Exit(Default);
  Result := TogsRegItem(fItems.Objects[idx]).GetBool(Default);
end;

function TogsVarRegistry.GetStr(const Key: AnsiString; const Default: AnsiString): AnsiString;
var
  idx: Integer;
begin
  idx := FindIndex(Key);
  if idx < 0 then Exit(Default);
  Result := TogsRegItem(fItems.Objects[idx]).GetStr(Default);
end;

procedure TogsVarRegistry.EnumSubKeys(const Prefix: AnsiString; List: TStrings);
var
 I: Integer;
 Key: AnsiString;
 Pfx: AnsiString;
 S: AnsiString;
 J: Integer;
begin
 if (List = nil) or (fItems = nil) then Exit;
 List.Clear;
 Pfx := Prefix;
 if Pfx = '' then Exit;
 for I := 0 to fItems.Count - 1 do begin
  Key := AnsiString(fItems[I]);
  if (Length(Key) < Length(Pfx)) or (AnsiCompareText(Copy(Key, 1, Length(Pfx)), Pfx) <> 0) then Continue;
  S := Copy(Key, Length(Pfx) + 1, Length(Key) - Length(Pfx));
  if S = '' then Continue;
  J := Pos('\', String(S));
  if J <= 0 then Continue;
  S := Copy(S, 1, J - 1);
  if S = '' then Continue;
  if List.IndexOf(String(S)) < 0 then
   List.Add(String(S));
 end;
end;

function TogsVarRegistry.GetColor(const Key: AnsiString; Default: TColor): TColor;
var
  idx: Integer;
begin
  idx := FindIndex(Key);
  if idx < 0 then Exit(Default);
  Result := TogsRegItem(fItems.Objects[idx]).GetColor(Default);
end;

procedure TogsVarRegistry.SaveToStream(Stream: TogsStream);
var
  i: Integer;
  v: Byte;
  cnt: Integer;
begin
  if (Stream = nil) or (fItems = nil) then Exit;

  v := OGS_REGISTRY_VERSION;
  Stream.WriteByte(v);

  cnt := fItems.Count;
  Stream.WriteInt(cnt);

  for i := 0 to fItems.Count - 1 do
    TogsRegItem(fItems.Objects[i]).SaveToStream(Stream);
end;

procedure TogsVarRegistry.LoadFromStream(Stream: TogsStream);
var
  i: Integer;
  cnt: Integer;
  v: Byte;
  item: TogsRegItem;
begin
  if Stream = nil then Exit;

  Clear;

  v := Stream.ReadByte;
  if v <> OGS_REGISTRY_VERSION then
  begin
    cnt := Stream.ReadInt;
    for i := 0 to cnt - 1 do
      TogsRegItem.LoadFromStream(Stream).Free;
    Exit;
  end;

  cnt := Stream.ReadInt;
  for i := 0 to cnt - 1 do
  begin
    item := TogsRegItem.LoadFromStream(Stream);
    if item <> nil then
      fItems.AddObject(item.Key, item);
  end;
end;

procedure TogsVarRegistry.SaveToFile(const FileName: String);
var
  st: TogsStream;
begin
  if FileName = '' then Exit;
  st := TogsStream.CreateFileStream(FileName, fmCreate or fmShareDenyWrite, nil);
  try
    SaveToStream(st);
  finally
    st.Free;
  end;
end;

procedure TogsVarRegistry.LoadFromFile(const FileName: String);
var
  st: TogsStream;
begin
  if FileName = '' then Exit;
  if not FileExists(FileName) then
  begin
    Clear;
    Exit;
  end;

  st := TogsStream.CreateFileStream(FileName, fmOpenRead or fmShareDenyWrite, nil);
  try
    if st.Size > 0 then
      LoadFromStream(st)
    else
      Clear;
  finally
    st.Free;
  end;
end;

end.
