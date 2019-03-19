inherited frmSerializationComplex: TfrmSerializationComplex
  Caption = 'frmSerializationComplex'
  PixelsPerInch = 96
  TextHeight = 13
  inherited pnlSerialize: TPanel
    TabOrder = 19
  end
  inherited memoSerialize: TMemo
    TabOrder = 18
  end
  object btnSerComplexObject: TButton [2]
    Left = 3
    Top = 63
    Width = 131
    Height = 25
    Caption = 'ComplexObject'
    TabOrder = 0
    OnClick = btnSerComplexObjectClick
  end
  object btnSerDictionary: TButton [3]
    Left = 3
    Top = 249
    Width = 131
    Height = 25
    Caption = 'Dictionary'
    TabOrder = 1
    OnClick = btnSerDictionaryClick
  end
  object btnSerFilterObject: TButton [4]
    Left = 3
    Top = 218
    Width = 131
    Height = 25
    Caption = 'FilterObject'
    TabOrder = 3
    OnClick = btnSerFilterObjectClick
  end
  object btnSerGenericList: TButton [5]
    Left = 3
    Top = 94
    Width = 131
    Height = 25
    Caption = 'GenericList'
    TabOrder = 4
    OnClick = btnSerGenericListClick
  end
  object btnSerGenericObjectList: TButton [6]
    Left = 3
    Top = 125
    Width = 131
    Height = 25
    Caption = 'GenericObjectList'
    TabOrder = 5
    OnClick = btnSerGenericObjectListClick
  end
  object btnSerSimpleObject: TButton [7]
    Left = 3
    Top = 32
    Width = 131
    Height = 25
    Caption = 'SimpleObject'
    TabOrder = 6
    OnClick = btnSerSimpleObjectClick
  end
  object btnSerStreamable: TButton [8]
    Left = 3
    Top = 156
    Width = 131
    Height = 25
    Caption = 'Streamable'
    TabOrder = 7
    OnClick = btnSerStreamableClick
  end
  object btnStreamableProp: TButton [9]
    Left = 3
    Top = 187
    Width = 131
    Height = 25
    Caption = 'StreamableProp'
    TabOrder = 8
    OnClick = btnStreamablePropClick
  end
  object btnDesComplexObject: TButton [10]
    Left = 485
    Top = 64
    Width = 131
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'ComplexObject'
    TabOrder = 9
    OnClick = btnDesComplexObjectClick
  end
  object btnDesDictionary: TButton [11]
    Left = 485
    Top = 249
    Width = 131
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Dictionary'
    TabOrder = 10
    OnClick = btnDesDictionaryClick
  end
  object btnDesFilterObject: TButton [12]
    Left = 485
    Top = 218
    Width = 131
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'FilterObject'
    TabOrder = 11
    OnClick = btnDesFilterObjectClick
  end
  object btnDesGenericList: TButton [13]
    Left = 485
    Top = 95
    Width = 131
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'GenericList'
    TabOrder = 12
    OnClick = btnDesGenericListClick
  end
  object btnDesGenericObjectList: TButton [14]
    Left = 485
    Top = 126
    Width = 131
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'GenericObjectList'
    TabOrder = 13
    OnClick = btnDesGenericObjectListClick
  end
  object btnDesSimpleObject: TButton [15]
    Left = 485
    Top = 33
    Width = 131
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'SimpleObject'
    TabOrder = 14
    OnClick = btnDesSimpleObjectClick
  end
  object btnDesStreamable: TButton [16]
    Left = 485
    Top = 157
    Width = 131
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Streamable'
    TabOrder = 15
    OnClick = btnDesStreamableClick
  end
  object btnDesStreamableProp: TButton [17]
    Left = 485
    Top = 188
    Width = 131
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'StreamableProp'
    TabOrder = 16
    OnClick = btnDesStreamablePropClick
  end
  inherited pnlDeserialize: TPanel
    TabOrder = 20
  end
  inherited memoDeserialize: TMemo
    TabOrder = 2
  end
  inherited memoLog: TMemo
    TabOrder = 17
  end
end
