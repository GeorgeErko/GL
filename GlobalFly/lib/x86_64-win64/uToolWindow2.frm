object TToolWindow2: TTToolWindow2
  Left = 329
  Height = 168
  Top = 257
  Width = 207
  Caption = 'TToolWindow2'
  ClientHeight = 168
  ClientWidth = 207
  LCLVersion = '7.8'
  object HeaderPanel: TPanel
    Left = 0
    Height = 16
    Top = 0
    Width = 207
    Align = alTop
    BevelOuter = bvNone
    ClientHeight = 16
    ClientWidth = 207
    Color = clSilver
    ParentColor = False
    TabOrder = 0
    object HeaderLabel: TLabel
      Left = 6
      Height = 15
      Top = 0
      Width = 22
      Caption = 'Tool'
    end
  end
  object ClientPanel: TPanel
    Left = 0
    Height = 152
    Top = 16
    Width = 207
    Align = alClient
    BevelOuter = bvNone
    BorderStyle = bsSingle
    Color = clBtnFace
    ParentColor = False
    TabOrder = 1
  end
end
