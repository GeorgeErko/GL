unit RPcxBox;

interface

uses
  imgutils, {$IFDEF WIN64} Windows,{$ELSE} LCLType, {$ENDIF} Messages, SysUtils, Classes, Graphics, Controls, RBitBox,
  RPCXfile, RBMPFile, RSBmp, {$IFDEF TIFF} tiffile, {$ENDIF} Collect;

const
  MAX_D_MATRIX = 4;
  MaxIntArr = 150;
  MaxMatrix = 20;
type

  TIntArr = array[0..MaxIntArr - 1, 0..MaxIntArr - 1] of integer;//array of array of integer;
  TIntMatrix = array[0..MaxMatrix - 1, 0..MaxMatrix - 1] of integer;//array of array of integer;
  TRealArr = array[0..MaxMatrix - 1, 0..MaxMatrix - 1] of double;//array of array of integer;

  TPCXBox = class(TBitBox)
  private
    procedure ___Paint(Canv: TCanvas);
  public
    { Public declarations }
    fk: double;
    fpal: HPalette;
    img: TSimpleBmp;
    savedrect: TRect;
    querydpi: boolean;

    GetPixel: TGetPixel;
    SetPixel: TSetPixel;

    FTileX, FTileY: integer;
    FDivisionX, FDivisionY: integer;
    FMaxDiv: integer;
    constructor Create(aowner: TComponent); override;
    destructor Destroy; override;

    function CreateNewBitmap(Box:TBitBox;FN:AnsiString;W,H:Integer): boolean; override;

    procedure Initialize(V: TControl; C: TCanvas); override;
    procedure SetPalette(color, bkcolor: TColor);

    procedure Paint(Canv: TCanvas);  override;

    procedure CreateView(FN: AnsiString; readonly: boolean); override;
    procedure CloseView; override;
    Function biWidth:Integer; override;
    Function biHeight:Integer; override;
    function DPI: integer; override;
    function PPM: integer; override;
    procedure AfterTrans(const s1, s2: AnsiString); override;
    function GetBackColor: Integer;
    procedure initBmi(const fn: AnsiString; w, h: integer); override;

    procedure GetImgRect(l, t, w, h: integer; var v: TIntArr);
    procedure SetImgRect(l, t, w, h: integer; var v: TIntArr; sx, sy, sx2, sy2: integer);
    procedure Divide;
    function GetDivW(i: integer): integer;
    function GetDivH(i: integer): integer;

//    procedure SwapBWPal;

    class function ConvertToRGBA(var src, dest: pointer; bpp: integer; w, h: integer): boolean;
  end;

  
var g_backColor: integer; 


procedure Register;

implementation uses newProcs;


procedure Register;
begin
  RegisterComponents('Version', [TBitBox]);
end;


{ TPCXBox }

procedure TPCXBox.CreateView(FN: AnsiString; readonly: boolean);
var
  s: AnsiString;
  zzz: integer;
begin
  savedrect := Rect(0, 0, 0, 0);
  FileName:=FN;
  bits := nil;
  if img <> nil then img.free;
  try
    s := UpperCase(ExtractFileExt(fn));
    if s = '.PCX' then  img := TPcx2file.Create(fn, readonly, false, querydpi)
    {$IFDEF TIFF}
    else if s = '.TIF' then  img := TTiffFile.Create(fn, readonly, false)//, false)//querydpi)
    {$ENDIF}
    else img := TBmpFile.Create(fn, readonly, false, querydpi);

    bits := pointer(1);
    Left := 0; Top := 0;

    width := img.width;
    height := img.height;

    GetPixel := img.GetPixel;
    SetPixel := img.SetPixel;

    XKoeff := 1;
    YKoeff := 1;

    zzz := 1;
    BackColor := RGBToCol(img.fbmi.bmiColors[zzz].rgbRed, img.fbmi.bmiColors[zzz].rgbGreen, img.fbmi.bmiColors[zzz].rgbBlue);
    zzz := 0;
    Color := RGBToCol(img.fbmi.bmiColors[zzz].rgbRed, img.fbmi.bmiColors[zzz].rgbGreen, img.fbmi.bmiColors[zzz].rgbBlue);
  except
    on e: Exception do
    begin
      MessageError(pChar(e.message));
      exit;
    end;
  end;
end;

procedure TPCXBox.CloseView;
begin
  if img <> nil then
  begin
    img.free;
    img := nil;
  end;
  bits := nil;
end;

procedure TPCXBox.Initialize(V: TControl; C: TCanvas);
begin
  inherited;
