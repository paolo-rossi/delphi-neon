inherited frmSerializationComplex: TfrmSerializationComplex
  Caption = 'frmSerializationComplex'
  PixelsPerInch = 96
  TextHeight = 13
  inherited pnlLeft: TPanel
    inherited catSerialize: TCategoryButtons
      Categories = <
        item
          Caption = 'Classes'
          Color = 13026810
          Collapsed = False
          Items = <
            item
              Action = actSerClassSimple
            end
            item
              Action = actSerClassComplex
            end
            item
              Action = actSerClassFilter
            end>
        end
        item
          Caption = 'Generics'
          Color = 7928316
          Collapsed = False
          Items = <
            item
              Action = actSerGenericList
            end
            item
              Action = actSerGenericObjectList
            end
            item
              Action = actSerDictionary
            end>
        end
        item
          Caption = 'Streamable'
          Color = 15459203
          Collapsed = False
          Items = <
            item
              Action = actSerStreamable
            end
            item
              Action = actSerStreamableProp
            end>
        end>
    end
  end
  inherited pnlRight: TPanel
    inherited catDeserialize: TCategoryButtons
      Categories = <
        item
          Caption = 'Classes'
          Color = 13026810
          Collapsed = False
          Items = <
            item
              Action = actDesClassSimple
            end
            item
              Action = actDesClassComplex
            end
            item
              Action = actDesClassFilter
            end>
        end
        item
          Caption = 'Generics'
          Color = 7928316
          Collapsed = False
          Items = <
            item
              Action = actDesGenericList
            end
            item
              Action = actDesGenericObjectList
            end
            item
              Action = actDesDictionary
            end>
        end
        item
          Caption = 'Streamable'
          Color = 15459203
          Collapsed = False
          Items = <
            item
              Action = actDesStreamable
            end
            item
              Action = actDesStreamableProp
            end>
        end>
    end
  end
  inherited aclMain: TActionList
    object actSerClassSimple: TAction
      Caption = 'Simple Class'
      ImageIndex = 0
      OnExecute = actSerClassSimpleExecute
    end
    object actSerClassComplex: TAction
      Caption = 'Complex Class'
      ImageIndex = 0
      OnExecute = actSerClassComplexExecute
    end
    object actSerClassFilter: TAction
      Caption = 'Filter Class'
      ImageIndex = 0
      OnExecute = actSerClassFilterExecute
    end
    object actSerGenericList: TAction
      Caption = 'Generic List'
      ImageIndex = 0
      OnExecute = actSerGenericListExecute
    end
    object actSerGenericObjectList: TAction
      Caption = 'Generic ObjectList'
      ImageIndex = 0
      OnExecute = actSerGenericObjectListExecute
    end
    object actSerDictionary: TAction
      Caption = 'Dictionary'
      ImageIndex = 0
      OnExecute = actSerDictionaryExecute
    end
    object actSerStreamable: TAction
      Caption = 'Streamable'
      ImageIndex = 0
      OnExecute = actSerStreamableExecute
    end
    object actSerStreamableProp: TAction
      Caption = 'Streamable Property'
      ImageIndex = 0
      OnExecute = actSerStreamablePropExecute
    end
    object actDesClassSimple: TAction
      Caption = 'Simple Class'
      ImageIndex = 1
      OnExecute = actDesClassSimpleExecute
    end
    object actDesClassComplex: TAction
      Caption = 'Complex Class'
      ImageIndex = 1
      OnExecute = actDesClassComplexExecute
    end
    object actDesClassFilter: TAction
      Caption = 'Filter Class'
      ImageIndex = 1
      OnExecute = actDesClassFilterExecute
    end
    object actDesGenericList: TAction
      Caption = 'Generic List'
      ImageIndex = 1
      OnExecute = actDesGenericListExecute
    end
    object actDesGenericObjectList: TAction
      Caption = 'Generic ObjectList'
      ImageIndex = 1
      OnExecute = actDesGenericObjectListExecute
    end
    object actDesDictionary: TAction
      Caption = 'Dictionary'
      ImageIndex = 1
      OnExecute = actDesDictionaryExecute
    end
    object actDesStreamable: TAction
      Caption = 'Streamable'
      ImageIndex = 1
      OnExecute = actDesStreamableExecute
    end
    object actDesStreamableProp: TAction
      Caption = 'Streamable Prop'
      ImageIndex = 1
      OnExecute = actDesStreamablePropExecute
    end
  end
end
