object RegistryMainForm: TRegistryMainForm
  Left = 257
  Height = 378
  Top = 257
  Width = 706
  BorderStyle = bsSingle
  Caption = 'Registry Editor'
  ClientHeight = 358
  ClientWidth = 706
  Menu = MainMenu
  OnClose = FormClose
  OnCreate = FormCreate
  Position = poScreenCenter
  LCLVersion = '7.8'
  object StatusBar: TStatusBar
    Left = 0
    Height = 23
    Top = 335
    Width = 706
    Panels = <>
    SimpleText = 'Готов'
  end
  object Splitter: TSplitter
    Left = 300
    Height = 335
    Top = 0
    Width = 5
  end
  object Tree: TTreeView
    Left = 0
    Height = 335
    Top = 0
    Width = 300
    Align = alLeft
    TabOrder = 0
    OnSelectionChanged = TreeSelectionChanged
  end
  object List: TListView
    Left = 305
    Height = 335
    Top = 0
    Width = 401
    Align = alClient
    Columns = <>
    TabOrder = 1
    ViewStyle = vsReport
    OnDblClick = ListDblClick
  end
  object MainMenu: TMainMenu
    Left = 8
    Top = 8
    object FileMenu: TMenuItem
      Caption = 'Файл'
      object MiNew: TMenuItem
        Caption = 'Новый'
        OnClick = DoNew
      end
      object MiOpen: TMenuItem
        Caption = 'Открыть...'
        OnClick = DoOpen
      end
      object MiSave: TMenuItem
        Caption = 'Сохранить'
        OnClick = DoSave
      end
      object MiSaveAs: TMenuItem
        Caption = 'Сохранить как...'
        OnClick = DoSaveAs
      end
      object MenuItem1: TMenuItem
        Caption = '-'
      end
      object MiExit: TMenuItem
        Caption = 'Выход'
        OnClick = DoExit
      end
    end
    object EditMenu: TMenuItem
      Caption = 'Правка'
      object MiAddSection: TMenuItem
        Caption = 'Добавить раздел'
        OnClick = DoAddSection
      end
      object MiAddValue: TMenuItem
        Caption = 'Добавить значение'
        OnClick = DoAddValue
      end
      object MiEditValue: TMenuItem
        Caption = 'Изменить значение'
        OnClick = DoEditValue
      end
      object MiDelete: TMenuItem
        Caption = 'Удалить'
        OnClick = DoDelete
      end
    end
  end
  object OpenDialog: TOpenDialog
    Title = 'Открыть файл реестра'
    DefaultExt = '.reg'
    Filter = 'Файлы реестра (*.reg)|*.reg|Все файлы (*.*)|*.*'
    Left = 80
    Top = 8
  end
  object SaveDialog: TSaveDialog
    Title = 'Сохранить файл реестра'
    DefaultExt = '.reg'
    Filter = 'Файлы реестра (*.reg)|*.reg|Все файлы (*.*)|*.*'
    Left = 152
    Top = 8
  end
end
