unit Neon.Tests.Types.Reference;

interface

uses
  System.SysUtils, System.Rtti, DUnitX.TestFramework,

  Neon.Tests.Entities,
  Neon.Tests.Utils;

type
  [TestFixture]
  [Category('Reference Types')]
  TTestReferenceTypes = class(TObject)
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestSimpleObject;
  end;

implementation

uses
  System.DateUtils;

procedure TTestReferenceTypes.Setup;
begin
end;

procedure TTestReferenceTypes.TearDown;
begin
end;

procedure TTestReferenceTypes.TestSimpleObject;
const
  LExpected = '{"Name":"Paolo","BirthDate":"1969-10-02T03:00:00.000Z","Age":50}';
var
  LValue: TPerson;
  LResult: string;
begin
  LValue := TPerson.Create('Paolo', 50);
  LValue.AddAddress('Via Trento, 30', 'Parma', 'Italy', True);
  LValue.AddContact(TContactType.Phone, '+39.123.4567890');
  LValue.AddContact(TContactType.Email, 'paolo@mail.com');

  LResult := TTestUtils.SerializeValue(LValue);
  Assert.AreEqual(LExpected, LResult);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestReferenceTypes);

end.
