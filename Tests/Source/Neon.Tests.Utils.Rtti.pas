{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Tests.Utils.Rtti;

interface

uses
  System.SysUtils, System.Classes, System.Rtti, System.JSON,
  DUnitX.TestFramework,

  Neon.Core.Types,
  Neon.Core.Utils,
  Neon.Core.Persistence,
  Neon.Core.Persistence.JSON;

type
  TPlainEntity = class
  private
    FName: string;
  public
    property Name: string read FName write FName;
  end;

  TNamedEntity = class
  private
    FName: string;
  public
    constructor Create(const AName: string);

    property Name: string read FName write FName;
  end;

  /// <summary>
  ///   TRttiUtils.CreateInstance raises when it cannot build the instance and
  ///   TryCreateInstance returns nil, in every overload: the two used to
  ///   disagree, the parameterless and string families returning nil while the
  ///   array-of-TValue one raised
  /// </summary>
  [TestFixture]
  [Category('rttiutils')]
  TTestRttiUtils = class(TObject)
  public
    [Test]
    procedure TestCreateInstanceBuildsThePlainClass;

    [Test]
    procedure TestCreateInstanceRaisesForAnUnknownTypeName;

    [Test]
    procedure TestCreateInstanceRaisesForANilType;

    [Test]
    procedure TestCreateInstanceWithAStringRaisesWithoutSuchAConstructor;

    [Test]
    procedure TestCreateInstanceWithArgsRaisesWithoutSuchAConstructor;

    [Test]
    procedure TestTryCreateInstanceReturnsNilForAnUnknownTypeName;

    [Test]
    procedure TestTryCreateInstanceReturnsNilForANilType;

    [Test]
    procedure TestTryCreateInstanceReturnsNilWithoutSuchAConstructor;

    [Test]
    procedure TestJSONToObjectRaisesForANilType;
  end;

implementation

{ TNamedEntity }

constructor TNamedEntity.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
end;

{ TTestRttiUtils }

procedure TTestRttiUtils.TestCreateInstanceBuildsThePlainClass;
var
  LObject: TObject;
begin
  // The happy path of both families is unchanged
  LObject := TRttiUtils.CreateInstance(TPlainEntity);
  try
    Assert.IsTrue(LObject is TPlainEntity);
  finally
    LObject.Free;
  end;

  LObject := TRttiUtils.CreateInstance(TNamedEntity, 'Paolo');
  try
    Assert.AreEqual('Paolo', (LObject as TNamedEntity).Name, False);
  finally
    LObject.Free;
  end;
end;

procedure TTestRttiUtils.TestCreateInstanceRaisesForAnUnknownTypeName;
begin
  // Used to return nil, so a caller resolving a type by name at run time got a
  // nil object instead of being told the name was wrong
  Assert.WillRaise(
    procedure
    begin
      TRttiUtils.CreateInstance('NoSuchTypeName').Free;
    end,
    ENeonException);
end;

procedure TTestRttiUtils.TestCreateInstanceRaisesForANilType;
begin
  Assert.WillRaise(
    procedure
    begin
      TRttiUtils.CreateInstance(TRttiType(nil)).Free;
    end,
    ENeonException);
end;

procedure TTestRttiUtils.TestCreateInstanceWithAStringRaisesWithoutSuchAConstructor;
begin
  // TPlainEntity has no constructor taking a string
  Assert.WillRaise(
    procedure
    begin
      TRttiUtils.CreateInstance(TPlainEntity, 'Paolo').Free;
    end,
    ENeonException);
end;

procedure TTestRttiUtils.TestCreateInstanceWithArgsRaisesWithoutSuchAConstructor;
begin
  // This overload already raised: it is the behavior the others now share
  Assert.WillRaise(
    procedure
    begin
      TRttiUtils.CreateInstance(TPlainEntity,
        [TValue.From<string>('Paolo'), TValue.From<Integer>(42)]).Free;
    end,
    ENeonException);
end;

procedure TTestRttiUtils.TestTryCreateInstanceReturnsNilForAnUnknownTypeName;
begin
  Assert.IsFalse(Assigned(TRttiUtils.TryCreateInstance('NoSuchTypeName')));
end;

procedure TTestRttiUtils.TestTryCreateInstanceReturnsNilForANilType;
begin
  Assert.IsFalse(Assigned(TRttiUtils.TryCreateInstance(TRttiType(nil))));
end;

procedure TTestRttiUtils.TestTryCreateInstanceReturnsNilWithoutSuchAConstructor;
begin
  // What the engine uses where "cannot create" is a normal outcome
  Assert.IsFalse(Assigned(TRttiUtils.TryCreateInstance(TPlainEntity, 'Paolo')));
  Assert.IsFalse(Assigned(TRttiUtils.TryCreateInstance(TPlainEntity,
    [TValue.From<string>('Paolo'), TValue.From<Integer>(42)])));
end;

procedure TTestRttiUtils.TestJSONToObjectRaisesForANilType;
begin
  // The facade builds the instance through CreateInstance: a type that could
  // not be resolved is reported instead of dereferenced (it used to reach
  // AType.Name on a nil type)
  Assert.WillRaise(
    procedure
    begin
      TNeon.JSONToObject(TRttiType(nil), '{"Name":"Paolo"}').Free;
    end,
    ENeonException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRttiUtils);

end.
