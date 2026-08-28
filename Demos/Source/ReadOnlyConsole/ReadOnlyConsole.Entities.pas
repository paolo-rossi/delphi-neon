{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                             }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                             }
{  Licensed under the MIT license                                             }
{                                                                             }
{******************************************************************************}

/// <summary>
///   The entities the read-only demo works on. Every class here exists to make
///   one distinction visible in the JSON, so they are deliberately small and
///   every member carries the rule it exercises.
/// </summary>
unit ReadOnlyConsole.Entities;

{$I Neon.inc}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,

  Neon.Core.Types,
  Neon.Core.Attributes;

type
  /// <summary>
  ///   A sub-object reached only through a read-only property: the case the
  ///   class-type exemption in the engine exists for
  /// </summary>
  TAddress = class
  private
    FCity: string;
    FZip: string;
  public
    property City: string read FCity write FCity;
    property Zip: string read FZip write FZip;
  end;

  /// <summary>
  ///   A record behind a read-only property. Not tkClass and not tkInterface,
  ///   so it gets no exemption and follows IgnoreReadOnlyProps like a string
  /// </summary>
  TSize = record
    Width: Integer;
    Height: Integer;
  end;

  /// <summary>
  ///   One property per shape the read-only rules can tell apart. All the
  ///   engine asks of each is "can I read it" and "can I write it": the first
  ///   decides serialization, the second decides deserialization and - when
  ///   IgnoreReadOnlyProps is on - serialization as well.
  /// </summary>
  TShapes = class
  private
    FId: Integer;
    FName: string;
    FCode: string;
    FSize: TSize;
    FAddress: TAddress;
    FTags: TList<string>;
    FSecret: string;
    function GetDisplay: string;
    procedure SetSecret(const AValue: string);
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    ///   Fills the members no document and no caller could otherwise reach.
    ///   Methods are never serialized, so this is invisible to the engine
    /// </summary>
    procedure Seed;

    /// <summary>The baseline: read and written like any other property</summary>
    property Id: Integer read FId write FId;
    property Name: string read FName write FName;

    /// <summary>
    ///   Read-only and computed: there is no field to put a value back into,
    ///   so it can only ever travel outwards
    /// </summary>
    property Display: string read GetDisplay;

    /// <summary>
    ///   Read-only but backed straight by a field. Neon cannot tell this apart
    ///   from the computed one above - RTTI reports "not writable" for both
    /// </summary>
    property Code: string read FCode;

    /// <summary>
    ///   Read-only, record typed: dropped by IgnoreReadOnlyProps, because the
    ///   exemption below covers class and interface types only
    /// </summary>
    property Size: TSize read FSize;

    /// <summary>
    ///   Read-only, class typed: kept even when IgnoreReadOnlyProps is on. The
    ///   owner-creates-it, exposes-it-read-only idiom is how most sub-objects
    ///   are published, and dropping those would empty out most documents
    /// </summary>
    property Address: TAddress read FAddress;

    /// <summary>
    ///   The same exemption, for the other half of that idiom: a collection
    ///   the owner creates and never replaces
    /// </summary>
    property Tags: TList<string> read FTags;

    /// <summary>
    ///   The mirror image of a read-only property: writable but not readable,
    ///   so it is absent from every document Neon writes and filled by every
    ///   document Neon reads
    /// </summary>
    property Secret: string write SetSecret;

    /// <summary>Not serialized, only so the demo can print what landed</summary>
    [NeonIgnore]
    property SecretValue: string read FSecret;
  end;

  /// <summary>
  ///   The two attributes that overrule the read-only rules, on properties
  ///   that are read-only in exactly the same way as TShapes.Code
  /// </summary>
  TOverrides = class
  private
    FName: string;
    FAlways: string;
    FPlain: string;
    FVersion: string;
  public
    /// <summary>Same purpose as TShapes.Seed</summary>
    procedure Seed;

    /// <summary>
    ///   The redirection target of the [NeonSetter] below. Delphi emits no
    ///   RTTI for a private method, so it has to be public
    /// </summary>
    procedure SetVersionValue(const AValue: string);

    property Name: string read FName write FName;

    /// <summary>
    ///   [NeonInclude(Always)] is evaluated before everything else and answers
    ///   the question on its own: the read-only check is never reached
    /// </summary>
    [NeonInclude(IncludeIf.Always)]
    property Always: string read FAlways;

    /// <summary>The same property without the attribute, as the control</summary>
    property Plain: string read FPlain;

    /// <summary>
    ///   A [NeonSetter] makes a read-only property writable as far as Neon is
    ///   concerned, which both saves it from IgnoreReadOnlyProps and lets a
    ///   document fill it
    /// </summary>
    [NeonSetter('SetVersionValue')]
    property Version: string read FVersion;
  end;

  /// <summary>
  ///   Fields, for the half of the question the flag cannot answer: RTTI
  ///   reports every field as both readable and writable, whatever its
  ///   visibility, so "read-only field" is not a thing the engine can see
  /// </summary>
  TFields = class
  public
    Id: Integer;
    Name: string;
  end;

implementation

{ TShapes }

constructor TShapes.Create;
begin
  FAddress := TAddress.Create;
  FTags := TList<string>.Create;
end;

destructor TShapes.Destroy;
begin
  FTags.Free;
  FAddress.Free;
  inherited;
end;

function TShapes.GetDisplay: string;
begin
  Result := Format('#%d %s', [FId, FName]);
end;

procedure TShapes.Seed;
begin
  FId := 42;
  FName := 'Paolo';
  FCode := 'NEON-1';
  FSize.Width := 320;
  FSize.Height := 200;
  FAddress.City := 'Piacenza';
  FAddress.Zip := '29122';
  FTags.Clear;
  FTags.AddRange(['delphi', 'json']);
  FSecret := '';
end;

procedure TShapes.SetSecret(const AValue: string);
begin
  FSecret := AValue;
end;

{ TOverrides }

procedure TOverrides.Seed;
begin
  FName := 'Paolo';
  FAlways := 'kept by the attribute';
  FPlain := 'dropped by the flag';
  FVersion := '1.0';
end;

procedure TOverrides.SetVersionValue(const AValue: string);
begin
  FVersion := AValue;
end;

end.
