{******************************************************************************}
{                                                                              }
{  Neon: Serialization Library for Delphi                                      }
{  Copyright (c) 2018 Paolo Rossi                                              }
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

{$I Neon.inc}

interface

uses
  System.Classes,
  System.SysUtils,
  System.Rtti,
  System.JSON,
  System.TypInfo,
  Data.DB,
  System.Generics.Collections,
{$IFDEF HAS_NET_ENCODING}
  System.NetEncoding;
{$ELSE}
  IdCoder,
  IdCoderMIME,
  IdGlobal;
{$ENDIF}

type
  TJSONUtils = class
  public
    class procedure Decode(const ASource: string; ADest: TStream); overload;
    class function Encode(const ASource: TStream): string; overload;

    class function ToJSON(AJSONValue: TJSONValue): string; static;

    class function StringArrayToJsonArray(const AValues: TArray<string>): string; static;
    class function DoubleArrayToJsonArray(const AValues: TArray<Double>): string; static;
    class function IntegerArrayToJsonArray(const AValues: TArray<Integer>): string; static;

    class function HasItems(const AJSON: TJSONValue): Boolean;
    class function IsNotEmpty(const AJSON: TJSONValue): Boolean;
    class function IsNotDefault(const AJSON: TJSONValue): Boolean;

    class procedure JSONCopyFrom(ASource, ADestination: TJSONObject); static;

    class function GetValueBool(AJSON: TJSONValue): Boolean;
    class function GetJSONBool(const AValue: TValue): TJSONValue; overload;
    class function GetJSONBool(AValue: Boolean): TJSONValue; overload;
    class function IsBool(AJSON: TJSONValue): Boolean;

    class function BooleanToTJSON(AValue: Boolean): TJSONValue;

    class function DateToJSON(ADate: TDate): string; static;
    class function DateToJSONValue(ADate: TDate): TJSONValue; static;

    class function TimeToJSON(ATime: TTime): string; static;
    class function TimeToJSONValue(ATime: TTime): TJSONValue; static;

    class function DateTimeToJSON(ADateTime: TDateTime; AInputIsUTC: Boolean = True): string; static;
    class function DateTimeToJSONValue(ADateTime: TDateTime; AInputIsUTC: Boolean = True): TJSONValue; static;

    class function JSONToDate(const ADate: string): TDate; static;
    class function JSONToTime(const ATime: string): TTime; static;
    class function JSONToDateTime(const ADateTime: string; AReturnUTC: Boolean = True): TDateTime; static;

    class procedure Prettify(const AJSONString: string; AWriter: TTextWriter);
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

    /// <summary>
    ///   Free array items (only if these are object)
    /// </summary>
    class procedure FreeArrayItems(const AData: TValue); static;

    /// <summary>
    ///   Create new value data
    /// </summary>
    class function CreateNewValue(AType: TRttiType): TValue; static;

    /// <summary>
    ///   Create instance of class with parameterless constructor
    /// </summary>
    class function CreateInstanceValue(AType: TRttiType): TValue; overload;

    // Create instance of class with parameterless constructor
    class function CreateInstance<T: class, constructor>: TObject;  overload;
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

    class function GetType(AValue: TValue): TRttiType; overload;
    class function GetType(AObject: TRttiObject): TRttiType; overload;

    class function GetSetElementType(ASetType: TRttiType): TRttiType;

    class function ClassDistanceFromRoot(AClass: TClass): Integer; overload; static;
    class function ClassDistanceFromRoot(AInfo: PTypeInfo): Integer; overload; static;

    class property Context: TRttiContext read FContext;
  end;

  TBase64 = class
  public
    class function Encode(const ASource: TBytes): string; overload;
    class function Encode(const ASource: TStream): string; overload;

    class function Decode(const ASource: string): TBytes; overload;
    class procedure Decode(const ASource: string; ADest: TStream); overload;
  end;

  TDataSetUtils = class
  public
    class function RecordToJSONSchema(const ADataSet: TDataSet; AUseUTCDate: Boolean): TJSONObject; static;

    class function FieldToJSONValue(const AField: TField; AUseUTCDate: Boolean): TJSONValue; static;
    class function RecordToJSONObject(const ADataSet: TDataSet; AUseUTCDate: Boolean): TJSONObject; static;
    class function DataSetToJSONArray(const ADataSet: TDataSet; AUseUTCDate: Boolean): TJSONArray; overload; static;
    class function DataSetToJSONArray(const ADataSet: TDataSet; const AAcceptFunc: TFunc<Boolean>; AUseUTCDate: Boolean): TJSONArray; overload; static;

    class procedure JSONToRecord(AJSONObject: TJSONObject; ADataSet: TDataSet; AUseUTCDate: Boolean); static;
    class procedure JSONToDataSet(AJSONValue: TJSONValue; ADataSet: TDataSet; AUseUTCDate: Boolean); static;
    class procedure JSONObjectToDataSet(AJSONValue: TJSONValue; ADataSet: TDataSet; AUseUTCDate: Boolean); static;

    class function BlobFieldToBase64(ABlobField: TBlobField): string;
    class procedure Base64ToBlobField(const ABase64: string; ABlobField: TBlobField);
  end;

