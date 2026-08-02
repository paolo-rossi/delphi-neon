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
    //[TestCase('TestBoolTrue', 'True,True')]
    procedure TestSerializer(const AValue: Boolean);

  end;

implementation

procedure TTestSerializer.Setup;
begin

end;

procedure TTestSerializer.TearDown;
begin
end;

procedure TTestSerializer.TestSerializer(const AValue: Boolean);
begin
  //Assert.AreEqual(_Result, TTestUtils.SerializeValue(AValue));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestSerializer);

end.
