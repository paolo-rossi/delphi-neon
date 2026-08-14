{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                }
{  Copyright (c) 2018 Paolo Rossi                                             }
{  https://github.com/paolo-rossi/neon-library                                }
{                                                                             }
{  Licensed under the MIT license                                             }
{                                                                             }
{******************************************************************************}
unit Classify.Options;

interface

uses
  System.SysUtils, System.StrUtils, System.IOUtils,

  Neon.Core.Generator;

type
  EOptionsError = class(Exception);

  /// <summary>
  ///   What the command line asked for: the files to read and write, and the
  ///   configuration of the generator built from the switches
  /// </summary>
  TEntitiesOptions = record
  public
    InputFile: string;
    OutputFile: string;
    UnitName: string;
    ShowHelp: Boolean;
    Config: TNeonEntityConfig;

    /// <summary>
    ///   Reads the command line. Raises EOptionsError on an unknown switch or
    ///   on a switch missing its value, so that the program can tell the user
    ///   what is wrong instead of generating something unexpected
    /// </summary>
    class function Parse: TEntitiesOptions; static;

    class procedure PrintUsage; static;
  end;

implementation

{ TEntitiesOptions }

class function TEntitiesOptions.Parse: TEntitiesOptions;
var
  LIndex: Integer;
  LParam: string;

  function NextValue(const ASwitch: string): string;
  begin
    Inc(LIndex);
    if LIndex > ParamCount then
      raise EOptionsError.CreateFmt('Switch [%s] needs a value', [ASwitch]);
    Result := ParamStr(LIndex);
  end;

begin
  Result.InputFile := '';
  Result.OutputFile := '';
  Result.UnitName := '';
  Result.ShowHelp := False;
  Result.Config := TNeonEntityConfig.Default;

  LIndex := 1;
  while LIndex <= ParamCount do
  begin
    LParam := ParamStr(LIndex);

    if (LParam = '-h') or (LParam = '--help') or (LParam = '-?') then
      Result.ShowHelp := True

    else if (LParam = '-o') or (LParam = '--output') then
      Result.OutputFile := NextValue(LParam)

    else if (LParam = '-u') or (LParam = '--unit') then
      Result.UnitName := NextValue(LParam)

    else if (LParam = '-p') or (LParam = '--prefix') then
      Result.Config.TypePrefix := NextValue(LParam)

    else if (LParam = '-r') or (LParam = '--root') then
      Result.Config.RootName := NextValue(LParam)

    else if (LParam = '-i') or (LParam = '--indent') then
      Result.Config.IndentSize := StrToInt(NextValue(LParam))

    else if (LParam = '-k') or (LParam = '--kind') then
    begin
      LParam := LowerCase(NextValue(LParam));
      if LParam = 'class' then
        Result.Config.EntityKind := TNeonEntityKind.Classes
      else if LParam = 'record' then
      begin
        Result.Config.EntityKind := TNeonEntityKind.Records;
        // Nobody would free the lists of a record
        Result.Config.ArrayKind := TNeonArrayKind.DynamicArray;
      end
      else
        raise EOptionsError.CreateFmt('Unknown entity kind [%s]: class or record', [LParam]);
    end

    else if (LParam = '-a') or (LParam = '--array') then
    begin
      LParam := LowerCase(NextValue(LParam));
      if LParam = 'objectlist' then
        Result.Config.ArrayKind := TNeonArrayKind.ObjectList
      else if LParam = 'list' then
        Result.Config.ArrayKind := TNeonArrayKind.GenericList
      else if LParam = 'array' then
        Result.Config.ArrayKind := TNeonArrayKind.DynamicArray
      else
        raise EOptionsError.CreateFmt('Unknown array kind [%s]: objectlist, list or array', [LParam]);
    end

    else if LParam = '--unchanged-names' then
      Result.Config.NameCase := TNeonNameCase.Unchanged

    else if (LParam = '-n') or (LParam = '--nullables') then
      Result.Config.UseNullables := True

    else if LParam = '--unknown-type' then
      Result.Config.UnknownType := NextValue(LParam)

    else if LParam = '--no-attributes' then
      Result.Config.UseNeonProperty := False

    else if LParam = '--no-datetime' then
      Result.Config.DetectDateTime := False

    else if LParam = '--no-merge' then
      Result.Config.MergeEqualTypes := False

    else if LParam = '--no-lifetime' then
      Result.Config.GenerateLifetime := False

    else if LParam = '--no-header' then
      Result.Config.WriteHeader := False

    else if StartsStr('-', LParam) then
      raise EOptionsError.CreateFmt('Unknown switch [%s]', [LParam])

    else if Result.InputFile = '' then
      Result.InputFile := LParam

    else
      raise EOptionsError.CreateFmt('Unexpected argument [%s]', [LParam]);

    Inc(LIndex);
  end;

  if (Result.InputFile <> '') and not TFile.Exists(Result.InputFile) then
    raise EOptionsError.CreateFmt('File not found [%s]', [Result.InputFile]);

  // The name of the unit is the one thing the output file already knows
  if Result.UnitName = '' then
    if Result.OutputFile <> '' then
      Result.UnitName := TPath.GetFileNameWithoutExtension(Result.OutputFile)
    else
      Result.UnitName := 'Demo.Entities';
end;

class procedure TEntitiesOptions.PrintUsage;
begin
  WriteLn('Generates Delphi entities from a JSON document');
  WriteLn;
  WriteLn('  Classify [options] <document.json>');
  WriteLn;
  WriteLn('Without a document, a set of examples is generated and printed instead.');
  WriteLn;
  WriteLn('Options');
  WriteLn('  -o, --output <file>     write the unit to <file> (default: standard output)');
  WriteLn('  -u, --unit <name>       name of the generated unit (default: from --output)');
  WriteLn('  -k, --kind <kind>       "class" (default) or "record"');
  WriteLn('  -a, --array <kind>      container of a JSON array of objects:');
  WriteLn('                          "objectlist" (default), "list" or "array"');
  WriteLn('  -p, --prefix <prefix>   prefix of the generated type names (default: T)');
  WriteLn('  -r, --root <name>       name of the type generated for the root (default: Root)');
  WriteLn('  -i, --indent <n>        spaces of one indentation level (default: 2)');
  WriteLn('  -n, --nullables         Nullable<T> for the members that can be null');
  WriteLn('      --unknown-type <t>  type of the members the document says nothing about');
  WriteLn('                          (default: string)');
  WriteLn('      --unchanged-names   keep the JSON member names as they are');
  WriteLn('      --no-attributes     do not emit the [NeonProperty] attributes');
  WriteLn('      --no-datetime       do not map the ISO8601 strings to TDateTime');
  WriteLn('      --no-merge          one type per JSON object, even when identical');
  WriteLn('      --no-lifetime       no constructor/destructor for the owned members');
  WriteLn('      --no-header         no banner at the top of the unit');
  WriteLn('  -h, --help              this help');
end;

end.
