unit Neon.Core.Utils.DB;

interface

uses
  System.SysUtils, System.Classes, Data.DB, System.JSON,
  Neon.Core.Persistence,
  Neon.Core.Utils;

type
  TDataSetUtils = class
  private
    class function RecordToXML(const ADataSet: TDataSet; const ARootPath: string; AConfig: INeonConfiguration): string; static;
    class function RecordToCSV(const ADataSet: TDataSet; AConfig: INeonConfiguration): string; static;
  public
    class function RecordToJSONSchema(const ADataSet: TDataSet; AConfig: INeonConfiguration): TJSONObject; static;

    class function RecordToJSONObject(const ADataSet: TDataSet; AConfig: INeonConfiguration): TJSONObject; static;
    class function DataSetToJSONArray(const ADataSet: TDataSet; AConfig: INeonConfiguration): TJSONArray; overload; static;
    class function DataSetToJSONArray(const ADataSet: TDataSet; const AAcceptFunc: TFunc<Boolean>; AConfig: INeonConfiguration): TJSONArray; overload; static;

    class function DataSetToXML(const ADataSet: TDataSet; AConfig: INeonConfiguration): string; overload; static;
    class function DataSetToXML(const ADataSet: TDataSet; const AAcceptFunc: TFunc<Boolean>; AConfig: INeonConfiguration): string; overload; static;

    class procedure JSONToRecord(AJSONObject: TJSONObject; ADataSet: TDataSet; AConfig: INeonConfiguration); static;
    class procedure JSONToDataSet(AJSONValue: TJSONValue; ADataSet: TDataSet; AConfig: INeonConfiguration); static;

    class function DataSetToCSV(const ADataSet: TDataSet; AConfig: INeonConfiguration): string; static;

    class function DatasetMetadataToJSONObject(const ADataSet: TDataSet; AConfig: INeonConfiguration): TJSONObject; static;

    class function BlobFieldToBase64(ABlobField: TBlobField): string;
    class procedure Base64ToBlobField(const ABase64: string; ABlobField: TBlobField);
  end;

implementation

uses
  System.StrUtils, System.DateUtils, System.TypInfo;

class function TDataSetUtils.RecordToCSV(const ADataSet: TDataSet; AConfig: INeonConfiguration): string;
var
  LField: TField;
begin
  if not Assigned(ADataSet) then
    raise Exception.Create('DataSet not assigned');
  if not ADataSet.Active then
    raise Exception.Create('DataSet is not active');
  if ADataSet.IsEmpty then
    raise Exception.Create('DataSet is empty');

  Result := '';
  for LField in ADataSet.Fields do
  begin
    Result := Result + LField.AsString + ',';
  end;
  Result := Result.TrimRight([',']);
end;

class function TDataSetUtils.RecordToJSONObject(const ADataSet: TDataSet; AConfig: INeonConfiguration): TJSONObject;
var
  LField: TField;
  LPairName: string;
