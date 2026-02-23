Unit lib;
interface Uses {$IFDEF UNIX}Types,{$ELSE WIN64}Windows,{$ENDIF}Collect, Twgdraw, newConsts, Maths_Basic,
               Classes,Circle_di, Polygons, Graphics, newSelector, DWGText,
               ogccallbacktypes;
{==============================================================================}

const VerConstOfZnk=1;
      VersionOfZnk:Integer=0;
      koefLine=0.1;

type
  Methods=(m_arc,m_line,m_Poly,m_text,m_Pie);

TLineEvent = procedure (Obj: Integer; X1, Y1, X2, Y2: Double); stdcall;
TArcEvent  = procedure (Obj: Integer; X1, Y1, X2, Y2, X3, Y3, X4, Y4: Double); stdcall;
TPolyEvent = procedure (Obj: Integer; Poly: PGeoPoint; penColor, brushColor: Integer; lineWidth: Double; useColor: Boolean; isPolygon: Boolean); stdcall;
TTextEvent = procedure (Obj: Integer; X, Y: Double; FontName: PChar; txtHeight, txtAngle, txtScale: Double;
                         txtColor: Integer; Align: byte; Bl, It, Un: Boolean; Text, AttrName: PChar); stdcall;

{ TGeometryEvents }

TGeometryEvents = class
private
  fOnArc: TArcEvent;
  fOnLine: TLineEvent;
  fOnPie: TArcEvent;
  fOnPoly: TPolyEvent;
  fOnText: TTextEvent;
public
 Obj: Integer;
  constructor Create(Obj_: THandle; OnPoly_: TPolyEvent; OnText_: TTextEvent);
  property OnLine: TLineEvent read fOnLine write fOnLine;
  property OnArc : TArcEvent read fOnArc write fOnArc;
  property OnPie : TArcEvent read fOnPie write fOnPie;
  property OnPoly: TPolyEvent read fOnPoly write fOnPoly;
  property OnText: TTextEvent read fOnText write fOnText;
end;

{---------------------------------------------------------}
TMeth=Class(TTD)
   MT:Methods;
   PT:pointer;
   constructor Create(M:Methods;P:Pointer);
   constructor Load(ST:TBufStream);Override;
   Procedure Store(ST:TBufStream);Override;
end;

{---------------------------------------------------------}

 { TDWG_Line }

 TDWG_Line=Class(TTD)
   x_b,y_b,x_e,y_e:single;
   usecolor: boolean;
   Color:Integer;
   lineW:single;
   Constructor Create(x1,y1,x2,y2:single{;c:SmallInt});
   Constructor Load(ST:TBufStream);Override;
   Procedure Store(ST:TBufStream);Override;
   Procedure SetGabarites(MRect_:TMRect);override;
   Procedure SetGabaritesBlock(MRect_:TMRect;X,Y,kX,kY,Angle:Double);override;
 //
   Procedure DrawTo(Geometry: TGeometryEvents);
 end;
{---------------------------------------------------------}

{ TDWG_Arc }

TDWG_Arc=Class(TTD)
   x_1,y_1,x_2,y_2:single;
   xu_1,yu_1,xu_2,yu_2:single;
   usefill: boolean;
   color, fillcolor: integer;
   linew: single;
   Constructor Create(x1,y1,x2,y2,xu1,yu1,xu2,yu2:single{;c:SmallInt});
   Constructor Load(ST:TBufStream);Override;
   Procedure Store(ST:TBufStream);Override;
   Procedure SetGabarites(MRect_:TMRect);override;
   Procedure SetGabaritesBlock(MRect_:TMRect;X,Y,kX,kY,Angle:Double);override;
 //
   Procedure DrawTo(Geometry: TGeometryEvents);
end;

{ TDWG_Pie }

TDWG_Pie=Class(TDWG_Arc)
   Procedure DrawTo(Geometry: TGeometryEvents);
end;

