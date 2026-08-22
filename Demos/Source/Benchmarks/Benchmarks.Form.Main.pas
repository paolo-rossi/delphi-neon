{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Benchmarks.Form.Main;

interface

uses
  System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  VclTee.TeeGDIPlus, VCLTee.TeEngine, Vcl.ExtCtrls,
  VCLTee.TeeProcs, VCLTee.Chart, VCLTee.Series,
  Vcl.Imaging.pngimage, System.ImageList, Vcl.ImgList,
  System.Generics.Collections, System.Diagnostics, System.UITypes,
  System.Json, REST.Json, System.JSON.Serializers,

  Benchmarks.Entities;

type
  TOperationType = (Serialization, Deserialization);

  /// <summary>
  ///   The JSON libraries under test: Neon, REST.Json (TJson) and
  ///   System.JSON.Serializers (TJsonSerializer)
  /// </summary>
  TJsonLibrary = (Neon, RestJson, JsonSerializer);

const
  /// <summary>
  ///   Display name of each library, used in the log and in the name of every
  ///   file written to Data\Results
  /// </summary>
  LIB_NAMES: array [TJsonLibrary] of string = ('Neon', 'TJSON', 'TJsonSerializer');

  /// <summary>
  ///   The two entities a benchmark run leaves a single-object sample of,
  ///   named after the class so that the file says what is in it
  /// </summary>
  SAMPLE_SIMPLE = 'TUser';
  SAMPLE_COMPLEX = 'TCustomer';

type
  TBenchmarkParam = record
  public
    Scale: Integer;
    FileName: string;
    Series: TBarSeries;
    Value: Integer;
    Operation: TOperationType;
    JsonLib: TJsonLibrary;
    XLabel: string;
  end;

  TBenchmarkParams = TArray<TBenchmarkParam>;
  TBenchmarkType = (Simple, Complex);

  TfrmBenchmarks = class(TForm)
    memoLog: TMemo;
    chtSer: TChart;
    serNeonSer: TBarSeries;
    serJsonSer: TBarSeries;
    chtDes: TChart;
    serNeonDes: TBarSeries;
    serJsonDes: TBarSeries;
    pnlFooter: TPanel;
    pnlHeader: TPanel;
    imgLogo: TImage;
    btnHelp: TButton;
    grpClassType: TGroupBox;
    rbClassSimple: TRadioButton;
    rbClassComplex: TRadioButton;
    btnExecute: TButton;
    imgMain24: TImageList;
    lblDescription: TLabel;
    chkSaveResults: TCheckBox;
    lblSaveResults: TLabel;
    serSerializerSer: TBarSeries;
    serSerializerDes: TBarSeries;
    btnCorrectness: TButton;
    grpEngines: TGroupBox;
    chkNeon: TCheckBox;
    chkRestJson: TCheckBox;
    chkSerializer: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnExecuteClick(Sender: TObject);
    procedure btnHelpClick(Sender: TObject);
    procedure btnCorrectnessClick(Sender: TObject);
    procedure EnginesChanged(Sender: TObject);
  private const
    DATA_PATH = 'Data\Benchmarks';
    RESULTS_PATH = 'Data\Results';
    USER_FILENAME = 'users-%dk.json';
    CUST_FILENAME = 'customers-%dk.json';
    USER_SCALE: array [1..5] of Integer = (10, 20, 30, 40, 50);
    CUST_SCALE: array [1..5] of Integer = (1, 2, 3, 4, 5);
  var
    FDataPath: string;
    FResultPath: string;
    FSerializer: TJsonSerializer;
    FEnumConverter: TJsonConverter;

    /// <summary>
    ///   The three controls that belong to each library, looked up by the
    ///   library itself so that the benchmark can walk TJsonLibrary instead of
    ///   naming Neon, TJson and TJsonSerializer over and over
    /// </summary>
    FEngineCheck: array [TJsonLibrary] of TCheckBox;
    FSerSeries: array [TJsonLibrary] of TBarSeries;
    FDesSeries: array [TJsonLibrary] of TBarSeries;
  private
    procedure SaveResult(var AParam: TBenchmarkParam; const AJSON: string);
    procedure SaveSample<T: class>(const AParam: TBenchmarkParam; AItem: T);
    procedure ClearCharts;
    procedure BenchmarkSimpleClass;
    procedure BenchmarkComplexClass;

    /// <summary>
    ///   Runs the six measurements over one document. Generic over the pair of
    ///   classes it is given - the envelope and the entity inside it - because
    ///   System.JSON.Serializers works through Serialize&lt;T&gt; / Populate&lt;T&gt;
    ///   and wants the class at compile time.
    /// </summary>
    procedure BenchmarkFile<TEnv: TEnvelope; TItem: class>(AObject: TEnv;
      const AJSON: string; AScale: Integer);
    procedure BenchmarkSingle<TEnv: TEnvelope; TItem: class>(var AParam: TBenchmarkParam;
      AObject: TEnv; const AJSON: string; AScale: Integer);
    function LoadData(const AFile: string; AScale: Integer): string;
    function CountItems(const AJSON: string): Integer;

    procedure RestJsonToObject(AObject: TEnvelope; const AJSON: string);

    function AnyEngineSelected: Boolean;
  public
    /// <summary>
    ///   Where the single-entity sample of ALib for AEntity (SAMPLE_SIMPLE or
    ///   SAMPLE_COMPLEX) is written, and where the Correctness window reads it
    ///   back from
    /// </summary>
    function SampleFileName(ALib: TJsonLibrary; const AEntity: string): string;

    property ResultPath: string read FResultPath;
  end;

var
  frmBenchmarks: TfrmBenchmarks;

implementation

uses
  System.IOUtils,
  System.JSON.Converters,
  Neon.Core.Persistence,
  Neon.Core.Persistence.JSON,
  Benchmarks.Form.Source,
  Benchmarks.Form.JSON;

{$R *.dfm}

procedure TfrmBenchmarks.FormCreate(Sender: TObject);
begin
  FDataPath := TPath.Combine(TPath.GetDirectoryName(
    TPath.GetDirectoryName(Application.ExeName)), DATA_PATH);
  FResultPath := TPath.Combine(TPath.GetDirectoryName(
    TPath.GetDirectoryName(Application.ExeName)), RESULTS_PATH);
  ForceDirectories(FResultPath);

  FEngineCheck[TJsonLibrary.Neon] := chkNeon;
  FEngineCheck[TJsonLibrary.RestJson] := chkRestJson;
  FEngineCheck[TJsonLibrary.JsonSerializer] := chkSerializer;
  FSerSeries[TJsonLibrary.Neon] := serNeonSer;
  FSerSeries[TJsonLibrary.RestJson] := serJsonSer;
  FSerSeries[TJsonLibrary.JsonSerializer] := serSerializerSer;
  FDesSeries[TJsonLibrary.Neon] := serNeonDes;
  FDesSeries[TJsonLibrary.RestJson] := serJsonDes;
  FDesSeries[TJsonLibrary.JsonSerializer] := serSerializerDes;

  // Out of the box TJsonSerializer reflects over the *private fields* (FID,
  // FName, ...) and writes enumerations as their ordinal value. Neither
  // matches the documents in Data\Benchmarks, nor what Neon and TJson do, so
  // the serializer is told to work on the public properties and on the
  // enumeration names: the three libraries then read and write the very same
  // JSON. MemberSerialization goes through the contract resolver because
  // TJsonSerializer only got a property of its own in Delphi 13.
  FSerializer := TJsonSerializer.Create;
  FSerializer.ContractResolver := TJsonDefaultContractResolver.Create(TJsonMemberSerialization.Public);
  // Converters is a plain TList<>, it does not own what is added to it
  FEnumConverter := TJsonEnumNameConverter.Create;
  FSerializer.Converters.Add(FEnumConverter);

  ClearCharts;

  memoLog.Lines.Add('Every library converts between the objects and a JSON *string*,');
  memoLog.Lines.Add('so parsing and printing are part of each measurement.');
  memoLog.Lines.Add('----------------------------');
end;

procedure TfrmBenchmarks.FormDestroy(Sender: TObject);
begin
  FSerializer.Free;
  FEnumConverter.Free;
end;

procedure TfrmBenchmarks.BenchmarkSimpleClass;
var
  LIndex, LScale: Integer;
  LJSONFile: string;
  LObj: TUsersEnvelope;
  LCount: Integer;
begin
  ClearCharts;
  for LIndex := Low(USER_SCALE) to High(USER_SCALE) do
  begin
    LScale := USER_SCALE[LIndex];
    LObj := TUsersEnvelope.Create;
    try
      LJSONFile := LoadData(USER_FILENAME, LScale);
      LCount := CountItems(LJSONFile);
      lblDescription.Caption := Format('Benchmarking %s class (%.0n items)', ['TUser', LCount/1.0]);
      memoLog.Lines.Add(lblDescription.Caption);
      memoLog.Lines.Add('');
      Application.ProcessMessages;
      BenchmarkFile<TUsersEnvelope, TUser>(LObj, LJSONFile, LScale);
    finally
      LObj.Free;
    end;
  end;
  lblDescription.Caption := 'Finish Benchmarking TUser class';
  memoLog.Lines.Add(lblDescription.Caption);
  memoLog.Lines.Add('----------------------------');
end;

procedure TfrmBenchmarks.BenchmarkComplexClass;
var
  LCount: Integer;
  LIndex, LScale: Integer;
  LJSONFile: string;
  LObj: TCustomersEnvelope;
begin
  ClearCharts;
  for LIndex := Low(CUST_SCALE) to High(CUST_SCALE) do
  begin
    LScale := CUST_SCALE[LIndex];
    LObj := TCustomersEnvelope.Create;
    try
      LJSONFile := LoadData(CUST_FILENAME, LScale);
      LCount := CountItems(LJSONFile);
      lblDescription.Caption := Format('Benchmarking %s class (%.0n items)', ['TCustomer', LCount/1.0]);
      memoLog.Lines.Add(lblDescription.Caption);
      memoLog.Lines.Add('');
      Application.ProcessMessages;
      BenchmarkFile<TCustomersEnvelope, TCustomer>(LObj, LJSONFile, LScale);
    finally
      LObj.Free;
    end;
  end;
  lblDescription.Caption := 'Finish Benchmarking TCustomer class';
  memoLog.Lines.Add(lblDescription.Caption);
  memoLog.Lines.Add('----------------------------');
end;

/// <summary>
///   One measurement: the library named by AParam converts the whole envelope
///   one way or the other. A method of its own rather than a local procedure
///   of BenchmarkFile, which the compiler will not take inside a generic.
/// </summary>
procedure TfrmBenchmarks.BenchmarkSingle<TEnv, TItem>(var AParam: TBenchmarkParam;
  AObject: TEnv; const AJSON: string; AScale: Integer);
var
  LOp: string;
  LJSON: string;
  LWatch: TStopWatch;
begin
  LWatch := TStopwatch.StartNew;
  case AParam.Operation of
    Deserialization:
    begin
      LOp := 'Deserialization';
      case AParam.JsonLib of
        TJsonLibrary.Neon:
          TNeon.JSONToObject(AObject, AJSON, TNeonConfiguration.Default);
        TJsonLibrary.RestJson:
          RestJsonToObject(AObject, AJSON);
        TJsonLibrary.JsonSerializer:
          FSerializer.Populate<TEnv>(AJSON, AObject);
      end;

      LWatch.Stop;
    end;
    Serialization:
    begin
      LOp := 'Serialization';
      LJSON := '';
      case AParam.JsonLib of
        TJsonLibrary.Neon:
          LJSON := TNeon.ObjectToJSONString(AObject);
        TJsonLibrary.RestJson:
          LJSON := TJson.ObjectToJsonString(AObject);
        TJsonLibrary.JsonSerializer:
          LJSON := FSerializer.Serialize<TEnv>(AObject);
      end;

      LWatch.Stop;
      SaveResult(AParam, LJSON);
      SaveSample<TItem>(AParam, AObject.FirstItem as TItem);
    end;
  end;
  AParam.Value := LWatch.ElapsedMilliseconds;

  memoLog.Lines.Add(Format('%s (%s): %dmsec', [LOp, LIB_NAMES[AParam.JsonLib], AParam.Value]));
  AParam.Series.Add(AParam.Value, Format('%dK', [AScale]));
end;

procedure TfrmBenchmarks.BenchmarkFile<TEnv, TItem>(AObject: TEnv;
  const AJSON: string; AScale: Integer);
var
  LParam: TBenchmarkParam;
  LLib: TJsonLibrary;
begin
  LParam.Scale := AScale;
  if AObject is TUsersEnvelope then
    LParam.FileName := USER_FILENAME
  else
    LParam.FileName := CUST_FILENAME;

  LParam.XLabel := AScale.ToString + 'K';

  for LLib := Low(TJsonLibrary) to High(TJsonLibrary) do
  begin
    if not FEngineCheck[LLib].Checked then
      Continue;

    // every engine starts from an empty envelope and fills it itself
    AObject.Clear;
    LParam.JsonLib := LLib;

    LParam.Series := FDesSeries[LLib];
    LParam.Operation := Deserialization;
    BenchmarkSingle<TEnv, TItem>(LParam, AObject, AJSON, AScale);

    LParam.Series := FSerSeries[LLib];
    LParam.Operation := Serialization;
    BenchmarkSingle<TEnv, TItem>(LParam, AObject, AJSON, AScale);
  end;

  memoLog.Lines.Add('----------------------------');
end;

procedure TfrmBenchmarks.btnExecuteClick(Sender: TObject);
begin
  if not AnyEngineSelected then
  begin
    MessageDlg('Tick at least one engine to benchmark.', mtInformation, [mbOK], 0);
    Exit;
  end;

  Screen.Cursor := crHourGlass;
  try
  if rbClassSimple.Checked then
    BenchmarkSimpleClass
  else
    BenchmarkComplexClass;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmBenchmarks.btnHelpClick(Sender: TObject);
begin
  frmSource.Show();
end;

procedure TfrmBenchmarks.btnCorrectnessClick(Sender: TObject);
begin
  // reload every time: the samples change with each benchmark run
  frmJSON.LoadSamples;
  frmJSON.Show();
end;

procedure TfrmBenchmarks.ClearCharts;
var
  LLib: TJsonLibrary;
begin
  for LLib := Low(TJsonLibrary) to High(TJsonLibrary) do
  begin
    FSerSeries[LLib].Clear;
    FDesSeries[LLib].Clear;
  end;
  EnginesChanged(nil);
end;

/// <summary>
///   An engine left out of the run should not sit in the chart legend either.
///   Only the visibility changes: unticking a box keeps whatever that engine
///   already plotted, so a previous run is not thrown away by a stray click.
/// </summary>
procedure TfrmBenchmarks.EnginesChanged(Sender: TObject);
var
  LLib: TJsonLibrary;
begin
  for LLib := Low(TJsonLibrary) to High(TJsonLibrary) do
  begin
    FSerSeries[LLib].Active := FEngineCheck[LLib].Checked;
    FDesSeries[LLib].Active := FEngineCheck[LLib].Checked;
  end;
end;

function TfrmBenchmarks.AnyEngineSelected: Boolean;
var
  LLib: TJsonLibrary;
begin
  for LLib := Low(TJsonLibrary) to High(TJsonLibrary) do
    if FEngineCheck[LLib].Checked then
      Exit(True);
  Result := False;
end;

/// <summary>
///   Reads a data file and wraps it in the envelope the classes expect. The
///   files hold a bare array, so the envelope is just text around it: nothing
///   is parsed here, the libraries are the ones doing that (and being timed
///   for it).
/// </summary>
function TfrmBenchmarks.LoadData(const AFile: string; AScale: Integer): string;
var
  LFileName: string;
begin
  LFileName := TPath.Combine(FDataPath, Format(AFile, [AScale]));
  Result := '{"Items":' + TFile.ReadAllText(LFileName) + '}';
end;

/// <summary>
///   Counts the items of a document, only to label the chart and the log.
///   Runs outside of any measurement.
/// </summary>
function TfrmBenchmarks.CountItems(const AJSON: string): Integer;
var
  LJSON: TJSONValue;
begin
  LJSON := TJSONObject.ParseJSONValue(AJSON);
  try
    Result := ((LJSON as TJSONObject).GetValue('Items') as TJSONArray).Count;
  finally
    LJSON.Free;
  end;
end;

/// <summary>
///   Fills AObject from AJSON with REST.Json. TJson is the odd one out: it has
///   no entry point that fills an existing instance from a string (only
///   JsonToObject&lt;T&gt;, which creates one), so the parsing that TNeon and
///   TJsonSerializer do internally is spelled out here - inside the measured
///   region, where the other two also pay for it.
/// </summary>
procedure TfrmBenchmarks.RestJsonToObject(AObject: TEnvelope; const AJSON: string);
var
  LJSON: TJSONObject;
begin
  LJSON := TJSONObject.ParseJSONValue(AJSON) as TJSONObject;
  try
    TJson.JsonToObject(AObject, LJSON);
  finally
    LJSON.Free;
  end;
end;

function TfrmBenchmarks.SampleFileName(ALib: TJsonLibrary; const AEntity: string): string;
begin
  Result := TPath.Combine(FResultPath, Format('%s-%s.json', [LIB_NAMES[ALib], AEntity]));
end;

/// <summary>
///   Writes the first entity of the envelope on its own, serialized by the
///   library that has just run. At this point the envelope holds what that
///   same library read a moment earlier, so each file is one library's round
///   trip of a single record - short enough to read side by side in the
///   Correctness window, which is what these files feed.
/// </summary>
/// <remarks>
///   Unlike the full results this is not behind the "Save Results" box: the
///   documents are a few lines each, and the window has nothing to show
///   without them.
/// </remarks>
procedure TfrmBenchmarks.SaveSample<T>(const AParam: TBenchmarkParam; AItem: T);
var
  LJSON: string;
  LValue: TJSONValue;
begin
  if AItem = nil then
    Exit;

  LJSON := '';
  case AParam.JsonLib of
    TJsonLibrary.Neon:
      LJSON := TNeon.ObjectToJSONString(AItem);
    TJsonLibrary.RestJson:
      LJSON := TJson.ObjectToJsonString(AItem);
    TJsonLibrary.JsonSerializer:
      LJSON := FSerializer.Serialize<T>(AItem);
  end;

  // written indented: these are meant to be read, not measured. A library that
  // emitted something unparseable is a finding in itself, so keep its output
  // as it came rather than losing it.
  LValue := TJSONObject.ParseJSONValue(LJSON);
  try
    if LValue <> nil then
      LJSON := TNeon.Print(LValue, True);
    TFile.WriteAllText(SampleFileName(AParam.JsonLib, AItem.ClassName), LJSON, TEncoding.UTF8);
  finally
    LValue.Free;
  end;
end;

procedure TfrmBenchmarks.SaveResult(var AParam: TBenchmarkParam; const AJSON: string);
var
  LFileName: string;
  LJSON: TJSONValue;
  LStream: TFileStream;
begin
  if not chkSaveResults.Checked then
    Exit;

  LFileName := TPath.Combine(FResultPath,
    Format('%s-' + AParam.FileName, [LIB_NAMES[AParam.JsonLib], AParam.Scale]));

  // parsed back only to be written out indented, well after the stopwatch
  LJSON := TJSONObject.ParseJSONValue(AJSON);
  try
    LStream := TFileStream.Create(LFileName, fmCreate or fmOpenWrite);
    try
      TNeon.PrintToStream((LJSON as TJSONObject).Pairs[0].JsonValue, LStream, True);
    finally
      LStream.Free;
    end;
  finally
    LJSON.Free;
  end;
end;

end.

