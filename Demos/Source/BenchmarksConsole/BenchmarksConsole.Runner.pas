{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit BenchmarksConsole.Runner;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Diagnostics,
  System.Generics.Collections,
  System.Rtti,
  System.JSON,
  System.JSON.Types,
  System.JSON.Readers,
  System.JSON.Writers,
  System.JSON.Serializers,
  System.JSON.Converters,
  System.TypInfo,

  BenchmarksConsole.Entities;

type
  /// <summary>
  ///   TJsonEnumNameConverter accepts every tkEnumeration type, and in
  ///   Delphi Boolean is an enumeration - so the stock converter would
  ///   write booleans as the strings "True"/"False" instead of JSON
  ///   true/false. This variant hands booleans back to the default
  ///   primitive handling and converts only the real enums.
  /// </summary>
  TJsonNamedEnumConverter = class(TJsonEnumNameConverter)
  public
    function CanConvert(ATypeInf: PTypeInfo): Boolean; override;
  end;

  /// <summary>
  ///   System.JSON.Converters has no TStringList converter: TJsonListConverter
  ///   handles TList&lt;V&gt;, which TStringList is not. Left alone,
  ///   TJsonSerializer writes TCustomer.Tags as the list's own properties
  ///   (Sorted, CaseSensitive, CommaText, Capacity, ...) and then raises
  ///   "Unexpected type while read json array" on the way back, so the whole
  ///   Customer deserialize column would be FAILED. This one writes a plain
  ///   JSON array of strings and reads one back, and is modelled directly on
  ///   the RTL's TJsonListConverter&lt;V&gt;. CanConvert and CreateInstance
  ///   come from TJsonCustomObjectConverter&lt;TStringList&gt;, so TStringList
  ///   descendants are matched too.
  /// </summary>
  TJsonStringListConverter = class(TJsonCustomObjectConverter<TStringList>)
  public
    procedure WriteJson(const AWriter: TJsonWriter; const AValue: TValue;
      const ASerializer: TJsonSerializer); override;
    function ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo;
      const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue; override;
  end;

  TBenchResult = record
    DatasetName: string;
    ItemCount: Integer;
    LibraryName: string;
    SerializeMs: Double;
    DeserializeMs: Double;
    JsonSizeBytes: Int64;
  end;

  /// <summary>
  ///   Runs the same serialize/deserialize workload through Neon,
  ///   REST.Json and System.JSON.Serializers (TJsonSerializer), timing
  ///   each one, then reports the results to the console and to disk.
  /// </summary>
  TBenchmarkRunner = class
  private
    FResults: TList<TBenchResult>;
    FLog: TStringList;
    FOutputPath: string;
    FIterations: Integer;

    /// <summary>
    ///   Owned by the runner and registered into every TJsonSerializer it
    ///   creates (Converters is a plain TList<> that does not own its
    ///   entries), so the converters outlive each short-lived serializer.
    /// </summary>
    FEnumConverter: TJsonNamedEnumConverter;
    FDictionaryConverter: TJsonStringDictionaryConverter<string>;
    FStringListConverter: TJsonStringListConverter;

    procedure Log(const AMsg: string); overload;
    procedure Log(const AFmt: string; const AArgs: array of const); overload;

    function MeasureMs(AProc: TProc; AIterations: Integer): Double;
    function FormatMs(AMs: Double): string;

    function NewJsonSerializer: TJsonSerializer;

    function RunLibraryBench(const ALibrary, ADataset: string; AItemCount: Integer;
      ASizeBytes: Int64; ASerializeProc, ADeserializeProc: TProc): TBenchResult;

    procedure SaveSample(const APath, ADatasetName, ALibrary, ARawJson: string);
    procedure TrySaveSample(const APath, ADatasetName, ALibrary: string; AGetJson: TFunc<string>);
  public
    constructor Create(const AOutputPath: string; AIterations: Integer = 5);
    destructor Destroy; override;

    procedure RunSimpleUsersBenchmark(const ACounts: array of Integer);
    procedure RunCustomersBenchmark(const ACounts: array of Integer);

    /// <summary>
    ///   Serializes a small, fixed-size dataset with every library and saves
    ///   one pretty-printed JSON file per library, so the output can be
    ///   eyeballed/diffed for correctness (not just timed).
    /// </summary>
    procedure SaveJsonSamples;

    procedure PrintReport;
    procedure SaveReport;
  end;

implementation

uses
  System.IOUtils,
  REST.Json,

  Neon.Core.Utils,
  Neon.Core.Attributes,
  Neon.Core.Persistence,
  Neon.Core.Persistence.JSON;

/// <summary>
///   Every TJsonSerializer instance in this benchmark must be created
///   through this method. It fixes four library defaults that would break
///   the comparison against Neon/REST.Json:
///   * TJsonSerializer defaults to MemberSerialization = Fields, i.e. it
///     reflects over private fields (FID, FName, ...) instead of public
///     properties. That's not a fair comparison against Neon/REST.Json
///     (which both serialize properties), and it makes its timings
///     artificially cheap since it skips property getters/setters entirely.
///   * TJsonSerializer reads and writes enums as their ordinal number by
///     default, but the documents this benchmark feeds it (written by Neon
///     and REST.Json) carry the enum *names*. Without a converter the
///     Deserialize of any document containing an enum fails with
///     "Could not convert string to integer: osNew". The registered
///     TJsonNamedEnumConverter (a TJsonEnumNameConverter that leaves
///     Boolean alone, see its declaration) makes it read the names too -
///     and write them, so all three libraries emit the same documents.
///   * TJsonSerializer has no TDictionary support switched on by default:
///     it writes the hash table's public properties (Capacity, Count,
///     Collisions, ...) instead of the pairs, and reading that back - or
///     reading the real key/value object Neon writes - silently leaves the
///     dictionary empty, with no exception to show for it. Without the
///     converter the Customer deserialize column would be timing a member
///     that isn't being populated at all. TJsonStringDictionaryConverter<V>
///     ships in System.JSON.Converters and costs nothing measurable: with
///     it registered, TCustomer.Metadata round-trips and the timings stay
///     inside the run-to-run scatter.
///   * TJsonSerializer has no TStringList support either, and this time the
///     RTL ships no converter to register: TJsonListConverter handles
///     TList<V>, which TStringList is not. TCustomer.Tags goes out as the
///     list's own properties and the read back raises "Unexpected type while
///     read json array", which would leave the whole Customer deserialize
///     column FAILED. TJsonStringListConverter, declared above, is the one
///     converter here that had to be written rather than registered.
/// </summary>
function TBenchmarkRunner.NewJsonSerializer: TJsonSerializer;
begin
  Result := TJsonSerializer.Create;
  Result.MemberSerialization := TJsonMemberSerialization.Public;
  // Converters is a plain TList<>, it does not own what is added to it;
  // the converters are owned by the runner and outlive this serializer.
  Result.Converters.Add(FEnumConverter);
  Result.Converters.Add(FDictionaryConverter);
  Result.Converters.Add(FStringListConverter);
end;

function TJsonNamedEnumConverter.CanConvert(ATypeInf: PTypeInfo): Boolean;
begin
  Result := (ATypeInf <> TypeInfo(Boolean)) and inherited CanConvert(ATypeInf);
end;

{ TJsonStringListConverter }

procedure TJsonStringListConverter.WriteJson(const AWriter: TJsonWriter;
  const AValue: TValue; const ASerializer: TJsonSerializer);
var
  LList: TStringList;
begin
  if AValue.TryAsType(LList) then
    ASerializer.Serialize<TArray<string>>(AWriter, LList.ToStringArray)
  else
    AWriter.WriteNull;
end;

function TJsonStringListConverter.ReadJson(const AReader: TJsonReader;
  ATypeInf: PTypeInfo; const AExistingValue: TValue;
  const ASerializer: TJsonSerializer): TValue;
var
  LList: TStringList;
  LArray: TArray<string>;
begin
  if AReader.TokenType = TJsonToken.Null then
    Exit(nil);

  ASerializer.Populate<TArray<string>>(AReader, LArray);

  // Reuse the instance the owning object already created in its constructor,
  // otherwise the one it replaces is leaked.
  if AExistingValue.IsEmpty then
    LList := CreateInstance(ATypeInf, ASerializer)
  else
    LList := AExistingValue.AsType<TStringList>;

  LList.AddStrings(LArray);
  Result := TValue.From(LList);
end;

{ TBenchmarkRunner }

constructor TBenchmarkRunner.Create(const AOutputPath: string; AIterations: Integer);
begin
  inherited Create;
  FResults := TList<TBenchResult>.Create;
  FLog := TStringList.Create;
  FOutputPath := AOutputPath;
  FIterations := AIterations;
  FEnumConverter := TJsonNamedEnumConverter.Create;
  FDictionaryConverter := TJsonStringDictionaryConverter<string>.Create;
  FStringListConverter := TJsonStringListConverter.Create;
end;

destructor TBenchmarkRunner.Destroy;
begin
  FLog.Free;
  FResults.Free;
  FEnumConverter.Free;
  FDictionaryConverter.Free;
  FStringListConverter.Free;

  inherited;
end;

procedure TBenchmarkRunner.Log(const AMsg: string);
begin
  WriteLn(AMsg);
  Flush(Output);
  FLog.Add(AMsg);
end;

procedure TBenchmarkRunner.Log(const AFmt: string; const AArgs: array of const);
begin
  Log(Format(AFmt, AArgs));
end;

function TBenchmarkRunner.MeasureMs(AProc: TProc; AIterations: Integer): Double;
var
  LWatch: TStopwatch;
  LIndex: Integer;
begin
  LWatch := TStopwatch.StartNew;
  for LIndex := 1 to AIterations do
    AProc();
  LWatch.Stop;
  Result := LWatch.Elapsed.TotalMilliseconds / AIterations;
end;

function TBenchmarkRunner.FormatMs(AMs: Double): string;
begin
  if AMs < 0 then
    Result := 'FAILED'
  else
    Result := Format('%.3f', [AMs]);
end;

function TBenchmarkRunner.RunLibraryBench(const ALibrary, ADataset: string; AItemCount: Integer;
  ASizeBytes: Int64; ASerializeProc, ADeserializeProc: TProc): TBenchResult;
begin
  Result.LibraryName := ALibrary;
  Result.DatasetName := ADataset;
  Result.ItemCount := AItemCount;
  Result.JsonSizeBytes := ASizeBytes;

  // Serialize and deserialize are measured (and can fail) independently:
  // a library that can round-trip only one direction (e.g. it can write an
  // enum as an ordinal but not read one back from the string another
  // library produced) must not have its working half hidden by the other.
  try
    ASerializeProc(); // Warm-up: primes RTTI/serializer caches equally for every library
    Result.SerializeMs := MeasureMs(ASerializeProc, FIterations);
  except
    on E: Exception do
    begin
      Result.SerializeMs := -1;
      Log('  %-24s Serialize FAILED: [%s] %s', [ALibrary, E.ClassName, E.Message]);
    end;
  end;

  try
    ADeserializeProc(); // Warm-up
    Result.DeserializeMs := MeasureMs(ADeserializeProc, FIterations);
  except
    on E: Exception do
    begin
      Result.DeserializeMs := -1;
      Log('  %-24s Deserialize FAILED: [%s] %s', [ALibrary, E.ClassName, E.Message]);
    end;
  end;

  if (Result.SerializeMs >= 0) and (Result.DeserializeMs >= 0) then
    Log('  %-24s Serialize: %8.3f ms   Deserialize: %8.3f ms',
      [ALibrary, Result.SerializeMs, Result.DeserializeMs]);
end;

procedure TBenchmarkRunner.SaveSample(const APath, ADatasetName, ALibrary, ARawJson: string);
var
  LParsed: TJSONValue;
  LFileName: string;
  LPretty: string;
  LSafeLib: string;
begin
  LSafeLib := StringReplace(ALibrary, '.', '', [rfReplaceAll]);
  LSafeLib := StringReplace(LSafeLib, ' ', '', [rfReplaceAll]);
  LFileName := TPath.Combine(APath, Format('%s-%s.json', [ADatasetName, LSafeLib]));

  // Re-parse and pretty-print with Neon so every library's output is
  // formatted identically, making it easy to diff for correctness.
  LParsed := TJSONObject.ParseJSONValue(ARawJson);
  try
    if Assigned(LParsed) then
      LPretty := TNeon.Print(LParsed, True)
    else
      LPretty := ARawJson;
  finally
    LParsed.Free;
  end;

  TFile.WriteAllText(LFileName, LPretty);
  Log('  %-24s -> %s', [ALibrary, ExtractFileName(LFileName)]);
end;

procedure TBenchmarkRunner.TrySaveSample(const APath, ADatasetName, ALibrary: string; AGetJson: TFunc<string>);
var
  LJson: string;
begin
  try
    LJson := AGetJson();
    SaveSample(APath, ADatasetName, ALibrary, LJson);
  except
    on E: Exception do
      Log('  %-24s FAILED: [%s] %s', [ALibrary, E.ClassName, E.Message]);
  end;
end;

procedure TBenchmarkRunner.SaveJsonSamples;
const
  SAMPLE_COUNT = 3;
var
  LPath: string;
  LNeonConfig: INeonConfiguration;
  LSimpleSourceNeon, LSimpleSourceRestJson, LSimpleSourceSystemJson: TSimpleUsersEnvelope;
  LCustomerSourceNeon, LCustomerSourceRestJson, LCustomerSourceSystemJson: TCustomersEnvelope;
begin
  LPath := TPath.Combine(FOutputPath, 'Samples');
  ForceDirectories(LPath);
  LNeonConfig := TNeonConfiguration.Default;

  Log('');
  Log('==============================================================');
  Log(Format(' Saving correctness samples (%d items) to %s', [SAMPLE_COUNT, LPath]));
  Log('==============================================================');
  Log('Note: REST.Json lowercases the first letter of property names by');
  Log('default (its own default naming, e.g. "id" instead of "ID"). Neon');
  Log('and TJsonSerializer write enums as their names - TJsonSerializer is');
  Log('given a TJsonNamedEnumConverter by NewJsonSerializer (the RTL''s');
  Log('TJsonEnumNameConverter also matches Boolean, so it is overridden');
  Log('to leave booleans as real JSON true/false). Without a name');
  Log('converter TJsonSerializer reads and writes enums as ordinals and');
  Log('cannot read the documents the other two libraries write. Keep the');
  Log('naming difference in mind while diffing the files below.');
  Log('Also: for TDictionary<string,string> (Customer.Metadata), neither RTL');
  Log('library handles it out of the box. TJsonSerializer writes the hash');
  Log('table''s public properties (Capacity, Count, Collisions, ...) and reads');
  Log('nothing back - not even from its own output - without raising a thing,');
  Log('so NewJsonSerializer registers the RTL''s own');
  Log('TJsonStringDictionaryConverter<string>: with it the pairs round-trip and');
  Log('the timings do not move. REST.Json has no equivalent and still dumps the');
  Log('private fields (hash buckets, empty slots as -1, precomputed hash codes);');
  Log('it can reload its own output but not the key/value object Neon writes.');
  Log('A library that cannot handle a given member is reported as FAILED');
  Log('below rather than aborting the whole run.');

  LSimpleSourceNeon := TEntityFactory.CreateSimpleUsers(SAMPLE_COUNT);
  LSimpleSourceRestJson := TEntityFactory.CreateSimpleUsers(SAMPLE_COUNT);
  LSimpleSourceSystemJson := TEntityFactory.CreateSimpleUsers(SAMPLE_COUNT);
  try
    Log('simpleuser.json:');
    TrySaveSample(LPath, 'simpleuser', 'Neon',
      function: string
      begin
        Result := TNeon.ObjectToJSONString(LSimpleSourceNeon, LNeonConfig);
      end);
    TrySaveSample(LPath, 'simpleuser', 'REST.Json',
      function: string
      begin
        Result := TJson.ObjectToJsonString(LSimpleSourceRestJson);
      end);
    TrySaveSample(LPath, 'simpleuser', 'System.JSON.Serializers',
      function: string
      var
        LSerializer: TJsonSerializer;
      begin
        LSerializer := NewJsonSerializer;
        try
          Result := LSerializer.Serialize<TSimpleUsersEnvelope>(LSimpleSourceSystemJson);
        finally
          LSerializer.Free;
        end;
      end);
  finally
    LSimpleSourceNeon.Free;
    LSimpleSourceRestJson.Free;
    LSimpleSourceSystemJson.Free;
  end;

  LCustomerSourceNeon := TEntityFactory.CreateCustomers(SAMPLE_COUNT);
  LCustomerSourceRestJson := TEntityFactory.CreateCustomers(SAMPLE_COUNT);
  LCustomerSourceSystemJson := TEntityFactory.CreateCustomers(SAMPLE_COUNT);
  try
    Log('customer.json:');
    TrySaveSample(LPath, 'customer', 'Neon',
      function: string
      begin
        Result := TNeon.ObjectToJSONString(LCustomerSourceNeon, LNeonConfig);
      end);
    TrySaveSample(LPath, 'customer', 'REST.Json',
      function: string
      begin
        Result := TJson.ObjectToJsonString(LCustomerSourceRestJson);
      end);
    TrySaveSample(LPath, 'customer', 'System.JSON.Serializers',
      function: string
      var
        LSerializer: TJsonSerializer;
      begin
        LSerializer := NewJsonSerializer;
        try
          Result := LSerializer.Serialize<TCustomersEnvelope>(LCustomerSourceSystemJson);
        finally
          LSerializer.Free;
        end;
      end);
  finally
    LCustomerSourceNeon.Free;
    LCustomerSourceRestJson.Free;
    LCustomerSourceSystemJson.Free;
  end;
end;

procedure TBenchmarkRunner.RunSimpleUsersBenchmark(const ACounts: array of Integer);
var
  LCount: Integer;
  LSourceNeon, LSourceRestJson, LSourceSystemJson: TSimpleUsersEnvelope;
  LJson: string;
  LSize: Int64;
  LNeonConfig: INeonConfiguration;
begin
  Log('');
  Log('==============================================================');
  Log(' Dataset: TSimpleUser (small, flat PODO)');
  Log('==============================================================');

  for LCount in ACounts do
  begin
    // Each library serializes its own source instance instead of sharing
    // one: see the "Each library below serializes its own source instance"
    // note in SaveJsonSamples for why that matters.
    LSourceNeon := TEntityFactory.CreateSimpleUsers(LCount);
    LSourceRestJson := TEntityFactory.CreateSimpleUsers(LCount);
    LSourceSystemJson := TEntityFactory.CreateSimpleUsers(LCount);
    try
      LNeonConfig := TNeonConfiguration.Default;
      LJson := TNeon.ObjectToJSONString(LSourceNeon, LNeonConfig);
      LSize := Length(UTF8Encode(LJson));

      Log('');
      Log('--- %d items (%.1f KB JSON) ---', [LCount, LSize / 1024]);

      FResults.Add(RunLibraryBench('Neon', 'SimpleUser', LCount, LSize,
        procedure
        var
          LValue: TJSONValue;
        begin
          LValue := TNeon.ObjectToJSON(LSourceNeon, LNeonConfig);
          LValue.Free;
        end,
        procedure
        var
          LObj: TSimpleUsersEnvelope;
        begin
          LObj := TNeon.JSONToObject<TSimpleUsersEnvelope>(LJson, LNeonConfig);
          LObj.Free;
        end));

      FResults.Add(RunLibraryBench('REST.Json', 'SimpleUser', LCount, LSize,
        procedure
        var
          LStr: string;
        begin
          LStr := TJson.ObjectToJsonString(LSourceRestJson);
        end,
        procedure
        var
          LObj: TSimpleUsersEnvelope;
        begin
          LObj := TJson.JsonToObject<TSimpleUsersEnvelope>(LJson);
          LObj.Free;
        end));

      FResults.Add(RunLibraryBench('System.JSON.Serializers', 'SimpleUser', LCount, LSize,
        procedure
        var
          LStr: string;
          LSerializer: TJsonSerializer;
        begin
          LSerializer := NewJsonSerializer;
          try
            LStr := LSerializer.Serialize<TSimpleUsersEnvelope>(LSourceSystemJson);
          finally
            LSerializer.Free;
          end;
        end,
        procedure
        var
          LObj: TSimpleUsersEnvelope;
          LSerializer: TJsonSerializer;
        begin
          LSerializer := NewJsonSerializer;
          try
            LObj := LSerializer.Deserialize<TSimpleUsersEnvelope>(LJson);
            LObj.Free;
          finally
            LSerializer.Free;
          end;
        end));
    finally
      LSourceNeon.Free;
      LSourceRestJson.Free;
      LSourceSystemJson.Free;
    end;
  end;
end;

procedure TBenchmarkRunner.RunCustomersBenchmark(const ACounts: array of Integer);
var
  LCount: Integer;
  LSourceNeon, LSourceRestJson, LSourceSystemJson: TCustomersEnvelope;
  LJson: string;
  LSize: Int64;
  LNeonConfig: INeonConfiguration;
begin
  Log('');
  Log('==============================================================');
  Log(' Dataset: TCustomer (complex PODO: nested object, object array,');
  Log('          enum, TDate, TTime, Currency, TDictionary map)');
  Log('==============================================================');

  for LCount in ACounts do
  begin
    // Each library serializes its own source instance instead of sharing
    // one: see the "Each library below serializes its own source instance"
    // note in SaveJsonSamples for why that matters.
    LSourceNeon := TEntityFactory.CreateCustomers(LCount);
    LSourceRestJson := TEntityFactory.CreateCustomers(LCount);
    LSourceSystemJson := TEntityFactory.CreateCustomers(LCount);
    try
      LNeonConfig := TNeonConfiguration.Default;
      LJson := TNeon.ObjectToJSONString(LSourceNeon, LNeonConfig);
      LSize := Length(UTF8Encode(LJson));

      Log('');
      Log('--- %d items (%.1f KB JSON) ---', [LCount, LSize / 1024]);

      FResults.Add(RunLibraryBench('Neon', 'Customer', LCount, LSize,
        procedure
        var
          LValue: TJSONValue;
        begin
          LValue := TNeon.ObjectToJSON(LSourceNeon, LNeonConfig);
          LValue.Free;
        end,
        procedure
        var
          LObj: TCustomersEnvelope;
        begin
          LObj := TNeon.JSONToObject<TCustomersEnvelope>(LJson, LNeonConfig);
          LObj.Free;
        end));

      FResults.Add(RunLibraryBench('REST.Json', 'Customer', LCount, LSize,
        procedure
        var
          LStr: string;
        begin
          LStr := TJson.ObjectToJsonString(LSourceRestJson);
        end,
        procedure
        var
          LObj: TCustomersEnvelope;
        begin
          LObj := TJson.JsonToObject<TCustomersEnvelope>(LJson);
          LObj.Free;
        end));

      FResults.Add(RunLibraryBench('System.JSON.Serializers', 'Customer', LCount, LSize,
        procedure
        var
          LStr: string;
          LSerializer: TJsonSerializer;
        begin
          LSerializer := NewJsonSerializer;
          try
            LStr := LSerializer.Serialize<TCustomersEnvelope>(LSourceSystemJson);
          finally
            LSerializer.Free;
          end;
        end,
        procedure
        var
          LObj: TCustomersEnvelope;
          LSerializer: TJsonSerializer;
        begin
          LSerializer := NewJsonSerializer;
          try
            LObj := LSerializer.Deserialize<TCustomersEnvelope>(LJson);
            LObj.Free;
          finally
            LSerializer.Free;
          end;
        end));
    finally
      LSourceNeon.Free;
      LSourceRestJson.Free;
      LSourceSystemJson.Free;
    end;
  end;
end;

procedure TBenchmarkRunner.PrintReport;
var
  LResult: TBenchResult;
  LLastDataset: string;
  LLastCount: Integer;
begin
  Log('');
  Log('==============================================================');
  Log(' SUMMARY');
  Log('==============================================================');

  LLastDataset := '';
  LLastCount := -1;
  for LResult in FResults do
  begin
    if (LResult.DatasetName <> LLastDataset) or (LResult.ItemCount <> LLastCount) then
    begin
      Log('');
      Log('--- %s | %d items ---', [LResult.DatasetName, LResult.ItemCount]);
      Log('%-24s %16s %18s %12s', ['Library', 'Serialize (ms)', 'Deserialize (ms)', 'Size (KB)']);
      Log(StringOfChar('-', 74));
      LLastDataset := LResult.DatasetName;
      LLastCount := LResult.ItemCount;
    end;
    Log('%-24s %16s %18s %12.1f',
      [LResult.LibraryName, FormatMs(LResult.SerializeMs), FormatMs(LResult.DeserializeMs),
       LResult.JsonSizeBytes / 1024]);
  end;
  Log('');
end;

procedure TBenchmarkRunner.SaveReport;
var
  LResultsArray: TArray<TBenchResult>;
  LJsonValue: TJSONValue;
  LCsv: TStringList;
  LResult: TBenchResult;
  LTimestamp: string;
  LJsonFile, LCsvFile, LLogFile: string;
begin
  ForceDirectories(FOutputPath);
  LTimestamp := FormatDateTime('yyyymmdd_hhnnss', Now);

  LResultsArray := FResults.ToArray;

  // JSON report, produced with Neon itself
  LJsonValue := TNeon.ValueToJSON(TValue.From<TArray<TBenchResult>>(LResultsArray),
    TNeonConfiguration.Default.SetPrettyPrint(True));
  try
    LJsonFile := TPath.Combine(FOutputPath, Format('benchmark-results-%s.json', [LTimestamp]));
    TFile.WriteAllText(LJsonFile, TNeon.Print(LJsonValue, True));
  finally
    LJsonValue.Free;
  end;

  // CSV report
  LCsv := TStringList.Create;
  try
    LCsv.Add('Dataset,ItemCount,Library,SerializeMs,DeserializeMs,TotalMs,JsonSizeBytes');
    for LResult in LResultsArray do
      LCsv.Add(Format('%s,%d,%s,%.3f,%.3f,%.3f,%d',
        [LResult.DatasetName, LResult.ItemCount, LResult.LibraryName, LResult.SerializeMs,
         LResult.DeserializeMs, LResult.SerializeMs + LResult.DeserializeMs, LResult.JsonSizeBytes],
        TFormatSettings.Invariant));
    LCsvFile := TPath.Combine(FOutputPath, Format('benchmark-results-%s.csv', [LTimestamp]));
    LCsv.SaveToFile(LCsvFile);
  finally
    LCsv.Free;
  end;

  // Full console transcript
  LLogFile := TPath.Combine(FOutputPath, Format('benchmark-log-%s.txt', [LTimestamp]));
  FLog.SaveToFile(LLogFile);

  Log('');
  Log('Results saved to:');
  Log('  ' + LJsonFile);
  Log('  ' + LCsvFile);
  Log('  ' + LLogFile);
end;

end.
