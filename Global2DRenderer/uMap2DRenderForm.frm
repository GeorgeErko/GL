object Map2DRenderForm: TMap2DRenderForm
  Left = 300
  Height = 600
  Top = 200
  Width = 800
  Caption = '2D Map OGL'
  ClientHeight = 580
  ClientWidth = 800
  Menu = MainMenu1
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  LCLVersion = '7.8'
  object OpenGLPanel1: TOpenGLPanel
    Left = 280
    Height = 514
    Top = 36
    Width = 520
    Align = alClient
    OnMouseDown = OpenGLPanel1MouseDown
    OnMouseMove = OpenGLPanel1MouseMove
    OnMouseUp = OpenGLPanel1MouseUp
    OnMouseWheel = OpenGLPanel1MouseWheel
    OnPaint = OpenGLPanel1Paint
  end
  object propEditor: TValueListEditor
    Left = 0
    Height = 514
    Top = 36
    Width = 280
    Align = alLeft
    Color = clBtnFace
    FixedCols = 0
    RowCount = 10
    TabOrder = 1
    Visible = False
    Strings.Strings = (
      ''
      ''
      ''
      ''
      ''
      ''
      ''
      ''
      ''
    )
    ColWidths = (
      64
      212
    )
  end
  object pnlTop: TPanel
    Left = 0
    Height = 36
    Top = 0
    Width = 800
    Align = alTop
    ClientHeight = 36
    ClientWidth = 800
    TabOrder = 2
    object sbOpen: TSpeedButton
      Left = 6
      Height = 22
      Top = 7
      Width = 23
      Glyph.Data = {
        F6000000424DF600000000000000760000002800000010000000100000000100
        0400000000008000000000000000000000001000000010000000000000000000
        8000008000000080800080000000800080008080000080808000C0C0C0000000
        FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00888888888888
        88888888888888888888000000000008888800333333333088880B0333333333
        08880FB03333333330880BFB0333333333080FBFB000000000000BFBFBFBFB08
        88880FBFBFBFBF0888880BFB0000000888888000888888880008888888888888
        8008888888880888080888888888800088888888888888888888
      }
      OnClick = MenuFileOpenClick
    end
    object cbTiles: TCheckBox
      Left = 100
      Height = 19
      Top = 7
      Width = 53
      Caption = 'Тайлы'
      OnChange = CBTilesClick
      TabOrder = 0
    end
    object PBScene: TProgressBar
      Left = 541
      Height = 20
      Top = 6
      Width = 251
      TabOrder = 1
      Visible = False
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Height = 30
    Top = 550
    Width = 800
    Align = alBottom
    Alignment = taLeftJustify
    TabOrder = 3
  end
  object MainMenu1: TMainMenu
    Left = 56
    Top = 40
    object MenuFile: TMenuItem
      Caption = 'Файл'
      object MenuFileOpen: TMenuItem
        Caption = 'Открыть LAS...'
        OnClick = MenuFileOpenClick
      end
      object MenuItem2: TMenuItem
        Caption = 'Открыть GMF...'
      end
    end
  end
  object ODGmf: TOpenDialog
    Filter = '*.gmf'
    Left = 56
    Top = 88
  end
  object ImgList: TImageList
    Left = 162
    Top = 84
    Bitmap = {
      4C7A0100000010000000100000009F0100000000000078DAAD924B48024118C7
      BD79E91C5E0BBA045DA320C2307A807488883A7428D053197409BB04B982445D
      2A90B4831E820E254494641244EFA028884AD19E86900485BDF6E1FE9BD9D5CD
      552390187EFCE71BE6F7EDCEEC4283BC5162D7211B688A1BFFD9A76CB5A6E81E
      D4ABF41B501568FDB587767213D914EAA13F3515F4E97E5114312F42413BB106
      833FA240BDB6A815D5810E558F8CEBE1411025BC1C8164EEFD75DE31683EB6A8
      D6A8EF7E17E1FA9071BFA7E056E6728FA6937E74C71CE8BA73A0373103FDD6CF
      39A83FFD2212522875EE22F71E28746F7B68147DCF4E34EC9894E766187F1230
      1C49A27C6E0F2900079F220EB3A03575EA823D525EB33C2E3E58C51F7B10A43B
      326DDF6291BCC7644248934A23CFA96BDC0863ED93C5C0D1ADE25BA33C74B3FB
      70DD243115E7C1C478D8628204934E1B59631E05B4AC87B1F2C62ADF98E6D005
      27D53E720E6B84CF63444A4EA2713504DFABDA3706E3A85D3883E79EC7E03947
      606149A75CCB58485DBF1C02739950F915DE330CEDC761BFE4603E666152F1A5
      A4F98445EDD255DEFF59E89BFD45C6FD06122E8BD7
    }
  end
end
