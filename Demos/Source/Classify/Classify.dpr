{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                }
{  Copyright (c) 2018 Paolo Rossi                                             }
{  https://github.com/paolo-rossi/neon-library                                }
{                                                                             }
{  Licensed under the MIT license                                             }
{                                                                             }
{******************************************************************************}
program Classify;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  Neon.Core.Generator,
  Classify.Options in 'Classify.Options.pas';

{$R *.res}

const
  /// <summary>
  ///   The document the examples are generated from: it holds one of everything
  ///   the generator has something to say about (naming conventions, dates,
  ///   nested objects, arrays of objects, arrays of values, nulls, repeated
  ///   structures)
  /// </summary>
  DEMO_JSON =
    '{' + sLineBreak +
    '  "id": 42,' + sLineBreak +
    '  "first_name": "Paolo",' + sLineBreak +
    '  "type": "customer",' + sLineBreak +
    '  "score": 4.5,' + sLineBreak +
    '  "active": true,' + sLineBreak +
    '  "created_at": "2026-08-12T10:00:00Z",' + sLineBreak +
    '  "nickname": null,' + sLineBreak +
    '  "tags": ["premium", "eu"],' + sLineBreak +
    '  "billing-address": { "street": "Via Emilia 1", "city": "Parma", "zip": "43100" },' + sLineBreak +
    '  "shipping-address": { "street": "Via Roma 2", "city": "Milano", "zip": "20100" },' + sLineBreak +
    '  "orders": [' + sLineBreak +
    '    { "code": "A1", "total": 10.5, "shipped": true },' + sLineBreak +
    '    { "code": "A2", "total": 20.0, "shipped": false, "note": "gift" }' + sLineBreak +
    '  ]' + sLineBreak +
    '}';

/// <summary>
///   Prints the warnings of a generation: everything the document was not able
///   to say, and that is worth a look at the generated code
/// </summary>
procedure PrintWarnings(AGenerator: TNeonEntityGenerator);
var
  LIndex: Integer;
begin
  if AGenerator.Warnings.Count = 0 then
    Exit;

  WriteLn;
  WriteLn('Warnings:');
  for LIndex := 0 to AGenerator.Warnings.Count - 1 do
    WriteLn('  - ', AGenerator.Warnings[LIndex]);
end;

procedure Generate(const AOptions: TEntitiesOptions);
var
  LGenerator: TNeonEntityGenerator;
  LSource: string;
begin
  LGenerator := TNeonEntityGenerator.Create(AOptions.Config);
  try
    LGenerator.Parse(TFile.ReadAllText(AOptions.InputFile, TEncoding.UTF8));
    LSource := LGenerator.GenerateUnit(AOptions.UnitName);

    if AOptions.OutputFile = '' then
      Write(LSource)
    else
    begin
      TFile.WriteAllText(AOptions.OutputFile, LSource, TEncoding.UTF8);
      WriteLn(Format('Unit [%s] written to [%s]', [AOptions.UnitName, AOptions.OutputFile]));
      WriteLn(Format('Root type: %s', [LGenerator.RootTypeName]));
    end;

    PrintWarnings(LGenerator);
  finally
    LGenerator.Free;
  end;
end;

/// <summary>
///   Generates one example and prints it under its title
/// </summary>
procedure RunExample(const ATitle, ANote: string; const AConfig: TNeonEntityConfig;
  const AJSON: string);
var
  LGenerator: TNeonEntityGenerator;
begin
  WriteLn;
  WriteLn('==============================================================');
  WriteLn(' ', ATitle);
  WriteLn('==============================================================');
  WriteLn(ANote);
  WriteLn;

  LGenerator := TNeonEntityGenerator.Create(AConfig);
  try
    LGenerator.Parse(AJSON);
    Write(LGenerator.GenerateTypes);
    WriteLn;
    WriteLn('Root type: ', LGenerator.RootTypeName);
    PrintWarnings(LGenerator);
  finally
    LGenerator.Free;
  end;
end;

procedure RunDemo;
var
  LGenerator: TNeonEntityGenerator;
begin
  WriteLn('Neon entity generator');
  WriteLn('Run with --help to generate entities from a document of your own');
  WriteLn;
  WriteLn('Document used by the examples:');
  WriteLn(DEMO_JSON);

  WriteLn;
  WriteLn('==============================================================');
  WriteLn(' 1. Classes, the whole unit');
  WriteLn('==============================================================');
  WriteLn('The default: private fields, properties, [NeonProperty] wherever the');
  WriteLn('Delphi name is not the JSON one, and the lifetime of the members the');
  WriteLn('entity owns. The two addresses have the same members, so they share');
  WriteLn('one type');
  WriteLn;

  LGenerator := TNeonEntityGenerator.Create;
  try
    LGenerator.Parse(DEMO_JSON);
    Write(LGenerator.GenerateUnit('Demo.Entities'));
    PrintWarnings(LGenerator);
  finally
    LGenerator.Free;
  end;

  RunExample('2. Records',
    'Records own nothing, so the arrays of entities become dynamic arrays and' + sLineBreak +
    'no lifetime is generated',
    TNeonEntityConfig.Records, DEMO_JSON);

  RunExample('3. Nullables',
    'A member that is null in the document, or missing from some of the items' + sLineBreak +
    'of an array, is generated as a Nullable<T>',
    TNeonEntityConfig.Default.SetUseNullables(True), DEMO_JSON);

  RunExample('4. Names left alone',
    'The JSON names are kept as they are (minus what is not legal in an' + sLineBreak +
    'identifier), so almost no attribute is needed',
    TNeonEntityConfig.Default.SetNameCase(TNeonNameCase.Unchanged), DEMO_JSON);

  RunExample('5. A document whose root is an array',
    'The items are what the document is about: they take the root name, and' + sLineBreak +
    'the root itself becomes an alias for their container',
    TNeonEntityConfig.Default.SetRootName('Order'),
    '[{"code":"A1","total":10.5},{"code":"A2","total":20.0,"note":"gift"}]');
end;

var
  LOptions: TEntitiesOptions;
begin
  try
    LOptions := TEntitiesOptions.Parse;

    if LOptions.ShowHelp then
      TEntitiesOptions.PrintUsage
    else if LOptions.InputFile = '' then
      RunDemo
    else
      Generate(LOptions);

    ReadLn;
  except
    on E: EOptionsError do
    begin
      WriteLn('Error: ', E.Message);
      WriteLn;
      TEntitiesOptions.PrintUsage;
      ExitCode := 1;
    end;
    on E: Exception do
    begin
      WriteLn(Format('Error: [%s] %s', [E.ClassName, E.Message]));
      ExitCode := 1;
    end;
  end;
end.
