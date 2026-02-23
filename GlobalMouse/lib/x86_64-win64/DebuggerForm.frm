object Debugger: TDebugger
  Left = 286
  Height = 388
  Top = 257
  Width = 571
  Caption = 'Debug'
  ClientHeight = 388
  ClientWidth = 571
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  LCLVersion = '7.8'
  object Panel1: TPanel
    Left = 2
    Height = 384
    Top = 2
    Width = 567
    Align = alClient
    BorderSpacing.Around = 2
    BevelOuter = bvNone
    Caption = 'Panel1'
    ClientHeight = 384
    ClientWidth = 567
    Color = clBtnFace
    ParentColor = False
    TabOrder = 0
    object PageControl: TPageControl
      Left = 0
      Height = 330
      Top = 0
      Width = 528
      Align = alClient
      Font.CharSet = ANSI_CHARSET
      Font.Name = 'Lucida Console'
      Font.Pitch = fpFixed
      Font.Quality = fqDraft
      ParentFont = False
      Style = tsFlatButtons
      TabOrder = 0
      OnChange = PageControlChange
    end
    object Splitter1: TSplitter
      Cursor = crVSplit
      Left = 0
      Height = 4
      Top = 330
      Width = 567
      Align = alBottom
      DoubleBuffered = True
      ParentColor = False
      ParentDoubleBuffered = False
      ResizeAnchor = akBottom
    end
    object Panel3: TPanel
      Left = 0
      Height = 50
      Top = 334
      Width = 567
      Align = alBottom
      BevelOuter = bvNone
      Caption = 'Panel3'
      ClientHeight = 50
      ClientWidth = 567
      TabOrder = 2
      object Panel4: TPanel
        Left = 528
        Height = 50
        Top = 0
        Width = 39
        Align = alRight
        BevelOuter = bvNone
        ClientHeight = 50
        ClientWidth = 39
        TabOrder = 0
        object Button3: TButton
          Left = 0
          Height = 25
          Top = 8
          Width = 30
          Caption = 'add'
          OnClick = Button3Click
          TabOrder = 0
        end
      end
      object Memo1: TMemo
        Left = 1
        Height = 48
        Top = 1
        Width = 526
        Align = alClient
        BorderSpacing.Around = 1
        BorderStyle = bsNone
        Font.CharSet = ANSI_CHARSET
        Font.Name = 'Lucida Console'
        Font.Pitch = fpFixed
        Font.Quality = fqDraft
        ParentFont = False
        TabOrder = 1
      end
    end
    object Panel2: TPanel
      Left = 528
      Height = 330
      Top = 0
      Width = 39
      Align = alRight
      BevelOuter = bvNone
      ClientHeight = 330
      ClientWidth = 39
      TabOrder = 3
      OnClick = Panel2Click
      object Button1: TButton
        Left = 0
        Height = 25
        Top = 8
        Width = 30
        Caption = 'add'
        OnClick = Button1Click
        TabOrder = 0
      end
      object thr: TButton
        Left = 0
        Height = 25
        Top = 272
        Width = 30
        Caption = 'thr'
        OnClick = thrClick
        TabOrder = 1
      end
      object thr1: TButton
        Left = 0
        Height = 25
        Top = 224
        Width = 30
        Caption = 'strt'
        OnClick = thr1Click
        TabOrder = 2
      end
      object clr: TButton
        Left = 5
        Height = 25
        Top = 140
        Width = 30
        Caption = 'clr'
        OnClick = clrClick
        TabOrder = 3
      end
    end
  end
  object Button2: TButton
    Left = 528
    Height = 25
    Top = 40
    Width = 30
    Caption = 'del'
    OnClick = Button2Click
    TabOrder = 1
  end
  object Timer1: TTimer
    Enabled = False
    OnTimer = Timer1Timer
    Left = 464
    Top = 24
  end
end