{---------------------------------------------------------}
TPn=class(TTwgObject)
   X,Y:Single;
   Constructor Create(X1,Y1:Single);
   Constructor Load(ST:TBufStream);override;
   Procedure Store(ST:TBufStream);override;
end;
{}

{ TDWG_Poly }

TDWG_Poly=Class(TTD)
   Vertex:PCollection;
   usefill: boolean;
   color, fillcolor: integer;
   linew: single;
   Constructor Create(P:PCollection);
   Constructor Load(ST:TBufStream);override;
   Procedure Store(ST:TBufStream);override;
   Destructor Destroy;Override;
   Procedure SetGabarites(MRect_:TMRect);override;
   Procedure SetGabaritesBlock(MRect_:TMRect;X,Y,kX,kY,Angle:Double);override;
 //
   Procedure DrawTo(Geometry: TGeometryEvents);
end;
{---------------------------------------------------------}

{ TPoint_Sign }

TPoint_Sign=Class(TTD)
  X,Y:Double;Ugol:single;
  MethodCol:PCollection;
  MyNameIs:array[0..100] of AnsiChar;
  BkColor:Boolean;
  MyInd:SmallInt;
  Drawing:Boolean;
  Sect:TSect;
  useMas:boolean;
  useFont:boolean;
  useInLot:boolean;
  XMax,XMin,YMax,YMin:Double;
  useLine:Boolean;
  Index:Integer;
  MRect:TMRect;
  constructor Create(a,b:single;Name:String = '';Ind:SmallInt = -1);
  constructor Load(ST:TBufStream);Override;
  Procedure Store(ST:TBufStream);Override;
  Destructor Destroy;Override;
 //
  Procedure SetGabarites(MRect_:TMRect);override;
  Procedure SetGabaritesBlock(MRect_:TMRect; X_,Y_,kX,kY,Angle:Double);override;
 //
  Procedure DrawTo(Geometry: TGeometryEvents);
  Procedure DrawTextTo(txt: TDWG_Text; Geometry: TGeometryEvents);
end;
{---------------------------------------------------------}

PLIB=Class(TSortedCollection)
  function Compare(Key1,Key2:Pointer):Integer;Override;
end;

function SearchThis(PC:TSortedCollection;Num:Integer):SmallInt;
{==============================================================================}
var Ar:Array[0..10000] of TPoint;
    PAr:Array[1..100] of TPoint;
    GLayer,GColor:String;
    DeviceHor,DeviceVert:Double;

implementation Uses Types_Dimano, SysUtils, LConvEncoding, ogcWriter, ogcMathUtils;

{ TGeometryEvents }

constructor TGeometryEvents.Create(Obj_: THandle; OnPoly_: TPolyEvent;
                                    OnText_: TTextEvent);
begin
 Obj := Obj_;
 OnPoly := OnPoly_;
// OnLine := OnLine_;
// OnArc  := OnArc_;
// OnPie  := OnPie_;
 OnText := OnText_;
end;

{----------------------------------------------------------------------}
function PLIB.Compare;
begin
 if TPoint_Sign(Key1).MyInd = TPoint_Sign(Key2).MyInd then Compare:=0 else
 if TPoint_Sign(Key1).MyInd < TPoint_Sign(Key2).MyInd then Compare:=-1 else
 Result:=1;
end;

{==============================================================================}
constructor TDWG_Line.Create(x1, y1, x2, y2: single);
begin
	x_b:=x1;
	y_b:=y1;
	x_e:=x2;
	y_e:=y2;
	{col:=c;}
end;
{---------------------------------------------------------}
procedure TDWG_Line.Store(ST: TBufStream);
var xx:boolean;
begin
	ST.write(x_b,SizeOf(x_b));
	ST.write(y_b,SizeOf(y_b));
	ST.write(x_e,SizeOf(x_e));
	ST.write(y_e,SizeOf(x_e));
        ST.write(color, sizeof(color));
        ST.write(linew, sizeof(linew));
        ST.write(xx, sizeof(xx));
{ST.write(col,4);}
end;

