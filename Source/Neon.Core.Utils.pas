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
  System.Classes, System.SysUtils, Data.DB, System.Rtti, System.JSON, System.TypInfo,
  {$IFDEF HAS_NET_ENCODING}
  System.NetEncoding,
  {$ELSE}
  IdCoder, IdCoderMIME, IdGlobal,
  {$ENDIF}
  System.Generics.Collections;

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

    class function HasAttribute<T: TCustomAttribute>(AClass: TClass): Boolean; overload; static;

    class function HasAttribute<T: TCustomAttribute>(ARttiObj: TRttiObject): Boolean; overload; static;

    class function HasAttribute<T: TCustomAttribute>(ARttiObj: TRttiObject; const ADoSomething: TProc<T>): Boolean; overload; static;

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
    class function GetSetElementType(ASetType: TRttiType): TRttiType;

    class function ClassDistanceFromRoot(AClass: TClass): Integer; overload; static;
    class function ClassDistanceFromRoot(AInfo: PTypeInfo): Integer; overload; static;

    class property Context: TRttiContext read FContext;
  end;

  TBase64 = class
    class function Encode(const ASource: TBytes): string; overload;
    class function Encode(const ASource: TStream): string; overload;

    class function Decode(const ASource: string): TBytes; overload;
    class procedure Decode(const ASource: string; ADest: TStream); overload;
  end;

  TDataSetUtils = class
  private
    class function RecordToXML(const ADataSet: TDataSet; const ARootPath: string; AUseUTCDate: Boolean): string; static;
    class function RecordToCSV(const ADataSet: TDataSet; AUseUTCDate: Boolean): string; static;
  public
    class function RecordToJSONSchema(const ADataSet: TDataSet; AUseUTCDate: Boolean): TJSONObject; static;

    class function RecordToJSONObject(const ADataSet: TDataSet; AUseUTCDate: Boolean): TJSONObject; static;
    class function DataSetToJSONArray(const ADataSet: TDataSet; AUseUTCDate: Boolean): TJSONArray; overload; static;
    class function DataSetToJSONArray(const ADataSet: TDataSet; const AAcceptFunc: TFunc<Boolean>; AUseUTCDate: Boolean): TJSONArray; overload; static;

    class function DataSetToXML(const ADataSet: TDataSet; AUseUTCDate: Boolean): string; overload; static;
    class function DataSetToXML(const ADataSet: TDataSet; const AAcceptFunc: TFunc<Boolean>; AUseUTCDate: Boolean): string; overload; static;

    class procedure JSONToRecord(AJSONObject: TJSONObject; ADataSet: TDataSet; AUseUTCDate: Boolean); static;
    class procedure JSONToDataSet(AJSONValue: TJSONValue; ADataSet: TDataSet; AUseUTCDate: Boolean); static;

    class function DataSetToCSV(const ADataSet: TDataSet; AUseUTCDate: Boolean): string; static;

    class function DatasetMetadataToJSONObject(const ADataSet: TDataSet; AUseUTCDate: Boolean): TJSONObject; static;

    class function BlobFieldToBase64(ABlobField: TBlobField): string;
    class procedure Base64ToBlobField(const ABase64: string; ABlobField: TBlobField);
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
  System.StrUtils, System.DateUtils;

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

class function TRttiUtils.ClassDistanceFromRoot(AClass: TClass): Integer;
var
  LClass: TClass;
begin
  Result := 0;
  LClass := AClass;
  while LClass <> TObject do
  begin
    LClass := LClass.ClassParent;
    Inc(Result);
  end;
end;

class function TRttiUtils.ClassDistanceFromRoot(AInfo: PTypeInfo): Integer;
var
  LType: TRttiType;
begin
  Result := -1;

  LType := TRttiUtils.Context.GetType(AInfo);
  if Assigned(LType) and (LType.TypeKind = tkClass) then
    Result := TRttiUtils.ClassDistanceFromRoot(LType.AsInstance.MetaclassType);
end;

{ TRttiUtils }

class function TRttiUtils.CreateNewValue(AType: TRttiType): TValue;
var
  LAllocatedMem: Pointer;
