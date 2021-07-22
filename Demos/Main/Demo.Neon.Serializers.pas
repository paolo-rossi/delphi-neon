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
unit Demo.Neon.Serializers;

interface

uses
  System.SysUtils, System.Classes, System.Rtti, System.SyncObjs, System.TypInfo,
  System.Generics.Collections, System.Math.Vectors, System.JSON, Vcl.Graphics,

  Demo.Neon.Entities,
  Neon.Core.Types,
  Neon.Core.Attributes,
  Neon.Core.Persistence;

type
  /// <summary>
  ///   Sample custom serializer for the TPoint3D record type
  /// </summary>
  TPoint3DSerializer = class(TCustomSerializer)
  protected
    class function GetTargetInfo: PTypeInfo; override;
    class function CanHandle(AType: PTypeInfo): Boolean; override;
  public
    function Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue; override;
    function Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue; override;
  end;

  /// <summary>
  ///   Sample custom serializer for the TParameterContainer class. Here I
  ///   wanted to serialize only one part of the class based on the value of
  ///   some property
  /// </summary>
  TParameterSerializer = class(TCustomSerializer)
  protected
    class function GetTargetInfo: PTypeInfo; override;
    class function CanHandle(AType: PTypeInfo): Boolean; override;
  public
    function Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue; override;
    function Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue; override;
  end;

  /// <summary>
  ///   Sample custom serializer for the standard TFont class
  /// </summary>
  TFontSerializer = class(TCustomSerializer)
  protected
    class function GetTargetInfo: PTypeInfo; override;
    class function CanHandle(AType: PTypeInfo): Boolean; override;
  public
    function Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue; override;
    function Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue; override;
  end;

  /// <summary>
  ///   Sample serializer for a class. You completely customize the
  ///   serialization and deserialization of a specific class
  /// </summary>
  TCaseClassSerializer = class(TCustomSerializer)
  protected
    class function GetTargetInfo: PTypeInfo; override;
    class function CanHandle(AType: PTypeInfo): Boolean; override;
  public
    function Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue; override;
    function Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue; override;
  end;

  /// <summary>
  ///   Sample serializer for TTime (not TDateTime). It's possible to register
  ///   custom serializer for every type (TypeInfo record) Delphi has.
  /// </summary>
  TTimeSerializer = class(TCustomSerializer)
  protected
    class function GetTargetInfo: PTypeInfo; override;
    class function CanHandle(AType: PTypeInfo): Boolean; override;
  public
    function Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue; override;
    function Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue; override;
  end;

  /// <summary>
  ///   Delphi, not having (yet) nullable types, makes hard to deal with null
  ///   values found in JSON, and the TDateTime is the most "controversial"
  ///   type of all. The simplest solution would be to create and register a
  ///   custom serializer for the TDateTime type and in here write all code you
  ///   want.
  /// </summary>
  TDateTimeSerializer = class(TCustomSerializer)
  protected
    class function GetTargetInfo: PTypeInfo; override;
    class function CanHandle(AType: PTypeInfo): Boolean; override;
  public
    function Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue; override;
    function Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue; override;
  end;


  /// <summary>
  ///   If you have "some" DateTime that you want to manage differently from
  ///   the standard you can create a custom TDateTime (simply as a type alias)
  ///   type and register a custom serializer for it
  /// </summary>
  TCustomDateSerializer = class(TCustomSerializer)
  protected
    class function GetTargetInfo: PTypeInfo; override;
    class function CanHandle(AType: PTypeInfo): Boolean; override;
  public
    function Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue; override;
    function Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue; override;
  end;

implementation

uses
  System.DateUtils,
  Neon.Core.Utils;

{ TPoint3DSerializer }

class function TPoint3DSerializer.GetTargetInfo: PTypeInfo;
begin
  Result := TypeInfo(TPoint3D);
end;

function TPoint3DSerializer.Serialize(const AValue: TValue; ANeonObject:
    TNeonRttiObject; AContext: ISerializerContext): TJSONValue;
var
  LVal: TPoint3D;
  LJSON: TJSONObject;
begin
  LVal := AValue.AsType<TPoint3D>;
  LJSON := TJSONObject.Create;
  LJSON.AddPair('X', TJSONNumber.Create(LVal.X));
  LJSON.AddPair('Y', TJSONNumber.Create(LVal.Y));
  LJSON.AddPair('Z', TJSONNumber.Create(LVal.Z));
  Result := LJSON;
end;

class function TPoint3DSerializer.CanHandle(AType: PTypeInfo): Boolean;
begin
  Result := AType = TypeInfo(TPoint3D);
end;

