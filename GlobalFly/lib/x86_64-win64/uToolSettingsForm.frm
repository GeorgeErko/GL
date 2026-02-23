object ToolSettingsForm: TToolSettingsForm
  Left = 457
  Height = 292
  Top = 257
  Width = 360
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Tool Settings'
  ClientHeight = 292
  ClientWidth = 360
  Position = poScreenCenter
  LCLVersion = '7.8'
  object GroupBox1: TGroupBox
    Left = 169
    Height = 32
    Top = 192
    Width = 77
    BorderSpacing.InnerBorder = 1
    BorderSpacing.CellAlignHorizontal = ccaLeftTop
    BorderSpacing.CellAlignVertical = ccaRightBottom
    ParentBackground = False
    ParentColor = False
    TabOrder = 10
  end
  object gbTool: TGroupBox
    Left = 4
    Height = 56
    Top = 59
    Width = 344
    Caption = 'Tool Window (buttons)'
    ClientHeight = 36
    ClientWidth = 340
    TabOrder = 0
    object lblToolW: TLabel
      Left = 12
      Height = 15
      Top = 12
      Width = 11
      Caption = 'W'
    end
    object seToolW: TSpinEdit
      Left = 28
      Height = 23
      Top = 8
      Width = 56
      TabOrder = 0
      Value = 6
    end
    object lblToolH: TLabel
      Left = 96
      Height = 15
      Top = 12
      Width = 9
      Caption = 'H'
    end
    object seToolH: TSpinEdit
      Left = 112
      Height = 23
      Top = 8
      Width = 56
      TabOrder = 1
      Value = 4
    end
  end
  object gbHPanel: TGroupBox
    Left = 4
    Height = 56
    Top = 123
    Width = 177
    Caption = 'Horizontal panel (buttons)'
    ClientHeight = 36
    ClientWidth = 173
    TabOrder = 1
    object lblHW: TLabel
      Left = 12
      Height = 15
      Top = 12
      Width = 11
      Caption = 'W'
    end
    object seHW: TSpinEdit
      Left = 28
      Height = 23
      Top = 8
      Width = 56
      TabOrder = 0
      Value = 12
    end
    object lblHH: TLabel
      Left = 96
      Height = 15
      Top = 12
      Width = 9
      Caption = 'H'
    end
    object seHH: TSpinEdit
      Left = 112
      Height = 23
      Top = 8
      Width = 56
      TabOrder = 1
      Value = 1
    end
  end
  object gbVPanel: TGroupBox
    Left = 171
    Height = 56
    Top = 122
    Width = 178
    Caption = 'Vertical panel (buttons)'
    ClientHeight = 36
    ClientWidth = 174
    TabOrder = 2
    object lblVW: TLabel
      Left = 12
      Height = 15
      Top = 12
      Width = 11
      Caption = 'W'
    end
    object seVW: TSpinEdit
      Left = 28
      Height = 23
      Top = 8
      Width = 56
      TabOrder = 0
      Value = 1
    end
    object lblVH: TLabel
      Left = 96
      Height = 15
      Top = 12
      Width = 9
      Caption = 'H'
    end
    object seVH: TSpinEdit
      Left = 112
      Height = 23
      Top = 8
      Width = 56
      TabOrder = 1
      Value = 4
    end
  end
  object btnCancel: TButton
    Left = 268
    Height = 28
    Top = 253
    Width = 72
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 3
  end
  object btnOK: TButton
    Left = 180
    Height = 28
    Top = 253
    Width = 72
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 4
  end
  object Label1: TLabel
    Left = 16
    Height = 15
    Top = 21
    Width = 24
    Caption = 'Имя'
  end
  object EName: TEdit
    Left = 52
    Height = 23
    Top = 18
    Width = 291
    TabOrder = 5
  end
  object Label2: TLabel
    Left = 21
    Height = 15
    Top = 200
    Width = 126
    Caption = 'Привязка инструмента'
  end
  object cbLeft: TCheckBox
    Left = 163
    Height = 19
    Top = 198
    Width = 24
    Caption = 'L'
    TabOrder = 6
  end
  object cbTop: TCheckBox
    Left = 201
    Height = 19
    Top = 185
    Width = 24
    Caption = 'T'
    OnChange = cbTopChange
    TabOrder = 7
  end
  object cbRight: TCheckBox
    Left = 241
    Height = 19
    Top = 198
    Width = 25
    Caption = 'R'
    TabOrder = 8
  end
  object cbBottom: TCheckBox
    Left = 201
    Height = 19
    Top = 215
    Width = 25
    Caption = 'B'
    TabOrder = 9
  end
end