end;
(*
procedure TPCXBox.Paint(C: TCanvas);

var tmpr: TRect;
    k: double;
    drl, drt, h, w: integer;
    dc: HDC;
          function clip_rect(const r1, r2: TRect): TRect;
          begin
            if not print then result := bitbox.clip_rect(r1, r2)
            else result := bitbox.clip_rect(RPrin, r2);
          end;
          {
          procedure DrawDirect;
          var w, h: integer;
              bi: TBitmapInfo;
          begin
            w := pcx.bmp.Width;
            h := pcx.bmp.Height;
          end;}
var rchg: boolean;
    p1, p2: TRGBQuad;
    zzz: integer;
begin
  if img = nil then exit;
  if (FWidth <= 0) or (FHeight <= 0) then exit;
  if c = nil then dc := printerdc
  else dc := c.handle;
    XKoeff := img.Width / FWidth;
    YKoeff := img.Height / FHeight;
    k := (XKoeff + YKoeff) / 2;

    if k = 0 then exit;
  try
    if k = 0 then exit;
        if left < 0 then drl := 0
    else drl := left;
    if top < 0 then drt := 0
    else drt := top;
    if  c<> nil then
    begin
      if TransParent then C.CopyMode := cmSrcAnd
      else C.CopyMode := cmSrcCopy;
    end;

    if  img.bpp = 1 then
    begin
      zzz := 1;
      p1 := img.fbmi.bmiColors[0];
      p2 := img.fbmi.bmiColors[zzz];
      img.fbmi.bmiColors[zzz].rgbBlue := GetBValue(BackColor);
      img.fbmi.bmiColors[zzz].rgbGreen := GetGValue(BackColor);
      img.fbmi.bmiColors[zzz].rgbRed := GetRValue(BackColor);

      img.fbmi.bmiColors[0].rgbBlue := GetBValue(Color);
      img.fbmi.bmiColors[0].rgbGreen := GetGValue(Color);
      img.fbmi.bmiColors[0].rgbRed := GetRValue(Color);
    end;

    r := clip_rect(Viewer.ClientRect, Rect(Left, Top, Right, Bottom));
    rchg := EqualRect(r, savedrect);
    savedrect := r;


    if k = 1 then
    begin
      if not rchg then
        img.savebmp(r.top, r.bottom, r.left, r.right, nil, nil, false);
      h := img.partHeight;
      w := img.PartWidth;
      if TransParent then
       StretchDIBits(dc, drl, drt, r.right - r.left, r.bottom - r.top,
           0, 0, w, h, img.bigmem, img.fbmi^, DIB_RGB_COLORS, SrcAnd)
      else SetDIBitsToDevice(dc, drl, drt, img.PartWidth, img.partHeight,
           0, 0, 0, img.PartHeight, img.bigmem, img.fbmi^, DIB_RGB_COLORS);
    end
    else if k > 1 then
    begin
      CreateDynaBits;
      if (DynaX.Count = 0) or (DynaY.Count = 0) then
      begin
//        FillRect(dc, Viewer.ClientRect, GetStockObject(WHITE_BRUSH));
        exit;
      end;
      img.savebmp(r.top, r.bottom, r.left, r.right, DynaX, DynaY, true);
      h := img.partHeight;
      w := img.PartWidth;
      if TransParent then
       StretchDIBits(dc, drl, drt, r.right - r.left, r.bottom - r.top,
           0, 0, w, h, img.bigmem, img.fbmi^, DIB_RGB_COLORS, SrcAnd)
      else SetDIBitsToDevice(dc, drl, drt, img.PartWidth, img.partHeight,
           0, 0, 0, img.PartHeight, img.bigmem, img.fbmi^, DIB_RGB_COLORS);
    end
    else if k < 1 then
    begin
      img.savebmp(trunc(r.top * ykoeff), trunc(r.bottom * ykoeff), trunc(r.left * xkoeff), trunc(r.right * xkoeff), nil, nil, false);
      if TransParent then
        StretchDIBits(dc, drl, drt, trunc((r.right - r.left)), trunc((r.bottom - r.top)),
           0, 0, img.fbmi^.bmiHeader.biWidth, img.fbmi^.bmiHeader.biHeight, img.bigmem, img.fbmi^, DIB_RGB_COLORS, SRCAND)
      else
        StretchDIBits(dc, drl, drt, trunc((r.right - r.left)), trunc((r.bottom - r.top)),
           0, 0, img.fbmi^.bmiHeader.biWidth, img.fbmi^.bmiHeader.biHeight, img.bigmem, img.fbmi^, DIB_RGB_COLORS, SRCCOPY);
    end;
  except
  end;
  if  img.bpp = 1 then
  begin
    zzz := 1;
    img.fbmi.bmiColors[0] := p1;
    img.fbmi.bmiColors[zzz] := p2;
  end;
end;
*)

