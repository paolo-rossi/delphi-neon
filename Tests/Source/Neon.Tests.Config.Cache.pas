{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Tests.Config.Cache;

interface

uses
  System.SysUtils, System.Classes, System.Rtti, System.SyncObjs,
  System.TypInfo, System.JSON,
  DUnitX.TestFramework,

  Neon.Core.Persistence,
  Neon.Core.Persistence.JSON,
  Neon.Core.Types;

type
  TCacheEntity = class
  private
    FFirstName: string;
    FAge: Integer;
  public
    property FirstName: string read FFirstName write FFirstName;
    property Age: Integer read FAge write FAge;
  end;

  /// <summary>
  ///   Serialized by TMutatingSerializer, which changes the configuration in
  ///   the middle of the traversal
  /// </summary>
  TMutatorMember = class
  end;

  TMutatingSerializer = class(TCustomSerializer)
  protected
    class function GetTargetInfo: PTypeInfo; override;
    class function CanHandle(AType: PTypeInfo): Boolean; override;
  public
    function Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue; override;
    function Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue; override;
  end;

  TMutatingEntity = class
  private
    FAlpha: string;
    FMutator: TMutatorMember;
    FBravo: string;
    FCharlie: string;
    FDelta: string;
  public
    constructor Create;
    destructor Destroy; override;

    property Alpha: string read FAlpha write FAlpha;
    property Mutator: TMutatorMember read FMutator write FMutator;
    property Bravo: string read FBravo write FBravo;
    property Charlie: string read FCharlie write FCharlie;
    property Delta: string read FDelta write FDelta;
  end;

  /// <summary>
  ///   The RTTI caches (member lists and parsed type objects) belong to the
  ///   configuration and survive a top-level call, so they have to follow the
  ///   configuration's settings and stay out of each other's way across threads
  /// </summary>
  [TestFixture]
  [Category('configcache')]
  TTestConfigCache = class(TObject)
  private
    FEntity: TCacheEntity;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestRepeatedCallsWithTheSameConfig;

    [Test]
    procedure TestChangingTheCaseInvalidatesTheCache;

    [Test]
    procedure TestIgnoringAMemberInvalidatesTheCache;

    [Test]
    procedure TestTwoConfigsDoNotShareTheCache;

    [Test]
    procedure TestConcurrentUseOfOneConfig;

    [Test]
    procedure TestRuleAddedThroughAKeptReference;

    [Test]
    procedure TestChangingTheConfigMidCall;
  end;

implementation

const
  PASCAL_JSON = '{"FirstName":"Paolo","Age":42}';
  CAMEL_JSON  = '{"firstName":"Paolo","age":42}';

procedure TTestConfigCache.Setup;
begin
  FEntity := TCacheEntity.Create;
  FEntity.FirstName := 'Paolo';
  FEntity.Age := 42;
end;

procedure TTestConfigCache.TearDown;
begin
  FEntity.Free;
end;

procedure TTestConfigCache.TestRepeatedCallsWithTheSameConfig;
var
  LConfig: INeonConfiguration;
  LIndex: Integer;
begin
  // The second and third calls read the member list the first one built
  LConfig := TNeonConfiguration.Default;

  for LIndex := 1 to 3 do
    Assert.AreEqual(PASCAL_JSON, TNeon.ObjectToJSONString(FEntity, LConfig),
      Format('call %d', [LIndex]));
end;

procedure TTestConfigCache.TestChangingTheCaseInvalidatesTheCache;
var
  LConfig: INeonConfiguration;
begin
  // The JSON names are cached on the member: a case change after the first call
  // has to drop what was cached, or the new setting would be ignored
  LConfig := TNeonConfiguration.Default;
  Assert.AreEqual(PASCAL_JSON, TNeon.ObjectToJSONString(FEntity, LConfig));

  LConfig.SetMemberCase(TNeonCase.CamelCase);
  // Case-sensitive on purpose: the point of the test is the *case* of the names,
  // and DUnitX compares strings case-insensitively unless told otherwise
  Assert.AreEqual(CAMEL_JSON, TNeon.ObjectToJSONString(FEntity, LConfig), False,
    'the member case changed after the first call and must be honoured');
end;

procedure TTestConfigCache.TestIgnoringAMemberInvalidatesTheCache;
var
  LConfig: INeonConfiguration;
begin
  // Same for the type-level serializable decision, which the ignore list feeds
  LConfig := TNeonConfiguration.Default;
  Assert.AreEqual(PASCAL_JSON, TNeon.ObjectToJSONString(FEntity, LConfig));

  LConfig.AddIgnoreMembers(['Age']);
  Assert.AreEqual('{"FirstName":"Paolo"}', TNeon.ObjectToJSONString(FEntity, LConfig),
    'the ignore list changed after the first call and must be honoured');
end;

procedure TTestConfigCache.TestTwoConfigsDoNotShareTheCache;
var
  LPascal, LCamel: INeonConfiguration;
begin
  LPascal := TNeonConfiguration.Default;
  LCamel := TNeonConfiguration.Camel;

  // Alternated, so a cache shared between configurations would show up as the
  // wrong names on the second pass
  Assert.AreEqual(PASCAL_JSON, TNeon.ObjectToJSONString(FEntity, LPascal), False);
  Assert.AreEqual(CAMEL_JSON, TNeon.ObjectToJSONString(FEntity, LCamel), False);
  Assert.AreEqual(PASCAL_JSON, TNeon.ObjectToJSONString(FEntity, LPascal), False);
  Assert.AreEqual(CAMEL_JSON, TNeon.ObjectToJSONString(FEntity, LCamel), False);
end;

procedure TTestConfigCache.TestConcurrentUseOfOneConfig;
const
  THREAD_COUNT = 4;
  ITERATIONS = 100;
var
  LConfig: INeonConfiguration;
  LThreads: array[0..THREAD_COUNT - 1] of TThread;
  LFailures: array[0..THREAD_COUNT - 1] of string;
  LIndex: Integer;

  // A function, so that every worker captures its own slot rather than sharing
  // the loop variable
  function MakeWorker(ASlot: Integer): TProc;
  begin
    Result :=
      procedure
      var
        LEntity: TCacheEntity;
        LRun: Integer;
        LJSON: string;
      begin
        try
          LEntity := TCacheEntity.Create;
          try
            LEntity.FirstName := 'Paolo';
            LEntity.Age := 42;

            for LRun := 1 to ITERATIONS do
            begin
              LJSON := TNeon.ObjectToJSONString(LEntity, LConfig);
              if LJSON <> PASCAL_JSON then
              begin
                LFailures[ASlot] := Format('run %d produced %s', [LRun, LJSON]);
                Break;
              end;
            end;
          finally
            LEntity.Free;
          end;
        except
          on E: Exception do
            LFailures[ASlot] := E.ClassName + ': ' + E.Message;
        end;
      end;
  end;

begin
  // A cache shared between threads would race on the state the member list
  // carries per instance (Serializable) and on the lazily filled JSON name:
  // the configuration hands out one cache per thread precisely to avoid that
  LConfig := TNeonConfiguration.Default;

  for LIndex := 0 to THREAD_COUNT - 1 do
  begin
    LFailures[LIndex] := '';
    LThreads[LIndex] := TThread.CreateAnonymousThread(MakeWorker(LIndex));
    LThreads[LIndex].FreeOnTerminate := False;
  end;

  for LIndex := 0 to THREAD_COUNT - 1 do
    LThreads[LIndex].Start;

  try
    for LIndex := 0 to THREAD_COUNT - 1 do
      LThreads[LIndex].WaitFor;
  finally
    for LIndex := 0 to THREAD_COUNT - 1 do
      LThreads[LIndex].Free;
  end;

  for LIndex := 0 to THREAD_COUNT - 1 do
    Assert.AreEqual('', LFailures[LIndex], Format('thread %d', [LIndex]));
end;


{ TMutatingEntity }

constructor TMutatingEntity.Create;
begin
  FAlpha := 'a';
  FMutator := TMutatorMember.Create;
  FBravo := 'b';
  FCharlie := 'c';
  FDelta := 'd';
end;

destructor TMutatingEntity.Destroy;
begin
  FMutator.Free;
  inherited;
end;

{ TMutatingSerializer }

class function TMutatingSerializer.CanHandle(AType: PTypeInfo): Boolean;
begin
  Result := TypeInfoIs(AType);
end;

class function TMutatingSerializer.GetTargetInfo: PTypeInfo;
begin
  Result := TMutatorMember.ClassInfo;
end;

function TMutatingSerializer.Serialize(const AValue: TValue; ANeonObject:
    TNeonRttiObject; AContext: ISerializerContext): TJSONValue;
begin
  AContext.GetConfiguration.SetMemberCase(TNeonCase.SnakeCase);
  Result := TJSONString.Create('mutated');
end;

function TMutatingSerializer.Deserialize(AValue: TJSONValue; const AData: TValue;
    ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue;
begin
  Result := AData;
end;

procedure TTestConfigCache.TestRuleAddedThroughAKeptReference;
var
  LConfig: INeonConfiguration;
  LRules: INeonConfigurationType;
begin
  // Reading Rules used to be what dropped the caches, so a rule added through
  // a kept reference after the first call was silently ignored: the rules
  // invalidate when they change, not when the configurator is handed out
  LConfig := TNeonConfiguration.Default;
  LRules := LConfig.Rules.ForClass<TCacheEntity>;
  Assert.AreEqual(PASCAL_JSON, TNeon.ObjectToJSONString(FEntity, LConfig));

  LRules.AddIgnoreMembers(['Age']);
  Assert.AreEqual('{"FirstName":"Paolo"}', TNeon.ObjectToJSONString(FEntity, LConfig),
    'a rule added through a kept INeonConfigurationType must be honoured');
end;

procedure TTestConfigCache.TestChangingTheConfigMidCall;
var
  LConfig: INeonConfiguration;
  LEntity: TMutatingEntity;
begin
  // A custom serializer that changes the configuration while the traversal is
  // running: the setter detaches the caches from the configuration, and the
  // call in flight holds its own reference instead of reading freed member
  // plans - which used to drop every member after the mutating one
  LConfig := TNeonConfiguration.Default;
  LConfig.RegisterSerializer(TMutatingSerializer);

  LEntity := TMutatingEntity.Create;
  try
    // The names still to be computed follow the new case - the documented
    // caveat - and the mutating member's own name is computed after its value
    Assert.AreEqual(
      '{"Alpha":"a","mutator":"mutated","bravo":"b","charlie":"c","delta":"d"}',
      TNeon.ObjectToJSONString(LEntity, LConfig), False,
      'the members after the mutating one must still be written');
  finally
    LEntity.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestConfigCache);

end.
