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

  TBigEnum = (E0, E1, E2, E3, E4, E5, E6, E7, E8, E9, E10, E11, E12, E13, E14, E15, E16, E17, E18, E19, E20, E21, E22, E23, E24, E25, E26, E27, E28, E29, E30, E31, E32, E33, E34, E35, E36, E37, E38, E39);
  TBigSet = set of TBigEnum;

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

    [Test]
    procedure TestBigSetSerialize;

    [Test]
    procedure TestBigSetDeserialize;
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

procedure TTestEnumTypes.TestBigSetSerialize;
var
  LSet: TBigSet;
begin
  // Elements beyond ordinal 31 (the set needs 8 bytes of storage) must not
  // be truncated to the low 32 bits
  LSet := [E0, E31, E32, E39];
  Assert.AreEqual('["E0","E31","E32","E39"]',
    TTestUtils.SerializeValue(TValue.From<TBigSet>(LSet)));
end;

procedure TTestEnumTypes.TestBigSetDeserialize;
var
  LSet: TBigSet;
begin
  LSet := TTestUtils.DeserializeValueTo<TBigSet>('["E0","E31","E32","E39"]');
  Assert.IsTrue(E0 in LSet);
  Assert.IsTrue(E31 in LSet);
  Assert.IsTrue(E32 in LSet);
  Assert.IsTrue(E39 in LSet);
  Assert.IsFalse(E1 in LSet);
  Assert.IsFalse(E38 in LSet);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestEnumTypes);

end.
