unit uLasAutoStatesForm;

{$mode Delphi}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
 StdCtrls, Spin;

type

 TLasAutoStatesForm = class(TForm)
 published
  BottomPanel: TPanel;
  BtnCancel: TButton;
  BtnOK: TButton;
  ColorDialog1: TColorDialog;
  PageControl1: TPageControl;
  TabData: TTabSheet;
  TabFilterZ: TTabSheet;
  TabReturns: TTabSheet;
  TabClasses: TTabSheet;
  TabAngle: TTabSheet;
  TabGpsTime: TTabSheet;
  TabFlags: TTabSheet;
  TabColoring: TTabSheet;
  DataScroll: TScrollBox;
  cbIntensity: TCheckBox;
  cbReturnNumber: TCheckBox;
  cbNumberOfReturns: TCheckBox;
  cbScanDirectionFlag: TCheckBox;
  cbEdgeOfFlightLine: TCheckBox;
  cbClassification: TCheckBox;
  cbSyntheticFlag: TCheckBox;
  cbKeypointFlag: TCheckBox;
  cbWithheldFlag: TCheckBox;
  cbScanAngleRank: TCheckBox;
  cbUserData: TCheckBox;
  cbPointSourceID: TCheckBox;
  cbGpsTime: TCheckBox;
  PanelZTop: TPanel;
  cbUseZFilter: TCheckBox;
  cbZMode: TComboBox;
  edZMin: TFloatSpinEdit;
  edZMax: TFloatSpinEdit;
  ShapeZColor: TShape;
  BtnZColor: TButton;
  MemoZInfo: TMemo;
  PanelReturnsTop: TPanel;
  cbUseReturns: TCheckBox;
  MemoReturnsInfo: TMemo;
  PanelClassesTop: TPanel;
  cbUseClasses: TCheckBox;
  MemoClassesInfo: TMemo;
  PanelAngleTop: TPanel;
  cbUseAngle: TCheckBox;
  cbAngleMode: TComboBox;
  edAngleMin: TFloatSpinEdit;
  edAngleMax: TFloatSpinEdit;
  ShapeAngleColor: TShape;
  BtnAngleColor: TButton;
  MemoAngleInfo: TMemo;
  PanelGpsTop: TPanel;
  cbUseGpsTime: TCheckBox;
  cbGpsMode: TComboBox;
  edGpsMin: TFloatSpinEdit;
  edGpsMax: TFloatSpinEdit;
  ShapeGpsColor: TShape;
  BtnGpsColor: TButton;
  MemoGpsInfo: TMemo;
  PanelFlagsTop: TPanel;
  cbUseFlags: TCheckBox;
  MemoFlagsInfo: TMemo;
  PanelColorTop: TPanel;
  cbUseColoring: TCheckBox;
  MemoColorInfo: TMemo;
  procedure BtnCancelClick(Sender: TObject);
  procedure BtnAngleColorClick(Sender: TObject);
  procedure BtnGpsColorClick(Sender: TObject);
  procedure BtnOKClick(Sender: TObject);
  procedure BtnZColorClick(Sender: TObject);
 end;

var
 LasAutoStatesForm: TLasAutoStatesForm;

implementation

{$R *.frm}

procedure TLasAutoStatesForm.BtnOKClick(Sender: TObject);
begin
 ModalResult := mrOk;
end;

procedure TLasAutoStatesForm.BtnCancelClick(Sender: TObject);
begin
 ModalResult := mrCancel;
end;

procedure TLasAutoStatesForm.BtnZColorClick(Sender: TObject);
begin
 if (ShapeZColor = nil) or (ColorDialog1 = nil) then Exit;
 ColorDialog1.Color := ShapeZColor.Brush.Color;
 if ColorDialog1.Execute then
  ShapeZColor.Brush.Color := ColorDialog1.Color;
end;

procedure TLasAutoStatesForm.BtnAngleColorClick(Sender: TObject);
begin
 if (ShapeAngleColor = nil) or (ColorDialog1 = nil) then Exit;
 ColorDialog1.Color := ShapeAngleColor.Brush.Color;
 if ColorDialog1.Execute then
  ShapeAngleColor.Brush.Color := ColorDialog1.Color;
end;

procedure TLasAutoStatesForm.BtnGpsColorClick(Sender: TObject);
begin
 if (ShapeGpsColor = nil) or (ColorDialog1 = nil) then Exit;
 ColorDialog1.Color := ShapeGpsColor.Brush.Color;
 if ColorDialog1.Execute then
  ShapeGpsColor.Brush.Color := ColorDialog1.Color;
end;

end.
