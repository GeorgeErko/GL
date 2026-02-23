unit dwgtext;

interface
Uses Collect, SysUtils, Polygons,
     Circle_di, Graphics, newFontScale, Types_Dimano, TwgDraw, newResource, newSelector
     {$IFDEF UNIX},LCLType{$ELSE},Windows{$ENDIF};

const
    pointDrawText:boolean=True;

type
  TVarType = (ttString, ttInt, ttFloat, tt_Number, tt_Z, tt_X, tt_Y);
  TVarTypeSet = Set of TVarType;

type
  TFontManager = class(PCollection)
    function AddFont(DC:hDc; fntName:AnsiString; H,W :Double; CharSet: Byte; bl1, it1, un1 :Integer; fS:Integer=10): integer;
  end;

  { TDWG_Text }

  TDWG_Text = class(TTD)
    FX, FY: single;
    FName: AnsiString;
    FText: AnsiString;
    FFntName:AnsiString;
    FCharSet: Byte;
    FBl :Integer;
    Fit :Integer;
    FUn :Integer;
    FScale:Integer;
    FColor: Integer;
    FFontIndex: integer;
    FAng: single;
    FWidth, FHeight: single;
    {}
    Active:Byte;
    XF,YF,X2,Y2,DX,DY,Ugol1,XFOld,YFOld:Double;
   {}
    FVisible: boolean;
    FBg: boolean;
    FBgColor: Integer;
   {}
    FVarType: TVarType;
    FTextAlignX, FTextAlignY: single;
    oldFontIndex: integer;
    FParams: array[0..127 - 5 - 8 - sizeof(TVarType)] of byte;
   {}
    ShiftX,ShiftY:SmallInt;
   {}
    constructor Create(x, y: single; DC:hDc; const txt, fntName:AnsiString; H, W :single;
          CharSet: Byte; bl1, it1, un1 :Integer; fS:Integer=10);
    constructor Load(st: TBufStream); override;
    procedure Store(st: TbufStream); override;
    destructor Destroy; override;
//    function GetParams(MXX,MYY,ko,Ugol,X1,Y1:Double;ItsTest:Integer):TFontViewEx;
    function PointIn(x, y: single): double;
    function PointInPoint(x, y: single; var dist: single): integer;
    procedure SetFont(DC:hDc; const fntName:AnsiString; H,W :Double;
          CharSet: Byte; bl1, it1, un1 :Integer; fS:Integer=10);
    function YMin:Double;
    function XMin:Double;
    function FH(C:Char):Double;
   {}
    function GetFV: TFontViewEx;
   {}
    Procedure SetGabarites(MRect_:TMRect);override;
    Procedure SetGabaritesBlock(MRect_:TMRect;X,Y,kX,kY,Angle:Double);override;
    Function TextAlign: Byte;
  end;

var FontCol: TFontManager;

implementation uses Writer, Dialogs;
//uses ptmainform;


{ TDWG_Text }

constructor TDWG_Text.Create(x, y: single; DC:hDc; const txt, fntName:AnsiString; H,W :single;
                CharSet: Byte; bl1, it1, un1 :Integer; fS:Integer=10);
begin
  FHeight := H;
  FWidth := W;
  FX := x;
  Fy := y;
  FText := txt;
  FCharSet := charset;
  FBl := bl1;
  Fit := it1;
  FUn := un1;
  FScale := fs;
  SetFont(dc, fntName, FHeight, FWidth, fCharSet, fbl, fit, fun, fscale);
  Active:=0;
end;

destructor TDWG_Text.Destroy;
begin
  inherited;
end;

function TDWG_Text.GetFV: TFontViewEx;
begin
  result := nil;
  if FFontIndex <> - 1 then
    result := fontcol[FFontIndex];
end;

constructor TDWG_Text.Load(st: TBufStream);
var Dc:hDc;
begin
  st.read(FX, sizeof(fx));
  st.read(Fy, sizeof(fx));
  st.read(FColor, sizeof(FColor));
  st.read(FFontindex, sizeof(FFontindex));
  OldFontIndex:=FFontIndex;
  st.read(FAng, sizeof(FAng));
  st.read(FWidth, sizeof(FWidth));
  st.read(FHeight, sizeof(FHeight));
  FName := st.readString;
  FText := st.readString;
  WriteS(['Load.dwgText=',FName,FText]);
  st.read(fcharset, sizeof(fcharset));
  st.read(fbl, sizeof(fbl));
  st.read(fit, sizeof(fit));
  st.read(fun, sizeof(fun));
  st.read(fscale, sizeof(fscale));
  ffntname := st.ReadString;
  {$IFDEF WIN64}Dc:=GetDc(0);{$ELSE}Dc:=0;{$ENDIF}
  FFontIndex := -1;
   SetFont(Dc, ffntName, FHeight, FWidth, fCharSet, fbl, fit, fun, fscale);
  {$IFDEF WIN64}ReleaseDc(0,Dc);{$ENDIF}
  Active:=0;
  st.read(fvisible, sizeof(fvisible));
  st.read(fBg, sizeof(FBg));
  st.read(fBgColor, sizeof(FBgColor));
 {}
  st.read(FVarType, sizeof(FVarType));
  st.read(FTextAlignX, sizeof(FTextAlignX));
  st.read(FTextAlignY, sizeof(FTextAlignY));
  st.read(FParams, sizeof(FParams));
//  isfirstdraw := true;
end;