begin
  Result := TJSONObject.Create;

  for LField in ADataSet.Fields do
  begin
    LPairName := LField.FieldName;

    if ContainsStr(LPairName, '.') then
      Continue;

    case LField.DataType of
      TFieldType.ftString:          Result.AddPair(LPairName, LField.AsString);
      TFieldType.ftSmallint:        Result.AddPair(LPairName, TJSONNumber.Create(LField.AsInteger));
      TFieldType.ftInteger:         Result.AddPair(LPairName, TJSONNumber.Create(LField.AsInteger));
      TFieldType.ftWord:            Result.AddPair(LPairName, TJSONNumber.Create(LField.AsInteger));
      TFieldType.ftBoolean:         Result.AddPair(LPairName, TJSONUtils.BooleanToTJSON(LField.AsBoolean));
      TFieldType.ftFloat:           Result.AddPair(LPairName, TJSONNumber.Create(LField.AsFloat));
      TFieldType.ftCurrency:        Result.AddPair(LPairName, TJSONNumber.Create(LField.AsCurrency));
      TFieldType.ftBCD:             Result.AddPair(LPairName, TJSONNumber.Create(LField.AsFloat));
      TFieldType.ftDate:            Result.AddPair(LPairName, TJSONUtils.DateToJSON(LField.AsDateTime, AConfig.GetUseUTCDate));
      TFieldType.ftTime:            Result.AddPair(LPairName, TJSONUtils.DateToJSON(LField.AsDateTime, AConfig.GetUseUTCDate));
      TFieldType.ftDateTime:        Result.AddPair(LPairName, TJSONUtils.DateToJSON(LField.AsDateTime, AConfig.GetUseUTCDate));
      TFieldType.ftBytes:           Result.AddPair(LPairName, TBase64.Encode(LField.AsBytes));
      TFieldType.ftVarBytes:        Result.AddPair(LPairName, TBase64.Encode(LField.AsBytes));
      TFieldType.ftAutoInc:         Result.AddPair(LPairName, TJSONNumber.Create(LField.AsInteger));
      TFieldType.ftBlob:            Result.AddPair(LPairName, BlobFieldToBase64(LField as TBlobField));
      TFieldType.ftMemo:            Result.AddPair(LPairName, LField.AsString);
      TFieldType.ftGraphic:         Result.AddPair(LPairName, TBase64.Encode(LField.AsBytes));
//      TFieldType.ftFmtMemo: ;
//      TFieldType.ftParadoxOle: ;
//      TFieldType.ftDBaseOle: ;
      TFieldType.ftTypedBinary:     Result.AddPair(LPairName, TBase64.Encode(LField.AsBytes));
//      TFieldType.ftCursor: ;
      TFieldType.ftFixedChar:       Result.AddPair(LPairName, LField.AsString);
      TFieldType.ftWideString:      Result.AddPair(LPairName, LField.AsWideString);
      TFieldType.ftLargeint:        Result.AddPair(LPairName, TJSONNumber.Create(LField.AsLargeInt));
      TFieldType.ftADT:             Result.AddPair(LPairName, TBase64.Encode(LField.AsBytes));
      TFieldType.ftArray:           Result.AddPair(LPairName, TBase64.Encode(LField.AsBytes));
//      TFieldType.ftReference: ;
      TFieldType.ftDataSet:         Result.AddPair(LPairName, DataSetToJSONArray((LField as TDataSetField).NestedDataSet, AConfig));
      TFieldType.ftOraBlob:         Result.AddPair(LPairName, TBase64.Encode(LField.AsBytes));
      TFieldType.ftOraClob:         Result.AddPair(LPairName, TBase64.Encode(LField.AsBytes));
      TFieldType.ftVariant:         Result.AddPair(LPairName, LField.AsString);
//      TFieldType.ftInterface: ;
//      TFieldType.ftIDispatch: ;
      TFieldType.ftGuid:            Result.AddPair(LPairName, LField.AsString);
      TFieldType.ftTimeStamp:       Result.AddPair(LPairName, TJSONUtils.DateToJSON(LField.AsDateTime, AConfig.GetUseUTCDate));
      TFieldType.ftFMTBcd:          Result.AddPair(LPairName, TJSONNumber.Create(LField.AsFloat));
      TFieldType.ftFixedWideChar:   Result.AddPair(LPairName, LField.AsString);
      TFieldType.ftWideMemo:        Result.AddPair(LPairName, LField.AsString);
      TFieldType.ftOraTimeStamp:    Result.AddPair(LPairName, TJSONUtils.DateToJSON(LField.AsDateTime, AConfig.GetUseUTCDate));
      TFieldType.ftOraInterval:     Result.AddPair(LPairName, LField.AsString);
      TFieldType.ftLongWord:        Result.AddPair(LPairName, TJSONNumber.Create(LField.AsInteger));
      TFieldType.ftShortint:        Result.AddPair(LPairName, TJSONNumber.Create(LField.AsInteger));
      TFieldType.ftByte:            Result.AddPair(LPairName, TJSONNumber.Create(LField.AsInteger));
      TFieldType.ftExtended:        Result.AddPair(LPairName, TJSONNumber.Create(LField.AsFloat));
