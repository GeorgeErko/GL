object StopFrm: TStopFrm
  Left = 300
  Height = 50
  Top = 257
  Width = 187
  BorderStyle = bsNone
  Caption = 'StopFrm'
  ClientHeight = 50
  ClientWidth = 187
  OnActivate = FormActivate
  OnClose = FormClose
  LCLVersion = '7.8'
  object Button1: TButton
    Left = 8
    Height = 25
    Top = 11
    Width = 25
    Cancel = True
    Default = True
    OnClick = Button1Click
    TabOrder = 0
  end
  object Edit1: TEdit
    Left = 40
    Height = 23
    Top = 12
    Width = 136
    TabOrder = 1
  end
end