procedure TPCXBox.Paint(Canv: TCanvas);
      procedure DrawRastr(koef: single; TransParent: boolean; dc: thandle; x, y, w, h, w2, h2: integer; p: integer = 0);
      var
        v, i, j,  k, w32, t1, t2, oldh, hh: integer;
        dd: integer;
        n, df, fdf: single;
        b: boolean;
        rgba, buf: pAnsiChar;
        bmp: TBitmap;
        pal: TMaxLogPalette;
        hpal: cardinal;
        rect: trect;
      begin
        w32 := TBmpFile.slwidth(w, img.bpp);
        while w32 mod 4 <> 0 do inc(w32); 
       // if TransParent then v := CopyMode else v := SRCCOPY;
       v:=Win32CopyMode;
      //!!                       
        if p = 0 then
        begin
          //SetStretchBltMode(Canv.Handle, WhiteOnBlack);
          oldh := img.fbmi^.bmiHeader.biHeight;
          img.fbmi^.bmiHeader.biHeight := 1;
          hh := (oldh - 1) * w32;
          for k := 0 to h2 - 1 do
          begin
           {$IFDEF WIN64}
            StretchDIBits(dc, x, y+k, w, 1, 0, 0, w2, 1, (img.bigmem + hh) - w32 * k, img.fbmi^, DIB_RGB_COLORS, v);
           {$ENDIF}
          end;
          img.fbmi^.bmiHeader.biHeight := oldh;
        end
        else
        begin
          bmp := TBitmap.Create;
          try
            w32 := TBmpFile.slwidth(w2, img.bpp);
            while w32 mod 4 <> 0 do inc(w32);

            oldh := img.fbmi^.bmiHeader.biHeight;
            img.fbmi^.bmiHeader.biHeight := 1;

            case img.bpp of
              1: bmp.PixelFormat := pf1bit;
              4: bmp.PixelFormat := pf4bit;
              8: bmp.PixelFormat := pf8bit;
              24: bmp.PixelFormat := pf24bit;
              32: bmp.PixelFormat := pf32bit;
            end;

            bmp.Width := w2;
            bmp.Height := h2;

            if img.bpp < 16 then
            begin
              pal.palVersion := $300;
              pal.palNumEntries := 1 shl img.bpp;

              for i := 0 to pal.palNumEntries - 1 do
              begin
                pal.palPalEntry[i].peRed := img.fbmi^.bmiColors[i].rgbRed;
                pal.palPalEntry[i].peGreen := img.fbmi^.bmiColors[i].rgbGreen;
                pal.palPalEntry[i].peBlue := img.fbmi^.bmiColors[i].rgbBlue;
                pal.palPalEntry[i].peFlags := 0;
              end;
             {$IFDEF WIN64}
              hpal := CreatePalette(PLogPalette(@pal)^);
              bmp.Palette := hpal;
              DeleteObject(hpal);
             {$ENDIF}
            end;
            hh := (oldh-1)* w32;
            for i := 0 to h2 - 1 do
            begin
              buf := bmp.ScanLine[i];
              rgba := (img.bigmem + hh) - w32 * i;
              move(rgba^, buf^, w32);
            end;

            rect.Left := x;
            rect.Top := y;
            rect.Right := x + w;
            rect.Bottom := y + h;
            if canv = nil then
            begin
              Canv := TCanvas.Create;
              Canv.Handle := PrinterDc;
            end;
           // if TransParent then Canv.CopyMode := cmSrcInvert
           // else Canv.CopyMode := cmSRCCOPY;
            Canv.CopyMode:=CopyMode;
            Canv.StretchDraw(rect, bmp);
        finally
            bmp.free;
          end;
          img.fbmi^.bmiHeader.biHeight := oldh;
        end;
      end;
var
  tmpr: TRect;
  k: double;
  drl, drt, h, w: integer;
  dc: HDC;
          function clip_rect(const r1, r2: TRect): TRect;
          begin
            if not print then result := rbitbox.clip_rect(r1, r2)
            else result := rbitbox.clip_rect(RPrin, r2);
          end;
var
  rchg: boolean;
  p1, p2: TRGBQuad;
  zzz: integer;
begin
  if img = nil then exit;
  if (FWidth <= 0) or (FHeight <= 0) then exit;
  if canv = nil then dc := printerdc
  else dc := canv.handle;

  XKoeff := img.Width / FWidth;
  YKoeff := img.Height / FHeight;
  k := (XKoeff + YKoeff) / 2;

  if k = 0 then exit;
  try
    if k = 0 then exit;
        if left < 0 then drl := 0
    else drl := left;
    if top < 0 then drt := 0
    else drt := top;
    if Canv <> nil then
    begin
     Canv.CopyMode:=CopyMode;
    end;

    if img.bpp = 1 then
    begin
      zzz := 1;
      p1 := img.fbmi.bmiColors[0];
      p2 := img.fbmi.bmiColors[zzz];
      img.fbmi.bmiColors[zzz].rgbBlue := GetB(BackColor);
      img.fbmi.bmiColors[zzz].rgbGreen := GetG(BackColor);
      img.fbmi.bmiColors[zzz].rgbRed := GetR(BackColor);

      img.fbmi.bmiColors[0].rgbBlue := GetB(Color);
      img.fbmi.bmiColors[0].rgbGreen := GetG(Color);
      img.fbmi.bmiColors[0].rgbRed := GetR(Color);
    end;

{    if  img.bpp = 1 then
    begin
      zzz := 1;
      p1 := img.fbmi.bmiColors[0];
      p2 := img.fbmi.bmiColors[zzz];
      img.fbmi.bmiColors[zzz].rgbBlue := GetBValue(BackColor);
      img.fbmi.bmiColors[zzz].rgbGreen := GetGValue(BackColor);
      img.fbmi.bmiColors[zzz].rgbRed := GetRValue(BackColor);

      img.fbmi.bmiColors[0].rgbBlue := GetBValue(Color);
      img.fbmi.bmiColors[0].rgbGreen := GetGValue(Color);
      img.fbmi.bmiColors[0].rgbRed := GetRValue(Color);
    end;                       }

    r := clip_rect(Viewer.ClientRect, Rect(Left, Top, Right, Bottom));
    rchg := false;//EqualRect(r, savedrect);
    savedrect := r;

    if k = 1 then
    begin
      if not rchg then
      begin
        img.savebmp(r.top, r.bottom, r.left, r.right, nil, nil, false);
      end;
      h := img.partHeight;
      w := img.PartWidth;
      DrawRastr(k, TransParent, dc, drl, drt, r.right - r.left, r.bottom - r.top, w, h);
    end
    else if k > 1 then
    begin
      CreateDynaBits;
      if (DynaX.Count = 0) or (DynaY.Count = 0) then
      begin
        exit;
      end;
      img.savebmp(r.top, r.bottom, r.left, r.right, DynaX, DynaY, true);

      h := img.partHeight;
      w := img.PartWidth;
      DrawRastr(k, TransParent, dc, drl, drt, r.right - r.left, r.bottom - r.top, w, h);
    end
    else if k < 1 then
    begin
      img.savebmp(trunc(r.top * ykoeff), trunc(r.bottom * ykoeff), trunc(r.left * xkoeff), trunc(r.right * xkoeff), nil, nil, false);
      DrawRastr(k, TransParent, dc, drl, drt, trunc((r.right - r.left)), trunc((r.bottom - r.top)), img.fbmi^.bmiHeader.biWidth, img.fbmi^.bmiHeader.biHeight, 1);
    end;
  except
  end;
  if  img.bpp = 1 then
  begin
    zzz := 1;
{    img.fbmi.bmiColors[0] := p1;
    img.fbmi.bmiColors[zzz] := p2;}
  end;
