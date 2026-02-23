object ToolForm: TToolForm
  Left = 329
  Height = 376
  Top = 257
  Width = 489
  Caption = 'ToolForm'
  ClientHeight = 356
  ClientWidth = 489
  Menu = MainMenu1
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  LCLVersion = '7.8'
  object pnlTop: TPanel
    Left = 0
    Height = 0
    Top = 0
    Width = 489
    Align = alTop
    AutoSize = True
    BevelOuter = bvNone
    Caption = 'pnlTop'
    TabOrder = 0
  end
  object pnlBottom: TPanel
    Left = 0
    Height = 0
    Top = 339
    Width = 489
    Align = alBottom
    AutoSize = True
    BevelInner = bvLowered
    BevelOuter = bvNone
    Caption = 'pnlBottom'
    TabOrder = 1
  end
  object pnlLeft: TPanel
    Left = 0
    Height = 339
    Top = 0
    Width = 0
    Align = alLeft
    AutoSize = True
    BevelInner = bvLowered
    BevelOuter = bvNone
    Caption = 'pnlLeft'
    TabOrder = 2
  end
  object pnlRight: TPanel
    Left = 489
    Height = 339
    Top = 0
    Width = 0
    Align = alRight
    AutoSize = True
    BevelInner = bvLowered
    BevelOuter = bvNone
    Caption = 'pnlRight'
    TabOrder = 3
  end
  object StaticText1: TStaticText
    Left = 0
    Height = 17
    Top = 339
    Width = 489
    Align = alBottom
    TabOrder = 4
  end
  object MainMenu1: TMainMenu
    Left = 8
    Top = 8
    object miTool: TMenuItem
      Caption = 'Tool'
      object miToolCreate: TMenuItem
        Caption = 'Create'
        OnClick = miToolCreateClick
      end
      object miToolDelete: TMenuItem
        Caption = 'Delete'
        OnClick = miToolDeleteClick
      end
    end
    object miSettings: TMenuItem
      Caption = 'Settings'
      object miSettingsLoad: TMenuItem
        Caption = 'Load'
        OnClick = miSettingsLoadClick
      end
      object miSettingsSave: TMenuItem
        Caption = 'Save'
        OnClick = miSettingsSaveClick
      end
    end
  end
end
