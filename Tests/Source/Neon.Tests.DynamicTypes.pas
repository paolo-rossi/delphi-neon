{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Tests.DynamicTypes;

interface

uses
  System.SysUtils, System.Classes, System.Rtti, System.JSON, DUnitX.TestFramework,

  Neon.Core.DynamicTypes,
  Neon.Core.Persistence,
  Neon.Core.Persistence.JSON,
  Neon.Core.Types;

type
  TCountingEnumerator = class
  public
    class var InstanceCount: Integer;
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
  end;

  TNearMissList = class
  public
    function GetEnumerator: TCountingEnumerator;
    procedure Clear;
    function Add(const AValue: Integer): Integer;
    function GetCount: Integer;
    property Count: Integer read GetCount;
  end;

  TIntArray3 = array[0..2] of Integer;

  TCountedArrayItem = class
  public
    class var InstanceCount: Integer;
    constructor Create;
    destructor Destroy; override;
  end;

  TStaticItems = array[0..1] of TCountedArrayItem;

  TStaticItemHolder = class
  private
    FItems: TStaticItems;
  public
    destructor Destroy; override;
    property Items: TStaticItems read FItems write FItems;
  end;

  TTestStreamable = class
  public
    procedure LoadFromStream(AStream: TStream);
    procedure SaveToStream(AStream: TStream);
  end;

  [TestFixture]
  TTestDynamicTypes = class(TObject)
  public
    [Test]
    procedure TestListGuessTypeFreesEnumerator;

    [Test]
    procedure TestJSONToArrayDynamic;

    [Test]
    procedure TestJSONToArrayStatic;

    [Test]
    procedure TestStaticArrayTooLongRaises;

    [Test]
    procedure TestStaticArrayReplacesWithoutLeak;

    [Test]
    procedure TestStreamableMissingValueRaises;
  end;

implementation

{ TCountingEnumerator }

constructor TCountingEnumerator.Create;
begin
  inherited;
  Inc(TCountingEnumerator.InstanceCount);
end;

destructor TCountingEnumerator.Destroy;
begin
  Dec(TCountingEnumerator.InstanceCount);
  inherited;
end;

procedure TCountingEnumerator.Reset;
begin
end;

{ TNearMissList }

function TNearMissList.Add(const AValue: Integer): Integer;
begin
  Result := 0;
end;

procedure TNearMissList.Clear;
begin
end;

function TNearMissList.GetCount: Integer;
begin
  Result := 0;
end;

function TNearMissList.GetEnumerator: TCountingEnumerator;
begin
  Result := TCountingEnumerator.Create;
end;

{ TTestDynamicTypes }

procedure TTestDynamicTypes.TestListGuessTypeFreesEnumerator;
var
  LList: TNearMissList;
  LGuess: IDynamicList;
begin
  TCountingEnumerator.InstanceCount := 0;
  LList := TNearMissList.Create;
  try
    // TNearMissList passes the enumerable shape checks (GetEnumerator, Clear,
    // Add, Count) but its enumerator lacks Current/MoveNext, so GuessType
    // allocates a probing enumerator and then fails the validation
    LGuess := TDynamicList.GuessType(LList);
    Assert.IsTrue(not Assigned(LGuess));
    // the probing enumerator must be freed on the failed guess
    Assert.AreEqual(0, TCountingEnumerator.InstanceCount);
  finally
    LList.Free;
  end;
end;

procedure TTestDynamicTypes.TestJSONToArrayDynamic;
var
  LCtx: TRttiContext;
  LDes: TNeonDeserializerJSON;
  LJSON: TJSONValue;
  LValue: TValue;
  LResult: TArray<Integer>;
begin
  LJSON := TJSONObject.ParseJSONValue('[1,2,3]');
  if not Assigned(LJSON) then
    raise Exception.Create('Error parsing JSON string');

  LDes := TNeonDeserializerJSON.Create(TNeonConfiguration.Default);
  try
    LValue := LDes.JSONToArray(LJSON, LCtx.GetType(TypeInfo(TArray<Integer>)));
    LResult := LValue.AsType<TArray<Integer>>;
    Assert.AreEqual(3, Length(LResult));
    Assert.AreEqual(2, LResult[1]);
  finally
    LDes.Free;
    LJSON.Free;
  end;
end;

procedure TTestDynamicTypes.TestJSONToArrayStatic;
var
  LCtx: TRttiContext;
  LDes: TNeonDeserializerJSON;
  LJSON: TJSONValue;
  LValue: TValue;
  LResult: TIntArray3;
begin
  LJSON := TJSONObject.ParseJSONValue('[10,20,30]');
  if not Assigned(LJSON) then
    raise Exception.Create('Error parsing JSON string');

  LDes := TNeonDeserializerJSON.Create(TNeonConfiguration.Default);
  try
    LValue := LDes.JSONToArray(LJSON, LCtx.GetType(TypeInfo(TIntArray3)));
    LResult := LValue.AsType<TIntArray3>;
    Assert.AreEqual(3, Length(LResult));
    Assert.AreEqual(30, LResult[2]);
  finally
    LDes.Free;
    LJSON.Free;
  end;
end;

{ TCountedArrayItem }

constructor TCountedArrayItem.Create;
begin
  inherited;
  Inc(TCountedArrayItem.InstanceCount);
end;

destructor TCountedArrayItem.Destroy;
begin
  Dec(TCountedArrayItem.InstanceCount);
  inherited;
end;

{ TStaticItemHolder }

destructor TStaticItemHolder.Destroy;
var
  I: Integer;
begin
  for I := 0 to High(FItems) do
    FItems[I].Free;
  inherited;
end;

{ TTestStreamable }

procedure TTestStreamable.LoadFromStream(AStream: TStream);
begin
end;

procedure TTestStreamable.SaveToStream(AStream: TStream);
begin
end;

procedure TTestDynamicTypes.TestStaticArrayTooLongRaises;
var
  LCtx: TRttiContext;
  LDes: TNeonDeserializerJSON;
  LJSON: TJSONValue;
begin
  LJSON := TJSONObject.ParseJSONValue('[1,2,3,4]');
  if not Assigned(LJSON) then
    raise Exception.Create('Error parsing JSON string');

  LDes := TNeonDeserializerJSON.Create(TNeonConfiguration.Default);
  try
    // A JSON array longer than the static bounds must raise a Neon error,
    // not a raw range exception from SetArrayElement
    try
      LDes.JSONToTValue(LJSON, LCtx.GetType(TypeInfo(TIntArray3)));
      Assert.Fail('Expected ENeonException for an over-long static array');
    except
      on E: ENeonException do
        ;
    end;
  finally
    LDes.Free;
    LJSON.Free;
  end;
end;

procedure TTestDynamicTypes.TestStaticArrayReplacesWithoutLeak;
var
  LDes: TNeonDeserializerJSON;
  LJSON: TJSONValue;
  LHolder: TStaticItemHolder;
  LItems: TStaticItems;
begin
  TCountedArrayItem.InstanceCount := 0;
  LItems[0] := TCountedArrayItem.Create;
  LItems[1] := TCountedArrayItem.Create;
  LHolder := TStaticItemHolder.Create;
  try
    LHolder.Items := LItems;
    Assert.AreEqual(2, TCountedArrayItem.InstanceCount);

    LJSON := TJSONObject.ParseJSONValue('{"Items":[{},{}]}');
    if not Assigned(LJSON) then
      raise Exception.Create('Error parsing JSON string');
    LDes := TNeonDeserializerJSON.Create(TNeonConfiguration.Default);
    try
      LDes.JSONToObject(LHolder, LJSON);
    finally
      LDes.Free;
      LJSON.Free;
    end;

    // Deserializing into an existing static array replaces the stored
    // elements: the previous objects are freed (the deserializer owns the
    // contents it replaces) and fresh ones are created. Had the old objects
    // been left behind the count would be four; keeping it at two proves
    // the replace-and-free behaviour without a leak
    Assert.AreEqual(2, TCountedArrayItem.InstanceCount);
    Assert.IsNotNull(LHolder.Items[0]);
    Assert.IsNotNull(LHolder.Items[1]);
  finally
    LHolder.Free;
  end;
end;

procedure TTestDynamicTypes.TestStreamableMissingValueRaises;
var
  LDes: TNeonDeserializerJSON;
  LJSON: TJSONValue;
  LStreamable: TTestStreamable;
begin
  LStreamable := TTestStreamable.Create;
  try
    LJSON := TJSONObject.ParseJSONValue('{"foo":1}');
    if not Assigned(LJSON) then
      raise Exception.Create('Error parsing JSON string');
    LDes := TNeonDeserializerJSON.Create(TNeonConfiguration.Default);
    try
      // The original streamable instance expects {"$value": ...}; an object
      // without it must raise a Neon error instead of dereferencing nil
      try
        LDes.JSONToObject(LStreamable, LJSON);
        Assert.Fail('Expected ENeonException for a streamable object without $value');
      except
        on E: ENeonException do
          ;
      end;
    finally
      LDes.Free;
      LJSON.Free;
    end;
  finally
    LStreamable.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDynamicTypes);

end.
