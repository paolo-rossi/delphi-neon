inherited frmSerializationSimple: TfrmSerializationSimple
  Caption = 'frmSerializationSimple'
  PixelsPerInch = 96
  TextHeight = 13
  inherited pnlSerialize: TPanel
    TabOrder = 16
  end
  object btnSerSimpleInteger: TButton [1]
    Left = 3
    Top = 32
    Width = 131
    Height = 25
    Caption = 'Intgeger'
    TabOrder = 0
    OnClick = btnSerSimpleIntegerClick
  end
  object btnSerSimpleString: TButton [2]
    Left = 3
    Top = 63
    Width = 131
    Height = 25
    Caption = 'String'
    TabOrder = 1
    OnClick = btnSerSimpleStringClick
  end
  object btnSerSimpleDatTime: TButton [3]
    Left = 3
    Top = 156
    Width = 131
    Height = 25
    Caption = 'DateTime'
    TabOrder = 2
    OnClick = btnSerSimpleDatTimeClick
  end
  object btnSerSimpleRecord: TButton [4]
    Left = 3
    Top = 187
    Width = 131
    Height = 25
    Caption = 'TMyRecord'
    TabOrder = 4
    OnClick = btnSerSimpleRecordClick
  end
  object btnSerSimpleArray: TButton [5]
    Left = 3
    Top = 218
    Width = 131
    Height = 25
    Caption = 'Int Array'
    TabOrder = 5
    OnClick = btnSerSimpleArrayClick
  end
  object btnSerSimpleFloat: TButton [6]
    Left = 3
    Top = 94
    Width = 131
    Height = 25
    Caption = 'Float'
    TabOrder = 6
    OnClick = btnSerSimpleFloatClick
  end
  object btnSerSimpleBool: TButton [7]
    Left = 3
    Top = 125
    Width = 131
    Height = 25
    Caption = 'Boolean'
    TabOrder = 7
    OnClick = btnSerSimpleBoolClick
  end
  object btnDesSimpleInteger: TButton [8]
    Left = 485
    Top = 33
    Width = 131
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Intgeger'
    TabOrder = 8
    OnClick = btnDesSimpleIntegerClick
  end
  object btnDesSimpleString: TButton [9]
    Left = 485
    Top = 64
    Width = 131
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'String'
    TabOrder = 9
    OnClick = btnDesSimpleStringClick
  end
  object btnDesSimpleDateTime: TButton [10]
    Left = 485
    Top = 157
    Width = 131
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'DateTime'
    TabOrder = 10
    OnClick = btnDesSimpleDateTimeClick
  end
  object btnDesSimpleRecord: TButton [11]
    Left = 485
    Top = 188
    Width = 131
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'TMyRecord'
    TabOrder = 11
    OnClick = btnDesSimpleRecordClick
  end
  object btnDesSimpleArray: TButton [12]
    Left = 485
    Top = 219
    Width = 131
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Int Array'
    TabOrder = 12
    OnClick = btnDesSimpleArrayClick
  end
  object btnDesSimpleFloat: TButton [13]
    Left = 485
    Top = 95
    Width = 131
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Float'
    TabOrder = 13
    OnClick = btnDesSimpleFloatClick
  end
  object btnDesSimpleBool: TButton [14]
    Left = 485
    Top = 126
    Width = 131
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Boolean'
    TabOrder = 14
    OnClick = btnDesSimpleBoolClick
  end
  inherited memoSerialize: TMemo
    TabOrder = 17
  end
  inherited pnlDeserialize: TPanel
    TabOrder = 18
  end
  inherited memoLog: TMemo
    TabOrder = 15
  end
  object btnSerTypeClass: TButton
    Left = 3
    Top = 248
    Width = 131
    Height = 25
    Caption = 'Types Class'
    TabOrder = 19
    OnClick = btnSerTypeClassClick
  end
  object btnDesTypeClass: TButton
    Left = 485
    Top = 248
    Width = 131
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Types Class'
    TabOrder = 20
    OnClick = btnDesTypeClassClick
  end
end
