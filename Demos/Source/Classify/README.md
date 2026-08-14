# Classify

Command line front end of `TNeonEntityGenerator` (`Neon.Core.Generator`): give it a JSON document, it writes the Delphi entities that hold it.

```
Classify [options] <document.json>
```

The examples below all use [`customer.json`](../../Data/customer.json), in the `Demos\Data` folder with the rest of the demo documents. The built executable ends up in `Demos\Bin`, so the commands are written as they would be run from this folder.

Run `Classify --help` for the same list of switches as below, and `Classify` with no arguments at all for a guided tour of what the generator does.

## Options

The switches can come before or after the document, in any order, and each one maps to a field of `TNeonEntityConfig`: whatever the command line does here, your own code can do with `TNeonEntityConfig.Default.Set*`. An unknown switch, a switch missing its value, or a document that is not there stops the program with the message, the usage and an exit code of 1.

### Input and output

| Switch | Default | What it does |
| --- | --- | --- |
| `<document.json>` | — | The JSON document to read, given without a switch. Only one is accepted; with none at all the program prints its set of examples instead. Its root is normally an object or an array of objects — anything else generates no entity, only a warning and the Delphi type the root maps to |
| `-o`, `--output <file>` | standard output | Writes the unit to `<file>` (UTF-8), and prints a summary and the warnings instead of the source. Without it the whole unit goes to standard output, ready to be piped or pasted |
| `-u`, `--unit <name>` | the base name of `--output`, or `Demo.Entities` | Name written in the `unit` clause. Worth setting explicitly when printing to standard output, since there is no output file to take it from |
| `-h`, `--help`, `-?` | — | Prints the usage and generates nothing |

### What to generate

| Switch | Default | What it does |
| --- | --- | --- |
| `-k`, `--kind <class\|record>` | `class` | `class` gives private fields and public properties; `record` gives public fields. A record owns nothing, so it never gets a constructor/destructor and its arrays are always `TArray<T>` whatever `--array` says |
| `-a`, `--array <objectlist\|list\|array>` | `objectlist` | The container generated for a JSON array **of objects** (arrays of simple values are always `TArray<T>`). `objectlist` is `TObjectList<T>` created with `OwnsObjects` on, which is the only one of the three that frees the items for you; `list` is `TList<T>`; `array` is `TArray<T>`, and leaves the lifetime of the items entirely to you |
| `-n`, `--nullables` | off | Generates `Nullable<T>` for the members that are null in the document, or missing from some of the items of an array. Only the simple types are wrapped: a class member is already nil when the document says null, and a dynamic array is already empty |
| `--unknown-type <type>` | `string` | The type generated where the document says nothing at all: a member that is always null, an array that is always empty. Each of those is reported as a warning too, so you can go and fix the type by hand |
| `--no-datetime` | off | Leaves the ISO8601 strings as `string`. By default a member whose every sample looks like a date, a date/time or a time becomes a `TDateTime` — one sample that does not is enough to rule the member out |
| `--no-merge` | off | Generates one type per JSON object, even when two have exactly the same members and member types. By default such objects share a single entity, named after the first one met |
| `--no-lifetime` | off | Leaves out the constructor/destructor pair generated for the entities owning others (nested entities and object lists). Their members then start out nil, so the serializer has to create them: `Config.SetAutoCreate(True)`, or `[NeonAutoCreate]` on the member |

### Naming

| Switch | Default | What it does |
| --- | --- | --- |
| `-p`, `--prefix <prefix>` | `T` | Prefix of every generated type name |
| `-r`, `--root <name>` | `Root` | Base name of the type generated for the root of the document, prefix apart. When the root is an array the items take this name, and the alias for their container becomes `<prefix><name>List` |
| `--unchanged-names` | off | Keeps the JSON member names as they are, minus the characters that are not legal in an identifier (`first_name`, `zip_code`). By default they are turned into PascalCase whatever convention they follow — `user_name`, `zip-code`, `USER_ID` and `userName` all read the same way afterwards. Type names are always PascalCase |
| `--no-attributes` | off | Never emits `[NeonProperty]`. By default it is emitted wherever the Delphi identifier is not exactly the JSON member name, which is what makes the entities round-trip the document; without it, the serializer has to be configured with a member case that matches the document (`TNeonConfiguration.Camel`, `.Snake`, ...) |

### Layout

| Switch | Default | What it does |
| --- | --- | --- |
| `-i`, `--indent <n>` | `2` | Spaces of one indentation level |
| `--no-header` | off | Leaves out the "generated file" banner at the top of the unit. The generated source carries no timestamp either way, so regenerating a unit that has not changed leaves the file byte for byte identical |

## Generate classes and print them

```
..\..\Bin\Classify ..\..\Data\customer.json
```

