unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Dialogs,
  HyperVControl,
  AdminHelper;

type
  TMainForm = class(TForm)
    lblStatusCaption: TLabel;
    lblStatusValue: TLabel;
    pnlStatusColor: TPanel;
    btnToggle: TButton;
    lblHint: TLabel;
    procedure FormCreate(Sender: TObject);
  private
    FCurrentStatus: THyperVStatus;
    procedure UpdateStatusUI(AStatus: THyperVStatus);
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

{ TMainForm }

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FCurrentStatus := GetHyperVStatus;
  UpdateStatusUI(FCurrentStatus);
end;

procedure TMainForm.UpdateStatusUI(AStatus: THyperVStatus);
begin
  case AStatus of
    hvsOn:
    begin
      lblStatusValue.Caption := 'Hyper-V 켜짐';
      lblStatusValue.Font.Color := clGreen;
      pnlStatusColor.Color := clGreen;
      btnToggle.Caption := 'Hyper-V 끄기';
      btnToggle.Enabled := True;
    end;

    hvsOff:
    begin
      lblStatusValue.Caption := 'Hyper-V 꺼짐';
      lblStatusValue.Font.Color := clRed;
      pnlStatusColor.Color := clRed;
      btnToggle.Caption := 'Hyper-V 켜기';
      btnToggle.Enabled := True;
    end;

    hvsUnknown:
    begin
      lblStatusValue.Caption := '감지 불가';
      lblStatusValue.Font.Color := clOlive;
      pnlStatusColor.Color := clOlive;
      btnToggle.Caption := '상태 확인 불가';
      btnToggle.Enabled := False;
    end;
  end;
end;

end.
