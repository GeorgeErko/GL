object ValueEditForm: TValueEditForm
  Left = 386
  Height = 270
  Top = 257
  Width = 643
  Caption = 'Редактировать значение'
  ClientHeight = 270
  ClientWidth = 643
  OnCreate = FormCreate
  LCLVersion = '7.8'
  object Label1: TLabel
    Left = 12
    Height = 15
    Top = 12
    Width = 81
    Caption = 'Имя значения:'
    Color = clDefault
    ParentColor = False
  end
  object Label2: TLabel
    Left = 12
    Height = 15
    Top = 84
    Width = 56
    Caption = 'Значение:'
    Color = clDefault
    ParentColor = False
  end
  object EditName: TEdit
    Left = 12
    Height = 23
    Top = 32
    Width = 326
    TabOrder = 0
  end
  object EditValue: TEdit
    Left = 12
    Height = 23
    Top = 104
    Width = 326
    TabOrder = 2
  end
  object RadioGroupType: TRadioGroup
    Left = 344
    Height = 240
    Top = 12
    Width = 320
    AutoFill = True
    Caption = 'Тип значения'
    ChildSizing.LeftRightSpacing = 6
    ChildSizing.TopBottomSpacing = 6
    ChildSizing.HorizontalSpacing = 6
    ChildSizing.VerticalSpacing = 6
    ChildSizing.EnlargeHorizontal = crsHomogenousChildResize
    ChildSizing.EnlargeVertical = crsHomogenousChildResize
    ChildSizing.ShrinkHorizontal = crsScaleChilds
    ChildSizing.ShrinkVertical = crsScaleChilds
    ChildSizing.Layout = cclLeftToRightThenTopToBottom
    ChildSizing.ControlsPerLine = 1
    TabOrder = 1
  end
  object ButtonOK: TButton
    Left = 186
    Height = 25
    Top = 164
    Width = 75
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 3
  end
  object ButtonCancel: TButton
    Left = 263
    Height = 25
    Top = 164
    Width = 75
    Caption = 'Отмена'
    ModalResult = 2
    TabOrder = 4
  end
end
