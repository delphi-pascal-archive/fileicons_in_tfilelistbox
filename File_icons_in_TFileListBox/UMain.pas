unit UMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls,
  FileCtrl,  {Unit� d'origine}
  CustomFileCtrl {Unit� Surcharg�e a placer toujours apr�s FileCtrl};

type
  TfrmMain = class(TForm)
    FileListBox1: TFileListBox;
    DirectoryListBox1: TDirectoryListBox;
    DriveComboBox1: TDriveComboBox;
  private
    { D�clarations priv�es }
  public
    { D�clarations publiques }
  end;

var
  frmMain: TfrmMain;

implementation
{$R *.DFM}

end.