//      TFieldType.ftConnection: ;
//      TFieldType.ftParams: ;
//      TFieldType.ftStream: ;
      TFieldType.ftTimeStampOffset: Result.AddPair(LPairName, LField.AsString);
//      TFieldType.ftObject: ;
      TFieldType.ftSingle:          Result.AddPair(LPairName, TJSONNumber.Create(LField.AsFloat));
    end;
  end;
end;

class function TDataSetUtils.RecordToJSONSchema(const ADataSet: TDataSet; AConfig: INeonConfiguration): TJSONObject;
var
  LField: TField;
  LPairName: string;
  LJSONField: TJSONObject;
begin
  Result := TJSONObject.Create;

  if not Assigned(ADataSet) then
    Exit;

  if not ADataSet.Active then
    ADataSet.Open;

  for LField in ADataSet.Fields do
  begin
    LPairName := LField.FieldName;

    if LPairName.Contains('.') then
      Continue;

    LJSONField := TJSONObject.Create;
    Result.AddPair(LPairName, LJSONField);

    case LField.DataType of
      TFieldType.ftString:
      begin
        LJSONField.AddPair('type', 'string');
      end;

      TFieldType.ftSmallint,
      TFieldType.ftInteger,
      TFieldType.ftWord,
      TFieldType.ftLongWord,
      TFieldType.ftShortint,
      TFieldType.ftByte:
      begin
        LJSONField.AddPair('type', 'integer').AddPair('format', 'int32');
      end;

      TFieldType.ftBoolean:
      begin
        LJSONField.AddPair('type', 'boolean');
      end;

      TFieldType.ftFloat,
      TFieldType.ftSingle:
      begin
        LJSONField.AddPair('type', 'number').AddPair('format', 'float');
      end;

      TFieldType.ftCurrency,
      TFieldType.ftExtended:
      begin
        LJSONField.AddPair('type', 'number').AddPair('format', 'double');
      end;

      TFieldType.ftBCD:
      begin
        LJSONField.AddPair('type', 'number').AddPair('format', 'double');
      end;

      TFieldType.ftDate:
      begin
        LJSONField.AddPair('type', 'string').AddPair('format', 'date');
      end;

      TFieldType.ftTime:
      begin
        LJSONField.AddPair('type', 'string').AddPair('format', 'date-time');
      end;

      TFieldType.ftDateTime:
      begin
        LJSONField.AddPair('type', 'string').AddPair('format', 'date-time');
      end;

//        ftBytes: ;
//        ftVarBytes: ;

      TFieldType.ftAutoInc:
      begin
        LJSONField.AddPair('type', 'integer').AddPair('format', 'int32');
      end;

      //        ftBlob: ;

      TFieldType.ftMemo,
      TFieldType.ftWideMemo:
      begin
        LJSONField.AddPair('type', 'string');
      end;

//        ftGraphic: ;
//        ftFmtMemo: ;
//        ftParadoxOle: ;
//        ftDBaseOle: ;
//        ftTypedBinary: ;
//        ftCursor: ;
      TFieldType.ftFixedChar,
      TFieldType.ftFixedWideChar,
      TFieldType.ftWideString:
      begin
        LJSONField.AddPair('type', 'string');
      end;

      TFieldType.ftLargeint:
      begin
        LJSONField.AddPair('type', 'integer').AddPair('format', 'int64');
      end;

//        ftADT: ;
//        ftArray: ;
//        ftReference: ;
//        ftDataSet: ;
//        ftOraBlob: ;
//        ftOraClob: ;

      TFieldType.ftVariant:
      begin
        LJSONField.AddPair('type', 'string');
      end;