end;


procedure TPCXBox.___Paint(Canv: TCanvas);

var
  isprintercanvas: boolean;
          procedure DrawRastr_(TransParent: boolean; dc: thandle; x, y, w, h, w2, h2: integer; p: integer = 0);
          var
            v, i, j,  k, w32, t1, t2, oldh, hh: integer;
            b: boolean;
          begin
            w32 := TBmpFile.slwidth(w2, img.bpp);
            while w32 mod 4 <> 0 do inc(w32);
            b := false;
            if p = 0 then
            begin
              if TransParent then
              begin
                oldh := img.fbmi^.bmiHeader.biHeight;
                img.fbmi^.bmiHeader.biHeight := 1;
                hh := oldh * w32;
                for k := h2 - 1 downto 0 do
                begin
                {$IFDEF WIN64}
                  StretchDIBits(dc, x, y+k, w, 1, 0, 0, w2, 1, (img.bigmem + hh) - w32 * k, img.fbmi^, DIB_RGB_COLORS, SrcAnd);
                {$ENDIF}
                end;
                img.fbmi^.bmiHeader.biHeight := oldh;
              end
              else
              begin
                for k := 0 to h2 - 1 do
                begin
                {$IFDEF WIN64}
                  SetDIBitsToDevice(dc, x, y, w2, h2, 0, 0, k, 1, img.bigmem + w32 * k, img.fbmi^, DIB_RGB_COLORS);
                {$ENDIF}
                end;
              end;
            end
            else
            begin
              if TransParent then v := SRCAND else v := SRCCOPY;
              oldh := img.fbmi^.bmiHeader.biHeight;
              img.fbmi^.bmiHeader.biHeight := 1;
              hh := oldh * w32;
              for k := 0 to h2 - 1 do
              begin
              {$IFDEF WIN64}
                StretchDIBits(dc, x, y+k, w, 1, 0, 0, w2, 1, (img.bigmem + hh) - w32 * k, img.fbmi^, DIB_RGB_COLORS, SrcAnd);
              {$ENDIF}
              end;
              img.fbmi^.bmiHeader.biHeight := oldh;
            end;
          end;


          procedure DrawRastr__(koef: single; TransParent: boolean; dc: thandle; x, y, w, h, w2, h2: integer; p: integer = 0);
          var
            v, i, j,  k, w32, t1, t2, oldh, hh: integer;
            dd: integer;
            n, df, fdf: single;
            b: boolean;
          begin
            w32 := TBmpFile.slwidth(w, img.bpp);
            while w32 mod 4 <> 0 do inc(w32);
            if TransParent then v := SRCAND else v := SRCCOPY;

            if p = 0 then
            begin
              oldh := img.fbmi^.bmiHeader.biHeight;
              img.fbmi^.bmiHeader.biHeight := 1;
              hh := (oldh - 1) * w32;
              for k := 0 to h2 - 1 do
              begin
              {$IFDEF WIN64}
                StretchDIBits(dc, x, y+k, w, 1, 0, 0, w2, 1, (img.bigmem + hh) - w32 * k, img.fbmi^, DIB_RGB_COLORS, v);
              {$ENDIF}
              end;
              img.fbmi^.bmiHeader.biHeight := oldh;
            end
            else
            begin
              w32 := TBmpFile.slwidth(w2, img.bpp);
              while w32 mod 4 <> 0 do inc(w32);

              oldh := img.fbmi^.bmiHeader.biHeight;
              img.fbmi^.bmiHeader.biHeight := 1;

              hh := (oldh - 1)* w32;
              if h2 = 0 then
                exit;
              df := 1 / koef;
              dd := y + h;
              fdf := 0;
              for k := h2 - 1 downto 0 do
              begin
//                if y + h < dd then break;
                for i := trunc(df)-1 downto 0 do
                begin
                {$IFDEF WIN64}
                  StretchDIBits(dc, x, dd, w, 1, 0, 0, w2, 1,
                      (img.bigmem + hh) - w32 * k, img.fbmi^, DIB_RGB_COLORS, v);
                {$ENDIF}
                  fdf := fdf + Frac(df);
                  dec(dd);
                end;
//                if y + h < dd  then break;
                while fdf >= 1 do
                begin
                {$IFDEF WIN64}
                  StretchDIBits(dc, x, dd, w, 1, 0, 0, w2, 1,
                      (img.bigmem + hh) - w32 * k, img.fbmi^, DIB_RGB_COLORS, v);
                {$ENDIF}
                  fdf := fdf - 1;
                  dec(dd);
                end;
              end;
              img.fbmi^.bmiHeader.biHeight := oldh;
            end;

