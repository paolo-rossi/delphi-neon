{******************************************************************************}
{                                                                              }
{  Neon: Serialization Library for Delphi                                      }
{  Copyright (c) 2018-2019 Paolo Rossi                                         }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{******************************************************************************}
{                                                                              }
{  Licensed under the Apache License, Version 2.0 (the "License");             }
{  you may not use this file except in compliance with the License.            }
{  You may obtain a copy of the License at                                     }
{                                                                              }
{      http://www.apache.org/licenses/LICENSE-2.0                              }
{                                                                              }
{  Unless required by applicable law or agreed to in writing, software         }
{  distributed under the License is distributed on an "AS IS" BASIS,           }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    }
{  See the License for the specific language governing permissions and         }
{  limitations under the License.                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Core.Utils;

interface

{$I Neon.inc}

uses
  System.Classes, System.SysUtils, Data.DB, System.Rtti, System.JSON,
  System.Generics.Collections,
  {$IFDEF HAS_NET_ENCODING}
  System.NetEncoding,
  {$ELSE}
  IdCoder, IdCoderMIME, IdGlobal,
  {$ENDIF}

  Neon.Core.Persistence;

type
  TJSONUtils = class
  public
    class procedure Decode(const ASource: string; ADest: TStream); overload;
    class function Encode(const ASource: TStream): string; overload;

    class function ToJSON(AJSONValue: TJSONValue): string; static;

    class function StringArrayToJsonArray(const AValues: TArray<string>): string; static;
    class function DoubleArrayToJsonArray(const AValues: TArray<Double>): string; static;
    class function IntegerArrayToJsonArray(const AValues: TArray<Integer>): string; static;

    class procedure JSONCopyFrom(ASource, ADestination: TJSONObject); static;

    class function BooleanToTJSON(AValue: Boolean): TJSONValue;
    class function DateToJSON(ADate: TDateTime; AInputIsUTC: Boolean = True): string; static;
    class function JSONToDate(const ADate: string; AReturnUTC: Boolean = True): TDateTime; static;
  end;

  TRttiUtils = class
  private
    class var FContext: TRttiContext;
  public
    // TRttiObject helpers functions
    class function FindAttribute<T: TCustomAttribute>(AType: TRttiObject): T; static;

    class function HasAttribute<T: TCustomAttribute>(
      AClass: TClass): Boolean; overload; static;

    class function HasAttribute<T: TCustomAttribute>(
      ARttiObj: TRttiObject): Boolean; overload; static;

    class function HasAttribute<T: TCustomAttribute>(
      ARttiObj: TRttiObject; const ADoSomething: TProc<T>): Boolean; overload; static;

    class function ForEachAttribute<T: TCustomAttribute>(
      ARttiObj: TRttiObject; const ADoSomething: TProc<T>): Integer; overload; static;

    // TRttiType helpers functions
    class function ForEachMethodWithAttribute<T: TCustomAttribute>(
      ARttiType: TRttiType; const ADoSomething: TFunc<TRttiMethod, T, Boolean>): Integer; static;

    class function ForEachFieldWithAttribute<T: TCustomAttribute>(
      ARttiType: TRttiType; const ADoSomething: TFunc<TRttiField, T, Boolean>): Integer; overload; static;

    class function ForEachPropertyWithAttribute<T: TCustomAttribute>(
      ARttiType: TRttiType; const ADoSomething: TFunc<TRttiProperty, T, Boolean>): Integer; overload; static;

    class function IsDynamicArrayOf<T: class>(ARttiType: TRttiType;
      const AAllowInherithance: Boolean = True): Boolean; overload; static;

    class function IsDynamicArrayOf(ARttiType: TRttiType; const AClass: TClass;
      const AAllowInherithance: Boolean = True): Boolean; overload; static;

    class function IsObjectOfType<T: class>(ARttiType: TRttiType;
      const AAllowInherithance: Boolean = True): Boolean; overload; static;

    class function IsObjectOfType(ARttiType: TRttiType; const AClass: TClass;
      const AAllowInherithance: Boolean = True): Boolean; overload; static;

    // Create new value data
    class function CreateNewValue(AType: TRttiType): TValue; static;

    // Create instance of class with parameterless constructor
    class function CreateInstanceValue(AType: TRttiType): TValue; overload;

    // Create instance of class with parameterless constructor
    class function CreateInstance(AClass: TClass): TObject;  overload;
    class function CreateInstance(AType: TRttiType): TObject; overload;
    class function CreateInstance(const ATypeName: string): TObject; overload;

    // Create instance of class with one string parameter
    class function CreateInstance(AClass: TClass; const AValue: string): TObject;  overload;
    class function CreateInstance(AType: TRttiType; const AValue: string): TObject; overload;
    class function CreateInstance(const ATypeName, AValue: string): TObject; overload;

    // Create instance of class with an array of TValue
    class function CreateInstance(AClass: TClass; const Args: array of TValue): TObject;  overload;
    class function CreateInstance(AType: TRttiType;  const Args: array of TValue): TObject; overload;
    class function CreateInstance(const ATypeName: string; const Args: array of TValue): TObject; overload;

    // Rtti general helper functions
    class function IfHasAttribute<T: TCustomAttribute>(AInstance: TObject): Boolean; overload;
    class function IfHasAttribute<T: TCustomAttribute>(AInstance: TObject; const ADoSomething: TProc<T>): Boolean; overload;

    class function ForEachAttribute<T: TCustomAttribute>(AInstance: TObject; const ADoSomething: TProc<T>): Integer; overload;

    class function ForEachFieldWithAttribute<T: TCustomAttribute>(AInstance: TObject; const ADoSomething: TFunc<TRttiField, T, Boolean>): Integer; overload;
    class function ForEachField(AInstance: TObject; const ADoSomething: TFunc<TRttiField, Boolean>): Integer;

    class function GetType(AObject: TRttiObject): TRttiType;

    class property Context: TRttiContext read FContext;
  end;

  TDataSetUtils = class
  private
    class function RecordToXML(const ADataSet: TDataSet; const ARootPath: string; AConfig: TNeonConfiguration): string; static;
    class function RecordToCSV(const ADataSet: TDataSet; AConfig: TNeonConfiguration): string; static;
  public
    class function RecordToJSONObject(const ADataSet: TDataSet; AConfig: TNeonConfiguration): TJSONObject; static;
    class function DataSetToJSONArray(const ADataSet: TDataSet; AConfig: TNeonConfiguration): TJSONArray; overload; static;
    class function DataSetToJSONArray(const ADataSet: TDataSet; const AAcceptFunc: TFunc<Boolean>; AConfig: TNeonConfiguration): TJSONArray; overload; static;

    class function DataSetToXML(const ADataSet: TDataSet; AConfig: TNeonConfiguration): string; overload; static;
    class function DataSetToXML(const ADataSet: TDataSet; const AAcceptFunc: TFunc<Boolean>; AConfig: TNeonConfiguration): string; overload; static;

    class function DataSetToCSV(const ADataSet: TDataSet; AConfig: TNeonConfiguration): string; static;

    class function DatasetMetadataToJSONObject(const ADataSet: TDataSet; AConfig: TNeonConfiguration): TJSONObject; static;
  end;

type
  TBase64 = class
    class function Encode(const ASource: TStream): string; overload;
    class procedure Decode(const ASource: string; ADest: TStream); overload;
  end;


function ExecuteMethod(const AInstance: TValue; const AMethodName: string; const AArguments: array of TValue;
  const ABeforeExecuteProc: TProc{ = nil}; const AAfterExecuteProc: TProc<TValue>{ = nil}): Boolean; overload;

function ExecuteMethod(const AInstance: TValue; AMethod: TRttiMethod; const AArguments: array of TValue;
  const ABeforeExecuteProc: TProc{ = nil}; const AAfterExecuteProc: TProc<TValue>{ = nil}): Boolean; overload;

function ReadPropertyValue(AInstance: TObject; const APropertyName: string): TValue;

function TValueToJSONObject(const AName: string; const AValue: TValue): TJSONObject; overload;
function TValueToJSONObject(AObject: TJSONObject; const AName: string; const AValue: TValue): TJSONObject; overload;


implementation

uses
  System.StrUtils, System.DateUtils, System.TypInfo;

type
  TJSONFieldType = (NestedObject, NestedArray, SimpleValue);

function TValueToJSONObject(AObject: TJSONObject; const AName: string; const AValue: TValue): TJSONObject;
begin
  Result := AObject;

  if (AValue.Kind in [tkString])  then
    Result.AddPair(AName, AValue.AsString)

  else if (AValue.Kind in [tkInteger, tkInt64]) then
    Result.AddPair(AName, TJSONNumber.Create(AValue.AsOrdinal))

  else if (AValue.Kind in [tkFloat]) then
    Result.AddPair(AName, TJSONNumber.Create(AValue.AsExtended))

  else if (AValue.IsType<Boolean>) then
    Result.AddPair(AName, TJSONUtils.BooleanToTJSON(AValue.AsType<Boolean>))

  else if (AValue.IsType<TDateTime>) then
    Result.AddPair(AName, TJSONUtils.DateToJSON(AValue.AsType<TDateTime>))
  else if (AValue.IsType<TDate>) then
    Result.AddPair(AName, TJSONUtils.DateToJSON(AValue.AsType<TDate>))
  else if (AValue.IsType<TTime>) then
    Result.AddPair(AName, TJSONUtils.DateToJSON(AValue.AsType<TTime>))

  else
    Result.AddPair(AName, AValue.ToString);
end;

function TValueToJSONObject(const AName: string; const AValue: TValue): TJSONObject;
begin
  Result := TValueToJSONObject(TJSONObject.Create(), AName, AValue);
end;

function ReadPropertyValue(AInstance: TObject; const APropertyName: string): TValue;
var
  LContext: TRttiContext;
  LType: TRttiType;
  LProperty: TRttiProperty;
begin
  Result := TValue.Empty;
  LType := LContext.GetType(AInstance.ClassType);
  if Assigned(LType) then
  begin
    LProperty := LType.GetProperty(APropertyName);
    if Assigned(LProperty) then
      Result := LProperty.GetValue(AInstance);
  end;
end;

function ExecuteMethod(const AInstance: TValue; AMethod: TRttiMethod;
  const AArguments: array of TValue; const ABeforeExecuteProc: TProc{ = nil};
  const AAfterExecuteProc: TProc<TValue>{ = nil}): Boolean;
var
  LResult: TValue;
begin
  if Assigned(ABeforeExecuteProc) then
    ABeforeExecuteProc();
  LResult := AMethod.Invoke(AInstance, AArguments);
  Result := True;
  if Assigned(AAfterExecuteProc) then
    AAfterExecuteProc(LResult);
end;

function ExecuteMethod(const AInstance: TValue; const AMethodName: string;
  const AArguments: array of TValue; const ABeforeExecuteProc: TProc{ = nil};
  const AAfterExecuteProc: TProc<TValue>{ = nil}): Boolean;
var
  LContext: TRttiContext;
  LType: TRttiType;
  LMethod: TRttiMethod;
begin
  Result := False;

  LType := LContext.GetType(AInstance.TypeInfo);
  if Assigned(LType) then
  begin
    LMethod := LType.GetMethod(AMethodName);
    if Assigned(LMethod) then
      Result := ExecuteMethod(AInstance, LMethod, AArguments, ABeforeExecuteProc, AAfterExecuteProc);
  end;
end;



class function TDataSetUtils.RecordToCSV(const ADataSet: TDataSet; AConfig: TNeonConfiguration): string;
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

class function TDataSetUtils.RecordToJSONObject(const ADataSet: TDataSet; AConfig: TNeonConfiguration): TJSONObject;
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
      TFieldType.ftString:        Result.AddPair(LPairName, LField.AsString);
      TFieldType.ftSmallint:      Result.AddPair(LPairName, TJSONNumber.Create(LField.AsInteger));
      TFieldType.ftInteger:       Result.AddPair(LPairName, TJSONNumber.Create(LField.AsInteger));
      TFieldType.ftWord:          Result.AddPair(LPairName, TJSONNumber.Create(LField.AsInteger));
      TFieldType.ftBoolean:       Result.AddPair(LPairName, TJSONUtils.BooleanToTJSON(LField.AsBoolean));
      TFieldType.ftFloat:         Result.AddPair(LPairName, TJSONNumber.Create(LField.AsFloat));
      TFieldType.ftCurrency:      Result.AddPair(LPairName, TJSONNumber.Create(LField.AsCurrency));
      TFieldType.ftBCD:           Result.AddPair(LPairName, TJSONNumber.Create(LField.AsFloat));
      TFieldType.ftDate:          Result.AddPair(LPairName, TJSONUtils.DateToJSON(LField.AsDateTime, AConfig.UseUTCDate));
      TFieldType.ftTime:          Result.AddPair(LPairName, TJSONUtils.DateToJSON(LField.AsDateTime, AConfig.UseUTCDate));
      TFieldType.ftDateTime:      Result.AddPair(LPairName, TJSONUtils.DateToJSON(LField.AsDateTime, AConfig.UseUTCDate));
//        ftBytes: ;
//        ftVarBytes: ;
      TFieldType.ftAutoInc:       Result.AddPair(LPairName, TJSONNumber.Create(LField.AsInteger));
//        ftBlob: ;
      TFieldType.ftMemo:          Result.AddPair(LPairName, LField.AsString);
//        ftGraphic: ;
//        ftFmtMemo: ;
//        ftParadoxOle: ;
//        ftDBaseOle: ;
//        ftTypedBinary: ;
//        ftCursor: ;
      TFieldType.ftFixedChar:     Result.AddPair(LPairName, LField.AsString);
      TFieldType.ftWideString:    Result.AddPair(LPairName, LField.AsWideString);
      TFieldType.ftLargeint:      Result.AddPair(LPairName, TJSONNumber.Create(LField.AsLargeInt));
//        ftADT: ;
//        ftArray: ;
//        ftReference: ;
//        ftDataSet: ;
//        ftOraBlob: ;
//        ftOraClob: ;
      TFieldType.ftVariant:       Result.AddPair(LPairName, LField.AsString);
//        ftInterface: ;
//        ftIDispatch: ;
      TFieldType.ftGuid:          Result.AddPair(LPairName, LField.AsString);
      TFieldType.ftTimeStamp:     Result.AddPair(LPairName, TJSONUtils.DateToJSON(LField.AsDateTime, AConfig.UseUTCDate));
      TFieldType.ftFMTBcd:        Result.AddPair(LPairName, TJSONNumber.Create(LField.AsFloat));
      TFieldType.ftFixedWideChar: Result.AddPair(LPairName, LField.AsString);
      TFieldType.ftWideMemo:      Result.AddPair(LPairName, LField.AsString);
//        ftOraTimeStamp: ;
//        ftOraInterval: ;
      TFieldType.ftLongWord:      Result.AddPair(LPairName, TJSONNumber.Create(LField.AsInteger));
      TFieldType.ftShortint:      Result.AddPair(LPairName, TJSONNumber.Create(LField.AsInteger));
      TFieldType.ftByte:          Result.AddPair(LPairName, TJSONNumber.Create(LField.AsInteger));
      TFieldType.ftExtended:      Result.AddPair(LPairName, TJSONNumber.Create(LField.AsFloat));
//        ftConnection: ;
//        ftParams: ;
//        ftStream: ;
//        ftTimeStampOffset: ;
//        ftObject: ;
      TFieldType.ftSingle:        Result.AddPair(LPairName, TJSONNumber.Create(LField.AsFloat));
    end;
  end;
end;

class function TDataSetUtils.RecordToXML(const ADataSet: TDataSet; const ARootPath: string; AConfig: TNeonConfiguration): string;
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

class function TDataSetUtils.DataSetToJSONArray(const ADataSet: TDataSet; AConfig: TNeonConfiguration): TJSONArray;
begin
  Result := DataSetToJSONArray(ADataSet, nil, AConfig);
end;

class function TDataSetUtils.DataSetToCSV(const ADataSet: TDataSet; AConfig: TNeonConfiguration): string;
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

class function TDataSetUtils.DataSetToJSONArray(const ADataSet: TDataSet; const AAcceptFunc: TFunc<Boolean>; AConfig: TNeonConfiguration): TJSONArray;
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

class function TDataSetUtils.DataSetToXML(const ADataSet: TDataSet; AConfig: TNeonConfiguration): string;
begin
  Result := DataSetToXML(ADataSet, nil, AConfig);
end;

class function TDataSetUtils.DataSetToXML(const ADataSet: TDataSet; const AAcceptFunc: TFunc<Boolean>; AConfig: TNeonConfiguration): string;
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

class function TDataSetUtils.DatasetMetadataToJSONObject(const ADataSet: TDataSet; AConfig: TNeonConfiguration): TJSONObject;
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

{ TRttiUtils }

class function TRttiUtils.CreateNewValue(AType: TRttiType): TValue;
var
  LAllocatedMem: Pointer;
begin
  case AType.TypeKind of
    tkInteger: Result := TValue.From<Integer>(0);
    tkInt64:   Result := TValue.From<Int64>(0);
    tkChar:    Result := TValue.From<UTF8Char>(#0);
    tkWChar:   Result := TValue.From<Char>(#0);
    tkFloat:   Result := TValue.From<Double>(0);
    tkString:  Result := TValue.From<UTF8String>('');
    tkWString: Result := TValue.From<string>('');
    tkLString: Result := TValue.From<UTF8String>('');
    tkUString: Result := TValue.From<string>('');
    tkClass:   Result := CreateInstance(AType);
    tkRecord:
    begin
      LAllocatedMem := AllocMem(AType.TypeSize);
      try
        TValue.Make(LAllocatedMem, AType.Handle, Result);
      finally
        FreeMem(LAllocatedMem);
      end;
    end;
  else
    raise Exception.CreateFmt('Error creating type', [AType.Name]);
  end;
end;

class function TRttiUtils.CreateInstance(AClass: TClass): TObject;
var
  LType: TRttiType;
begin
  LType := FContext.GetType(AClass);
  Result := CreateInstanceValue(LType).AsObject;
end;

class function TRttiUtils.CreateInstance(AType: TRttiType): TObject;
begin
  Result := CreateInstanceValue(AType).AsObject;
end;

class function TRttiUtils.CreateInstance(const ATypeName: string): TObject;
var
  LType: TRttiType;
begin
  LType := Context.FindType(ATypeName);
  Result := CreateInstanceValue(LType).AsObject;
end;

class function TRttiUtils.CreateInstance(AClass: TClass; const AValue: string): TObject;
var
  LType: TRttiType;
begin
  LType := FContext.GetType(AClass);
  Result := CreateInstance(LType, AValue);
end;

class function TRttiUtils.CreateInstance(AType: TRttiType;
  const AValue: string): TObject;
var
  LMethod: TRttiMethod;
  LMetaClass: TClass;
begin
  Result := nil;
  if Assigned(AType) then
  begin
    for LMethod in AType.GetMethods do
    begin
      if LMethod.HasExtendedInfo and LMethod.IsConstructor then
      begin
        if Length(LMethod.GetParameters) = 1 then
        begin
          if LMethod.GetParameters[0].ParamType.TypeKind in [tkLString, tkUString, tkWString, tkString] then
          begin
            LMetaClass := AType.AsInstance.MetaclassType;
            Exit(LMethod.Invoke(LMetaClass, [AValue]).AsObject);
          end;
        end;
      end;
    end;
  end;
end;

class function TRttiUtils.CreateInstance(const ATypeName, AValue: string): TObject;
var
  LType: TRttiType;
begin
  LType := Context.FindType(ATypeName);
  Result := CreateInstance(LType, AValue);
end;

class function TRttiUtils.CreateInstanceValue(AType: TRttiType): TValue;
var
  LMethod: TRTTIMethod;
  LMetaClass: TClass;
begin
  Result := nil;
  if Assigned(AType) then
    for LMethod in AType.GetMethods do
    begin
      if LMethod.HasExtendedInfo and LMethod.IsConstructor then
      begin
        if Length(LMethod.GetParameters) = 0 then
        begin
          LMetaClass := AType.AsInstance.MetaclassType;
          Exit(LMethod.Invoke(LMetaClass, []));
        end;
      end;
    end;
end;

class function TRttiUtils.ForEachAttribute<T>(AInstance: TObject;
  const ADoSomething: TProc<T>): Integer;
var
  LContext: TRttiContext;
  LType: TRttiType;
begin
  Result := 0;
  LType := LContext.GetType(AInstance.ClassType);
  if Assigned(LType) then
    Result := TRttiUtils.ForEachAttribute<T>(LType, ADoSomething);
end;

class function TRttiUtils.ForEachField(AInstance: TObject;
  const ADoSomething: TFunc<TRttiField, Boolean>): Integer;
var
  LContext: TRttiContext;
  LField: TRttiField;
  LType: TRttiType;
  LBreak: Boolean;
begin
  Result := 0;
  LType := LContext.GetType(AInstance.ClassType);
  for LField in LType.GetFields do
  begin
    LBreak := False;

    if Assigned(ADoSomething) then
    begin
      if not ADoSomething(LField) then
        LBreak := True
      else
        Inc(Result);
    end;

    if LBreak then
      Break;
  end;
end;

class function TRttiUtils.ForEachFieldWithAttribute<T>(AInstance: TObject;
  const ADoSomething: TFunc<TRttiField, T, Boolean>): Integer;
var
  LContext: TRttiContext;
  LType: TRttiType;
begin
  Result := 0;
  LType := LContext.GetType(AInstance.ClassType);
  if Assigned(LType) then
    Result := TRttiUtils.ForEachFieldWithAttribute<T>(LType, ADoSomething);
end;

class function TRttiUtils.IfHasAttribute<T>(AInstance: TObject): Boolean;
begin
  Result := TRttiUtils.IfHasAttribute<T>(AInstance, nil);
end;

class function TRttiUtils.IfHasAttribute<T>(AInstance: TObject;
  const ADoSomething: TProc<T>): Boolean;
var
  LContext: TRttiContext;
  LType: TRttiType;
begin
  Result := False;
  LType := LContext.GetType(AInstance.ClassType);
  if Assigned(LType) then
    Result := TRttiUtils.HasAttribute<T>(LType, ADoSomething);
end;

class function TRttiUtils.ForEachAttribute<T>(ARttiObj: TRttiObject;
    const ADoSomething: TProc<T>): Integer;
var
  LAttribute: TCustomAttribute;
begin
  Result := 0;
  for LAttribute in ARttiObj.GetAttributes do
  begin
    if LAttribute.InheritsFrom(TClass(T)) then
    begin
      if Assigned(ADoSomething) then
        ADoSomething(T(LAttribute));
      Inc(Result);
    end;
  end;
end;

class function TRttiUtils.HasAttribute<T>(ARttiObj: TRttiObject): Boolean;
begin
  Result := HasAttribute<T>(ARttiObj, nil);
end;

class function TRttiUtils.HasAttribute<T>(ARttiObj: TRttiObject; const
    ADoSomething: TProc<T>): Boolean;
var
  LAttribute: TCustomAttribute;
begin
  Result := False;
  for LAttribute in ARttiObj.GetAttributes do
  begin
    if LAttribute.InheritsFrom(TClass(T)) then
    begin
      Result := True;

      if Assigned(ADoSomething) then
        ADoSomething(T(LAttribute));

      Break;
    end;
  end;
end;

class function TRttiUtils.ForEachFieldWithAttribute<T>(ARttiType: TRttiType;
  const ADoSomething: TFunc<TRttiField, T, Boolean>): Integer;
var
  LField: TRttiField;
  LBreak: Boolean;
begin
  for LField in ARttiType.GetFields do
  begin
    LBreak := False;
    if TRttiUtils.HasAttribute<T>(LField,
       procedure (AAttrib: T)
       begin
         if Assigned(ADoSomething) then
         begin
           if not ADoSomething(LField, AAttrib) then
             LBreak := True;
         end;
       end
    )
    then
      Inc(Result);

    if LBreak then
      Break;
  end;
end;

class function TRttiUtils.ForEachMethodWithAttribute<T>(ARttiType: TRttiType;
  const ADoSomething: TFunc<TRttiMethod, T, Boolean>): Integer;
var
  LMethod: TRttiMethod;
  LBreak: Boolean;
begin
  Result := 0;
  for LMethod in ARttiType.GetMethods do
  begin
    LBreak := False;
    if TRttiUtils.HasAttribute<T>(LMethod,
       procedure (AAttrib: T)
       begin
         if Assigned(ADoSomething) then
         begin
           if not ADoSomething(LMethod, AAttrib) then
             LBreak := True;
         end;
       end
    )
    then
      Inc(Result);

    if LBreak then
      Break;
  end;
end;

class function TRttiUtils.ForEachPropertyWithAttribute<T>(ARttiType: TRttiType;
  const ADoSomething: TFunc<TRttiProperty, T, Boolean>): Integer;
var
  LProperty: TRttiProperty;
  LBreak: Boolean;
begin
  Result := 0;
  for LProperty in ARttiType.GetProperties do
  begin
    LBreak := False;
    if TRttiUtils.HasAttribute<T>(LProperty,
       procedure (AAttrib: T)
       begin
         if Assigned(ADoSomething) then
         begin
           if not ADoSomething(LProperty, AAttrib) then
             LBreak := True;
         end;
       end
    )
    then
      Inc(Result);

    if LBreak then
      Break;
  end;
end;

class function TRttiUtils.GetType(AObject: TRttiObject): TRttiType;
begin
  if AObject is TRttiParameter then
    Result := TRttiParameter(AObject).ParamType
  else if AObject is TRttiField then
    Result := TRttiField(AObject).FieldType
  else if AObject is TRttiProperty then
    Result := TRttiProperty(AObject).PropertyType
  else if AObject is TRttiManagedField then
    Result := TRttiManagedField(AObject).FieldType
  else
    raise Exception.Create('Object doesn''t have a type');
end;

class function TRttiUtils.HasAttribute<T>(AClass: TClass): Boolean;
begin
  Result := HasAttribute<T>(Context.GetType(AClass));
end;

class function TRttiUtils.IsDynamicArrayOf(ARttiType: TRttiType;
  const AClass: TClass; const AAllowInherithance: Boolean): Boolean;
begin
  Result := False;
  if ARttiType is TRttiDynamicArrayType then
    Result := TRttiUtils.IsObjectOfType(
      TRttiDynamicArrayType(ARttiType).ElementType, AClass, AAllowInherithance);
end;

class function TRttiUtils.IsDynamicArrayOf<T>(ARttiType: TRttiType;
  const AAllowInherithance: Boolean): Boolean;
begin
  Result := TRttiUtils.IsDynamicArrayOf(ARttiType, TClass(T), AAllowInherithance);
end;

class function TRttiUtils.IsObjectOfType(ARttiType: TRttiType;
  const AClass: TClass; const AAllowInherithance: Boolean): Boolean;
begin
  Result := False;
  if ARttiType is TRttiInstanceType then
  begin
    if AAllowInherithance then
      Result := TRttiInstanceType(ARttiType).MetaclassType.InheritsFrom(AClass)
    else
      Result := TRttiInstanceType(ARttiType).MetaclassType = AClass;
  end;
end;

class function TRttiUtils.IsObjectOfType<T>(ARttiType: TRttiType;
  const AAllowInherithance: Boolean): Boolean;
begin
  Result := TRttiUtils.IsObjectOfType(ARttiType, TClass(T), AAllowInherithance);
end;

class function TRttiUtils.FindAttribute<T>(AType: TRttiObject): T;
var
  LAttribute: TCustomAttribute;
begin
  Result := nil;
  for LAttribute in AType.GetAttributes do
  begin
    if LAttribute.InheritsFrom(TClass(T)) then
    begin
      Result := LAttribute as T;

      Break;
    end;
  end;
end;

class function TRttiUtils.CreateInstance(AClass: TClass;
  const Args: array of TValue): TObject;
var
  LType: TRttiType;
begin
  LType := FContext.GetType(AClass);
  Result := CreateInstance(LType, Args);
end;

class function TRttiUtils.CreateInstance(AType: TRttiType;
  const Args: array of TValue): TObject;
var
  LMethod: TRttiMethod;
  LMetaClass: TClass;
begin
  Result := nil;
  if Assigned(AType) then
  begin
    for LMethod in AType.GetMethods do
    begin
      if LMethod.HasExtendedInfo and LMethod.IsConstructor then
      begin
        if Length(LMethod.GetParameters) = Length(Args) then
        begin
          LMetaClass := AType.AsInstance.MetaclassType;
          Exit(LMethod.Invoke(LMetaClass, Args).AsObject);
        end;
      end;
    end;
  end;
  if not Assigned(Result) then
    raise Exception.CreateFmt('TRttiUtils.CreateInstance: can''t create object [%s]', [AType.Name]);
end;

class function TRttiUtils.CreateInstance(const ATypeName: string;
  const Args: array of TValue): TObject;
var
  LType: TRttiType;
begin
  LType := Context.FindType(ATypeName);
  Result := CreateInstance(LType, Args);
end;

class function TJSONUtils.BooleanToTJSON(AValue: Boolean): TJSONValue;
begin
  if AValue then
    Result := TJSONTrue.Create
  else
    Result := TJSONFalse.Create;
end;

class function TJSONUtils.DateToJSON(ADate: TDateTime; AInputIsUTC: Boolean = True): string;
begin
  Result := '';
  if ADate <> 0 then
    Result := DateToISO8601(ADate, AInputIsUTC);
end;

class procedure TJSONUtils.Decode(const ASource: string; ADest: TStream);
{$IFDEF HAS_NET_ENCODING}
var
  LBase64Stream: TStringStream;
{$ENDIF}
begin
{$IFDEF HAS_NET_ENCODING}
  LBase64Stream := TStringStream.Create(ASource);
  LBase64Stream.Position := soFromBeginning;
  try
    TNetEncoding.Base64.Decode(LBase64Stream, ADest);
  finally
    LBase64Stream.Free;
  end;
{$ELSE}
  TIdDecoderMIME.DecodeStream(ASource, ADest);
{$ENDIF}
end;

class function TJSONUtils.DoubleArrayToJsonArray(const AValues: TArray<Double>): string;
var
  LArray: TJSONArray;
  LIndex: Integer;
begin
  LArray := TJSONArray.Create;
  try
    for LIndex := 0 to High(AValues) do
      LArray.Add(AValues[LIndex]);
    Result := ToJSON(LArray);
  finally
    LArray.Free;
  end;
end;

class function TJSONUtils.Encode(const ASource: TStream): string;
{$IFDEF HAS_NET_ENCODING}
var
  LBase64Stream: TStringStream;
{$ENDIF}
begin
{$IFDEF HAS_NET_ENCODING}
  LBase64Stream := TStringStream.Create;
  try
    TNetEncoding.Base64.Encode(ASource, LBase64Stream);
    Result := LBase64Stream.DataString;
  finally
    LBase64Stream.Free;
  end;
{$ELSE}
  Result := TIdEncoderMIME.EncodeStream(ASource);
{$ENDIF}
end;

class function TJSONUtils.IntegerArrayToJsonArray(const AValues: TArray<Integer>): string;
var
  LArray: TJSONArray;
  LIndex: Integer;
begin
  LArray := TJSONArray.Create;
  try
    for LIndex := 0 to High(AValues) do
      LArray.Add(AValues[LIndex]);
    Result := ToJSON(LArray);
  finally
    LArray.Free;
  end;
end;

class function TJSONUtils.JSONToDate(const ADate: string; AReturnUTC: Boolean = True): TDateTime;
begin
  Result := 0.0;
  if ADate<>'' then
    Result := ISO8601ToDate(ADate, AReturnUTC);
end;

class function TJSONUtils.ToJSON(AJSONValue: TJSONValue): string;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, AJSONValue.ToString.Length * 6);
  SetLength(LBytes, AJSONValue.ToBytes(LBytes, 0));
  Result := TEncoding.Default.GetString(LBytes);
end;

class function TJSONUtils.StringArrayToJsonArray(const AValues: TArray<string>): string;
var
  LArray: TJSONArray;
  LIndex: Integer;
begin
  LArray := TJSONArray.Create;
  try
    for LIndex := 0 to High(AValues) do
      LArray.Add(AValues[LIndex]);
    Result := ToJSON(LArray);
  finally
    LArray.Free;
  end;
end;

class procedure TJSONUtils.JSONCopyFrom(ASource, ADestination: TJSONObject);
var
  LPair: TJSONPair;
begin
  for LPair in ASource do
    ADestination.AddPair(TJSONPair(LPair.Clone));
end;

class function TBase64.Encode(const ASource: TStream): string;
{$IFDEF HAS_NET_ENCODING}
var
  LBase64Stream: TStringStream;
{$ENDIF}
begin
{$IFDEF HAS_NET_ENCODING}
  LBase64Stream := TStringStream.Create;
  try
    TNetEncoding.Base64.Encode(ASource, LBase64Stream);
    Result := LBase64Stream.DataString;
  finally
    LBase64Stream.Free;
  end;
{$ELSE}
  Result := TIdEncoderMIME.EncodeStream(ASource);
{$ENDIF}
end;

class procedure TBase64.Decode(const ASource: string; ADest: TStream);
{$IFDEF HAS_NET_ENCODING}
var
  LBase64Stream: TStringStream;
{$ENDIF}
begin
{$IFDEF HAS_NET_ENCODING}
  LBase64Stream := TStringStream.Create(ASource);
  LBase64Stream.Position := soFromBeginning;
  try
    TNetEncoding.Base64.Decode(LBase64Stream, ADest);
  finally
    LBase64Stream.Free;
  end;
{$ELSE}
  TIdDecoderMIME.DecodeStream(ASource, ADest);
{$ENDIF}
end;


end.
