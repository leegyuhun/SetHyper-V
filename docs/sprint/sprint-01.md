# Sprint 1: 프로젝트 뼈대 및 Hyper-V 상태 감지 구현 계획

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Delphi VCL 프로젝트를 생성하고, 앱 실행 즉시 Hyper-V 현재 상태를 색상과 텍스트로 표시하는 단일 폼을 완성한다.

**Architecture:** `HyperVControl.pas` 유닛이 `bcdedit /enum {current}` stdout을 파싱하여 `THyperVStatus` 열거형을 반환하고, `MainForm.pas`가 `FormCreate` 이벤트에서 이를 호출해 UI를 갱신한다. `AdminHelper.pas`는 권한 확인 유틸리티를 제공하며 Phase 2에서 실제 호출된다.

**Tech Stack:** Delphi (RAD Studio / Lazarus), VCL Forms, Windows API (`CreateProcess`, Anonymous Pipe, `CheckTokenMembership`), `bcdedit.exe` (Windows 내장)

---

## 스프린트 개요

| 항목 | 내용 |
|------|------|
| 스프린트 번호 | Sprint 1 |
| 기간 | 2026-03-20 ~ 2026-03-26 (1주) |
| ROADMAP Phase | Phase 1: 프로젝트 뼈대 및 상태 감지 |
| 우선순위 | Must Have |
| 의존성 | 없음 (첫 스프린트) |
| 다음 스프린트 의존 | Sprint 2 (토글 및 재부팅) |

---

## 구현 범위

### 포함 항목
- Delphi VCL 프로젝트 파일 초기 구성 (`SetHyperV.dpr`, `SetHyperV.dproj`)
- 메인 폼 UI 레이아웃 (`MainForm.pas` / `MainForm.dfm`)
- Hyper-V 상태 감지 로직 (`HyperVControl.pas`)
- 관리자 권한 확인/상승 유틸리티 함수 (`AdminHelper.pas`) - 구현까지만, 호출은 Sprint 2
- 폼과 로직 통합 (`FormCreate`에서 상태 감지 후 UI 반영)

### 제외 항목
- 토글 버튼 실제 동작 (bcdedit /set 실행) - Sprint 2
- UAC 권한 상승 연동 - Sprint 2
- 재부팅 안내 다이얼로그 - Sprint 2
- 고DPI 세부 대응 - Sprint 3
- 매니페스트 `requireAdministrator` 설정 - Sprint 2 ([2-2]에서 처리)
- 단일 인스턴스 Mutex - Sprint 3

---

## 작업 분해 (Task Breakdown)

### Task 1: Delphi VCL 프로젝트 생성 및 디렉토리 구조 설정

**예상 소요 시간:** 0.5일 (4시간)
**복잡도:** 낮음
**의존성:** 없음

**Files:**
- Create: `src/SetHyperV.dpr`
- Create: `src/SetHyperV.dproj`
- Create: `src/MainForm.pas`
- Create: `src/MainForm.dfm`

**Step 1: RAD Studio에서 새 VCL Forms Application 생성**

File > New > VCL Forms Application 선택.
프로젝트 저장 경로를 `src/` 디렉토리로 지정.
프로젝트 이름: `SetHyperV`.

**Step 2: 생성된 파일 확인**

```
src/
├── SetHyperV.dpr
├── SetHyperV.dproj
├── MainForm.pas
└── MainForm.dfm
```

**Step 3: `SetHyperV.dpr` 기본 구조 확인**

```pascal
program SetHyperV;

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
```

**Step 4: 컴파일 확인 (Ctrl+F9)**

RAD Studio에서 빌드 실행. 오류 없이 빈 폼이 실행되어야 함.

**Step 5: 커밋**

```bash
git add src/SetHyperV.dpr src/SetHyperV.dproj src/MainForm.pas src/MainForm.dfm
git commit -m "feat: initialize Delphi VCL project structure"
```

---

### Task 2: 메인 폼 UI 구성

**예상 소요 시간:** 1일 (8시간)
**복잡도:** 낮음
**의존성:** Task 1 완료

