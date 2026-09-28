{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Tests.Serializer;

interface

uses
  System.Rtti, DUnitX.TestFramework,

  Neon.Tests.Entities,
  Neon.Tests.Utils;

type

  [TestFixture]
  TTestSerializer = class(TObject)
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    [TestCase('TestBoolTrue', 'True,True')]
    [TestCase('TestBoolFalse', 'False,False')]
    procedure TestSerializer(const AValue: Boolean; const _Result: string);

  end;

implementation

procedure TTestSerializer.Setup;
begin

end;

procedure TTestSerializer.TearDown;
begin
end;

procedure TTestSerializer.TestSerializer(const AValue: Boolean; const _Result: string);
var
  LJSON: string;
begin
  // The value keeps its JSON text ...
  LJSON := TTestUtils.SerializeValue(AValue);
  Assert.AreEqual(_Result, LJSON);

  // ... and that text reads back as the value it came from
  Assert.AreEqual(AValue, TTestUtils.DeserializeValueTo<Boolean>(LJSON));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestSerializer);

end.