//              StretchDIBits(dc, x, y, w, h, 0, 0, w2, h2, img.bigmem, img.fbmi^, DIB_RGB_COLORS, v);
{            b := false;
            for k := 0 to h2 - 1 do
            begin
              SetDIBitsToDevice(dc, x, y, w, h, 0, 0, k, 1, img.bigmem + w32 * k, img.fbmi^, DIB_RGB_COLORS);
            end;}
          end;


          procedure DrawRastr(koef: single; TransParent: boolean; dc: thandle; x, y, w, h, w2, h2: integer; p: integer = 0);
          var
            v, i, j,  k, w32, t1, t2, oldh, hh: integer;
            dd: integer;
            n, df, fdf: single;
            b: boolean;
            rgba, buf: pAnsiChar;
            bmp: TBitmap;
            pal: TMaxLogPalette;
            hpal: cardinal;
            rect: trect;
          begin
            w32 := TBmpFile.slwidth(w, img.bpp);
            while w32 mod 4 <> 0 do inc(w32);
            if TransParent then v := SRCAND else v := SRCCOPY;
            if p = 0 then
            begin
              oldh := img.fbmi^.bmiHeader.biHeight;
              img.fbmi^.bmiHeader.biHeight := 1;
              hh := (oldh - 1) * w32;
              for k := 0 to h2 - 1 do
              begin
              {$IFDEF WIN64}
                StretchDIBits(dc, x, y+k, w, 1, 0, 0, w2, 1, (img.bigmem + hh) - w32 * k, img.fbmi^, DIB_RGB_COLORS, v);
              {$ENDIF}
              end;
              img.fbmi^.bmiHeader.biHeight := oldh;
            end
            else
            begin
//              ConvertToRGBA(pointer(img.bigmem), pointer(rgba), 1, w2, h2);

              bmp := TBitmap.Create;
              try

                w32 := TBmpFile.slwidth(w2, img.bpp);
                while w32 mod 4 <> 0 do inc(w32);

                oldh := img.fbmi^.bmiHeader.biHeight;
                img.fbmi^.bmiHeader.biHeight := 1;

                case img.bpp of
                  1: bmp.PixelFormat := pf1bit;
                  4: bmp.PixelFormat := pf4bit;
                  8: bmp.PixelFormat := pf8bit;
                  24: bmp.PixelFormat := pf24bit;
                  32: bmp.PixelFormat := pf32bit;
                end;
                
                bmp.Width := w2;
                bmp.Height := h2;

                if img.bpp < 16 then
                begin
                  pal.palVersion := $300;
                  pal.palNumEntries := img.bpp shl 1;

                  for i := 0 to pal.palNumEntries - 1 do
                  begin
                    pal.palPalEntry[i].peRed := img.fbmi^.bmiColors[i].rgbRed;
                    pal.palPalEntry[i].peGreen := img.fbmi^.bmiColors[i].rgbGreen;
                    pal.palPalEntry[i].peBlue := img.fbmi^.bmiColors[i].rgbBlue;
                    pal.palPalEntry[i].peFlags := 0;
                  end;
                 {$IFDEF WIN64}
                  hpal := CreatePalette(PLogPalette(@pal)^);
                  bmp.Palette := hpal;
                  DeleteObject(hpal);
                 {$ENDIF}
                end; 
                hh := (oldh-1)* w32;
                for i := 0 to h2 - 1 do
                begin
                  buf := bmp.ScanLine[i];
                  rgba := (img.bigmem + hh) - w32 * i;
                  move(rgba^, buf^, w32);
                end;
                
                rect.Left := x;
                rect.Top := y;
                rect.Right := x + w;
                rect.Bottom := y + h;

                Canv.StretchDraw(rect, bmp);

{

                hh := (oldh-1)* w32;
                df := 1 / koef;
                dd := y;
                fdf := 0;
                for i := 0 to h - 1 do
                begin
                  k := round(i * koef);
                  StretchDIBits(dc, x, y + i, w, 1, 0, 0, w2, 1, (img.bigmem + hh) - w32 * k,
                        img.fbmi^, DIB_RGB_COLORS, v);
                end;
                if k < (h - 1) then
                begin
                  k := h;
                  i := h;
                  StretchDIBits(dc, x, y + i, w, 1, 0, 0, w2, 1, (img.bigmem + hh) - w32 * k,
                        img.fbmi^, DIB_RGB_COLORS, v);
                end;                                  }
              finally
                bmp.free;
              end;
 

{              for k := 0 to h2 - 1 do
              begin
                for i := 0 to trunc(df)-1 do
                begin
                  StretchDIBits(dc, x, dd, w, 1, 0, 0, w2, 1, (img.bigmem + hh) - w32 * k,
                      img.fbmi^, DIB_RGB_COLORS, v);
                  fdf := fdf + Frac(df);
                  inc(dd);
                  while fdf >= 1 do
                  begin
                    StretchDIBits(dc, x, dd, w, 1, 0, 0, w2, 1, (img.bigmem + hh) - w32 * k,
                        img.fbmi^, DIB_RGB_COLORS, v);
                    fdf := fdf - 1;
                    inc(dd);
                  end;
                end;
              end;  }
              img.fbmi^.bmiHeader.biHeight := oldh;
            end;
          end;


