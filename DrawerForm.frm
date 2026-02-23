object Form1: TForm1
  Left = 343
  Height = 560
  Top = 257
  Width = 826
  Caption = 'Form1'
  ClientHeight = 560
  ClientWidth = 826
  OnCreate = FormCreate
  LCLVersion = '7.8'
  object PaintBox1: TPaintBox
    Left = 6
    Height = 469
    Top = 8
    Width = 668
    OnMouseWheel = PaintBox1MouseWheel
    OnPaint = PaintBox1Paint
  end
  object btnUp: TButton
    Tag = 1
    Left = 728
    Height = 25
    Top = 14
    Width = 31
    Caption = 'btnUp'
    OnClick = MoveClick
    TabOrder = 0
  end
  object btnDown: TButton
    Tag = 3
    Left = 728
    Height = 25
    Top = 56
    Width = 31
    Caption = 'btnDown'
    OnClick = MoveClick
    TabOrder = 1
  end
  object btnRight: TButton
    Tag = 2
    Left = 768
    Height = 25
    Top = 32
    Width = 31
    Caption = 'btnRight'
    OnClick = MoveClick
    TabOrder = 2
  end
  object btmLeft: TButton
    Tag = 4
    Left = 688
    Height = 25
    Top = 32
    Width = 31
    Caption = 'btmLeft'
    OnClick = MoveClick
    TabOrder = 3
  end
end
