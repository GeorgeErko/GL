unit uChildComboBoxForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Dialogs, StdCtrls, Spin;

type

  { TChildComboBoxForm }

  TChildComboBoxForm = class(TForm)
    btnCancel: TButton;
    btnOK: TButton;
    EHint: TEdit;
    EItems: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    seW: TSpinEdit;
  public
    function Execute(var AItemsDelimited, AHint: String; var ABtnWidth: Integer): Boolean;
  end;

implementation

{$R *.frm}

function TChildComboBoxForm.Execute(var AItemsDelimited, AHint: String; var ABtnWidth: Integer): Boolean;
begin
  if EItems <> nil then
    EItems.Text := AItemsDelimited;
  if EHint <> nil then
    EHint.Text := AHint;
  if seW <> nil then
    seW.Value := ABtnWidth;

  Result := ShowModal = mrOk;
  if not Result then Exit;

  if EItems <> nil then
    AItemsDelimited := EItems.Text;
  if EHint <> nil then
    AHint := EHint.Text;
  if seW <> nil then
    ABtnWidth := seW.Value;
end;

end.
