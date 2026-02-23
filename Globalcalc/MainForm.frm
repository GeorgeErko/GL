object frmCalculator: TfrmCalculator
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Калькулятор'
  ClientHeight = 320
  ClientWidth = 450
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  
  object edtDisplay: TEdit
    Left = 10
    Height = 40
    Top = 10
    Width = 280
    Alignment = taRightJustify
    Font.Height = -24
    Font.Name = 'Tahoma'
    ParentFont = False
    ReadOnly = True
    TabOrder = 0
    Text = '0'
  end

  object pnlResult: TPanel
    Left = 300
    Top = 10
    Width = 140
    Height = 300
    BevelOuter = bvLowered
    Color = clWhite
    ParentBackground = False
    TabOrder = 20
    object lblResult: TLabel
      Left = 5
      Top = 5
      Width = 130
      Height = 290
      Alignment = taCenter
      AutoSize = False
      Caption = '0'
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -48
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
      Layout = tlCenter
      WordWrap = True
    end
  end

  object btn7: TButton
    Left = 10
    Top = 60
    Width = 50
    Height = 50
    Caption = '7'
    OnClick = NumberClick
    TabOrder = 1
  end

  object btn8: TButton
    Left = 70
    Top = 60
    Width = 50
    Height = 50
    Caption = '8'
    OnClick = NumberClick
    TabOrder = 2
  end

  object btn9: TButton
    Left = 130
    Top = 60
    Width = 50
    Height = 50
    Caption = '9'
    OnClick = NumberClick
    TabOrder = 3
  end

  object btnDivide: TButton
    Left = 190
    Top = 60
    Width = 50
    Height = 50
    Caption = '/'
    OnClick = OperationClick
    TabOrder = 4
  end

  object btnClear: TButton
    Left = 250
    Top = 60
    Width = 40
    Height = 50
    Caption = 'C'
    OnClick = btnClearClick
    TabOrder = 5
  end

  object btn4: TButton
    Left = 10
    Top = 120
    Width = 50
    Height = 50
    Caption = '4'
    OnClick = NumberClick
    TabOrder = 6
  end

  object btn5: TButton
    Left = 70
    Top = 120
    Width = 50
    Height = 50
    Caption = '5'
    OnClick = NumberClick
    TabOrder = 7
  end

  object btn6: TButton
    Left = 130
    Top = 120
    Width = 50
    Height = 50
    Caption = '6'
    OnClick = NumberClick
    TabOrder = 8
  end

  object btnMultiply: TButton
    Left = 190
    Top = 120
    Width = 50
    Height = 50
    Caption = '*'
    OnClick = OperationClick
    TabOrder = 9
  end

  object btnSqrt: TButton
    Left = 250
    Top = 120
    Width = 40
    Height = 50
    Caption = '√'
    OnClick = btnSqrtClick
    TabOrder = 10
  end

  object btn1: TButton
    Left = 10
    Top = 180
    Width = 50
    Height = 50
    Caption = '1'
    OnClick = NumberClick
    TabOrder = 11
  end

  object btn2: TButton
    Left = 70
    Top = 180
    Width = 50
    Height = 50
    Caption = '2'
    OnClick = NumberClick
    TabOrder = 12
  end

  object btn3: TButton
    Left = 130
    Top = 180
    Width = 50
    Height = 50
    Caption = '3'
    OnClick = NumberClick
    TabOrder = 13
  end

  object btnMinus: TButton
    Left = 190
    Top = 180
    Width = 50
    Height = 50
    Caption = '-'
    OnClick = OperationClick
    TabOrder = 14
  end

  object btnPercent: TButton
    Left = 250
    Top = 180
    Width = 40
    Height = 50
    Caption = '%'
    OnClick = btnPercentClick
    TabOrder = 15
  end

  object btn0: TButton
    Left = 10
    Top = 240
    Width = 110
    Height = 50
    Caption = '0'
    OnClick = NumberClick
    TabOrder = 16
  end

  object btnDecimal: TButton
    Left = 130
    Top = 240
    Width = 50
    Height = 50
    Caption = '.'
    OnClick = btnDecimalClick
    TabOrder = 17
  end

  object btnEquals: TButton
    Left = 190
    Top = 240
    Width = 50
    Height = 50
    Caption = '='
    OnClick = btnEqualsClick
    TabOrder = 18
  end

  object btnPlus: TButton
    Left = 250
    Top = 240
    Width = 40
    Height = 50
    Caption = '+'
    OnClick = OperationClick
    TabOrder = 19
  end

end
