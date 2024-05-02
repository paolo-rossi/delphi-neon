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
unit Neon.Core.Serializers.RTL;

interface

uses
  System.SysUtils, System.Classes, System.Rtti, System.SyncObjs, System.TypInfo,
  System.Generics.Collections, System.Math.Vectors, System.JSON,

  Neon.Core.Types,
  Neon.Core.Attributes,
  Neon.Core.Persistence;

type
  /// <summary>
  ///   Custom serializer for the TGUID record type. It serialize the GUID in
  ///   the canonical form: 'C4A22FDD-443F-4737-AA7D-2323F635E207'
  /// </summary>
  TGUIDSerializer = class(TCustomSerializer)
  protected
    class function GetTargetInfo: PTypeInfo; override;
    class function CanHandle(AType: PTypeInfo): Boolean; override;
  public
    function Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue; override;
    function Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue; override;
  end;

  /// <summary>
  ///   Custom serializer for the TStream (and descendant) class. It serializes
  ///   the stream as Base64
  /// </summary>
  TStreamSerializer = class(TCustomSerializer)
  protected
    class function GetTargetInfo: PTypeInfo; override;
    class function CanHandle(AType: PTypeInfo): Boolean; override;
  public
    function Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue; override;
    function Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue; override;
  end;

  /// <summary>
  ///   Custom serializer for the TJSONValue class. Clones the JSON object or
  ///   array
  /// </summary>
  TJSONValueSerializer = class(TCustomSerializer)
  protected
    class function GetTargetInfo: PTypeInfo; override;
    class function CanHandle(AType: PTypeInfo): Boolean; override;
  public
    function Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue; override;
    function Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue; override;
  end;

  /// <summary>
  ///   Custom serializer for the TValue record.
  /// </summary>
  TTValueSerializer = class(TCustomSerializer)
  protected
    class function GetTargetInfo: PTypeInfo; override;
    class function CanHandle(AType: PTypeInfo): Boolean; override;
  public
    function Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue; override;
    function Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue; override;
  end;

  /// <summary>
  ///   Custom serializer for the TBytes type. It allows to serialize TBytes as
  ///   Base64 using NeonFormat attribute
  /// </summary>
  TBytesSerializer = class(TCustomSerializer)
  private
    function IsFormatValue(AFormat: NeonFormatAttribute; const AValue: string): Boolean; inline;

    function ValueAsBase64(const AValue: TJSONValue): TValue; inline;
  protected
    class function GetTargetInfo: PTypeInfo; override;
    class function CanHandle(AType: PTypeInfo): Boolean; override;
  public
    function Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue; override;
    function Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue; override;
  end;


procedure RegisterDefaultSerializers(ARegistry: TNeonSerializerRegistry);

implementation

uses
  Neon.Core.Utils;

procedure RegisterDefaultSerializers(ARegistry: TNeonSerializerRegistry);
begin
  ARegistry.RegisterSerializer(TGUIDSerializer);
  ARegistry.RegisterSerializer(TBytesSerializer);
  ARegistry.RegisterSerializer(TStreamSerializer);
  ARegistry.RegisterSerializer(TJSONValueSerializer);
end;

{ TGUIDSerializer }

class function TGUIDSerializer.GetTargetInfo: PTypeInfo;
begin
  Result := TypeInfo(TGUID);
end;

function TGUIDSerializer.Serialize(const AValue: TValue; ANeonObject:
    TNeonRttiObject; AContext: ISerializerContext): TJSONValue;
var
  LGUID: TGUID;
begin
  LGUID := AValue.AsType<TGUID>;
  Result := TJSONString.Create(Format('%.8x-%.4x-%.4x-%.2x%.2x-%.2x%.2x%.2x%.2x%.2x%.2x',
    [LGUID.D1, LGUID.D2, LGUID.D3, LGUID.D4[0], LGUID.D4[1], LGUID.D4[2],
     LGUID.D4[3], LGUID.D4[4], LGUID.D4[5], LGUID.D4[6], LGUID.D4[7]])
    );