**Files:**
- Modify: `src/MainForm.dfm`
- Modify: `src/MainForm.pas`

**Step 1: 폼 기본 속성 설정 (`MainForm.dfm`)**

RAD Studio Object Inspector에서 다음 속성을 설정하거나 `MainForm.dfm` 텍스트를 직접 편집:

```
object MainForm: TMainForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Windows Hyper-V 관리'
  ClientHeight = 170
  ClientWidth = 380
  Color = clBtnFace
  Font.Charset = HANGEUL_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Malgun Gothic'
  Font.Style = []
  Position = poScreenCenter
end
```

**Step 2: 상태 레이블 배치**

폼에 `TLabel` 두 개 추가:

```
# lblStatusCaption - "현재 상태:" 고정 텍스트
object lblStatusCaption: TLabel
  Left = 24
  Top = 24
  Width = 70
  Height = 18
  Caption = '현재 상태:'
  Font.Height = -13
end

# lblStatusValue - 동적으로 변경될 상태값 텍스트
object lblStatusValue: TLabel
  Left = 100
  Top = 24
  Width = 120
  Height = 18
  Caption = '확인 중...'
  Font.Height = -13
  Font.Style = [fsBold]
end
```

**Step 3: 상태 색상 패널 배치**

```
object pnlStatusColor: TPanel
  Left = 24
  Top = 52
  Width = 332
  Height = 32
  BevelOuter = bvNone
  Color = clOlive
  Caption = ''
end
```

**Step 4: 토글 버튼 배치**

```
object btnToggle: TButton
  Left = 115
  Top = 100
  Width = 150
  Height = 35
  Caption = '확인 중...'
  Enabled = False
  Font.Height = -14
  Font.Style = [fsBold]
  TabOrder = 0
end
```

**Step 5: 안내 문구 레이블 배치**

```
object lblHint: TLabel
  Left = 24
  Top = 148
  Width = 332
  Height = 16
  Caption = '* 변경 후 재부팅이 필요합니다.'
  Font.Color = clGrayText
  Font.Height = -11
end
```

**Step 6: `MainForm.pas`에 컴포넌트 선언 추가**

```pascal
unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TMainForm = class(TForm)
    lblStatusCaption: TLabel;
    lblStatusValue: TLabel;
    pnlStatusColor: TPanel;
    btnToggle: TButton;
    lblHint: TLabel;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

end.
```

**Step 7: 컴파일 및 폼 외관 확인**

빌드 후 실행. 폼 크기 380x200, 레이블, 패널, 버튼이 배치된 화면이 표시되어야 함.

**Step 8: 커밋**

```bash
git add src/MainForm.pas src/MainForm.dfm
git commit -m "feat: add main form UI layout with status label, color panel, toggle button"
```

---

### Task 3: Hyper-V 상태 감지 로직 구현 (`HyperVControl.pas`)

**예상 소요 시간:** 1.5일 (12시간)
**복잡도:** 중간
**의존성:** Task 1 완료 (Task 2와 병렬 진행 가능)

**Files:**
- Create: `src/HyperVControl.pas`
- Modify: `src/SetHyperV.dproj` (유닛 추가)

**Step 1: `HyperVControl.pas` 유닛 파일 생성**

File > New > Unit 선택 후 `src/HyperVControl.pas`로 저장.

**Step 2: 열거형 타입 및 함수 시그니처 선언**

```pascal
unit HyperVControl;

interface

type
  THyperVStatus = (hvsOn, hvsOff, hvsUnknown);

function GetHyperVStatus: THyperVStatus;
function RunCommandAndGetOutput(const ACommand: string): string;

implementation

uses
  Winapi.Windows, System.SysUtils;
```

`THyperVStatus`의 세 값:
- `hvsOn`: `bcdedit` 출력에서 `hypervisorlaunchtype  Auto` 확인
- `hvsOff`: `bcdedit` 출력에서 `hypervisorlaunchtype  Off` 확인
- `hvsUnknown`: 명령 실패 또는 항목 미존재 (Home 에디션 등)