var
  tmpr: TRect;
  k: double;
  drl, drt, h, w: integer;
  dc: HDC;
          function clip_rect(const r1, r2: TRect): TRect;
          begin
            if not print then result := rbitbox.clip_rect(r1, r2)
            else result := rbitbox.clip_rect(RPrin, r2);
          end;
var
  rchg: boolean;
  p1, p2: TRGBQuad;
  zzz: integer;
begin
  if img = nil then exit;
  if (FWidth <= 0) or (FHeight <= 0) then exit;
  if canv = nil then dc := printerdc
  else dc := canv.handle;
  isprintercanvas := canv = nil;

  XKoeff := img.Width / FWidth;
  YKoeff := img.Height / FHeight;
  k := (XKoeff + YKoeff) / 2;

  if k = 0 then exit;
  try
    if k = 0 then exit;
        if left < 0 then drl := 0
    else drl := left;                          
    if top < 0 then drt := 0
    else drt := top;
    if Canv <> nil then
    begin
      if TransParent then Canv.CopyMode := cmSrcAnd
      else Canv.CopyMode := cmSrcCopy;
    end;

    if  img.bpp = 1 then
    begin
      zzz := 1;
      p1 := img.fbmi.bmiColors[0];
      p2 := img.fbmi.bmiColors[zzz];
      img.fbmi.bmiColors[zzz].rgbBlue := GetB(BackColor);
      img.fbmi.bmiColors[zzz].rgbGreen := GetG(BackColor);
      img.fbmi.bmiColors[zzz].rgbRed := GetR(BackColor);

      img.fbmi.bmiColors[0].rgbBlue := GetB(Color);
      img.fbmi.bmiColors[0].rgbGreen := GetG(Color);
      img.fbmi.bmiColors[0].rgbRed := GetR(Color);
    end;

    r := clip_rect(Viewer.ClientRect, Rect(Left, Top, Right, Bottom));
    rchg := false;//EqualRect(r, savedrect);
    savedrect := r;


    if k = 1 then
    begin
      if not rchg then
      begin
        img.savebmp(r.top, r.bottom, r.left, r.right, nil, nil, false);
      end;


      h := img.partHeight;
      w := img.PartWidth;
      DrawRastr(k, TransParent, dc, drl, drt, r.right - r.left, r.bottom - r.top, w, h);
{      if TransParent then
       StretchDIBits(dc, drl, drt, r.right - r.left, r.bottom - r.top,
           0, 0, w, h, img.bigmem, img.fbmi^, DIB_RGB_COLORS, SrcAnd)
      else SetDIBitsToDevice(dc, drl, drt, img.PartWidth, img.partHeight,
           0, 0, 0, img.PartHeight, img.bigmem, img.fbmi^, DIB_RGB_COLORS);}
    end
    else if k > 1 then
    begin
      CreateDynaBits;
      if (DynaX.Count = 0) or (DynaY.Count = 0) then
      begin
//        FillRect(dc, Viewer.ClientRect, GetStockObject(WHITE_BRUSH));
        exit;
      end;
      img.savebmp(r.top, r.bottom, r.left, r.right, DynaX, DynaY, true);

      h := img.partHeight;
      w := img.PartWidth;
      DrawRastr(k, TransParent, dc, drl, drt, r.right - r.left, r.bottom - r.top, w, h);

      {      if TransParent then
       StretchDIBits(dc, drl, drt, r.right - r.left, r.bottom - r.top,
           0, 0, w, h, img.bigmem, img.fbmi^, DIB_RGB_COLORS, SrcAnd)
      else SetDIBitsToDevice(dc, drl, drt, img.PartWidth, img.partHeight,
           0, 0, 0, img.PartHeight, img.bigmem, img.fbmi^, DIB_RGB_COLORS);}
    end
    else if k < 1 then
    begin
      img.savebmp(trunc(r.top * ykoeff), trunc(r.bottom * ykoeff), trunc(r.left * xkoeff), trunc(r.right * xkoeff), nil, nil, false);
      DrawRastr(k, TransParent, dc, drl, drt, trunc((r.right - r.left)), trunc((r.bottom - r.top)), img.fbmi^.bmiHeader.biWidth, img.fbmi^.bmiHeader.biHeight, 1);
{            if TransParent then
        StretchDIBits(dc, drl, drt, trunc((r.right - r.left)), trunc((r.bottom - r.top)),
           0, 0, img.fbmi^.bmiHeader.biWidth, img.fbmi^.bmiHeader.biHeight, img.bigmem, img.fbmi^, DIB_RGB_COLORS, SRCAND)
      else
        StretchDIBits(dc, drl, drt, trunc((r.right - r.left)), trunc((r.bottom - r.top)),
           0, 0, img.fbmi^.bmiHeader.biWidth, img.fbmi^.bmiHeader.biHeight, img.bigmem, img.fbmi^, DIB_RGB_COLORS, SRCCOPY);
}    end;
  except
    on e: exception do
      MessageError(pChar(e.message));
  end;
  if  img.bpp = 1 then
  begin
    zzz := 1;
    img.fbmi.bmiColors[0] := p1;
    img.fbmi.bmiColors[zzz] := p2;
  end;
end;


{function TPCXBox.GetPixel(X, Y: integer): integer;
begin
  result := img.GetPixel(x, y);
end;
 }
function TPCXBox.biHeight: Integer;
begin
  if img <> nil then Result := img.Height;
