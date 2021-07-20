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
unit Neon.Core.Serializers.Nullables;

interface

uses
  System.SysUtils, System.Generics.Defaults, System.Rtti, System.TypInfo, System.JSON,

  Neon.Core.Attributes,
  Neon.Core.Persistence,
  Neon.Core.Types,
  Neon.Core.Nullables,
  Neon.Core.Serializers.RTL;

type
  TNullableStringSerializer = class(TCustomSerializer)
  protected
    class function GetTargetInfo: PTypeInfo; override;
    class function CanHandle(AType: PTypeInfo): Boolean; override;
  public
    function Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue; override;
    function Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue; override;
  end;

  TNullableBooleanSerializer = class(TCustomSerializer)
  protected
    class function GetTargetInfo: PTypeInfo; override;
    class function CanHandle(AType: PTypeInfo): Boolean; override;
  public
    function Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue; override;
    function Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue; override;
  end;

  TNullableIntegerSerializer = class(TCustomSerializer)
  protected
    class function GetTargetInfo: PTypeInfo; override;
    class function CanHandle(AType: PTypeInfo): Boolean; override;
  public
    function Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue; override;
    function Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue; override;
  end;

  TNullableInt64Serializer = class(TCustomSerializer)
  protected
    class function GetTargetInfo: PTypeInfo; override;
    class function CanHandle(AType: PTypeInfo): Boolean; override;
  public
    function Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue; override;
    function Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue; override;
  end;

  TNullableDoubleSerializer = class(TCustomSerializer)
  protected
    class function GetTargetInfo: PTypeInfo; override;
    class function CanHandle(AType: PTypeInfo): Boolean; override;
  public
    function Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue; override;
    function Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue; override;
  end;

  TNullableTDateTimeSerializer = class(TCustomSerializer)
  protected
    class function GetTargetInfo: PTypeInfo; override;
    class function CanHandle(AType: PTypeInfo): Boolean; override;
  public
    function Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue; override;
    function Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue; override;
  end;

  procedure RegisterNullableSerializers(ARegistry: TNeonSerializerRegistry);
  procedure UnregisterNullableSerializers(ARegistry: TNeonSerializerRegistry);

implementation

uses
  Neon.Core.Utils;

{ TNullableStringSerializer }

class function TNullableStringSerializer.CanHandle(AType: PTypeInfo): Boolean;
begin
  if AType = GetTargetInfo then
    Result := True
  else
    Result := False;
end;

