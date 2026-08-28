{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                }
{  Copyright (c) 2018 Paolo Rossi                                             }
{  https://github.com/paolo-rossi/neon-library                                }
{                                                                             }
{  Licensed under the MIT license                                             }
{                                                                             }
{******************************************************************************}

/// <summary>
///   What Neon does with members it cannot write back, and what
///   SetIgnoreReadOnlyProps changes about it.
/// </summary>
/// <remarks>
///   <para>
///     The engine never asks whether a member is "read-only". It asks two
///     separate questions, in TNeonRttiMembers.Prepare:
///   </para>
///   <para>
///     serializing - can I read this member? (IsReadable)
///   </para>
///   <para>
///     deserializing - can I write this member? (IsWritable)
///   </para>
///   <para>
///     So a read-only property is written out but never read back, whatever
///     the configuration says. IgnoreReadOnlyProps adds one rule on top of
///     that, on the serialization side only: drop a member that cannot be
///     written back, unless its type is a class or an interface. That
///     exemption is what keeps the create-it-in-the-constructor,
///     publish-it-read-only idiom - sub-objects and collections - in the
///     document.
///   </para>
/// </remarks>
unit ReadOnlyConsole.Runner;

{$I Neon.inc}

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Rtti,
  System.Generics.Collections,

  Neon.Core.Types,
  Neon.Core.Attributes,
  Neon.Core.Persistence,
  Neon.Core.Persistence.JSON,

  ReadOnlyConsole.Entities;

type
  TReadOnlyDemo = class
  private
    /// <summary>
    ///   The document the deserialization steps read: it names every member of
    ///   TShapes, the ones Neon can never write back included, so what lands on
    ///   the object is down to the rules and not to what the document omits
    /// </summary>
    const SHAPES_JSON =
      '{' +
      '"Id":7,' +
      '"Name":"Marco",' +
      '"Display":"#7 Marco - from the document",' +
      '"Code":"FROM-JSON",' +
      '"Size":{"Width":1,"Height":2},' +
      '"Address":{"City":"Milano","Zip":"20121"},' +
      '"Tags":["from","json"],' +
      '"Secret":"filled through the setter"' +
      '}';
  private
    function Config(AIgnoreReadOnly: Boolean): INeonConfiguration;

    procedure Header(const ATitle: string);
    procedure Note(const AText: string);
    procedure PrintJSON(const ACaption, AJSON: string);

    function Serialize(AObject: TObject; AConfig: INeonConfiguration): string;
    procedure Deserialize(const AJSON: string; AObject: TObject; AConfig: INeonConfiguration);

    function Describe(AShapes: TShapes): string;

    procedure StepSerialize;
    procedure StepDeserialize;
    procedure StepRoundTrip;
    procedure StepAttributes;
    procedure StepFields;
    procedure StepIgnoreMembers;
  public
    procedure Run;
  end;

implementation

{ TReadOnlyDemo }

function TReadOnlyDemo.Config(AIgnoreReadOnly: Boolean): INeonConfiguration;
begin
  Result := TNeonConfiguration.Default
    .SetPrettyPrint(True)
    .SetIgnoreReadOnlyProps(AIgnoreReadOnly);
end;

procedure TReadOnlyDemo.Header(const ATitle: string);
begin
  WriteLn;
  WriteLn(StringOfChar('=', 78));
  WriteLn('  ' + ATitle);
  WriteLn(StringOfChar('=', 78));
  WriteLn;
end;

procedure TReadOnlyDemo.Note(const AText: string);
begin
  if AText.IsEmpty then
    WriteLn
  else
    WriteLn('  . ' + AText);
end;

procedure TReadOnlyDemo.PrintJSON(const ACaption, AJSON: string);
var
  LLine: string;
begin
  WriteLn('  ' + ACaption);
  for LLine in AJSON.Split([sLineBreak]) do
    WriteLn('    ' + LLine);
  WriteLn;
end;

function TReadOnlyDemo.Serialize(AObject: TObject; AConfig: INeonConfiguration): string;
var
  LJSON: TJSONValue;
begin
  LJSON := TNeon.ObjectToJSON(AObject, AConfig);
  try
    Result := TNeon.Print(LJSON, AConfig.GetPrettyPrint);
  finally
    LJSON.Free;
  end;
end;

procedure TReadOnlyDemo.Deserialize(const AJSON: string; AObject: TObject;
  AConfig: INeonConfiguration);
begin
  TNeon.JSONToObject(AObject, AJSON, AConfig);
end;

function TReadOnlyDemo.Describe(AShapes: TShapes): string;
begin
  Result :=
    Format('Id=%d  Name=%s  Display=%s  Code=%s  Size=%dx%d', [
      AShapes.Id, AShapes.Name, AShapes.Display, AShapes.Code,
      AShapes.Size.Width, AShapes.Size.Height]) + sLineBreak +
    Format('    Address=%s/%s  Tags=[%s]  Secret=%s', [
      AShapes.Address.City, AShapes.Address.Zip,
      string.Join(',', AShapes.Tags.ToArray), AShapes.SecretValue]);
end;

procedure TReadOnlyDemo.StepSerialize;
var
  LShapes: TShapes;
begin
  Header('1. Serialization: the only place IgnoreReadOnlyProps has a say');

  LShapes := TShapes.Create;
  try
    LShapes.Seed;

    PrintJSON('SetIgnoreReadOnlyProps(False) - the default',
      Serialize(LShapes, Config(False)));

    Note('Every readable member is there, whether or not it can be written back.');
    Note('"Secret" is missing from both: it is write-only, so there is nothing');
    Note('  to read.');
    WriteLn;

    PrintJSON('SetIgnoreReadOnlyProps(True)',
      Serialize(LShapes, Config(True)));

    Note('Gone: "Display" and "Code" (read-only, simple type) and "Size"');
    Note('  (read-only, record type - the exemption is class/interface only).');
    Note('Kept: "Address" and "Tags", read-only but class typed.');
  finally
    LShapes.Free;
  end;
end;

procedure TReadOnlyDemo.StepDeserialize;
var
  LShapes: TShapes;
  LIgnore: Boolean;
begin
  Header('2. Deserialization: the flag is not consulted at all');

  PrintJSON('the document, which names every member of TShapes', SHAPES_JSON);

  for LIgnore in [False, True] do
  begin
    LShapes := TShapes.Create;
    try
      LShapes.Seed;
      Deserialize(SHAPES_JSON, LShapes, Config(LIgnore));

      WriteLn(Format('  after JSONToObject, SetIgnoreReadOnlyProps(%s)',
        [BoolToStr(LIgnore, True)]));
      WriteLn('    ' + Describe(LShapes));
      WriteLn;
    finally
      LShapes.Free;
    end;
  end;

  Note('The two blocks are identical: deserialization filters on IsWritable and');
  Note('  never looks at the flag.');
  Note('Id and Name took the values from the document. Code and Size kept the');
  Note('  ones Seed put there, because a read-only property has no setter to');
  Note('  call, and Display recomputed itself from the new Id and Name.');
  Note('Address and Tags kept theirs too: the class-type exemption is a');
  Note('  serialization rule, so a read-only sub-object goes out but does not');
  Note('  come back. That is the asymmetry worth remembering here.');
  Note('Secret is the reverse case: write-only, so only a document can fill it.');
end;

procedure TReadOnlyDemo.StepRoundTrip;
var
  LSource, LTarget: TShapes;
  LDocument: string;
begin
  Header('3. What survives a round trip');

  LSource := TShapes.Create;
  try
    LSource.Seed;
    LDocument := Serialize(LSource, Config(False));
  finally
    LSource.Free;
  end;

  LTarget := TShapes.Create;
  try
    // A blank target, so anything present afterwards came from the document
    Deserialize(LDocument, LTarget, Config(False));

    WriteLn('  a seeded object serialized, then read into a blank one');
    WriteLn('    ' + Describe(LTarget));
    WriteLn;

    Note('Only Id and Name made it across: every other member of TShapes is');
    Note('  read-only, Display included, which is why it shows the new Id and');
    Note('  Name rather than the string that was in the document.');
    Note('So the JSON that IgnoreReadOnlyProps(False) produces is a report, not a');
    Note('  document an object can be restored from. Turning the flag on makes');
    Note('  the document honest about the simple members: what is left is what a');
    Note('  reader could put back, minus the class-typed exemptions.');
  finally
    LTarget.Free;
  end;
end;

procedure TReadOnlyDemo.StepAttributes;
var
  LOverrides: TOverrides;
begin
  Header('4. The attributes that overrule the rule');

  LOverrides := TOverrides.Create;
  try
    LOverrides.Seed;

    PrintJSON('SetIgnoreReadOnlyProps(False)',
      Serialize(LOverrides, Config(False)));
    PrintJSON('SetIgnoreReadOnlyProps(True)',
      Serialize(LOverrides, Config(True)));

    Note('"Plain" is the control and disappears.');
    Note('"Always" survives: [NeonInclude(Always)] is checked first and short-');
    Note('  circuits every other test, the read-only one included.');
    Note('"Version" survives for a different reason: [NeonSetter] gives Neon a');
    Note('  way to write the property, so IsWritable answers True and the rule');
    Note('  does not apply to it.');

    LOverrides.Seed;
    Deserialize('{"Always":"from json","Plain":"from json","Version":"2.0"}',
      LOverrides, Config(True));

    WriteLn;
    WriteLn('  after reading {"Always":.., "Plain":.., "Version":"2.0"}');
    WriteLn(Format('    Always=%s  Plain=%s  Version=%s',
      [LOverrides.Always, LOverrides.Plain, LOverrides.Version]));
    WriteLn;

    Note('Only Version changed. [NeonInclude(Always)] marks a member serializable');
    Note('  for both operations, but it does not conjure a setter, so writing');
    Note('  "Always" still goes nowhere. [NeonSetter] is the attribute that');
    Note('  actually makes a read-only property writable.');
  finally
    LOverrides.Free;
  end;
end;

procedure TReadOnlyDemo.StepFields;
var
  LFields: TFields;
begin
  Header('5. Fields: nothing for the flag to act on');

  LFields := TFields.Create;
  try
    LFields.Id := 42;
    LFields.Name := 'Paolo';

    PrintJSON('SetMembers([Fields]) + SetIgnoreReadOnlyProps(True)',
      Serialize(LFields, Config(True).SetMembers([TNeonMembers.Fields])));

    Note('Unchanged from the flag being off. TRttiField reports every field as');
    Note('  both readable and writable - visibility and the absence of a setter');
    Note('  are invisible to it - so no field can ever look read-only to the');
    Note('  engine. The name of the option says as much: ReadOnly*Props*.');
  finally
    LFields.Free;
  end;
end;

procedure TReadOnlyDemo.StepIgnoreMembers;
var
  LShapes: TShapes;
begin
  Header('6. Ignoring a read-only member by name');

  LShapes := TShapes.Create;
  try
    LShapes.Seed;

    PrintJSON('SetIgnoreReadOnlyProps(True) + SetIgnoreMembers([Address, Tags])',
      Serialize(LShapes, Config(True).SetIgnoreMembers(['Address', 'Tags'])));

    Note('The ignore list is the way to drop the class-typed members the');
    Note('  exemption keeps. Order matters inside the engine too: the read-only');
    Note('  check probes the member type, which is not guaranteed to have RTTI,');
    Note('  so an ignored member has to be gone before anything looks at it.');
  finally
    LShapes.Free;
  end;
end;

procedure TReadOnlyDemo.Run;
begin
  WriteLn('Neon - read-only fields and properties');
  WriteLn('SetIgnoreReadOnlyProps, and the rules it does and does not change');

  StepSerialize;
  StepDeserialize;
  StepRoundTrip;
  StepAttributes;
  StepFields;
  StepIgnoreMembers;
end;

end.
