unit Unit1;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls,
 gd_dockingengine, gd_dockingbase, gd_dockingoptions, Unit3;

type

 { TForm1 }

 TForm1 = class(TForm)
  GlassDockEngine1: TGlassDockEngine;
  GlassDockOptions1: TGlassDockOptions;
  GlassDockPanel1: TGlassDockPanel;
  procedure FormCreate(Sender: TObject);
  procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
  procedure GlassDockPanel1EndDock(Sender, Target: TObject; X, Y: Integer);
  procedure GlassDockPanel1SizeConstraintsChange(Sender: TObject);
 private
  FTopPanel: TGlassDockPanel;
  FDockPanel: TGlassDockPanel;
  FTestForm: TTestDockForm;
  FTestForm2: TTestDockForm;

 public
  
 end;

var
 Form1: TForm1;

implementation

{$R *.frm}

procedure TForm1.FormCreate(Sender: TObject);
var
 Site: TGlassDockHostSite;
 LayoutFile: String;
begin
 Sender := Sender;
 Application.CreateForm(TTestDockForm, FTestForm);
 FTestForm.Show;
 Application.CreateForm(TTestDockForm, FTestForm2);
 FTestForm2.Show;
 LayoutFile := ExtractFilePath(ParamStr(0)) + 'docklayout.xml';
// if FileExists(LayoutFile) then
//  GlassDockEngine1.LoadAllFromFile(LayoutFile);
// GlassDockEngine1.DockMaster.MakeDockable(FTestForm);
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
var
 LayoutFile: String;
begin
 Sender := Sender;
 CloseAction := CloseAction;
 LayoutFile := ExtractFilePath(ParamStr(0)) + 'docklayout.xml';
 GlassDockEngine1.SaveAllToFile(LayoutFile);
end;

procedure TForm1.GlassDockPanel1EndDock(Sender, Target: TObject; X, Y: Integer);
begin

end;

procedure TForm1.GlassDockPanel1SizeConstraintsChange(Sender: TObject);
begin
end;

end.

