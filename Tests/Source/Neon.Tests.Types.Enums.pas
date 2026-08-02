{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Tests.Types.Enums;

interface

uses
  System.SysUtils, System.Classes, System.Rtti, DUnitX.TestFramework,

  Neon.Tests.Entities,
  Neon.Tests.Utils;

type

  [TestFixture]
  [Category('enumtypes')]
  TTestEnumTypes = class(TObject)
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    [TestCase('TestTDuplicates', 'dupIgnore,"dupIgnore"')]
    procedure TestDelphiEnum(const AValue: TDuplicates; _Result: string);

    [Test]
    [TestCase('TestCustomEnum', 'Decline,"Decline"')]
    procedure TestCustomEnum(const AValue: TResponseType; _Result: string);

    [Test]
    [TestCase('TestCustomNamesEnum', 'High,"Very High Speed"')]
    procedure TestCustomNames(const AValue: TSpeedType; _Result: string);
  end;

implementation

procedure TTestEnumTypes.Setup;
begin
end;

procedure TTestEnumTypes.TearDown;
begin
end;

procedure TTestEnumTypes.TestCustomNames(const AValue: TSpeedType; _Result: string);
begin
  Assert.AreEqual(_Result, TTestUtils.SerializeValue(TValue.From<TSpeedType>(AValue)));
end;

procedure TTestEnumTypes.TestDelphiEnum(const AValue: TDuplicates; _Result: string);
begin
  Assert.AreEqual(_Result, TTestUtils.SerializeValue(TValue.From<TDuplicates>(AValue)));
end;

procedure TTestEnumTypes.TestCustomEnum(const AValue: TResponseType; _Result: string);
begin
  Assert.AreEqual(_Result, TTestUtils.SerializeValue(TValue.From<TResponseType>(AValue)));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestEnumTypes);

end.
