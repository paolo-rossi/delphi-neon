{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Tests.Types.Interfaces;

interface

uses
  System.SysUtils, System.Classes, System.Rtti, System.JSON,
  DUnitX.TestFramework,

  Neon.Core.Attributes,
  Neon.Core.Persistence,
  Neon.Core.Persistence.JSON,
  Neon.Core.Types;

type
  /// <summary>
  ///   Reference counted, and without the public RefCount property that
  ///   TInterfacedObject would add to every serialized document
  /// </summary>
  TRefCounted = class(TObject, IInterface)
  private
    FRefCount: Integer;
  protected
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  end;

  TPersonFactory = class(TCustomFactory)
  public
    function Build(const AType: TRttiType; AValue: TJSONValue): TObject; override;
  end;

  TEmployeeFactory = class(TCustomFactory)
  public
    function Build(const AType: TRttiType; AValue: TJSONValue): TObject; override;
  end;

  /// <summary>
  ///   Builds something that does not implement the interface it is asked for
  /// </summary>
  TStrangerFactory = class(TCustomFactory)
  public
    function Build(const AType: TRttiType; AValue: TJSONValue): TObject; override;
  end;

  IPerson = interface
    ['{3F6E5B4A-1C77-4F9E-9C1E-9B1A0C6A6D01}']
    function GetName: string;
    procedure SetName(const AValue: string);
    property Name: string read GetName write SetName;
  end;

  /// <summary>
  ///   The factory on the interface type covers every member declared with it
  /// </summary>
  [NeonFactory(TEmployeeFactory)]
  IEmployee = interface
    ['{3F6E5B4A-1C77-4F9E-9C1E-9B1A0C6A6D02}']
    function GetCode: string;
    property Code: string read GetCode;
  end;

  INoGuid = interface
    function GetCaption: string;
    property Caption: string read GetCaption;
  end;

  TPerson = class(TRefCounted, IPerson)
  private
    FName: string;
    FAge: Integer;
    function GetName: string;
    procedure SetName(const AValue: string);
  public
    destructor Destroy; override;

    property Name: string read FName write FName;
    property Age: Integer read FAge write FAge;
  end;

  TEmployee = class(TRefCounted, IEmployee)
  private
    FCode: string;
    function GetCode: string;
  public
    property Code: string read FCode write FCode;
  end;

  TStranger = class(TRefCounted)
  private
    FName: string;
  public
    property Name: string read FName write FName;
  end;

  TPersonHolder = class
  private
    FPerson: IPerson;
  public
    [NeonFactory(TPersonFactory)]
    property Person: IPerson read FPerson write FPerson;
  end;

  TPlainHolder = class
  private
    FPerson: IPerson;
  public
    property Person: IPerson read FPerson write FPerson;
  end;

  TStrangerHolder = class
  private
    FPerson: IPerson;
  public
    [NeonFactory(TStrangerFactory)]
    property Person: IPerson read FPerson write FPerson;
  end;

  TNoGuidHolder = class
  private
    FItem: INoGuid;
  public
    [NeonFactory(TPersonFactory)]
    property Item: INoGuid read FItem write FItem;
  end;

  TEmployeeHolder = class
  private
    FEmployee: IEmployee;
  public
    property Employee: IEmployee read FEmployee write FEmployee;
  end;

  /// <summary>
  ///   An interface member is written as the object that implements it, and is
  ///   read back into that same object: the one the member already points to,
  ///   or the one its [NeonFactory] builds
  /// </summary>
  [TestFixture]
  [Category('interfaces')]
  TTestInterfaces = class(TObject)
  private
    FErrors: TStringList;

    function ConfigWithHandler: INeonConfiguration;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestSerializeTheImplementingObject;

    [Test]
    procedure TestSerializeNilInterface;

    [Test]
    procedure TestDeserializeIntoTheExistingInstance;

    [Test]
    procedure TestDeserializeThroughTheMemberFactory;

    [Test]
    procedure TestDeserializeThroughTheTypeFactory;

    [Test]
    procedure TestDeserializeTopLevelValue;

    [Test]
    procedure TestRoundTrip;

    [Test]
    procedure TestNoFactoryIsLoggedAndSkipped;

    [Test]
    procedure TestFactoryOfTheWrongClassRaises;

    [Test]
    procedure TestInterfaceWithoutGuidRaises;

    [Test]
    procedure TestTheCreatedObjectIsOwnedByTheMember;
  end;

implementation

var
  GDestroyedPersons: Integer = 0;

{ TRefCounted }

function TRefCounted.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := S_OK
  else
    Result := E_NOINTERFACE;
end;

function TRefCounted._AddRef: Integer;
begin
  Result := AtomicIncrement(FRefCount);
end;

function TRefCounted._Release: Integer;
begin
  Result := AtomicDecrement(FRefCount);
  if Result = 0 then
    Destroy;
end;

{ Factories }

function TPersonFactory.Build(const AType: TRttiType; AValue: TJSONValue): TObject;
begin
  Result := TPerson.Create;
end;

function TEmployeeFactory.Build(const AType: TRttiType; AValue: TJSONValue): TObject;
begin
  Result := TEmployee.Create;
end;

function TStrangerFactory.Build(const AType: TRttiType; AValue: TJSONValue): TObject;
begin
  Result := TStranger.Create;
end;

{ TPerson }

destructor TPerson.Destroy;
begin
  Inc(GDestroyedPersons);
  inherited;
end;

function TPerson.GetName: string;
begin
  Result := FName;
end;

procedure TPerson.SetName(const AValue: string);
begin
  FName := AValue;
end;

{ TEmployee }

function TEmployee.GetCode: string;
begin
  Result := FCode;
end;

{ TTestInterfaces }

function TTestInterfaces.ConfigWithHandler: INeonConfiguration;
begin
  Result := TNeonConfiguration.Default.SetOnError(
    procedure (const AMessage: string; AOperation: TNeonOperation)
    begin
      FErrors.Add(AMessage);
    end);
end;

procedure TTestInterfaces.Setup;
begin
  FErrors := TStringList.Create;
end;

procedure TTestInterfaces.TearDown;
begin
  FErrors.Free;
end;

procedure TTestInterfaces.TestSerializeTheImplementingObject;
var
  LHolder: TPersonHolder;
  LPerson: TPerson;
begin
  LHolder := TPersonHolder.Create;
  try
    LPerson := TPerson.Create;
    LPerson.Name := 'Paolo';
    LPerson.Age := 42;
    LHolder.Person := LPerson;

    Assert.AreEqual('{"Person":{"Name":"Paolo","Age":42}}',
      TNeon.ObjectToJSONString(LHolder));
  finally
    LHolder.Free;
  end;
end;

procedure TTestInterfaces.TestSerializeNilInterface;
var
  LHolder: TPersonHolder;
begin
  LHolder := TPersonHolder.Create;
  try
    // Omitted by default, like a nil object member
    Assert.AreEqual('{}', TNeon.ObjectToJSONString(LHolder));
  finally
    LHolder.Free;
  end;
end;

procedure TTestInterfaces.TestDeserializeIntoTheExistingInstance;
var
  LHolder: TPersonHolder;
  LPerson: TPerson;
begin
  LHolder := TPersonHolder.Create;
  try
    LPerson := TPerson.Create;
    LPerson.Name := 'Paolo';
    LPerson.Age := 42;
    LHolder.Person := LPerson;

    // No new instance: the JSON lands in the object the member points to, and
    // the member it does not mention keeps its value
    TNeon.JSONToObject(LHolder, '{"Person":{"Name":"Marco"}}', ConfigWithHandler);

    Assert.AreEqual(0, FErrors.Count);
    Assert.IsTrue(LPerson = (LHolder.Person as TObject));
    Assert.AreEqual('Marco', LPerson.Name);
    Assert.AreEqual(42, LPerson.Age);
  finally
    LHolder.Free;
  end;
end;

procedure TTestInterfaces.TestDeserializeThroughTheMemberFactory;
var
  LHolder: TPersonHolder;
begin
  LHolder := TPersonHolder.Create;
  try
    TNeon.JSONToObject(LHolder, '{"Person":{"Name":"Paolo","Age":42}}', ConfigWithHandler);

    Assert.AreEqual(0, FErrors.Count);
    Assert.IsTrue(Assigned(LHolder.Person));
    Assert.AreEqual('Paolo', LHolder.Person.Name);
    Assert.AreEqual(42, ((LHolder.Person as TObject) as TPerson).Age);
  finally
    LHolder.Free;
  end;
end;

procedure TTestInterfaces.TestDeserializeThroughTheTypeFactory;
var
  LHolder: TEmployeeHolder;
begin
  LHolder := TEmployeeHolder.Create;
  try
    // The member has no attribute of its own: the factory comes from the
    // [NeonFactory] on IEmployee
    TNeon.JSONToObject(LHolder, '{"Employee":{"Code":"A-01"}}', ConfigWithHandler);

    Assert.AreEqual(0, FErrors.Count);
    Assert.IsTrue(Assigned(LHolder.Employee));
    Assert.AreEqual('A-01', LHolder.Employee.Code);
  finally
    LHolder.Free;
  end;
end;

procedure TTestInterfaces.TestDeserializeTopLevelValue;
var
  LEmployee: IEmployee;
begin
  // The facade entry points go through the same path, with the interface type
  // itself carrying the factory
  LEmployee := TNeon.JSONToValue<IEmployee>('{"Code":"A-02"}');

  Assert.IsTrue(Assigned(LEmployee));
  Assert.AreEqual('A-02', LEmployee.Code);
end;

procedure TTestInterfaces.TestRoundTrip;
var
  LSource, LTarget: TPersonHolder;
  LPerson: TPerson;
  LJSON: string;
begin
  LSource := TPersonHolder.Create;
  try
    LPerson := TPerson.Create;
    LPerson.Name := 'Paolo';
    LPerson.Age := 42;
    LSource.Person := LPerson;
    LJSON := TNeon.ObjectToJSONString(LSource);
  finally
    LSource.Free;
  end;

  LTarget := TPersonHolder.Create;
  try
    TNeon.JSONToObject(LTarget, LJSON, ConfigWithHandler);

    Assert.AreEqual(0, FErrors.Count);
    Assert.AreEqual(LJSON, TNeon.ObjectToJSONString(LTarget));
  finally
    LTarget.Free;
  end;
end;

procedure TTestInterfaces.TestNoFactoryIsLoggedAndSkipped;
var
  LHolder: TPlainHolder;
begin
  LHolder := TPlainHolder.Create;
  try
    // Neither the member nor IPerson carries a factory, and no instance is
    // there to read into: the member stays nil and the reason is logged
    TNeon.JSONToObject(LHolder, '{"Person":{"Name":"Paolo"}}', ConfigWithHandler);

    Assert.IsFalse(Assigned(LHolder.Person));
    Assert.AreEqual(1, FErrors.Count);
    Assert.Contains(FErrors[0], 'IPerson');
  finally
    LHolder.Free;
  end;
end;

procedure TTestInterfaces.TestFactoryOfTheWrongClassRaises;
var
  LHolder: TStrangerHolder;
begin
  LHolder := TStrangerHolder.Create;
  try
    Assert.WillRaise(
      procedure
      begin
        TNeon.JSONToObject(LHolder, '{"Person":{"Name":"Paolo"}}',
          TNeonConfiguration.Default.SetRaiseExceptions(True));
      end,
      ENeonException);
  finally
    LHolder.Free;
  end;
end;

procedure TTestInterfaces.TestInterfaceWithoutGuidRaises;
var
  LHolder: TNoGuidHolder;
begin
  LHolder := TNoGuidHolder.Create;
  try
    // A factory is not enough: without a GUID no object can be asked for the
    // interface
    Assert.WillRaise(
      procedure
      begin
        TNeon.JSONToObject(LHolder, '{"Item":{"Caption":"nope"}}',
          TNeonConfiguration.Default.SetRaiseExceptions(True));
      end,
      ENeonException);
  finally
    LHolder.Free;
  end;
end;

procedure TTestInterfaces.TestTheCreatedObjectIsOwnedByTheMember;
var
  LHolder: TPersonHolder;
  LDestroyed: Integer;
begin
  LDestroyed := GDestroyedPersons;

  LHolder := TPersonHolder.Create;
  try
    TNeon.JSONToObject(LHolder, '{"Person":{"Name":"Paolo"}}', ConfigWithHandler);
    Assert.IsTrue(Assigned(LHolder.Person));
    Assert.AreEqual(LDestroyed, GDestroyedPersons);
  finally
    // The member holds the only reference to what the factory built, so
    // releasing the holder destroys it: nothing to free by hand, nothing leaked
    LHolder.Free;
  end;

  Assert.AreEqual(LDestroyed + 1, GDestroyedPersons);
end;

end.
