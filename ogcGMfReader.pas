unit ogcGMFReader;

{$mode Delphi}
                                           

interface

uses Classes, SysUtils, ogcBasic, ogcGeometry, gmfGeometry, ogcMapObject,
     ogcCallbackRec, ogcIEObjects;

type
 TOpenFunction = function (AppHandle: THandle; FileName: PChar;
                            CallbackRec_: PCallbackRec): Integer; stdcall;

function OpenGMF(ogsMapObject: TogsMapObject; gmfFileName: string): Integer;
function OpenDWG(ogsMapObject: TogsMapObject; gmfFileName: string): Integer;

implementation uses Forms,
                    ogcWriter, TTFGeometry, feFontEngineObjects, ogcPlayer,
                    ogcProperties;

function OpenGMF(ogsMapObject: TogsMapObject; gmfFileName: string): Integer;
var hLib: THandle;
    openFunc: TOpenFunction;
    IEObject: TIEObject;
begin
 IEObject := ieCreateRootObject(ogsMapObject);
 try
 { загрузка DLL }
 WriteIn(['Load']);
  hLib := SafeLoadLibrary(ExtractFilePath(ParamStr(0))+ 'GMFLib\GMFLib.dll');
  WriteIn(['hLib=', hlib]);
  If hLib <> 0 then begin
   openFunc := GetProcedureAddress(hLib,'OpenGMF');
   If Assigned(openFunc) then
    openFunc(Application.Handle, PChar(gmfFileName), CallbackRec);
   FreeLibrary(hLib);
  end;
 finally
  ieResetRootObject(IEObject);
 end;
end;

function OpenDWG(ogsMapObject: TogsMapObject; gmfFileName: string): Integer;
var hLib: THandle;
    openFunc: TOpenFunction;
    IEObject: TIEObject;
begin
 IEObject := ieCreateRootObject(ogsMapObject);
 try
 { загрузка DLL }
 WriteIn(['Load = ', ExtractFilePath(ParamStr(0))+ 'DWGLib\DWGGL2project.dll']);
  hLib := SafeLoadLibrary(ExtractFilePath(ParamStr(0))+ 'DWGLib\DWGGL2project.dll');
  WriteIn(['hLib=', LongInt(hlib)]);
  If hLib <> 0 then begin
   openFunc := GetProcedureAddress(hLib, 'OpenGMF2');
   If Assigned(openFunc) then
    openFunc(Application.Handle, PChar(gmfFileName), CallbackRec) else
    WriteIn(['OpenFunc = nil']);
   FreeLibrary(hLib);
  end;
 finally
  ieResetRootObject(IEObject);
 end;
end;

end.

