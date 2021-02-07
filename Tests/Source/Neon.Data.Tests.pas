unit Neon.Data.Tests;

interface

uses
  System.SysUtils, System.Classes,
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  {$ENDIF}

  FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, FireDAC.Stan.StorageBin, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client, FireDAC.Stan.StorageJSON;

type
  TDataTests = class(TDataModule)
    Persons: TFDMemTable;
    PersonsName: TStringField;
    PersonsAge: TIntegerField;
    PersonsDeveloper: TBooleanField;
    FDStanStorageJSONLink1: TFDStanStorageJSONLink;
    procedure DataModuleCreate(Sender: TObject);
  private
    FDataPath: string;
  public
    procedure LoadDataSet(ADataSet: TFDMemTable);
    procedure LoadDataSets;
  end;

var
  DataTests: TDataTests;

implementation

uses
  System.IOUtils;

{%CLASSGROUP 'System.Classes.TPersistent'}

{$R *.dfm}

procedure TDataTests.DataModuleCreate(Sender: TObject);
begin
  FDataPath := TDirectory.GetCurrentDirectory;
  FDataPath := TDirectory.GetParent(FDataPath);
  FDataPath := TDirectory.GetParent(FDataPath);
  FDataPath := TPath.Combine(FDataPath, 'Data');
end;

procedure TDataTests.LoadDataSet(ADataSet: TFDMemTable);
begin
  ADataSet.LoadFromFile(TPath.Combine(FDataPath, ClassName + '.' + ADataSet.Name + '.json'));
end;

procedure TDataTests.LoadDataSets;
begin
  LoadDataSet(Persons);
end;

end.
