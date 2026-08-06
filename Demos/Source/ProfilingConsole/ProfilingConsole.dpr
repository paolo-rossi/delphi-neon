{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                }
{  Copyright (c) 2018 Paolo Rossi                                             }
{  https://github.com/paolo-rossi/neon-library                                }
{                                                                              }
{  Licensed under the MIT license                                             }
{                                                                              }
{******************************************************************************}
program ProfilingConsole;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Diagnostics,
  System.JSON,

  Neon.Core.Utils,
  Neon.Core.Persistence,
  Neon.Core.Persistence.JSON,

  ProfilingConsole.Entities in 'ProfilingConsole.Entities.pas';

const
  /// <summary>
  ///   Scenario A: one small flat object, run through this many separate
  ///   TNeon calls.
  /// </summary>
  FLAT_CALLS = 5000;

  /// <summary>
  ///   Scenarios B and C: how many objects go through a single TNeon call,
  ///   and how many times that call is repeated.
  /// </summary>
  COLLECTION_SIZE = 5000;
  COLLECTION_RUNS = 5;
  CUSTOMER_SIZE   = 1000;
  CUSTOMER_RUNS   = 5;

  /// <summary>
  ///   Set to False to profile serialization only.
  /// </summary>
  PROFILE_DESERIALIZE = True;

/// <summary>
///   Runs a serialize and a deserialize closure ARuns times with the
///   TNeonLogger profiler enabled, then prints the per-section breakdown.
///   A warm-up pass runs first, outside the measured window. The two
///   directions are guarded independently so that a failure in one still
///   leaves usable numbers for the other.
/// </summary>
procedure RunScenario(const ATitle, ANote: string; ARuns: Integer;
  ASerialize, ADeserialize: TProc);
var
  LIndex: Integer;
  LWatch: TStopwatch;
  LElapsed: Double;
begin
  WriteLn;
  WriteLn('==============================================================');
  WriteLn(' ', ATitle);
  WriteLn('==============================================================');
  WriteLn(ANote);

  // Warm-up: primes RTTI/serializer caches so first-call costs do not land
  // in the numbers below
  try
    ASerialize();
    if PROFILE_DESERIALIZE then
      ADeserialize();
  except
    on E: Exception do
    begin
      WriteLn(Format('  Warm-up FAILED: [%s] %s', [E.ClassName, E.Message]));
      Exit;
    end;
  end;

  TNeonLogger.ProfileReset;
  TNeonLogger.ProfileEnabled := True;
  LWatch := TStopwatch.StartNew;
  try
    try
      for LIndex := 1 to ARuns do
        ASerialize();
    except
      on E: Exception do
        WriteLn(Format('  Serialize FAILED: [%s] %s', [E.ClassName, E.Message]));
    end;

    if PROFILE_DESERIALIZE then
    try
      for LIndex := 1 to ARuns do
        ADeserialize();
    except
      on E: Exception do
        WriteLn(Format('  Deserialize FAILED: [%s] %s', [E.ClassName, E.Message]));
    end;
  finally
    LWatch.Stop;
    TNeonLogger.ProfileEnabled := False;
  end;
  LElapsed := LWatch.Elapsed.TotalMilliseconds;

  WriteLn(Format('Wall clock: %.1f ms total (%d passes per direction)', [LElapsed, ARuns]));
  WriteLn;
  WriteLn(TNeonLogger.ProfileReport);
end;

/// <summary>
///   One flat object per TNeon call. Every call builds a fresh
///   TNeonSerializerJSON and therefore a fresh member registry, so the
///   per-type caches cannot amortize: this measures Neon's fixed per-call
///   setup cost.
/// </summary>
procedure ProfileFlatSingle(AConfig: INeonConfiguration);
var
  LPerson: TPerson;
  LJson: string;
begin
  LPerson := TEntityFactory.CreatePerson;
  try
    LJson := TNeon.ObjectToJSONString(LPerson, AConfig);
    WriteLn;
    WriteLn('Sample JSON (flat): ', LJson);

    RunScenario(
      Format('A. Single flat object, %d separate TNeon calls', [FLAT_CALLS]),
      'Worst case for the per-type caches: each call rebuilds the member' + sLineBreak +
      'registry from scratch, so Core:PrepareMembers runs once per call.',
      FLAT_CALLS,
      procedure
      var
        LValue: TJSONValue;
      begin
        LValue := TNeon.ObjectToJSON(LPerson, AConfig);
        LValue.Free;
      end,
      procedure
      var
        LObj: TPerson;
      begin
        LObj := TNeon.JSONToObject<TPerson>(LJson, AConfig);
        LObj.Free;
      end);
  finally
    LPerson.Free;
  end;
end;

/// <summary>
///   Many flat objects inside ONE TNeon call. This is where the per-type
///   member cache pays off: Core:PrepareMembers should run a handful of times
///   in total rather than once per object.
/// </summary>
procedure ProfileFlatCollection(AConfig: INeonConfiguration);
var
  LSource: TPeopleEnvelope;
  LJson: string;
begin
  LSource := TEntityFactory.CreatePeople(COLLECTION_SIZE);
  try
    LJson := TNeon.ObjectToJSONString(LSource, AConfig);

    RunScenario(
      Format('B. %d flat objects per call, %d calls', [COLLECTION_SIZE, COLLECTION_RUNS]),
      'Best case for the per-type caches: the member list, the resolved JSON' + sLineBreak +
      'names and the type-level serializable decision are computed once and' + sLineBreak +
      'reused for every object handled within the call.',
      COLLECTION_RUNS,
      procedure
      var
        LValue: TJSONValue;
      begin
        LValue := TNeon.ObjectToJSON(LSource, AConfig);
        LValue.Free;
      end,
      procedure
      var
        LObj: TPeopleEnvelope;
      begin
        LObj := TNeon.JSONToObject<TPeopleEnvelope>(LJson, AConfig);
        LObj.Free;
      end);
  finally
    LSource.Free;
  end;
end;

/// <summary>
///   Composite objects (nested object, object array, string array, enum,
///   dictionary). Exercises the per-element WriteDataMember/ReadDataMember
///   entry overload and the TDynamic*.GuessType probes, neither of which is
///   cached today.
/// </summary>
procedure ProfileCustomerCollection(AConfig: INeonConfiguration);
var
  LSource: TCustomersEnvelope;
  LJson: string;
begin
  LSource := TEntityFactory.CreateCustomers(CUSTOMER_SIZE);
  try
    LJson := TNeon.ObjectToJSONString(LSource, AConfig);

    RunScenario(
      Format('C. %d composite objects per call, %d calls', [CUSTOMER_SIZE, CUSTOMER_RUNS]),
      'Nested object + object array + string array + enum + dictionary.' + sLineBreak +
      'Watch Serialize:RttiResolve and the Dynamic:Guess* rows here: both are' + sLineBreak +
      'paid per element and are NOT cached per type.',
      CUSTOMER_RUNS,
      procedure
      var
        LValue: TJSONValue;
      begin
        LValue := TNeon.ObjectToJSON(LSource, AConfig);
        LValue.Free;
      end,
      procedure
      var
        LObj: TCustomersEnvelope;
      begin
        LObj := TNeon.JSONToObject<TCustomersEnvelope>(LJson, AConfig);
        LObj.Free;
      end);
  finally
    LSource.Free;
  end;
end;

var
  LConfig: INeonConfiguration;
begin
  ReportMemoryLeaksOnShutdown := True;
  try
    WriteLn('==============================================================');
    WriteLn(' Neon Profiling Console');
    WriteLn('==============================================================');
    WriteLn('Breaks Neon''s own Serialize/Deserialize work down by internal');
    WriteLn('stage. Timings are INCLUSIVE of nested calls (e.g. Serialize:Object');
    WriteLn('includes the Serialize:Members time spent writing its own fields),');
    WriteLn('so rows do not sum to the grand total - they show where time is');
    WriteLn('nested, not a flat, mutually-exclusive breakdown.');
    WriteLn;
    WriteLn('NOTE: TNeon.ObjectToJSON creates a new serializer (and a new member');
    WriteLn('registry) per call, so every per-type cache is scoped to a single');
    WriteLn('call. Compare scenario A against B to see what that costs.');

    LConfig := TNeonConfiguration.Default;

    ProfileFlatSingle(LConfig);
    ProfileFlatCollection(LConfig);
    ProfileCustomerCollection(LConfig);
  except
    on E: Exception do
      WriteLn(E.ClassName, ': ', E.Message);
  end;

  WriteLn;
  WriteLn('Done. Press ENTER to exit...');
  ReadLn;
end.
