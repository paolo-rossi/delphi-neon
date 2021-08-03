{******************************************************************************}
{                                                                              }
{  Neon: Serialization Library for Delphi                                      }
{  Copyright (c) 2018-2021 Paolo Rossi                                         }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{******************************************************************************}
{                                                                              }
{  Licensed under the Apache License, Version 2.0 (the "License");             }
{  you may not use this file except in compliance with the License.            }
{  You may obtain a copy of the License at                                     }
{                                                                              }
{      http://www.apache.org/licenses/LICENSE-2.0                              }
{                                                                              }
{  Unless required by applicable law or agreed to in writing, software         }
{  distributed under the License is distributed on an "AS IS" BASIS,           }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    }
{  See the License for the specific language governing permissions and         }
{  limitations under the License.                                              }
{                                                                              }
{******************************************************************************}
unit Demo.Frame.Configuration;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  System.TypInfo,

  Neon.Core.Types,
  Neon.Core.Persistence;

type
  TSerializersType = (CustomNeon, CustomDemo);
  TSerializersSet = set of TSerializersType;

  TframeConfiguration = class(TFrame)
    grpType: TGroupBox;
    grpCase: TGroupBox;
    rbCasePascal: TRadioButton;
    rbCaseCamel: TRadioButton;
    rbCaseSnake: TRadioButton;
    rbCaseLower: TRadioButton;
    rbCaseUpper: TRadioButton;
    rbCaseCustom: TRadioButton;
    grpPrefix: TGroupBox;
    chkVisibilityPrivate: TCheckBox;
    chkVisibilityProtected: TCheckBox;
    chkVisibilityPublic: TCheckBox;
    chkVisibilityPublished: TCheckBox;
    lblCaption: TLabel;
    GroupBox1: TGroupBox;
    chkUseUTCDate: TCheckBox;
    chkPrettyPrinting: TCheckBox;
    chkIgnorePrefix: TCheckBox;
    chkMemberStandard: TCheckBox;
    chkMemberFields: TCheckBox;
    chkMemberProperties: TCheckBox;
  private
    FCustomCaseAlgo: TCaseFunc;
  public
    procedure Initialize;
    function BuildSerializerConfig(ASerializers: TSerializersSet = [TSerializersType.CustomNeon]): INeonConfiguration;

    procedure RegisterNeonSerializers(ARegistry: TNeonSerializerRegistry);
    procedure UnregisterNeonSerializers(ARegistry: TNeonSerializerRegistry);

    procedure RegisterDemoSerializers(ARegistry: TNeonSerializerRegistry);
    procedure UnregisterDemoSerializers(ARegistry: TNeonSerializerRegistry);
  end;

implementation

uses
  Neon.Core.Serializers.DB,
  Neon.Core.Serializers.RTL,
  Neon.Core.Serializers.VCL,
  Neon.Core.Serializers.Nullables,

  Demo.Neon.Serializers;

{$R *.dfm}

function TframeConfiguration.BuildSerializerConfig(ASerializers: TSerializersSet): INeonConfiguration;
var
  LVis: TNeonVisibility;
  LMembers: TNeonMembersSet;
begin
  LVis := [];
  LMembers := [TNeonMembers.Standard];
  Result := TNeonConfiguration.Default;

  // Case settings
  Result.SetMemberCustomCase(nil);
  if rbCaseCamel.Checked then
    Result.SetMemberCase(TNeonCase.CamelCase);
  if rbCaseSnake.Checked then
    Result.SetMemberCase(TNeonCase.SnakeCase);
  if rbCaseLower.Checked then
    Result.SetMemberCase(TNeonCase.LowerCase);
  if rbCaseUpper.Checked then
    Result.SetMemberCase(TNeonCase.UpperCase);
  if rbCaseCustom.Checked then
    Result
      .SetMemberCase(TNeonCase.CustomCase)
      .SetMemberCustomCase(FCustomCaseAlgo);

  // Member type settings
  if chkMemberFields.Checked then
    LMembers := LMembers + [TNeonMembers.Fields];
  if chkMemberProperties.Checked then
    LMembers := LMembers + [TNeonMembers.Properties];
  Result.SetMembers(LMembers);

  // F Prefix setting
  Result.SetIgnoreFieldPrefix(chkIgnorePrefix.Checked);

  // Use UTC Date
  Result.SetUseUTCDate(chkUseUTCDate.Checked);

  // Pretty Printing
  Result.SetPrettyPrint(chkPrettyPrinting.Checked);

  // Visibility settings
  if chkVisibilityPrivate.Checked then
    LVis := LVis + [mvPrivate];
  if chkVisibilityProtected.Checked then
    LVis := LVis + [mvProtected];
  if chkVisibilityPublic.Checked then
    LVis := LVis + [mvPublic];
  if chkVisibilityPublished.Checked then
    LVis := LVis + [mvPublished];
  Result.SetVisibility(LVis);

  //Custom Serializers

  if TSerializersType.CustomNeon in ASerializers then
    RegisterNeonSerializers(Result.GetSerializers);

  if TSerializersType.CustomDemo in ASerializers then
    RegisterDemoSerializers(Result.GetSerializers);
end;

procedure TframeConfiguration.Initialize;
begin
  FCustomCaseAlgo :=
    function(const AString: string): string
    begin
      Result := AString + 'X';
    end
  ;
end;

procedure TframeConfiguration.RegisterNeonSerializers(ARegistry: TNeonSerializerRegistry);
begin
  //RTL serializers
  ARegistry.RegisterSerializer(TGUIDSerializer);
  ARegistry.RegisterSerializer(TStreamSerializer);
  ARegistry.RegisterSerializer(TJSONValueSerializer);
  ARegistry.RegisterSerializer(TTValueSerializer);
  //DB serializers
  ARegistry.RegisterSerializer(TDataSetSerializer);
  //VCL serializers
  ARegistry.RegisterSerializer(TImageSerializer);
  // Nullable serializers
  RegisterNullableSerializers(ARegistry);
end;

procedure TframeConfiguration.UnregisterNeonSerializers(ARegistry: TNeonSerializerRegistry);
begin
  //RTL serializers
  ARegistry.UnregisterSerializer(TGUIDSerializer);
  ARegistry.UnregisterSerializer(TStreamSerializer);
  ARegistry.UnregisterSerializer(TJSONValueSerializer);
  //DB serializers
  ARegistry.UnregisterSerializer(TDataSetSerializer);
  //VCL serializers
  ARegistry.UnregisterSerializer(TImageSerializer);
  // Nullable serializers
  UnregisterNullableSerializers(ARegistry);
end;

procedure TframeConfiguration.RegisterDemoSerializers(ARegistry: TNeonSerializerRegistry);
begin
  // Demo Serializers
  ARegistry.RegisterSerializer(TCustomDateSerializer);
  ARegistry.RegisterSerializer(TTimeSerializer);
  ARegistry.RegisterSerializer(TPoint3DSerializer);
  ARegistry.RegisterSerializer(TParameterSerializer);
  ARegistry.RegisterSerializer(TFontSerializer);
end;

procedure TframeConfiguration.UnregisterDemoSerializers(ARegistry: TNeonSerializerRegistry);
begin
  // Demo Serializers
  ARegistry.UnregisterSerializer(TCustomDateSerializer);
  ARegistry.UnregisterSerializer(TTimeSerializer);
  ARegistry.UnregisterSerializer(TPoint3DSerializer);
  ARegistry.UnregisterSerializer(TParameterSerializer);
  ARegistry.UnregisterSerializer(TFontSerializer);
end;

end.
