object MonitorForm: TMonitorForm
  Left = 71
  Height = 625
  Top = 0
  Width = 800
  Caption = 'Global Monitor - Work Complex Management'
  ClientHeight = 605
  ClientWidth = 800
  Menu = MainMenu1
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  Position = poScreenCenter
  LCLVersion = '7.8'
  object FilterPanel: TPanel
    Left = 0
    Height = 53
    Top = 528
    Width = 800
    Align = alBottom
    Anchors = [akTop, akLeft, akRight, akBottom]
    BevelOuter = bvLowered
    ClientHeight = 53
    ClientWidth = 800
    TabOrder = 0
    object FilterCombo: TComboBox
      Left = 10
      Height = 23
      Top = 15
      Width = 150
      ItemHeight = 15
      OnChange = FilterComboChange
      Style = csDropDownList
      TabOrder = 0
    end
    object FilterEdit: TEdit
      Left = 170
      Height = 23
      Top = 15
      Width = 300
      OnChange = FilterEditChange
      TabOrder = 1
    end
    object FilterClearButton: TButton
      Left = 480
      Height = 23
      Top = 15
      Width = 100
      Caption = 'Clear Filter'
      OnClick = FilterClearButtonClick
      TabOrder = 2
    end
  end
  object ButtonPanel: TPanel
    Left = 0
    Height = 48
    Top = 480
    Width = 800
    Align = alBottom
    Anchors = [akTop, akLeft, akRight, akBottom]
    BevelOuter = bvLowered
    ClientHeight = 48
    ClientWidth = 800
    TabOrder = 1
    object AddButton: TButton
      Left = 8
      Height = 23
      Top = 12
      Width = 80
      Caption = 'Add'
      OnClick = AddButtonClick
      TabOrder = 0
    end
    object EditButton: TButton
      Left = 100
      Height = 23
      Top = 12
      Width = 80
      Caption = 'Edit'
      OnClick = EditButtonClick
      TabOrder = 1
    end
    object DeleteButton: TButton
      Left = 190
      Height = 23
      Top = 12
      Width = 80
      Caption = 'Delete'
      OnClick = DeleteButtonClick
      TabOrder = 2
    end
    object ProgressButton: TButton
      Left = 280
      Height = 23
      Top = 12
      Width = 100
      Caption = 'Progress'
      OnClick = ProgressButtonClick
      TabOrder = 3
    end
    object GitHubButton: TButton
      Left = 390
      Height = 23
      Top = 12
      Width = 100
      Caption = 'GitHub'
      OnClick = GitHubButtonClick
      TabOrder = 4
    end
    object ActivityButton: TButton
      Left = 500
      Height = 23
      Top = 12
      Width = 100
      Caption = 'Activity'
      OnClick = ActivityButtonClick
      TabOrder = 5
    end
  end
  object StatusPanel: TPanel
    Left = 0
    Height = 24
    Top = 581
    Width = 800
    Align = alBottom
    BevelOuter = bvLowered
    ClientHeight = 24
    ClientWidth = 800
    TabOrder = 2
    object StatusLabel2: TLabel
      Left = 10
      Height = 15
      Top = 8
      Width = 63
      Caption = 'Status Label'
      Color = clDefault
      ParentColor = False
    end
  end
  object MonitorTreeView: TVirtualStringTree
    Left = 0
    Height = 480
    Top = 0
    Width = 400
    Align = alLeft
    DefaultText = 'Node'
    Header.AutoSizeIndex = 0
    Header.Columns = <>
    Header.MainColumn = -1
    Images = ImageList1
    NodeDataSize = 4
    TabOrder = 3
    OnAfterCellPaint = MonitorTreeViewAfterCellPaint
    OnAfterItemPaint = MonitorTreeViewAfterItemPaint
    OnChange = MonitorTreeViewChange
    OnCollapsed = MonitorTreeViewCollapsed
    OnColumnResize = MonitorTreeViewColumnResize
    OnGetText = MonitorTreeViewGetText
    OnGetImageIndex = MonitorTreeViewGetImageIndex
  end
  object DetailsPanel: TPanel
    Left = 400
    Height = 480
    Top = 0
    Width = 400
    Align = alClient
    BevelOuter = bvLowered
    ClientHeight = 480
    ClientWidth = 400
    TabOrder = 4
    object Splitter1: TSplitter
      Left = 1
      Height = 478
      Top = 1
      Width = 10
      OnCanOffset = Splitter1CanOffset
      OnChangeBounds = Splitter1ChangeBounds
    end
    object PC: TPageControl
      Left = 11
      Height = 478
      Top = 1
      Width = 388
      ActivePage = TS2
      Align = alClient
      TabIndex = 1
      TabOrder = 1
      object TS1: TTabSheet
        Caption = 'TS1'
        ClientHeight = 450
        ClientWidth = 380
        object DetailsMemo: TMemo
          Left = 0
          Height = 110
          Top = 340
          Width = 380
          Anchors = [akTop, akLeft, akRight, akBottom]
          ReadOnly = True
          ScrollBars = ssVertical
          TabOrder = 0
        end
        object VLE: TValueListEditor
          Left = 0
          Height = 363
          Top = 1
          Width = 380
          Anchors = [akTop, akLeft, akRight, akBottom]
          FixedCols = 0
          RowCount = 2
          TabOrder = 1
          ColWidths = (
            64
            312
          )
        end
      end
      object TS2: TTabSheet
        Caption = 'TS2'
        ClientHeight = 450
        ClientWidth = 380
        object ProgressChart: TChart
          Left = 8
          Height = 416
          Top = 8
          Width = 356
          AxisList = <          
            item
              Marks.LabelBrush.Style = bsClear
              Minors = <>
              Title.LabelFont.Orientation = 900
              Title.LabelBrush.Style = bsClear
            end          
            item
              Alignment = calBottom
              Marks.LabelBrush.Style = bsClear
              Minors = <>
              Title.LabelBrush.Style = bsClear
            end>
          Title.Text.Strings = (
            'TAChart'
          )
        end
      end
    end
  end
  object MainMenu1: TMainMenu
    Left = 50
    Top = 50
    object FileMenu: TMenuItem
      Caption = 'File'
      object NewThemeMenu: TMenuItem
        Caption = 'New Theme'
        OnClick = NewThemeMenuClick
      end
      object NewTaskMenu: TMenuItem
        Caption = 'New Task'
        OnClick = NewTaskMenuClick
      end
      object NewSubTaskMenu: TMenuItem
        Caption = 'New SubTask'
        OnClick = NewSubTaskMenuClick
      end
      object N1: TMenuItem
        Caption = '-'
      end
      object SaveMenu: TMenuItem
        Caption = 'Save'
        OnClick = SaveMenuClick
      end
      object LoadMenu: TMenuItem
        Caption = 'Load'
        OnClick = LoadMenuClick
      end
      object BackupMenu: TMenuItem
        Caption = 'Create Backup'
        OnClick = BackupMenuClick
      end
      object N2: TMenuItem
        Caption = '-'
      end
      object ExitMenu: TMenuItem
        Caption = 'Exit'
        OnClick = ExitMenuClick
      end
    end
    object EditMenu: TMenuItem
      Caption = 'Edit'
      object DeleteMenu: TMenuItem
        Caption = 'Delete'
        OnClick = DeleteMenuClick
      end
    end
    object ViewMenu: TMenuItem
      Caption = 'View'
      object RefreshMenu: TMenuItem
        Caption = 'Refresh'
        OnClick = RefreshMenuClick
      end
      object N3: TMenuItem
        Caption = '-'
      end
      object ExpandAllMenu: TMenuItem
        Caption = 'Expand All'
        OnClick = ExpandAllMenuClick
      end
      object CollapseAllMenu: TMenuItem
        Caption = 'Collapse All'
        OnClick = CollapseAllMenuClick
      end
      object N4: TMenuItem
        Caption = '-'
      end
      object FilterMenu: TMenuItem
        Caption = 'Filter'
        Enabled = False
      end
    end
    object ToolsMenu: TMenuItem
      Caption = 'Tools'
      object GitHubValidateMenu: TMenuItem
        Caption = 'Validate GitHub Links'
        OnClick = GitHubValidateMenuClick
      end
      object ProgressUpdateMenu: TMenuItem
        Caption = 'Progress Update'
        OnClick = ProgressButtonClick
      end
      object ActivityLogMenu: TMenuItem
        Caption = 'Activity Log'
        OnClick = ActivityLogMenuClick
      end
    end
    object ReportsMenu: TMenuItem
      Caption = 'Reports'
      Enabled = False
    end
    object HelpMenu: TMenuItem
      Caption = 'Help'
      object AboutMenu: TMenuItem
        Caption = 'About'
        OnClick = AboutMenuClick
      end
    end
  end
  object ImageList1: TImageList
    Left = 296
    Top = 16
    Bitmap = {
      4C7A030000001000000010000000EE0200000000000078DAE595DD4B145118C6
      4765D1EDCB8F3233445D0C0C2CDD0B4310625CBAA89B58B3BA0961BD10892D58
      CD882E94954A0889DA2C366DD5A95DC38A2CC2082145B75DDDD5C0A08B082F12
      8AAE8DFA039ECE3BB3A7CEAC33BADB4544CDF0CCCE39F33EBFF3CE99F79C8504
      D3536A63172648E99DE4C93A970DEBF57CE4F8F25366505C4E572E72FDA52878
      BC075B1FED46D6F016586E6E5E9741CFF2AE956167703F8A276A91F7B412D90F
      8A50F4B002AE482B0A43C5C8B89169C8A8B86853FBCB5E1D42E9E441EC78B60F
      352F1DB8F4AE0F9FBE7FC6D49769548FD7401A60C1B7D6CE4749B70DBD93BD6A
      7FDE44354ECEB561F9DB47BCFFFA017478E63B20F5B3C041A6BB4CB7F58CFCFE
      4AB5CD19652F6AB1F7791DACA14228CBF7554667AC13923FE10F30DDF9C5D8D4
      B51D2553B28E611D2B464EA80005A3BB105C0EA2FB4DB7963FE530C434C27459
      63481D1ACF3A56A46358EE6D43C6B045F30D24C656049FF00E9CA1B2058614C8
      D4C6A29CAF68CF4EB88F63647018555555BA79FCC90824312E68EDE6D3CD181D
      09211E89E1EDD2D21ABF511EA4B3E7DD180F3D417C3E86B96814F1780C8B8B0B
      AABFEE689D3983E940732D16671710791D463412C1423C8EA1400067DC6ED4D7
      D79BD7638271B8E308A2D31184C3B3F0FBFD686A3A0687C391DA5A600CDB291B
      FA7AAFC2E9741ABEEF46277936F4B1A7ECA00B959A94AEC827CBB2EAF57ABDEA
      7D3A2C8A25DFCACA8A2AEA9B999901CFC948667E6A730ECF2959142B32E8BEA5
      A545E7E571621F97995FF4F2B874FC8AA2CF3F1DBFDDEE49397F59361E9FC79B
      E5AF288A2AEA1773E07E2E8FC703FA7E3C8E8BBE07F5F35F713CB10639C76EB7
      A3A1A14127F19B26FB8D5846FDA9F8D79358EBBFB75E687D781392F1A7FDFF9B
      F8FEB4D19E94BCBF701FD52A97594DF1B8D5D555F87C3EB576451FDFD38C18D4
      A6DAE6719C416B4DF4FD6D0CA3FD3599417B01CD85C870B95C686F6F476363A3
      E97C96979783B348C4A078F2F5F4F4A8ED54FF63688D90375D5F2AFBC9BFA01F
      984C58AD
    }
  end
  object ImgList: TImageList
    Left = 468
    Top = 95
  end
end