procedure TDWG_Line.SetGabarites(MRect_: TMRect);
begin
 MRect_.Insert(x_b,y_b);MRect_.Insert(x_e,y_e);
end;

procedure TDWG_Line.SetGabaritesBlock(MRect_: TMRect; X, Y, kX, kY,
 Angle: Double);
var XX,YY,XX1,YY1:Double;
begin
 XX:=X+(x_b*kX*cos(Angle)-y_b*kX*sin(Angle));
 YY:=Y+(x_B*kY*sin(Angle)+y_b*kY*cos(Angle));
 XX1:=X+(x_e*kX*cos(Angle)-y_e*kX*sin(Angle));
 YY1:=Y+(y_e *kY*cos(Angle)+x_E*kY*sin(Angle));
 MRect_.Insert(XX,YY);MRect_.Insert(XX1,YY1);
end;

procedure TDWG_Line.DrawTo(Geometry: TGeometryEvents);
var P, P1: PGeoPoint; I: Integer;
begin
 New(P);
 P.Create(x_b, y_b, 0);
 P.AddPoint(x_e, y_e, 0);
 P.Count := 2;
// WriteIn(['dllLine.Count=', P.Count]);
 P1 := P;
 For I := 0 to P.Count - 1 do begin
//  WriteIn([P1.X, P1.Y]);
  P1 := P1.Next;
 end;
  Geometry.OnPoly(Geometry.Obj, P, Color, 0, lineW, useColor, False);
 P1 := P;
 For I := 0 to P.Count - 1 do begin

   P1 := P1.Next;
 end;
 P.FreeAll;
 Dispose(P);
end;

{---------------------------------------------------------}
constructor TDWG_Line.Load(ST: TBufStream);
begin
  linew := 0.1;
	ST.read(x_b,SizeOf(X_b));
	ST.read(y_b,SizeOf(y_b));
	ST.read(x_e,SizeOf(x_e));
	ST.read(y_e,SizeOf(y_e));
        if VersionOfZnk > 1 then
        begin
          ST.read(color, sizeof(color));
          ST.read(linew, sizeof(linew));
          if linew = 0 then linew := 0.1;
          if VersionOfZnk > 2 then ST.read(usecolor, sizeof(usecolor));
        end;
{ST.read(col,4);}
end;

{==============================================================================}
constructor TDWG_Arc.Create(x1, y1, x2, y2, xu1, yu1, xu2, yu2: single);
begin
	x_1:=x1;
	y_1:=y1;
	x_2:=x2;
	y_2:=y2;
	xu_1:=xu1;
	yu_1:=yu1;
	xu_2:=xu2;
	yu_2:=yu2;
{col:=c;}
end;
{---------------------------------------------------------}
procedure TDWG_Arc.Store(ST: TBufStream);
begin
  ST.write(x_1,SizeOf(x_1));
  ST.write(y_1,SizeOf(y_1));
  ST.write(x_2,SizeOf(x_2));
  ST.write(y_2,SizeOf(y_2));
  ST.write(xu_1,SizeOf(xu_1));
  ST.write(yu_1,SizeOf(yu_1));
  ST.write(xu_2,SizeOf(xu_2));
  ST.write(yu_2,SizeOf(yu_2));
  ST.Write(color, sizeof(color));
  ST.write(usefill, sizeof(usefill));
  ST.Write(fillcolor, sizeof(fillcolor));
  ST.write(linew, sizeof(linew));
  ST.write(usefill, sizeof(usefill));
{ST.write(col,4);}
end;

procedure TDWG_Arc.SetGabarites(MRect_: TMRect);
begin
 MRect_.Insert(x_1,y_1);MRect_.Insert(x_2,y_2);MRect_.Insert(xu_1,yu_1);MRect_.Insert(xu_2,yu_2);
