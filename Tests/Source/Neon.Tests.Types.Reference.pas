{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Tests.Types.Reference;

interface

uses
  System.SysUtils, System.Rtti, System.Generics.Collections, DUnitX.TestFramework,
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  {$ENDIF}

  Neon.Core.Persistence,
  Neon.Tests.Entities,
  Neon.Tests.Utils;

type
  /// <summary>
  ///   A plain class holding a reference to another node (or to itself): the
  ///   serialization path must not follow a reference back into it
  /// </summary>
  TRefNode = class
  private
    FName: string;
    FRef: TRefNode;
  public
    property Name: string read FName write FName;
    property Ref: TRefNode read FRef write FRef;
  end;

  /// <summary>
  ///   Two members holding the very same instance: not a cycle, so both must
  ///   still be written out
  /// </summary>
  TSharedRefHolder = class
  private
    FFirst: TRefNode;
    FSecond: TRefNode;
  public
    property First: TRefNode read FFirst write FFirst;
    property Second: TRefNode read FSecond write FSecond;
  end;

  /// <summary>
  ///   A tree whose children point back to their parent through a list: the
  ///   usual shape of a circular reference in an entity model
  /// </summary>
  TTreeNode = class
  private
    FName: string;
    FParent: TTreeNode;
    FChildren: TObjectList<TTreeNode>;
  public
    constructor Create(const AName: string);
    destructor Destroy; override;
    function AddChild(const AName: string): TTreeNode;

    property Name: string read FName write FName;
    property Parent: TTreeNode read FParent write FParent;
    property Children: TObjectList<TTreeNode> read FChildren write FChildren;
  end;

  [TestFixture]
  [Category('reftypes')]
  TTestReferenceTypes = class(TObject)
  private
    FDataPath: string;
    FPerson1: TPerson;
    FPerson2: TPerson;

    function GetFileName(const AMethod: string): string;
  public
    constructor Create;
    destructor Destroy; override;

    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    [TestCase('TestPersonAnsi', 'TestPersonAnsi')]
    procedure TestPersonAnsi(const AMethod: string);

    [Test]
    [TestCase('TestPersonUnicode', 'TestPersonUnicode')]
    procedure TestPersonUnicode(const AMethod: string);

    [Test]
    [TestCase('TestPersonPretty', 'TestPersonPretty')]
    procedure TestPersonPretty(const AMethod: string);

    [Test]
    [TestCase('TestPersonNil', 'TestPersonNil')]
    procedure TestPersonNil(const AMethod: string);

    [Test]
    procedure TestNilArrayElementsSerializeAsNull;

    [Test]
    procedure TestSelfReferenceIsOmitted;

    [Test]
    procedure TestCircularReferenceIsOmitted;

    [Test]
    procedure TestParentReferenceIsOmitted;

    [Test]
    procedure TestSharedReferenceIsWrittenTwice;

    [Test]
    procedure TestCircularRefsOffWritesAcyclicGraph;
  end;

implementation

uses
  System.IOUtils, System.DateUtils;

{ TTreeNode }

constructor TTreeNode.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
  FChildren := TObjectList<TTreeNode>.Create(True);
end;

destructor TTreeNode.Destroy;
begin
  FChildren.Free;
  inherited;
end;

function TTreeNode.AddChild(const AName: string): TTreeNode;
begin
  Result := TTreeNode.Create(AName);
  Result.Parent := Self;
  FChildren.Add(Result);
end;

{ TTestReferenceTypes }

constructor TTestReferenceTypes.Create;
begin
  FDataPath := TPath.GetAppPath;
  FDataPath := TDirectory.GetParent(FDataPath);
  FDataPath := TPath.Combine(FDataPath, 'Data');

  FPerson1 := TPerson.Create('Paolo', 50);
  FPerson1.AddAddress('Via Trento, 30', 'Parma', 'Italy', True);
  FPerson1.AddContact(TContactType.Phone, '+39.123.4567890');
  FPerson1.AddContact(TContactType.Email, 'paolo@mail.com');

  FPerson2 := TPerson.Create('', -0);
  FPerson2.AddAddress('Via Москва 334', 'Москва', 'Россия', True);
  FPerson2.AddContact(TContactType.Phone, '+39.123.4567890');
  FPerson2.AddContact(TContactType.Email, 'paolo@mail.com');
end;

destructor TTestReferenceTypes.Destroy;
begin
  FPerson1.Free;
  FPerson2.Free;

  inherited;
end;

function TTestReferenceTypes.GetFileName(const AMethod: string): string;
begin
  Result := TPath.Combine(FDataPath, ClassName + '.' + AMethod + '.json');
end;

procedure TTestReferenceTypes.Setup;
begin
end;

procedure TTestReferenceTypes.TearDown;
begin
end;

procedure TTestReferenceTypes.TestPersonAnsi(const AMethod: string);
begin
  Assert.AreEqual(
    TTestUtils.ExpectedFromFile(GetFileName(AMethod)),
    TTestUtils.SerializeObject(FPerson1));
end;

procedure TTestReferenceTypes.TestPersonNil(const AMethod: string);
begin
  Assert.AreEqual('{}',
    TTestUtils.SerializeObject(nil, TNeonConfiguration.Default));
end;

procedure TTestReferenceTypes.TestNilArrayElementsSerializeAsNull;
var
  LArray: TArray<TObject>;
begin
  // A nil element must serialize as JSON null, not as a nil TJSONValue
  // (which corrupts the array or raises on newer RTLs)
  SetLength(LArray, 3);
  Assert.AreEqual('[null,null,null]',
    TTestUtils.SerializeValue(TValue.From<TArray<TObject>>(LArray)));
end;

procedure TTestReferenceTypes.TestPersonPretty(const AMethod: string);
begin
  Assert.AreEqual(
    TTestUtils.ExpectedFromFile(GetFileName(AMethod)),
    TTestUtils.SerializeObject(FPerson1, TNeonConfiguration.Pretty));
end;

procedure TTestReferenceTypes.TestPersonUnicode(const AMethod: string);
begin
  Assert.AreEqual(
    TTestUtils.ExpectedFromFile(GetFileName(AMethod)),
    TTestUtils.SerializeObject(FPerson2));
end;

procedure TTestReferenceTypes.TestSelfReferenceIsOmitted;
var
  LNode: TRefNode;
begin
  LNode := TRefNode.Create;
  try
    LNode.Name := 'root';
    LNode.Ref := LNode;

    Assert.AreEqual('{"Name":"root"}', TTestUtils.SerializeObject(LNode));
  finally
    LNode.Free;
  end;
end;

procedure TTestReferenceTypes.TestCircularReferenceIsOmitted;
var
  LFirst, LSecond: TRefNode;
begin
  LFirst := TRefNode.Create;
  LSecond := TRefNode.Create;
  try
    LFirst.Name := 'first';
    LSecond.Name := 'second';
    LFirst.Ref := LSecond;
    LSecond.Ref := LFirst;

    // The cycle is cut where it closes: second is written inside first, and its
    // reference back to first is omitted
    Assert.AreEqual('{"Name":"first","Ref":{"Name":"second"}}',
      TTestUtils.SerializeObject(LFirst));
    Assert.AreEqual('{"Name":"second","Ref":{"Name":"first"}}',
      TTestUtils.SerializeObject(LSecond));
  finally
    LSecond.Free;
    LFirst.Free;
  end;
end;

procedure TTestReferenceTypes.TestParentReferenceIsOmitted;
var
  LRoot: TTreeNode;
begin
  LRoot := TTreeNode.Create('root');
  try
    LRoot.AddChild('left');
    LRoot.AddChild('right').AddChild('leaf');

    // Every Parent points to a node already on the path (through the Children
    // list), so none of them is written
    Assert.AreEqual(
      '{"Name":"root","Children":[' +
        '{"Name":"left","Children":[]},' +
        '{"Name":"right","Children":[{"Name":"leaf","Children":[]}]}' +
      ']}',
      TTestUtils.SerializeObject(LRoot));
  finally
    LRoot.Free;
  end;
end;

procedure TTestReferenceTypes.TestSharedReferenceIsWrittenTwice;
var
  LNode: TRefNode;
  LHolder: TSharedRefHolder;
begin
  LNode := TRefNode.Create;
  LHolder := TSharedRefHolder.Create;
  try
    LNode.Name := 'shared';
    LHolder.First := LNode;
    LHolder.Second := LNode;

    // The same instance reached twice on sibling members is not a cycle: the
    // guard is scoped to the path, not a global "already written" set
    Assert.AreEqual('{"First":{"Name":"shared"},"Second":{"Name":"shared"}}',
      TTestUtils.SerializeObject(LHolder));
  finally
    LHolder.Free;
    LNode.Free;
  end;
end;

procedure TTestReferenceTypes.TestCircularRefsOffWritesAcyclicGraph;
var
  LNode: TRefNode;
  LHolder: TSharedRefHolder;
begin
  LNode := TRefNode.Create;
  LHolder := TSharedRefHolder.Create;
  try
    LNode.Name := 'shared';
    LHolder.First := LNode;
    LHolder.Second := LNode;

    Assert.AreEqual('{"First":{"Name":"shared"},"Second":{"Name":"shared"}}',
      TTestUtils.SerializeObject(LHolder,
        TNeonConfiguration.Default.SetIgnoreCircularRefs(False)));
  finally
    LHolder.Free;
    LNode.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestReferenceTypes);

end.