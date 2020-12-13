{******************************************************************************}
{                                                                              }
{  Neon: Serialization Library for Delphi                                      }
{  Copyright (c) 2018-2019 Paolo Rossi                                         }
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
    function BuildSerializerConfig: INeonConfiguration;
  end;

implementation

uses
  Neon.Core.Serializers.DB,
  Neon.Core.Serializers.RTL,
  Neon.Core.Serializers.VCL,

  Demo.Neon.Serializers;

{$R *.dfm}

function TframeConfiguration.BuildSerializerConfig: INeonConfiguration;
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

  //RTL serializers
  Result.GetSerializers.RegisterSerializer(TGUIDSerializer);
  Result.GetSerializers.RegisterSerializer(TStreamSerializer);
  //DB serializers
  Result.GetSerializers.RegisterSerializer(TDataSetSerializer);
  //VCL serializers
  Result.GetSerializers.RegisterSerializer(TImageSerializer);

  // Demo Serializers
  Result.GetSerializers.RegisterSerializer(TCustomDateSerializer);
  Result.GetSerializers.RegisterSerializer(TTimeSerializer);
  Result.GetSerializers.RegisterSerializer(TPoint3DSerializer);
  Result.GetSerializers.RegisterSerializer(TParameterSerializer);
  Result.GetSerializers.RegisterSerializer(TFontSerializer);
  Result.GetSerializers.RegisterSerializer(TCaseClassSerializer);
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

end.
