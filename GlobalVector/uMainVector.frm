object MainVector: TMainVector
  Left = 300
  Height = 600
  Top = 200
  Width = 900
  Caption = 'Main Vector'
  ClientHeight = 580
  ClientWidth = 900
  Menu = MainMenu1
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  LCLVersion = '7.8'
  object PanelLeft: TPanel
    Left = 0
    Height = 580
    Top = 0
    Width = 450
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 0
  end
  object Splitter1: TSplitter
    Left = 450
    Height = 580
    Top = 0
    Width = 6
  end
  object PanelRight: TPanel
    Left = 456
    Height = 580
    Top = 0
    Width = 444
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
  end
  object MainMenu1: TMainMenu
    Left = 24
    Top = 24
    object MenuFile: TMenuItem
      Caption = 'Проект'
      object miOpenProj: TMenuItem
        Caption = 'Открыть...'
        OnClick = miOpenProjClick
      end
      object miSaveProj: TMenuItem
        Caption = 'Сохранить'
        OnClick = miSaveProjClick
      end
      object miSaveAsProj: TMenuItem
        Caption = 'Сохранить как...'
        OnClick = miSaveAsProjClick
      end
    end
  end
  object ODProj: TOpenDialog
    DefaultExt = '.lpj'
    Filter = 'Проект 3D->2D|*.lpj'
    Left = 24
    Top = 72
  end
  object SDProj: TSaveDialog
    DefaultExt = '.lpj'
    Filter = 'Проект 3D->2D|*.lpj'
    Left = 120
    Top = 72
  end
end
