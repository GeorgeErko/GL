object frmVFLineTypes: TfrmVFLineTypes
  Left = 200
  Height = 420
  Top = 200
  Width = 760
  Caption = 'Типы линий'
  ClientHeight = 420
  ClientWidth = 760
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  Position = poScreenCenter
  LCLVersion = '7.8'
  object ilButtons: TImageList
    Height = 16
    Width = 16
    Left = 24
    Top = 56
  end
  object pnlLeft: TPanel
    Left = 0
    Height = 420
    Top = 0
    Width = 260
    Align = alLeft
    BevelOuter = bvNone
    ClientHeight = 420
    ClientWidth = 260
    TabOrder = 0
    object tvLineTypes: TTreeView
      Left = 0
      Height = 384
      Top = 0
      Width = 260
      Align = alClient
      PopupMenu = pmTree
      TabOrder = 0
      OnCustomDrawItem = tvLineTypesCustomDrawItem
      OnEditing = tvLineTypesEditing
      OnEdited = tvLineTypesEdited
      OnSelectionChanged = tvLineTypesSelectionChanged
      Options = [tvoAutoItemHeight, tvoHideSelection, tvoKeepCollapsedNodes, tvoShowButtons, tvoShowLines, tvoShowRoot, tvoToolTips, tvoThemedDraw]
    end
    object pnlLeftBottom: TPanel
      Left = 0
      Height = 36
      Top = 384
      Width = 260
      Align = alBottom
      BevelOuter = bvNone
      ClientHeight = 36
      ClientWidth = 260
      TabOrder = 1
      object btnAddLineType: TBitBtn
        Left = 8
        Height = 25
        Top = 6
        Width = 110
        Caption = 'Добавить'
        OnClick = btnAddLineTypeClick
        TabOrder = 0
      end
      object btnDeleteLineType: TBitBtn
        Left = 128
        Height = 25
        Top = 6
        Width = 110
        Caption = 'Удалить'
        OnClick = btnDeleteLineTypeClick
        TabOrder = 1
      end
    end
  end
  object splMain: TSplitter
    Left = 260
    Height = 420
    Top = 0
    Width = 6
    Align = alLeft
  end
  object pnlRight: TPanel
    Left = 266
    Height = 420
    Top = 0
    Width = 494
    Align = alClient
    BevelOuter = bvNone
    ClientHeight = 420
    ClientWidth = 494
    TabOrder = 1
    object pbPreview: TPaintBox
      Left = 0
      Height = 220
      Top = 0
      Width = 494
      Align = alTop
      OnPaint = pbPreviewPaint
    end
    object pnlParams: TPanel
      Left = 0
      Height = 200
      Top = 220
      Width = 494
      Align = alClient
      BevelOuter = bvNone
      ClientHeight = 200
      ClientWidth = 494
      TabOrder = 0
      object pcLayerParams: TPageControl
        Left = 0
        Height = 164
        Top = 0
        Width = 494
        ActivePage = tsCommon
        Align = alClient
        TabIndex = 0
        TabOrder = 0
        object tsCommon: TTabSheet
          Caption = 'Общие'
          ClientHeight = 136
          ClientWidth = 486
          object lblLayerName: TLabel
            Left = 8
            Height = 15
            Top = 8
            Width = 53
            Caption = 'Имя слоя'
          end
          object edtLayerName: TEdit
            Left = 120
            Height = 23
            Top = 4
            Width = 200
            Anchors = [akTop, akLeft, akRight]
            TabOrder = 0
          end
          object cbEnabled: TCheckBox
            Left = 340
            Height = 19
            Top = 6
            Width = 60
            Anchors = [akTop, akRight]
            Caption = 'Enabled'
            TabOrder = 1
          end
          object lblColor: TLabel
            Left = 8
            Height = 15
            Top = 36
            Width = 29
            Caption = 'Color'
          end
          object edtColor: TEdit
            Left = 120
            Height = 23
            Top = 32
            Width = 120
            Anchors = [akTop, akLeft]
            TabOrder = 2
          end
          object lblBaseThickness: TLabel
            Left = 8
            Height = 15
            Top = 64
            Width = 51
            Caption = 'Толщина'
          end
          object edtBaseThickness: TEdit
            Left = 120
            Height = 23
            Top = 60
            Width = 120
            Anchors = [akTop, akLeft]
            TabOrder = 3
          end
          object lblOffset: TLabel
            Left = 8
            Height = 15
            Top = 92
            Width = 32
            Caption = 'Offset'
          end
          object edtOffset: TEdit
            Left = 120
            Height = 23
            Top = 88
            Width = 120
            Anchors = [akTop, akLeft]
            TabOrder = 4
          end
          object lblTrimStart: TLabel
            Left = 260
            Height = 15
            Top = 64
            Width = 47
            Anchors = [akTop, akRight]
            Caption = 'TrimStart'
          end
          object edtTrimStart: TEdit
            Left = 340
            Height = 23
            Top = 60
            Width = 120
            Anchors = [akTop, akRight]
            TabOrder = 5
          end
          object lblTrimEnd: TLabel
            Left = 260
            Height = 15
            Top = 92
            Width = 43
            Anchors = [akTop, akRight]
            Caption = 'TrimEnd'
          end
          object edtTrimEnd: TEdit
            Left = 340
            Height = 23
            Top = 88
            Width = 120
            Anchors = [akTop, akRight]
            TabOrder = 6
          end
        end
        object tsSolid: TTabSheet
          Caption = 'Solid'
          ClientHeight = 136
          ClientWidth = 486
          object lblCapKind: TLabel
            Left = 8
            Height = 15
            Top = 8
            Width = 55
            Caption = 'CapKind'
          end
          object cbCapKind: TComboBox
            Left = 120
            Height = 23
            Top = 4
            Width = 140
            ItemHeight = 15
            Anchors = [akTop, akLeft, akRight]
            Style = csDropDownList
            TabOrder = 0
          end
          object lblJoinKind: TLabel
            Left = 8
            Height = 15
            Top = 36
            Width = 55
            Caption = 'JoinKind'
          end
          object cbJoinKind: TComboBox
            Left = 120
            Height = 23
            Top = 32
            Width = 140
            ItemHeight = 15
            Anchors = [akTop, akLeft, akRight]
            Style = csDropDownList
            TabOrder = 1
          end
        end
        object tsPattern: TTabSheet
          Caption = 'Pattern'
          ClientHeight = 136
          ClientWidth = 486
          object lblDash: TLabel
            Left = 8
            Height = 15
            Top = 8
            Width = 35
            Caption = 'Dash'
          end
          object edtDash: TEdit
            Left = 120
            Height = 23
            Top = 4
            Width = 120
            Anchors = [akTop, akLeft, akRight]
            TabOrder = 0
          end
          object lblGap: TLabel
            Left = 8
            Height = 15
            Top = 36
            Width = 25
            Caption = 'Gap'
          end
          object edtGap: TEdit
            Left = 120
            Height = 23
            Top = 32
            Width = 120
            Anchors = [akTop, akLeft, akRight]
            TabOrder = 1
          end
          object lblDashOffset: TLabel
            Left = 8
            Height = 15
            Top = 64
            Width = 60
            Caption = 'DashOffset'
          end
          object edtDashOffset: TEdit
            Left = 120
            Height = 23
            Top = 60
            Width = 120
            Anchors = [akTop, akLeft, akRight]
            TabOrder = 2
          end
        end
        object tsCustom: TTabSheet
          Caption = 'Custom'
          ClientHeight = 136
          ClientWidth = 486
          object lblUserParams: TLabel
            Left = 8
            Height = 15
            Top = 8
            Width = 70
            Caption = 'UserParams'
          end
          object edtUserParams: TEdit
            Left = 120
            Height = 23
            Top = 4
            Width = 340
            Anchors = [akTop, akLeft, akRight]
            TabOrder = 0
          end
        end
      end
      object pnlParamsBottom: TPanel
        Left = 0
        Height = 36
        Top = 164
        Width = 494
        Align = alBottom
        BevelOuter = bvNone
        ClientHeight = 36
        ClientWidth = 494
        TabOrder = 1
        object btnApplyLayerParams: TBitBtn
          Left = 8
          Height = 25
          Top = 6
          Width = 100
          Caption = 'Принять'
          OnClick = btnApplyLayerParamsClick
          TabOrder = 0
        end
      end
    end
  end
  object pmTree: TPopupMenu
    Left = 16
    Top = 16
    object miAddSolidLayer: TMenuItem
      Caption = 'Добавить сплошной слой'
      OnClick = miAddSolidLayerClick
    end
    object miAddPatternLayer: TMenuItem
      Caption = 'Добавить пунктирный слой'
      OnClick = miAddPatternLayerClick
    end
    object miAddCustomLayer: TMenuItem
      Caption = 'Добавить пользовательский слой'
      OnClick = miAddCustomLayerClick
    end
  end
end
