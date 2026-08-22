object frmJSON: TfrmJSON
  Left = 0
  Top = 0
  Caption = 'Check JSON Correctness'
  ClientHeight = 460
  ClientWidth = 918
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 15
  object lblEngineA: TLabel
    Left = 8
    Top = 63
    Width = 98
    Height = 15
    Caption = 'JSON produced by'
  end
  object lblEngineB: TLabel
    Left = 463
    Top = 63
    Width = 98
    Height = 15
    Caption = 'JSON produced by'
  end
  object lblStatus: TLabel
    Left = 8
    Top = 439
    Width = 45
    Height = 15
    Caption = 'lblStatus'
  end
  object memoA: TMemo
    Left = 8
    Top = 88
    Width = 449
    Height = 345
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 0
    WordWrap = False
  end
  object memoB: TMemo
    Left = 463
    Top = 88
    Width = 449
    Height = 345
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 1
    WordWrap = False
  end
  object cbbEngineA: TComboBox
    Left = 152
    Top = 59
    Width = 145
    Height = 23
    Style = csDropDownList
    ItemIndex = 0
    TabOrder = 2
    Text = 'TNeon'
    OnChange = SelectionChanged
    Items.Strings = (
      'TNeon'
      'TJson'
      'TJSONSerializer')
  end
  object cbbEngineB: TComboBox
    Left = 612
    Top = 59
    Width = 145
    Height = 23
    Style = csDropDownList
    ItemIndex = 2
    TabOrder = 3
    Text = 'TJSONSerializer'
    OnChange = SelectionChanged
    Items.Strings = (
      'TNeon'
      'TJson'
      'TJSONSerializer')
  end
  object grpClassType: TGroupBox
    Left = 353
    Top = 8
    Width = 224
    Height = 47
    TabOrder = 4
    object rbClassSimple: TRadioButton
      Left = 8
      Top = 15
      Width = 113
      Height = 16
      Caption = 'Simple Class'
      Checked = True
      TabOrder = 0
      TabStop = True
      OnClick = SelectionChanged
    end
    object rbClassComplex: TRadioButton
      Left = 107
      Top = 15
      Width = 113
      Height = 17
      Caption = 'Complex Class'
      TabOrder = 1
      OnClick = SelectionChanged
    end
  end
end
