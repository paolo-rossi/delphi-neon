inherited frmSerializationRecords: TfrmSerializationRecords
  Caption = 'frmSerializationRecords'
  TextHeight = 13
  inherited pnlLeft: TPanel
    inherited catSerialize: TCategoryButtons
      Categories = <
        item
          Caption = 'Records'
          Color = 13026810
          Collapsed = False
          Items = <
            item
              Action = actSerRecord
            end
            item
              Action = actSerRecordManaged
            end>
        end
        item
          Caption = 'Arrays'
          Color = 7928316
          Collapsed = False
          Items = <
            item
              Action = actSerArrayInt
            end
            item
              Action = actSerArrayString
            end
            item
              Action = actSerArrayEnum
            end
            item
              Action = actSerSetEnumCustom
            end>
        end
        item
          Caption = 'Sets'
          Color = 15459203
          Collapsed = False
          Items = <
            item
              Action = actSerSetNumber
            end
            item
              Action = actSerSetBoolean
            end
            item
              Action = actSerSetEnum
            end
            item
              Action = actSerSetEnumCustom
            end>
        end>
    end
  end
  inherited pnlRight: TPanel
    inherited catDeserialize: TCategoryButtons
      Categories = <
        item
          Caption = 'Records'
          Color = 13026810
          Collapsed = False
          Items = <
            item
              Action = actDesRecord
            end
            item
              Action = actDesRecordManaged
            end>
        end
        item
          Caption = 'Arrays'
          Color = 7928316
          Collapsed = False
          Items = <
            item
              Action = actDesArrayInt
            end
            item
              Action = actDesArrayString
            end
            item
              Action = actDesArrayEnum
            end
            item
              Action = actDesArrayEnumCustom
            end>
        end
        item
          Caption = 'Sets'
          Color = 15459203
          Collapsed = False
          Items = <
            item
              Action = actDesSetNumber
            end
            item
              Action = actDesSetBoolean
            end
            item
              Action = actDesSetEnum
            end
            item
              Action = actDesArrayEnumCustom
            end>
        end>
    end
  end
  inherited aclMain: TActionList
    object actSerRecord: TAction
      Caption = 'Record'
      ImageIndex = 0
      OnExecute = actSerRecordExecute
    end
    object actSerRecordManaged: TAction
      Caption = 'Managed Record'
      ImageIndex = 0
      OnExecute = actSerRecordManagedExecute
    end
    object actSerArrayInt: TAction
      Caption = 'of Integer'
      ImageIndex = 0
      OnExecute = actSerArrayIntExecute
    end
    object actSerArrayString: TAction
      Caption = 'of String'
      ImageIndex = 0
      OnExecute = actSerArrayStringExecute
    end
    object actSerArrayEnum: TAction
      Caption = 'of Enum'
      ImageIndex = 0
      OnExecute = actSerArrayEnumExecute
    end
    object actSerArrayEnumCustom: TAction
      Caption = 'of Custom Enum'
      ImageIndex = 0
      OnExecute = actSerArrayEnumCustomExecute
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
    object actSerSetNumber: TAction
      Caption = 'of Number'
      ImageIndex = 0
      OnExecute = actSerSetNumberExecute
    end
    object actSerSetBoolean: TAction
      Caption = 'of Boolean'
      ImageIndex = 0
      OnExecute = actSerSetBooleanExecute
    end
    object actSerSetChar: TAction
      Caption = 'of Char'
      ImageIndex = 0
      OnExecute = actSerSetCharExecute
    end
    object actSerSetEnum: TAction
      Caption = 'of Enum'
      ImageIndex = 0
      OnExecute = actSerSetEnumExecute
    end
    object actSerSetEnumCustom: TAction
      Caption = 'of Custom Enum'
      ImageIndex = 0
      OnExecute = actSerSetEnumCustomExecute
    end
    object actDesRecord: TAction
      Caption = 'Record'
      ImageIndex = 1
      OnExecute = actDesRecordExecute
    end
    object actDesRecordManaged: TAction
      Caption = 'Managed Record'
      ImageIndex = 1
      OnExecute = actDesRecordManagedExecute
    end
    object actDesArrayInt: TAction
      Caption = 'of Integer'
      ImageIndex = 1
      OnExecute = actDesArrayIntExecute
    end
    object actDesArrayString: TAction
      Caption = 'of String'
      ImageIndex = 1
      OnExecute = actDesArrayStringExecute
    end
    object actDesArrayEnum: TAction
      Caption = 'of Enum'
      ImageIndex = 1
      OnExecute = actDesArrayEnumExecute
    end
    object actDesArrayEnumCustom: TAction
      Caption = 'of Custom Enum'
      ImageIndex = 1
      OnExecute = actDesArrayEnumCustomExecute
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
    object actDesSetNumber: TAction
      Caption = 'of Number'
      ImageIndex = 1
      OnExecute = actDesSetNumberExecute
    end
    object actDesSetBoolean: TAction
      Caption = 'of Boolean'
      ImageIndex = 1
      OnExecute = actDesSetBooleanExecute
    end
    object actDesSetEnum: TAction
      Caption = 'of Enum'
      ImageIndex = 1
      OnExecute = actDesSetEnumExecute
    end
    object actDesSetEnumCustom: TAction
      Caption = 'of Custom Enum'
      ImageIndex = 1
      OnExecute = actDesSetEnumCustomExecute
    end
  end
end
