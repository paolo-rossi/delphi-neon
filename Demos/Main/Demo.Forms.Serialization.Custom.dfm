inherited frmSerializationCustom: TfrmSerializationCustom
  Caption = 'frmSerializationCustom'
  PixelsPerInch = 96
  TextHeight = 13
  object btnSerMyClass: TButton [0]
    Left = 3
    Top = 32
    Width = 131
    Height = 25
    Caption = 'TMyClass'
    TabOrder = 0
    OnClick = btnSerMyClassClick
  end
  object btnDesMyClass: TButton [1]
    Left = 485
    Top = 33
    Width = 131
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'TMyClass'
    TabOrder = 1
    OnClick = btnDesMyClassClick
  end
  object btnSerParameter: TButton [2]
    Left = 3
    Top = 63
    Width = 131
    Height = 25
    Caption = 'TParameter'
    TabOrder = 2
    OnClick = btnSerParameterClick
  end
  object btnSerFont: TButton [3]
    Left = 3
    Top = 94
    Width = 131
    Height = 25
    Caption = 'TFont'
    TabOrder = 3
    OnClick = btnSerFontClick
  end
  object btnSerCaseClass: TButton [4]
    Left = 3
    Top = 125
    Width = 131
    Height = 25
    Caption = 'TCaseClass'
    TabOrder = 4
    OnClick = btnSerCaseClassClick
  end
  object btnDesCaseClass: TButton [5]
    Left = 485
    Top = 126
    Width = 131
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'TCaseClass'
    TabOrder = 5
    OnClick = btnDesCaseClassClick
  end
  object btnDesParameter: TButton [6]
    Left = 485
    Top = 64
    Width = 131
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'TParameter'
    TabOrder = 6
    OnClick = btnDesParameterClick
  end
  object btnDesFont: TButton [7]
    Left = 485
    Top = 95
    Width = 131
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'TFont'
    TabOrder = 7
    OnClick = btnDesFontClick
  end
  inherited pnlSerialize: TPanel
    TabOrder = 11
  end
  inherited memoSerialize: TMemo
    TabOrder = 9
  end
  inherited pnlDeserialize: TPanel
    TabOrder = 12
  end
  inherited memoDeserialize: TMemo
    TabOrder = 10
  end
  inherited memoLog: TMemo
    TabOrder = 8
  end
  object btnSerNullables: TButton
    Left = 3
    Top = 188
    Width = 131
    Height = 25
    Caption = 'Nullables'
    TabOrder = 13
    OnClick = btnSerNullablesClick
  end
  object btnDesNullables: TButton
    Left = 485
    Top = 188
    Width = 131
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Nullables'
    TabOrder = 14
    OnClick = btnDesNullablesClick
  end
end
