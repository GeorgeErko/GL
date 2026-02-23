object Las3DViewerForm: TLas3DViewerForm
  Left = 300
  Height = 789
  Top = 0
  Width = 1022
  Caption = 'LAS 3D'
  ClientHeight = 789
  ClientWidth = 1022
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  LCLVersion = '7.8'
  object TopPanel: TPanel
    Left = 0
    Height = 40
    Top = 0
    Width = 1022
    Align = alTop
    BevelOuter = bvNone
    ClientHeight = 40
    ClientWidth = 1022
    TabOrder = 0
    object BlendCheck: TCheckBox
      Left = 10
      Height = 19
      Top = 12
      Width = 48
      Caption = 'Blend'
      Checked = True
      OnChange = UIChanged
      State = cbChecked
      TabOrder = 0
    end
    object AlphaBar: TTrackBar
      Left = 298
      Height = 28
      Top = 6
      Width = 180
      Max = 255
      OnChange = UIChanged
      Position = 64
      TabOrder = 1
    end
    object PointSizeBox: TComboBox
      Left = 117
      Height = 23
      Top = 8
      Width = 60
      ItemHeight = 15
      ItemIndex = 0
      Items.Strings = (
        '1'
        '2'
        '3'
        '4'
      )
      OnChange = UIChanged
      Style = csDropDownList
      TabOrder = 2
      Text = '1'
    end
    object Mode2DCheck: TCheckBox
      Left = 190
      Height = 19
      Top = 10
      Width = 32
      Caption = '2D'
      OnChange = UIChanged
      TabOrder = 3
    end
    object YawBar: TTrackBar
      Left = 479
      Height = 28
      Top = 6
      Width = 180
      Max = 180
      Min = -180
      OnChange = UIChanged
      Position = 0
      TabOrder = 4
    end
    object PitchBar: TTrackBar
      Left = 640
      Height = 28
      Top = 6
      Width = 180
      Max = 89
      Min = -89
      OnChange = UIChanged
      Position = 0
      TabOrder = 5
    end
    object FovBar: TTrackBar
      Left = 810
      Height = 28
      Top = 6
      Width = 180
      Max = 120
      Min = 10
      OnChange = UIChanged
      Position = 45
      TabOrder = 6
    end
    object Label2: TLabel
      Left = 69
      Height = 15
      Top = 14
      Width = 42
      Caption = 'R точки'
    end
    object ResetBtn: TButton
      Left = 234
      Height = 23
      Top = 8
      Width = 60
      Caption = 'Сброс'
      OnClick = ResetBtnClick
      TabOrder = 7
    end
  end
  object OGL: TOpenGLPanel
    Cursor = crCross
    Left = 0
    Height = 713
    Top = 40
    Width = 1022
    Align = alClient
    OnKeyDown = FormKeyDown
    OnMouseDown = OGLMouseDown
    OnMouseMove = OGLMouseMove
    OnMouseUp = OGLMouseUp
    OnMouseWheel = OGLMouseWheel
    OnPaint = OGLPaint
  end
  object BottomPanel: TPanel
    Left = 0
    Height = 36
    Top = 753
    Width = 1022
    Align = alBottom
    BevelOuter = bvNone
    ClientHeight = 36
    ClientWidth = 1022
    TabOrder = 1
    object LevelSpin: TFloatSpinEdit
      Left = 8
      Height = 23
      Top = 7
      Width = 100
      Increment = 0.25
      OnChange = LevelChanged
      OnKeyDown = FormKeyDown
      TabOrder = 0
    end
    object ZMinLabel: TLabel
      Left = 120
      Height = 15
      Top = 10
      Width = 28
      Caption = 'ZMin'
      Color = clDefault
      ParentColor = False
    end
    object ZMaxLabel: TLabel
      Left = 240
      Height = 15
      Top = 10
      Width = 30
      Caption = 'ZMax'
      Color = clDefault
      ParentColor = False
    end
    object PlaneShowCheck: TCheckBox
      Left = 360
      Height = 19
      Top = 9
      Width = 83
      Caption = 'Показывать'
      Checked = True
      OnChange = PlaneChanged
      State = cbChecked
      TabOrder = 1
    end
    object PlaneAlphaLabel: TLabel
      Left = 465
      Height = 15
      Top = 10
      Width = 92
      Caption = 'Прозрачность %'
      Color = clDefault
      ParentColor = False
    end
    object PlaneAlphaSpin: TFloatSpinEdit
      Left = 565
      Height = 23
      Top = 7
      Width = 60
      DecimalPlaces = 0
      MaxValue = 100
      OnChange = PlaneChanged
      TabOrder = 2
      Value = 75
    end
    object PlaneZSpin: TFloatSpinEdit
      Left = 796
      Height = 23
      Top = 7
      Width = 60
      Increment = 0.05
      OnChange = PlaneChanged
      TabOrder = 3
      Value = 0.1
    end
    object PlaneSizeSpin: TFloatSpinEdit
      Left = 891
      Height = 23
      Top = 7
      Width = 50
      DecimalPlaces = 0
      MaxValue = 64
      MinValue = 1
      OnChange = PlaneSizeChanged
      TabOrder = 4
      Value = 5
    end
    object PlaneDistEdit: TFloatSpinEdit
      Left = 696
      Height = 23
      Top = 8
      Width = 60
      Increment = 0.05
      OnChange = PlaneChanged
      TabOrder = 5
    end
    object cbPlane: TCheckBox
      Left = 638
      Height = 19
      Top = 10
      Width = 54
      Caption = 'Захват'
      OnChange = cbPlaneChange
      TabOrder = 6
    end
    object Label1: TLabel
      Left = 765
      Height = 15
      Top = 12
      Width = 24
      Caption = 'по Z'
    end
    object Label3: TLabel
      Left = 872
      Height = 15
      Top = 12
      Width = 15
      Caption = 'R='
    end
    object LODBtn: TButton
      Left = 966
      Height = 23
      Top = 8
      Width = 60
      Caption = 'LOD'
      OnClick = LODBtnClick
      TabOrder = 7
    end
  end
end