**Step 3: `RunCommandAndGetOutput` 함수 구현 (Anonymous Pipe 방식)**

이 함수는 지정한 커맨드라인을 실행하고 stdout을 문자열로 반환한다. `CreateProcess` + Anonymous Pipe 패턴을 사용한다.

```pascal
function RunCommandAndGetOutput(const ACommand: string): string;
var
  SA: TSecurityAttributes;
  hReadPipe, hWritePipe: THandle;
  SI: TStartupInfo;
  PI: TProcessInformation;
  Buffer: array[0..4095] of AnsiChar;
  BytesRead: DWORD;
  CmdLine: string;
begin
  Result := '';

  // 파이프 생성: 자식 프로세스 stdout -> 부모 읽기
  SA.nLength := SizeOf(TSecurityAttributes);
  SA.bInheritHandle := True;
  SA.lpSecurityDescriptor := nil;

  if not CreatePipe(hReadPipe, hWritePipe, @SA, 0) then
    Exit;

  try
    // 읽기 핸들은 상속되지 않도록 설정 (자식에게 불필요)
    SetHandleInformation(hReadPipe, HANDLE_FLAG_INHERIT, 0);

    ZeroMemory(@SI, SizeOf(SI));
    SI.cb := SizeOf(SI);
    SI.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
    SI.hStdOutput := hWritePipe;
    SI.hStdError  := hWritePipe;
    SI.wShowWindow := SW_HIDE;

    ZeroMemory(@PI, SizeOf(PI));

    CmdLine := ACommand;
    UniqueString(CmdLine);

    if CreateProcess(
      nil,
      PChar(CmdLine),
      nil, nil,
      True,                      // bInheritHandles
      CREATE_NO_WINDOW,
      nil, nil,
      SI, PI
    ) then
    begin
      // 자식이 파이프 쓰기 핸들을 가지고 있으므로 부모 측 쓰기 핸들 닫아야
      // 읽기가 블로킹되지 않음
      CloseHandle(hWritePipe);
      hWritePipe := INVALID_HANDLE_VALUE;

      // 자식 종료 대기 (최대 5초)
      WaitForSingleObject(PI.hProcess, 5000);

      // stdout 읽기
      while ReadFile(hReadPipe, Buffer, SizeOf(Buffer) - 1, BytesRead, nil)
            and (BytesRead > 0) do
      begin
        Buffer[BytesRead] := #0;
        Result := Result + string(AnsiString(Buffer));
      end;

      CloseHandle(PI.hProcess);
      CloseHandle(PI.hThread);
    end;
  finally
    CloseHandle(hReadPipe);
    if hWritePipe <> INVALID_HANDLE_VALUE then
      CloseHandle(hWritePipe);
  end;
end;
```

**Step 4: `GetHyperVStatus` 함수 구현**

```pascal
function GetHyperVStatus: THyperVStatus;
var
  Output: string;
  LowerOutput: string;
begin
  Result := hvsUnknown;

  // bcdedit는 관리자 권한 없이도 읽기(/enum) 가능
  Output := RunCommandAndGetOutput(
    '%SystemRoot%\System32\bcdedit.exe /enum {current}'
  );

  // ExpandEnvironmentStrings를 통해 %SystemRoot% 확장
  // 위 방식 대신 아래처럼 직접 경로 확장 사용:
  Output := RunCommandAndGetOutput(
    ExpandEnvironmentStrings('%SystemRoot%') +
    '\System32\bcdedit.exe /enum {current}'
  );

  if Output = '' then
    Exit; // 명령 실행 실패

  LowerOutput := LowerCase(Output);

  // "hypervisorlaunchtype" 키가 아예 없으면 Hyper-V 미지원 (Home 에디션)
  if Pos('hypervisorlaunchtype', LowerOutput) = 0 then
  begin
    Result := hvsUnknown;
    Exit;
  end;

  // 값 파싱: "hypervisorlaunchtype    auto" 또는 "hypervisorlaunchtype    off"
  // bcdedit 출력에서 키 이름은 소문자 영문 고정
  if Pos('hypervisorlaunchtype    auto', LowerOutput) > 0 then
    Result := hvsOn
  else if Pos('hypervisorlaunchtype    off', LowerOutput) > 0 then
    Result := hvsOff;
  // 그 외 값이면 hvsUnknown 유지
end;
```