function TNullableStringSerializer.Deserialize(AValue: TJSONValue; const AData:
    TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue;
var
  LNullValue: NullString;
begin
  if AValue is TJSONString then
    LNullValue := AValue.Value
  else if AValue is TJSONNull then
    LNullValue := nil
  else
    raise ENeonException.Create(Self.ClassName + '.Deserialize: incompatible types');

  Result := TValue.From<NullString>(LNullValue);
end;

class function TNullableStringSerializer.GetTargetInfo: PTypeInfo;
begin
  Result := TypeInfo(NullString);
end;

function TNullableStringSerializer.Serialize(const AValue: TValue; ANeonObject:
    TNeonRttiObject; AContext: ISerializerContext): TJSONValue;
var
  LValue: NullString;
begin
  LValue := AValue.AsType<NullString>;

  if not LValue.HasValue then
  begin
    case ANeonObject.NeonInclude.Value of
      IncludeIf.NotNull,
      IncludeIf.NotEmpty,
      IncludeIf.NotDefault: Exit(nil);
    else
      Exit(TJSONNull.Create);
    end;
  end;

  Result := TJSONString.Create(LValue.Value);
end;

{ TNullableBooleanSerializer }

class function TNullableBooleanSerializer.CanHandle(AType: PTypeInfo): Boolean;
begin
  if AType = GetTargetInfo then
    Result := True
  else
    Result := False;
end;

function TNullableBooleanSerializer.Deserialize(AValue: TJSONValue; const
    AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue;
var
  LNullValue: NullBoolean;
begin
  if AValue is TJSONBool then
    LNullValue := (AValue as TJSONBool).AsBoolean
  else if AValue is TJSONNull then
    LNullValue := nil
  else
    raise ENeonException.Create(Self.ClassName + '.Deserialize: incompatible types');

  Result := TValue.From<NullBoolean>(LNullValue);
end;

class function TNullableBooleanSerializer.GetTargetInfo: PTypeInfo;
begin
  Result := TypeInfo(NullBoolean);
end;

function TNullableBooleanSerializer.Serialize(const AValue: TValue;
    ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue;
var
  LValue: NullBoolean;
begin
  LValue := AValue.AsType<NullBoolean>;

  if not LValue.HasValue then
  begin
    case ANeonObject.NeonInclude.Value of
      IncludeIf.NotNull   : Exit(nil);
      IncludeIf.NotEmpty  : Exit(nil);
      IncludeIf.NotDefault: Exit(nil);
    else
      Exit(TJSONNull.Create);
    end;
  end;

  Result := TJSONBool.Create(LValue.Value);
end;

{ TNullableIntegerSerializer }

class function TNullableIntegerSerializer.CanHandle(AType: PTypeInfo): Boolean;
begin
  if AType = GetTargetInfo then
    Result := True
  else
    Result := False;
end;

function TNullableIntegerSerializer.Deserialize(AValue: TJSONValue; const
    AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue;
var
  LNullValue: NullInteger;
begin
  if AValue is TJSONNumber then
    LNullValue := (AValue as TJSONNumber).AsInt
  else if AValue is TJSONNull then
    LNullValue := nil
  else
    raise ENeonException.Create(Self.ClassName + '.Deserialize: incompatible types');

  Result := TValue.From<NullInteger>(LNullValue);
end;

class function TNullableIntegerSerializer.GetTargetInfo: PTypeInfo;
begin
  Result := TypeInfo(NullInteger);
end;

function TNullableIntegerSerializer.Serialize(const AValue: TValue;
    ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue;
var
  LValue: NullInteger;
begin
  LValue := AValue.AsType<NullInteger>;

  if not LValue.HasValue then
  begin
    case ANeonObject.NeonInclude.Value of
      IncludeIf.NotNull   : Exit(nil);
      IncludeIf.NotEmpty  : Exit(nil);
      IncludeIf.NotDefault: Exit(nil);
    else
      Exit(TJSONNull.Create);
    end;
  end;

  Result := TJSONNumber.Create(LValue.Value);
end;

{ TNullableInt64Serializer }

class function TNullableInt64Serializer.CanHandle(AType: PTypeInfo): Boolean;
begin
  if AType = GetTargetInfo then
    Result := True
  else
    Result := False;
end;

function TNullableInt64Serializer.Deserialize(AValue: TJSONValue; const AData: TValue;
    ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue;
var
  LNullValue: NullInt64;
begin
  if AValue is TJSONNumber then
    LNullValue := (AValue as TJSONNumber).AsInt64
  else if AValue is TJSONNull then
    LNullValue := nil
  else
    raise ENeonException.Create(Self.ClassName + '.Deserialize: incompatible types');

  Result := TValue.From<NullInt64>(LNullValue);
end;

class function TNullableInt64Serializer.GetTargetInfo: PTypeInfo;
begin
  Result := TypeInfo(NullInt64);
end;

function TNullableInt64Serializer.Serialize(const AValue: TValue; ANeonObject:
    TNeonRttiObject; AContext: ISerializerContext): TJSONValue;
var
  LValue: NullInt64;
begin
  LValue := AValue.AsType<NullInt64>;

  if not LValue.HasValue then
  begin
    case ANeonObject.NeonInclude.Value of
      IncludeIf.NotNull   : Exit(nil);
      IncludeIf.NotEmpty  : Exit(nil);
      IncludeIf.NotDefault: Exit(nil);
    else
      Exit(TJSONNull.Create);
    end;
  end;

  Result := TJSONNumber.Create(LValue.Value);
end;

{ TNullableDoubleSerializer }

class function TNullableDoubleSerializer.CanHandle(AType: PTypeInfo): Boolean;
begin
  if AType = GetTargetInfo then
    Result := True
  else
    Result := False;
end;

function TNullableDoubleSerializer.Deserialize(AValue: TJSONValue; const AData: TValue;
    ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue;
var
  LNullValue: NullDouble;
begin
  if AValue is TJSONNumber then
    LNullValue := (AValue as TJSONNumber).AsDouble
  else if AValue is TJSONNull then
    LNullValue := nil
  else
    raise ENeonException.Create(Self.ClassName + '.Deserialize: incompatible types');

  Result := TValue.From<NullDouble>(LNullValue);
end;

class function TNullableDoubleSerializer.GetTargetInfo: PTypeInfo;
begin
  Result := TypeInfo(NullDouble);
end;

function TNullableDoubleSerializer.Serialize(const AValue: TValue; ANeonObject:
    TNeonRttiObject; AContext: ISerializerContext): TJSONValue;
var
  LValue: NullDouble;
begin
  LValue := AValue.AsType<NullDouble>;

  if not LValue.HasValue then
  begin
    case ANeonObject.NeonInclude.Value of
      IncludeIf.NotNull   : Exit(nil);
      IncludeIf.NotEmpty  : Exit(nil);
      IncludeIf.NotDefault: Exit(nil);
    else
      Exit(TJSONNull.Create);
    end;
  end;

  Result := TJSONNumber.Create(LValue.Value);
end;

{ TNullableTDateTimeSerializer }

class function TNullableTDateTimeSerializer.CanHandle(AType: PTypeInfo): Boolean;
begin
  if AType = GetTargetInfo then
    Result := True
  else
    Result := False;
end;

function TNullableTDateTimeSerializer.Deserialize(AValue: TJSONValue; const AData: TValue;
    ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue;
var
  LNullValue: NullDateTime;
begin
  if AValue is TJSONString then
    LNullValue := TJSONUtils.JSONToDate(AValue.Value, AContext.GetConfiguration.GetUseUTCDate)
  else if AValue is TJSONNull then
    LNullValue := nil
  else
    raise ENeonException.Create(Self.ClassName + '.Deserialize: incompatible types');

  Result := TValue.From<NullDateTime>(LNullValue);
end;

class function TNullableTDateTimeSerializer.GetTargetInfo: PTypeInfo;
begin
  Result := TypeInfo(NullDateTime);
end;

function TNullableTDateTimeSerializer.Serialize(const AValue: TValue;
    ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue;
var
  LValue: NullDateTime;
begin
  LValue := AValue.AsType<NullDateTime>;

  if not LValue.HasValue then
  begin
    case ANeonObject.NeonInclude.Value of
      IncludeIf.NotNull   : Exit(nil);
      IncludeIf.NotEmpty  : Exit(nil);
      IncludeIf.NotDefault: Exit(nil);
    else
      Exit(TJSONNull.Create);
    end;
  end;

  Result := TJSONString.Create(TJSONUtils.DateToJSON(LValue.Value, AContext.GetConfiguration.GetUseUTCDate))
end;

procedure RegisterNullableSerializers(ARegistry: TNeonSerializerRegistry);
begin
  ARegistry.RegisterSerializer(TNullableStringSerializer);
  ARegistry.RegisterSerializer(TNullableBooleanSerializer);
  ARegistry.RegisterSerializer(TNullableIntegerSerializer);
  ARegistry.RegisterSerializer(TNullableInt64Serializer);
  ARegistry.RegisterSerializer(TNullableDoubleSerializer);
  ARegistry.RegisterSerializer(TNullableTDateTimeSerializer);
end;

procedure UnregisterNullableSerializers(ARegistry: TNeonSerializerRegistry);
begin
  ARegistry.UnregisterSerializer(TNullableStringSerializer);
  ARegistry.UnregisterSerializer(TNullableBooleanSerializer);
  ARegistry.UnregisterSerializer(TNullableIntegerSerializer);
  ARegistry.UnregisterSerializer(TNullableInt64Serializer);
  ARegistry.UnregisterSerializer(TNullableDoubleSerializer);
  ARegistry.UnregisterSerializer(TNullableTDateTimeSerializer);
end;

end.