//        ftInterface: ;
//        ftIDispatch: ;

      TFieldType.ftGuid:
      begin
        LJSONField.AddPair('type', 'string');
      end;

      TFieldType.ftTimeStamp:
      begin
        LJSONField.AddPair('type', 'string').AddPair('format', 'date-time');
      end;

      TFieldType.ftFMTBcd:
      begin
        LJSONField.AddPair('type', 'number').AddPair('format', 'double');
      end;


//        ftOraTimeStamp: ;
//        ftOraInterval: ;
//        ftConnection: ;
//        ftParams: ;
//        ftStream: ;
//        ftTimeStampOffset: ;
//        ftObject: ;
    end;
  end;
end;

class function TDataSetUtils.RecordToXML(const ADataSet: TDataSet; const ARootPath: string; AConfig: INeonConfiguration): string;
var
  LField: TField;
begin
  Result := '';
  for LField in ADataSet.Fields do
  begin
    Result := Result
      + Format('<%s>%s</%s>', [LField.FieldName, LField.AsString, LField.FieldName]);
  end;
end;

class function TDataSetUtils.DataSetToJSONArray(const ADataSet: TDataSet; AConfig: INeonConfiguration): TJSONArray;
begin
  Result := DataSetToJSONArray(ADataSet, nil, AConfig);
end;

class function TDataSetUtils.DataSetToCSV(const ADataSet: TDataSet; AConfig: INeonConfiguration): string;
var
  LBookmark: TBookmark;
begin
  Result := '';
  if not Assigned(ADataSet) then
    Exit;

  if not ADataSet.Active then
    ADataSet.Open;

  ADataSet.DisableControls;
  try
    LBookmark := ADataSet.Bookmark;
    try
      ADataSet.First;
      while not ADataSet.Eof do
      try
        Result := Result + TDataSetUtils.RecordToCSV(ADataSet, AConfig) + sLineBreak;
      finally
        ADataSet.Next;
      end;
    finally
      ADataSet.GotoBookmark(LBookmark);
    end;
  finally
    ADataSet.EnableControls;
  end;
end;

class function TDataSetUtils.DataSetToJSONArray(const ADataSet: TDataSet; const AAcceptFunc: TFunc<Boolean>; AConfig: INeonConfiguration): TJSONArray;
var
  LBookmark: TBookmark;
begin
  Result := TJSONArray.Create;
  if not Assigned(ADataSet) then
    Exit;

  if not ADataSet.Active then
    ADataSet.Open;

  ADataSet.DisableControls;
  try
    LBookmark := ADataSet.Bookmark;
    try
      ADataSet.First;
      while not ADataSet.Eof do
      try
        if (not Assigned(AAcceptFunc)) or (AAcceptFunc()) then
          Result.AddElement(RecordToJSONObject(ADataSet, AConfig));
      finally
        ADataSet.Next;
      end;
    finally
      ADataSet.GotoBookmark(LBookmark);
    end;
  finally
    ADataSet.EnableControls;
  end;
end;

class function TDataSetUtils.DataSetToXML(const ADataSet: TDataSet; AConfig: INeonConfiguration): string;
begin
  Result := DataSetToXML(ADataSet, nil, AConfig);
end;

class function TDataSetUtils.DataSetToXML(const ADataSet: TDataSet; const AAcceptFunc: TFunc<Boolean>; AConfig: INeonConfiguration): string;
var
  LBookmark: TBookmark;
begin
  Result := '';
  if not Assigned(ADataSet) then
    Exit;

  if not ADataSet.Active then
    ADataSet.Open;

  ADataSet.DisableControls;
  try
    LBookmark := ADataSet.Bookmark;
    try
      ADataSet.First;
      while not ADataSet.Eof do
      try
        if (not Assigned(AAcceptFunc)) or (AAcceptFunc()) then
          Result := Result + '<row>' + RecordToXML(ADataSet, '', AConfig) + '</row>';
      finally
        ADataSet.Next;
      end;
    finally
      ADataSet.GotoBookmark(LBookmark);
    end;
  finally
    ADataSet.EnableControls;
  end;
