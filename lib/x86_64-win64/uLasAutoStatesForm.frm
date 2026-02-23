object LasAutoStatesForm: TLasAutoStatesForm
  Left = 300
  Height = 520
  Top = 200
  Width = 760
  Caption = 'Параметры LAS'
  ClientHeight = 520
  ClientWidth = 760
  Position = poScreenCenter
  LCLVersion = '7.8'
  object BottomPanel: TPanel
    Left = 0
    Height = 40
    Top = 480
    Width = 760
    Align = alBottom
    ClientHeight = 40
    ClientWidth = 760
    TabOrder = 0
    object BtnOK: TButton
      Left = 568
      Height = 25
      Top = 8
      Width = 90
      Anchors = [akTop, akRight]
      Caption = 'OK'
      OnClick = BtnOKClick
      TabOrder = 0
    end
    object BtnCancel: TButton
      Left = 664
      Height = 25
      Top = 8
      Width = 90
      Anchors = [akTop, akRight]
      Caption = 'Отмена'
      OnClick = BtnCancelClick
      TabOrder = 1
    end
  end
  object PageControl1: TPageControl
    Left = 0
    Height = 480
    Top = 0
    Width = 760
    ActivePage = TabData
    Align = alClient
    TabIndex = 0
    TabOrder = 1
    object TabData: TTabSheet
      Caption = 'Данные'
      ClientHeight = 452
      ClientWidth = 752
      object DataScroll: TScrollBox
        Left = 0
        Height = 452
        Top = 0
        Width = 752
        HorzScrollBar.Page = 209
        VertScrollBar.Page = 315
        Align = alClient
        BorderStyle = bsNone
        ClientHeight = 452
        ClientWidth = 752
        TabOrder = 0
        object cbIntensity: TCheckBox
          Left = 8
          Height = 19
          Top = 8
          Width = 102
          Caption = 'Интенсивность'
          Checked = True
          State = cbChecked
          TabOrder = 0
        end
        object cbReturnNumber: TCheckBox
          Left = 8
          Height = 19
          Top = 32
          Width = 107
          Caption = 'Номер возврата'
          Checked = True
          State = cbChecked
          TabOrder = 1
        end
        object cbNumberOfReturns: TCheckBox
          Left = 8
          Height = 19
          Top = 56
          Width = 111
          Caption = 'Число возвратов'
          Checked = True
          State = cbChecked
          TabOrder = 2
        end
        object cbScanDirectionFlag: TCheckBox
          Left = 8
          Height = 19
          Top = 80
          Width = 201
          Caption = 'Флаг направления сканирования'
          Checked = True
          State = cbChecked
          TabOrder = 3
        end
        object cbEdgeOfFlightLine: TCheckBox
          Left = 8
          Height = 19
          Top = 104
          Width = 159
          Caption = 'Флаг края линии пролёта'
          Checked = True
          State = cbChecked
          TabOrder = 4
        end
        object cbClassification: TCheckBox
          Left = 8
          Height = 19
          Top = 128
          Width = 105
          Caption = 'Классификация'
          Checked = True
          State = cbChecked
          TabOrder = 5
        end
        object cbSyntheticFlag: TCheckBox
          Left = 8
          Height = 19
          Top = 152
          Width = 128
          Caption = 'Флаг синтетическая'
          Checked = True
          State = cbChecked
          TabOrder = 6
        end
        object cbKeypointFlag: TCheckBox
          Left = 8
          Height = 19
          Top = 176
          Width = 102
          Caption = 'Флаг ключевая'
          Checked = True
          State = cbChecked
          TabOrder = 7
        end
        object cbWithheldFlag: TCheckBox
          Left = 8
          Height = 19
          Top = 200
          Width = 182
          Caption = 'Флаг исключённая (Withheld)'
          Checked = True
          State = cbChecked
          TabOrder = 8
        end
        object cbScanAngleRank: TCheckBox
          Left = 8
          Height = 19
          Top = 224
          Width = 151
          Caption = 'Ранг угла сканирования'
          Checked = True
          State = cbChecked
          TabOrder = 9
        end
        object cbUserData: TCheckBox
          Left = 8
          Height = 19
          Top = 248
          Width = 164
          Caption = 'Пользовательские данные'
          Checked = True
          State = cbChecked
          TabOrder = 10
        end
        object cbPointSourceID: TCheckBox
          Left = 8
          Height = 19
          Top = 272
          Width = 201
          Caption = 'Идентификатор источника точки'
          Checked = True
          State = cbChecked
          TabOrder = 11
        end
        object cbGpsTime: TCheckBox
          Left = 8
          Height = 19
          Top = 296
          Width = 78
          Caption = 'GPS-время'
          Checked = True
          State = cbChecked
          TabOrder = 12
        end
      end
    end
    object TabFilterZ: TTabSheet
      Caption = 'Z'
      ClientHeight = 452
      ClientWidth = 752
      object PanelZTop: TPanel
        Left = 0
        Height = 80
        Top = 0
        Width = 752
        Align = alTop
        ClientHeight = 80
        ClientWidth = 752
        TabOrder = 0
        object cbUseZFilter: TCheckBox
          Left = 8
          Height = 19
          Top = 8
          Width = 95
          Caption = 'Использовать'
          TabOrder = 0
        end
        object cbZMode: TComboBox
          Left = 160
          Height = 23
          Top = 6
          Width = 220
          ItemHeight = 15
          Items.Strings = (
            'Выделять цветом'
            'Фильтровать (исключать)'
          )
          Style = csDropDownList
          TabOrder = 1
        end
        object edZMin: TFloatSpinEdit
          Left = 8
          Height = 23
          Top = 40
          Width = 120
          DecimalPlaces = 3
          Increment = 0.1
          MaxValue = 1E30
          MinValue = -1E30
          TabOrder = 2
        end
        object edZMax: TFloatSpinEdit
          Left = 136
          Height = 23
          Top = 40
          Width = 120
          DecimalPlaces = 3
          Increment = 0.1
          MaxValue = 1E30
          MinValue = -1E30
          TabOrder = 3
        end
        object ShapeZColor: TShape
          Left = 392
          Height = 18
          Top = 10
          Width = 30
          Brush.Color = clRed
        end
        object BtnZColor: TButton
          Left = 432
          Height = 25
          Top = 6
          Width = 120
          Caption = 'Цвет...'
          OnClick = BtnZColorClick
          TabOrder = 4
        end
      end
      object MemoZInfo: TMemo
        Left = 0
        Height = 372
        Top = 80
        Width = 752
        Align = alClient
        Lines.Strings = (
          'Фильтр по высоте (Z).'
          ''
          'Если включён, точки вне заданного диапазона Z могут быть исключены из облака.'
          'Если выключён, фильтрации нет.'
        )
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 1
      end
    end
    object TabReturns: TTabSheet
      Caption = 'Возвраты'
      ClientHeight = 452
      ClientWidth = 752
      object PanelReturnsTop: TPanel
        Left = 0
        Height = 80
        Top = 0
        Width = 752
        Align = alTop
        ClientHeight = 80
        ClientWidth = 752
        TabOrder = 0
        object cbUseReturns: TCheckBox
          Left = 8
          Height = 19
          Top = 8
          Width = 95
          Caption = 'Использовать'
          TabOrder = 0
        end
      end
      object MemoReturnsInfo: TMemo
        Left = 0
        Height = 372
        Top = 80
        Width = 752
        Align = alClient
        Lines.Strings = (
          'Возвраты (Return Number / Number Of Returns).'
          ''
          'Параметр используется для фильтрации или визуализации по номеру возврата (первый/последний/одиночный и т.п.).'
          'При выключенном режиме точки не исключаются и не выделяются по возвратам.'
        )
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 1
      end
    end
    object TabClasses: TTabSheet
      Caption = 'Классы'
      ClientHeight = 452
      ClientWidth = 752
      object PanelClassesTop: TPanel
        Left = 0
        Height = 80
        Top = 0
        Width = 752
        Align = alTop
        ClientHeight = 80
        ClientWidth = 752
        TabOrder = 0
        object cbUseClasses: TCheckBox
          Left = 8
          Height = 19
          Top = 8
          Width = 95
          Caption = 'Использовать'
          TabOrder = 0
        end
      end
      object MemoClassesInfo: TMemo
        Left = 0
        Height = 372
        Top = 80
        Width = 752
        Align = alClient
        Lines.Strings = (
          'Классификация (Classification).'
          ''
          'Параметр позволяет выделять или отбирать точки по классу (земля, растительность, здания и т.п.).'
          'Список классов и их значения зависят от исходных данных.'
        )
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 1
      end
    end
    object TabAngle: TTabSheet
      Caption = 'Угол'
      ClientHeight = 452
      ClientWidth = 752
      object PanelAngleTop: TPanel
        Left = 0
        Height = 80
        Top = 0
        Width = 752
        Align = alTop
        ClientHeight = 80
        ClientWidth = 752
        TabOrder = 0
        object cbUseAngle: TCheckBox
          Left = 8
          Height = 19
          Top = 8
          Width = 95
          Caption = 'Использовать'
          TabOrder = 0
        end
        object cbAngleMode: TComboBox
          Left = 160
          Height = 23
          Top = 6
          Width = 220
          ItemHeight = 15
          Items.Strings = (
            'Выделять цветом'
            'Фильтровать (исключать)'
          )
          Style = csDropDownList
          TabOrder = 1
        end
        object edAngleMin: TFloatSpinEdit
          Left = 8
          Height = 23
          Top = 40
          Width = 120
          DecimalPlaces = 3
          MaxValue = 1E30
          MinValue = -1E30
          TabOrder = 2
        end
        object edAngleMax: TFloatSpinEdit
          Left = 136
          Height = 23
          Top = 40
          Width = 120
          DecimalPlaces = 3
          MaxValue = 1E30
          MinValue = -1E30
          TabOrder = 3
        end
        object ShapeAngleColor: TShape
          Left = 392
          Height = 18
          Top = 10
          Width = 30
          Brush.Color = clLime
        end
        object BtnAngleColor: TButton
          Left = 432
          Height = 25
          Top = 6
          Width = 120
          Caption = 'Цвет...'
          OnClick = BtnAngleColorClick
          TabOrder = 4
        end
      end
      object MemoAngleInfo: TMemo
        Left = 0
        Height = 372
        Top = 80
        Width = 752
        Align = alClient
        Lines.Strings = (
          'Угол сканирования (Scan Angle Rank).'
          ''
          'Параметр может использоваться как диапазон для фильтрации (уменьшение облака) или для раскраски (визуализация).'
          'При выключенном режиме точки не исключаются и не выделяются по углу.'
        )
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 1
      end
    end
    object TabGpsTime: TTabSheet
      Caption = 'GPS'
      ClientHeight = 452
      ClientWidth = 752
      object PanelGpsTop: TPanel
        Left = 0
        Height = 80
        Top = 0
        Width = 752
        Align = alTop
        ClientHeight = 80
        ClientWidth = 752
        TabOrder = 0
        object cbUseGpsTime: TCheckBox
          Left = 8
          Height = 19
          Top = 8
          Width = 95
          Caption = 'Использовать'
          TabOrder = 0
        end
        object cbGpsMode: TComboBox
          Left = 160
          Height = 23
          Top = 6
          Width = 220
          ItemHeight = 15
          Items.Strings = (
            'Выделять цветом'
            'Фильтровать (исключать)'
          )
          Style = csDropDownList
          TabOrder = 1
        end
        object edGpsMin: TFloatSpinEdit
          Left = 8
          Height = 23
          Top = 40
          Width = 180
          DecimalPlaces = 3
          MaxValue = 1E30
          MinValue = -1E30
          TabOrder = 2
        end
        object edGpsMax: TFloatSpinEdit
          Left = 196
          Height = 23
          Top = 40
          Width = 180
          DecimalPlaces = 3
          MaxValue = 1E30
          MinValue = -1E30
          TabOrder = 3
        end
        object ShapeGpsColor: TShape
          Left = 392
          Height = 18
          Top = 10
          Width = 30
          Brush.Color = clAqua
        end
        object BtnGpsColor: TButton
          Left = 432
          Height = 25
          Top = 6
          Width = 120
          Caption = 'Цвет...'
          OnClick = BtnGpsColorClick
          TabOrder = 4
        end
      end
      object MemoGpsInfo: TMemo
        Left = 0
        Height = 372
        Top = 80
        Width = 752
        Align = alClient
        Lines.Strings = (
          'GPS-время (GPS Time).'
          ''
          'Параметр может использоваться для отбора диапазона времени (уменьшение облака) или для раскраски по времени (визуализация).'
          'При выключенном режиме точки не исключаются и не выделяются по времени.'
        )
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 1
      end
    end
    object TabFlags: TTabSheet
      Caption = 'Флаги'
      ClientHeight = 452
      ClientWidth = 752
      object PanelFlagsTop: TPanel
        Left = 0
        Height = 80
        Top = 0
        Width = 752
        Align = alTop
        ClientHeight = 80
        ClientWidth = 752
        TabOrder = 0
        object cbUseFlags: TCheckBox
          Left = 8
          Height = 19
          Top = 8
          Width = 95
          Caption = 'Использовать'
          TabOrder = 0
        end
      end
      object MemoFlagsInfo: TMemo
        Left = 0
        Height = 372
        Top = 80
        Width = 752
        Align = alClient
        Lines.Strings = (
          'Флаги качества (Withheld / Synthetic / Keypoint / Edge of Flight Line и др.).'
          ''
          'Параметр может использоваться для фильтрации или визуального выделения по флагам.'
          'Например: withheld можно сделать полупрозрачными, а edge-of-flight-line подсветить.'
        )
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 1
      end
    end
    object TabColoring: TTabSheet
      Caption = 'Раскраска'
      ClientHeight = 452
      ClientWidth = 752
      object PanelColorTop: TPanel
        Left = 0
        Height = 80
        Top = 0
        Width = 752
        Align = alTop
        ClientHeight = 80
        ClientWidth = 752
        TabOrder = 0
        object cbUseColoring: TCheckBox
          Left = 8
          Height = 19
          Top = 8
          Width = 95
          Caption = 'Использовать'
          TabOrder = 0
        end
      end
      object MemoColorInfo: TMemo
        Left = 0
        Height = 372
        Top = 80
        Width = 752
        Align = alClient
        Lines.Strings = (
          'Раскраска (визуализация).'
          ''
          'Если включено, точки остаются в облаке, меняется только отображение (цвет/прозрачность).'
          'Если выключено, используется базовая раскраска.'
        )
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 1
      end
    end
  end
  object ColorDialog1: TColorDialog
    Color = clBlack
    CustomColors.Strings = (
      'ColorA=000000'
      'ColorB=000080'
      'ColorC=008000'
      'ColorD=008080'
      'ColorE=800000'
      'ColorF=800080'
      'ColorG=808000'
      'ColorH=808080'
      'ColorI=C0C0C0'
      'ColorJ=0000FF'
      'ColorK=00FF00'
      'ColorL=00FFFF'
      'ColorM=FF0000'
      'ColorN=FF00FF'
      'ColorO=FFFF00'
      'ColorP=FFFFFF'
      'ColorQ=C0DCC0'
      'ColorR=F0CAA6'
      'ColorS=F0FBFF'
      'ColorT=A4A0A0'
    )
    Left = 628
    Top = 33
  end
end