end;

procedure TDWG_Arc.SetGabaritesBlock(MRect_: TMRect; X, Y, kX, kY, Angle: Double);
const N:Integer = 5;
var I:Integer;Col:PCollection;
begin
 Col:=Arc_Rotate2(X,Y,Angle,x+x_1*kX,y+y_1*kY,x+x_2*kX,y+y_2*kY,
                                         x+xu_1*kX,y+yu_1*kY,x+xu_2*kX,y+yu_2*kY,N);
 For I:=0 to Col.Count-1 do MRect_.Insert(TDot1(Col[I]).X,TDot1(Col[I]).Y);
 Col.Free;
end;

procedure TDWG_Arc.DrawTo(Geometry: TGeometryEvents);
var Col: PCollection;
    N: Integer;
    xnc, ync: Single;
    P, rootP: PGeoPoint;
begin
{ xc := (x_1 + x_2) / 2;
 yc := (y_1 + y_2) / 2;
 xu_c := (xu_1 + xu_2 / 2);
 yu_c := (yu_1 + yu_2 / 2);
 If
}
// WriteIn(['dllArc=']);
 N := 25;
 Col := Arc_Rotate2(0, 0, 0, x_1, y_1, x_2, y_2,  xu_2, yu_2, xu_1, yu_1, N);
 If N > 1 then begin
  New(P); rootP := P;
  For N := 0 to Col.Count - 1 do With TDot(Col.List[N]) do
   If N = 0 then P.Create(fX, fY, 0) else begin
                 P.AddPoint(fX, fY, 0);
                 P := P.Next;
                end;
  rootP.Count := Col.Count;
  Geometry.OnPoly(Geometry.Obj, rootP, Color, fillColor, lineW, useFill,
                           Sqrt(Sqr(xu_1 - xu_2) + Sqr(yu_1 - yu_2)) <= 0.1);
  rootP.FreeAll;
  Dispose(rootP);
 end;
 If Col <> nil then Col.Free;
end;

{---------------------------------------------------------}
constructor TDWG_Arc.Load(ST: TBufStream);
var XX:boolean;
begin
  ST.read(x_1,SizeOf(x_1));
  ST.read(y_1,SizeOf(y_1));
  ST.read(x_2,SizeOf(x_2));
  ST.read(y_2,SizeOf(y_2));
  ST.read(xu_1,SizeOf(xu_1));
  ST.read(yu_1,SizeOf(yu_1));
  ST.read(xu_2,SizeOf(xu_2));
  ST.read(yu_2,SizeOf(yu_2));
  if VersionOfZnk > 1 then begin
   ST.read(color, sizeof(color));
   ST.read(XX, sizeof(XX));
   ST.read(fillcolor, sizeof(fillcolor));
   ST.read(linew, sizeof(linew));
   if VersionOfZnk > 2 then ST.read(useFILL, sizeof(useFILL));
  end;
{ST.read(col,4);}
end;

{==============================================================================}
{ TDWG_Pie }

procedure TDWG_Pie.DrawTo(Geometry: TGeometryEvents);
var Col: PCollection; N:Integer;
    ox, oy: Double; P, rootP: PGeoPoint;
begin
// WriteIn(['dllPie']);
 N:= 25;
 Col:=Arc_Rotate2(0,0,0,x_1, y_1, x_2, y_2, xu_1, yu_1, xu_2, yu_2, N);
 If N > 1 then begin
  ox := x_1 + (x_2 - x_1) / 2;
  oy := y_1 + (y_2 - y_1) / 2;
  Col.Insert(TDot1.Create(ox, oy));
  Col.AtInsert(0, TDot1.Create(ox, oy));
  New(P); rootP := P;
  For N := 0 to Col.Count - 1 do With TDot(Col.List[N]) do
   If N = 0 then P.Create(fX, fY, 0) else begin
                 P.AddPoint(fX, fY, 0);
                 P := P.Next;
                end;
  rootP.Count := Col.Count;
  Geometry.OnPoly(Geometry.Obj, rootP, Color, fillColor, lineW, useFill, True);
  rootP.FreeAll;
  Dispose(rootP);
 end;
 Col.Free;
