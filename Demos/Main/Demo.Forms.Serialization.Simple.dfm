inherited frmSerializationSimple: TfrmSerializationSimple
  Caption = 'frmSerializationSimple'
  TextHeight = 13
  inherited pnlLeft: TPanel
    inherited catSerialize: TCategoryButtons
      Categories = <
        item
          Caption = 'Simple Types'
          Color = 7928316
          Collapsed = False
          Items = <
            item
              Action = actSerInteger
            end
            item
              Action = actSerString
            end
            item
              Action = actSerFloat
            end
            item
              Action = actSerBoolean
            end
            item
              Action = actSerDateTime
            end
            item
              Action = actSerEnum
            end
            item
              Action = actSerEnumCustom
            end
            item
              Action = actSerVariants
            end
            item
              Action = actSerTypesClass
            end>
        end>
    end
  end
  inherited pnlRight: TPanel
    inherited catDeserialize: TCategoryButtons
      Categories = <
        item
          Caption = 'Simple Types'
          Color = 7928316
          Collapsed = False
          Items = <
            item
              Action = actDesInteger
            end
            item
              Action = actDesString
            end
            item
              Action = actDesFloat
            end
            item
              Action = actDesBoolean
            end
            item
              Action = actDesDateTime
            end
            item
              Action = actDesEnum
            end
            item
              Action = actDesEnumCustom
            end
            item
              Action = actDesVariants
            end
            item
              Action = actDesTypesClass
            end>
        end>
    end
  end
  inherited aclMain: TActionList
    object actSerInteger: TAction
      Caption = 'Integer'
      ImageIndex = 0
      OnExecute = actSerIntegerExecute
    end
    object actSerString: TAction
      Caption = 'String'
      ImageIndex = 0
      OnExecute = actSerStringExecute
    end
    object actSerFloat: TAction
      Caption = 'Float'
      ImageIndex = 0
      OnExecute = actSerFloatExecute
    end
    object actSerBoolean: TAction
      Caption = 'Boolean'
      ImageIndex = 0
      OnExecute = actSerBooleanExecute
    end
    object actSerDateTime: TAction
      Caption = 'DateTime'
      ImageIndex = 0
      OnExecute = actSerDateTimeExecute
    end
    object actSerTypesClass: TAction
      Caption = 'Simple Class'
      ImageIndex = 0
      OnExecute = actSerTypesClassExecute
    end
    object actSerVariants: TAction
      Caption = 'Variants'
      ImageIndex = 0
      OnExecute = actSerVariantsExecute
    end
    object actSerEnum: TAction
      Caption = 'Enum'
      ImageIndex = 0
      OnExecute = actSerEnumExecute
    end
    object actSerEnumCustom: TAction
      Caption = 'Custom Enum'
      ImageIndex = 0
      OnExecute = actSerEnumCustomExecute
    end
    object actDesInteger: TAction
      Caption = 'Integer'
      ImageIndex = 1
      OnExecute = actDesIntegerExecute
    end
    object actDesString: TAction
      Caption = 'String'
      ImageIndex = 1
      OnExecute = actDesStringExecute
    end
    object actDesFloat: TAction
      Caption = 'Float'
      ImageIndex = 1
      OnExecute = actDesFloatExecute
    end
    object actDesBoolean: TAction
      Caption = 'Boolean'
      ImageIndex = 1
      OnExecute = actDesBooleanExecute
    end
    object actDesDateTime: TAction
      Caption = 'DateTime'
      ImageIndex = 1
      OnExecute = actDesDateTimeExecute
    end
    object actDesTypesClass: TAction
      Caption = 'Simple Class'
      ImageIndex = 1
      OnExecute = actDesTypesClassExecute
    end
    object actDesVariants: TAction
      Caption = 'Variants'
      ImageIndex = 1
      OnExecute = actDesVariantsExecute
    end
    object actDesEnum: TAction
      Caption = 'Enum'
      ImageIndex = 1
      OnExecute = actDesEnumExecute
    end
    object actDesEnumCustom: TAction
      Caption = 'Custom Enum'
      ImageIndex = 1
      OnExecute = actDesEnumCustomExecute
    end
  end
end
