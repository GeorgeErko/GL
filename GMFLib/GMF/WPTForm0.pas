unit WPTForm0;
interface uses {$IFDEF WIN64} Windows, {$ELSE} Types, LCLType,{$ENDIF}
               Collect, WpTwigs, ECLot, TwgColle, EcDot, EMath, newForm0,
               Lib, newConsts, WpArcs, newResource,
               SysUtils, Types_dimano, Classes, newLayersTable, newSelector;


 Type
   ECAboutObjectOld=record
      Modified:SmallInt;
     {}
      DecimalHeight,DecimalLength,SqwearMetric,
      DecimalSqwear,AngleMetric,DecimalCoord,DecimalAngle,CalcDirect:Byte;
     {}
      BaseBool2:SmallInt;
      Path:Array[0..300] of AnsiChar;
      ObjectName:Array[0..50] of AnsiChar;
      // префикс
      idPrefix:Array[0..25] of AnsiChar;
      idAutoAddLot:Boolean;
      GraphSet:Boolean; // глобальные установки графики
      idDop:Array[0..22] of AnsiChar;
      MsnpName  :Array[0..50] of AnsiChar;
      XGP,YGP:Extended;
      HedName   :Array[0..30] of AnsiChar;
      ClassName ,
      BaseName  :Array[0..50] of AnsiChar;
      MyName    :Array[0..50] of AnsiChar;
      MyBase    :Array[0..50] of AnsiChar;
      MyDir1    :SmallInt;
      XMin,YMin,XMax,YMax:Extended;
		    HObject,WObject:Single;
		    MaxLotNum :LongInt;
    end;

   ECAboutObject=record
      Version:Byte;
      ModifiedObject:SmallInt;
     {}
      DecimalHeight,DecimalLength,SqwearMetric,
      DecimalSqwear,AngleMetric,DecimalCoord,DecimalAngle,CalcDirect:Byte;
     {}
      Path:AnsiString;
      ObjectName:AnsiString;
      BasePath:AnsiString;
      // префикс
      idPrefix:AnsiString;
      idAutoAddLot:Boolean;
      GraphSet:Boolean; // глобальные установки графики
      ClassName :AnsiString;
      MyName    :AnsiString;
      XMin,YMin,XMax,YMax:Extended;
      HObject1,WObject1:Single;
      MaxLotNum :LongInt;
      Fragment:TSect;
      MirrorObject:Byte;
      Dop:Array[0..959] of byte;
    end;

Procedure CopyFromIn(xFrom:EcAboutObjectOld;var xTo:EcAboutObject);
Procedure StoreAbout(A:EcAboutObject;B:TBufStream);
Procedure LoadAbout(var A:EcAboutObject;B:TBufStream);

Type
  TForm0=class(TFormMain)
   HWndParent:hWnd;
   Rect:Trect;
   ActiveLotBool,
    ActiveTwigBool,
    ActiveFontBool,
     ActiveMapBool:Boolean;
	{}
     Activemap    :LongInt;
   {}
   {}
    About    :EcAboutObject;
    XXMin,YYMin,XXMax,YYMax:Extended;
    UndoColl,ActivePoint2,TmpColl,ActivePoint,NotLink_Up,Perehlests,LineNesost:PCollection;
   { блокирует сортировку текста по признакам }
   {}
    NeedTwigs:PCollection;
   {}
    LotZnak:TPoint_Sign;
   {}
    OneLotNum:LongInt;
    OneLotZnak:TPDot;
    OneLot:TLot;
    OneDot:PCollection;
    Parametr:byte;
  { По автоматическому сбору }
     LotBool:Boolean;
  { Taheo }
     ActiveTaheo:LongInt;
     TaheoTwig  :LongInt;
     ActivePntLine:PCollection;
  {}
     LotPoints:PCollection;
  {}
  { Новые коллекции }
    LotActive:PCollection;
    LotTwig  :PCollection;
    ActiveHPoly:PCollection;
    TempPoints :PCollection;
//    TempTwig:TTwig;
    ZPiket:Double;
  { MosLib }
     MkLib   :TMosLib;
  { линейно представленные подписи и точки }
     LinearPoints:PCollection;
     LinearFonts :PCollection;
     LinearTwigs :PCollection;
  {}
     TransformPoints:PCollection;
  { Тахео }
    thTwig:TTwig;
  { Построение}
    MemMake:AnsiString;
    MemMakeIndex:Integer;
  { ArcВетки}
    ArcTwigs:PCollection;
  { Шрифт }
    TTFViews:PCollection;
  {}
    V25:Pointer;
    LayerTable:TLayerTable;
    Taheo:Pointer;
  {}
    Undo:Pointer;
 {}
     Procedure CreateLinearView;virtual;abstract;
     Procedure FreeLinearView;virtual;abstract;
  end;



implementation uses Writer;

