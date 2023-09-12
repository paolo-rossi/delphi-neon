{******************************************************************************}
{                                                                              }
{  Neon: Serialization Library for Delphi                                      }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{******************************************************************************}
{                                                                              }
{  Licensed under the Apache License, Version 2.0 (the "License");             }
{  you may not use this file except in compliance with the License.            }
{  You may obtain a copy of the License at                                     }
{                                                                              }
{      http://www.apache.org/licenses/LICENSE-2.0                              }
{                                                                              }
{  Unless required by applicable law or agreed to in writing, software         }
{  distributed under the License is distributed on an "AS IS" BASIS,           }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    }
{  See the License for the specific language governing permissions and         }
{  limitations under the License.                                              }
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
  System.Generics.Collections, System.Diagnostics,
  System.Json, REST.Json,

  Benchmarks.Entities;

type
  TOperationType = (Serialization, Deserialization);
  TJsonLibrary = (Neon, Json);
  TBenchmarkParam = record
  public
    Scale: Integer;
    FileName: string;
    Series: TBarSeries;
    Value: Integer;
    Operation: TOperationType;
    JsonLib: string;
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
    procedure FormCreate(Sender: TObject);
    procedure btnExecuteClick(Sender: TObject);
    procedure btnHelpClick(Sender: TObject);
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
  private
    procedure SaveResult(var AParam: TBenchmarkParam; AJSON: TJSONObject);
    procedure ClearCharts;
    procedure BenchmarkSimpleClass;
    procedure BenchmarkComplexClass;

    procedure BenchmarkFile(AObject: TEnvelope; AJSON: TJSONObject; AScale: Integer);
    function LoadData(const AFile: string; AScale: Integer): TJSONObject;
  public
    { Public declarations }
  end;

var
  frmBenchmarks: TfrmBenchmarks;

implementation

uses
  System.IOUtils,
  Neon.Core.Persistence,
  Neon.Core.Persistence.JSON,
  Benchmarks.Form.Source;

{$R *.dfm}

procedure TfrmBenchmarks.FormCreate(Sender: TObject);
begin
  FDataPath := TPath.Combine(TPath.GetDirectoryName(
    TPath.GetDirectoryName(Application.ExeName)), DATA_PATH);
  FResultPath := TPath.Combine(TPath.GetDirectoryName(
    TPath.GetDirectoryName(Application.ExeName)), RESULTS_PATH);
  ForceDirectories(FResultPath);
  ClearCharts;
end;

procedure TfrmBenchmarks.BenchmarkSimpleClass;
var
  LIndex, LScale: Integer;
  LJSONFile: TJSONObject;
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
      LCount := (LJSONFile.GetValue('Items') as TJSONArray).Count;
      lblDescription.Caption := Format('Benchmarking %s class (%.0n items)', ['TUser', LCount/1.0]);
      memoLog.Lines.Add(lblDescription.Caption);
      memoLog.Lines.Add('');
      Application.ProcessMessages;
      try
        BenchmarkFile(LObj, LJSONFile, LScale);
      finally
        LJSONFile.Free;
      end;
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
  LJSONFile: TJSONObject;
  LObj: TCustomersEnvelope;
begin
  ClearCharts;
  for LIndex := Low(CUST_SCALE) to High(CUST_SCALE) do
  begin
    LScale := CUST_SCALE[LIndex];
    LObj := TCustomersEnvelope.Create;
    try
      LJSONFile := LoadData(CUST_FILENAME, LScale);
      LCount := (LJSONFile.GetValue('Items') as TJSONArray).Count;
      lblDescription.Caption := Format('Benchmarking %s class (%.0n items)', ['TCustomer', LCount/1.0]);
      memoLog.Lines.Add(lblDescription.Caption);
      memoLog.Lines.Add('');
      Application.ProcessMessages;
      try
        BenchmarkFile(LObj, LJSONFile, LScale);
      finally
        LJSONFile.Free;
      end;
    finally
      LObj.Free;
    end;
  end;
  lblDescription.Caption := 'Finish Benchmarking TCustomer class';
  memoLog.Lines.Add(lblDescription.Caption);
  memoLog.Lines.Add('----------------------------');
