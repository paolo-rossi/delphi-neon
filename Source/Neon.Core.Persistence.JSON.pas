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
unit Neon.Core.Persistence.JSON;

interface

{$I Neon.inc}

uses
  System.SysUtils, System.Classes, System.Rtti, System.SyncObjs,
  System.TypInfo, System.Generics.Collections, System.JSON, Data.DB,

  Neon.Core.Types,
  Neon.Core.Attributes,
  Neon.Core.Persistence,
  Neon.Core.DynamicTypes,
  Neon.Core.Utils;

type
  /// <summary>
  ///   JSON Serializer class
  /// </summary>
  TNeonSerializerJSON = class(TNeonBase, ISerializerContext)
  private
    /// <summary>
    ///   Writer for members of objects and records
    /// </summary>
    procedure WriteMembers(AType: TRttiType; AInstance: Pointer; AResult: TJSONValue);
  private
    /// <summary>
    ///   Writer for string types
    /// </summary>
    function WriteString(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for Char types
    /// </summary>
    function WriteChar(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for enums types <br />
    /// </summary>
    function WriteEnum(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for Integer types <br />
    /// </summary>
    function WriteInteger(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for float types <br />
    /// </summary>
    function WriteFloat(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for Variant types
    /// </summary>
    /// <remarks>
    ///   The variant will be written as string
    /// </remarks>
    function WriteVariant(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for static and dynamic arrays
    /// </summary>
    function WriteArray(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for the set type
    /// </summary>
    /// <remarks>
    ///   The output is a string with the values comma separated and enclosed by square brackets
    /// </remarks>
    /// <returns>[First,Second,Third]</returns>
    function WriteSet(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for a record type
    /// </summary>
    /// <remarks>
    ///   For records the engine serialize the fields by default
    /// </remarks>
    function WriteRecord(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for a standard TObject (descendants)  type (no list, stream or streamable)
    /// </summary>
    function WriteObject(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for an Interface type
    /// </summary>
    /// <remarks>
    ///   The object that implements the interface is serialized
    /// </remarks>
    function WriteInterface(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for TStream (descendants) objects
    /// </summary>
    function WriteStream(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for TDataSet (descendants) objects
    /// </summary>
    function WriteDataSet(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for "Enumerable" objects (Lists, Generic Lists, TStrings, etc...)
    /// </summary>
    /// <remarks>
    ///   Objects must have GetEnumerator, Clear, Add methods
    /// </remarks>
    function WriteEnumerable(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for "Dictionary" objects (TDictionary, TObjectDictionary)
    /// </summary>
    /// <remarks>
    ///   Objects must have Keys, Values, GetEnumerator, Clear, Add methods
    /// </remarks>
    function WriteEnumerableMap(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for "Streamable" objects
    /// </summary>
    /// <remarks>
    ///   Objects must have LoadFromStream and SaveToStream methods
    /// </remarks>
    function WriteStreamable(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
  protected
    /// <summary>
    ///   Function to be called by a custom serializer method (ISerializeContext)
    /// </summary>
    function WriteDataMember(const AValue: TValue): TJSONValue; overload;

    /// <summary>
    ///   This method chooses the right Writer based on the Kind of the AValue parameter
    /// </summary>
    function WriteDataMember(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue; overload;
  public
    constructor Create(const AConfig: INeonConfiguration);

    /// <summary>
    ///   Serialize any Delphi type into a JSONValue, the Delphi type must be passed as a TValue
    /// </summary>
    function ValueToJSON(const AValue: TValue): TJSONValue;

    /// <summary>
    ///   Serialize any Delphi objects into a JSONValue
    /// </summary>
    function ObjectToJSON(AObject: TObject): TJSONValue;
  end;

  /// <summary>
  ///   JSON Deserializer class
  /// </summary>
  TNeonDeserializerJSON = class(TNeonBase, IDeserializerContext)
  private
    procedure ReadMembers(AType: TRttiType; AInstance: Pointer; AJSONObject: TJSONObject);
  private
    function ReadString(AJSONValue: TJSONValue; AType: TRttiType; AKind: TTypeKind): TValue;
    function ReadChar(AJSONValue: TJSONValue; AType: TRttiType; AKind: TTypeKind): TValue;
    function ReadEnum(AJSONValue: TJSONValue; AType: TRttiType): TValue;
    function ReadInteger(AJSONValue: TJSONValue; AType: TRttiType): TValue;
    function ReadInt64(AJSONValue: TJSONValue; AType: TRttiType): TValue;
    function ReadFloat(AJSONValue: TJSONValue; AType: TRttiType): TValue;
    function ReadSet(AJSONValue: TJSONValue; AType: TRttiType): TValue;
    function ReadVariant(AJSONValue: TJSONValue; AType: TRttiType): TValue;
  private
    function ReadArray(AJSONValue: TJSONValue; AType: TRttiType; const AData: TValue): TValue;
    function ReadDynArray(AJSONValue: TJSONValue; AType: TRttiType; const AData: TValue): TValue;
    function ReadObject(AJSONValue: TJSONValue; AType: TRttiType; const AData: TValue): TValue;
    function ReadInterface(AJSONValue: TJSONValue; AType: TRttiType; const AData: TValue): TValue;
    function ReadRecord(AJSONValue: TJSONValue; AType: TRttiType; const AData: TValue): TValue;
    function ReadDataSet(AJSONValue: TJSONValue; AType: TRttiType; const AData: TValue): TValue;
    function ReadStream(AJSONValue: TJSONValue; AType: TRttiType; const AData: TValue): TValue;

    function ReadStreamable(AJSONValue: TJSONValue; AType: TRttiType; const AData: TValue): Boolean;
    function ReadEnumerable(AJSONValue: TJSONValue; AType: TRttiType; const AData: TValue): Boolean;
    function ReadEnumerableMap(AJSONValue: TJSONValue; AType: TRttiType; const AData: TValue): Boolean;
  private
    function ReadDataMember(AJSONValue: TJSONValue; AType: TRttiType; const AData: TValue): TValue;
  public
    constructor Create(const AConfig: INeonConfiguration);

    procedure JSONToObject(AObject: TObject; AJSON: TJSONValue);
    function JSONToTValue(AJSON: TJSONValue; AType: TRttiType): TValue; overload;
    function JSONToTValue(AJSON: TJSONValue; AType: TRttiType; const AData: TValue): TValue; overload;
    function JSONToArray(AJSON: TJSONValue; AType: TRttiType): TValue;
  end;

  /// <summary>
  ///   Static utility class for serializing and deserializing Delphi types
  /// </summary>
  TNeon = class
  public
    /// <summary>
    ///   Prints a TJSONValue in a single line or formatted (PrettyPrinting)
    /// </summary>
    class function Print(AJSONValue: TJSONValue; APretty: Boolean): string; static;
  public
    /// <summary>
    ///   Serializes a value based type (record, string, integer, etc...) to a TJSONValue
    /// </summary>
    /// <remarks>
    ///   A default configuration object will be provided
    /// </remarks>
    class function ValueToJSON(const AValue: TValue): TJSONValue; overload;

    /// <summary>
    ///   Serializes a value based type (record, string, integer, etc...) to a TJSONValue
    ///   with a given configuration
    /// </summary>
    class function ValueToJSON(const AValue: TValue; AConfig: INeonConfiguration): TJSONValue; overload;

    /// <summary>
    ///   Serializes an object based type to a TJSONValue with a default configuration
    /// </summary>
    class function ObjectToJSON(AObject: TObject): TJSONValue; overload;

    /// <summary>
    ///   Serializes an object based type to a TJSONValue with a given configuration <br />
    /// </summary>
    class function ObjectToJSON(AObject: TObject; AConfig: INeonConfiguration): TJSONValue; overload;

    /// <summary>
    ///   Serializes an object based type to a string with a default configuration <br />
    /// </summary>
    class function ObjectToJSONString(AObject: TObject): string; overload;

    /// <summary>
    ///   Serializes an object based type to a string with a given configuration <br />
    /// </summary>
    class function ObjectToJSONString(AObject: TObject; AConfig: INeonConfiguration): string; overload;
  public
    /// <summary>
    ///   Deserializes a TJSONValue into a TObject with a given configuration
    /// </summary>
    class procedure JSONToObject(AObject: TObject; AJSON: TJSONValue; AConfig: INeonConfiguration); overload;
    /// <summary>
    ///   Deserializes a string into a TObject with a given configuration
    /// </summary>
    class procedure JSONToObject(AObject: TObject; const AJSON: string; AConfig: INeonConfiguration); overload;

    /// <summary>
    ///   Deserializes a TJSONValue into a TRttiType with a default configuration
    /// </summary>
    class function JSONToObject(AType: TRttiType; AJSON: TJSONValue): TObject; overload;

    /// <summary>
    ///   Deserializes a TJSONValue into a TRttiType with a given configuration
    /// </summary>
    class function JSONToObject(AType: TRttiType; AJSON: TJSONValue; AConfig: INeonConfiguration): TObject; overload;

    /// <summary>
    ///   Deserializes a string into a TRttiType with a default configuration
    /// </summary>
    class function JSONToObject(AType: TRttiType; const AJSON: string): TObject; overload;

    /// <summary>
    ///   Deserializes a string into a TRttiType with a given configuration
    /// </summary>
    class function JSONToObject(AType: TRttiType; const AJSON: string; AConfig: INeonConfiguration): TObject; overload;

    /// <summary>
    ///   Deserializes a TJSONValue into a generic type &lt;T&gt; with a default
    ///   configuration
    /// </summary>
    class function JSONToObject<T: class, constructor>(AJSON: TJSONValue): T; overload;

    /// <summary>
    ///   Deserializes a TJSONValue into a generic type &lt;T&gt; with a given
    ///   configuration <br />
    /// </summary>
    class function JSONToObject<T: class, constructor>(AJSON: TJSONValue; AConfig: INeonConfiguration): T; overload;

    /// <summary>
    ///   Deserializes a string into a generic type &lt;T&gt; with a default
    ///   configuration <br />
    /// </summary>
    class function JSONToObject<T: class, constructor>(const AJSON: string): T; overload;

    /// <summary>
    ///   Deserializes a string into a generic type &lt;T&gt; with a given configuration <br />
    /// </summary>
    class function JSONToObject<T: class, constructor>(const AJSON: string; AConfig: INeonConfiguration): T; overload;
  public
    /// <summary>
    ///   Deserializes a TJSONValue into a TRttiType value based with a default
    ///   configuration <br />
    /// </summary>
    class function JSONToValue(ARttiType: TRttiType; AJSON: TJSONValue): TValue; overload;

    /// <summary>
    ///   Deserializes a TJSONValue into a TRttiType value based with a given
    ///   configuration
    /// </summary>
    class function JSONToValue(ARttiType: TRttiType; AJSON: TJSONValue; AConfig: INeonConfiguration): TValue; overload;

    /// <summary>
    ///   Deserializes a TJSONValue into a generic type &lt;T&gt; (value based) with a
    ///   default configuration
    /// </summary>
    class function JSONToValue<T>(AJSON: TJSONValue): T; overload;

    /// <summary>
    ///   Deserializes a TJSONValue into a generic type &lt;T&gt; (value based) with a
    ///   given configuration <br />
    /// </summary>
    class function JSONToValue<T>(AJSON: TJSONValue; AConfig: INeonConfiguration): T; overload;
  end;

implementation

{ TNeonSerializerJSON }

constructor TNeonSerializerJSON.Create(const AConfig: INeonConfiguration);
begin
  inherited Create(AConfig);
  FOperation := TNeonOperation.Serialize;
end;

function TNeonSerializerJSON.ObjectToJSON(AObject: TObject): TJSONValue;
begin
  FOriginalInstance := AObject;
  if not Assigned(AObject) then
    Exit(TJSONObject.Create);

  Result := WriteDataMember(AObject);
end;

function TNeonSerializerJSON.ValueToJSON(const AValue: TValue): TJSONValue;
begin
  FOriginalInstance := AValue;

  Result := WriteDataMember(AValue);
end;

function TNeonSerializerJSON.WriteArray(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
var
  LIndex, LCount: Integer;
  LArray: TJSONArray;
begin
  LCount := AValue.GetArrayLength;
  if ANeonObject.NeonInclude.Value = Include.NotEmpty then
    if LCount = 0 then
      Exit(nil);

  LArray := TJSONArray.Create;
  for LIndex := 0 to LCount - 1 do
    LArray.AddElement(WriteDataMember(AValue.GetArrayElement(LIndex)));

  Result := LArray;
end;

function TNeonSerializerJSON.WriteChar(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
begin
  if AValue.AsString = #0 then
    Result := TJSONString.Create('')
  else
    Result := TJSONString.Create(AValue.AsString);
end;

function TNeonSerializerJSON.WriteDataMember(const AValue: TValue): TJSONValue;
var
  LNeonObject: TNeonRttiObject;
  LRttiType: TRttiType;
begin
  LRttiType := TRttiUtils.Context.GetType(AValue.TypeInfo);

  LNeonObject := TNeonRttiObject.Create(LRttiType, FOperation);
  try
    Result := WriteDataMember(AValue, LNeonObject);
  finally
    LNeonObject.Free;
  end;
end;

function TNeonSerializerJSON.WriteDataMember(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
var
  LCustomSer: TCustomSerializer;
begin
  Result := nil;

  LCustomSer := FConfig.Serializers.GetSerializer(AValue.TypeInfo);
  if Assigned(LCustomSer) then
  begin
    Result := LCustomSer.Serialize(AValue, Self);
    Exit(Result);
  end;

  case AValue.Kind of
    tkChar,
    tkWChar:
    begin
      Result := WriteChar(AValue, ANeonObject);
    end;

    tkString,
    tkLString,
    tkWString,
    tkUString:
    begin
      Result := WriteString(AValue, ANeonObject);
    end;

    tkEnumeration:
    begin
      Result := WriteEnum(AValue, ANeonObject);
    end;

    tkInteger,
    tkInt64:
    begin
      Result := WriteInteger(AValue, ANeonObject);
    end;

    tkFloat:
    begin
      Result := WriteFloat(AValue, ANeonObject);
    end;

    tkClass:
    begin
      if AValue.AsObject is TDataSet then
        Result := WriteDataSet(AValue, ANeonObject)
      else if AValue.AsObject is TStream then
        Result := WriteStream(AValue, ANeonObject)
      else
      begin
        Result := WriteEnumerableMap(AValue, ANeonObject);
        if not Assigned(Result) then
          Result := WriteEnumerable(AValue, ANeonObject);
        if not Assigned(Result) then
          Result := WriteStreamable(AValue, ANeonObject);
        if not Assigned(Result) then
          Result := WriteObject(AValue, ANeonObject);
      end;
    end;

    tkArray:
    begin
      Result := WriteArray(AValue, ANeonObject);
    end;

    tkDynArray:
    begin
      Result := WriteArray(AValue, ANeonObject);
    end;

    tkSet:
    begin
      Result := WriteSet(AValue, ANeonObject);
    end;

    tkRecord:
    begin
      Result := WriteRecord(AValue, ANeonObject);
      if not Assigned(Result) then
        Result := TJSONObject.Create;
    end;

    tkInterface:
    begin
      Result := WriteInterface(AValue, ANeonObject);
    end;

    tkVariant:
    begin
      Result := WriteVariant(AValue, ANeonObject);
    end;
    {
    tkUnknown,
    tkMethod,
    tkPointer,
    tkProcedure,
    tkClassRef:
    }
  end;
end;

function TNeonSerializerJSON.WriteDataSet(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
var
  LDataSet: TDataSet;
begin
  LDataSet := AValue.AsObject as TDataSet;

  if ANeonObject.NeonInclude.Value = Include.NotNull then
    if not Assigned(LDataSet) then
      Exit(nil);

  if ANeonObject.NeonInclude.Value = Include.NotEmpty then
    if LDataSet.IsEmpty then
      Exit(nil);

  if not Assigned(LDataSet) then
    Exit(TJSONNull.Create);

  Result := TDataSetUtils.DataSetToJSONArray(LDataSet, FConfig);
end;

function TNeonSerializerJSON.WriteEnum(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
begin
  if AValue.TypeInfo = System.TypeInfo(Boolean) then
  begin
    if AValue.AsBoolean then
      Result := TJSONTrue.Create
    else
      Result := TJSONFalse.Create;
  end
  else
    Result := TJSONString.Create(GetEnumName(AValue.TypeInfo, AValue.AsOrdinal));
end;

function TNeonSerializerJSON.WriteFloat(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
begin
  if (AValue.TypeInfo = System.TypeInfo(TDateTime)) or
     (AValue.TypeInfo = System.TypeInfo(TDate)) or
     (AValue.TypeInfo = System.TypeInfo(TTime)) then
    Result := TJSONString.Create(TJSONUtils.DateToJSON(AValue.AsType<TDateTime>, FConfig.UseUTCDate))
  else
    Result := TJSONNumber.Create(AValue.AsExtended);
end;

function TNeonSerializerJSON.WriteInteger(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
begin
  Result := TJSONNumber.Create(AValue.AsInt64);
end;

function TNeonSerializerJSON.WriteInterface(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
var
  LInterface: IInterface;
  LObject: TObject;
begin
  LInterface := AValue.AsInterface;
  LObject := LInterface as TObject;
  Result := WriteObject(LObject, ANeonObject);
end;

procedure TNeonSerializerJSON.WriteMembers(AType: TRttiType; AInstance: Pointer; AResult: TJSONValue);
var
  LJSONValue: TJSONValue;
  LMembers: TNeonRttiMembers;
  LNeonMember: TNeonRttiMember;
begin
  LMembers := GetNeonMembers(AInstance, AType);
  LMembers.FilterSerialize;
  try
    for LNeonMember in LMembers do
    begin
      if LNeonMember.Serializable then
      begin
        try
          LJSONValue := WriteDataMember(LNeonMember.GetValue, LNeonMember);
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

function TNeonSerializerJSON.WriteObject(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
var
  LObject: TObject;
  LType: TRttiType;
begin
  Result := TJSONObject.Create;
  LObject := AValue.AsObject;

  if not Assigned(LObject) then
    Exit(TJSONNull.Create);

  LType := TRttiUtils.Context.GetType(LObject.ClassType);

  WriteMembers(LType, LObject, Result);
end;

function TNeonSerializerJSON.WriteEnumerable(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
var
  LObject: TObject;
  LJSONValue: TJSONValue;
  LList: IDynamicList;
begin
  Result := nil;

  LObject := AValue.AsObject;

  if ANeonObject.NeonInclude.Value = Include.NotNull then
    if not Assigned(LObject) then
      Exit(nil);

  if not Assigned(LObject) then
    Exit(TJSONNull.Create);

  // Exit or Exception?
  LList := TDynamicList.GuessType(LObject);
  if not Assigned(LList) then
    Exit;

  if ANeonObject.NeonInclude.Value = Include.NotEmpty then
    if LList.Count = 0 then
      Exit(nil);

  Result := TJSONArray.Create;
  while LList.MoveNext do
  begin
    LJSONValue := WriteDataMember(LList.Current);
    (Result as TJSONArray).AddElement(LJSONValue);
  end;
end;

function TNeonSerializerJSON.WriteEnumerableMap(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
var
  LObject: TObject;
  LJSONName: string;
  LKeyValue, LValValue: TValue;
  LJSONValue: TJSONValue;

  LMap: IDynamicMap;
begin
  Result := nil;
  LObject := AValue.AsObject;

  if ANeonObject.NeonInclude.Value = Include.NotNull then
    if not Assigned(LObject) then
      Exit(nil);

  if not Assigned(LObject) then
    Exit(TJSONNull.Create);

  LMap := TDynamicMap.GuessType(LObject);
  if not Assigned(LMap) then
    Exit;

  if ANeonObject.NeonInclude.Value = Include.NotEmpty then
    if LMap.Count = 0 then
      Exit(nil);

  case LMap.GetKeyType.TypeKind  of
    tkChar, tkWChar,
    tkString, tkLString,
    tkWString, tkUString: ;
  else
    Exit(TJSONNull.Create);
  end;

  Result := TJSONObject.Create;
  while LMap.MoveNext do
  begin
    LKeyValue := LMap.CurrentKey;
    LValValue := LMap.CurrentValue;

    LJSONName := LKeyValue.AsString;
    LJSONValue := WriteDataMember(LValValue);

    (Result as TJSONObject).AddPair(LJSONName, LJSONValue);
  end;
end;

function TNeonSerializerJSON.WriteRecord(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
var
  LType: TRttiType;
begin
  Result := TJSONObject.Create;
  LType := TRttiUtils.Context.GetType(AValue.TypeInfo);
  try
    WriteMembers(LType, AValue.GetReferenceToRawData, Result);
  except
    FreeAndNil(Result);
  end;
end;

function TNeonSerializerJSON.WriteSet(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
begin
  Result := TJSONString.Create(SetToString(AValue.TypeInfo, Integer(AValue.GetReferenceToRawData^), True));
end;

function TNeonSerializerJSON.WriteStream(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
var
  LStream: TStream;
  LBase64: string;
begin
  LStream := AValue.AsObject as TStream;

  if not Assigned(LStream) then
    Exit(TJSONNull.Create);

  LStream.Position := soFromBeginning;
  LBase64 := TBase64.Encode(LStream);
  Result := TJSONString.Create(LBase64);
end;

function TNeonSerializerJSON.WriteStreamable(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
var
  LObject: TObject;
  LBinaryStream: TMemoryStream;
  LBase64: string;
  LStreamable: IDynamicStream;
begin
  Result := nil;
  LObject := AValue.AsObject;

  if not Assigned(LObject) then
    Exit(TJSONNull.Create);

  LStreamable := TDynamicStream.GuessType(LObject);

  if Assigned(LStreamable) then
  begin
    LBinaryStream := TMemoryStream.Create;
    try
      LStreamable.SaveToStream(LBinaryStream);
      LBinaryStream.Position := soFromBeginning;
      LBase64 := TBase64.Encode(LBinaryStream);
      if IsOriginalInstance(AValue) then
        Result := TJSONObject.Create.AddPair('$value', LBase64)
      else
        Result := TJSONString.Create(LBase64);
    finally
      LBinaryStream.Free;
    end;
  end;
end;

function TNeonSerializerJSON.WriteString(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
begin
  if ANeonObject.NeonInclude.Value = Include.NotEmpty then
    if AValue.AsString.IsEmpty then
      Exit(nil);

  Result := TJSONString.Create(AValue.AsString);
end;

function TNeonSerializerJSON.WriteVariant(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
begin
  Result := TJSONString.Create(AValue.AsVariant);
end;

{ TNeonDeserializerJSON }

constructor TNeonDeserializerJSON.Create(const AConfig: INeonConfiguration);
begin
  inherited Create(AConfig);
  FOperation := TNeonOperation.Deserialize;
end;

{ TNeonDeserializerJSON }

function TNeonDeserializerJSON.ReadArray(AJSONValue: TJSONValue; AType: TRttiType; const AData: TValue): TValue;
var
  LIndex: NativeInt;
  LItemValue: TValue;
  LItemType: TRttiType;
  LJSONArray: TJSONArray;
  LJSONItem: TJSONValue;
begin
  // TValue record copy (but the TValue only copy the reference to Data)
  Result := AData;

  // Clear (and Free) previous elements?
  LJSONArray := AJSONValue as TJSONArray;
  LItemType := (AType as TRttiArrayType).ElementType;

  // Check static array bounds
  for LIndex := 0 to LJSONArray.Count - 1 do
  begin
    LJSONItem := LJSONArray.Items[LIndex];
    LItemValue := TRttiUtils.CreateNewValue(LItemType);
    LItemValue := ReadDataMember(LJSONItem, LItemType, Result);
    Result.SetArrayElement(LIndex, LItemValue);
  end;
end;

function TNeonDeserializerJSON.ReadDynArray(AJSONValue: TJSONValue; AType: TRttiType; const AData: TValue): TValue;
var
  LIndex: NativeInt;
  LItemValue: TValue;
  LItemType: TRttiType;
  LArrayLength: NativeInt;
  LJSONArray: TJSONArray;
  LJSONItem: TJSONValue;
begin
  Result := AData;

  // Clear (and Free) previous elements?
  LJSONArray := AJSONValue as TJSONArray;
  LItemType := (AType as TRttiDynamicArrayType).ElementType;
  LArrayLength := LJSONArray.Count;
  DynArraySetLength(PPointer(Result.GetReferenceToRawData)^, Result.TypeInfo, 1, @LArrayLength);

  for LIndex := 0 to LJSONArray.Count - 1 do
  begin
    LJSONItem := LJSONArray.Items[LIndex];

    LItemValue := TRttiUtils.CreateNewValue(LItemType);
    LItemValue := ReadDataMember(LJSONItem, LItemType, LItemValue);

    Result.SetArrayElement(LIndex, LItemValue);
  end;
end;

function TNeonDeserializerJSON.ReadChar(AJSONValue: TJSONValue; AType: TRttiType; AKind: TTypeKind): TValue;
begin
  if (AJSONValue is TJSONNull) or AJSONValue.Value.IsEmpty then
    Exit(#0);

  case AKind of
    // AnsiChar
    tkChar:  Result := TValue.From<UTF8Char>(UTF8Char(AJSONValue.Value.Chars[0]));

    // WideChar
    tkWChar: Result := TValue.From<Char>(AJSONValue.Value.Chars[0]);
  end;
end;

function TNeonDeserializerJSON.ReadDataMember(AJSONValue: TJSONValue; AType: TRttiType; const AData: TValue): TValue;
var
  LCustom: TCustomSerializer;
begin
  if AJSONValue is TJSONNull then
    Exit(TValue.Empty);

  // if there is a custom serializer
  LCustom := FConfig.Serializers.GetSerializer(AType.Handle);

  if Assigned(LCustom) then
  begin
    Result := LCustom.Deserialize(AJSONValue, AData, Self);
    Exit(Result);
  end;

  case AType.TypeKind of
    // Simple types
    tkInt64:       Result := ReadInt64(AJSONValue, AType);
    tkInteger:     Result := ReadInteger(AJSONValue, AType);
    tkChar:        Result := ReadChar(AJSONValue, AType, AType.TypeKind);
    tkWChar:       Result := ReadChar(AJSONValue, AType, AType.TypeKind);
    tkEnumeration: Result := ReadEnum(AJSONValue, AType);
    tkFloat:       Result := ReadFloat(AJSONValue, AType);
    tkLString:     Result := ReadString(AJSONValue, AType, AType.TypeKind);
    tkWString:     Result := ReadString(AJSONValue, AType, AType.TypeKind);
    tkUString:     Result := ReadString(AJSONValue, AType, AType.TypeKind);
    tkString:      Result := ReadString(AJSONValue, AType, AType.TypeKind);
    tkSet:         Result := ReadSet(AJSONValue, AType);
    tkVariant:     Result := ReadVariant(AJSONValue, AType);
    tkArray:       Result := ReadArray(AJSONValue, AType, AData);
    tkDynArray:    Result := ReadDynArray(AJSONValue, AType, AData);

    // Complex types
    tkClass:
    begin
      { TODO -opaolo -c : Refactor Read*Object function (boolean result) 20/05/2017 12:25:19 }
      if AData.AsObject is TDataSet then
        Result := ReadDataSet(AJSONValue, AType, AData)
      else if AData.AsObject is TStream then
        Result := ReadStream(AJSONValue, AType, AData)
      else
      begin
        if ReadEnumerableMap(AJSONValue, AType, AData) then
          Result := AData
        else if ReadEnumerable(AJSONValue, AType, AData) then
          Result := AData
        else if ReadStreamable(AJSONValue, AType, AData) then
          Result := AData
        else
          Result := ReadObject(AJSONValue, AType, AData);
      end;
    end;
    tkInterface:   Result := ReadInterface(AJSONValue, AType, AData);
    tkRecord:      Result := ReadRecord(AJSONValue, AType, AData);

    // Not supported (yet)
    {
    tkUnknown: ;
    tkClassRef: ;
    tkPointer: ;
    tkMethod: ;
    tkProcedure: ;
    }
    else Result := TValue.Empty;
  end;
end;

function TNeonDeserializerJSON.ReadDataSet(AJSONValue: TJSONValue; AType: TRttiType; const AData: TValue): TValue;
var
  LJSONArray: TJSONArray;
  LJSONItem: TJSONObject;
  LJSONField: TJSONValue;
  LDataSet: TDataSet;
  LIndex: Integer;
  LItemIntex: Integer;
  LName: string;
begin
  Result := AData;
  LDataSet := AData.AsObject as TDataSet;
  LJSONArray := AJSONValue as TJSONArray;

  for LIndex := 0 to LJSONArray.Count - 1 do
  begin
    LJSONItem := LJSONArray.Items[LIndex] as TJSONObject;

    LDataSet.Append;
    for LItemIntex := 0 to LDataSet.Fields.Count - 1 do
    begin
      LName := LDataSet.Fields[LItemIntex].FieldName;

      LJSONField := LJSONItem.GetValue(LName);
      if Assigned(LJSONField) then
      begin
        { TODO -opaolo -c : Be more specific (field and json type) 27/04/2017 17:16:09 }
        LDataSet.FieldByName(LName).AsString := LJSONField.Value;
      end;
    end;
    LDataSet.Post;
  end;
end;

function TNeonDeserializerJSON.ReadEnum(AJSONValue: TJSONValue; AType: TRttiType): TValue;
begin
  if AType.Handle = System.TypeInfo(Boolean) then
  begin
    if AJSONValue is TJSONTrue then
      Result := True
    else if AJSONValue is TJSONFalse then
      Result := False
    else
      raise ENeonException.Create('Invalid JSON value. Boolean expected');
  end
  else
  begin
    TValue.Make(GetEnumValue(AType.Handle, AJSONValue.Value), AType.Handle, Result);
  end;
end;

function TNeonDeserializerJSON.ReadEnumerable(AJSONValue: TJSONValue; AType: TRttiType; const AData: TValue): Boolean;
var
  LItemValue: TValue;
  LList: IDynamicList;
  LJSONArray: TJSONArray;
  LJSONItem: TJSONValue;
  LIndex: Integer;
  LItemType: TRttiType;
begin
  Result := False;
  LList := TDynamicList.GuessType(AData.AsObject);
  if Assigned(LList) then
  begin
    Result := True;
    LItemType := LList.GetItemType;
    LList.Clear;

    LJSONArray := AJSONValue as TJSONArray;

    for LIndex := 0 to LJSONArray.Count - 1 do
    begin
      LJSONItem := LJSONArray.Items[LIndex];

      LItemValue := LList.NewItem;
      LItemValue := ReadDataMember(LJSONItem, LItemType, LItemValue);

      LList.Add(LItemValue);
    end;
  end;
end;

function TNeonDeserializerJSON.ReadEnumerableMap(AJSONValue: TJSONValue; AType: TRttiType; const AData: TValue): Boolean;
var
  LMap: IDynamicMap;
{$IFDEF HAS_NEW_JSON}
  LEnum: TJSONObject.TEnumerator;
{$ELSE}
  LEnum: TJSONPairEnumerator;
{$ENDIF}
  LKeyType, LValueType: TRttiType;

  procedure NewItemFromPair(APair: TJSONPair);
  var
    LKey, LValue: TValue;
  begin
    LKey := LMap.NewKey;
    LKey := ReadDataMember(APair.JsonString, LKeyType, LKey);

    LValue := LMap.NewValue;
    LValue := ReadDataMember(APair.JsonValue, LValueType, LValue);

    LMap.Add(LKey, LValue);
  end;

begin
  Result := False;
  LMap := TDynamicMap.GuessType(AData.AsObject);
  if Assigned(LMap) then
  begin
    Result := True;
    LKeyType := LMap.GetKeyType;
    LValueType := LMap.GetValueType;
    LMap.Clear;

    LEnum := (AJSONValue as TJSONObject).GetEnumerator;
    try
      while LEnum.MoveNext do
        NewItemFromPair(LEnum.Current);
    finally
      LEnum.Free;
    end;
  end;
end;

function TNeonDeserializerJSON.ReadFloat(AJSONValue: TJSONValue; AType: TRttiType): TValue;
begin
  if AJSONValue is TJSONNull then
    Exit(0);

  if AType.Handle = System.TypeInfo(TDate) then
    Result := TValue.From<TDate>(TJSONUtils.JSONToDate(AJSONValue.Value, True))
  else if AType.Handle = System.TypeInfo(TTime) then
    Result := TValue.From<TTime>(TJSONUtils.JSONToDate(AJSONValue.Value, True))
  else if AType.Handle = System.TypeInfo(TDateTime) then
    Result := TValue.From<TDateTime>(TJSONUtils.JSONToDate(AJSONValue.Value, FConfig.UseUTCDate))
  else
  begin
    if AJSONValue is TJSONNumber then
      Result := (AJSONValue as TJSONNumber).AsDouble
    else
      raise ENeonException.Create('Invalid JSON value. Float expected');
  end;
end;

function TNeonDeserializerJSON.ReadInt64(AJSONValue: TJSONValue; AType: TRttiType): TValue;
var
  LNumber: TJSONNumber;
begin
  if AJSONValue is TJSONNull then
    Exit(0);

  LNumber := AJSONValue as TJSONNumber;
  Result := LNumber.AsInt64
end;

function TNeonDeserializerJSON.ReadInteger(AJSONValue: TJSONValue; AType: TRttiType): TValue;
var
  LNumber: TJSONNumber;
begin
  if AJSONValue is TJSONNull then
    Exit(0);

  LNumber := AJSONValue as TJSONNumber;
  Result := LNumber.AsInt;
end;

function TNeonDeserializerJSON.ReadInterface(AJSONValue: TJSONValue; AType: TRttiType; const AData: TValue): TValue;
begin
  Result := AData;
end;

procedure TNeonDeserializerJSON.ReadMembers(AType: TRttiType; AInstance: Pointer; AJSONObject: TJSONObject);
var
  LMembers: TNeonRttiMembers;
  LNeonMember: TNeonRttiMember;
  LJSONValue: TJSONValue;
  LMemberValue: TValue;
begin
  LMembers := GetNeonMembers(AInstance, AType);
  LMembers.FilterDeserialize;
  try
    for LNeonMember in LMembers do
    begin
      if LNeonMember.Serializable then
      begin
        //Look for a JSON with the calculated Member Name
        LJSONValue := AJSONObject.GetValue(GetNameFromMember(LNeonMember));

        // Property not found in JSON, continue to the next one
        if not Assigned(LJSONValue) then
          Continue;

        LMemberValue := ReadDataMember(LJSONValue, LNeonMember.RttiType, LNeonMember.GetValue);
        LNeonMember.SetValue(LMemberValue);
      end;
    end;
  finally
    LMembers.Free;
  end;
end;

function TNeonDeserializerJSON.ReadObject(AJSONValue: TJSONValue; AType: TRttiType; const AData: TValue): TValue;
var
  LJSONObject: TJSONObject;
  LPData: Pointer;
begin
  Result := AData;
  LPData := AData.AsObject;
  LJSONObject := AJSONValue as TJSONObject;

  if (AType.TypeKind = tkClass) or (AType.TypeKind = tkInterface) then
    ReadMembers(AType, LPData, LJSONObject);
end;

function TNeonDeserializerJSON.ReadRecord(AJSONValue: TJSONValue; AType: TRttiType; const AData: TValue): TValue;
var
  LJSONObject: TJSONObject;
  LPData: Pointer;
begin
  Result := AData;
  LPData := AData.GetReferenceToRawData;

  if not Assigned(LPData) then
    Exit;

  // Objects, Records, Interfaces are all represented by JSON objects
  LJSONObject := AJSONValue as TJSONObject;

  ReadMembers(AType, LPData, LJSONObject);
end;

function TNeonDeserializerJSON.ReadSet(AJSONValue: TJSONValue; AType: TRttiType): TValue;
var
  LSetStr: string;
begin
  LSetStr := AJSONValue.Value;
  LSetStr := LSetStr.Replace(sLineBreak, '', [rfReplaceAll]);
  LSetStr := LSetStr.Replace(' ', '', [rfReplaceAll]);
  TValue.Make(StringToSet(AType.Handle, LSetStr), aType.Handle, Result);
end;

function TNeonDeserializerJSON.ReadStream(AJSONValue: TJSONValue;
  AType: TRttiType; const AData: TValue): TValue;
var
  LStream: TStream;
begin
  Result := AData;
  LStream := AData.AsObject as TStream;
  LStream.Position := soFromBeginning;

  TBase64.Decode(AJSONValue.Value, LStream);
end;

function TNeonDeserializerJSON.ReadStreamable(AJSONValue: TJSONValue;
  AType: TRttiType; const AData: TValue): Boolean;
var
  LStream: TMemoryStream;
  LStreamable: IDynamicStream;
  LJSONValue: TJSONValue;
begin
  Result := False;
  LStreamable := TDynamicStream.GuessType(AData.AsObject);
  if Assigned(LStreamable) then
  begin
    Result := True;
    LStream := TMemoryStream.Create;
    try
      if IsOriginalInstance(AData) then
        LJSONValue := (AJSONValue as TJSONObject).GetValue('$value')
      else
        LJSONValue := AJSONValue;

      TBase64.Decode(LJSONValue.Value, LStream);
      LStream.Position := soFromBeginning;
      LStreamable.LoadFromStream(LStream);
    finally
      LStream.Free;
    end;
  end;
end;

function TNeonDeserializerJSON.ReadString(AJSONValue: TJSONValue;
  AType: TRttiType; AKind: TTypeKind): TValue;
begin
  case AKind of
    // AnsiString
    tkLString: Result := TValue.From<UTF8String>(UTF8String(AJSONValue.Value));

    //WideString
    tkWString: Result := TValue.From<string>(AJSONValue.Value);

    //UnicodeString
    tkUString: Result := TValue.From<string>(AJSONValue.Value);

    //ShortString
    tkString:  Result := TValue.From<UTF8String>(UTF8String(AJSONValue.Value));

  // Future string types treated as unicode strings
  else
    Result := AJSONValue.Value;
  end;
end;

function TNeonDeserializerJSON.ReadVariant(AJSONValue: TJSONValue; AType: TRttiType): TValue;
begin

end;

function TNeonDeserializerJSON.JSONToArray(AJSON: TJSONValue; AType: TRttiType): TValue;
begin
  Result := ReadDataMember(AJSON, AType, TValue.Empty);
end;

procedure TNeonDeserializerJSON.JSONToObject(AObject: TObject; AJSON: TJSONValue);
var
  LType: TRttiType;
  LValue: TValue;
begin
  FOriginalInstance := AObject;
  LType := TRttiUtils.Context.GetType(AObject.ClassType);
  LValue := AObject;
  ReadDataMember(AJSON, LType, AObject);
end;

function TNeonDeserializerJSON.JSONToTValue(AJSON: TJSONValue; AType: TRttiType;
  const AData: TValue): TValue;
begin
  FOriginalInstance := AData;
  Result := ReadDataMember(AJSON, AType, AData);
end;

function TNeonDeserializerJSON.JSONToTValue(AJSON: TJSONValue; AType: TRttiType): TValue;
begin
  //FOriginalInstance := TValue.Empty;
  Result := ReadDataMember(AJSON, AType, TValue.Empty);
end;

{ TNeon }

class function TNeon.JSONToObject(AType: TRttiType; AJSON: TJSONValue): TObject;
begin
  Result := JSONToObject(AType, AJSON, TNeonConfiguration.Default);
end;

class function TNeon.JSONToObject(AType: TRttiType; const AJSON: string): TObject;
begin
  Result := JSONToObject(AType, AJSON, TNeonConfiguration.Default);
end;

class function TNeon.JSONToObject(AType: TRttiType; AJSON: TJSONValue; AConfig: INeonConfiguration): TObject;
begin
  Result := TRttiUtils.CreateInstance(AType);
  JSONToObject(Result, AJSON, AConfig);
end;

class function TNeon.JSONToObject<T>(AJSON: TJSONValue): T;
begin
  Result := JSONToObject(TRttiUtils.Context.GetType(TClass(T)), AJSON) as T;
end;

class procedure TNeon.JSONToObject(AObject: TObject; const AJSON: string; AConfig: INeonConfiguration);
var
  LJSON: TJSONValue;
begin
  LJSON := TJSONObject.ParseJSONValue(AJSON);
  try
    JSONToObject(AObject, LJSON, AConfig);
  finally
    LJSON.Free;
  end;
end;

class function TNeon.JSONToObject<T>(const AJSON: string): T;
begin
  Result := JSONToObject(TRttiUtils.Context.GetType(TClass(T)), AJSON) as T;
end;

class function TNeon.ObjectToJSON(AObject: TObject; AConfig: INeonConfiguration): TJSONValue;
var
  LWriter: TNeonSerializerJSON;
begin
  LWriter := TNeonSerializerJSON.Create(AConfig);
  try
    Result := LWriter.ObjectToJSON(AObject);
  finally
    LWriter.Free;
  end;
end;

class function TNeon.ObjectToJSONString(AObject: TObject): string;
begin
  Result := TNeon.ObjectToJSONString(AObject, TNeonConfiguration.Default);
end;

class function TNeon.ObjectToJSON(AObject: TObject): TJSONValue;
begin
  Result := TNeon.ObjectToJSON(AObject, TNeonConfiguration.Default);
end;

class function TNeon.ObjectToJSONString(AObject: TObject; AConfig: INeonConfiguration): string;
var
  LJSON: TJSONValue;
begin
  LJSON := ObjectToJSON(AObject, AConfig);
  try
    Result := Print(LJSON, AConfig.GetPrettyPrint);
  finally
    LJSON.Free;
  end;
end;

class function TNeon.Print(AJSONValue: TJSONValue; APretty: Boolean): string;
var
  LJSONString: string;
  LChar: Char;
  LOffset: Integer;
  LIndex: Integer;
  LOutsideString: Boolean;

  function Spaces(AOffset: Integer): string;
  begin
    Result := StringOfChar(#32, AOffset * 2);
  end;

begin
  if not APretty then
    Exit(AJSONValue.ToJSON);

  Result := '';
  LOffset := 0;
  LOutsideString := True;
  LJSONString := AJSONValue.ToJSON;

  for LIndex := 0 to Length(LJSONString) - 1 do
  begin
    LChar := LJSONString.Chars[LIndex];

    if LChar = '"' then
      LOutsideString := not LOutsideString;

    if LOutsideString and (LChar = '{') then
    begin
      Inc(LOffset);
      Result := Result + LChar;
      Result := Result + sLineBreak;
      Result := Result + Spaces(LOffset);
    end
    else if LOutsideString and (LChar = '}') then
    begin
      Dec(LOffset);
      Result := Result + sLineBreak;
      Result := Result + Spaces(LOffset);
      Result := Result + LChar;
    end
    else if LOutsideString and (LChar = ',') then
    begin
      Result := Result + LChar;
      Result := Result + sLineBreak;
      Result := Result + Spaces(LOffset);
    end
    else if LOutsideString and (LChar = '[') then
    begin
      Inc(LOffset);
      Result := Result + LChar;
      Result := Result + sLineBreak;
      Result := Result + Spaces(LOffset);
    end
    else if LOutsideString and (LChar = ']') then
    begin
      Dec(LOffset);
      Result := Result + sLineBreak;
      Result := Result + Spaces(LOffset);
      Result := Result + LChar;
    end
    else if LOutsideString and (LChar = ':') then
    begin
      Result := Result + LChar;
      Result := Result + ' ';
    end
    else
      Result := Result + LChar;
  end;
end;

class function TNeon.ValueToJSON(const AValue: TValue): TJSONValue;
begin
  Result := TNeon.ValueToJSON(AValue, TNeonConfiguration.Default);
end;

class function TNeon.ValueToJSON(const AValue: TValue; AConfig: INeonConfiguration): TJSONValue;
var
  LWriter: TNeonSerializerJSON;
begin
  LWriter := TNeonSerializerJSON.Create(AConfig);
  try
    Result := LWriter.ValueToJSON(AValue);
  finally
    LWriter.Free;
  end;
end;

class procedure TNeon.JSONToObject(AObject: TObject; AJSON: TJSONValue; AConfig: INeonConfiguration);
var
  LReader: TNeonDeserializerJSON;
begin
  LReader := TNeonDeserializerJSON.Create(AConfig);
  try
    LReader.JSONToObject(AObject, AJSON);
  finally
    LReader.Free;
  end;
end;

class function TNeon.JSONToObject(AType: TRttiType; const AJSON: string; AConfig: INeonConfiguration): TObject;
var
  LJSON: TJSONValue;
begin
  LJSON := TJSONObject.ParseJSONValue(AJSON);
  try
    Result := TRttiUtils.CreateInstance(AType);
    JSONToObject(Result, LJSON, AConfig);
  finally
    LJSON.Free;
  end;
end;

class function TNeon.JSONToObject<T>(AJSON: TJSONValue; AConfig: INeonConfiguration): T;
begin
  Result := JSONToObject(TRttiUtils.Context.GetType(TClass(T)), AJSON, AConfig) as T;
end;

class function TNeon.JSONToObject<T>(const AJSON: string; AConfig: INeonConfiguration): T;
begin
  Result := JSONToObject(TRttiUtils.Context.GetType(TClass(T)), AJSON, AConfig) as T;
end;

class function TNeon.JSONToValue(ARttiType: TRttiType; AJSON: TJSONValue;
  AConfig: INeonConfiguration): TValue;
var
  LDes: TNeonDeserializerJSON;
begin
  LDes := TNeonDeserializerJSON.Create(AConfig);
  try
    Result := LDes.JSONToTValue(AJSON, ARttiType);
  finally
    LDes.Free;
  end;
end;

class function TNeon.JSONToValue(ARttiType: TRttiType; AJSON: TJSONValue): TValue;
begin
  Result := JSONToValue(ARttiType, AJSON, TNeonConfiguration.Default);
end;

class function TNeon.JSONToValue<T>(AJSON: TJSONValue; AConfig: INeonConfiguration): T;
var
  LDes: TNeonDeserializerJSON;
  LValue: TValue;
begin
  LDes := TNeonDeserializerJSON.Create(AConfig);
  try
    LValue := LDes.JSONToTValue(AJSON, TRttiUtils.Context.GetType(TypeInfo(T)));
    Result := LValue.AsType<T>;
  finally
    LDes.Free;
  end;
end;

class function TNeon.JSONToValue<T>(AJSON: TJSONValue): T;
begin
  Result := JSONToValue<T>(AJSON, TNeonConfiguration.Default);
end;

end.