function TPoint3DSerializer.Deserialize(AValue: TJSONValue; const AData:
    TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue;
var
  LVal: TPoint3D;
begin
  LVal.X := AValue.GetValue<Double>('X');
  LVal.Y := AValue.GetValue<Double>('Y');
  LVal.Z := AValue.GetValue<Double>('Z');

  Result := TValue.From<TPoint3D>(LVal);
end;

{ TParameterSerializer }

class function TParameterSerializer.GetTargetInfo: PTypeInfo;
begin
  Result := TParameterContainer.ClassInfo;
end;

function TParameterSerializer.Serialize(const AValue: TValue; ANeonObject:
    TNeonRttiObject; AContext: ISerializerContext): TJSONValue;
var
  LParam: TParameterContainer;
  LType: TRttiType;
begin
  LParam := AValue.AsType<TParameterContainer>;

  if Assigned(Lparam.ref) then
    Result := AContext.WriteDataMember(LParam.ref)
  else
  begin
    LType := TRttiUtils.Context.GetType(AValue.TypeInfo);
    Result := TJSONObject.Create;
    AContext.WriteMembers(LType, LParam, Result);
  end;
end;

class function TParameterSerializer.CanHandle(AType: PTypeInfo): Boolean;
begin
  Result := TypeInfoIs(AType);
end;

function TParameterSerializer.Deserialize(AValue: TJSONValue; const AData:
    TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue;
var
  LVal: TParameterContainer;
  LType: TRttiType;
  LPData: Pointer;
begin
  LVal := AData.AsType<TParameterContainer>;

  if Assigned((AValue as TJSONObject).GetValue('$ref')) then
  begin
    LType := TRttiUtils.Context.GetType(TReference);
    AContext.ReadDataMember(AValue, LType, LVal.ref);
  end
  else
  begin
    LPData := AData.AsObject;
    LType := TRttiUtils.Context.GetType(TParameterContainer);
    AContext.ReadMembers(LType, LPData, AValue as TJSONObject);
  end;

  Result := TValue.From<TParameterContainer>(LVal);
end;

{ TFontSerializer }

class function TFontSerializer.GetTargetInfo: PTypeInfo;
begin
  Result := TFont.ClassInfo;
end;

function TFontSerializer.Serialize(const AValue: TValue; ANeonObject:
    TNeonRttiObject; AContext: ISerializerContext): TJSONValue;
var
  LFont: TFont;
  LJSON: TJSONObject;
begin
  LFont := AValue.AsType<TFont>;

  LJSON := TJSONObject.Create;
  LJSON.AddPair('Name', LFont.Name);
  LJSON.AddPair('Orientation', TJSONNumber.Create(LFont.Orientation));
  LJSON.AddPair('Pitch', AContext.WriteDataMember(TValue.From<TFontPitch>(LFont.Pitch)));
  LJSON.AddPair('Size', TJSONNumber.Create(LFont.Size));

  Result := LJSON;
end;

class function TFontSerializer.CanHandle(AType: PTypeInfo): Boolean;
begin
  Result := TypeInfoIs(AType);
end;

function TFontSerializer.Deserialize(AValue: TJSONValue; const AData: TValue;
    ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue;
var
  LJSONObject: TJSONObject;
  LJSONValue: TJSONValue;
  LFont: TFont;
begin
  if not (AValue is TJSONObject) then
    raise ENeonException.Create('TFontSerializer.Deserialize: JSON does not represent an object');

  if AData.IsEmpty then
    LFont := TFont.Create
  else
    LFont := AData.AsType<TFont>;

  LJSONObject := AValue as TJSONObject;

  LJSONValue := LJSONObject.GetValue('Name');
  if Assigned(LJSONValue) then
    LFont.Name := LJSONValue.Value;

  LJSONValue := LJSONObject.GetValue('Orientation');
  if Assigned(LJSONValue) then
    LFont.Orientation := (LJSONValue as TJSONNumber).AsInt;

  LJSONValue := LJSONObject.GetValue('Size');
  if Assigned(LJSONValue) then
    LFont.Size := (LJSONValue as TJSONNumber).AsInt;

  Result := TValue.From<TFont>(LFont);
end;

{ TCaseClassSerializer }

class function TCaseClassSerializer.CanHandle(AType: PTypeInfo): Boolean;
begin
  Result := TypeInfoIs(AType);
end;

function TCaseClassSerializer.Deserialize(AValue: TJSONValue; const AData:
    TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue;
var
  LJSONObject: TJSONObject;
  LJSONValue: TJSONValue;
  LVal: TCaseClass;
  LType: TRttiType;
begin

  if AData.IsEmpty then
    LVal := TCaseClass.Create
  else
    LVal := AData.AsType<TCaseClass>;

  LJSONObject := AValue as TJSONObject;

  LJSONValue := LJSONObject.GetValue('First');
  if Assigned(LJSONValue) then
    LVal.FirstProp := (LJSONValue as TJSONNumber).AsInt;

  LJSONValue := LJSONObject.GetValue('Second');
  if Assigned(LJSONValue) then
    LVal.SecondXProp := LJSONValue.Value;

  LJSONValue := LJSONObject.GetValue('Note');
  if Assigned(LJSONValue) then
  begin
    LType := TRttiUtils.Context.GetType(TNote);
    AContext.ReadDataMember(LJSONValue, LType, LVal.Note);
  end;

  Result := TValue.From<TCaseClass>(LVal);
end;

class function TCaseClassSerializer.GetTargetInfo: PTypeInfo;
begin
  Result := TCaseClass.ClassInfo;
end;

function TCaseClassSerializer.Serialize(const AValue: TValue; ANeonObject:
    TNeonRttiObject; AContext: ISerializerContext): TJSONValue;
var
  LObj: TCaseClass;
  LJSON: TJSONObject;
begin
  LObj := AValue.AsType<TCaseClass>;

  LJSON := TJSONObject.Create;
  LJSON.AddPair('First', TJSONNumber.Create(LObj.FirstProp));
  LJSON.AddPair('Second', LObj.SecondXProp);
  LJSON.AddPair('Note', AContext.WriteDataMember(TValue.From<TNote>(LObj.Note)));

  Result := LJSON;
end;

{ TTimeSerializer }

class function TTimeSerializer.GetTargetInfo: PTypeInfo;
begin
  Result := TypeInfo(TTime);
end;

function TTimeSerializer.Serialize(const AValue: TValue; ANeonObject:
    TNeonRttiObject; AContext: ISerializerContext): TJSONValue;
var
  LTime: TTime;
  LHours, LMinutes, LSeconds, LMilli: Word;
begin
  LTime := AValue.AsType<TTime>;
  DecodeTime(LTime, LHours, LMinutes, LSeconds, LMilli);
  Result := TJSONString.Create(Format('%.2d:%.2d:%.2d', [LHours, LMinutes, LSeconds]));
end;

class function TTimeSerializer.CanHandle(AType: PTypeInfo): Boolean;
begin
  if AType = GetTargetInfo then
    Result := True
  else
    Result := False;
end;

function TTimeSerializer.Deserialize(AValue: TJSONValue; const AData: TValue;
    ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue;
var
  LTime: TTime;
begin
  LTime := StrToTime(AValue.Value);
  Result := TValue.From<TTime>(LTime);
end;

{ TCustomDateSerializer }

class function TCustomDateSerializer.CanHandle(AType: PTypeInfo): Boolean;
begin
  if AType = GetTargetInfo then
    Result := True
  else
    Result := False;
end;

function TCustomDateSerializer.Deserialize(AValue: TJSONValue;
  const AData: TValue; ANeonObject: TNeonRttiObject;
  AContext: IDeserializerContext): TValue;
var
  LDate: TCustomDate;
  LFormats: TFormatSettings;
begin
  LFormats := TFormatSettings.Create;
  LFormats.DateSeparator := '|';
  LFormats.ShortDateFormat := 'yyyy|mm|dd';
  LDate := StrToDate(AValue.Value, LFormats);
  Result := TValue.From<TCustomDate>(LDate);
end;

class function TCustomDateSerializer.GetTargetInfo: PTypeInfo;
begin
  Result := System.TypeInfo(TCustomDate);
end;

function TCustomDateSerializer.Serialize(const AValue: TValue;
  ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue;
var
  LDate: TCustomDate;
  LYear, LMonth, LDay: Word;
begin
  LDate := AValue.AsType<TCustomDate>;
  DecodeDate(LDate, LYear, LMonth, LDay);
  Result := TJSONString.Create(Format('%d|%.2d|%.2d', [LYear, LMonth, LDay]));
end;

{ TDateTimeSerializer }

class function TDateTimeSerializer.CanHandle(AType: PTypeInfo): Boolean;
begin
  Result := AType = GetTargetInfo;
end;

function TDateTimeSerializer.Deserialize(AValue: TJSONValue;
  const AData: TValue; ANeonObject: TNeonRttiObject;
  AContext: IDeserializerContext): TValue;
var
  LDate: TDateTime;
begin
  // Here if you want you can test for special date values and act accordingly
  if AValue is TJSONNull then
    Exit(0);

  LDate := StrToDate(AValue.Value);
  Result := TValue.From<TDateTime>(LDate);
end;

class function TDateTimeSerializer.GetTargetInfo: PTypeInfo;
begin
  Result := System.TypeInfo(TDateTime);
end;

function TDateTimeSerializer.Serialize(const AValue: TValue;
  ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue;
var
  LDate: TDateTime;
begin
  LDate := AValue.AsType<TDateTime>;

  // Here if you want you can test for special date values and act accordingly
  if LDate = 0 then
    Exit(TJSONNull.Create);

  // This is where you customize the date serialization format
  Result := TJSONString.Create(DateTimeToStr(LDate));
end;

end.
