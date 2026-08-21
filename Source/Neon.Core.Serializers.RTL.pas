{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
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
    function SerializeSchema(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject; override;
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
    /// <summary>
    ///   Deserialize returns a clone of the JSON it is given, so it does not
    ///   need an instance to read into and a TJSONValue member works without
    ///   AutoCreate or [NeonAutoCreate]
    /// </summary>
    class function NeedsInstance: Boolean; override;
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
    function SerializeSchema(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject; override;
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
    function SerializeSchema(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject; override;
  end;

  /// <summary>
  ///   Custom serializer for the TCollection class.
  ///   Adds to the config for the TCollectionItem some exclusions
  /// </summary>
  TCollectionSerializer = class(TCustomSerializer)
  protected
    class function GetTargetInfo: PTypeInfo; override;
    class function CanHandle(AType: PTypeInfo): Boolean; override;
  public
    class procedure ChangeConfig(AConfig: INeonConfiguration); override;
    function Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue; override;
    function Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue; override;
    function SerializeSchema(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject; override;
  end;


/// <summary>
///   Registers every serializer in this unit. <b>Nothing in the library calls
///   it</b>: a configuration starts with an empty registry, so this is the
///   consumer's call to make - see the "Custom Serializers" section of the
///   README for what each type serializes as when it is not registered
/// </summary>
/// <remarks>
///   Neon.Core.Serializers.DB declares a procedure with the same name, so
///   qualify the call with the unit name when both units are in scope.
///   Registering into the registry skips TCustomSerializer.ChangeConfig, which
///   TCollectionSerializer needs: register that one (or all of them) through
///   INeonConfiguration.RegisterSerializer instead
/// </remarks>
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
  ARegistry.RegisterSerializer(TCollectionSerializer);
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

function TGUIDSerializer.SerializeSchema(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
begin
  // The serializer writes the canonical textual form of the GUID, so without
  // this hook the generator would describe the record as an object of its D1/
  // D2/D3/D4 fields. "uuid" is the de-facto format for it (annotation-only in
  // 2020-12, harmless in older drafts)
  Result := TJSONObject.Create
    .AddPair('type', 'string')
    .AddPair('format', 'uuid');
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

class function TJSONValueSerializer.NeedsInstance: Boolean;
begin
  Result := False;
end;

function TJSONValueSerializer.Deserialize(AValue: TJSONValue;
  const AData: TValue; ANeonObject: TNeonRttiObject;
  AContext: IDeserializerContext): TValue;
var
  LJSONData: TJSONValue;
  LPair: TJSONPair;
  LValue: TJSONValue;
  LTargetClass: TClass;
  LMemberType: TRttiType;
begin
  Result := AData;

  LJSONData := nil;
  if AData.IsObject then
    LJSONData := AData.AsObject as TJSONValue;

  // The instance the caller passed to JSONToObject cannot be replaced: there is
  // no reference to update and the entry point discards the result, so the JSON
  // is merged into it - the only thing this serializer used to do, for every
  // target. Note that the merge appends: reading two documents into the same
  // instance keeps the pairs of both
  if Assigned(LJSONData) and AContext.IsOriginalInstance(AData) then
  begin
    if LJSONData.ClassType <> AValue.ClassType then
    begin
      AContext.LogError(Format(SNeonErrorSerializerIncompatibleF2, [LJSONData.ClassName, AValue.ClassName]));
      Exit;
    end;

    if LJSONData is TJSONObject then
      for LPair in (AValue as TJSONObject) do
        (LJSONData as TJSONObject).AddPair(LPair.Clone as TJSONPair)

    else if LJSONData is TJSONArray then
      for LValue in (AValue as TJSONArray) do
        (LJSONData as TJSONArray).AddElement(LValue.Clone as TJSONValue);

    Exit;
  end;

  // Everywhere else the target simply takes a clone of the JSON it is read
  // from, whatever its kind: the mirror image of Serialize, which clones
  // whatever it is given. Merging into the instance could only ever work for an
  // object or an array of the exact same class, left a nil member untouched,
  // and appended the same pairs again on a second read
  LTargetClass := TJSONValue;
  if ANeonObject is TNeonRttiMember then
  begin
    LMemberType := TNeonRttiMember(ANeonObject).RttiType;
    if LMemberType is TRttiInstanceType then
      LTargetClass := TRttiInstanceType(LMemberType).MetaclassType;
  end
  else if Assigned(LJSONData) then
    LTargetClass := LJSONData.ClassType;

  // A TJSONString cannot be stored in a TJSONObject member: say so instead of
  // letting the assignment fail with an unrelated cast error
  if not AValue.InheritsFrom(LTargetClass) then
  begin
    AContext.LogError(Format(SNeonErrorSerializerIncompatibleF2, [LTargetClass.ClassName, AValue.ClassName]));
    Exit;
  end;

  Result := AValue.Clone as TJSONValue;

  // Neon is replacing the value the target holds, so it disposes of the
  // instance it replaces: leaving it behind would leak it
  LJSONData.Free;
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

  if not Assigned(LOriginalJSON) then
    case ANeonObject.NeonInclude.Value of
      IncludeIf.NotNull:    Exit(nil);
      IncludeIf.NotEmpty:   Exit(nil);
      IncludeIf.NotDefault: Exit(nil);
    end;

  if LOriginalJSON is TJSONObject then
    LEmpty := (LOriginalJSON as TJSONObject).Count = 0;

  if LOriginalJSON is TJSONArray then
    LEmpty := (LOriginalJSON as TJSONArray).Count = 0;

  if LEmpty then
    case ANeonObject.NeonInclude.Value of
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
var
  LValue: TValue;
begin
  Result := nil;

  if AValue.TypeInfo = TypeInfo(TValue) then
  begin
    LValue := AValue.AsType<TValue>;
    if not Assigned(TRttiUtils.Context.GetType(LValue.TypeInfo)) then
      Exit(nil);

    Result := AContext.WriteDataMember(AValue.AsType<TValue>, False)
  end;
end;

function TTValueSerializer.SerializeSchema(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
begin
  // A TValue member is written as whatever its inner value serializes to,
  // which is unknowable from the declared type: the empty schema admits it all
  Result := TJSONObject.Create;
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

  if Length(LVal) = 0 then
  begin
    case ANeonObject.NeonInclude.Value of
      IncludeIf.NotEmpty, IncludeIf.NotDefault: Exit(nil);
    else
      Exit(TJSONString.Create(''));
    end;
  end;

  if IsFormatValue(LFormat, 'native') then
    Exit(AContext.WriteDataMember(AValue, False));

  //if IsFormatValue(LFormat, 'base64') then
  Exit(TJSONString.Create(TBase64.Encode(LVal)));
end;

function TBytesSerializer.SerializeSchema(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
var
  LFormat: NeonFormatAttribute;
begin
  // Mirror Serialize: with [NeonFormat('native')] the byte array is written
  // as-is, otherwise as a Base64 string (like a stream)
  LFormat := ANeonObject.GetAttribute<NeonFormatAttribute>;
  if IsFormatValue(LFormat, 'native') then
    Result := TJSONObject.Create
      .AddPair('type', 'array')
      .AddPair('items', TJSONObject.Create
        .AddPair('type', 'integer')
        .AddPair('minimum', TJSONNumber.Create(0))
        .AddPair('maximum', TJSONNumber.Create(255)))
  else
    Result := TJSONObject.Create
      .AddPair('type', 'string')
      .AddPair('contentEncoding', 'base64');
end;

function TBytesSerializer.ValueAsBase64(const AValue: TJSONValue): TValue;
var
  LVal: TBytes;
begin
  if not (AValue is TJSONString) then
    raise ENeonException.Create(SNeonErrorJSONNotString);

  LVal := TBase64.Decode(AValue.Value);
  Result := TValue.From<TBytes>(LVal);
end;

{ TCollectionSerializer }

class function TCollectionSerializer.CanHandle(AType: PTypeInfo): Boolean;
begin
  Result := TypeInfoIs(AType);
end;

class procedure TCollectionSerializer.ChangeConfig(AConfig: INeonConfiguration);
begin
  AConfig.Rules.ForClass<TCollectionItem>
    .AddIgnoreMembers(['Collection', 'Index', 'DisplayName'])
end;

function TCollectionSerializer.Deserialize(AValue: TJSONValue;
  const AData: TValue; ANeonObject: TNeonRttiObject;
  AContext: IDeserializerContext): TValue;
var
  LColl: TCollection;
  LItemColl: TCollectionItem;
  LType: TRttiType;
  LArray: TJSONArray;
  LItem: TJSONValue;
begin
  if not (AValue is TJSONArray) then
    raise ENeonException.Create(SNeonErrorJSONNotArray);

  LArray := AValue as TJSONArray;
  LColl := AData.AsType<TCollection>;
  LType := TRttiUtils.Context.GetType(LColl.ItemClass);

  for LItem in LArray do
  begin
    if LItem is TJSONNull then
      Continue;

    if not (LItem is TJSONObject) then
      raise ENeonException.Create(SNeonErrorJSONItemNotObject);

    LItemColl := LColl.Add;
    AContext.ReadDataMember(LItem, LType, LItemColl);
  end;

  Result := TValue.From<TCollection>(LColl);
end;

class function TCollectionSerializer.GetTargetInfo: PTypeInfo;
begin
  Result := TCollection.ClassInfo;
end;

function TCollectionSerializer.Serialize(const AValue: TValue;
  ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue;
var
  LIndex: Integer;
  LColl: TCollection;
  LItemColl: TCollectionItem;
  LArray: TJSONArray;
  LItem: TJSONValue;
begin
  LColl := AValue.AsType<TCollection>;

  if LColl.Count > 0 then
  begin
    LArray := TJSONArray.Create;
    for LIndex := 0 to LColl.Count - 1 do
    begin
      LItemColl := LColl.Items[LIndex];
      LItem := AContext.WriteDataMember(LItemColl, True);
      LArray.AddElement(LItem);
    end;
    Result := LArray;
  end
  else
  begin
    if ANeonObject.NeonInclude.Value = IncludeIf.NotEmpty then
      Exit(nil);
    Result := TJSONArray.Create;
  end;
end;

function TCollectionSerializer.SerializeSchema(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
begin
  // The serializer writes one object per item; the item class is dynamic
  // (TCollection.ItemClass), so the row itself is left unconstrained
  Result := TJSONObject.Create
    .AddPair('type', 'array')
    .AddPair('items', TJSONObject.Create.AddPair('type', 'object'));
end;

end.