end;

{==============================================================================}
constructor TPn.Create;
begin
 X:=X1;Y:=Y1;
end;
{---------------------------------------------------------}
procedure TPn.store;
begin
 ST.Write(X,SizeOf(X));
 ST.Write(Y,SizeOf(Y));
end;
{---------------------------------------------------------}
constructor TPn.load;
begin
 ST.Read(X,SizeOf(X));
 ST.Read(Y,SizeOf(Y));
end;
{}
constructor TDWG_Poly.Create(P: PCollection);
begin
 Vertex:=P;
end;
{---------------------------------------------------------}
procedure TDWG_Poly.Store(ST: TBufStream);
begin
 ST.Put(Vertex);
   ST.write(color, sizeof(color));
   ST.write(usefill, sizeof(usefill));
   ST.write(fillcolor, sizeof(fillcolor));
   ST.write(linew, sizeof(linew));
   ST.write(usefill, sizeof(usefill));
end;
{---------------------------------------------------------}
constructor TDWG_Poly.Load(ST: TBufStream);
var XX:boolean;
begin
 Vertex:=PCollection(St.Get);
  if VersionOfZnk > 1 then
  begin
    ST.read(color, sizeof(color));
    ST.read(XX, sizeof(XX));
    ST.read(fillcolor, sizeof(fillcolor));
    ST.read(linew, sizeof(linew));
    if VersionOfZnk > 2 then ST.read(USEFILL, sizeof(USEFILL));
  end;
end;
{---------------------------------------------------------}

destructor TDWG_Poly.Destroy;
 begin
  Vertex.Free;
 end;

procedure TDWG_Poly.SetGabarites(MRect_: TMRect);
var I:Integer;XX,YY:Double;
begin
 For I:=0 to Vertex.Count-1 do
  begin
   XX:=TPn(Vertex.At(I)).X;YY:=TPn(Vertex.At(I)).Y;
   MRect_.Insert(XX,YY);
  end;
end;

procedure TDWG_Poly.SetGabaritesBlock(MRect_: TMRect; X, Y, kX, kY,
 Angle: Double);
var I:Integer;XX,YY:Double;
begin
 For I:=0 to Vertex.Count-1 do
  begin
   XX:=TPn(Vertex.At(I)).X;YY:=TPn(Vertex.At(I)).Y;
   XX:=x+(XX*kX*cos(Angle)-YY*kX*sin(Angle));
   YY:=y+(XX*kY*sin(Angle)+YY*kY*cos(Angle));
   MRect_.Insert(XX,YY);
  end;
end;

procedure TDWG_Poly.DrawTo(Geometry: TGeometryEvents);
var Col: PCollection;
    I, N: Integer;
    X1, Y1, X2, Y2: Double; P, rootP: PGeoPoint;
begin
// WriteIn(['dllPoly']);
 Col := PCollection.Create(1);
 For I := 0 to Vertex.Count - 1 do Col.Insert(TDot1.Create(TPn(Vertex[I]).X, TPn(Vertex[I]).Y));
  X1 := TDot1(Col[0]).X; Y1 := TDot1(Col[0]).Y;
  X2 := TDot1(Col[Col.Count - 1]).X; Y2 := TDot1(Col[Col.Count - 1]).Y;
  New(P); rootP := P;
   For N := 0 to Col.Count - 1 do With TDot(Col.List[N]) do
    If N = 0 then P.Create(fX, fY, 0) else begin
                  P.AddPoint(fX, fY, 0);
                  P := P.Next;
                 end;
  rootP.Count := Col.Count;
  Geometry.OnPoly(Geometry.Obj, rootP, Color, fillColor, lineW, useFill,
                   Sqrt(Sqr(rootP.X - P.X)) + Sqr(rootP.Y - P.Y) <= 0.1);
  rootP.FreeAll;
  Dispose(rootP);
 //
 Col.Free;
