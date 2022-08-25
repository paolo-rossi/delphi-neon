unit Neon.Tests.Config.EnumAsInt;

interface

uses
  System.Classes, DUnitX.TestFramework,

  Neon.Core.Types;

type
  [TestFixture]
  [Category('enumasint')]
  TTestConfigEnumAsInt = class(TObject)
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    [TestCase('TestTDuplicates', '1,dupAccept')]
    procedure TestDeserialize(const AValue: String; _Result: TDuplicates);

    [Test]
    [TestCase('TestTDuplicates', 'dupAccept,1')]
    procedure TestSerialize(const AValue: TDuplicates; _Result: string);

    [Test]
    [TestCase('TestTDuplicates', '3,dupAccept')]
    [TestCase('TestTDuplicates', '-1,dupError')]
    procedure TestReadOutOfBounds(const AValue: String; _Result: TDuplicates);

  end;

implementation

uses
  System.Rtti, Neon.Tests.Utils, Neon.Core.Persistence;

{ TTestConfigEnumAsInt }

procedure TTestConfigEnumAsInt.Setup;
begin
end;

procedure TTestConfigEnumAsInt.TearDown;
begin
end;

procedure TTestConfigEnumAsInt.TestDeserialize(const AValue: String; _Result: TDuplicates);
var
  LConfig: INeonConfiguration;
begin
  LConfig := TNeonConfiguration.Default.SetEnumAsInt(True);
  Assert.AreEqual(_Result, TTestUtils.DeserializeValueTo<TDuplicates>(AValue, lConfig));
end;

procedure TTestConfigEnumAsInt.TestSerialize(const AValue: TDuplicates; _Result: string);
var
  LConfig: INeonConfiguration;
begin
  LConfig := TNeonConfiguration.Default.SetEnumAsInt(True);
  Assert.AreEqual(_Result, TTestUtils.SerializeValue(TValue.From<TDuplicates>(aValue), LConfig));
end;

procedure TTestConfigEnumAsInt.TestReadOutOfBounds(const AValue: String; _Result: TDuplicates);
var
  LConfig: INeonConfiguration;
begin
  LConfig := TNeonConfiguration.Default.SetEnumAsInt(True);
  Assert.WillRaise(
    procedure begin TTestUtils.DeserializeValueTo<TDuplicates>(AValue, lConfig) end,
    ENeonException
  );
end;

initialization
  TDUnitX.RegisterTestFixture(TTestConfigEnumAsInt);

end.
