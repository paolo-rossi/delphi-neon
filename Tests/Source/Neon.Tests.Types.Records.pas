{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Tests.Types.Records;

interface

uses
  System.Rtti, DUnitX.TestFramework,

  Neon.Tests.Entities,
  Neon.Tests.Utils;

type

  [TestFixture]
  [Category('recordtypes')]
  TTestRecordTypes = class(TObject)
  private
    FSimpleRecord: TSimpleRecord;
    FManagedrecord: TManagedRecord;
  public
    constructor Create;

    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    [TestCase('TestSimpleRecord', '{"Name":"Paolo","BirthDate":"1969-02-02T03:23:54.000Z","Age":50}', '|')]
    procedure TestSimpleRecord(_Result: string);

    [Test]
    [TestCase('TestManagedRecord', '{"Name":"Luca","Age":43,"Height":1.8}', '|')]
    procedure TestManagedRecord(_Result: string);
  end;

implementation

uses
  System.DateUtils;

constructor TTestRecordTypes.Create;
begin
  FSimpleRecord.Name := 'Paolo';
  FSimpleRecord.BirthDate := EncodeDateTime(1969, 02, 02, 03, 23, 54, 0);
  FSimpleRecord.Age := 50;

  FManagedrecord.Name := 'Luca';
  FManagedrecord.Age := 43;
  FManagedrecord.Height := 1.80;
end;

procedure TTestRecordTypes.Setup;
begin
end;

procedure TTestRecordTypes.TearDown;
begin
end;

procedure TTestRecordTypes.TestManagedRecord(_Result: string);
begin
  Assert.AreEqual(_Result, TTestUtils.SerializeValue(TValue.From<TManagedRecord>(FManagedRecord)));
end;

procedure TTestRecordTypes.TestSimpleRecord(_Result: string);
begin
  Assert.AreEqual(_Result, TTestUtils.SerializeValue(TValue.From<TSimpleRecord>(FSimpleRecord)));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRecordTypes);

end.
