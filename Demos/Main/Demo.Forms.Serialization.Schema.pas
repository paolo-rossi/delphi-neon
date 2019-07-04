unit Demo.Forms.Serialization.Schema;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, System.Generics.Collections,
  System.json,

  Demo.Forms.Serialization.Base,
  Demo.Frame.Configuration,
  Neon.Core.Types,
  Neon.Core.Attributes,
  Neon.Core.Persistence,
  Neon.Core.Serializers,
  Neon.Core.Persistence.Swagger,
  Neon.Core.Utils;

type
  TfrmSerializationSchema = class(TfrmSerializationBase)
    btnSchemaCaseClass: TButton;
    procedure btnSchemaCaseClassClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmSerializationSchema: TfrmSerializationSchema;

implementation

uses
  Demo.Neon.Entities, Neon.Core.Persistence.JSON;

{$R *.dfm}

procedure TfrmSerializationSchema.btnSchemaCaseClassClick(Sender: TObject);
var
  LSchema: TNeonSchemaGenerator;
  LJSON: TJSONValue;
begin
  LSchema := TNeonSchemaGenerator.Create(TNeonConfiguration.Default);
  try
    LJSON := LSchema.ClassToJSONSchema(TCaseClass);
    try
      memoSerialize.Lines.Text := TNeon.Print(LJSON, True);
    finally
      LJSON.Free;
    end;
  finally
    LSchema.Free;
  end;
end;

end.