> **주의:** `bcdedit` 출력에서 키와 값 사이의 공백 개수는 정렬 패딩으로 인해 여러 개일 수 있다. 위 패턴은 4개의 공백을 기준으로 하지만, 실제 환경에서 다를 수 있다. 더 안전한 파싱:

```pascal
// 개선된 파싱: 줄 단위로 분리 후 키 이름으로 해당 줄 찾기
function ParseBcdeditValue(const AOutput, AKey: string): string;
var
  Lines: TStringList;
  I: Integer;
  Line, LKey, LLine: string;
  SpacePos: Integer;
begin
  Result := '';
  Lines := TStringList.Create;
  try
    Lines.Text := AOutput;
    LKey := LowerCase(AKey);
    for I := 0 to Lines.Count - 1 do
    begin
      LLine := LowerCase(Trim(Lines[I]));
      if LLine.StartsWith(LKey) then
      begin
        // 공백 이후 값 추출
        Line := Trim(Lines[I]);
        SpacePos := Pos(' ', Line);
        if SpacePos > 0 then
          Result := LowerCase(Trim(Copy(Line, SpacePos + 1, MaxInt)));
        Break;
      end;
    end;
  finally
    Lines.Free;
  end;
end;
```

개선된 `GetHyperVStatus`:

```pascal
function GetHyperVStatus: THyperVStatus;
var
  Output, Value: string;
begin
  Result := hvsUnknown;

  Output := RunCommandAndGetOutput(
    ExpandEnvironmentStrings('%SystemRoot%') +
    '\System32\bcdedit.exe /enum {current}'
  );

  if Output = '' then
    Exit;

  Value := ParseBcdeditValue(Output, 'hypervisorlaunchtype');

  if Value = '' then
    Result := hvsUnknown  // 항목 미존재 = 미지원 OS
  else if Value = 'auto' then
    Result := hvsOn
  else if Value = 'off' then
    Result := hvsOff;
  // 그 외 알 수 없는 값 -> hvsUnknown
end;
```

**Step 5: `HyperVControl.pas` `uses` 절에 `TStringList` 관련 유닛 추가**

```pascal
uses
  Winapi.Windows, System.SysUtils, System.Classes;
```

**Step 6: 컴파일 확인**

`src/SetHyperV.dproj`의 `uses` 절에 `HyperVControl` 추가 후 빌드 (Ctrl+F9).
컴파일 오류 없음을 확인.

**Step 7: 수동 기능 테스트**

PowerShell에서 직접 확인:
```powershell
bcdedit /enum '{current}' | Select-String 'hypervisorlaunchtype'
```
출력 예: `hypervisorlaunchtype    Auto` 또는 `hypervisorlaunchtype    Off`

위 출력값이 `GetHyperVStatus` 파싱 로직과 일치하는지 대조 확인.

**Step 8: 커밋**

```bash
git add src/HyperVControl.pas src/SetHyperV.dproj
git commit -m "feat: implement HyperVControl unit with bcdedit stdout parsing"
```

---

### Task 4: 관리자 권한 확인 유틸리티 구현 (`AdminHelper.pas`)

**예상 소요 시간:** 0.5일 (4시간)
**복잡도:** 낮음
**의존성:** Task 1 완료

**Files:**
- Create: `src/AdminHelper.pas`
- Modify: `src/SetHyperV.dproj` (유닛 추가)

**Step 1: `AdminHelper.pas` 유닛 파일 생성**

```pascal
unit AdminHelper;

interface

function IsRunAsAdmin: Boolean;
procedure RunAsAdmin(const ExePath: string);

implementation

uses
  Winapi.Windows, Winapi.ShellAPI, System.SysUtils;
```

**Step 2: `IsRunAsAdmin` 함수 구현**

