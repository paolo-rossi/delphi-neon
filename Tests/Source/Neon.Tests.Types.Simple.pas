unit Neon.Tests.Types.Simple;

interface

uses
  System.Rtti, DUnitX.TestFramework,

  Neon.Tests.Entities,
  Neon.Tests.Utils;

type

  [TestFixture]
  [Category('Simple Types')]
  TTestSimpleTypes = class(TObject)
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    [TestCase('TestIntegerPos', '42,42')]
    [TestCase('TestIntegerNull', '0,0')]
    [TestCase('TestIntegerNeg', '-42,-42')]
    procedure TestInteger(const AValue: Integer; _Result: string);

    [Test]
    [TestCase('TestString', 'Lorem "Ipsum" \n \\ {}')]
    procedure TestString(const AValue: string);

    [Test]
    [TestCase('TestFloatPos', '123.42,123.42')]
    [TestCase('TestFloatNull', '0.0,0')]
    [TestCase('TestFloatNeg', '-123.42,-123.42')]
    procedure TestFloat(const AValue: Double; _Result: string);

    [Test]
    [TestCase('TestBoolTrue', 'True,True')]
    [TestCase('TestBoolFalse', 'False,False')]
    procedure TestBoolean(const AValue: Boolean; _Result: string);

    [Test]
    [TestCase('TestDateOnly', '23/12/2019,"2019-12-23T00:00:00.000Z"')]
    [TestCase('TestDateTime', '23/12/2019 01:01:01,"2019-12-23T01:01:01.000Z"')]
    [TestCase('TestTimeOnly', '01:01:01,"1899-12-30T01:01:01.000Z"')]
    procedure TestDateTime(const AValue: TDateTime; _Result: string);

  end;

implementation

procedure TTestSimpleTypes.Setup;
begin
end;

procedure TTestSimpleTypes.TearDown;
begin
end;

procedure TTestSimpleTypes.TestBoolean(const AValue: Boolean; _Result: string);
begin
  Assert.AreEqual(_Result, TTestUtils.SerializeValue(AValue));
end;

procedure TTestSimpleTypes.TestDateTime(const AValue: TDateTime; _Result: string);
begin
  Assert.AreEqual(_Result, TTestUtils.SerializeValue(TValue.From<TDateTime>(AValue)));
end;

procedure TTestSimpleTypes.TestFloat(const AValue: Double; _Result: string);
begin
  Assert.AreEqual(_Result, TTestUtils.SerializeValue(AValue));
end;

procedure TTestSimpleTypes.TestInteger(const AValue: Integer; _Result: string);
begin
  Assert.AreEqual(_Result, TTestUtils.SerializeValue(AValue));
end;

procedure TTestSimpleTypes.TestString(const AValue: string);
begin
  Assert.AreEqual('"Lorem \"Ipsum\" \\n \\\\ {}"', TTestUtils.SerializeValue(AValue));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestSimpleTypes);

end.
