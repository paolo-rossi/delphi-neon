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
  System.SysUtils, System.Classes, System.Rtti, System.JSON,
  System.Generics.Collections, DUnitX.TestFramework,

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

  TRecordKey = record
    Id: Integer;
  end;

  // Every class has ToString, but without a matching FromString a key cannot be
  // read back from a JSON name
  TPlainKey = class
  end;

  TIntegerKeyMap = TDictionary<Integer, string>;
  TBooleanKeyMap = TDictionary<Boolean, string>;
  TStringKeyMap = TDictionary<string, Integer>;
  TRecordKeyMap = TDictionary<TRecordKey, string>;
  TPlainKeyMap = TObjectDictionary<TPlainKey, string>;

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

    [Test]
    procedure TestIntegerMapKeyRoundTrips;

    [Test]
    procedure TestBooleanMapKeyRoundTrips;

    [Test]
    procedure TestEmptyStringMapKeyRoundTrips;

    [Test]
    procedure TestRecordMapKeyFailsBothWays;

    [Test]
    procedure TestClassMapKeyWithoutFromStringFailsBothWays;
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
    Assert.WillRaise(
      procedure begin LDes.JSONToTValue(LJSON, LCtx.GetType(TypeInfo(TIntArray3))) end,
      ENeonException
    );
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
      Assert.WillRaise(
        procedure begin LDes.JSONToObject(LStreamable, LJSON) end,
        ENeonException
      );
    finally
      LDes.Free;
      LJSON.Free;
    end;
  finally
    LStreamable.Free;
  end;
end;

function AlphaConfig: INeonConfiguration;
begin
  // Sort the pairs by name so the expected JSON does not depend on the
  // dictionary's hash order
  Result := TNeonConfiguration.Default.SetMapSort(TNeonSort.Alpha);
end;

procedure TTestDynamicTypes.TestIntegerMapKeyRoundTrips;
var
  LMap: TIntegerKeyMap;
  LJSON: string;
begin
  // An Integer key has an unambiguous text form, so it is written as the JSON
  // name and read back from it - both directions used to fail, with two
  // different errors (A20)
  LMap := TIntegerKeyMap.Create;
  try
    LMap.Add(1, 'one');
    LMap.Add(2, 'two');
    LJSON := TNeon.ObjectToJSONString(LMap, AlphaConfig);
    Assert.AreEqual('{"1":"one","2":"two"}', LJSON);
  finally
    LMap.Free;
  end;

  LMap := TIntegerKeyMap.Create;
  try
    TNeon.JSONToObject(LMap, LJSON, AlphaConfig);
    Assert.AreEqual(2, LMap.Count);
    Assert.AreEqual('one', LMap[1]);
    Assert.AreEqual('two', LMap[2]);
  finally
    LMap.Free;
  end;
end;

procedure TTestDynamicTypes.TestBooleanMapKeyRoundTrips;
var
  LMap: TBooleanKeyMap;
  LJSON: string;
begin
  LMap := TBooleanKeyMap.Create;
  try
    LMap.Add(True, 'yes');
    LMap.Add(False, 'no');
    LJSON := TNeon.ObjectToJSONString(LMap, AlphaConfig);
    Assert.AreEqual('{"false":"no","true":"yes"}', LJSON);
  finally
    LMap.Free;
  end;

  LMap := TBooleanKeyMap.Create;
  try
    TNeon.JSONToObject(LMap, LJSON, AlphaConfig);
    Assert.AreEqual(2, LMap.Count);
    Assert.AreEqual('yes', LMap[True]);
    Assert.AreEqual('no', LMap[False]);
  finally
    LMap.Free;
  end;
end;

procedure TTestDynamicTypes.TestEmptyStringMapKeyRoundTrips;
var
  LMap: TStringKeyMap;
  LJSON: string;
begin
  // An empty name is legal JSON: it used to be read as "the key could not be
  // built" and raised SNeonErrorDictKeyInvalid
  LMap := TStringKeyMap.Create;
  try
    LMap.Add('', 42);
    LJSON := TNeon.ObjectToJSONString(LMap, AlphaConfig);
    Assert.AreEqual('{"":42}', LJSON);
  finally
    LMap.Free;
  end;

  LMap := TStringKeyMap.Create;
  try
    TNeon.JSONToObject(LMap, LJSON, AlphaConfig);
    Assert.AreEqual(1, LMap.Count);
    Assert.AreEqual(42, LMap['']);
  finally
    LMap.Free;
  end;
end;

procedure TTestDynamicTypes.TestRecordMapKeyFailsBothWays;
var
  LMap: TRecordKeyMap;
  LKey: TRecordKey;
  LConfig: INeonConfiguration;
begin
  // A record key has no text form: both directions must refuse it, and with the
  // same error (A20)
  LConfig := TNeonConfiguration.Default.SetRaiseExceptions(True);

  LMap := TRecordKeyMap.Create;
  try
    LKey.Id := 1;
    LMap.Add(LKey, 'one');
    try
      TNeon.ObjectToJSONString(LMap, LConfig);
      Assert.Fail('Expected ENeonException serializing a record-keyed map');
    except
      on E: ENeonException do
        Assert.AreEqual(SNeonErrorDictKeyInvalid, E.Message);
    end;
  finally
    LMap.Free;
  end;

  LMap := TRecordKeyMap.Create;
  try
    try
      TNeon.JSONToObject(LMap, '{"1":"one"}', LConfig);
      Assert.Fail('Expected ENeonException deserializing into a record-keyed map');
    except
      on E: ENeonException do
        Assert.AreEqual(SNeonErrorDictKeyInvalid, E.Message);
    end;
  finally
    LMap.Free;
  end;
end;

procedure TTestDynamicTypes.TestClassMapKeyWithoutFromStringFailsBothWays;
var
  LMap: TPlainKeyMap;
  LConfig: INeonConfiguration;
begin
  // A class key needs both ToString and FromString: without FromString the read
  // used to add a default-constructed key instead of failing (A20)
  LConfig := TNeonConfiguration.Default.SetRaiseExceptions(True);

  LMap := TPlainKeyMap.Create([doOwnsKeys]);
  try
    LMap.Add(TPlainKey.Create, 'one');
    try
      TNeon.ObjectToJSONString(LMap, LConfig);
      Assert.Fail('Expected ENeonException serializing a class-keyed map');
    except
      on E: ENeonException do
        Assert.AreEqual(SNeonErrorDictKeyInvalid, E.Message);
    end;
  finally
    LMap.Free;
  end;

  LMap := TPlainKeyMap.Create([doOwnsKeys]);
  try
    try
      TNeon.JSONToObject(LMap, '{"one":"1"}', LConfig);
      Assert.Fail('Expected ENeonException deserializing into a class-keyed map');
    except
      on E: ENeonException do
        Assert.AreEqual(SNeonErrorDictKeyInvalid, E.Message);
    end;
  finally
    LMap.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDynamicTypes);

end.
