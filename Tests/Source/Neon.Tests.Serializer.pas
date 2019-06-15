unit Neon.Tests.Serializer;

interface

uses
  DUnitX.TestFramework,
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
    [TestCase('TestInteger', '42')]
    procedure TestInteger(const AValue: Integer);

    [Test]
    [TestCase('TestString', 'Lorem "Ipsum" \n \\ {}')]
    procedure TestString(const AValue: string);

  end;

implementation

procedure TTestSerializer.Setup;
begin
end;

procedure TTestSerializer.TearDown;
begin
end;

procedure TTestSerializer.TestInteger(const AValue: Integer);
var
  LJSON: string;
begin
  LJSON := TTestUtils.SerializeValueFrom<Integer>(AValue);
  Assert.AreEqual('42', LJSON);
end;

procedure TTestSerializer.TestString(const AValue: string);
var
  LJSON: string;
begin
  LJSON := TTestUtils.SerializeValueFrom<string>(AValue);
  Assert.AreEqual('"Lorem \"Ipsum\" \\n \\\\ {}"', LJSON);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestSerializer);

end.
