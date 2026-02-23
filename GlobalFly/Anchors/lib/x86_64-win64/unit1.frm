object Form1: TForm1
  Left = 329
  Height = 424
  Top = 257
  Width = 556
  Caption = 'Form1'
  ClientHeight = 424
  ClientWidth = 556
  OnCreate = FormCreate
  LCLVersion = '7.8'
  object GlassDockPanel1: TGlassDockPanel
    Left = 0
    Height = 0
    Top = 0
    Width = 556
    Align = alTop
    AutoSize = True
    Caption = 'GlassDockPanel1'
    Constraints.OnChange = GlassDockPanel1SizeConstraintsChange
    TabOrder = 0
    OnEndDock = GlassDockPanel1EndDock
  end
  object GlassDockOptions1: TGlassDockOptions
    Left = 50
    Top = 101
  end
  object GlassDockEngine1: TGlassDockEngine
    Active = True
    DockPanel = GlassDockPanel1
    Left = 183
    Top = 84
  end
end