procedure TDWG_Text.Store(st: TbufStream);
var fv: TFontViewEx;
    i: integer;
begin
  st.Write(FX, sizeof(fx));
  st.Write(Fy, sizeof(fx));
  st.Write(FColor, sizeof(FColor));
  st.Write(FFontindex, sizeof(FFontindex));
  st.Write(FAng, sizeof(FAng));
  st.Write(FWidth, sizeof(FWidth));
  st.Write(FHeight, sizeof(FHeight));
  st.WriteString(FName);
  st.WriteString(FText);
  st.write(fcharset, sizeof(fcharset));
  st.write(fbl, sizeof(fbl));
  st.write(fit, sizeof(fit));
  st.write(fun, sizeof(fun));
  st.write(fscale, sizeof(fscale));
  st.writeString(FFntName);
//  fvisible := true;
  st.write(fvisible, sizeof(fvisible));
  st.write(fbg, sizeof(fbg));
  st.write(fbgcolor, sizeof(fbgcolor));
  st.write(FVarType, sizeof(FVarType));
  st.write(FTextAlignX, sizeof(FTextAlignX));
  st.write(FTextAlignY, sizeof(FTextAlignY));
  st.write(FParams, sizeof(FParams));
end;

function TDWG_Text.PointIn(x, y: single): double;
begin
  result := sqrt(sqr(x - fx) + sqr(y - fy));
end;

function TDWG_Text.PointInPoint(x, y: single; var dist: single): integer;
begin
  result := - 1;
  dist := 10000000;
end;

procedure TDWG_Text.SetFont(DC: hDc; const fntName: AnsiString; H, W: Double;
 CharSet: Byte; bl1, it1, un1: Integer; fS: Integer);
begin
  FHeight := h;
  FWidth := w;
  ffntname := FntName;
  FCharSet := char_set;
  FBl := bl1;
  Fit := it1;
  FUn := un1;
  FScale := 500;
  FFontIndex := fontcol.AddFont(dc, ffntName, FHeight, FWidth, fCharSet, fbl, fit, fun, fscale);
  OldFontIndex:=FFontIndex;
end;

function TDWG_Text.FH(C: Char): Double;
var F:TFontViewEx;
begin
 Result:=0;
 if FFontIndex=-1 then Exit;
 F:=fontCol[FFontIndex];
  Result:=FHeight*F.RH(C)/F.Scale;
end;

function TDWG_Text.YMin: Double;
var F:TFontViewEx;
begin
 Result:=0;
 if FFontIndex=-1 then Exit;
 F:=fontCol[FFontIndex];
  Result:=FY+FY*F.YMin('W')/F.Scale;
end;

function TDWG_Text.XMin: Double;
var F:TFontViewEx;
begin
 Result:=0;
 if FFontIndex=-1 then Exit;
 F:=fontCol[FFontIndex];
  Result:=FX+FX*F.XMin('W')/F.Scale;
end;

procedure TDWG_Text.SetGabarites(MRect_: TMRect);
begin
 ShowMessage('1');
end;

procedure TDWG_Text.SetGabaritesBlock(MRect_: TMRect; X, Y, kX, kY,
 Angle: Double);
begin
 ShowMessage('2');
end;

function TDWG_Text.TextAlign: Byte;
begin
 If (fTextAlignX = 0) and (fTextAlignY = 0) then Result:= 1 else
 If (fTextAlignX = 0) and (fTextAlignY = 0.5) then Result:= 2 else
 If (fTextAlignX = 0) and (fTextAlignY = 1) then Result:= 3 else
 If (fTextAlignX = 0.5) and (fTextAlignY = 0) then Result:= 5 else
 If (fTextAlignX = 0.5) and (fTextAlignY = 0.5) then Result:= 6 else
 If (fTextAlignX = 0.5) and (fTextAlignY = 1) then Result:= 7 else
 If (fTextAlignX = 1) and (fTextAlignY = 0) then Result:= 9 else
 If (fTextAlignX = 1) and (fTextAlignY = 0.5) then Result:= 10 else
 If (fTextAlignX = 1) and (fTextAlignY = 1) then Result:= 11;
{ Add('влево-основание');
 Add('влево-низ');
 Add('влево-центр');
 Add('влево-верх');
 Add('центр-основание');
 Add('центр-низ');
 Add('центр-центр');
 Add('центр-верх');
 Add('вправо-основание');
 Add('вправо-низ');
 Add('вправо-центр');
 Add('вправо-верх');
}
end;

{ TFontManager }

function TFontManager.AddFont(DC: hDc; fntName: AnsiString; H, W: Double;
  CharSet: Byte; bl1, it1, un1, fS: Integer): integer;
var I: Integer;
    fv: TFontViewEx;
begin
 Fs:=350;
 charSet:=Default_CharSet;
  result := -1;
  for i := 0 to count - 1 do
  begin
    fv := items[i];
    if fv.isEqual(fntname, charset, bl1, it1, un1) then
    begin
      result := i;
      exit;
    end;
  end;
  fv := TFontViewEx.Create(dc, fntName, h, w, CharSet, bl1, it1, un1, fs);
 // Writeln('Add=',FntName,' ',bl1,' ',It1,' ',Un1,' ',Count);
  Insert(fv);
  fv.Index:=Count-1;
  result := count - 1;
end;

initialization
  FontCol := TFontManager.Create(1);
  PointDrawText:=True;
  RegisterObject(TFontManager,154);
finalization
  FontCol.free;
end.