end;

{============================================================}
constructor TPoint_Sign.Create(a, b: single; Name: String; Ind: SmallInt);
begin
 MRect:=TMRect.Create;
 x:=a;
 y:=b;
 MRect.Insert(x,y);
 MethodCol:=PCollection.Create(1);
 Drawing:=True;
 StrCopy(MyNameIs,PAnsiChar(Name));MyInd:=Ind;
end;
{---------------------------------------------------------}
destructor TPoint_Sign.Destroy;
begin
 If MRect<>nil then MRect.Free;
 MethodCol.Destroy;
end;

procedure TPoint_Sign.SetGabaritesBlock(MRect_: TMRect; X_, Y_, kX, kY,
 Angle: Double);
var I:Integer;PP:TMeth;
begin
 // проходим по всем примитивам и вычисляем габариты
 // Mrect_ может быть nil
 For I:=0 to MethodCol.Count-1 do begin
  pp:=MethodCol[I];
//  WriteMsg(['Meth=',ord(pp.Mt)]);
  TTD(pp.pt).SetGabaritesBlock(MRect_,X_,Y_,kX,kY,Angle);
 end;
end;

procedure TPoint_Sign.DrawTo(Geometry: TGeometryEvents);
var pp:TMeth;
    p1:TDWG_Line;
    p2:TDWG_Arc;
    p3:TDWG_Poly;
    p4:TDwg_Text;
    p5:TDwg_Pie;
    I:Integer;
    Coord: TList;
begin
 for i:=0 to Methodcol.Count-1 do begin
  pp:=MethodCol.At(i);
//  Writeln('DrawTo ', I,' ',Methodcol.Count, pp.mt);
  case pp.mt of
 	  m_Line:
 		  begin
 		   p1:=pp.pt;
                   p1.DrawTo(Geometry);
 	       	  end else
           if (pp.mt=m_Arc) then
 		   begin
 		   p2:=pp.pt;
                   p2.DrawTo(Geometry);
 		   end else
           if pp.mt=m_Poly then
                  begin
 		   p3:=pp.pt;
                   p3.DrawTo(Geometry);
 		  end else
           if pp.mt=m_Pie then begin
 		  p5:=pp.pt;
                  p5.DrawTo(Geometry);
           end else
           if pp.mt=m_Text then begin
                  p4 := pp.pt;
                  DrawTextTo(P4, Geometry);
           end;
  end;
//  Writeln('End=',I);
 end;
end;

procedure TPoint_Sign.DrawTextTo(txt: TDWG_Text; Geometry: TGeometryEvents);
begin
// (X, Y: Double; FontName: String; txtHeight, txtAngle: Double;
//                        txtColor: TColor; Align: byte; Bl, It, Un: Boolean; Text: String)
 Geometry.OnText(Geometry.Obj, txt.FX, txt.FY, PChar(txt.fFntName), txt.fHeight, txt.fAng, txt.fScale/1000,
                 txt.fColor, txt.TextAlign,
                 bool(txt.fBl), bool(txt.fIt), bool(txt.fUn), PChar(txt.fText), PChar(txt.fName));
end;

procedure TPoint_Sign.SetGabarites(MRect_: TMRect);
var I:Integer;
    pp:TMeth;
begin
 // проходим по всем примитивам и вычисляем габариты
 // Mrect_ может быть nil
 For I:=0 to MethodCol.Count-1 do begin
  pp:=MethodCol[I];
  TTD(pp.mt).SetGabarites(MRect);
 end;
 If MRect_<>nil then MRect_.CreateAs(MRect);
end;