Procedure CopyFromIn;
 begin
  With xFrom do
   begin
    xTo.Version:=Round(HObject);
    xTo.ModifiedObject:=Modified;
    xTo.DecimalHeight:=DecimalHeight;
    xTo.DecimalLength:=DecimalLength;
    xTo.SqwearMetric:=SqwearMetric;
    xTo.DecimalSqwear:=DecimalSqwear;
    xTo.AngleMetric:=AngleMetric;
    xTo.DecimalCoord:=DecimalCoord;
    xTo.DecimalAngle:=DecimalAngle;
    xTo.CalcDirect:=CalcDirect;
    xTo.Path:=StrPas(Path);
    xTo.ObjectName:=StrPas(ObjectName);
    xTo.BasePath:='';
    xTo.idPrefix:=StrPas(idPrefix);
    xTo.idAutoAddLot:=idAutoAddLot;
    xTo.GraphSet:=GraphSet;
    xTo.ClassName:=StrPas(ClassName);
    xTo.MyName:=StrPas(MyName);
    xTo.XMin:=XMin;xTo.YMin:=YMin;xTo.XMax:=XMax;xTo.YMax:=YMax;
    xTo.MaxLotNum:=MaxLotNum;
    FillChar(xTo.Dop,SizeOf(xTo.Dop),#0);
    With xTo.FragMent do begin
     Left:=YMin;Right:=YMax;Top:=-XMax;Bottom:=-XMin;
    end;
   end;
 end;


Procedure StoreAbout;
 Const S:Array [0..7] of AnsiChar='VER252';
 begin
  With A,B do
   begin
    Write(S,SizeOf(S));
    Write(A.Version,SizeOf(A.Version));
    Write(ModifiedObject,SizeOf(ModifiedObject));
    Write(DecimalHeight,SizeOf(DecimalHeight));
    Write(DecimalLength,SizeOf(DecimalLength));
    Write(SqwearMetric,SizeOf(SqwearMetric));
    Write(DecimalSqwear,SizeOf(DecimalSqwear));
    Write(AngleMetric,SizeOf(AngleMetric));
    Write(DecimalCoord,SizeOf(DecimalCoord));
    Write(DecimalAngle,SizeOf(DecimalAngle));
    Write(CalcDirect,SizeOf(CalcDirect));
    WriteString(Path);
    WriteString(ObjectName);
    WriteString(BasePath);
    WriteString(idPrefix);
    Write(idAutoAddLot,SizeOf(idAutoAddLot));
    Write(GraphSet,SizeOf(GraphSet));
    WriteString(A.ClassName);
    WriteString(MyName);
    Write(XMin,SizeOf(XMin));Write(YMin,SizeOf(YMin));Write(XMax,SizeOf(XMax));Write(YMax,SizeOf(YMax));
    Write(MaxLotNum,SizeOf(MaxLotNum));
    Write(Fragment,SizeOf(TSect));
    Write(MirrorObject,SizeOf(MirrorObject));
    Write(Dop,SizeOf(Dop));
   end;
 end;

Procedure LoadAboutNew(var Ab:EcAboutObject;B:TBufStream);
 Const S:Array [0..7] of AnsiChar='VER251';
 var XY:TExtended80Rec;extRect:TExtendedSect;
 begin
  With Ab,B do
   begin
    WriteS(['begRead']);
    Read(Ab.Version,SizeOf(Ab.Version));
    Read(ModifiedObject,SizeOf(ModifiedObject));
    Read(DecimalHeight,SizeOf(DecimalHeight));
    Read(DecimalLength,SizeOf(DecimalLength));
    Read(SqwearMetric,SizeOf(SqwearMetric));
    Read(DecimalSqwear,SizeOf(DecimalSqwear));
    Read(AngleMetric,SizeOf(AngleMetric));
    Read(DecimalCoord,SizeOf(DecimalCoord));
    Read(DecimalAngle,SizeOf(DecimalAngle));
    Read(CalcDirect,SizeOf(CalcDirect));
    WriteS(['begRead2']);
    Path:=ReadString;
    WriteS(['begRead3']);
    ObjectName:=ReadString;
    BasePath:=ReadString;
    idPrefix:=ReadString;
    Read(idAutoAddLot,SizeOf(idAutoAddLot));
    Read(GraphSet,SizeOf(GraphSet));
    Ab.ClassName:=ReadString;
    {!!! изменить запись WIN64}
    WriteS(['XY1 =',Xmin,YMin,XMax,YMax]);
    MyName:=ReadString;
    XMin:=ReadExtended;
    YMin:=ReadExtended;
    XMax:=ReadExtended;
    YMax:=ReadExtended;
    WriteS(['XY2 =',Xmin,YMin,XMax,YMax]);
    Read(MaxLotNum,SizeOf(MaxLotNum));
    WriteS(['next']);
    With ReadSect do begin Fragment.Left:=Left;Fragment.Top:=Top;Fragment.Right:=Right;Fragment.Bottom:=Bottom;end;
    WriteS(['SecRead']);
//    WriteS(['Fragment =',Fragment.Left,Fragment.Top,Fragment.Right,Fragment.Bottom]);
    Read(MirrorObject,SizeOf(MirrorObject));
    Read(Dop,SizeOf(Dop));
    WriteS(['EndOf']);
   end;
 end;

Procedure LoadAbout;
 var S:Array [0..7] of AnsiChar;
 begin
  WriteS(['Load1']);
  B.Read(S,SizeOf(S));
  WriteS(['Load2']);
  If StrPos(S,'VER25')<>nil then begin LoadAboutNew(A,B);if S='VER251' then A.Version:=24; end else
  begin
   raise Exception.Create('Формат заголовка файла не поддерживается');
   // Writeln(Ab.HObject:8:2,' ',Ab.ClassName,' ',A.version,' ',A.ClassName);
  end;
 end;

{ TForm0 }

Initialization
end.
