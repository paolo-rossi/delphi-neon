{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                }
{  Copyright (c) 2018 Paolo Rossi                                             }
{  https://github.com/paolo-rossi/neon-library                                }
{                                                                             }
{  Licensed under the MIT license                                             }
{                                                                             }
{******************************************************************************}
unit SchemaConsole.Runner;

{$I Neon.inc}

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.DateUtils,
  System.IOUtils, System.Generics.Collections,

  Neon.Core.Types,
  Neon.Core.Persistence,
  Neon.Core.Persistence.JSON,
  Neon.Core.Persistence.JSON.Schema,

  SchemaConsole.Entities;

type
  /// <summary>
  ///   The two halves of the story, run one after the other: a Delphi type is
  ///   turned into a Draft 2020-12 schema document, and JSON documents are then
  ///   checked against that very document
  /// </summary>
  TSchemaDemo = class
  private
    /// <summary>
    ///   The same configuration drives the schema generator and the serializer,
    ///   so that the names in the schema are the names the serializer writes.
    ///   Two different configurations here would produce a schema no serialized
    ///   object could ever satisfy
    /// </summary>
    FConfig: INeonConfiguration;

    /// <summary>
    ///   The schema for TOrder, generated once and reused by every step
    /// </summary>
    FOrderSchema: TJSONObject;

    /// <summary>
    ///   Where SaveEntities writes: the Demos\Data folder next to the Bin the
    ///   executable runs from, so the files land with the rest of the demo
    ///   documents rather than inside the build output
    /// </summary>
    FDataFolder: string;

    /// <summary>
    ///   TNeon.ParseJSON is private to the engine and the parser of the RTL
    ///   returns nil rather than raising on a malformed document, so the demo
    ///   brings its own wrapper to fail loudly on a broken constant
    /// </summary>
    function ParseJSON(const AJSON: string): TJSONValue;

    procedure Header(const ATitle: string);
    procedure PrintJSON(const ACaption: string; AJSON: TJSONValue);
    procedure PrintResult(const AResult: TJSONValidationResult);

    /// <summary>
    ///   Writes a document as UTF-8 with no BOM: a byte order mark is legal in
    ///   a file but not in JSON itself, and several validators reject it
    /// </summary>
    procedure SaveJSON(AJSON: TJSONValue; const AFileName: string);

    function BuildOrder: TOrder;
    function BuildCatalog: TCategory;

    procedure StepGenerateSchema;
    procedure StepSerializeAndValidate;
    procedure StepInvalidDocument;
    procedure StepStopOnFirstError;
    procedure StepRecursiveType;
    procedure StepHandWrittenSchema;
    procedure SaveEntities;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Run;
  end;

implementation

const
  /// <summary>
  ///   A document that breaks a constraint of nearly every kind the generator
  ///   can emit, so that one validation run shows them all at once
  /// </summary>
  INVALID_ORDER =
    '{'                                                        + sLineBreak +
    '  "orderId": "12345",'                                    + sLineBreak +
    '  "status": "Refunded",'                                  + sLineBreak +
    '  "customer": {'                                          + sLineBreak +
    '    "id": 0,'                                             + sLineBreak +
    '    "fullName": "A",'                                     + sLineBreak +
    '    "email": "paolo.example.com",'                        + sLineBreak +
    '    "billingAddress": {'                                  + sLineBreak +
    '      "street": "Via Emilia 1",'                          + sLineBreak +
    '      "city": "Parma",'                                   + sLineBreak +
    '      "zipCode": "431",'                                  + sLineBreak +
    '      "country": "italy"'                                 + sLineBreak +
    '    }'                                                    + sLineBreak +
    '  },'                                                     + sLineBreak +
    '  "items": ['                                             + sLineBreak +
    '    { "sku": "1234", "description": "", "quantity": 0, "unitPrice": 0.0 }' + sLineBreak +
    '  ],'                                                     + sLineBreak +
    '  "total": -10.5'                                         + sLineBreak +
    '}';

  /// <summary>
  ///   A schema written by hand rather than generated, using the keywords a
  ///   Delphi type has no way to express: a reference to a named definition,
  ///   a positional array and a rule that depends on another member's value
  /// </summary>
  PAYMENT_SCHEMA =
    '{'                                                                     + sLineBreak +
    '  "$schema": "https://json-schema.org/draft/2020-12/schema",'          + sLineBreak +
    '  "$defs": {'                                                          + sLineBreak +
    '    "money": {'                                                        + sLineBreak +
    '      "$anchor": "money",'                                             + sLineBreak +
    '      "type": "object",'                                               + sLineBreak +
    '      "properties": {'                                                 + sLineBreak +
    '        "amount": { "type": "number", "exclusiveMinimum": 0 },'        + sLineBreak +
    '        "currency": { "enum": ["EUR", "USD", "GBP"] }'                 + sLineBreak +
    '      },'                                                              + sLineBreak +
    '      "required": ["amount", "currency"]'                              + sLineBreak +
    '    }'                                                                 + sLineBreak +
    '  },'                                                                  + sLineBreak +
    '  "type": "object",'                                                   + sLineBreak +
    '  "properties": {'                                                     + sLineBreak +
    '    "method": { "enum": ["card", "transfer"] },'                       + sLineBreak +
    '    "amount": { "$ref": "#money" },'                                   + sLineBreak +
    '    "card": {'                                                         + sLineBreak +
    '      "type": "object",'                                               + sLineBreak +
    '      "properties": {'                                                 + sLineBreak +
    '        "number": { "type": "string", "pattern": "^[0-9]{16}$" },'     + sLineBreak +
    '        "expiry": {'                                                   + sLineBreak +
    '          "type": "array",'                                            + sLineBreak +
    '          "prefixItems": ['                                            + sLineBreak +
    '            { "type": "integer", "minimum": 1, "maximum": 12 },'       + sLineBreak +
    '            { "type": "integer", "minimum": 2026 }'                    + sLineBreak +
    '          ],'                                                          + sLineBreak +
    '          "items": false'                                              + sLineBreak +
    '        }'                                                             + sLineBreak +
    '      },'                                                              + sLineBreak +
    '      "required": ["number", "expiry"]'                                + sLineBreak +
    '    },'                                                                + sLineBreak +
    '    "iban": { "type": "string", "pattern": "^[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30}$" }' + sLineBreak +
    '  },'                                                                  + sLineBreak +
    '  "required": ["method", "amount"],'                                   + sLineBreak +
    '  "if": { "properties": { "method": { "const": "card" } } },'          + sLineBreak +
    '  "then": { "required": ["card"] },'                                   + sLineBreak +
    '  "else": { "required": ["iban"] }'                                    + sLineBreak +
    '}';

  VALID_PAYMENT =
    '{'                                                        + sLineBreak +
    '  "method": "card",'                                      + sLineBreak +
    '  "amount": { "amount": 129.90, "currency": "EUR" },'      + sLineBreak +
    '  "card": { "number": "4111111111111111", "expiry": [7, 2029] }' + sLineBreak +
    '}';

  INVALID_PAYMENT =
    '{'                                                        + sLineBreak +
    '  "method": "transfer",'                                  + sLineBreak +
    '  "amount": { "amount": 0, "currency": "CHF" }'            + sLineBreak +
    '}';

{ TSchemaDemo }

constructor TSchemaDemo.Create;
begin
  inherited Create;

  FConfig := TNeonConfiguration.Camel;

  FOrderSchema := TNeonSchemaGenerator.ClassToJSONSchema(TOrder, FConfig,
    TNeonJSchemaVersion.v202012);

  FDataFolder := TPath.GetFullPath(TPath.Combine(
    TPath.GetDirectoryName(ParamStr(0)), '..' + PathDelim + 'Data'));
end;

destructor TSchemaDemo.Destroy;
begin
  FOrderSchema.Free;
  inherited;
end;

function TSchemaDemo.ParseJSON(const AJSON: string): TJSONValue;
begin
{$IFDEF HAS_NEW_JSON}
  Result := TJSONObject.ParseJSONValue(AJSON, True, True);
{$ELSE}
  {$IFDEF HAS_JSON_BOOL}
  Result := TJSONObject.ParseJSONValue(AJSON, True);
  {$ELSE}
  Result := TJSONObject.ParseJSONValue(AJSON);
  {$ENDIF}
  if not Assigned(Result) then
    raise ENeonException.Create('The document is not valid JSON');
{$ENDIF}
end;

procedure TSchemaDemo.Header(const ATitle: string);
begin
  WriteLn;
  WriteLn('==============================================================');
  WriteLn(' ', ATitle);
  WriteLn('==============================================================');
end;

procedure TSchemaDemo.PrintJSON(const ACaption: string; AJSON: TJSONValue);
begin
  WriteLn(ACaption);
  WriteLn(TNeon.Print(AJSON, True));
  WriteLn;
end;

procedure TSchemaDemo.PrintResult(const AResult: TJSONValidationResult);
var
  LError: TJSONValidationError;
  LPath: string;
begin
  if AResult.IsValid then
  begin
    WriteLn('  VALID: the document satisfies the schema');
    Exit;
  end;

  WriteLn(Format('  INVALID: %d violation(s)', [Length(AResult.Errors)]));
  for LError in AResult.Errors do
  begin
    // An empty path is the document itself, not a member of it
    LPath := LError.Path;
    if LPath = '' then
      LPath := '(root)';

    WriteLn(Format('    %-32s %-18s %s', [LPath, LError.Keyword, LError.Message]));
  end;
end;

procedure TSchemaDemo.SaveJSON(AJSON: TJSONValue; const AFileName: string);
var
  LFileName: string;
begin
  LFileName := TPath.Combine(FDataFolder, AFileName);

  // TFile.WriteAllText with TEncoding.UTF8 would prepend a byte order mark
  TFile.WriteAllBytes(LFileName, TEncoding.UTF8.GetBytes(TNeon.Print(AJSON, True)));

  WriteLn('  ', LFileName);
end;

function TSchemaDemo.BuildOrder: TOrder;
var
  LItem: TOrderItem;
begin
  Result := TOrder.Create;
  try
    Result.OrderId := 'ORD-000042';
    Result.CreatedAt := EncodeDateTime(2026, 8, 20, 9, 30, 0, 0);
    Result.Status := TOrderStatus.Paid;
    Result.Total := 149.80;
    Result.Notes := 'Deliver after 6pm';

    Result.Customer.Id := 7;
    Result.Customer.FullName := 'Paolo Rossi';
    Result.Customer.Email := 'paolo@example.com';
    Result.Customer.BillingAddress.Street := 'Via Emilia 1';
    Result.Customer.BillingAddress.City := 'Parma';
    Result.Customer.BillingAddress.ZipCode := '43100';
    Result.Customer.BillingAddress.Country := 'IT';
    // ShippingAddress is left nil on purpose: [NeonInclude(NotNull)] keeps it
    // out of the document, and the schema does not require it

    LItem := TOrderItem.Create;
    LItem.Sku := 'SKU-0001';
    LItem.Description := 'Delphi 12 Athens';
    LItem.Quantity := 1;
    LItem.UnitPrice := 129.90;
    Result.Items.Add(LItem);

    LItem := TOrderItem.Create;
    LItem.Sku := 'SKU-0042';
    LItem.Description := 'Neon sticker pack';
    LItem.Quantity := 2;
    LItem.UnitPrice := 9.95;
    Result.Items.Add(LItem);
  except
    Result.Free;
    raise;
  end;
end;

function TSchemaDemo.BuildCatalog: TCategory;
var
  LBooks: TCategory;
begin
  Result := TCategory.Create('Catalog');
  try
    LBooks := Result.AddChild('Books');
    LBooks.AddChild('Programming');
    LBooks.AddChild('Fiction');
    Result.AddChild('Merchandise');
  except
    Result.Free;
    raise;
  end;
end;

procedure TSchemaDemo.StepGenerateSchema;
begin
  Header('1. From a Delphi type to a Draft 2020-12 schema');
  WriteLn('TNeonSchemaGenerator walks the RTTI of TOrder and turns every member');
  WriteLn('into a subschema; the [JsonSchema] tags add the constraints RTTI');
  WriteLn('alone cannot know. The version argument is what puts the 2020-12');
  WriteLn('"$schema" URI at the root - the dialect the document is written in.');
  WriteLn;

  PrintJSON('Schema for TOrder:', FOrderSchema);
end;

procedure TSchemaDemo.StepSerializeAndValidate;
var
  LOrder: TOrder;
  LDocument: TJSONValue;
begin
  Header('2. Serialize an object, then validate the result');
  WriteLn('The object and the schema come from the same type and the same');
  WriteLn('configuration, so this is the round trip that has to hold: whatever');
  WriteLn('Neon writes for a well-formed TOrder must satisfy the schema of');
  WriteLn('TOrder.');
  WriteLn;

  LOrder := BuildOrder;
  try
    LDocument := TNeon.ObjectToJSON(LOrder, FConfig);
    try
      PrintJSON('Serialized order:', LDocument);
      PrintResult(TNeon.ValidateJSON(LDocument, FOrderSchema));
    finally
      LDocument.Free;
    end;
  finally
    LOrder.Free;
  end;
end;

procedure TSchemaDemo.StepInvalidDocument;
var
  LDocument: TJSONValue;
begin
  Header('3. A document that comes from elsewhere');
  WriteLn('The point of validating is the JSON you did not write: a request');
  WriteLn('body, a file, an answer from another service. By default the');
  WriteLn('validator reports every violation it finds, each with a JSON Pointer');
  WriteLn('into the *instance* and the keyword that rejected it.');
  WriteLn;

  LDocument := ParseJSON(INVALID_ORDER);
  try
    PrintJSON('Document to check:', LDocument);
    PrintResult(TNeon.ValidateJSON(LDocument, FOrderSchema));
  finally
    LDocument.Free;
  end;
end;

procedure TSchemaDemo.StepStopOnFirstError;
var
  LValidator: TJSONSchemaValidator;
  LDocument: TJSONValue;
begin
  Header('4. One validator, many documents');
  WriteLn('TJSONSchemaValidator collects the anchors of the schema once, so');
  WriteLn('keeping one instance around beats calling TNeon.ValidateJSON per');
  WriteLn('document. StopOnFirstError turns the full report into a plain');
  WriteLn('yes/no answer, all an "is this request acceptable" check needs.');
  WriteLn;

  LValidator := TJSONSchemaValidator.Create(FOrderSchema);
  try
    LValidator.StopOnFirstError := True;

    LDocument := ParseJSON(INVALID_ORDER);
    try
      WriteLn('Same document as step 3, with StopOnFirstError:');
      PrintResult(LValidator.Validate(LDocument));
    finally
      LDocument.Free;
    end;

    WriteLn;
    LDocument := ParseJSON('[]');
    try
      WriteLn('An array where the schema asks for an object:');
      PrintResult(LValidator.Validate(LDocument));
    finally
      LDocument.Free;
    end;
  finally
    LValidator.Free;
  end;
end;

procedure TSchemaDemo.StepRecursiveType;
var
  LSchema: TJSONObject;
  LCatalog: TCategory;
  LDocument: TJSONValue;
begin
  Header('5. A type that contains itself');
  WriteLn('TCategory holds a list of TCategory, which cannot be inlined: the');
  WriteLn('generator moves the schema into "$defs" and refers to it with');
  WriteLn('"$ref". The validator resolves those references while it descends,');
  WriteLn('so a tree of any depth is checked by the one definition.');
  WriteLn;

  LSchema := TNeonSchemaGenerator.ClassToJSONSchema(TCategory, FConfig,
    TNeonJSchemaVersion.v202012);
  try
    PrintJSON('Schema for TCategory:', LSchema);

    LCatalog := BuildCatalog;
    try
      LDocument := TNeon.ObjectToJSON(LCatalog, FConfig);
      try
        PrintJSON('Serialized tree:', LDocument);
        PrintResult(TNeon.ValidateJSON(LDocument, LSchema));
      finally
        LDocument.Free;
      end;
    finally
      LCatalog.Free;
    end;

    WriteLn;
    WriteLn('The same tree with an empty name three levels down:');
    LDocument := ParseJSON(
      '{"name":"Catalog","children":[{"name":"Books","children":[{"name":"","children":[]}]}]}');
    try
      PrintResult(TNeon.ValidateJSON(LDocument, LSchema));
    finally
      LDocument.Free;
    end;
  finally
    LSchema.Free;
  end;
end;

procedure TSchemaDemo.StepHandWrittenSchema;
var
  LSchema, LDocument: TJSONValue;
begin
  Header('6. A schema nobody generated');
  WriteLn('The validator takes any TJSONValue as its schema, so a document');
  WriteLn('written by hand (or downloaded, or stored in a table) works just as');
  WriteLn('well as a generated one. This one uses keywords a Delphi type has no');
  WriteLn('way to express: "$ref" to a named definition, "prefixItems" for a');
  WriteLn('positional array, and if/then/else to let the value of one member');
  WriteLn('decide which other member is mandatory.');
  WriteLn;

  LSchema := ParseJSON(PAYMENT_SCHEMA);
  try
    PrintJSON('Payment schema:', LSchema);

    LDocument := ParseJSON(VALID_PAYMENT);
    try
      WriteLn('A card payment with the card details:');
      PrintResult(TNeon.ValidateJSON(LDocument, LSchema));
    finally
      LDocument.Free;
    end;

    WriteLn;
    LDocument := ParseJSON(INVALID_PAYMENT);
    try
      WriteLn('A transfer with no IBAN, a zero amount and an unlisted currency:');
      PrintResult(TNeon.ValidateJSON(LDocument, LSchema));
    finally
      LDocument.Free;
    end;
  finally
    LSchema.Free;
  end;
end;

procedure TSchemaDemo.SaveEntities;
var
  LOrder: TOrder;
  LCatalog: TCategory;
  LDocument: TJSONValue;
  LSchema: TJSONObject;
begin
  Header('7. The same pair, on disk');
  WriteLn('Everything above happens in memory, where the only thing checking');
  WriteLn('the schema is the validator that came with it. Writing the schema');
  WriteLn('and the document it describes side by side lets any other tool have');
  WriteLn('a say - a JSON Schema validator of another language, an editor that');
  WriteLn('completes against a schema, or the reviewer of a pull request.');
  WriteLn;

  TDirectory.CreateDirectory(FDataFolder);

  LOrder := BuildOrder;
  try
    LDocument := TNeon.ObjectToJSON(LOrder, FConfig);
    try
      SaveJSON(FOrderSchema, 'order.schema.json');
      SaveJSON(LDocument, 'order.json');
    finally
      LDocument.Free;
    end;
  finally
    LOrder.Free;
  end;

  LSchema := TNeonSchemaGenerator.ClassToJSONSchema(TCategory, FConfig,
    TNeonJSchemaVersion.v202012);
  try
    LCatalog := BuildCatalog;
    try
      LDocument := TNeon.ObjectToJSON(LCatalog, FConfig);
      try
        SaveJSON(LSchema, 'category.schema.json');
        SaveJSON(LDocument, 'category.json');
      finally
        LDocument.Free;
      end;
    finally
      LCatalog.Free;
    end;
  finally
    LSchema.Free;
  end;

  WriteLn;
  WriteLn('Any Draft 2020-12 validator can now be pointed at the pair, e.g.');
  WriteLn('  check-jsonschema --schemafile order.schema.json order.json');
end;

procedure TSchemaDemo.Run;
begin
  WriteLn('Neon - JSON Schema (Draft 2020-12): generate, then validate');

  StepGenerateSchema;
  StepSerializeAndValidate;
  StepInvalidDocument;
  StepStopOnFirstError;
  StepRecursiveType;
  StepHandWrittenSchema;
  SaveEntities;

  Header('What the validator does not do (yet)');
  WriteLn('- "format" is an annotation only: "date-time" and the rest are');
  WriteLn('  written into the schema but never checked against the value');
  WriteLn('- "$ref" is resolved inside the document only; a reference to');
  WriteLn('  another document raises an exception rather than fetching it');
  WriteLn('- "unevaluatedProperties"/"unevaluatedItems" are not implemented');
end;

end.