Windows API `CheckTokenMembership`을 사용해 현재 프로세스가 Administrators 그룹으로 실행 중인지 확인한다.

```pascal
function IsRunAsAdmin: Boolean;
var
  hToken: THandle;
  ptgGroups: PTOKEN_GROUPS;
  dwInfoBufferSize: DWORD;
  psidAdministrators: PSID;
  siaNtAuthority: SID_IDENTIFIER_AUTHORITY;
  I: Integer;
  bSuccess: Boolean;
begin
  Result := False;
  hToken := 0;

  if not OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, hToken) then
    Exit;

  try
    // 필요한 버퍼 크기 확인
    GetTokenInformation(hToken, TokenGroups, nil, 0, dwInfoBufferSize);
    if GetLastError <> ERROR_INSUFFICIENT_BUFFER then
      Exit;

    ptgGroups := AllocMem(dwInfoBufferSize);
    try
      if not GetTokenInformation(hToken, TokenGroups,
                                 ptgGroups, dwInfoBufferSize, dwInfoBufferSize) then
        Exit;

      // Administrators SID 생성
      siaNtAuthority.Value[0] := 0;
      siaNtAuthority.Value[1] := 0;
      siaNtAuthority.Value[2] := 0;
      siaNtAuthority.Value[3] := 0;
      siaNtAuthority.Value[4] := 0;
      siaNtAuthority.Value[5] := 5; // SECURITY_NT_AUTHORITY

      if not AllocateAndInitializeSid(siaNtAuthority, 2,
        SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_ADMINS,
        0, 0, 0, 0, 0, 0, psidAdministrators) then
        Exit;

      try
        bSuccess := False;
        for I := 0 to ptgGroups^.GroupCount - 1 do
        begin
          if EqualSid(psidAdministrators,
                      ptgGroups^.Groups[I].Sid) then
          begin
            bSuccess := True;
            Break;
          end;
        end;
        Result := bSuccess;
      finally
        FreeSid(psidAdministrators);
      end;
    finally
      FreeMem(ptgGroups);
    end;
  finally
    CloseHandle(hToken);
  end;
end;
```

> **대안 (간단한 방식):** `IsUserAnAdmin` Windows API 함수 사용. 단, 이 함수는 deprecated 표시가 있지만 실용적이다.

```pascal
// 간단한 대안 구현
function IsRunAsAdmin: Boolean;
begin
  // IsUserAnAdmin은 Shell32.dll에 있으므로 동적 로딩
  // 또는 CheckTokenMembership 사용
  Result := IsUserAnAdmin;  // Winapi.ShellAPI에 선언됨
end;
```

권장: `CheckTokenMembership` 방식 사용 (더 명확하고 UAC 가상화 환경에서도 정확).

**Step 3: `RunAsAdmin` 프로시저 구현**

```pascal
procedure RunAsAdmin(const ExePath: string);
var
  SEI: TShellExecuteInfo;
begin
  ZeroMemory(@SEI, SizeOf(SEI));
  SEI.cbSize := SizeOf(TShellExecuteInfo);
  SEI.fMask  := SEE_MASK_DEFAULT;
  SEI.lpVerb := 'runas';
  SEI.lpFile := PChar(ExePath);
  SEI.lpParameters := nil;
  SEI.nShow  := SW_SHOWNORMAL;

  ShellExecuteEx(@SEI);
  // UAC 거부 시 ShellExecuteEx는 False를 반환하고 GetLastError = ERROR_CANCELLED
  // 호출자에서 반환값 확인 필요 시 Boolean 반환으로 시그니처 변경 가능
end;
```

**Step 4: `interface` 절 `end.` 및 `implementation` 마무리**

```pascal
end.
```

**Step 5: 컴파일 확인**

`SetHyperV.dproj`에 `AdminHelper` 유닛 추가 후 빌드. 오류 없음 확인.

**Step 6: 커밋**

```bash
git add src/AdminHelper.pas src/SetHyperV.dproj
git commit -m "feat: implement AdminHelper unit for admin rights check and UAC elevation"
```