```delphi
unit Demo.Entities;

interface

uses
  System.Generics.Collections, Neon.Core.Attributes;

type
  TBillingAddress = class
  private
    FStreet: string;
    FCity: string;
    FZip: string;
  public
    [NeonProperty('street')]
    property Street: string read FStreet write FStreet;
    ...
  end;

  TOrder = class
    ...
  end;

  TRoot = class
  private
    FId: Integer;
    FFirstName: string;
    FType: string;
    FCreatedAt: TDateTime;
    FTags: TArray<string>;
    FBillingAddress: TBillingAddress;
    FShippingAddress: TBillingAddress;
    FOrders: TObjectList<TOrder>;
  public
    constructor Create;
    destructor Destroy; override;

    [NeonProperty('id')]
    property Id: Integer read FId write FId;
    [NeonProperty('first_name')]
    property FirstName: string read FFirstName write FFirstName;
    [NeonProperty('type')]
    property &Type: string read FType write FType;
    [NeonProperty('created_at')]
    property CreatedAt: TDateTime read FCreatedAt write FCreatedAt;
    ...
    [NeonProperty('shipping-address')]
    property ShippingAddress: TBillingAddress read FShippingAddress write FShippingAddress;
    [NeonProperty('orders')]
    property Orders: TObjectList<TOrder> read FOrders write FOrders;
  end;

implementation

{ TRoot }

constructor TRoot.Create;
begin
  inherited Create;
  FBillingAddress := TBillingAddress.Create;
  FShippingAddress := TBillingAddress.Create;
  FOrders := TObjectList<TOrder>.Create(True);
end;
...
```

```
Warnings:
  - Position [TRoot.nickname] is always null: generated as [string]
```

The two addresses have the same members, so they share one type. `nickname` is null everywhere, and there is nothing in the document to generate it from: the warning says so, and `string` is the fallback (`--unknown-type` changes it).

## Write the unit to a file

```
..\..\Bin\Classify -o Api.Customer.pas -p TApi -r Customer -n ..\..\Data\customer.json
```

```
Unit [Api.Customer] written to [Api.Customer.pas]
Root type: TApiCustomer

Warnings:
  - Position [TApiCustomer.nickname] is always null: generated as [string]
```

The unit name is taken from the output file when `-u` is not given. `-p`/`-r` name the types (`TApiCustomer`, `TApiOrder`, `TApiBillingAddress`), and `-n` turns the members that can be missing or null into `Nullable<T>` — `note` is absent from the first order, so:

```delphi
uses
  System.Generics.Collections, Neon.Core.Nullables, Neon.Core.Attributes;
...
  TApiOrder = class
  private
    FCode: string;
    FTotal: Double;
    FShipped: Boolean;
    FNote: Nullable<string>;
```

## Generate records instead

```
..\..\Bin\Classify -k record --no-header ..\..\Data\customer.json
```

```delphi
unit Demo.Entities;

interface

uses
  Neon.Core.Attributes;

type
  TBillingAddress = record
    [NeonProperty('street')]
    Street: string;
    [NeonProperty('city')]
    City: string;
    [NeonProperty('zip')]
    Zip: string;
  end;
  ...
  TRoot = record
    ...
    [NeonProperty('billing-address')]
    BillingAddress: TBillingAddress;
    [NeonProperty('orders')]
    Orders: TArray<TOrder>;
  end;

implementation

end.
```

Records own nothing, so the arrays of entities are dynamic arrays and no constructor/destructor is generated.

## A document whose root is an array

```
..\..\Bin\Classify -r Order -u Api.Orders --no-header ..\..\Data\orders.json
```

with [`orders.json`](../../Data/orders.json) holding `[{"code":"A1","total":10.5},{"code":"A2","total":20.0,"note":"gift"}]`:

```delphi
unit Api.Orders;

interface

uses
  System.Generics.Collections, Neon.Core.Attributes;

type
  TOrder = class
  private
    FCode: string;
    FTotal: Double;
    FNote: string;
  public
    [NeonProperty('code')]
    property Code: string read FCode write FCode;
    [NeonProperty('total')]
    property Total: Double read FTotal write FTotal;
    [NeonProperty('note')]
    property Note: string read FNote write FNote;
  end;

  TOrderList = TObjectList<TOrder>;

implementation

end.
```

The items are what the document is about: they take the root name, and the root itself becomes an alias for their container. Every item is a sample of the same entity, which is why `note` is there even though only the second order carries it.

## Tuning the output

```
..\..\Bin\Classify -p TCrm -r Customer -a array --no-merge --no-lifetime --no-header ..\..\Data\customer.json
```

```delphi
type
  TCrmBillingAddress = class
  private
    FStreet: string;
    ...
  end;

  TCrmShippingAddress = class
  private
    FStreet: string;
    ...
```

`--no-merge` gives every JSON object its own type even when two are identical — the two addresses no longer share one — while `-a array` uses `TArray<T>` for the arrays of objects and `--no-lifetime` leaves the creation of the members to you (or to Neon's `AutoCreate`).

## Names left alone

```
..\..\Bin\Classify --unchanged-names --no-header ..\..\Data\customer.json
```

```delphi
  TBillingAddress = class
  private
    Fstreet: string;
    Fcity: string;
    Fzip: string;
  public
    property street: string read Fstreet write Fstreet;
    ...
```

The JSON names become the identifiers, so most members need no `[NeonProperty]` at all — only the ones holding a character that is not legal in an identifier still do (`billing-address` becomes `billing_address`, and keeps its attribute).

## Errors

An unknown switch, a missing value or a file that is not there is reported and followed by the usage, with an exit code of 1:

```
> ..\..\Bin\Classify --nope ..\..\Data\customer.json
Error: Unknown switch [--nope]

Generates Delphi entities from a JSON document
...
```