end;

class procedure TDataSetUtils.JSONToDataSet(AJSONValue: TJSONValue; ADataSet: TDataSet; AConfig: INeonConfiguration);
var
  LJSONArray: TJSONArray;
  LJSONItem: TJSONObject;
  LIndex: Integer;
begin
  LJSONArray := AJSONValue as TJSONArray;

  for LIndex := 0 to LJSONArray.Count - 1 do
  begin
    LJSONItem := LJSONArray.Items[LIndex] as TJSONObject;

    JSONToRecord(LJSONItem, ADataSet, AConfig);
  end;
end;

class procedure TDataSetUtils.JSONToRecord(AJSONObject: TJSONObject; ADataSet: TDataSet; AConfig: INeonConfiguration);
var
  LJSONField: TJSONValue;
  LIndex: Integer;
  LField: TField;
begin
  ADataSet.Append;
  for LIndex := 0 to ADataSet.Fields.Count - 1 do
  begin
    LField := ADataSet.Fields[LIndex];
    LJSONField := AJSONObject.GetValue(LField.FieldName);
    if not Assigned(LJSONField) then
      Continue;

    case LField.DataType of
      //TFieldType.ftUnknown: ;
      TFieldType.ftString:          LField.AsString := LJSONField.Value;
      TFieldType.ftSmallint:        LField.AsString := LJSONField.Value;
      TFieldType.ftInteger:         LField.AsString := LJSONField.Value;
      TFieldType.ftWord:            LField.AsString := LJSONField.Value;
      TFieldType.ftBoolean:         LField.AsString := LJSONField.Value;
      TFieldType.ftFloat:           LField.AsString := LJSONField.Value;
      TFieldType.ftCurrency:        LField.AsString := LJSONField.Value;
      TFieldType.ftBCD:             LField.AsString := LJSONField.Value;
      TFieldType.ftDate:            LField.AsDateTime := TJSONUtils.JSONToDate(LJSONField.Value, AConfig.GetUseUTCDate);
      TFieldType.ftTime:            LField.AsDateTime := TJSONUtils.JSONToDate(LJSONField.Value, AConfig.GetUseUTCDate);
      TFieldType.ftDateTime:        LField.AsDateTime := TJSONUtils.JSONToDate(LJSONField.Value, AConfig.GetUseUTCDate);
      TFieldType.ftBytes:           ADataSet.Fields[LIndex].AsBytes := TBase64.Decode(LJSONField.Value);
      TFieldType.ftVarBytes:        ADataSet.Fields[LIndex].AsBytes := TBase64.Decode(LJSONField.Value);
      TFieldType.ftAutoInc:         LField.AsString := LJSONField.Value;
      TFieldType.ftBlob:            TDataSetUtils.Base64ToBlobField(LJSONField.Value, ADataSet.Fields[LIndex] as TBlobField);
      TFieldType.ftMemo:            LField.AsString := LJSONField.Value;
      TFieldType.ftGraphic:         (ADataSet.Fields[LIndex] as TGraphicField).Value := TBase64.Decode(LJSONField.Value);
      //TFieldType.ftFmtMemo: ;
      //TFieldType.ftParadoxOle: ;
      //TFieldType.ftDBaseOle: ;
      TFieldType.ftTypedBinary:     ADataSet.Fields[LIndex].AsBytes := TBase64.Decode(LJSONField.Value);
      //TFieldType.ftCursor: ;
      TFieldType.ftFixedChar:       LField.AsString := LJSONField.Value;
      TFieldType.ftWideString:      LField.AsString := LJSONField.Value;
      TFieldType.ftLargeint:        LField.AsString := LJSONField.Value;
      TFieldType.ftADT:             ADataSet.Fields[LIndex].AsBytes := TBase64.Decode(LJSONField.Value);
      TFieldType.ftArray:           ADataSet.Fields[LIndex].AsBytes := TBase64.Decode(LJSONField.Value);
      //TFieldType.ftReference: ;
      TFieldType.ftDataSet:         JSONToDataSet(LJSONField, (ADataSet.Fields[LIndex] as TDataSetField).NestedDataSet, AConfig);
      TFieldType.ftOraBlob:         TDataSetUtils.Base64ToBlobField(LJSONField.Value, ADataSet.Fields[LIndex] as TBlobField);
      TFieldType.ftOraClob:         TDataSetUtils.Base64ToBlobField(LJSONField.Value, ADataSet.Fields[LIndex] as TBlobField);
      TFieldType.ftVariant:         TDataSetUtils.Base64ToBlobField(LJSONField.Value, ADataSet.Fields[LIndex] as TBlobField);
      //TFieldType.ftInterface: ;
      //TFieldType.ftIDispatch: ;
      TFieldType.ftGuid:            LField.AsString := LJSONField.Value;
      TFieldType.ftTimeStamp:       LField.AsDateTime := TJSONUtils.JSONToDate(LJSONField.Value, AConfig.GetUseUTCDate);
      TFieldType.ftFMTBcd:          ADataSet.Fields[LIndex].AsBytes := TBase64.Decode(LJSONField.Value);
      TFieldType.ftFixedWideChar:   LField.AsString := LJSONField.Value;
      TFieldType.ftWideMemo:        LField.AsString := LJSONField.Value;
      TFieldType.ftOraTimeStamp:    LField.AsDateTime := TJSONUtils.JSONToDate(LJSONField.Value, AConfig.GetUseUTCDate);
      TFieldType.ftOraInterval:     LField.AsString := LJSONField.Value;
      TFieldType.ftLongWord:        LField.AsString := LJSONField.Value;
      TFieldType.ftShortint:        LField.AsString := LJSONField.Value;
      TFieldType.ftByte:            LField.AsString := LJSONField.Value;
      TFieldType.ftExtended:        LField.AsString := LJSONField.Value;
      //TFieldType.ftConnection: ;
      //TFieldType.ftParams: ;
      TFieldType.ftStream:          ADataSet.Fields[LIndex].AsBytes := TBase64.Decode(LJSONField.Value);
      //TFieldType.ftTimeStampOffset: ;
      //TFieldType.ftObject: ;
      TFieldType.ftSingle:          LField.AsString := LJSONField.Value;
    end;
  end;

  try
    ADataSet.Post;
  except
    ADataSet.Cancel;
    raise;
  end;
