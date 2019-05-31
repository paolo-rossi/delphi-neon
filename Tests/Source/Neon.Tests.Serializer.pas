unit Neon.Tests.Serializer;

interface

uses
  DUnitX.TestFramework;

type

  [TestFixture]
  TTestSerializer = class(TObject)
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    // Sample Methods
    // Simple single Test
    [Test]
    procedure TestInteger;
    // Test with TestCase Attribute to supply parameters.
    [Test]
    [TestCase('TestA','1,2')]
    [TestCase('TestB','3,4')]
    procedure Test2(const AValue1 : Integer;const AValue2 : Integer);
  end;

implementation

procedure TTestSerializer.Setup;
begin
end;

procedure TTestSerializer.TearDown;
begin
end;

procedure TTestSerializer.TestInteger;
begin
end;

procedure TTestSerializer.Test2(const AValue1 : Integer;const AValue2 : Integer);
begin
end;

initialization
  TDUnitX.RegisterTestFixture(TTestSerializer);
end.
