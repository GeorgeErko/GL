unit ogcLType;

{$mode Delphi}

interface

uses ogcBasic, ogcCallbackTypes;

const
 ls_Dinamic1=1;
 ls_Dinamic2=32;
 ls_DblLine=2;
 ls_Solid1=4;
 ls_Solid2=8;
 ls_OrientOn=16;
 ls_OnlyInDot=32;
 ls_ToNext=64;
 ls_ToPred=128;
//
 ZnakDrawMode: Integer = 0;

type
 AllBits = (bt_Line, bt_Arc, bt_Custom);

{ TogsLineStruct }

 { TLineStruct }

 TLineStruct = class(TogsBasic)
  BitOf: AllBits;
  DrawState:SmallInt; 	{флаги для линии}
  Param0 :single;		{смещение dL (1)}
  Param1 :single;		{толщина линии (1)}
  Param2 :single;		{отрезок линии (1)/радиус окружности/угол поворота объекта}
  Param3 :single;		{начальное смещение (0>=..<1)*Param0}
              	        {для 2 линий}
  Param4 :single;		{расстояние м-ду линиями/Номер усл. зн.}
  Param5 :single;		{смещение dL (1)}
  Param6 :single;		{толщина линии (2)}
  Param7 :single;		{отрезок линии (2)}
  Param8 :single;		{начальное смещение (2)}
  lVorign: single;      {поперечное смещение}
  rVOrign: single;      {поперечное смещение}
  Color  : integer;
  bkColor: integer;
 //
  Param4S: AnsiString;  {строковое имя блока из таблицы блоков}
                        {конечное смещение?}
  constructor Create;
  constructor AssignPartOfLineType(PLT: TPartOfLineType);
  constructor Load(Stream: TogsStream); virtual;
  procedure Store(Stream: TogsStream); virtual;
 //
  procedure FillPartOfLineType(var PLT: TPartOfLineType);
  procedure Write;
 end;

 { TGeoLine }

 TGeoLine = class(TogsBasic)
  Structura:TogsCollection;
  NameOf: AnsiString;
  idNum : SmallInt;
  Layer : Pointer;
 //
  Points: TogsCollection;
  constructor Create(Name:String = ''; Id:Integer = -1);
  destructor Destroy; override;
  constructor Load(Stream: TogsStream); virtual;
  procedure Store(Stream: TogsStream); virtual;
 //
  procedure CreatePoints(P:TogsCollection);
 end;

var ZnakNil:Pointer;

implementation uses ogcWriter;

{ TogsLineStruct }

constructor TLineStruct.Create;
begin
 BitOf := bt_Line;
 DrawState := ls_Solid1;
 Param0 := 0;
 Param1 := 0.1;
 Param2 := 0;
 Param3 := 0;
 Param4 := 0;
 Param5 := 0;
 Param6 := 0;
 Param7 := 0;
 Param8 := 0;
 Color  := 0;
 bkColor := 0;
 Param4S := '';
end;

constructor TLineStruct.AssignPartOfLineType(PLT: TPartOfLineType);
begin
 BitOf := AllBits(PLT.BitOf);
 DrawState := PLT.DrawState;
 Param0 := PLT.Param0;
 Param1 := PLT.Param1;
 Param2 := PLT.Param2;
 Param3 := PLT.Param3;
 Param4 := PLT.Param4;
 Param5 := PLT.Param5;
 Param6 := PLT.Param6;
 Param7 := PLT.Param7;
 Param8 := PLT.Param8;
 Color  := PLT.Color;
 bkColor := PLT.bkColor;
 Param4S := PLT.Param4S;
end;

