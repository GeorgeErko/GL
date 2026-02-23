unit uChildEditForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Dialogs, StdCtrls, Spin;

type

  { TChildEditForm }

  TChildEditForm = class(TForm)
    btnCancel: TButton;
    btnOK: TButton;
    EHint: TEdit;
    EText: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    seW: TSpinEdit;
  public
    function Execute(var AText, AHint: String; var ABtnWidth: Integer): Boolean;
  end;

implementation

{$R *.frm}

function TChildEditForm.Execute(var AText, AHint: String; var ABtnWidth: Integer): Boolean;
begin
  if EText <> nil then
    EText.Text := AText;
  if EHint <> nil then
    EHint.Text := AHint;
  if seW <> nil then
    seW.Value := ABtnWidth;

  Result := ShowModal = mrOk;
  if not Result then Exit;

  if EText <> nil then
    AText := EText.Text;
  if EHint <> nil then
    AHint := EHint.Text;
  if seW <> nil then
    ABtnWidth := seW.Value;
end;

end.
