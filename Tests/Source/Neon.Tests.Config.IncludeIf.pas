{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Tests.Config.IncludeIf;

interface

uses
  System.SysUtils, System.Rtti, DUnitX.TestFramework,

  Neon.Core.Types,
  Neon.Core.Attributes,
  Neon.Core.Persistence,
  Neon.Tests.Utils;

type
  /// <summary>
  ///   Members decided by a [NeonInclude(IncludeIf.CustomFunction)] method are
  ///   the only ones whose serializability depends on the instance: every other
  ///   check is type-level and resolved once per type. ShouldInclude is public
  ///   on purpose, so the fixture does not need an {$RTTI EXPLICIT METHODS}
  ///   directive to let Neon find it.
  /// </summary>
  TIncludeIfClass = class
  private
    FName: string;
    FSecret: string;
    FNote: string;
    FIgnored: string;
  public
    // Public *field*: not serialized, because for classes the Standard member
    // choice means properties only
    IncludeSecret: Boolean;

    function ShouldInclude(const AContext: TNeonIgnoreIfContext): Boolean;

    property Name: string read FName write FName;

    [NeonInclude(IncludeIf.CustomFunction)]
    property Secret: string read FSecret write FSecret;

    property Note: string read FNote write FNote;

    // NeonIgnore wins over the include function, which is never called here
    [NeonIgnore]
    [NeonInclude(IncludeIf.CustomFunction)]
    property Ignored: string read FIgnored write FIgnored;
  end;

  /// <summary>
  ///   Two instances of the same type inside a single serialization: they share
  ///   one cached member list, so each must still get its own answer from the
  ///   include function while the type-level decisions stay put.
  /// </summary>
  TIncludeIfPair = class
  private
    FFirst: TIncludeIfClass;
    FSecond: TIncludeIfClass;
  public
    constructor Create;
    destructor Destroy; override;

    property First: TIncludeIfClass read FFirst;
    property Second: TIncludeIfClass read FSecond;
  end;

  [TestFixture]
  [Category('includeif')]
  TTestIncludeIf = class(TObject)
  private
    FTestObj: TIncludeIfClass;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    [TestCase('TestFunctionIncludes', 'True|{"Name":"Paolo","Secret":"hidden","Note":"note"}', '|')]
    [TestCase('TestFunctionExcludes', 'False|{"Name":"Paolo","Note":"note"}', '|')]
    procedure TestCustomFunction(const AInclude: Boolean; const _Result: string);

    /// <summary>
    ///   The include function must be re-evaluated for every serialization,
    ///   and the members it does not govern must be unaffected either way
    /// </summary>
    [Test]
    procedure TestReEvaluatedBetweenCalls;

    /// <summary>
    ///   Two instances of the same type in one serialization: the second must
    ///   not inherit the first one's decision (nor overwrite it)
    /// </summary>
    [Test]
    procedure TestPerInstanceInsideSingleCall;

    /// <summary>
    ///   An include function returning True wins over the type-level
    ///   exclusions, the ignore list included
    /// </summary>
    [Test]
    [TestCase('TestIncludeBeatsIgnoreList', 'True|{"Name":"Paolo","Secret":"hidden","Note":"note"}', '|')]
    [TestCase('TestExcludeWithIgnoreList', 'False|{"Name":"Paolo","Note":"note"}', '|')]
    procedure TestCustomFunctionVsIgnoreList(const AInclude: Boolean; const _Result: string);
  end;

implementation

{ TIncludeIfClass }

function TIncludeIfClass.ShouldInclude(const AContext: TNeonIgnoreIfContext): Boolean;
begin
  Result := IncludeSecret;
end;

{ TIncludeIfPair }

constructor TIncludeIfPair.Create;
begin
  FFirst := TIncludeIfClass.Create;
  FFirst.Name := 'First';
  FFirst.Secret := 'shown';
  FFirst.Note := 'n1';
  FFirst.IncludeSecret := True;

  FSecond := TIncludeIfClass.Create;
  FSecond.Name := 'Second';
  FSecond.Secret := 'hidden';
  FSecond.Note := 'n2';
  FSecond.IncludeSecret := False;
end;

destructor TIncludeIfPair.Destroy;
begin
  FFirst.Free;
  FSecond.Free;
  inherited;
end;

{ TTestIncludeIf }

procedure TTestIncludeIf.Setup;
begin
  FTestObj := TIncludeIfClass.Create;
  FTestObj.Name := 'Paolo';
  FTestObj.Secret := 'hidden';
  FTestObj.Note := 'note';
  FTestObj.Ignored := 'never';
end;

procedure TTestIncludeIf.TearDown;
begin
  FTestObj.Free;
end;

procedure TTestIncludeIf.TestCustomFunction(const AInclude: Boolean; const _Result: string);
var
  LConfig: INeonConfiguration;
begin
  FTestObj.IncludeSecret := AInclude;

  LConfig := TNeonConfiguration.Default;

  Assert.AreEqual(_Result, TTestUtils.SerializeObject(FTestObj, LConfig));
end;

procedure TTestIncludeIf.TestReEvaluatedBetweenCalls;
var
  LConfig: INeonConfiguration;
begin
  LConfig := TNeonConfiguration.Default;

  FTestObj.IncludeSecret := True;
  Assert.AreEqual('{"Name":"Paolo","Secret":"hidden","Note":"note"}',
    TTestUtils.SerializeObject(FTestObj, LConfig));

  FTestObj.IncludeSecret := False;
  Assert.AreEqual('{"Name":"Paolo","Note":"note"}',
    TTestUtils.SerializeObject(FTestObj, LConfig));

  FTestObj.IncludeSecret := True;
  Assert.AreEqual('{"Name":"Paolo","Secret":"hidden","Note":"note"}',
    TTestUtils.SerializeObject(FTestObj, LConfig));
end;

procedure TTestIncludeIf.TestPerInstanceInsideSingleCall;
var
  LConfig: INeonConfiguration;
  LPair: TIncludeIfPair;
begin
  LConfig := TNeonConfiguration.Default;

  LPair := TIncludeIfPair.Create;
  try
    Assert.AreEqual(
      '{"First":{"Name":"First","Secret":"shown","Note":"n1"},' +
       '"Second":{"Name":"Second","Note":"n2"}}',
      TTestUtils.SerializeObject(LPair, LConfig));
  finally
    LPair.Free;
  end;
end;

procedure TTestIncludeIf.TestCustomFunctionVsIgnoreList(const AInclude: Boolean; const _Result: string);
var
  LConfig: INeonConfiguration;
begin
  FTestObj.IncludeSecret := AInclude;

  LConfig := TNeonConfiguration.Default;
  LConfig.SetIgnoreMembers(['Secret']);

  Assert.AreEqual(_Result, TTestUtils.SerializeObject(FTestObj, LConfig));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestIncludeIf);

end.
