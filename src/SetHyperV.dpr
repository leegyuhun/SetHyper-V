program SetHyperV;

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {MainForm},
  HyperVControl in 'HyperVControl.pas',
  AdminHelper in 'AdminHelper.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