---

### Task 5: 폼과 로직 통합 - FormCreate에서 상태 감지 후 UI 반영

**예상 소요 시간:** 0.5일 (4시간)
**복잡도:** 낮음
**의존성:** Task 2, Task 3, Task 4 완료

**Files:**
- Modify: `src/MainForm.pas`
- Modify: `src/MainForm.dfm` (이벤트 핸들러 연결)

**Step 1: `MainForm.pas`의 `uses` 절에 유닛 추가**

```pascal
uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Dialogs,
  HyperVControl,   // GetHyperVStatus, THyperVStatus
  AdminHelper;     // IsRunAsAdmin (Phase 2에서 실제 사용)
```

**Step 2: `TMainForm` 클래스에 상태 갱신 메서드 선언**

```pascal
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
```

**Step 3: `FormCreate` 이벤트 핸들러 구현**

```pascal
procedure TMainForm.FormCreate(Sender: TObject);
begin
  FCurrentStatus := GetHyperVStatus;
  UpdateStatusUI(FCurrentStatus);
end;
```

**Step 4: `UpdateStatusUI` 메서드 구현**

```pascal
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
```

**Step 5: `MainForm.dfm`에서 `FormCreate` 이벤트 연결 확인**

dfm 파일에 다음이 있어야 함:
```
OnCreate = FormCreate
```

RAD Studio에서 폼을 선택하고 Object Inspector > Events 탭 > OnCreate에 `FormCreate`를 지정.

**Step 6: 전체 빌드 및 수동 검증**

빌드 후 `SetHyperV.exe` 실행. 아래 시나리오를 수동으로 확인:

1. 폼 크기 380x200 확인
2. 레이블에 "Hyper-V 켜짐" 또는 "Hyper-V 꺼짐"이 1초 이내 표시
3. 초록(ON) 또는 빨강(OFF) 패널 색상 확인
4. 버튼 텍스트가 "Hyper-V 끄기" 또는 "Hyper-V 켜기"로 표시
5. 일반 사용자 권한으로 실행해도 상태 조회가 정상 동작 (bcdedit 읽기는 권한 불필요)

PowerShell 교차 검증:
```powershell
bcdedit /enum '{current}' | Select-String 'hypervisorlaunchtype'
```
앱 표시 상태와 PowerShell 출력이 일치하는지 확인.

**Step 7: 커밋**

```bash
git add src/MainForm.pas src/MainForm.dfm
git commit -m "feat: integrate HyperVControl into MainForm, display Hyper-V status on startup"
```

---

### Task 6: 빌드 검증 스크립트 작성 및 최종 확인

**예상 소요 시간:** 0.5일 (포함: 디렉토리 구조 정리)
**복잡도:** 낮음
**의존성:** Task 5 완료

**Step 1: Release 모드 빌드 확인**

RAD Studio에서 Build Configuration을 `Release`로 전환 (Ctrl+Shift+F9 또는 Build > Build SetHyperV).

또는 커맨드라인:
```bash
msbuild src/SetHyperV.dproj /t:Build /p:Config=Release /p:Platform=Win64
```

**Step 2: 빌드 산출물 확인**

```bash
test -f Win64/Release/SetHyperV.exe && echo "BUILD OK" || echo "BUILD FAIL"
```

**Step 3: Sprint 1 완료 기준 체크리스트 수동 검증**

- [ ] 프로젝트 컴파일 성공, 단일 EXE 생성
- [ ] EXE 실행 시 1초 이내 Hyper-V 상태 표시
- [ ] ON(초록) / OFF(빨강) / 감지불가(올리브) 세 가지 상태 구분 표시
- [ ] 관리자 권한 없이 실행해도 상태 조회 정상 동작
- [ ] 감지 불가 시 토글 버튼 비활성화

**Step 4: 최종 커밋**

```bash
git add .
git commit -m "chore: Sprint 1 complete - Hyper-V status detection UI working"
```

---

## 기술적 접근 방법 요약

