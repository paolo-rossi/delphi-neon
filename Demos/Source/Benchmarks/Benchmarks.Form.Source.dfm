object frmSource: TfrmSource
  Left = 0
  Top = 0
  Caption = 'Benchmark Info'
  ClientHeight = 635
  ClientWidth = 634
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 15
  object pgcSource: TPageControl
    Left = 0
    Top = 145
    Width = 634
    Height = 490
    ActivePage = tsSourceSimple
    Align = alClient
    Style = tsFlatButtons
    TabOrder = 0
    ExplicitWidth = 630
    ExplicitHeight = 489
    object tsSourceSimple: TTabSheet
      Caption = 'Simple Entity (TUser)'
      object lblSimple: TLabel
        Left = 24
        Top = 24
        Width = 239
        Height = 17
        Caption = 'TUser si a simple class with 3 properties '
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object richSourceSimple: TRichEdit
        Left = 0
        Top = 0
        Width = 626
        Height = 457
        Align = alClient
        Color = clBtnText
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        ScrollBars = ssVertical
        TabOrder = 0
        WordWrap = False
        ExplicitWidth = 622
        ExplicitHeight = 456
      end
    end
    object tsSourceComplex: TTabSheet
      Caption = 'Complex Entity (TCustomer)'
      ImageIndex = 1
      object richSourceComplex: TRichEdit
        Left = 0
        Top = 0
        Width = 626
        Height = 457
        Align = alClient
        Color = clBtnText
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        ScrollBars = ssVertical
        TabOrder = 0
        WordWrap = False
      end
    end
  end
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 634
    Height = 145
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    ExplicitWidth = 630
    object shpHeader: TShape
      AlignWithMargins = True
      Left = 10
      Top = 10
      Width = 614
      Height = 125
      Margins.Left = 10
      Margins.Top = 10
      Margins.Right = 10
      Margins.Bottom = 10
      Align = alClient
      Brush.Color = clMenuHighlight
      Shape = stRoundRect
      ExplicitHeight = 143
    end
    object lblHeader: TLabel
      Left = 28
      Top = 19
      Width = 587
      Height = 46
      Alignment = taCenter
      AutoSize = False
      Caption = 
        'Measured times don'#39't take into account the parsing time because ' +
        '(for the parsing of a '#13#10'string into a JSON structure) I am using' +
        ' the standard TJSON.ParseJSONValue in both cases.'
      Color = clBtnFace
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clHighlightText
      Font.Height = -15
      Font.Name = 'Segoe UI'
      Font.Style = [fsItalic]
      ParentColor = False
      ParentFont = False
      Transparent = True
      StyleElements = [seClient, seBorder]
    end
    object lblHeader2: TLabel
      Left = 28
      Top = 71
      Width = 587
      Height = 62
      Alignment = taCenter
      AutoSize = False
      Caption = 
        'Given the limitations of the TJSON engine I had to envelope the ' +
        'final array in a class: '#13#10'TEnvelopeUsers and TEnvelopeCustomers.' +
        ' In Neon you could use a simple TArray<> '#13#10'or a TList<> or a TOb' +
        'jectList<>'
      Color = clBtnFace
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clHighlightText
      Font.Height = -15
      Font.Name = 'Segoe UI'
      Font.Style = [fsItalic]
      ParentColor = False
      ParentFont = False
      Transparent = True
      StyleElements = [seClient, seBorder]
    end
  end
end
