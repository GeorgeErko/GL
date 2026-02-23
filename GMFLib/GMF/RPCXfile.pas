unit RPCXfile;

interface uses {$IFDEF WIN64}Windows,{$ELSE} LCLType, {$ENDIF} SysUtils, Classes, Graphics, Collect, RSBmp, RBitBox, RBMPFile;

type

  TDinArr = array of pointer;
  TDinBArr = array of byte;
  PIntArray = ^TIntArray;
  TIntArray = array[0..maxint div 16] of integer;
  TRGBArr = array[0..255] of TRGBQuad;


  TPCXHdr = packed record
    Signature      :  byte;
    Version        :  byte;
    Encoding       :  byte;
    BitsPerPixel   :  byte;
    XMin,YMin,
    XMax,YMax      :  word;
    HRes,VRes      :  word;
    Palette        :  array [0..47] of byte;
    Reserved       :  byte;
    Planes         :  byte;
    BytesPerLine   :  word;
    PaletteType    :  word;
    Filler         :  array [0..57] of byte;
  end;

  TPcx2file = class(TSimpleBmp)
  private
    function GetPixel24(X, Y: integer): integer;
    procedure SetPixel24(x, y, v: integer);
    function ReadDpi(fn: AnsiString): integer; override;
    procedure WriteDpi(fn: AnsiString; dpi: integer); override;
  public
    planew, planew2: integer;
    colorcount: integer;
    hdr: TPCXHdr;
    constructor Create(const fn: TFilename; readonly: boolean; inmemory: boolean = false; QUERYDPI: boolean = true);
    procedure ReadHdr; override;
    procedure ReadPal;
    procedure ReadScan(var p: PAnsiChar); override;
    procedure GetSlPart24(p, bigmemcur: PByteArray; usedyna: boolean);

    procedure Save(const fn: AnsiString); override;
    class function BmpToPcx(const bmpfn, pcxfn: AnsiString; adpi: integer = 0): boolean;
    function PcxToBmp(const bmpfn: AnsiString): boolean;
  end;


implementation uses newProcs;

function slwidth(w: integer; bpp: byte): integer;
begin
  case bpp of
    1 : result := (w + 7) div 8;
    4 : result := w div 2 + ord(odd(w));
    8 : result := w;
    24: result := w * 3;
    32: result := w * 4;
  else raise Exception.Create('Ошибка: число битов на пиксел задано не верно');
  end;
  if odd(result) then inc(result); 
end;

{ TPcx2file }

procedure TPcx2file.ReadHdr;
begin
  try
    move(fp^, hdr, sizeof(hdr));
    inc(fp, sizeof(hdr));
    if (hdr.Signature <> $A) or (hdr.Encoding <> 1) then   raise Exception.Create('Неверный формат файла');
  except
    on e: EAccessViolation do  raise Exception.Create('Неверный формат файла');
    else raise;
  end;
  FWidth := hdr.XMax - hdr.XMin + 1;
  FHeight := hdr.YMax - hdr.YMin + 1;

  fslsize := hdr.Planes * hdr.BytesPerLine;
  fbpp := hdr.Planes * hdr.BitsPerPixel;
  fdpi := hdr.HRes;
  fppm := Round(fdpi / 0.0254);

  GetMem(ScanLine, slsize);
  GetLines(fp);
  InitBMI;
  fbmi.bmiHeader.biXPelsPerMeter := fppm;
  fbmi.bmiHeader.biYPelsPerMeter := fppm;

  readpal;
end;

procedure TPcx2file.ReadPal;
var p: pAnsiChar;
    i: integer;
    k: byte;
    q: TRGBQuad;