| 태스크 | 핵심 기술 | 주의사항 |
|--------|-----------|----------|
| bcdedit stdout 캡처 | `CreateProcess` + Anonymous Pipe | `hWritePipe`를 부모에서 반드시 닫아야 `ReadFile`이 블로킹되지 않음 |
| bcdedit 파싱 | 줄 단위 `TStringList` + `StartsWith` | 공백 개수 의존 파싱 대신 키 이름 기반 줄 탐색 사용 |
| 관리자 권한 확인 | `CheckTokenMembership` / `IsUserAnAdmin` | Sprint 2에서 실제 호출, 이번 Sprint에서는 구현까지만 |
| UI 상태 반영 | `FormCreate` 이벤트 + `UpdateStatusUI` | 상태 감지는 동기 방식으로 충분 (bcdedit 즉시 응답) |

---

## 의존성 및 리스크

| 리스크 | 영향도 | 완화 방법 |
|--------|--------|-----------|
| `bcdedit` 출력 공백 패딩 수 환경마다 다름 | 중 | 줄 단위 파싱 + `Trim` 후 `StartsWith` 사용 |
| Windows Home 에디션에서 `hypervisorlaunchtype` 항목 없음 | 중 | 항목 미존재 시 `hvsUnknown` 반환, UI에서 버튼 비활성화 |
| Delphi/RAD Studio 환경 미설치 | 높 | Community Edition(무료) 사용 가능. 없을 경우 Lazarus/FPC도 VCL 일부 호환 |
| `bcdedit` PATH 미등록 | 낮 | `ExpandEnvironmentStrings('%SystemRoot%\System32\bcdedit.exe')` 절대 경로 사용 |

---

## 완료 기준 (Definition of Done)

Sprint 1은 아래 모든 항목이 충족될 때 완료로 간주한다:

- [ ] `src/SetHyperV.dpr`, `src/SetHyperV.dproj` 생성 및 컴파일 성공
- [ ] `src/HyperVControl.pas` - `GetHyperVStatus: THyperVStatus` 함수 동작
- [ ] `src/AdminHelper.pas` - `IsRunAsAdmin: Boolean`, `RunAsAdmin` 함수 구현 완료
- [ ] `src/MainForm.pas` / `MainForm.dfm` - UI 레이아웃 구성 완료
- [ ] `FormCreate`에서 `GetHyperVStatus` 호출 후 UI 반영
- [ ] EXE 실행 시 1초 이내 상태 표시 (ON 초록 / OFF 빨강 / 감지불가 올리브)
- [ ] 일반 사용자 권한으로 실행해도 상태 조회 정상 동작
- [ ] 감지 불가 시 토글 버튼 `Enabled = False`
- [ ] Release 모드 빌드 성공 (`Win64/Release/SetHyperV.exe` 생성)

---

## 예상 산출물

Sprint 1 완료 시 다음 파일들이 생성된다:

```
SetHyper-V/
├── src/
│   ├── SetHyperV.dpr          # 프로젝트 메인 파일
│   ├── SetHyperV.dproj        # Delphi 프로젝트 설정
│   ├── MainForm.pas           # 메인 폼 로직 (FormCreate + UpdateStatusUI)
│   ├── MainForm.dfm           # 메인 폼 디자인 (레이아웃 정의)
│   ├── HyperVControl.pas      # Hyper-V 상태 감지 로직
│   └── AdminHelper.pas        # 관리자 권한 확인/상승 유틸리티
└── Win64/Release/
    └── SetHyperV.exe          # 단일 포터블 EXE (Sprint 1 산출물)
```

---

## 다음 스프린트 예고 (Sprint 2 예정 작업)

Sprint 1 완료 후 Sprint 2(2026-03-27 ~ 2026-04-02)에서 아래를 구현한다:

- `btnToggle` 클릭 이벤트 - `bcdedit /set` 실행
- UAC 매니페스트 (`requireAdministrator`) 연동
- 재부팅 안내 다이얼로그 (`TaskDialog`)
- 오류 처리 (bcdedit 실패, UAC 거부, 미지원 OS)