end;

procedure TfrmBenchmarks.BenchmarkFile(AObject: TEnvelope; AJSON: TJSONObject; AScale: Integer);
var
  LParam: TBenchmarkParam;

  procedure BenchmarkSingle(var AParam: TBenchmarkParam);
  var
    LOp: string;
    LJSON: TJSONObject;
    LWatch: TStopWatch;
  begin
    LWatch := TStopwatch.StartNew;
    case AParam.Operation of
      Deserialization:
      begin
        LOp := 'Deserialization';
        if AParam.JsonLib = 'Neon' then
          TNeon.JSONToObject(AObject, AJSON, TNeonConfiguration.Default)
        else
          TJson.JsonToObject(AObject, AJSON);

        LWatch.Stop;
      end;
      Serialization:
      begin
        LOp := 'Serialization';
        if AParam.JsonLib = 'Neon' then
          LJSON := TNeon.ObjectToJSON(AObject) as TJSONObject
        else
          LJSON := TJson.ObjectToJsonObject(AObject);

        LWatch.Stop;
        try
          SaveResult(AParam, LJSON);
        finally
          LJSON.Free;
        end;
      end;
    end;
    AParam.Value := LWatch.ElapsedMilliseconds;

    memoLog.Lines.Add(Format('%s (%s): %dmsec', [LOp, AParam.JsonLib, AParam.Value]));
    AParam.Series.Add(AParam.Value, Format('%dK', [AScale]));
  end;

begin
  LParam.Scale := AScale;
  if AObject is TUsersEnvelope then
    LParam.FileName := USER_FILENAME
  else
    LParam.FileName := CUST_FILENAME;

  LParam.XLabel := AScale.ToString + 'K';

  LParam.JsonLib := 'Neon';

  LParam.Series := serNeonDes;
  LParam.Operation := Deserialization;
  BenchmarkSingle(LParam);

  LParam.Operation := Serialization;
  LParam.Series := serNeonSer;
  BenchmarkSingle(LParam);

  AObject.Clear;
  LParam.JsonLib := 'Json';

  LParam.Series := serJsonDes;
  LParam.Operation := Deserialization;
  BenchmarkSingle(LParam);

  LParam.Series := serJsonSer;
  LParam.Operation := Serialization;
  BenchmarkSingle(LParam);

  memoLog.Lines.Add('----------------------------');
end;

procedure TfrmBenchmarks.btnExecuteClick(Sender: TObject);
begin
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

procedure TfrmBenchmarks.ClearCharts;
begin
  serNeonSer.Clear;
  serJsonSer.Clear;
  serNeonDes.Clear;
  serJsonDes.Clear;
end;

function TfrmBenchmarks.LoadData(const AFile: string; AScale: Integer): TJSONObject;
var
  LFile: string;
  LFileName: string;
  LJSON: TJSONValue;
begin
  LFileName := TPath.Combine(FDataPath, Format(AFile, [AScale]));
  LFile := TFile.ReadAllText(LFileName);
  LJSON := TJSONObject.ParseJSONValue(LFile);
  Result := TJSONObject.Create.AddPair('Items', LJSON);
end;

procedure TfrmBenchmarks.SaveResult(var AParam: TBenchmarkParam; AJSON: TJSONObject);
var
  LFileName: string;
  LStream: TFileStream;
begin
  if not chkSaveResults.Checked then
    Exit;

  LFileName := TPath.Combine(FResultPath, Format('%s-' + AParam.FileName, [AParam.JsonLib, AParam.Scale]));
  LStream := TFileStream.Create(LFileName, fmCreate or fmOpenWrite);
  try
    TNeon.PrintToStream(AJSON.Pairs[0].JsonValue, LStream, True);
  finally
    LStream.Free;
  end;
end;

end.