implementation

uses
  System.StrUtils,
  System.DateUtils,
  System.Math,
  System.Variants,
  Neon.Core.Types;

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

class procedure TRttiUtils.FreeArrayItems(const AData: TValue);
var
  LIndex: NativeInt;
  LItemValue: TValue;
  LArrayLength: NativeInt;
begin
  // Free Array Items (if objects)
  LArrayLength := AData.GetArrayLength;
  for LIndex := 0 to LArrayLength - 1 do
  begin
    LItemValue := AData.GetArrayElement(LIndex);
    if LItemValue.IsObject then
      if Assigned(LItemValue.AsObject()) then
        LItemValue.AsObject.Free;
  end;
end;

class function TRttiUtils.CreateNewValue(AType: TRttiType): TValue;
var
  LAllocatedMem: Pointer;
begin
  case AType.TypeKind of
    tkEnumeration: Result := TValue.From<Byte>(0);
    tkInteger:     Result := TValue.From<Integer>(0);
    tkInt64:       Result := TValue.From<Int64>(0);
{$IFDEF HAS_UTF8CHAR}
    tkChar:        Result := TValue.From<UTF8Char>(#0);
{$ELSE}
    tkChar,
{$ENDIF}
    tkWChar:       Result := TValue.From<Char>(#0);
    tkFloat:       Result := TValue.From<Double>(0);
    tkString:      Result := TValue.From<UTF8String>('');
    tkWString:     Result := TValue.From<string>('');
    tkLString:     Result := TValue.From<UTF8String>('');
    tkUString:     Result := TValue.From<string>('');
    tkVariant:     Result := TValue.From<Variant>(Null);

    tkClass:       Result := CreateInstance(AType);

    {$IFDEF HAS_MRECORDS}tkMRecord,{$ENDIF}
    tkRecord, tkDynArray:
    begin
      LAllocatedMem := AllocMem(AType.TypeSize);
      try
        TValue.Make(LAllocatedMem, AType.Handle, Result);
      finally
        FreeMem(LAllocatedMem);
      end;
    end;
  else
    raise Exception.CreateFmt('Error creating type [%s]', [AType.Name]);
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

class function TRttiUtils.CreateInstance(AType: TRttiType; const AValue: string): TObject;
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

class function TRttiUtils.IfHasAttribute<T>(AInstance: TObject; const ADoSomething: TProc<T>): Boolean;
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

class function TRttiUtils.HasAttribute<T>(ARttiObj: TRttiObject; const ADoSomething: TProc<T>): Boolean;
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
  Result := 0;
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

class function TRttiUtils.GetType(AValue: TValue): TRttiType;
begin
  Result := FContext.GetType(AValue.TypeInfo);
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

class function TRttiUtils.CreateInstance<T>: TObject;
begin
  Result := CreateInstance(TRttiUtils.Context.GetType(TClass(T)));
end;

class function TJSONUtils.BooleanToTJSON(AValue: Boolean): TJSONValue;
begin
  if AValue then
    Result := TJSONTrue.Create
  else
    Result := TJSONFalse.Create;
end;

class function TJSONUtils.DateToJSON(ADate: TDate): string;
begin
  Result := '';
  if ADate <> 0 then
    Result := FormatDateTime('YYYY-MM-DD', ADate);
end;

class function TJSONUtils.DateToJSONValue(ADate: TDate): TJSONValue;
begin
  Result := TJSONString.Create(TJSONUtils.DateToJSON(ADate));
end;

class function TJSONUtils.TimeToJSON(ATime: TTime): string;
begin
  Result := '';
  if ATime <> 0 then
  Result := FormatDateTime('hh:nn:ss', ATime);
end;

class function TJSONUtils.TimeToJSONValue(ATime: TTime): TJSONValue;
begin
  Result := TJSONString.Create(TJSONUtils.TimeToJSON(ATime));
end;

class function TJSONUtils.DateTimeToJSON(ADateTime: TDateTime; AInputIsUTC: Boolean = True): string;
begin
  Result := '';
  if ADateTime <> 0 then
    Result := DateToISO8601(ADateTime, AInputIsUTC);
end;

class function TJSONUtils.DateTimeToJSONValue(ADateTime: TDateTime; AInputIsUTC: Boolean): TJSONValue;
begin
  Result := TJSONString.Create(TJSONUtils.DateTimeToJSON(ADateTime, AInputIsUTC));
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

class function TJSONUtils.GetJSONBool(const AValue: TValue): TJSONValue;
begin
{$IFDEF HAS_JSON_BOOL}
  Result := TJSONBool.Create(AValue.AsBoolean);
{$ELSE}
  if AValue.AsBoolean then
    Result := TJSONTrue.Create
  else
    Result := TJsonFalse.Create;
{$ENDIF}
end;

class function TJSONUtils.GetJSONBool(AValue: Boolean): TJSONValue;
begin
{$IFDEF HAS_JSON_BOOL}
  Result := TJSONBool.Create(AValue);
{$ELSE}
  if AValue then
    Result := TJSONTrue.Create
  else
    Result := TJsonFalse.Create;
{$ENDIF}
end;

class function TJSONUtils.GetValueBool(AJSON: TJSONValue): Boolean;
begin
{$IFDEF HAS_JSON_BOOL}
  if AJSON is TJSONBool then
    Result := (AJSON as TJSONBool).AsBoolean
  else
    raise ENeonException.Create('The JSON value is not boolean');
{$ELSE}
  if AJSON is TJSONTrue then
    Result := True
  else if AJSON is TJSONFalse then
    Result := False
  else
    raise ENeonException.Create('The JSON value is not boolean');
{$ENDIF}
end;

class function TJSONUtils.IsBool(AJSON: TJSONValue): Boolean;
begin
  Result := False;
{$IFDEF HAS_JSON_BOOL}
  if AJSON is TJSONBool then
    Result := True;
{$ELSE}
  if (AJSON is TJSONTrue) or (AJSON is TJSONFalse) then
    Result := True;
{$ENDIF}
end;

class function TJSONUtils.HasItems(const AJSON: TJSONValue): Boolean;
begin
  Result := True;

  if AJSON = nil then
    Exit(False);

  if AJSON is TJSONNull then
    Exit(False);

  if AJSON is TJSONObject then
    Exit((AJSON as TJSONObject).Count > 0);

  if AJSON is TJSONArray then
    Exit((AJSON as TJSONArray).Count > 0);
end;

class function TJSONUtils.IsNotEmpty(const AJSON: TJSONValue): Boolean;
begin
  Result := True;

  if AJSON = nil then
    Exit(False);

  if AJSON is TJSONNull then
    Exit(False);

  if AJSON is TJSONString then
    Exit(not (AJSON as TJSONString).Value.IsEmpty);

  if AJSON is TJSONObject then
    Exit((AJSON as TJSONObject).Count > 0);

  if AJSON is TJSONArray then
    Exit((AJSON as TJSONArray).Count > 0);
end;

class function TJSONUtils.IsNotDefault(const AJSON: TJSONValue): Boolean;
begin
  Result := True;

  if AJSON = nil then
    Exit(False);

  if AJSON is TJSONNull then
    Exit(False);

  if AJSON is TJSONString then
    Exit(not (AJSON as TJSONString).Value.IsEmpty);

  if AJSON is TJSONNumber then
  begin
    if (AJSON as TJSONNumber).Value.Contains('.') then
      Exit(not IsZero((AJSON as TJSONNumber).AsDouble));

    Exit(not (AJSON as TJSONNumber).AsInt = 0);
  end;

  if AJSON is TJSONObject then
    Exit((AJSON as TJSONObject).Count > 0);

  if AJSON is TJSONArray then
    Exit((AJSON as TJSONArray).Count > 0);
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

class function TJSONUtils.JSONToDate(const ADate: string): TDate;
begin
  Result := 0.0;
  if Length(ADate) = 10 then  {YYYY-MM-DD} // Possible RegEx => ^(?:\d{4}-(?:0[1-9]|1[0-2])-(?:0[1-9]|[12]\d|3[01]))$
    Result := EncodeDate(StrToInt(Copy(ADate, 1, 4)), StrToInt(Copy(ADate, 6, 2)), StrToInt(Copy(ADate, 9, 2)));
end;

class function TJSONUtils.JSONToTime(const ATime: string): TTime;
begin
  Result := 0.0;
  if Length(ATime) = 8 then {hh:nn:ss} // Possible RegEx => ^(?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d$
    Result := EncodeTime(StrToInt(Copy(ATime, 1, 2)), StrToInt(Copy(ATime, 4, 2)), StrToInt(Copy(ATime, 7, 2)), 0);
end;

class procedure TJSONUtils.Prettify(const AJSONString: string; AWriter: TTextWriter);
var
  LChar, LPrev: Char;
  LOffset: Integer;
  LIndex: Integer;
  LOutsideString: Boolean;

  function Spaces(AOffset: Integer): string; inline;
  begin
    Result := StringOfChar(#32, AOffset * 2);
  end;

begin
  LOffset := 0;
  LOutsideString := True;

  LPrev := #0;
  for LIndex := 0 to Length(AJSONString) - 1 do
  begin
    LChar := AJSONString.Chars[LIndex];

    if (LChar = '"') and not (LPrev = '\') then
      LOutsideString := not LOutsideString;

    if LOutsideString and (LChar = '{') then
    begin
      Inc(LOffset);
      AWriter.Write(LChar);
      AWriter.Write(sLineBreak);
      AWriter.Write(Spaces(LOffset));
    end
    else if LOutsideString and (LChar = '}') then
    begin
      Dec(LOffset);
      AWriter.Write(sLineBreak);
      AWriter.Write(Spaces(LOffset));
      AWriter.Write(LChar);
    end
    else if LOutsideString and (LChar = ',') then
    begin
      AWriter.Write(LChar);
      AWriter.Write(sLineBreak);
      AWriter.Write(Spaces(LOffset));
    end
    else if LOutsideString and (LChar = '[') then
    begin
      Inc(LOffset);
      AWriter.Write(LChar);
      AWriter.Write(sLineBreak);
      AWriter.Write(Spaces(LOffset));
    end
    else if LOutsideString and (LChar = ']') then
    begin
      Dec(LOffset);
      AWriter.Write(sLineBreak);
      AWriter.Write(Spaces(LOffset));
      AWriter.Write(LChar);
    end
    else if LOutsideString and (LChar = ':') then
    begin
      AWriter.Write(LChar);
      AWriter.Write(' ');
    end
    else
      AWriter.Write(LChar);

    LPrev := LChar;
  end;

end;

class function TJSONUtils.JSONToDateTime(const ADateTime: string; AReturnUTC: Boolean = True): TDateTime;
begin
  Result := 0.0;
  if ADateTime <> '' then
    Result := ISO8601ToDate(ADateTime, AReturnUTC);
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
  LEncoder: TBase64Encoding;
{$ENDIF}
begin
{$IFDEF HAS_NET_ENCODING}
  LBase64Stream := TStringStream.Create;
  try
    // FIX: if CharsPerLine is not initialized, it adds \r\n line feeds to
    //      each line that are not part of Base64
    LEncoder := TBase64Encoding.Create(0);
    try
      LEncoder.Encode(ASource, LBase64Stream);
      Result := LBase64Stream.DataString;
    finally
      LEncoder.Free;
    end;
  finally
    LBase64Stream.Free;
  end;
{$ELSE}
  Result := TIdEncoderMIME.EncodeStream(ASource);
{$ENDIF}
end;

class function TBase64.Decode(const ASource: string): TBytes;
{$IFNDEF HAS_NET_ENCODING}
var
  LBytes: TIdBytes;
  LIndex: Integer;
{$ENDIF}
begin
{$IFDEF HAS_NET_ENCODING}
  Result := TNetEncoding.Base64.DecodeStringToBytes(ASource);
{$ELSE}
  LBytes := TIdDecoderMIME.DecodeBytes(ASource);

  SetLength(Result, Length(LBytes));
  for LIndex := 0 to Length(LBytes) - 1 do
    Result[LIndex] := LBytes[LIndex];
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

class function TDataSetUtils.RecordToJSONObject(const ADataSet: TDataSet; AUseUTCDate: Boolean): TJSONObject;
var
  LField: TField;
  LPairName: string;
  LJSONValue: TJSONValue;
begin
  Result := TJSONObject.Create;

  for LField in ADataSet.Fields do
  begin
    LPairName := LField.FieldName;

    if ContainsStr(LPairName, '.') then
      Continue;

    LJSONValue := FieldToJSONValue(LField, AUseUTCDate);
    if Assigned(LJSONValue) then
      Result.AddPair(LPairName, LJSONValue);
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
        LJSONField.AddPair('type', 'string').AddPair('format', 'time');
      end;

      TFieldType.ftDateTime:
      begin
        LJSONField.AddPair('type', 'string').AddPair('format', 'date-time');
      end;

//      TFieldType.ftBytes: ;
//      TFieldType.ftVarBytes: ;

      TFieldType.ftAutoInc:
      begin
        LJSONField.AddPair('type', 'integer').AddPair('format', 'int32');
      end;

//      TFieldType.ftBlob: ;

      TFieldType.ftMemo,
      TFieldType.ftWideMemo:
      begin
        LJSONField.AddPair('type', 'string');
      end;

//      TFieldType.ftGraphic: ;
//      TFieldType.ftFmtMemo: ;
//      TFieldType.ftParadoxOle: ;
//      TFieldType.ftDBaseOle: ;
//      TFieldType.ftTypedBinary: ;
//      TFieldType.ftCursor: ;
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

//      TFieldType.ftADT: ;
//      TFieldType.ftArray: ;
//      TFieldType.ftReference: ;
//      TFieldType.ftDataSet: ;
//      TFieldType.ftOraBlob: ;
//      TFieldType.ftOraClob: ;

      TFieldType.ftVariant:
      begin
        LJSONField.AddPair('type', 'string');
      end;

//      TFieldType.ftInterface: ;
//      TFieldType.ftIDispatch: ;

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


//      TFieldType.ftOraTimeStamp: ;
//      TFieldType.ftOraInterval: ;
//      TFieldType.ftConnection: ;
//      TFieldType.ftParams: ;
//      TFieldType.ftStream: ;
//      TFieldType.ftTimeStampOffset: ;
//      TFieldType.ftObject: ;
    end;
  end;
end;

class function TDataSetUtils.DataSetToJSONArray(const ADataSet: TDataSet; AUseUTCDate: Boolean): TJSONArray;
begin
  Result := DataSetToJSONArray(ADataSet, nil, AUseUTCDate);
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

class function TDataSetUtils.FieldToJSONValue(const AField: TField; AUseUTCDate: Boolean): TJSONValue;
begin
  Result := nil;

  if AField.IsNull then
    Exit(TJSONNull.Create);

  case AField.DataType of
    TFieldType.ftString:          Result := TJSONString.Create(AField.AsString);
    TFieldType.ftSmallint:        Result := TJSONNumber.Create(AField.AsInteger);
    TFieldType.ftInteger:         Result := TJSONNumber.Create(AField.AsInteger);
    TFieldType.ftWord:            Result := TJSONNumber.Create(AField.AsInteger);
    TFieldType.ftBoolean:         Result := TJSONUtils.BooleanToTJSON(AField.AsBoolean);
    TFieldType.ftFloat:           Result := TJSONNumber.Create(AField.AsFloat);
    TFieldType.ftCurrency:        Result := TJSONNumber.Create(AField.AsCurrency);
    TFieldType.ftBCD:             Result := TJSONNumber.Create(AField.AsFloat);
    TFieldType.ftDate:            Result := TJSONUtils.DateToJSONValue(AField.AsDateTime);
    TFieldType.ftTime:            Result := TJSONUtils.TimeToJSONValue(AField.AsDateTime);
    TFieldType.ftDateTime:        Result := TJSONUtils.DateTimeToJSONValue(AField.AsDateTime, AUseUTCDate);
    TFieldType.ftBytes:           Result := TJSONString.Create(TBase64.Encode(AField.AsBytes));
    TFieldType.ftVarBytes:        Result := TJSONString.Create(TBase64.Encode(AField.AsBytes));
    TFieldType.ftAutoInc:         Result := TJSONNumber.Create(AField.AsInteger);
    TFieldType.ftBlob:            Result := TJSONString.Create(BlobFieldToBase64(AField as TBlobField));
    TFieldType.ftMemo:            Result := TJSONString.Create(AField.AsString);
    TFieldType.ftGraphic:         Result := TJSONString.Create(TBase64.Encode(AField.AsBytes));
//      TFieldType.ftFmtMemo: ;
//      TFieldType.ftParadoxOle: ;
//      TFieldType.ftDBaseOle: ;
    TFieldType.ftTypedBinary:     Result := TJSONString.Create(TBase64.Encode(AField.AsBytes));
//      TFieldType.ftCursor: ;
    TFieldType.ftFixedChar:       Result := TJSONString.Create(AField.AsString);
    TFieldType.ftWideString:      Result := TJSONString.Create(AField.AsWideString);
    TFieldType.ftLargeint:        Result := TJSONNumber.Create(AField.AsLargeInt);
    TFieldType.ftADT:             Result := TJSONString.Create(TBase64.Encode(AField.AsBytes));
    TFieldType.ftArray:           Result := TJSONString.Create(TBase64.Encode(AField.AsBytes));
//      TFieldType.ftReference: ;
    TFieldType.ftDataSet:         Result := DataSetToJSONArray((AField as TDataSetField).NestedDataSet, AUseUTCDate);
    TFieldType.ftOraBlob:         Result := TJSONString.Create(TBase64.Encode(AField.AsBytes));
    TFieldType.ftOraClob:         Result := TJSONString.Create(TBase64.Encode(AField.AsBytes));
    TFieldType.ftVariant:         Result := TJSONString.Create(AField.AsString);
//      TFieldType.ftInterface: ;
//      TFieldType.ftIDispatch: ;
    TFieldType.ftGuid:            Result := TJSONString.Create(AField.AsString);
    TFieldType.ftTimeStamp:       Result := TJSONUtils.DateTimeToJSONValue(AField.AsDateTime, AUseUTCDate);
    TFieldType.ftFMTBcd:          Result := TJSONNumber.Create(AField.AsFloat);
    TFieldType.ftFixedWideChar:   Result := TJSONString.Create(AField.AsString);
    TFieldType.ftWideMemo:        Result := TJSONString.Create(AField.AsString);
    TFieldType.ftOraTimeStamp:    Result := TJSONUtils.DateTimeToJSONValue(AField.AsDateTime, AUseUTCDate);
    TFieldType.ftOraInterval:     Result := TJSONString.Create(AField.AsString);
    TFieldType.ftLongWord:        Result := TJSONNumber.Create(AField.AsInteger);
    TFieldType.ftShortint:        Result := TJSONNumber.Create(AField.AsInteger);
    TFieldType.ftByte:            Result := TJSONNumber.Create(AField.AsInteger);
    TFieldType.ftExtended:        Result := TJSONNumber.Create(AField.AsFloat);
//      TFieldType.ftConnection: ;
//      TFieldType.ftParams: ;
//      TFieldType.ftStream: ;
    TFieldType.ftTimeStampOffset: Result := TJSONString.Create(AField.AsString);
//      TFieldType.ftObject: ;
    TFieldType.ftSingle:          Result := TJSONNumber.Create(AField.AsFloat);
  end;
end;

class procedure TDataSetUtils.JSONObjectToDataSet(AJSONValue: TJSONValue; ADataSet: TDataSet; AUseUTCDate: Boolean);
var
  LJSONArray: TJSONArray;
begin
  if AJSONValue is TJSONObject then
  begin
    LJSONArray := TJSONArray.Create;
    try
      LJSONArray.AddElement(AJSONValue.Clone as TJSONValue);
      JSONToDataSet(LJSONArray, ADataSet, AUseUTCDate);
    finally
      LJSONArray.Free;
    end;
  end;
end;

class procedure TDataSetUtils.JSONToDataSet(AJSONValue: TJSONValue; ADataSet: TDataSet; AUseUTCDate: Boolean);
var
  LJSONArray: TJSONArray;
  LJSONItem: TJSONObject;
  LIndex: Integer;
begin
  if not (AJSONValue is TJSONArray) then
    raise ENeonException.Create('JSONToDataSet: The JSON must be an array');

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

    if LJSONField is TJSONNull then
    begin
      LField.Clear;
      Continue;
    end;

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
      TFieldType.ftDate:            LField.AsDateTime := TJSONUtils.JSONToDate(LJSONField.Value);
      TFieldType.ftTime:            LField.AsDateTime := TJSONUtils.JSONToTime(LJSONField.Value);
      TFieldType.ftDateTime:        LField.AsDateTime := TJSONUtils.JSONToDateTime(LJSONField.Value, AUseUTCDate);
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
      TFieldType.ftTimeStamp:       LField.AsDateTime := TJSONUtils.JSONToDateTime(LJSONField.Value, AUseUTCDate);
      TFieldType.ftFMTBcd:          ADataSet.Fields[LIndex].AsBytes := TBase64.Decode(LJSONField.Value);
      TFieldType.ftFixedWideChar:   LField.AsString := LJSONField.Value;
      TFieldType.ftWideMemo:        LField.AsString := LJSONField.Value;
      TFieldType.ftOraTimeStamp:    LField.AsDateTime := TJSONUtils.JSONToDateTime(LJSONField.Value, AUseUTCDate);
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

end.