{---------------------------------------------------------}
procedure TPoint_Sign.Store(ST: TBufStream);
var XX,YY:Single;
begin
 XX:=X;YY:=Y;
  ST.write(xx,SizeOf(xx));
  ST.write(yy,SizeOf(yy));
  ST.write(Ugol,SizeOf(Ugol));
  ST.write(MyNameIs,SizeOf(MyNameIs));
  ST.write(usemas, SizeOf(usemas));
  ST.Write(BkColor,1);
  ST.write(MyInd,SizeOf(MyInd));
  ST.put(MethodCol);
end;
{---------------------------------------------------------}

constructor TPoint_Sign.Load(ST: TBufStream);
var a,b:single;I:Integer;p5:TDwg_Pie;XX,YY:single;
    S:AnsiString;
begin
 UseFont:=False;
 MRect:=TMRect.Create;
  ST.read(XX,SizeOf(XX));
  ST.read(YY,SizeOf(YY));
  X:=XX;Y:=YY;
  MRect.Insert(X,Y);
  ST.read(Ugol,SizeOf(Ugol));
  If VersionOfZnk>0 then
  ST.read(MyNameIs,SizeOf(MyNameIs)) else ST.read(MyNameIs,24);
  //    S:=CP1251ToUtf8(MyNameIs);
  MyNameIs:=CP1251ToUtf8(MyNameIs);
  if VersionOfZnk > 1 then
  ST.read(usemas,SizeOf(usemas));

  ST.Read(BkColor,1);
  ST.read(MyInd,SizeOf(MyInd));
  MethodCol:=PCollection(ST.Get);
  {!!!!!!!!!!}
 // Ugol:=0; это видимо для отладки что-то было
 // Drawing:=True;
  {}
  if VersionOfZnk < 3 then
  begin
  //          bkcolor := false;
  For i := 0 to MethodCol.Count - 1 do
    begin
      case TMeth(MethodCol[i]).MT of
        m_arc: TDWG_Arc(TMeth(MethodCol[i]).PT).usefill := BkColor;
  //              m_line: TDWG_Line(TMeth(MethodCol).PT).usefill := BkColor;
        m_Poly: TDWG_Poly(TMeth(MethodCol[i]).PT).usefill := BkColor;
        m_Text: UseFont:=True;
      end;
    end;
    bkcolor := true;
  end else
  For i := 0 to MethodCol.Count - 1 do
   If TMeth(MethodCol[i]).MT=m_Text then UseFont:=True else
   If TMeth(MethodCol[i]).MT=m_Pie then begin
    p5:=TMeth(MethodCol[i]).pt;
   end;
end;

{==============================================================================}
Constructor TMeth.Create;
begin
	MT:=M;
	PT:=P;
end;
{---------------------------------------------------------}
Procedure TMeth.store;
begin
	St.write(MT,SizeOf(MT));
  St.Put(PT);
end;
{---------------------------------------------------------}
constructor TMeth.load;
begin
	St.read(MT,SizeOf(MT));
  PT:=St.Get;
end;
{---------------------------------------------------------}

var GlobalPoint: TPoint_Sign;

function SearchThis;
var I:Integer;
begin
Result:=-1;
if pc=nil then exit;
 GlobalPoint.MyInd:=Num;
 If Pc.Search(GlobalPoint,I) then begin
  Result:=I;
 end;
end;

{==============================================================================}

initialization
 GlobalPoint:=TPoint_Sign.Create(0,0,'');
  RegisterObject(TDWG_Line,5100);
  RegisterObject(TDWG_Arc,5101);
  RegisterObject(TMeth,5103);
  RegisterObject(TPoint_Sign,5102);
  RegisterObject(TPn,5111);
  RegisterObject(TDWG_Poly,5112);
  RegisterObject(TDWG_Text, 5113);
  RegisterObject(TDWG_Pie, 5114);
finalization
 GlobalPoint.Free;
end.