end;

function TPCXBox.biWidth: Integer;
begin
  if img <> nil then Result := img.Width;
end;

function TPCXBox.DPI: integer;
begin
  if img <> nil then Result := img.dpi
  else result := -1;
end;

function TPCXBox.PPM: integer;
begin
  if img <> nil then Result := img.ppm
  else Result:=-1;
  If Result=0 then Result:=Round(1000/25.4*96);
end;

procedure TPCXBox.initBmi(const fn: AnsiString; w, h: integer);
var bi: TBitmapInfoHeader;
    bfh: TBitmapFileHeader;
begin
  bfh.bfType := $4d42;
  bfh.bfSize := 0;
  bfh.bfReserved1 := 0;
  bfh.bfReserved2 := 0;
  bfh.bfOffBits := sizeof(bfh) + sizeof(bi) + sizeof(TRGBquad) * 2;
  bi.biSize := sizeof(bi);
  bi.biWidth := w;
  bi.biHeight := h;
  bi.biPlanes := 1;
  bi.biBitCount := 1;
  bi.biCompression := BI_RGB;
  bi.biSizeImage := 0;
  bi.biXPelsPerMeter := PPM;
  bi.biYPelsPerMeter := PPM;
  bi.biClrUsed := 0;
  bi.biClrImportant := 0;
  bmi.bminfo.bmiHeader := bi;
  if img <> nil then
    move(bmi, img.fbmi^, sizeof(bi) + sizeof(TRGBQuad) * 2);
  bmFile^ := bfh;
end;

procedure TPCXBox.AfterTrans;
begin
  if (img is tpcx2file) then
  begin
    TPcx2File(img).BmpToPcx(s1, s2);
//    DeleteFile(s2);
  end;
end;

constructor TPCXBox.Create(aowner: TComponent);
begin
  inherited;
  new(bmFile);
  SetPalette(clBlack, clWhite);
  querydpi := true;
  FMaxDiv := MaxIntArr;
end;

destructor TPCXBox.Destroy;
begin
{$IFDEF WIN64}
  if fpal <> 0 then DeleteObject(fpal);
{$ENDIF}
  dispose(bmfile);
  inherited;
end;

procedure TPCXBox.SetPalette(color, bkcolor: TColor);
var pal: TMaxLogPalette;
begin
  pal.palVersion := $300;
  pal.palNumEntries := 2;
  pal.palPalEntry[0].peRed := getR(color);
  pal.palPalEntry[0].peGreen := getG(color);
  pal.palPalEntry[0].peBlue := getB(color);
  pal.palPalEntry[0].peFlags := 0;
  pal.palPalEntry[1].peRed := getR(bkcolor);
  pal.palPalEntry[1].peGreen := getG(bkcolor);
  pal.palPalEntry[1].peBlue := getB(bkcolor);
  pal.palPalEntry[1].peFlags := 0;
{$IFDEF WIN64}
  if fpal <> 0 then DeleteObject(fpal);
  fpal := CreatePalette(PLogPAlette(@pal)^);
{$ENDIF}
end;

{procedure TPCXBox.SetPixel(X, Y: integer; value: integer);
begin
  img.SetPixel(x, y, value);
end;
 }
function TPCXBox.CreateNewBitmap(Box: TBitBox; FN: AnsiString; W, H: Integer): boolean;
var i, j, k, zzzz, isz: integer;
    bi: TBitmapInfoHeader;
    bfh: TBitmapFileHeader;
    pal: array[0..255] of TRGBQuad;
    buf: TBufStream;
    p: PAnsiChar;
    bsw, sss: integer;
    c: byte;
    bbb: PByteArray;
begin
  result := false;
  initBmi(fn, w, h);
  width := w; height := h;
  c := 0;
  buf := TBufStream.InitFileStream(fn, fmCreate or fmShareDenyWrite);
  try
    try
    result := true;
      bfh.bfType := $4d42;
      bfh.bfSize := 0;
      bfh.bfReserved1 := 0;
      bfh.bfReserved2 := 0;
      bfh.bfOffBits := 0;
      buf.Write(bfh, sizeof(bfh));
      with bi do
      begin
        biSize := sizeof(bi);
        biWidth := Width;
        biHeight := Height;
        biPlanes := 1;
        biBitCount := TPCXBox(box).img.bpp;
        biCompression := BI_RGB;
        biSizeImage := 0;
        biXPelsPerMeter := round(TPCXBox(box).DPI / 0.0254);
        biYPelsPerMeter := round(TPCXBox(box).DPI / 0.0254);
        biClrUsed := 0;
        biClrImportant := 0;
      end;
      buf.Write(bi, sizeof(bi));
      zzzz := (1 shl TPCXBox(box).img.bpp);
      if TPCXBox(box).img.bpp < 24 then
        for i := 0 to zzzz - 1 do
        begin
          pal[i].rgbBlue := TPCXBox(box).img.fbmi.bmiColors[i].rgbBlue;
          pal[i].rgbRed := TPCXBox(box).img.fbmi.bmiColors[i].rgbRed;
          pal[i].rgbGreen := TPCXBox(box).img.fbmi.bmiColors[i].rgbGreen;
          pal[i].rgbReserved := 0;
        end;
      if TPCXBox(box).img.bpp < 24 then
        buf.Write(pal, sizeof(pal[0]) * zzzz);

      bfh.bfOffBits := buf.position;
      isz := getimgSize4(w, TPCXBox(box).img.bpp);
      Getmem(bbb, isz);
      try
{        case TPCXBox(box).img.bpp of
          1:
          4, 8: g_backColor := 1;
          24, 32: g_backColor := $ffffff00;
        end;}
        if TPCXBox(box).img.bpp < 24 then fillChar(bbb^, isz, $ff)
        else fillChar(bbb^, isz, $ff{ffffff});
        for i := 0 to  h - 1 do
          buf.Write(bbb^, isz);
      finally
        freemem(bbb);
      end;
      buf.FlushBuffer;
      buf.Position := 0;
      bfh.bfSize := buf.Size;
      buf.Write(bfh, sizeof(bfh));
    finally
      buf.Free;
    end;
  except
    on e: Exception do
    begin
      MessageError(PChar(e.Message));
      result := false;
    end;
  end;
