{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Tests.Attributes.GetterSetter;

interface

uses
  System.SysUtils, System.Rtti, DUnitX.TestFramework,

  Neon.Core.Attributes,
  Neon.Core.Persistence,
  Neon.Core.Types;

type
  /// <summary>
  ///   One property per kind of member a [NeonGetter] can read through. Every
  ///   property holds a value of its own, so the JSON says which of the two
  ///   members the engine actually went through.
  /// </summary>
  /// <remarks>
  ///   The public *fields* are the redirection targets and never show up in the
  ///   JSON: the standard members of a class are its properties.
  /// </remarks>
  TGetterEntity = class
  private
    FName: string;
    FCount: Integer;
    FRatio: Double;
    FCountSource: Integer;
  public
    NameSource: string;
    RatioSource: Double;

    // Public: Delphi emits no RTTI for a private method, so Neon could not
    // find one to read through
    function GetRatio: Double;

    [NeonGetter('NameSource')]
    property Name: string read FName write FName;

    [NeonGetter('CountSource')]
    property Count: Integer read FCount write FCount;

    [NeonGetter('GetRatio')]
    property Ratio: Double read FRatio write FRatio;

    [NeonIgnore]
    property CountSource: Integer read FCountSource write FCountSource;
  end;

  /// <summary>
  ///   The same three kinds on the writing side: what the document holds must
  ///   land on the redirection target and leave the property itself alone
  /// </summary>
  TSetterEntity = class
  private
    FName: string;
    FCount: Integer;
    FRatio: Double;
    FCountTarget: Integer;
  public
    NameTarget: string;
    RatioTarget: Double;

    procedure SetRatio(const AValue: Double);

    [NeonSetter('NameTarget')]
    property Name: string read FName write FName;

    [NeonSetter('CountTarget')]
    property Count: Integer read FCount write FCount;

    [NeonSetter('SetRatio')]
    property Ratio: Double read FRatio write FRatio;

    [NeonIgnore]
    property CountTarget: Integer read FCountTarget write FCountTarget;
  end;

  /// <summary>
  ///   A property Neon cannot read on its own: the [NeonGetter] is what puts it
  ///   in the document at all
  /// </summary>
  TWriteOnlyEntity = class
  private
    FToken: string;
  public
    function TokenValue: string;

    [NeonGetter('FToken')]
    property Token: string write FToken;
  end;

  /// <summary>
  ///   The mirror case: a read-only property the [NeonSetter] makes writable
  /// </summary>
  TReadOnlyEntity = class
  private
    FCode: string;
  public
    [NeonSetter('FCode')]
    property Code: string read FCode;
  end;

  /// <summary>
  ///   Both attributes on one member, pointing at the same target: what is
  ///   written is what comes back out
  /// </summary>
  TGetterAndSetterEntity = class
  private
    FValue: string;
  public
    ValueSource: string;

    [NeonGetter('ValueSource')]
    [NeonSetter('ValueSource')]
    property Value: string read FValue write FValue;
  end;

  /// <summary>
  ///   A record member redirected to another field: no instance is needed to
  ///   read or write one, so records work like classes here
  /// </summary>
  TRecordEntity = record
    [NeonGetter('Source')]
    [NeonSetter('Source')]
    Value: string;

    [NeonIgnore]
    Source: string;
  end;

  /// <summary>
  ///   A record method has no instance to run on: Neon hands records around as
  ///   a pointer to a copy, so this must be reported, not silently ignored
  /// </summary>
  TRecordMethodEntity = record
  public
    [NeonGetter('GetSource')]
    Value: string;

    function GetSource: string;
  end;

  TUnknownMemberEntity = class
  private
    FValue: string;
  public
    [NeonGetter('NotThere')]
    property Value: string read FValue write FValue;
  end;

  TWrongTypeEntity = class
  private
    FValue: string;
  public
    Source: Integer;

    [NeonGetter('Source')]
    property Value: string read FValue write FValue;
  end;

  TWrongSignatureEntity = class
  private
    FValue: string;
  public
    function GetValue(AIndex: Integer): string;

    [NeonGetter('GetValue')]
    property Value: string read FValue write FValue;
  end;

  TUnwritableTargetEntity = class
  private
    FValue: string;
    FSource: string;
  public
    [NeonIgnore]
    property Source: string read FSource;

    [NeonSetter('Source')]
    property Value: string read FValue write FValue;
  end;

  /// <summary>
  ///   [NeonGetter] and [NeonSetter] make the engine read and write a member
  ///   other than the annotated one. Both are resolved once, while the member's
  ///   attributes are parsed, and both demand a member of the very same type.
  /// </summary>
  [TestFixture]
  [Category('attraccessor')]
  TTestAttributesGetterSetter = class(TObject)
  private
    /// <summary>
    ///   An unusable [NeonGetter]/[NeonSetter] is reported like any other
    ///   member error: logged and skipped, or raised with this on
    /// </summary>
    FStrict: INeonConfiguration;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestGetterThroughEveryMemberKind;

    [Test]
    procedure TestSetterThroughEveryMemberKind;

    [Test]
    procedure TestGetterMakesWriteOnlyPropertySerializable;

    [Test]
    procedure TestSetterMakesReadOnlyPropertyWritable;

    [Test]
    procedure TestGetterAndSetterOnTheSameMember;

    [Test]
    procedure TestRecordFieldRoundTrips;

    [Test]
    procedure TestRecordMethodRaises;

    [Test]
    procedure TestUnknownMemberRaises;

    [Test]
    procedure TestTypeMismatchRaises;

    [Test]
    procedure TestWrongMethodSignatureRaises;

    [Test]
    procedure TestUnwritableTargetRaises;
  end;

implementation

uses
  Neon.Core.Persistence.JSON;

{ TGetterEntity }

function TGetterEntity.GetRatio: Double;
begin
  Result := RatioSource;
end;

{ TSetterEntity }

procedure TSetterEntity.SetRatio(const AValue: Double);
begin
  RatioTarget := AValue;
end;

{ TWriteOnlyEntity }

function TWriteOnlyEntity.TokenValue: string;
begin
  Result := FToken;
end;

{ TRecordMethodEntity }

function TRecordMethodEntity.GetSource: string;
begin
  Result := 'source';
end;

{ TWrongSignatureEntity }

function TWrongSignatureEntity.GetValue(AIndex: Integer): string;
begin
  Result := FValue;
end;

{ TTestAttributesGetterSetter }

procedure TTestAttributesGetterSetter.Setup;
begin
  FStrict := TNeonConfiguration.Default.SetRaiseExceptions(True);
end;

procedure TTestAttributesGetterSetter.TestGetterThroughEveryMemberKind;
var
  LEntity: TGetterEntity;
begin
  LEntity := TGetterEntity.Create;
  try
    LEntity.Name := 'own';
    LEntity.Count := 1;
    LEntity.Ratio := 1.5;

    LEntity.NameSource := 'redirected';
    LEntity.CountSource := 2;
    LEntity.RatioSource := 2.5;

    Assert.AreEqual('{"Name":"redirected","Count":2,"Ratio":2.5}',
      TNeon.ObjectToJSONString(LEntity));
  finally
    LEntity.Free;
  end;
end;

procedure TTestAttributesGetterSetter.TestSetterThroughEveryMemberKind;
var
  LEntity: TSetterEntity;
begin
  LEntity := TSetterEntity.Create;
  try
    TNeon.JSONToObject(LEntity, '{"Name":"n","Count":7,"Ratio":2.5}',
      TNeonConfiguration.Default);

    Assert.AreEqual('n', LEntity.NameTarget);
    Assert.AreEqual(7, LEntity.CountTarget);
    Assert.AreEqual(Double(2.5), LEntity.RatioTarget);

    // The annotated properties never saw the value
    Assert.AreEqual('', LEntity.Name);
    Assert.AreEqual(0, LEntity.Count);
    Assert.AreEqual(Double(0), LEntity.Ratio);
  finally
    LEntity.Free;
  end;
end;

procedure TTestAttributesGetterSetter.TestGetterMakesWriteOnlyPropertySerializable;
var
  LEntity: TWriteOnlyEntity;
begin
  LEntity := TWriteOnlyEntity.Create;
  try
    LEntity.Token := 'abc';
    Assert.AreEqual('{"Token":"abc"}', TNeon.ObjectToJSONString(LEntity));
  finally
    LEntity.Free;
  end;
end;

procedure TTestAttributesGetterSetter.TestSetterMakesReadOnlyPropertyWritable;
var
  LEntity: TReadOnlyEntity;
begin
  LEntity := TReadOnlyEntity.Create;
  try
    TNeon.JSONToObject(LEntity, '{"Code":"abc"}', TNeonConfiguration.Default);
    Assert.AreEqual('abc', LEntity.Code);
  finally
    LEntity.Free;
  end;
end;

procedure TTestAttributesGetterSetter.TestGetterAndSetterOnTheSameMember;
var
  LEntity: TGetterAndSetterEntity;
begin
  LEntity := TGetterAndSetterEntity.Create;
  try
    LEntity.Value := 'own';
    LEntity.ValueSource := 'redirected';
    Assert.AreEqual('{"Value":"redirected"}', TNeon.ObjectToJSONString(LEntity));

    TNeon.JSONToObject(LEntity, '{"Value":"read"}', TNeonConfiguration.Default);
    Assert.AreEqual('read', LEntity.ValueSource);
    Assert.AreEqual('own', LEntity.Value);
  finally
    LEntity.Free;
  end;
end;

procedure TTestAttributesGetterSetter.TestRecordFieldRoundTrips;
var
  LRecord: TRecordEntity;
begin
  LRecord.Value := 'own';
  LRecord.Source := 'redirected';
  Assert.AreEqual('{"Value":"redirected"}',
    TNeon.ValueToJSONString(TValue.From<TRecordEntity>(LRecord)));

  LRecord := TNeon.JSONToValue<TRecordEntity>('{"Value":"read"}');
  Assert.AreEqual('read', LRecord.Source);
  Assert.AreEqual('', LRecord.Value);
end;

procedure TTestAttributesGetterSetter.TestRecordMethodRaises;
var
  LRecord: TRecordMethodEntity;
begin
  LRecord.Value := 'own';
  Assert.WillRaise(
    procedure begin TNeon.ValueToJSONString(TValue.From<TRecordMethodEntity>(LRecord), FStrict) end,
    ENeonException
  );
end;

procedure TTestAttributesGetterSetter.TestUnknownMemberRaises;
var
  LEntity: TUnknownMemberEntity;
begin
  LEntity := TUnknownMemberEntity.Create;
  try
    Assert.WillRaise(
      procedure begin TNeon.ObjectToJSONString(LEntity, FStrict) end,
      ENeonException
    );
  finally
    LEntity.Free;
  end;
end;

procedure TTestAttributesGetterSetter.TestTypeMismatchRaises;
var
  LEntity: TWrongTypeEntity;
begin
  LEntity := TWrongTypeEntity.Create;
  try
    // An Integer field cannot stand in for a string property
    Assert.WillRaise(
      procedure begin TNeon.ObjectToJSONString(LEntity, FStrict) end,
      ENeonException
    );
  finally
    LEntity.Free;
  end;
end;

procedure TTestAttributesGetterSetter.TestWrongMethodSignatureRaises;
var
  LEntity: TWrongSignatureEntity;
begin
  LEntity := TWrongSignatureEntity.Create;
  try
    // A getter method has to take no parameter at all
    Assert.WillRaise(
      procedure begin TNeon.ObjectToJSONString(LEntity, FStrict) end,
      ENeonException
    );
  finally
    LEntity.Free;
  end;
end;

procedure TTestAttributesGetterSetter.TestUnwritableTargetRaises;
var
  LEntity: TUnwritableTargetEntity;
begin
  LEntity := TUnwritableTargetEntity.Create;
  try
    Assert.WillRaise(
      procedure begin
        TNeon.JSONToObject(LEntity, '{"Value":"abc"}', FStrict)
      end,
      ENeonException
    );
  finally
    LEntity.Free;
  end;
end;

end.
