{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Tests.Attributes;

interface

uses
  System.SysUtils, System.Rtti, DUnitX.TestFramework,

  Neon.Core.Attributes,
  Neon.Core.Persistence,
  Neon.Core.Types,
  Neon.Tests.Entities,
  Neon.Tests.Utils;

type
  TRawValueHolder = class
  private
    FData: string;
  public
    [NeonRawValue]
    property Data: string read FData write FData;
  end;

  /// <summary>
  ///   [NeonRawValue] makes the member carry JSON text rather than a value, in
  ///   both directions: what is read back can be written again unchanged, and a
  ///   member that does not hold JSON is an error
  /// </summary>
  [TestFixture]
  [Category('attrrawvalue')]
  TTestAttributesRawValue = class(TObject)
  private
    FHolder: TRawValueHolder;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestRawObjectIsSpliced;

    [Test]
    procedure TestRawObjectRoundTrips;

    [Test]
    procedure TestRawScalarKeepsItsJSONText;

    [Test]
    procedure TestRawNonJSONRaises;

    [Test]
    procedure TestRawEmptyRaises;

    [Test]
    procedure TestRawMalformedRaises;
  end;

  [TestFixture]
  [Category('attrinclude')]
  TTestAttributesInclude = class(TObject)
  public
    constructor Create;
    destructor Destroy; override;

    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestIncludeIfAlways(const AMethod: string);
  end;

implementation

uses
  System.IOUtils, System.DateUtils,
  Neon.Core.Persistence.JSON;

{ TTestAttributesRawValue }

procedure TTestAttributesRawValue.Setup;
begin
  FHolder := TRawValueHolder.Create;
end;

procedure TTestAttributesRawValue.TearDown;
begin
  FHolder.Free;
end;

procedure TTestAttributesRawValue.TestRawObjectIsSpliced;
begin
  // The member holds JSON text: it is spliced into the document as the object
  // it spells, not quoted as a string
  FHolder.Data := '{"a":1}';
  Assert.AreEqual('{"Data":{"a":1}}', TNeon.ObjectToJSONString(FHolder));
end;

procedure TTestAttributesRawValue.TestRawObjectRoundTrips;
begin
  TNeon.JSONToObject(FHolder, '{"Data":{"a":1}}', TNeonConfiguration.Default);
  Assert.AreEqual('{"a":1}', FHolder.Data);
end;

procedure TTestAttributesRawValue.TestRawScalarKeepsItsJSONText;
begin
  // A scalar comes back JSON-encoded, quotes included, because that is what the
  // writer needs to read back: the round trip is what the attribute promises,
  // not "the string you would have got without it"
  TNeon.JSONToObject(FHolder, '{"Data":"abc"}', TNeonConfiguration.Default);
  Assert.AreEqual('"abc"', FHolder.Data);

  Assert.AreEqual('{"Data":"abc"}', TNeon.ObjectToJSONString(FHolder));
end;

procedure TTestAttributesRawValue.TestRawNonJSONRaises;
var
  LConfig: INeonConfiguration;
begin
  // 'abc' is not JSON - the text a plain string member would have produced is
  // '"abc"' - so it is reported, not quietly quoted or dropped
  LConfig := TNeonConfiguration.Default.SetRaiseExceptions(True);
  FHolder.Data := 'abc';

  Assert.WillRaise(
    procedure begin TNeon.ObjectToJSONString(FHolder, LConfig) end,
    ENeonException
  );
end;

procedure TTestAttributesRawValue.TestRawEmptyRaises;
var
  LConfig: INeonConfiguration;
begin
  // An empty member is not JSON either: it used to leave the member out of the
  // document without a word
  LConfig := TNeonConfiguration.Default.SetRaiseExceptions(True);
  FHolder.Data := '';

  Assert.WillRaise(
    procedure begin TNeon.ObjectToJSONString(FHolder, LConfig) end,
    ENeonException
  );
end;

procedure TTestAttributesRawValue.TestRawMalformedRaises;
var
  LConfig: INeonConfiguration;
begin
  // Truncated JSON is reported the same way, and as the same exception: the RTL
  // parser tells nil from a raise depending on how far it got, which is not a
  // distinction the member's owner can act on
  LConfig := TNeonConfiguration.Default.SetRaiseExceptions(True);
  FHolder.Data := '{"a":';

  Assert.WillRaise(
    procedure begin TNeon.ObjectToJSONString(FHolder, LConfig) end,
    ENeonException
  );
end;

{ TTestAttributesInclude }

constructor TTestAttributesInclude.Create;
begin

end;

destructor TTestAttributesInclude.Destroy;
begin

  inherited;
end;

procedure TTestAttributesInclude.Setup;
begin
end;

procedure TTestAttributesInclude.TearDown;
begin
end;

procedure TTestAttributesInclude.TestIncludeIfAlways(const AMethod: string);
begin

end;

initialization
  TDUnitX.RegisterTestFixture(TTestAttributesInclude);
  TDUnitX.RegisterTestFixture(TTestAttributesRawValue);

end.