begin
  case AType.TypeKind of
    tkEnumeration: Result := TValue.From<Byte>(0);
    tkInteger:     Result := TValue.From<Integer>(0);
    tkInt64:       Result := TValue.From<Int64>(0);
    tkChar:        Result := TValue.From<UTF8Char>(#0);
    tkWChar:       Result := TValue.From<Char>(#0);
    tkFloat:       Result := TValue.From<Double>(0);
    tkString:      Result := TValue.From<UTF8String>('');
    tkWString:     Result := TValue.From<string>('');
    tkLString:     Result := TValue.From<UTF8String>('');
    tkUString:     Result := TValue.From<string>('');
    tkClass:       Result := CreateInstance(AType);
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

class function TRttiUtils.GetSetElementType(ASetType: TRttiType): TRttiType;
var
  LEnumInfo: PPTypeInfo;
begin
  LEnumInfo := GetTypeData(ASetType.Handle)^.CompType;
  Result := TRttiUtils.Context.GetType(LEnumInfo^);
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

class function TRttiUtils.CreateInstance(AType: TRttiType; const Args: array of TValue): TObject;
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

class function TRttiUtils.CreateInstance(const ATypeName: string; const Args: array of TValue): TObject;
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

class function TBase64.Encode(const ASource: TBytes): string;
begin
{$IFDEF HAS_NET_ENCODING}
  Result := TNetEncoding.Base64.EncodeBytesToString(ASource);
{$ELSE}
  Result := TIdEncoderMIME.EncodeBytes(TIdBytes(ASource));
{$ENDIF}
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

class function TBase64.Decode(const ASource: string): TBytes;
begin
{$IFDEF HAS_NET_ENCODING}
  Result := TNetEncoding.Base64.DecodeStringToBytes(ASource);
{$ELSE}
  Result := TIdDecoderMIME.DecodeBytes(ASource) as TBytes;
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

class function TDataSetUtils.RecordToCSV(const ADataSet: TDataSet; AUseUTCDate: Boolean): string;
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

class function TDataSetUtils.RecordToJSONObject(const ADataSet: TDataSet; AUseUTCDate: Boolean): TJSONObject;
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
      TFieldType.ftDate:            Result.AddPair(LPairName, TJSONUtils.DateToJSON(LField.AsDateTime, AUseUTCDate));
      TFieldType.ftTime:            Result.AddPair(LPairName, TJSONUtils.DateToJSON(LField.AsDateTime, AUseUTCDate));
      TFieldType.ftDateTime:        Result.AddPair(LPairName, TJSONUtils.DateToJSON(LField.AsDateTime, AUseUTCDate));
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
      TFieldType.ftDataSet:         Result.AddPair(LPairName, DataSetToJSONArray((LField as TDataSetField).NestedDataSet, AUseUTCDate));
      TFieldType.ftOraBlob:         Result.AddPair(LPairName, TBase64.Encode(LField.AsBytes));
      TFieldType.ftOraClob:         Result.AddPair(LPairName, TBase64.Encode(LField.AsBytes));
      TFieldType.ftVariant:         Result.AddPair(LPairName, LField.AsString);
//      TFieldType.ftInterface: ;
//      TFieldType.ftIDispatch: ;
      TFieldType.ftGuid:            Result.AddPair(LPairName, LField.AsString);
      TFieldType.ftTimeStamp:       Result.AddPair(LPairName, TJSONUtils.DateToJSON(LField.AsDateTime, AUseUTCDate));
      TFieldType.ftFMTBcd:          Result.AddPair(LPairName, TJSONNumber.Create(LField.AsFloat));
      TFieldType.ftFixedWideChar:   Result.AddPair(LPairName, LField.AsString);
      TFieldType.ftWideMemo:        Result.AddPair(LPairName, LField.AsString);
      TFieldType.ftOraTimeStamp:    Result.AddPair(LPairName, TJSONUtils.DateToJSON(LField.AsDateTime, AUseUTCDate));
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

class function TDataSetUtils.RecordToJSONSchema(const ADataSet: TDataSet; AUseUTCDate: Boolean): TJSONObject;
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

class function TDataSetUtils.RecordToXML(const ADataSet: TDataSet; const ARootPath: string; AUseUTCDate: Boolean): string;
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

class function TDataSetUtils.DataSetToJSONArray(const ADataSet: TDataSet; AUseUTCDate: Boolean): TJSONArray;
begin
  Result := DataSetToJSONArray(ADataSet, nil, AUseUTCDate);
end;

class function TDataSetUtils.DataSetToCSV(const ADataSet: TDataSet; AUseUTCDate: Boolean): string;
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
        Result := Result + TDataSetUtils.RecordToCSV(ADataSet, AUseUTCDate) + sLineBreak;
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

class function TDataSetUtils.DataSetToJSONArray(const ADataSet: TDataSet; const AAcceptFunc: TFunc<Boolean>; AUseUTCDate: Boolean): TJSONArray;
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
          Result.AddElement(RecordToJSONObject(ADataSet, AUseUTCDate));
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

class function TDataSetUtils.DataSetToXML(const ADataSet: TDataSet; AUseUTCDate: Boolean): string;
begin
  Result := DataSetToXML(ADataSet, nil, AUseUTCDate);
end;

class function TDataSetUtils.DataSetToXML(const ADataSet: TDataSet; const AAcceptFunc: TFunc<Boolean>; AUseUTCDate: Boolean): string;
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
          Result := Result + '<row>' + RecordToXML(ADataSet, '', AUseUTCDate) + '</row>';
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

class procedure TDataSetUtils.JSONToDataSet(AJSONValue: TJSONValue; ADataSet: TDataSet; AUseUTCDate: Boolean);
var
  LJSONArray: TJSONArray;
  LJSONItem: TJSONObject;
  LIndex: Integer;
begin
  LJSONArray := AJSONValue as TJSONArray;

  for LIndex := 0 to LJSONArray.Count - 1 do
  begin
    LJSONItem := LJSONArray.Items[LIndex] as TJSONObject;

    JSONToRecord(LJSONItem, ADataSet, AUseUTCDate);
  end;
end;

class procedure TDataSetUtils.JSONToRecord(AJSONObject: TJSONObject; ADataSet: TDataSet; AUseUTCDate: Boolean);
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
      TFieldType.ftDate:            LField.AsDateTime := TJSONUtils.JSONToDate(LJSONField.Value, AUseUTCDate);
      TFieldType.ftTime:            LField.AsDateTime := TJSONUtils.JSONToDate(LJSONField.Value, AUseUTCDate);
      TFieldType.ftDateTime:        LField.AsDateTime := TJSONUtils.JSONToDate(LJSONField.Value, AUseUTCDate);
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
      TFieldType.ftDataSet:         JSONToDataSet(LJSONField, (ADataSet.Fields[LIndex] as TDataSetField).NestedDataSet, AUseUTCDate);
      TFieldType.ftOraBlob:         TDataSetUtils.Base64ToBlobField(LJSONField.Value, ADataSet.Fields[LIndex] as TBlobField);
      TFieldType.ftOraClob:         TDataSetUtils.Base64ToBlobField(LJSONField.Value, ADataSet.Fields[LIndex] as TBlobField);
      TFieldType.ftVariant:         TDataSetUtils.Base64ToBlobField(LJSONField.Value, ADataSet.Fields[LIndex] as TBlobField);
      //TFieldType.ftInterface: ;
      //TFieldType.ftIDispatch: ;
      TFieldType.ftGuid:            LField.AsString := LJSONField.Value;
      TFieldType.ftTimeStamp:       LField.AsDateTime := TJSONUtils.JSONToDate(LJSONField.Value, AUseUTCDate);
      TFieldType.ftFMTBcd:          ADataSet.Fields[LIndex].AsBytes := TBase64.Decode(LJSONField.Value);
      TFieldType.ftFixedWideChar:   LField.AsString := LJSONField.Value;
      TFieldType.ftWideMemo:        LField.AsString := LJSONField.Value;
      TFieldType.ftOraTimeStamp:    LField.AsDateTime := TJSONUtils.JSONToDate(LJSONField.Value, AUseUTCDate);
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

class function TDataSetUtils.DatasetMetadataToJSONObject(const ADataSet: TDataSet; AUseUTCDate: Boolean): TJSONObject;
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
