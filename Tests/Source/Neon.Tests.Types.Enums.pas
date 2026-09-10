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
  System.SysUtils, System.Classes, System.Rtti, System.JSON,
  System.Generics.Collections, DUnitX.TestFramework,

  Neon.Core.Attributes,
  Neon.Core.Types,
  Neon.Core.Persistence,
  Neon.Core.Persistence.JSON.Schema,
  Neon.Tests.Entities,
  Neon.Tests.Utils;

type

  TBigEnum = (E0, E1, E2, E3, E4, E5, E6, E7, E8, E9, E10, E11, E12, E13, E14, E15, E16, E17, E18, E19, E20, E21, E22, E23, E24, E25, E26, E27, E28, E29, E30, E31, E32, E33, E34, E35, E36, E37, E38, E39);
  TBigSet = set of TBigEnum;

  /// <summary>
  ///   Enums used to pin how the configured member case shapes an enum's JSON
  ///   name
  /// </summary>
  TUserType = (Admin, Guest);
  TMultiWordEnum = (LowSpeed, VeryHighSpeed);

  /// <summary>
  ///   An explicit [NeonEnumNames] spelling wins over the case setting, and a
  ///   member the attribute does not name still follows it
  /// </summary>
  [NeonEnumNames('NotKnown,InProgress')]
  TCustomNameEnum = (CNPending, CNActive);
  [NeonEnumNames('NotKnown')]
  TPartialNameEnum = (Pending, InProgress);

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

    [Test]
    procedure TestEnumFollowsLowerCase;

    [Test]
    procedure TestEnumFollowsCamelCase;

    [Test]
    procedure TestEnumFollowsSnakeCase;

    [Test]
    procedure TestEnumFollowsScreamingSnakeCase;

    [Test]
    procedure TestEnumCustomNamesWinOverTheCase;

    [Test]
    procedure TestEnumRoundTripsThroughEveryCase;

    [Test]
    procedure TestSchemaEnumFollowsMemberCase;
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

procedure TTestEnumTypes.TestEnumFollowsLowerCase;
var
  LConfig: INeonConfiguration;
begin
  LConfig := TNeonConfiguration.Default.SetMemberCase(TNeonCase.LowerCase);
  // Case-sensitive on purpose: DUnitX compares strings case-insensitively by
  // default, and the case of the name is exactly what is under test
  Assert.AreEqual('"admin"', TTestUtils.SerializeValue(TValue.From<TUserType>(Admin), LConfig), False);
  Assert.AreEqual('"guest"', TTestUtils.SerializeValue(TValue.From<TUserType>(Guest), LConfig), False);
end;

procedure TTestEnumTypes.TestEnumFollowsCamelCase;
begin
  Assert.AreEqual('"admin"', TTestUtils.SerializeValue(TValue.From<TUserType>(Admin), TNeonConfiguration.Camel), False);
  Assert.AreEqual('"veryHighSpeed"', TTestUtils.SerializeValue(TValue.From<TMultiWordEnum>(VeryHighSpeed), TNeonConfiguration.Camel), False);
end;

procedure TTestEnumTypes.TestEnumFollowsSnakeCase;
begin
  Assert.AreEqual('"very_high_speed"', TTestUtils.SerializeValue(TValue.From<TMultiWordEnum>(VeryHighSpeed), TNeonConfiguration.Snake), False);
end;

procedure TTestEnumTypes.TestEnumFollowsScreamingSnakeCase;
begin
  Assert.AreEqual('"VERY_HIGH_SPEED"', TTestUtils.SerializeValue(TValue.From<TMultiWordEnum>(VeryHighSpeed), TNeonConfiguration.ScreamingSnake), False);
end;

procedure TTestEnumTypes.TestEnumCustomNamesWinOverTheCase;
begin
  // [NeonEnumNames] supplies the spelling and wins over the case setting, the
  // way [NeonProperty] wins for a member name
  Assert.AreEqual('"InProgress"', TTestUtils.SerializeValue(TValue.From<TCustomNameEnum>(CNActive), TNeonConfiguration.Default), False);
  Assert.AreEqual('"InProgress"', TTestUtils.SerializeValue(TValue.From<TCustomNameEnum>(CNActive), TNeonConfiguration.Snake), False);

  // The override is per member, not per type: a member the attribute does not
  // name still follows the case, which is what a short array leaves behind
  Assert.AreEqual('"NotKnown"', TTestUtils.SerializeValue(TValue.From<TPartialNameEnum>(Pending), TNeonConfiguration.Snake), False);
  Assert.AreEqual('"in_progress"', TTestUtils.SerializeValue(TValue.From<TPartialNameEnum>(InProgress), TNeonConfiguration.Snake), False);
end;

procedure TTestEnumTypes.TestEnumRoundTripsThroughEveryCase;
begin
  // A name that only changes capitalization still reads back through the RTTI
  // spelling; a separator the case introduces has to be resolved by Neon
  Assert.IsTrue(VeryHighSpeed = TTestUtils.DeserializeValueTo<TMultiWordEnum>(
    TTestUtils.SerializeValue(TValue.From<TMultiWordEnum>(VeryHighSpeed), TNeonConfiguration.Camel), TNeonConfiguration.Camel));
  Assert.IsTrue(VeryHighSpeed = TTestUtils.DeserializeValueTo<TMultiWordEnum>(
    TTestUtils.SerializeValue(TValue.From<TMultiWordEnum>(VeryHighSpeed), TNeonConfiguration.Snake), TNeonConfiguration.Snake));
  Assert.IsTrue(VeryHighSpeed = TTestUtils.DeserializeValueTo<TMultiWordEnum>(
    TTestUtils.SerializeValue(TValue.From<TMultiWordEnum>(VeryHighSpeed), TNeonConfiguration.Kebab), TNeonConfiguration.Kebab));
  Assert.IsTrue(VeryHighSpeed = TTestUtils.DeserializeValueTo<TMultiWordEnum>(
    TTestUtils.SerializeValue(TValue.From<TMultiWordEnum>(VeryHighSpeed), TNeonConfiguration.ScreamingSnake), TNeonConfiguration.ScreamingSnake));
  // An explicit [NeonEnumNames] spelling is written verbatim and reads back
  Assert.IsTrue(CNActive = TTestUtils.DeserializeValueTo<TCustomNameEnum>(
    TTestUtils.SerializeValue(TValue.From<TCustomNameEnum>(CNActive), TNeonConfiguration.Snake), TNeonConfiguration.Snake));
end;

procedure TTestEnumTypes.TestSchemaEnumFollowsMemberCase;
var
  LConfig: INeonConfiguration;
  LSchema: TJSONObject;
  LEnum: TJSONArray;
  LRtti: TRttiContext;
begin
  LConfig := TNeonConfiguration.Default.SetMemberCase(TNeonCase.SnakeCase);
  LRtti := TRttiContext.Create;
  LSchema := TNeonSchemaGenerator.TypeToJSONSchema(
    LRtti.GetType(TypeInfo(TMultiWordEnum)), LConfig);
  try
    LEnum := LSchema.GetValue('enum') as TJSONArray;
    Assert.IsNotNull(LEnum, 'the enum schema must list the allowed names');
    Assert.AreEqual('low_speed', LEnum.Items[0].Value, False);
    Assert.AreEqual('very_high_speed', LEnum.Items[1].Value, False);
  finally
    LSchema.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestEnumTypes);

end.
