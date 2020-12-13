unit Demo.Forms.Serialization.Schema;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, System.Generics.Collections,
  System.Actions, Vcl.ActnList, System.ImageList, Vcl.ImgList, Vcl.CategoryButtons,
  System.JSON, System.Rtti,

  Demo.Forms.Serialization.Base,
  Demo.Frame.Configuration,
  Neon.Core.Types,
  Neon.Core.Attributes,
  Neon.Core.Persistence,
  Neon.Core.Persistence.Swagger,
  Neon.Core.Utils;

type
  TfrmSerializationSchema = class(TfrmSerializationBase)
    actSerJSONSchema: TAction;
    procedure actSerJSONSchemaExecute(Sender: TObject);
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

procedure TfrmSerializationSchema.actSerJSONSchemaExecute(Sender: TObject);
var
  LJSON: TJSONObject;
begin
  LJSON := TNeonSchemaGenerator.ClassToJSONSchema(TCaseClass);
  try
    memoSerialize.Lines.Text := TNeon.Print(LJSON, True);
  finally
    LJSON.Free;
  end;
end;

end.