constructor TLineStruct.Load(Stream: TogsStream);
begin
 Stream.Read(BitOf, SizeOf(BitOf));
 Stream.Read(DrawState, SizeOf(DrawState));
 Stream.Read(Param0, SizeOf(Param0));
 Stream.Read(Param1, SizeOf(Param1));
 Stream.Read(Param2, SizeOf(Param2));
 Stream.Read(Param3, SizeOf(Param3));
 Stream.Read(Param4, SizeOf(Param4));
 Stream.Read(Param5, SizeOf(Param5));
 Stream.Read(Param6, SizeOf(Param6));
 Stream.Read(Param7, SizeOf(Param7));
 Stream.Read(Param8, SizeOf(Param8));
 Stream.Read(Color , SizeOf(Color));
 Stream.Read(bkColor, SizeOf(bkColor));
 Stream.ReadString(Param4S);
end;

procedure TLineStruct.Store(Stream: TogsStream);
begin
 Stream.Write(BitOf, SizeOf(BitOf));
 Stream.Write(DrawState, SizeOf(DrawState));
 Stream.Write(Param0, SizeOf(Param0));
 Stream.Write(Param1, SizeOf(Param1));
 Stream.Write(Param2, SizeOf(Param2));
 Stream.Write(Param3, SizeOf(Param3));
 Stream.Write(Param4, SizeOf(Param4));
 Stream.Write(Param5, SizeOf(Param5));
 Stream.Write(Param6, SizeOf(Param6));
 Stream.Write(Param7, SizeOf(Param7));
 Stream.Write(Param8, SizeOf(Param8));
 Stream.Write(Color , SizeOf(Color));
 Stream.Write(bkColor, SizeOf(bkColor));
 Stream.WriteString(Param4S);
end;

procedure TLineStruct.FillPartOfLineType(var PLT: TPartOfLineType);
begin
 PLT.BitOf := ord(BitOf);
 PLT.DrawState := DrawState;
 PLT.Param0 := Param0;
 PLT.Param1 := Param1;
 PLT.Param2 := Param2;
 PLT.Param3 := Param3;
 PLT.Param4 := Param4;
 PLT.Param5 := Param5;
 PLT.Param6 := Param6;
 PLT.Param7 := Param7;
 PLT.Param8 := Param8;
 PLT.Color  := Color;
 PLT.bkColor := bkColor;
 PLT.SetParam4S(Param4S);
end;

procedure TLineStruct.Write;
begin
 WriteIn(['ogcLType.pas']);
 WriteIn(['bitOf', BitOf]);
 WriteIn(['DrawState', DrawState]);
 WriteIn(['Param0', Param0]);
 WriteIn(['Param1', Param1]);
 WriteIn(['Param2', Param2]);
 WriteIn(['Param3', Param3]);
 WriteIn(['Param4', Param4]);
 WriteIn(['Param5', Param5]);
 WriteIn(['Param6', Param6]);
 WriteIn(['Param7', Param7]);
 WriteIn(['Param8', Param8]);
 WriteIn(['Color', Color]);
 WriteIn(['bkColor', bkColor]);
 WriteIn(['Param4S', Param4S]);
end;

{ TGeoLine }

constructor TGeoLine.Create(Name: String; Id: Integer);
begin
 Structura := TogsCollection.Create;
 Points := TogsCollection.Create;
 NameOf := Name;
end;

destructor TGeoLine.Destroy;
begin
 Structura.Free;
 Points.DeleteAll;
 Points.Free;
end;

constructor TGeoLine.Load(Stream: TogsStream);
begin
 Structura := TogsCollection(Stream.Get);
 Stream.ReadString(NameOf);
 Stream.Read(idNum, SizeOf(idNum));
end;

procedure TGeoLine.Store(Stream: TogsStream);
begin
 Stream.Put(Structura);
 Stream.WriteString(NameOf);
 Stream.Write(idNum, SizeOf(idNum));
end;

procedure TGeoLine.CreatePoints(P: TogsCollection);
var I, Index:Integer; PS:TLineStruct;
begin
Points.DeleteAll;
for I:=0 to Structura.Count-1 do begin
 PS:=Structura[I];
  If PS.BitOf = ogcLType.bt_Custom then begin
    // Index:=SearchThis(P,Round(PS.Param4));
   If Index<>-1 then
    Points.Add(P.List[Index]) else
    Points.Add(@ZnakNil);
  end else Points.Add(@ZnakNil);
 end;
end;

end.