end;

class procedure TDataSetUtils.Base64ToBlobField(const ABase64: string; ABlobField: TBlobField);
var
  LBinaryStream: TMemoryStream;
begin
  LBinaryStream := TMemoryStream.Create;
  try
    TBase64.Decode(ABase64, LBinaryStream);
    ABlobField.LoadFromStream(LBinaryStream);
  finally
    LBinaryStream.Free;
  end;
end;

class function TDataSetUtils.BlobFieldToBase64(ABlobField: TBlobField): string;
var
  LBlobStream: TMemoryStream;
begin
  LBlobStream := TMemoryStream.Create;
  try
    ABlobField.SaveToStream(LBlobStream);
    LBlobStream.Position := soFromBeginning;
    Result := TBase64.Encode(LBlobStream);
  finally
    LBlobStream.Free;
  end;
end;

class function TDataSetUtils.DatasetMetadataToJSONObject(const ADataSet: TDataSet; AConfig: INeonConfiguration): TJSONObject;
  procedure AddPropertyValue(APropertyName: string);
  begin
    TValueToJSONObject(Result, APropertyName, ReadPropertyValue(ADataSet, APropertyName));
  end;
begin
  Result := TJSONObject.Create;
  AddPropertyValue('Eof');
  AddPropertyValue('Bof');
  AddPropertyValue('RecNo');
  AddPropertyValue('Name');
end;

end.
