unit MainForm;

{$mode Delphi}

interface

uses
 Classes, SysUtils, Forms, LCLType, Controls, Graphics, Dialogs, StdCtrls;

type

 { TForm1 }

 TForm1 = class(TForm)
  Button1: TButton;
 public
   procedure CreateParams(var Params: TCreateParams); override;
 end;

var
 Form1: TForm1;

implementation

{$R *.frm}

{ TForm1 }

procedure TForm1.CreateParams(var Params: TCreateParams);
begin
 inherited CreateParams(Params);
 {$IFNDEF LCLWin32}
  ParentFormHandle := AppHandle;
 {$ENDIF}
end;

end.

