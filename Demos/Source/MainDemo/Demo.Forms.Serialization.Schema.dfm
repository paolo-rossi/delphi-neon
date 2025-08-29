inherited frmSerializationSchema: TfrmSerializationSchema
  Caption = 'frmSerializationSchema'
  StyleElements = [seFont, seClient, seBorder]
  TextHeight = 13
  inherited memoLog: TMemo
    StyleElements = [seFont, seClient, seBorder]
  end
  inherited pnlLeft: TPanel
    StyleElements = [seFont, seClient, seBorder]
    inherited pnlSerialize: TPanel
      StyleElements = [seFont, seClient, seBorder]
    end
    inherited catSerialize: TCategoryButtons
      Categories = <
        item
          Caption = 'Attributes'
          Color = 7928316
          Collapsed = False
          Items = <
            item
              Action = actSerAttrUnwrapped
            end>
        end
        item
          Caption = 'Misc'
          Color = 16771839
          Collapsed = False
          Items = <
            item
              Action = actSerMiscTValue
            end
            item
              Action = actSerMiscTValueDict
            end>
        end
        item
          Caption = 'JSON Schema'
          Color = 13026810
          Collapsed = False
          Items = <
            item
              Action = actSerJSONSchema
            end>
        end>
    end
    inherited memoSerialize: TMemo
      StyleElements = [seFont, seClient, seBorder]
    end
  end
  inherited pnlRight: TPanel
    StyleElements = [seFont, seClient, seBorder]
    inherited pnlDeserialize: TPanel
      Visible = False
      StyleElements = [seFont, seClient, seBorder]
    end
    inherited catDeserialize: TCategoryButtons
      Categories = <
        item
          Caption = 'Attribute'
          Color = 7928316
          Collapsed = False
          Items = <
            item
              Action = actDesAttrUnwrapped
            end>
        end
        item
          Caption = 'Misc'
          Color = 16771839
          Collapsed = False
          Items = <
            item
              Action = actDesMiscTValue
            end
            item
              Action = actDesMiscTValueDict
            end>
        end>
    end
    inherited memoDeserialize: TMemo
      StyleElements = [seFont, seClient, seBorder]
    end
  end
  inherited aclMain: TActionList
    object actSerJSONSchema: TAction
      Caption = 'To JSON Schema'
      ImageIndex = 0
      OnExecute = actSerJSONSchemaExecute
    end
    object actSerAttrUnwrapped: TAction
      Caption = 'Unwrapped Attribute'
      ImageIndex = 0
      OnExecute = actSerAttrUnwrappedExecute
    end
    object actDesAttrUnwrapped: TAction
      Caption = 'Unwrapped Attribute'
      ImageIndex = 1
      OnExecute = actDesAttrUnwrappedExecute
    end
    object actSerMiscTValueDict: TAction
      Caption = 'TValue Dictionary'
      ImageIndex = 0
      OnExecute = actSerMiscTValueDictExecute
    end
    object actDesMiscTValueDict: TAction
      Caption = 'TValue Dictionary'
      ImageIndex = 1
      OnExecute = actDesMiscTValueDictExecute
    end
    object actSerMiscTValue: TAction
      Caption = 'TValue'
      ImageIndex = 0
      OnExecute = actSerMiscTValueExecute
    end
    object actDesMiscTValue: TAction
      Caption = 'TValue'
      ImageIndex = 1
      OnExecute = actDesMiscTValueExecute
    end
  end
end
