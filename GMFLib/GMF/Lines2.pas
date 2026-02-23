Unit Lines2;
{=============================================================}
Interface
{=============================================================}
Uses {$IFDEF UNIX}LCLType,{$ELSE WIN64}Windows,{$ENDIF}Collect, SysUtils, Lib, TwgDraw, EcDot,
     Maths_Basic, Lines3;
{-------------------------------------------------}
procedure DevDrawGeoLine(DC:hdc;GL:TGeoLine;PCTwig:PCollection;PC2:TSortedCollection;Ko,MXX,MYY:single;R,G,B:byte;Flag:SmallInt;
	XGeoCent,YGeoCent:Single;XPrintCent,YPrintCent:SmallInt;KoPoint:Single;MakeUsel:Boolean;ZDx:Single;LineWidth:Single);
{-------------------------------------------------}
 Type

   { LLIB }

   LLIB=Class(PLib)
    Function Compare(Key1,Key2:Pointer):Integer;override;
    end;

function SearchLine(PC:TSortedCollection;Num:Integer):SmallInt;
{=============================================================}
Implementation

function LLIB.Compare(Key1, Key2: Pointer): Integer;
begin
 If TGeoLine(Key1).idNum < TGeoLine(Key2).idNum then Result:=-1 else
 If TGeoLine(Key1).idNum = TGeoLine(Key2).idNum then Result:=-0 else Result:=1;
end;
{-------------------------------------------------}
var GlobalLine:TGeoLine;

function SearchLine;
var
   p:TGeoLine;
   i:Integer;
begin
Result:=-1;
if pc=nil then exit;
 GlobalLine.idNum:=Num;
 If Pc.Search(GlobalLine,I) then
   Result:=I;
end;
{=============================================================}
 procedure DevDrawGeoLine(DC:hdc;GL:TGeoLine;PCTwig:PCollection;PC2:TSortedCollection;Ko,MXX,MYY:single;R,G,B:byte;Flag:SmallInt;
  	XGeoCent,YGeoCent:Single;XPrintCent,YPrintCent:SmallInt;KoPoint:Single;MakeUsel:Boolean;ZDx:Single;LineWidth:Single);
 begin
 end;

initialization
 GlobalLine:=TGeoLine.Create('');
 RegisterObject(TGeoLine,5106);
 RegisterObject(TLineStruct,5107);
finalization
 //GlobalLine.Free;
end.
