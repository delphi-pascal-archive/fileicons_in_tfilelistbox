program Demo;

uses
  Forms,
  UMain in 'UMain.pas' {frmMain},
  CustomFileCtrl in 'CustomFileCtrl.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
