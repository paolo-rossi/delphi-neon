{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Tests.Attributes.Serialize;

interface

uses
  System.SysUtils, System.Classes, System.Rtti, System.TypInfo, System.JSON,
  System.Generics.Collections, DUnitX.TestFramework,

  Neon.Core.Attributes,
  Neon.Core.Persistence,
  Neon.Core.Types;

type
  /// <summary>
  ///   Writes a string upper case and reads it back lower case, so the JSON
  ///   and the object both tell whether the serializer ran
  /// </summary>
  TUpperSerializer = class(TCustomSerializer)
  protected
    class function GetTargetInfo: PTypeInfo; override;
    class function CanHandle(AType: PTypeInfo): Boolean; override;
  public
    function Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue; override;
    function Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue; override;
    function SerializeSchema(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject; override;
  end;

  /// <summary>
  ///   Registered in the configuration for every string: writes it reversed
  /// </summary>
  TReverseSerializer = class(TCustomSerializer)
  protected
    class function GetTargetInfo: PTypeInfo; override;
    class function CanHandle(AType: PTypeInfo): Boolean; override;
  public
    function Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue; override;
    function Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue; override;
  end;

  /// <summary>
  ///   Writes a TSerPoint as "X,Y" and reads it back into the instance
  /// </summary>
  TSerPointSerializer = class(TCustomSerializer)
  protected
    class function GetTargetInfo: PTypeInfo; override;
    class function CanHandle(AType: PTypeInfo): Boolean; override;
  public
    function Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue; override;
    function Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue; override;
  end;

  TSerAttrEntity = class
  private
    FBoth: string;
    FWriteOnly: string;
    FReadOnly: string;
    FPlain: string;
  public
    [NeonSerialize(TUpperSerializer)]
    [NeonDeserialize(TUpperSerializer)]
    property Both: string read FBoth write FBoth;

    [NeonSerialize(TUpperSerializer)]
    property WriteOnly: string read FWriteOnly write FWriteOnly;

    [NeonDeserialize(TUpperSerializer)]
    property ReadOnly: string read FReadOnly write FReadOnly;

    property Plain: string read FPlain write FPlain;
  end;

  /// <summary>
  ///   The attributes on the type cover every value of it: a member, a list
  ///   item
  /// </summary>
  [NeonSerialize(TSerPointSerializer)]
  [NeonDeserialize(TSerPointSerializer)]
  TSerPoint = class
  private
    FX: Integer;
    FY: Integer;
  public
    property X: Integer read FX write FX;
    property Y: Integer read FY write FY;
  end;

  TSerPointHolder = class
  private
    FPoint: TSerPoint;
    FPoints: TObjectList<TSerPoint>;
  public
    constructor Create;
    destructor Destroy; override;

    property Point: TSerPoint read FPoint write FPoint;
    property Points: TObjectList<TSerPoint> read FPoints write FPoints;
  end;

  TSerBadEntity = class
  private
    FValue: string;
  public
    [NeonSerialize(TStringList)]
    property Value: string read FValue write FValue;
  end;

  /// <summary>
  ///   [NeonSerialize(TClass)] / [NeonDeserialize(TClass)] name the custom
  ///   serializer of a member (or of every value of a type), each for its own
  ///   direction, without registering it in the configuration
  /// </summary>
  [TestFixture]
  [Category('attrserialize')]
  TTestAttributesSerialize = class(TObject)
  public
    [Test]
    procedure TestSerializeUsesMemberSerializer;

    [Test]
    procedure TestDeserializeUsesMemberSerializer;

    [Test]
    procedure TestMemberSerializerWinsOverRegistered;

    [Test]
    procedure TestAttributeOnTypeRoundTrips;

    [Test]
    procedure TestNotASerializerRaises;

    [Test]
    procedure TestSchemaUsesMemberSerializer;
  end;

implementation

uses
  Neon.Core.Persistence.JSON,
  Neon.Core.Persistence.JSON.Schema;

{ TUpperSerializer }

class function TUpperSerializer.GetTargetInfo: PTypeInfo;
begin
  Result := TypeInfo(string);
end;

class function TUpperSerializer.CanHandle(AType: PTypeInfo): Boolean;
begin
  Result := AType = TypeInfo(string);
end;

function TUpperSerializer.Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue;
begin
  Result := TJSONString.Create(AValue.AsString.ToUpper);
end;

function TUpperSerializer.Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue;
begin
  Result := TValue.From<string>(AValue.Value.ToLower);
end;

function TUpperSerializer.SerializeSchema(AType: TRttiType; ANeonObject: TNeonRttiObject): TJSONObject;
begin
  Result := TJSONObject.Create
    .AddPair('type', 'string')
    .AddPair('pattern', '^[A-Z]*$');
end;

{ TReverseSerializer }

class function TReverseSerializer.GetTargetInfo: PTypeInfo;
begin
  Result := TypeInfo(string);
end;

class function TReverseSerializer.CanHandle(AType: PTypeInfo): Boolean;
begin
  Result := AType = TypeInfo(string);
end;

function TReverseSerializer.Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue;
var
  LValue: string;
  LIndex: Integer;
begin
  LValue := '';
  for LIndex := AValue.AsString.Length downto 1 do
    LValue := LValue + AValue.AsString[LIndex];
  Result := TJSONString.Create(LValue);
end;

function TReverseSerializer.Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue;
begin
  Result := TValue.From<string>(AValue.Value);
end;

{ TSerPointSerializer }

class function TSerPointSerializer.GetTargetInfo: PTypeInfo;
begin
  Result := TSerPoint.ClassInfo;
end;

class function TSerPointSerializer.CanHandle(AType: PTypeInfo): Boolean;
begin
  Result := TypeInfoIs(AType);
end;

function TSerPointSerializer.Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue;
var
  LPoint: TSerPoint;
begin
  LPoint := AValue.AsType<TSerPoint>;
  Result := TJSONString.Create(Format('%d,%d', [LPoint.X, LPoint.Y]));
end;

function TSerPointSerializer.Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue;
var
  LPoint: TSerPoint;
  LParts: TArray<string>;
begin
  LPoint := AData.AsType<TSerPoint>;
  LParts := AValue.Value.Split([',']);
  LPoint.X := LParts[0].ToInteger;
  LPoint.Y := LParts[1].ToInteger;
  Result := AData;
end;

{ TSerPointHolder }

constructor TSerPointHolder.Create;
begin
  FPoint := TSerPoint.Create;
  FPoints := TObjectList<TSerPoint>.Create;
end;

destructor TSerPointHolder.Destroy;
begin
  FPoints.Free;
  FPoint.Free;
  inherited;
end;

{ TTestAttributesSerialize }

procedure TTestAttributesSerialize.TestSerializeUsesMemberSerializer;
var
  LEntity: TSerAttrEntity;
begin
  LEntity := TSerAttrEntity.Create;
  try
    LEntity.Both := 'abc';
    LEntity.WriteOnly := 'abc';
    LEntity.ReadOnly := 'abc';
    LEntity.Plain := 'abc';

    // [NeonDeserialize] alone does not change what is written
    Assert.AreEqual('{"Both":"ABC","WriteOnly":"ABC","ReadOnly":"abc","Plain":"abc"}',
      TNeon.ObjectToJSONString(LEntity));
  finally
    LEntity.Free;
  end;
end;

procedure TTestAttributesSerialize.TestDeserializeUsesMemberSerializer;
var
  LEntity: TSerAttrEntity;
begin
  LEntity := TSerAttrEntity.Create;
  try
    TNeon.JSONToObject(LEntity,
      '{"Both":"ABC","WriteOnly":"ABC","ReadOnly":"ABC","Plain":"ABC"}',
      TNeonConfiguration.Default);

    // [NeonSerialize] alone does not change what is read
    Assert.AreEqual('abc', LEntity.Both);
    Assert.AreEqual('ABC', LEntity.WriteOnly);
    Assert.AreEqual('abc', LEntity.ReadOnly);
    Assert.AreEqual('ABC', LEntity.Plain);
  finally
    LEntity.Free;
  end;
end;

procedure TTestAttributesSerialize.TestMemberSerializerWinsOverRegistered;
var
  LEntity: TSerAttrEntity;
begin
  LEntity := TSerAttrEntity.Create;
  try
    LEntity.Both := 'abc';
    LEntity.WriteOnly := 'abc';
    LEntity.ReadOnly := 'abc';
    LEntity.Plain := 'abc';

    // The registered serializer still applies where no attribute names one
    Assert.AreEqual('{"Both":"ABC","WriteOnly":"ABC","ReadOnly":"cba","Plain":"cba"}',
      TNeon.ObjectToJSONString(LEntity,
        TNeonConfiguration.Default.RegisterSerializer(TReverseSerializer)));
  finally
    LEntity.Free;
  end;
end;

procedure TTestAttributesSerialize.TestAttributeOnTypeRoundTrips;
var
  LHolder: TSerPointHolder;
  LPoint: TSerPoint;
  LJSON: string;
begin
  LHolder := TSerPointHolder.Create;
  try
    LHolder.Point.X := 1;
    LHolder.Point.Y := 2;
    LPoint := TSerPoint.Create;
    LPoint.X := 3;
    LPoint.Y := 4;
    LHolder.Points.Add(LPoint);

    LJSON := TNeon.ObjectToJSONString(LHolder);
    Assert.AreEqual('{"Point":"1,2","Points":["3,4"]}', LJSON);
  finally
    LHolder.Free;
  end;

  LHolder := TSerPointHolder.Create;
  try
    TNeon.JSONToObject(LHolder, LJSON, TNeonConfiguration.Default);

    Assert.AreEqual(1, LHolder.Point.X);
    Assert.AreEqual(2, LHolder.Point.Y);
    Assert.AreEqual(1, LHolder.Points.Count);
    Assert.AreEqual(3, LHolder.Points[0].X);
    Assert.AreEqual(4, LHolder.Points[0].Y);
  finally
    LHolder.Free;
  end;
end;

procedure TTestAttributesSerialize.TestNotASerializerRaises;
var
  LEntity: TSerBadEntity;
begin
  LEntity := TSerBadEntity.Create;
  try
    Assert.WillRaise(
      procedure begin
        TNeon.ObjectToJSONString(LEntity, TNeonConfiguration.Default.SetRaiseExceptions(True))
      end,
      ENeonException
    );
  finally
    LEntity.Free;
  end;
end;

procedure TTestAttributesSerialize.TestSchemaUsesMemberSerializer;
var
  LSchema: TJSONObject;
  LProps: TJSONObject;
begin
  LSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSerAttrEntity);
  try
    LProps := LSchema.GetValue('properties') as TJSONObject;

    // The schema describes what is written: [NeonSerialize] counts,
    // [NeonDeserialize] does not
    Assert.IsNotNull((LProps.GetValue('Both') as TJSONObject).GetValue('pattern'));
    Assert.IsNotNull((LProps.GetValue('WriteOnly') as TJSONObject).GetValue('pattern'));
    Assert.IsNull((LProps.GetValue('ReadOnly') as TJSONObject).GetValue('pattern'));
    Assert.IsNull((LProps.GetValue('Plain') as TJSONObject).GetValue('pattern'));
  finally
    LSchema.Free;
  end;
end;

end.
