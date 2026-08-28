{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Tests.Config.ReadOnlyProps;

interface

uses
  System.SysUtils, System.Rtti, System.Generics.Collections,
  DUnitX.TestFramework,

  Neon.Core.Types,
  Neon.Core.Attributes,
  Neon.Core.Persistence,
  Neon.Tests.Utils;

type
  TReadOnlyChild = class
  private
    FValue: Integer;
  public
    property Value: Integer read FValue write FValue;
  end;

  TReadOnlyClass = class
  private
    FName: string;
    FChild: TReadOnlyChild;
    function GetComputed: string;
  public
    constructor Create;
    destructor Destroy; override;

    property Name: string read FName write FName;

    // Read-only and simply typed: dropped when IgnoreReadOnlyProps is on
    property Computed: string read GetComputed;

    // Read-only but class typed: kept even when IgnoreReadOnlyProps is on,
    // otherwise sub-objects exposed through a getter would never be written
    property Child: TReadOnlyChild read FChild;
  end;

  /// <summary>
  ///   A record behind a read-only property: not tkClass and not tkInterface,
  ///   so it gets no exemption from IgnoreReadOnlyProps
  /// </summary>
  TReadOnlySize = record
    Width: Integer;
    Height: Integer;
  end;

  /// <summary>
  ///   One property per shape the read-only rules can tell apart. All the
  ///   engine ever asks is "can I read it" (IsReadable, which decides
  ///   serialization) and "can I write it" (IsWritable, which decides
  ///   deserialization and, with IgnoreReadOnlyProps on, serialization too).
  /// </summary>
  TReadOnlyShapes = class
  private
    FId: Integer;
    FCode: string;
    FSize: TReadOnlySize;
    FChild: TReadOnlyChild;
    FSecret: string;
    procedure SetSecret(const AValue: string);
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    ///   Fills the members nothing outside the class could otherwise reach.
    ///   Methods are never serialized, so this is invisible to the engine
    /// </summary>
    procedure Seed;

    property Id: Integer read FId write FId;

    /// <summary>Read-only, simple type: follows the flag</summary>
    property Code: string read FCode;

    /// <summary>Read-only, record type: follows the flag as well</summary>
    property Size: TReadOnlySize read FSize;

    /// <summary>Read-only, class type: exempt from the flag</summary>
    property Child: TReadOnlyChild read FChild;

    /// <summary>
    ///   The mirror image of a read-only property: writable but not readable,
    ///   so it is in no document Neon writes and filled by every document
    ///   Neon reads
    /// </summary>
    property Secret: string write SetSecret;

    /// <summary>Not serialized, only so a test can see what landed</summary>
    [NeonIgnore]
    property SecretValue: string read FSecret;
  end;

  /// <summary>
  ///   The two attributes that overrule the read-only rules, on properties
  ///   that are read-only in exactly the same way as TReadOnlyShapes.Code
  /// </summary>
  TReadOnlyOverrides = class
  private
    FAlways: string;
    FPlain: string;
    FVersion: string;
  public
    procedure Seed;

    /// <summary>
    ///   The redirection target of the [NeonSetter]. Delphi emits no RTTI for
    ///   a private method, so it has to be public
    /// </summary>
    procedure SetVersionValue(const AValue: string);

    /// <summary>
    ///   Checked before everything else and answers on its own: the read-only
    ///   check is never reached
    /// </summary>
    [NeonInclude(IncludeIf.Always)]
    property Always: string read FAlways;

    /// <summary>The same property without the attribute, as the control</summary>
    property Plain: string read FPlain;

    /// <summary>
    ///   A [NeonSetter] makes IsWritable answer True, which both saves the
    ///   property from IgnoreReadOnlyProps and lets a document fill it
    /// </summary>
    [NeonSetter('SetVersionValue')]
    property Version: string read FVersion;
  end;

  /// <summary>
  ///   RTTI reports every field as both readable and writable, whatever its
  ///   visibility, so no field can look read-only to the engine
  /// </summary>
  TReadOnlyFields = class
  public
    Id: Integer;
    Name: string;
  end;

  [TestFixture]
  [Category('readonlyprops')]
  TTestReadOnlyProps = class(TObject)
  private
    FTestObj: TReadOnlyClass;

    function Config(AIgnore: Boolean): INeonConfiguration;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    [TestCase('TestKeepReadOnly', 'False|{"Name":"Paolo","Computed":"Paolo!","Child":{"Value":42}}', '|')]
    [TestCase('TestDropReadOnly', 'True|{"Name":"Paolo","Child":{"Value":42}}', '|')]
    procedure TestIgnoreReadOnlyProps(const AIgnore: Boolean; const _Result: string);

    /// <summary>
    ///   The ignore list is applied before the read-only check, which probes
    ///   the member type: an ignored member must be dropped without its type
    ///   ever being looked at
    /// </summary>
    [Test]
    [TestCase('TestIgnoreSimpleReadOnly', 'Computed|{"Name":"Paolo","Child":{"Value":42}}', '|')]
    [TestCase('TestIgnoreClassReadOnly', 'Child|{"Name":"Paolo"}', '|')]
    [TestCase('TestIgnoreBoth', 'Computed,Child|{"Name":"Paolo"}', '|')]
    procedure TestIgnoreListWithReadOnlyProps(const AMemberList, _Result: string);

    /// <summary>
    ///   The exemption covers class and interface types only, so a read-only
    ///   record property goes the way of a read-only string. A write-only
    ///   property is absent from both documents: there is nothing to read
    /// </summary>
    [Test]
    [TestCase('TestKeepAllShapes', 'False|{"Id":1,"Code":"NEON","Size":{"Width":320,"Height":200},"Child":{"Value":42}}', '|')]
    [TestCase('TestDropSimpleAndRecord', 'True|{"Id":1,"Child":{"Value":42}}', '|')]
    procedure TestSerializeShapes(const AIgnore: Boolean; const _Result: string);
  end;

  [TestFixture]
  [Category('readonlyprops')]
  TTestReadOnlyPropsDeserialize = class(TObject)
  private const
    /// <summary>
    ///   Names every member of TReadOnlyShapes, the ones Neon can never write
    ///   back included, so what lands on the object is down to the rules and
    ///   not to what the document happens to omit
    /// </summary>
    SHAPES_JSON =
      '{"Id":7,"Code":"FROM-JSON","Size":{"Width":1,"Height":2},' +
      '"Child":{"Value":99},"Secret":"from the document"}';
  private
    FTestObj: TReadOnlyShapes;

    function Config(AIgnore: Boolean): INeonConfiguration;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    /// <summary>
    ///   Deserialization filters on IsWritable and never consults
    ///   IgnoreReadOnlyProps, so both settings give the same object
    /// </summary>
    [Test]
    [TestCase('TestReadWithFlagOff', 'False', '|')]
    [TestCase('TestReadWithFlagOn', 'True', '|')]
    procedure TestDeserializeIgnoresTheFlag(const AIgnore: Boolean);

    /// <summary>
    ///   The class-type exemption is a serialization rule: a read-only
    ///   sub-object is written out but is not filled back in, which is the one
    ///   asymmetry of the whole feature
    /// </summary>
    [Test]
    procedure TestReadOnlyClassPropIsNotDeserialized;

    /// <summary>
    ///   A write-only property is the reverse case: only a document can fill it
    /// </summary>
    [Test]
    procedure TestWriteOnlyPropIsDeserialized;
  end;

  [TestFixture]
  [Category('readonlyprops')]
  TTestReadOnlyPropsOverrides = class(TObject)
  private
    FTestObj: TReadOnlyOverrides;

    function Config(AIgnore: Boolean): INeonConfiguration;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    /// <summary>
    ///   [NeonInclude(Always)] short-circuits the read-only check, [NeonSetter]
    ///   removes its premise; "Plain" is the control that disappears
    /// </summary>
    [Test]
    [TestCase('TestKeepAll', 'False|{"Always":"always","Plain":"plain","Version":"1.0"}', '|')]
    [TestCase('TestKeepOverridden', 'True|{"Always":"always","Version":"1.0"}', '|')]
    procedure TestOverridesWinOverTheFlag(const AIgnore: Boolean; const _Result: string);

    /// <summary>
    ///   [NeonInclude(Always)] marks a member serializable for both operations
    ///   but conjures no setter, so only the [NeonSetter] property is filled
    /// </summary>
    [Test]
    procedure TestOnlyNeonSetterMakesAReadOnlyPropWritable;
  end;

  [TestFixture]
  [Category('readonlyprops')]
  TTestReadOnlyPropsFields = class(TObject)
  public
    /// <summary>
    ///   The option is named ReadOnly*Props* for a reason: TRttiField answers
    ///   True to both IsReadable and IsWritable for every field, so the flag
    ///   has nothing to act on
    /// </summary>
    [Test]
    [TestCase('TestFieldsFlagOff', 'False|{"Id":42,"Name":"Paolo"}', '|')]
    [TestCase('TestFieldsFlagOn', 'True|{"Id":42,"Name":"Paolo"}', '|')]
    procedure TestFieldsAreNeverReadOnly(const AIgnore: Boolean; const _Result: string);
  end;

implementation

{ TReadOnlyClass }

constructor TReadOnlyClass.Create;
begin
  FChild := TReadOnlyChild.Create;
end;

destructor TReadOnlyClass.Destroy;
begin
  FChild.Free;
  inherited;
end;

function TReadOnlyClass.GetComputed: string;
begin
  Result := FName + '!';
end;

{ TReadOnlyShapes }

constructor TReadOnlyShapes.Create;
begin
  FChild := TReadOnlyChild.Create;
end;

destructor TReadOnlyShapes.Destroy;
begin
  FChild.Free;
  inherited;
end;

procedure TReadOnlyShapes.Seed;
begin
  FId := 1;
  FCode := 'NEON';
  FSize.Width := 320;
  FSize.Height := 200;
  FChild.Value := 42;
  FSecret := '';
end;

procedure TReadOnlyShapes.SetSecret(const AValue: string);
begin
  FSecret := AValue;
end;

{ TReadOnlyOverrides }

procedure TReadOnlyOverrides.Seed;
begin
  FAlways := 'always';
  FPlain := 'plain';
  FVersion := '1.0';
end;

procedure TReadOnlyOverrides.SetVersionValue(const AValue: string);
begin
  FVersion := AValue;
end;

{ TTestReadOnlyProps }

function TTestReadOnlyProps.Config(AIgnore: Boolean): INeonConfiguration;
begin
  Result := TNeonConfiguration.Default.SetIgnoreReadOnlyProps(AIgnore);
end;

procedure TTestReadOnlyProps.Setup;
begin
  FTestObj := TReadOnlyClass.Create;
  FTestObj.Name := 'Paolo';
  FTestObj.Child.Value := 42;
end;

procedure TTestReadOnlyProps.TearDown;
begin
  FTestObj.Free;
end;

procedure TTestReadOnlyProps.TestIgnoreReadOnlyProps(const AIgnore: Boolean; const _Result: string);
begin
  Assert.AreEqual(_Result, TTestUtils.SerializeObject(FTestObj, Config(AIgnore)));
end;

procedure TTestReadOnlyProps.TestIgnoreListWithReadOnlyProps(const AMemberList, _Result: string);
var
  LConfig: INeonConfiguration;
begin
  LConfig := Config(True);
  LConfig.SetIgnoreMembers(AMemberList.Split([',']));

  Assert.AreEqual(_Result, TTestUtils.SerializeObject(FTestObj, LConfig));
end;

procedure TTestReadOnlyProps.TestSerializeShapes(const AIgnore: Boolean; const _Result: string);
var
  LShapes: TReadOnlyShapes;
begin
  LShapes := TReadOnlyShapes.Create;
  try
    LShapes.Seed;
    Assert.AreEqual(_Result, TTestUtils.SerializeObject(LShapes, Config(AIgnore)));
  finally
    LShapes.Free;
  end;
end;

{ TTestReadOnlyPropsDeserialize }

function TTestReadOnlyPropsDeserialize.Config(AIgnore: Boolean): INeonConfiguration;
begin
  Result := TNeonConfiguration.Default.SetIgnoreReadOnlyProps(AIgnore);
end;

procedure TTestReadOnlyPropsDeserialize.Setup;
begin
  FTestObj := TReadOnlyShapes.Create;
  FTestObj.Seed;
end;

procedure TTestReadOnlyPropsDeserialize.TearDown;
begin
  FTestObj.Free;
end;

procedure TTestReadOnlyPropsDeserialize.TestDeserializeIgnoresTheFlag(const AIgnore: Boolean);
begin
  TTestUtils.DeserializeObject(SHAPES_JSON, FTestObj, Config(AIgnore));

  // Writable, so the document wins
  Assert.AreEqual(7, FTestObj.Id, 'Id');

  // Read-only: no setter to call, whatever the flag says
  Assert.AreEqual('NEON', FTestObj.Code, 'Code');
  Assert.AreEqual(320, FTestObj.Size.Width, 'Size.Width');
  Assert.AreEqual(200, FTestObj.Size.Height, 'Size.Height');
end;

procedure TTestReadOnlyPropsDeserialize.TestReadOnlyClassPropIsNotDeserialized;
begin
  TTestUtils.DeserializeObject(SHAPES_JSON, FTestObj, Config(False));

  Assert.AreEqual(42, FTestObj.Child.Value,
    'A read-only class property is serialized but not deserialized');
end;

procedure TTestReadOnlyPropsDeserialize.TestWriteOnlyPropIsDeserialized;
begin
  TTestUtils.DeserializeObject(SHAPES_JSON, FTestObj, Config(True));

  Assert.AreEqual('from the document', FTestObj.SecretValue);
end;

{ TTestReadOnlyPropsOverrides }

function TTestReadOnlyPropsOverrides.Config(AIgnore: Boolean): INeonConfiguration;
begin
  Result := TNeonConfiguration.Default.SetIgnoreReadOnlyProps(AIgnore);
end;

procedure TTestReadOnlyPropsOverrides.Setup;
begin
  FTestObj := TReadOnlyOverrides.Create;
  FTestObj.Seed;
end;

procedure TTestReadOnlyPropsOverrides.TearDown;
begin
  FTestObj.Free;
end;

procedure TTestReadOnlyPropsOverrides.TestOverridesWinOverTheFlag(const AIgnore: Boolean;
  const _Result: string);
begin
  Assert.AreEqual(_Result, TTestUtils.SerializeObject(FTestObj, Config(AIgnore)));
end;

procedure TTestReadOnlyPropsOverrides.TestOnlyNeonSetterMakesAReadOnlyPropWritable;
begin
  TTestUtils.DeserializeObject(
    '{"Always":"from json","Plain":"from json","Version":"2.0"}',
    FTestObj, Config(True));

  Assert.AreEqual('always', FTestObj.Always, 'NeonInclude(Always) does not add a setter');
  Assert.AreEqual('plain', FTestObj.Plain, 'Plain');
  Assert.AreEqual('2.0', FTestObj.Version, 'NeonSetter does add one');
end;

{ TTestReadOnlyPropsFields }

procedure TTestReadOnlyPropsFields.TestFieldsAreNeverReadOnly(const AIgnore: Boolean;
  const _Result: string);
var
  LConfig: INeonConfiguration;
  LFields: TReadOnlyFields;
begin
  LConfig := TNeonConfiguration.Default
    .SetMembers([TNeonMembers.Fields])
    .SetIgnoreReadOnlyProps(AIgnore);

  LFields := TReadOnlyFields.Create;
  try
    LFields.Id := 42;
    LFields.Name := 'Paolo';

    Assert.AreEqual(_Result, TTestUtils.SerializeObject(LFields, LConfig));
  finally
    LFields.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestReadOnlyProps);
  TDUnitX.RegisterTestFixture(TTestReadOnlyPropsDeserialize);
  TDUnitX.RegisterTestFixture(TTestReadOnlyPropsOverrides);
  TDUnitX.RegisterTestFixture(TTestReadOnlyPropsFields);

end.