//  readln;
end;


function TPCXBox.GetBackColor: Integer;
var i, j: integer;
    c, b, w: integer;
begin
  if img.bpp <> 1 then
  begin
    g_backColor := $fffffff{f};
    exit;
  end;
  with img.fbmi.bmiColors[0] do
    g_backColor := ord(not ((rgbBlue = 255) and (rgbGreen = 255) and (rgbRed = 255)));
{  b := 0 ;
  w := 0 ;


  for i := 0 to Height - 1 do
  begin
    for j := 0 to Width - 1 do
    begin
      c := GetPixel(j, i);
      if c = 0 then inc(b)
      else inc(w);
    end;
  end;
  if w > b then g_backColor := 1
  else g_backColor := 0;}
  Result := g_backColor;
end;

procedure TPCXBox.GetImgRect(l, t, w, h: integer; var v: TIntArr);
var
  i, j, c1, c2: integer;
  p: pAnsiChar;
begin
  c1 := h - 1;
  c2 := w - 1;
  for i := 0 to c1 do
    for j := 0 to c2 do
       v[i, j] := getpixel(l + j, t + i);
end;

procedure TPCXBox.Divide;
begin
  fTileX := (img.Width div FMaxDiv) + ord(img.Width mod FMaxDiv <> 0);
  FTileY := (img.Height div FMaxDiv) + ord(img.Height mod FMaxDiv <> 0);
  FDivisionX := FMaxDiv;
  FDivisionY := FMaxDiv;
end;

function TPCXBox.GetDivH(i: integer): integer;
begin
  result := FDivisionY;
  if (i + 1)* FDivisionY  >= img.Height then result := (i + 1)* FDivisionY - img.Height;
end;

function TPCXBox.GetDivW(i: integer): integer;
begin
  result := FDivisionX;
  if (i + 1)* FDivisionX >= img.Width then result := (i + 1)* FDivisionX - img.Width;
end;

procedure TPCXBox.SetImgRect(l, t, w, h: integer; var v: TIntArr; sx, sy, sx2, sy2: integer);
var
  i, j, c1, c2: integer;
begin
  c1 := h - 1 - sy2;
  c2 := w - 1 - sx2;
  for i := sy to c1 do
    for j := sx to c2 do
       Setpixel(l + j - sx, t + i - sy, v[i, j]);
end;


class function TPCXBox.ConvertToRGBA(var src, dest: pointer; bpp, w, h: integer): boolean;
var
  i, j, wb2, w32: integer;
  sline: pointer;
  dline: PIntArray;
  f: TFileStream;
begin
  writeln(w, ' ', h);
  result := true;
  wb2 := ((w + 7) div 8);
  while wb2  mod 4 <> 0 do inc(wb2);

  w32 := w * 4;
  while w32 mod 4 <> 0 do inc(w32);

  getmem(dest, w32 * h);
  try
    for i := 0 to h - 1 do
    begin
      sline := pointer(integer(src) + i * wb2);
      dline := pointer(integer(dest) + i * w32);
      for j := 0 to w - 1 do
      begin
        if GetScanPixel2(j, sline) = 0 then dline[j] := 0
        else dline[j] := $ffffff;
        write(dline[j], ' ');
      end;
      writeln;
    end;
  if (w > 0) and (h > 0) then
  begin
    f := TFileStream.Create('c:\x.raw', fmCreate or fmShareDenyWrite);
    try
        f.Write(w, 4);
        f.Write(h, 4);
        w32 := w32 * h;
        f.Write(w32, 4);
        f.Write(dest^, w32);
    finally
      f.free;
    end;
  end;

  finally
    freemem(dest);
    dest := nil;
    result := false;
  end;
end;

{procedure TPCXBox.SwapBWPal;
var
  c: integer;
begin
  if img.bpp <> 1 then
    raise Exception.Create('Операция работает только для черно-белых изображений!');
  c := Color;
  color := BackColor;
  BackColor := c;

  if  img.bpp = 1 then
  begin
    c := 1;
    img.fbmi.bmiColors[c].rgbBlue := GetBValue(BackColor);
    img.fbmi.bmiColors[c].rgbGreen := GetGValue(BackColor);
    img.fbmi.bmiColors[c].rgbRed := GetRValue(BackColor);

    img.fbmi.bmiColors[0].rgbBlue := GetBValue(Color);
    img.fbmi.bmiColors[0].rgbGreen := GetGValue(Color);
    img.fbmi.bmiColors[0].rgbRed := GetRValue(Color);
  end;
end;  }

end.
