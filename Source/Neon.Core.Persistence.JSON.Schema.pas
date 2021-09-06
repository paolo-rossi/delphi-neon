{******************************************************************************}
{                                                                              }
{  Neon: Serialization Library for Delphi                                      }
{  Copyright (c) 2018-2021 Paolo Rossi                                         }
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
unit Neon.Core.Persistence.JSON.Schema;

interface

{$I Neon.inc}

uses
  System.SysUtils, System.Classes, System.Rtti, System.SyncObjs,
  System.TypInfo, System.Generics.Collections, System.JSON, Data.DB,

  Neon.Core.Types,
  Neon.Core.Attributes,
  Neon.Core.Persistence,
  Neon.Core.TypeInfo,
  Neon.Core.Utils;

type
  /// <summary>
  ///   JSON Schema (OpenAPI version) generator
  /// </summary>
  TNeonSchemaGenerator = class(TNeonBase)
  private
    /// <summary>
    ///   Writer for members of objects and records
    /// </summary>
    procedure WriteMembers(AType: TRttiType; AResult: TJSONObject);
  private
    /// <summary>
    ///   Writer for string types
    /// </summary>
    function WriteString(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;

    /// <summary>
    ///   Writer for Boolean types
    /// </summary>
    function WriteBoolean(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;

    /// <summary>
    ///   Writer for enums types <br />
    /// </summary>
    function WriteEnum(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;

    /// <summary>
    ///   Writer for Integer types <br />
    /// </summary>
    function WriteInteger(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;

    /// <summary>
    ///   Writer for Integer types <br />
    /// </summary>
    function WriteInt64(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;

    /// <summary>
    ///   Writer for float types
    /// </summary>
    function WriteFloat(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
    function WriteDouble(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;

    /// <summary>
    ///   Writer for TDate* types
    /// </summary>
    function WriteDate(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
    function WriteDateTime(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;

    /// <summary>
    ///   Writer for Variant types
    /// </summary>
    /// <remarks>
    ///   The variant will be written as string
    /// </remarks>
    function WriteVariant(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;

    /// <summary>
    ///   Writer for static and dynamic arrays
    /// </summary>
    function WriteArray(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
    function WriteDynArray(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;

    /// <summary>
    ///   Writer for the set type
    /// </summary>
    /// <remarks>
    ///   The output is a string with the values comma separated and enclosed by square brackets
    /// </remarks>
    /// <returns>[First,Second,Third]</returns>
    function WriteSet(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;

    /// <summary>
    ///   Writer for a record type
    /// </summary>
    /// <remarks>
    ///   For records the engine serialize the fields by default
    /// </remarks>
    function WriteRecord(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;

    /// <summary>
    ///   Writer for a standard TObject (descendants)  type (no list, stream or streamable)
    /// </summary>
    function WriteObject(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;

    /// <summary>
    ///   Writer for an Interface type
    /// </summary>
    /// <remarks>
    ///   The object that implements the interface is serialized
    /// </remarks>
    function WriteInterface(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;

    /// <summary>
    ///   Writer for TStream (descendants) objects
    /// </summary>
    function WriteStream(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;

    /// <summary>
    ///   Writer for TDataSet (descendants) objects
    /// </summary>
    function WriteDataSet(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;

    /// <summary>
    ///   Writer for "Enumerable" objects (Lists, Generic Lists, TStrings, etc...)
    /// </summary>
    /// <remarks>
    ///   Objects must have GetEnumerator, Clear, Add methods
    /// </remarks>
    function WriteEnumerable(AType: TRttiType; ANeonObject: TNeonRttiObject; AList: INeonTypeInfoList): TJSONObject;
    function IsEnumerable(AType: TRttiType; out AList: INeonTypeInfoList): Boolean;

    /// <summary>
    ///   Writer for "Dictionary" objects (TDictionary, TObjectDictionary)
    /// </summary>
    /// <remarks>
    ///   Objects must have Keys, Values, GetEnumerator, Clear, Add methods
    /// </remarks>
    function WriteEnumerableMap(AType: TRttiType; ANeonObject: TNeonRttiObject; AMap: INeonTypeInfoMap): TJSONObject;
    function IsEnumerableMap(AType: TRttiType; out AMap: INeonTypeInfoMap): Boolean;

    /// <summary>
    ///   Writer for "Streamable" objects
    /// </summary>
    /// <remarks>
    ///   Objects must have LoadFromStream and SaveToStream methods
    /// </remarks>
    function WriteStreamable(AType: TRttiType; ANeonObject: TNeonRttiObject; AStream: INeonTypeInfoStream): TJSONObject;
    function IsStreamable(AType: TRttiType; out AStream: INeonTypeInfoStream): Boolean;

    /// <summary>
    ///   Writer for "Nullable" records
    /// </summary>
    /// <remarks>
    ///   Record must have HasValue and GetValue methods
    /// </remarks>
    function WriteNullable(AType: TRttiType; ANeonObject: TNeonRttiObject; ANullable: INeonTypeInfoNullable): TJSONObject;
    function IsNullable(AType: TRttiType; out ANullable: INeonTypeInfoNullable): Boolean;
  protected
    /// <summary>
    ///   Function to be called by a custom serializer method (ISerializeContext)
    /// </summary>
    function WriteDataMember(AType: TRttiType): TJSONObject; overload;

    /// <summary>
    ///   This method chooses the right Writer based on the Kind of the AValue parameter
    /// </summary>
    function WriteDataMember(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject; overload;
  public
    constructor Create(const AConfig: INeonConfiguration);

    /// <summary>
    ///   Serialize any Delphi type into a JSONValue, the Delphi type must be passed as a TRttiType
    /// </summary>
    class function TypeToJSONSchema(AType: TRttiType): TJSONObject; overload;
    class function TypeToJSONSchema(AType: TRttiType; AConfig: INeonConfiguration): TJSONObject; overload;

    /// <summary>
    ///   Serialize any Delphi type into a JSONValue, the Delphi type must be passed as a TRttiType
    /// </summary>
    class function ClassToJSONSchema(AClass: TClass): TJSONObject; overload;
    class function ClassToJSONSchema(AClass: TClass; AConfig: INeonConfiguration): TJSONObject; overload;
  end;

implementation

uses
  System.Variants;

{ TNeonSchemaGenerator }

class function TNeonSchemaGenerator.ClassToJSONSchema(AClass: TClass): TJSONObject;
begin
  Result := TypeToJSONSchema(TRttiUtils.Context.GetType(AClass), TNeonConfiguration.Default);
end;

class function TNeonSchemaGenerator.ClassToJSONSchema(AClass: TClass; AConfig: INeonConfiguration): TJSONObject;
begin
  Result := TypeToJSONSchema(TRttiUtils.Context.GetType(AClass), AConfig);
end;

constructor TNeonSchemaGenerator.Create(const AConfig: INeonConfiguration);
begin
  inherited Create(AConfig);
  FOperation := TNeonOperation.Serialize;
end;

function TNeonSchemaGenerator.IsEnumerable(AType: TRttiType; out AList: INeonTypeInfoList): Boolean;
begin
  AList := TNeonTypeInfoList.GuessType(AType);
  Result := Assigned(AList);
end;

function TNeonSchemaGenerator.IsEnumerableMap(AType: TRttiType; out AMap: INeonTypeInfoMap): Boolean;
begin
  AMap := TNeonTypeInfoMap.GuessType(AType);
  Result := Assigned(AMap);
end;

function TNeonSchemaGenerator.IsNullable(AType: TRttiType; out ANullable: INeonTypeInfoNullable): Boolean;
begin
  ANullable := TNeonTypeInfoNullable.GuessType(AType);
  Result := Assigned(ANullable);
end;

function TNeonSchemaGenerator.IsStreamable(AType: TRttiType; out AStream: INeonTypeInfoStream): Boolean;
begin
  AStream := TNeonTypeInfoStream.GuessType(AType);
  Result := Assigned(AStream);
end;

class function TNeonSchemaGenerator.TypeToJSONSchema(AType: TRttiType; AConfig: INeonConfiguration): TJSONObject;
var
  LGenerator: TNeonSchemaGenerator;
begin
  LGenerator := TNeonSchemaGenerator.Create(AConfig);
  try
    Result := LGenerator.WriteDataMember(AType);
  finally
    LGenerator.Free;
  end;
end;

class function TNeonSchemaGenerator.TypeToJSONSchema(AType: TRttiType): TJSONObject;
begin
  Result := TypeToJSONSchema(AType, TNeonConfiguration.Default);
end;

function TNeonSchemaGenerator.WriteArray(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
var
  LItems: TJSONObject;
begin
  LItems := WriteDataMember((AType as TRttiArrayType).ElementType);
  Result := TJSONObject.Create
    .AddPair('type', 'array')
    .AddPair('items', LItems)
end;

function TNeonSchemaGenerator.WriteBoolean(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
begin
  Result := TJSONObject.Create
    .AddPair('type', 'boolean');
end;

function TNeonSchemaGenerator.WriteDataMember(AType: TRttiType): TJSONObject;
var
  LNeonObject: TNeonRttiObject;
begin
  LNeonObject := TNeonRttiObject.Create(AType, FOperation);
  LNeonObject.ParseAttributes;
  try
    Result := WriteDataMember(AType, LNeonObject);
  finally
    LNeonObject.Free;
  end;
end;

function TNeonSchemaGenerator.WriteDataMember(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
var
  LNeonTypeInfo: INeonTypeInfo;

  LNeonMap: INeonTypeInfoMap absolute LNeonTypeInfo;
  LNeonList: INeonTypeInfoList absolute LNeonTypeInfo;
  LNeonStream: INeonTypeInfoStream absolute LNeonTypeInfo;
  LNeonNullable: INeonTypeInfoNullable absolute LNeonTypeInfo;
begin
  Result := nil;

  case AType.TypeKind of
    tkChar,
    tkWChar,
    tkString,
    tkLString,
    tkWString,
    tkUString:
    begin
      Result := WriteString(AType, ANeonObject);
    end;

    tkEnumeration:
    begin
      if AType.Handle = System.TypeInfo(Boolean) then
        Result := WriteBoolean(AType, ANeonObject)
      else
        Result := WriteEnum(AType, ANeonObject);
    end;

    tkInteger:
    begin
      Result := WriteInteger(AType, ANeonObject);
    end;

    tkInt64:
    begin
      Result := WriteInt64(AType, ANeonObject);
    end;

    tkFloat:
    begin
      if AType.Handle = TypeInfo(Single) then
        Result := WriteFloat(AType, ANeonObject)
      else if AType.Handle = TypeInfo(TDateTime) then
        Result := WriteDateTime(AType, ANeonObject)
      else if AType.Handle = TypeInfo(TTime) then
        Result := WriteDateTime(AType, ANeonObject)
      else if AType.Handle = TypeInfo(TDate) then
        Result := WriteDate(AType, ANeonObject)
      else
        Result := WriteDouble(AType, ANeonObject);
    end;

    tkClass:
    begin
      if AType.IsInstance and AType.AsInstance.MetaclassType.InheritsFrom(TDataSet) then
        Result := WriteDataSet(AType, ANeonObject)
      else if AType.IsInstance and AType.AsInstance.MetaclassType.InheritsFrom(TStream) then
        Result := WriteStream(AType, ANeonObject)
      else if IsEnumerableMap(AType, LNeonMap) then
        Result := WriteEnumerableMap(AType, ANeonObject, LNeonMap)
      else if IsEnumerable(AType, LNeonList) then
        Result := WriteEnumerable(AType, ANeonObject, LNeonList)
      else if IsStreamable(AType, LNeonStream) then
        Result := WriteStreamable(AType, ANeonObject, LNeonStream)
      else
        Result := WriteObject(AType, ANeonObject);
    end;

    tkArray:
    begin
      Result := WriteArray(AType, ANeonObject);
    end;

    tkDynArray:
    begin
      Result := WriteDynArray(AType, ANeonObject);
    end;

    tkSet:
    begin
      Result := WriteSet(AType, ANeonObject);
    end;

    tkRecord:
    begin
      if IsNullable(AType, LNeonNullable) then
        Result := WriteNullable(AType, ANeonObject, LNeonNullable)
      else
        Result := WriteRecord(AType, ANeonObject);
    end;

    tkInterface:
    begin
      Result := WriteInterface(AType, ANeonObject);
    end;

    tkVariant:
    begin
      Result := WriteVariant(AType, ANeonObject);
    end;

  end;
end;

function TNeonSchemaGenerator.WriteDataSet(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
var
  LJSONProps: TJSONObject;
begin
  //Result := TDataSetUtils.RecordToJSONSchema(AValue.AsObject as TDataSet, FConfig);

  LJSONProps := TJSONObject.Create;
  Result := TJSONObject.Create
    .AddPair('type', 'object')
    .AddPair('properties', LJSONProps);
end;

function TNeonSchemaGenerator.WriteDate(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
begin
  Result := TJSONObject.Create
    .AddPair('type', 'string')
    .AddPair('format', 'date');
end;

function TNeonSchemaGenerator.WriteDateTime(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
begin
  Result := TJSONObject.Create
    .AddPair('type', 'string')
    .AddPair('format', 'date-time');
end;

function TNeonSchemaGenerator.WriteDouble(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
begin
  Result := TJSONObject.Create
    .AddPair('type', 'number')
    .AddPair('format', 'double');
end;

function TNeonSchemaGenerator.WriteDynArray(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
var
  LItems: TJSONObject;
begin
  LItems := WriteDataMember((AType as TRttiDynamicArrayType).ElementType);
  Result := TJSONObject.Create
    .AddPair('type', 'array')
    .AddPair('items', LItems)
end;

function TNeonSchemaGenerator.WriteEnum(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
var
  LTypeData: PTypeData;
  LIndex: Integer;
  LEnumArray: TJSONArray;
begin
  LTypeData := GetTypeData(AType.Handle);

  LEnumArray := TJSONArray.Create;
  for LIndex := LTypeData.MinValue to LTypeData.MaxValue do
    LEnumArray.Add(TTypeInfoUtils.EnumToString(AType.Handle, LIndex, ANeonObject));

  Result := TJSONObject.Create
    .AddPair('type', 'string')
    .AddPair('enum', LEnumArray);
end;

function TNeonSchemaGenerator.WriteFloat(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
begin
  Result := TJSONObject.Create
    .AddPair('type', 'number')
    .AddPair('format', 'float');
end;

function TNeonSchemaGenerator.WriteInt64(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
begin
  Result := TJSONObject.Create
    .AddPair('type', 'integer')
    .AddPair('format', 'int64');
end;

function TNeonSchemaGenerator.WriteInteger(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
begin
  Result := TJSONObject.Create
    .AddPair('type', 'integer')
    .AddPair('format', 'int32');
end;

function TNeonSchemaGenerator.WriteInterface(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
begin
  Result := nil;
end;

procedure TNeonSchemaGenerator.WriteMembers(AType: TRttiType; AResult: TJSONObject);
var
  LJSONValue: TJSONObject;
  LMembers: TNeonRttiMembers;
  LNeonMember: TNeonRttiMember;
begin
  LMembers := GetNeonMembers(nil, AType);
  LMembers.FilterSerialize;
  try
    for LNeonMember in LMembers do
    begin
      if LNeonMember.Serializable then
      begin
        try
          LJSONValue := WriteDataMember(LNeonMember.RttiType, LNeonMember);
          if Assigned(LJSONValue) then
            (AResult as TJSONObject).AddPair(GetNameFromMember(LNeonMember), LJSONValue);
        except
          LogError(Format('Error converting property [%s] of object [%s]',
            [LNeonMember.Name, AType.Name]));
        end;
      end;
    end;
  finally
    LMembers.Free;
  end;
end;

function TNeonSchemaGenerator.WriteNullable(AType: TRttiType; ANeonObject: TNeonRttiObject; ANullable: INeonTypeInfoNullable): TJSONObject;
begin
  Result := nil;

  if Assigned(ANullable) then
    Result := WriteDataMember(ANullable.GetBaseType)
end;

function TNeonSchemaGenerator.WriteObject(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
var
  LProperties: TJSONObject;
begin
  LProperties := TJSONObject.Create;

  WriteMembers(AType, LProperties);

  Result := TJSONObject.Create
    .AddPair('type', 'object')
    .AddPair('properties', LProperties);
end;

function TNeonSchemaGenerator.WriteEnumerable(AType: TRttiType; ANeonObject: TNeonRttiObject; AList: INeonTypeInfoList): TJSONObject;
var
  LJSONItems: TJSONObject;
begin
  // Is not an Enumerable compatible object
  if not Assigned(AList) then
    Exit(nil);

  LJSONItems := WriteDataMember(AList.GetItemType);

  Result := TJSONObject.Create
    .AddPair('type', 'array')
    .AddPair('items', LJSONItems);
end;

function TNeonSchemaGenerator.WriteEnumerableMap(AType: TRttiType; ANeonObject: TNeonRttiObject; AMap: INeonTypeInfoMap): TJSONObject;
var
  LValueJSON: TJSONObject;
begin
  // Is not an EnumerableMap-compatible object
  if not Assigned(AMap) then
    Exit(nil);

  LValueJSON := WriteDataMember(AMap.GetValueType);
  Result := TJSONObject.Create
    .AddPair('type', 'object')
    .AddPair('additionalProperties', LValueJSON);
end;

function TNeonSchemaGenerator.WriteRecord(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
var
  LProperties: TJSONObject;
begin
  LProperties := TJSONObject.Create;

  WriteMembers(AType, LProperties);

  Result := TJSONObject.Create
    .AddPair('type', 'object')
    .AddPair('properties', LProperties);
end;

function TNeonSchemaGenerator.WriteSet(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
begin
  Result := TJSONObject.Create
    .AddPair('type', 'string');
end;

function TNeonSchemaGenerator.WriteStream(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
begin
  Result := TJSONObject.Create
    .AddPair('type', 'string')
    .AddPair('format', 'byte');
end;

function TNeonSchemaGenerator.WriteStreamable(AType: TRttiType; ANeonObject: TNeonRttiObject; AStream: INeonTypeInfoStream): TJSONObject;
begin
  Result := TJSONObject.Create
    .AddPair('type', 'string')
    .AddPair('format', 'byte');
end;

function TNeonSchemaGenerator.WriteString(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
begin
  Result := TJSONObject.Create
    .AddPair('type', 'string');
end;

function TNeonSchemaGenerator.WriteVariant(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
begin
{
  case ANeonObject.NeonInclude.Value of
    Include.NotNull:
    begin
      if VarIsNull(AValue.AsVariant) then
        Exit(nil);
    end;
    Include.NotEmpty:
    begin
      if VarIsEmpty(AValue.AsVariant) then
        Exit(nil);
    end;
  end;
}
  Result :=nil;
  //TJSONString.Create(AValue.AsVariant);
end;

end.