end;

class function TGUIDSerializer.CanHandle(AType: PTypeInfo): Boolean;
begin
  if AType = GetTargetInfo then
    Result := True
  else
    Result := False;
end;

function TGUIDSerializer.Deserialize(AValue: TJSONValue; const AData: TValue;
    ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue;
var
  LGUID: TGUID;
begin
  LGUID := StringToGUID(Format('{%s}', [AValue.Value]));
  Result := TValue.From<TGUID>(LGUID);
end;

{ TStreamSerializer }

class function TStreamSerializer.GetTargetInfo: PTypeInfo;
begin
  Result := TStream.ClassInfo;
end;

class function TStreamSerializer.CanHandle(AType: PTypeInfo): Boolean;
begin
  Result := TypeInfoIs(AType);
end;

function TStreamSerializer.Serialize(const AValue: TValue;
  ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue;
var
  LStream: TStream;
  LBase64: string;
begin
  LStream := AValue.AsObject as TStream;

  if LStream.Size = 0 then
  begin
    case ANeonObject.NeonInclude.Value of
      IncludeIf.NotEmpty, IncludeIf.NotDefault: Exit(nil);
    else
      Exit(TJSONString.Create(''));
    end;
  end;

  LStream.Position := soFromBeginning;
  LBase64 := TBase64.Encode(LStream);
  Result := TJSONString.Create(LBase64);
end;

function TStreamSerializer.Deserialize(AValue: TJSONValue; const AData: TValue;
  ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue;
var
  LStream: TStream;
begin
  Result := AData;
  LStream := AData.AsObject as TStream;
  LStream.Position := soFromBeginning;

  TBase64.Decode(AValue.Value, LStream);
end;

{ TJSONValueSerializer }

class function TJSONValueSerializer.CanHandle(AType: PTypeInfo): Boolean;
begin
  Result := TypeInfoIs(AType);
end;

function TJSONValueSerializer.Deserialize(AValue: TJSONValue;
  const AData: TValue; ANeonObject: TNeonRttiObject;
  AContext: IDeserializerContext): TValue;
var
  LJSONData: TJSONValue;
  LPair: TJSONPair;
  LValue: TJSONValue;
begin
  Result := AData;
  LJSONData := Result.AsObject as TJSONValue;

  // Check the TypeInfo of AData as TJSONValue and AValue
  if not (LJSONData.ClassType = AValue.ClassType) then
  begin
    AContext.LogError(Format('TJSONValueSerializer: %s and %s not compatible',
      [LJSONData.ClassName, AValue.ClassName]));
    Exit;
  end;

  if LJSONData is TJSONObject then
    for LPair in (AValue as TJSONObject) do
      (LJSONData as TJSONObject).AddPair(LPair.Clone as TJSONPair)

  else if LJSONData is TJSONArray then
    for LValue in (AValue as TJSONArray) do
      (LJSONData as TJSONArray).AddElement(LValue.Clone as TJSONValue)

  {
  else if LJSONData is TJSONString then
    (LJSONData as TJSONString). Value := (AValue as TJSONString).Value

  else if LJSONData is TJSONNumber then
    (LJSONData as TJSONNumber).Value := (AValue as TJSONNumber).Value

  else if LJSONData is TJSONBool then
    (LJSONData as TJSONString).Value := (AValue as TJSONString).Value

  else if LJSONData is TJSONNull then
    (LJSONData as TJSONString).Value := (AValue as TJSONString).Value
  }
end;

class function TJSONValueSerializer.GetTargetInfo: PTypeInfo;
begin
  Result := TJSONValue.ClassInfo;
end;

function TJSONValueSerializer.Serialize(const AValue: TValue;
  ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue;
var
  LOriginalJSON: TJSONValue;
  LEmpty: Boolean;
begin
  LEmpty := False;

  LOriginalJSON := AValue.AsObject as TJSONValue;

  if LOriginalJSON is TJSONObject then
    LEmpty := (LOriginalJSON as TJSONObject).Count = 0;

  if LOriginalJSON is TJSONArray then
    LEmpty := (LOriginalJSON as TJSONArray).Count = 0;

  if LEmpty then
    case ANeonObject.NeonInclude.Value of
      IncludeIf.NotNull:    Exit(nil);
      IncludeIf.NotEmpty:   Exit(nil);
      IncludeIf.NotDefault: Exit(nil);
    end;

  Exit(LOriginalJSON.Clone as TJSONValue);
end;

{ TTValueSerializer }

class function TTValueSerializer.CanHandle(AType: PTypeInfo): Boolean;
begin
  Result := AType = GetTargetInfo;
end;

function TTValueSerializer.Deserialize(AValue: TJSONValue; const AData: TValue;
  ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue;
var
  LType: TRttiType;
  LValue: TValue;
begin
  LValue := TValue.Empty;

  if AValue is TJSONNumber then
  begin
    LType := TRttiUtils.Context.GetType(TypeInfo(Double));
    LValue := AContext.ReadDataMember(AValue, LType, AData, False);
  end
  else if AValue is TJSONString then
  begin
    LType := TRttiUtils.Context.GetType(TypeInfo(string));
    LValue := AContext.ReadDataMember(AValue, LType, AData, False);
  end
  else if TJSONUtils.IsBool(AValue) then
  begin
    LType := TRttiUtils.Context.GetType(TypeInfo(Boolean));
    LValue := AContext.ReadDataMember(AValue, LType, AData, False);
  end;

  Result := LValue;
end;

class function TTValueSerializer.GetTargetInfo: PTypeInfo;
begin
  Result := TypeInfo(TValue);
end;

function TTValueSerializer.Serialize(const AValue: TValue;
  ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue;
begin
  if AValue.Kind = tkRecord then
    Result := AContext.WriteDataMember(AValue.AsType<TValue>, False)
  else
    Result := nil;
end;

{ TBytesSerializer }

class function TBytesSerializer.CanHandle(AType: PTypeInfo): Boolean;
begin
  Result := AType = TypeInfo(TBytes);
end;

function TBytesSerializer.Deserialize(AValue: TJSONValue; const AData: TValue;
  ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue;
var
  LType: TRttiType;
  LFormat: NeonFormatAttribute;
begin
  LFormat := ANeonObject.GetAttribute<NeonFormatAttribute>;
  if IsFormatValue(LFormat, 'native') then
  begin
    LType := TRttiUtils.Context.GetType(TypeInfo(TBytes));
    Exit(AContext.ReadDataMember(AValue, LType, AData, False));
  end;

  //if IsFormatValue(LFormat, 'base64') then
  Result := ValueAsBase64(AValue);
end;

function TBytesSerializer.IsFormatValue(AFormat: NeonFormatAttribute; const AValue: string): Boolean;
begin
  if not Assigned(AFormat) then
    Exit(False);

  Result := AFormat.IsValue(AValue);
end;

class function TBytesSerializer.GetTargetInfo: PTypeInfo;
begin
  Result := TypeInfo(TBytes);
end;

function TBytesSerializer.Serialize(const AValue: TValue;
  ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue;
var
  LVal: TBytes;
  LFormat: NeonFormatAttribute;
begin
  LVal := AValue.AsType<TBytes>;
  LFormat := ANeonObject.GetAttribute<NeonFormatAttribute>;

  if IsFormatValue(LFormat, 'native') then
    Exit(AContext.WriteDataMember(AValue, False));

  //if IsFormatValue(LFormat, 'base64') then
  Exit(TJSONString.Create(TBase64.Encode(LVal)));
end;

function TBytesSerializer.ValueAsBase64(const AValue: TJSONValue): TValue;
var
  LVal: TBytes;
begin
  if not (AValue is TJSONString) then
    raise ENeonException.Create('JSONValue must be a string');

  LVal := TBase64.Decode(AValue.Value);
  Result := TValue.From<TBytes>(LVal);
end;

end.
