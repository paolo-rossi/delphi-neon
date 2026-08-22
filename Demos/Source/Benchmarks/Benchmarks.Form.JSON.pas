{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Benchmarks.Form.JSON;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,

  Benchmarks.Form.Main;

type
  /// <summary>
  ///   Puts the JSON that two of the libraries wrote for a *single* entity
  ///   side by side, so that the shape of the two documents can be compared by
  ///   eye. The full benchmark documents hold thousands of records and are of
  ///   no use for that; these samples hold one.
  /// </summary>
  /// <remarks>
  ///   Nothing is serialized here. The panes show the files that
  ///   TfrmBenchmarks.SaveSample writes into Data\Results while a benchmark
  ///   runs, one per library and per class, so a run has to have happened
  ///   before there is anything to look at.
  /// </remarks>
  TfrmJSON = class(TForm)
    memoA: TMemo;
    memoB: TMemo;
    cbbEngineA: TComboBox;
    cbbEngineB: TComboBox;
    grpClassType: TGroupBox;
    rbClassSimple: TRadioButton;
    rbClassComplex: TRadioButton;
    lblEngineA: TLabel;
    lblEngineB: TLabel;
    lblStatus: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure SelectionChanged(Sender: TObject);
  private
    function SelectedEntity: string;
    function SelectedCaption: string;
    function LoadInto(AMemo: TMemo; ACombo: TComboBox): string;
  public
    /// <summary>
    ///   Re-reads both panes from disk. Called every time the window is
    ///   opened, since a benchmark run replaces the samples.
    /// </summary>
    procedure LoadSamples;
  end;

var
  frmJSON: TfrmJSON;

implementation

uses
  System.IOUtils;

{$R *.dfm}

procedure TfrmJSON.FormCreate(Sender: TObject);
begin
  // the combo entries stand for the values of TJsonLibrary, in order: a name
  // added to one and not the other would silently show the wrong file
  Assert(cbbEngineA.Items.Count = Ord(High(TJsonLibrary)) + 1,
    'The engine combo boxes and TJsonLibrary have drifted apart');
end;

procedure TfrmJSON.SelectionChanged(Sender: TObject);
begin
  LoadSamples;
end;

function TfrmJSON.SelectedEntity: string;
begin
  if rbClassSimple.Checked then
    Result := SAMPLE_SIMPLE
  else
    Result := SAMPLE_COMPLEX;
end;

function TfrmJSON.SelectedCaption: string;
begin
  if rbClassSimple.Checked then
    Result := rbClassSimple.Caption
  else
    Result := rbClassComplex.Caption;
end;

/// <summary>
///   Fills one pane and reports what ended up in it. The engine boxes on the
///   main form mean a run can leave one library's sample untouched, so the
///   caller gets the write time back to put on screen: two samples from
///   different runs would otherwise be indistinguishable.
/// </summary>
function TfrmJSON.LoadInto(AMemo: TMemo; ACombo: TComboBox): string;
var
  LFileName: string;
begin
  if ACombo.ItemIndex < 0 then
    ACombo.ItemIndex := 0;

  LFileName := frmBenchmarks.SampleFileName(TJsonLibrary(ACombo.ItemIndex), SelectedEntity);

  AMemo.Clear;
  if TFile.Exists(LFileName) then
  begin
    AMemo.Lines.LoadFromFile(LFileName, TEncoding.UTF8);
    Result := Format('%s written %s', [TPath.GetFileName(LFileName),
      FormatDateTime('hh:nn:ss', TFile.GetLastWriteTime(LFileName))]);
  end
  else
  begin
    AMemo.Lines.Add(Format('No %s sample from %s yet.', [SelectedEntity, ACombo.Text]));
    AMemo.Lines.Add('');
    AMemo.Lines.Add(Format('Tick %s and run the "%s" benchmark.',
      [ACombo.Text, SelectedCaption]));
    Result := TPath.GetFileName(LFileName) + ' not written yet';
  end;
end;

procedure TfrmJSON.LoadSamples;
var
  LLeft, LRight: string;
begin
  LLeft := LoadInto(memoA, cbbEngineA);
  LRight := LoadInto(memoB, cbbEngineB);
  lblStatus.Caption := Format('%s   |   %s   -   in %s',
    [LLeft, LRight, frmBenchmarks.ResultPath]);
end;

end.