begin
  colorcount := 1 shl bpp;
  if bpp <> 24 then
  begin
    if (hdr.Version = 5) and (pAnsiChar(pAnsiChar(hmap) + filesize - 769)^ = #$C) then
    begin
      p := pAnsiChar(pAnsiChar(hmap) + filesize - 768);
        for i := 0 to colorcount - 1 do
        begin
          fbmi.bmiColors[i].rgbRed := byte(p^); inc(p);
          fbmi.bmiColors[i].rgbGreen := byte(P^); inc(p);
          fbmi.bmiColors[i].rgbBlue := byte(p^); inc(p);
          fbmi.bmiColors[i].rgbReserved := 0;
        end;
    end
    else
    begin
      k := 0;
      if bpp <> 8 then
        for i := 0 to colorcount - 1 do
        begin
          fbmi.bmiColors[i].rgbRed := hdr.palette[k];
          fbmi.bmiColors[i].rgbGreen := hdr.palette[k + 1];
          fbmi.bmiColors[i].rgbBlue := hdr.palette[k + 2];
          inc(k, 3);
          fbmi.bmiColors[i].rgbReserved := 0;
        end
    end;
  end;
  if FInvBWPal and (FBpp = 1) then
  begin
    i := 1;
    q := fbmi.bmiColors[i];
    fbmi.bmiColors[i] := fbmi.bmiColors[0];
    fbmi.bmiColors[0] := q;
  end;
end;

procedure TPCX2File.ReadScan(var p: PAnsiChar);
var rlen, rval: byte;
    index, i: integer;
begin
  if fp = nil then raise Exception.Create('Неожиданный конец файла');
  index := 0;
  repeat
    if (byte(p^) and $C0) = $C0 then
    begin
      rlen := byte(p^) and $3F;
      if (p - hmap) < filesize then inc(p);
      rval := byte(p^);
    end
    else
    begin
      rlen := 1;
      rval := byte(p^);
    end;                           
    if (p - hmap) < filesize then inc(p);
    for i := 0 to rlen - 1 do
    begin
      if index >= slsize then exit;
      ScanLine[index] := rval;
      inc(index);
    end;
  until (index >= slsize);
(*  if FBpp = 24 then
  begin
    index := 0;
    for i := 0 to slsize div 3 - 1 do
    begin
      scanline[index] := ord(p[i + hdr.BytesPerLine * 2]);
      scanline[index + 1] := ord(p[i + hdr.BytesPerLine]);
      scanline[index + 2] := ord(p[i]);

{      rval := scanline[index];
      scanline[index] := scanline[index + 2];
      scanline[index + 2] := rval;
      inc(index, 3);}
    end;
  end;  *)
end;

procedure EncodeScan(buf: PByteArray; buf2: TBufStream; ssize: integer);
var i, j: integer;
    count: byte;
begin
  j := 0;
  while j < ssize do
  begin
    i := 0;
    while (buf[j + i] = buf[j + i + 1]) and (j + i + 1 < ssize) and (i < 63) do inc(i);
    if i > 1 then
    begin
      count := i or 192;
      buf2.Write(count, sizeof(byte));
      buf2.Write(buf[j], sizeof(byte));
      inc(j, i);
    end
    else
    begin
      if (buf[j] and 192) = 192 then
      begin
        count := 193;
        buf2.Write(count, sizeof(byte));
      end;
      buf2.Write(buf[j], sizeof(byte));
      inc(j);
    end;
  end;
end;

class function TPcx2file.BmpToPcx(const bmpfn, pcxfn: AnsiString; adpi: integer): boolean;
var bmp: TBmpFile;
    rhdr: TPCXHdr;
    i, j, k, pcw, bsl: integer;
    buf: TBufStream;
    c: AnsiChar;
    arr, sarr: pByteArray;
begin
  result := false;
  bmp := TBmpFile.Create(bmpfn, True, False, False);
  try
    with rhdr do
    begin
      Signature := $0A;
      Version := 5;
      Encoding := 1;
      BitsPerPixel := bmp.bpp;
      XMin := 0;
      YMin := 0;
      XMax := bmp.Width - 1;
      YMax := bmp.Height - 1;
      if adpi = 0 then HRes := bmp.dpi
      else HRes := adpi;
      VRes := hres;

      if BitsPerPixel = 24 then
      begin
        pcw := slwidth(xmax, 8);
        Planes := 3;
        BitsPerPixel := 8;
      end
      else
      begin
        pcw := slwidth(xmax, BitsPerPixel);
        Planes := 1;
        BitsPerPixel := bmp.bpp;
      end;
      pcw := pcw + ord(odd(pcw));
      Reserved := 0;
      BytesPerLine := pcw;
      PaletteType := 0;
    end;

    if bmp.bpp < 8 then
    begin
      j := 0;
      for i := 0 to 1 shl bmp.bpp - 1 do
        with bmp.fbmi.bmiColors[i] do
        begin
          rhdr.Palette[j] := rgbRed;
          rhdr.Palette[j + 1] := rgbGreen;
          rhdr.Palette[j + 2] := rgbBlue;
          inc(j, 3);
        end;
    end;

    buf := TBufStream.InitFileStream(pcxfn, fmCreate);
    try
      buf.Write(rhdr, sizeof(rhdr));
      if rhdr.Planes = 1 then
        for i := 0 to bmp.Height - 1 do
          EncodeScan(PBytearray(bmp.SLStarts[i]), buf, pcw)
      else
      begin
        try
          getMem(arr, pcw * 3);
          for i := 0 to bmp.Height - 1 do
          begin
            k := 0;
            sarr := PBytearray(bmp.SLStarts[i]);
            for j := 0 to rhdr.XMax do
            begin
              arr[j] := sarr[k + 2];
              arr[j + pcw] := sarr[k + 1];
              arr[j + pcw * 2] := sarr[k];
              inc(k, 3);
            end;
            EncodeScan(arr, buf, pcw * 3);
          end;
        finally
          freemem(arr);
        end;
      end;

      if (rhdr.BitsPerPixel = 8) and (rhdr.Planes = 1) then
      begin
        c := #$C;
        buf.Write(c, 1);
        for i := 0 to 255 do
          with bmp.fbmi.bmiColors[i] do
          begin
            buf.Write(rgbRed, sizeof(byte));
            buf.Write(rgbGreen, sizeof(byte));
            buf.Write(rgbBlue, sizeof(byte));
          end;
      end;
    finally
      buf.free;
    end;
  finally
    bmp.Free;
  end;
  result := true;
end;

(*
class function TPcx2file.BmpToPcx(const bmpfn, pcxfn: AnsiString): boolean;
var i, j: integer;
    bi: TBitmapInfoHeader;
    bfh: TBitmapFileHeader;
    pal: TRGBArr;
    rhdr: TPCXHdr;
    buf2, buf: TBufStream;
    bslwid, pcw: integer;
    parr, parr2: PByteArray;
    c: AnsiAnsiChar;
    k, t: integer;
    b, b2, b3: byte;
    bprp1, bprp2: integer;
begin
  result := true;
  try
    buf := TBufStream.InitFileStream(bmpfn, fmOpenRead or fmShareDenyWrite);
    try
      buf.read(bfh, sizeof(bfh));
      if (bfh.bfType <> $4d42) {or (bfh.bfsize <> buf.size)} then raise Exception.Create('Неверный формат файла');
      buf.Read(bi, sizeof(bi));
  //      if (bi.biBitCount = 24) or (bi.biCompression <> bi_rgb) then
//        raise Exception.Create('Изображения с количеством цветов больше 256 не поддерживаются.');
      if bi.biBitCount <= 8 then
        buf.Read(pal, sizeof(trgbquad) * (1 shl bi.biBitCount));
      if bi.biBitCount = 24 then bslwid := slwidth(bi.biWidth, 8)
      else bslwid := slwidth(bi.biWidth, bi.biBitCount);
      pcw := bslwid + ord(odd(bslwid));
      while bslwid mod 4 <> 0 do inc(bslwid);
      FillAnsiChar(rhdr, sizeof(rhdr), 0);
      with rhdr do
      begin
        Signature := $0A;
        Version := 5;
        Encoding := 1;
        BitsPerPixel := bi.biBitCount;
        XMin := 0;
        YMin := 0;
        XMax := bi.biWidth - 1;
        YMax := bi.biHeight - 1;
        HRes := round(bi.biXPelsPerMeter * 0.0254);
        VRes := round(bi.biYPelsPerMeter * 0.0254);
        if BitsPerPixel < 8 then
        begin
          j := 0;
          for i := 0 to 1 shl BitsPerPixel - 1 do
          begin
            Palette[j] := pal[i].rgbRed;
            Palette[j + 1] := pal[i].rgbGreen;
            Palette[j + 2] := pal[i].rgbBlue;
            inc(j, 3);
          end;
        end;
        if bi.biBitCount = 24 then
        begin
          Planes := 3;
          BitsPerPixel := 8;
        end
        else
        begin
          Planes := 1;
          BitsPerPixel := bi.biBitCount;
        end;

        Reserved := 0;
        BytesPerLine := pcw;
        PaletteType := 0;
      end;
      buf2 := TBufStream.InitFileStream(pcxfn, fmCreate);
      try
        GetMem(parr, bslwid);
        try
          buf2.Write(rhdr, sizeof(rhdr));
          j := bfh.bfOffBits;
          if rhdr.BitsPerPixel < 24 then
            for i := rhdr.ymax downto rhdr.ymin do
            begin
              buf.Seek(bslwid * i + j, soFromBeginning);
              buf.Read(parr^, bslwid);
              EncodeScan(parr, buf2, pcw);
            end
          else
          begin
            GetMem(parr2, pcw * 3);
            try
              for i := rhdr.ymax downto rhdr.ymin do
              begin
                buf.Seek(bslwid * i + j, soFromBeginning);
                buf.Read(parr^, bslwid);
                t := 0;
                for k := 0 to pcw - 1 do
                begin
                  b := parr^[t];
                  b2 := parr^[t + 1];
                  b3 := parr^[t + 2];

                  parr2^[k] := b2;
                  parr2^[k + pcw] := b;
                  parr2^[k + pcw * 2] := b3;
                  inc(t, 3);
                end;

                EncodeScan(parr2, buf2, pcw * 3)
              end;
            finally
              freemem(parr2);
            end;
          end;
{              t := 0;
             for k := 0 to pcw - 1 do
              begin
                b := parr^[t + 1];
                parr^[t + 1] := parr^[t + pcw];
                parr^[t + pcw] := b;

                b := parr^[t + 2];
                parr^[t + 2] := parr^[t + pcw * 2];
                parr^[t + pcw * 2] := b;
                inc(t, 3);
              end;
              EncodeScan(parr, buf2, pcw * 3);
            end;          }
        finally
          FreeMem(parr);
        end;
        if bi.biBitCount = 8 then
        begin
          c := #$C;
          buf2.Write(c, 1);
          for i := 0 to 255 do
          begin
            buf2.Write(pal[i].rgbRed, sizeof(byte));
            buf2.Write(pal[i].rgbGreen, sizeof(byte));
            buf2.Write(pal[i].rgbBlue, sizeof(byte));
          end;
        end;
      finally
        buf2.free;
       end;
    finally
      buf.Free;
    end;
  except
    on e: Exception do
    begin
      MessageBox(0, PAnsiAnsiChar(e.Message), 'Ошибка', MB_OK or MB_ICONERROR);
      result := false;
    end;
  end;
end;
*)
function TPcx2file.PcxToBmp(const bmpfn: AnsiString): boolean;
var i, j, k: integer;
    bi: TBitmapInfoHeader;
    bfh: TBitmapFileHeader;
    pal: TRGBArr;
//    pal: array[0..255] of TRGBQuad;
    buf: TBufStream;
    p: PAnsiChar;
    bsw, sss: integer;
const stub: array[0..11] of byte = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
begin
  result := true;
  try
    buf := TBufStream.InitFileStream(bmpfn, fmCreate or fmShareDenyWrite);
    try
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
        biBitCount := bpp;
        biCompression := BI_RGB;
        biSizeImage := 0;
        biXPelsPerMeter := ppm;
        biYPelsPerMeter := ppm;
        biClrUsed := 0;
        biClrImportant := 0;
      end;
      buf.Write(bi, sizeof(bi));
      if bpp < 24 then buf.Write(fbmi.bmiColors, sizeof(TRgbQuad) * colorcount);

      bfh.bfOffBits := buf.position;

      bsw := slwidth(bi.biWidth , bpp);
      while (bsw mod 4) <> 0 do inc(bsw);
      j := bsw - slsize;
      if j > high(stub) then raise Exception.Create('Ошибка 7631');
      if fbpp < 24 then
        for i := height - 1 downto 0 do
        begin
          p := PAnsiChar(SlStarts[i]);
          ReadScan(p);
          buf.Write(ScanLine^, slsize);
          buf.Write(stub, j);
        end
      else
       begin
//        sss := hdr.width div 3;
        for i := height - 1 downto 0 do
        begin
          p := PAnsiChar(SlStarts[i]);
          ReadScan(p);
          for k := 0 to hdr.BytesPerLine - 1 do
          begin
            buf.Write(Scanline[k + planew2], 1);
            buf.Write(Scanline[k + planew], 1);
            buf.Write(Scanline[k], 1);
          end;
          buf.Write(stub, j);
        end;
      end;
      bufnum := 0;
      bfh.bfSize := buf.Size;

      buf.Position := 0;
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
end;

procedure TPcx2file.GetSlPart24(p, bigmemcur: PByteArray;
  usedyna: boolean);
var rbyt: integer;
    i, v: integer;
begin
  rbyt := 0;
  bigmemcur[rbyt] := 0;
  for i := xstart to xend - 1 do
  begin
    if usedyna then v := TInt(FDynaX[i - xstart]).value
    else v := i;
    bigmemcur[rbyt] := p[v + planew * 2];
    inc(rbyt);
    bigmemcur[rbyt] := p[v + planew];
    inc(rbyt);
    bigmemcur[rbyt] := p[v];
    inc(rbyt);
  end;
end;

function TPcx2file.GetPixel24(X, Y: integer): integer;
var p: PAnsiChar;
begin
  if (y < 0) or (y >= height) or (x < 0) or (x >= width) then
  begin
    result := 0;
    exit;
  end;
  if bufnum <> y then
  begin
    bufnum := y;
    p := pointer(SlStarts[y]);
    ReadScan(p);
  end;
  if (y < 0) or (y > height) or (x < 0) or (x > width) then exit;
  result := ((ScanLine[x] shl 16) and $00ff0000) or
            ((ScanLine[x + planew] shl 8) and $0000ff00) or
            ((ScanLine[x + planew2]) and $000000ff);
end;

procedure TPcx2file.SetPixel24(x, y, v: integer);
var p: PAnsiChar;
begin
  if (y < 0) or (y >= height) or (x < 0) or (x >= width) then exit;
  p := PAnsiChar(SlStarts[y] + x);
  p^ := AnsiChar(chr((v shr 24) and $000000ff));
  inc(p, planew);
  p^ := AnsiChar(chr((v shr 16) and $000000ff));
  inc(p, planew);
  p^ := AnsiChar(chr((v shr 8) and $000000ff))
end;

constructor TPcx2file.Create(const fn: TFilename; readonly,
  inmemory: boolean; querydpi: boolean);
begin
  INHERITED;
  if bpp = 24 then
  begin
    planew := hdr.BytesPerLine;
    planew2 := planew * 2;
    GetSlPart := GetSlPart24;
    SetPixel := SetPixel24;
    GetPixel := GetPixel24;
  end;
end;

function TPcx2file.ReadDpi(fn: AnsiString): integer;
var
  f: TFileStream;
begin
  f := TFileStream.Create(fn, fmOpenRead or fmShareDenyWrite);
  try
    f.Read(hdr, sizeof(hdr));
    result := hdr.HRes;
  finally
    f.free;
  end;
end;

procedure TPcx2file.WriteDpi(fn: AnsiString; dpi: integer);
var
  f: TFileStream;
begin
  f := TFileStream.Create(fn, fmOpenReadWrite);
  try
    f.read(hdr, sizeof(hdr));
    f.Seek(0, soFromBeginning);
    hdr.HRes := dpi;
    hdr.VRes := dpi;
    f.write(hdr, sizeof(hdr));
  finally
    f.free;
  end;
end;

procedure TPcx2file.Save(const fn: AnsiString);
var
  pcxhdr: TPCXHdr;
  BUF: TBufStream;
  i, j: integer;
begin
    pcxhdr := hdr;
    if bpp < 8 then
    begin
      j := 0;
      for i := 0 to 1 shl bpp - 1 do
        begin
          pcxhdr.Palette[j] := fbmi.bmiColors[i].rgbRed;
          pcxhdr.Palette[j + 1] := fbmi.bmiColors[i].rgbGreen;
          pcxhdr.Palette[j + 2] := fbmi.bmiColors[i].rgbBlue;
          inc(j, 3);
        end;
    end;

    buf := TBufStream.InitFileStream(fn, fmCreate);
    try
      buf.Write(hmap^, filesize);
      BUF.Position := 0;
      buf.Write(pcxhdr, sizeof(pcxhdr));
    finally
      buf.free;
    end;
end;

end.


