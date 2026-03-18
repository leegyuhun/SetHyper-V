unit HyperVControl;
{
  HyperVControl.pas
  Hyper-V 상태 감지 유닛.

  bcdedit.exe /enum {current} 의 stdout 을 Anonymous Pipe + CreateProcess 로
  캡처한 뒤, 줄 단위 TStringList 파싱으로 hypervisorlaunchtype 항목 값을 읽어
  THyperVStatus 열거형으로 반환한다.

  주요 함수:
    GetHyperVStatus  - Hyper-V 현재 활성화 상태 반환
    RunCommandAndGetOutput - 커맨드라인 실행 후 stdout 반환
    ParseBcdeditValue      - bcdedit 출력에서 특정 키의 값 추출
}

interface

type
  THyperVStatus = (
    hvsOn,       // hypervisorlaunchtype = Auto
    hvsOff,      // hypervisorlaunchtype = Off
    hvsUnknown   // 항목 미존재(Home 에디션) 또는 명령 실패
  );

function GetHyperVStatus: THyperVStatus;
function RunCommandAndGetOutput(const ACommand: string): string;
function ParseBcdeditValue(const AOutput, AKey: string): string;

implementation

uses
  Winapi.Windows, System.SysUtils, System.Classes;

{ ---------------------------------------------------------------------------
  RunCommandAndGetOutput
  지정한 커맨드라인을 CreateProcess 로 실행하고 stdout/stderr 를
  Anonymous Pipe 를 통해 읽어 반환한다.

  Anonymous Pipe 주의사항:
  - hWritePipe 를 부모 측에서 반드시 닫아야 ReadFile 이 파이프 끝(EOF)을
    인식하고 블로킹에서 빠져나온다.
  - 읽기 핸들(hReadPipe)은 자식 프로세스가 상속하지 않도록
    SetHandleInformation 으로 HANDLE_FLAG_INHERIT 를 해제한다.
--------------------------------------------------------------------------- }
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
  hReadPipe  := INVALID_HANDLE_VALUE;
  hWritePipe := INVALID_HANDLE_VALUE;

  // 보안 속성: 핸들 상속 허용
  SA.nLength              := SizeOf(TSecurityAttributes);
  SA.bInheritHandle       := True;
  SA.lpSecurityDescriptor := nil;

  if not CreatePipe(hReadPipe, hWritePipe, @SA, 0) then
    Exit;

  try
    // 읽기 핸들은 부모 전용 - 자식에게 상속되지 않도록 설정
    SetHandleInformation(hReadPipe, HANDLE_FLAG_INHERIT, 0);

    ZeroMemory(@SI, SizeOf(SI));
    SI.cb          := SizeOf(SI);
    SI.dwFlags     := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
    SI.hStdOutput  := hWritePipe;
    SI.hStdError   := hWritePipe;
    SI.wShowWindow := SW_HIDE;

    ZeroMemory(@PI, SizeOf(PI));

    CmdLine := ACommand;
    UniqueString(CmdLine);  // PChar 로 전달 전 고유 버퍼 확보

    if CreateProcess(
      nil,           // lpApplicationName (사용 안 함)
      PChar(CmdLine),
      nil, nil,
      True,          // bInheritHandles - 파이프 핸들 상속
      CREATE_NO_WINDOW,
      nil, nil,
      SI, PI
    ) then
    begin
      // 부모 측 쓰기 핸들을 닫아야 ReadFile 이 EOF 를 인식함
      CloseHandle(hWritePipe);
      hWritePipe := INVALID_HANDLE_VALUE;

      // 자식 프로세스 종료 대기 (최대 5초)
      WaitForSingleObject(PI.hProcess, 5000);

      // stdout 읽기
      while ReadFile(hReadPipe, Buffer[0], SizeOf(Buffer) - 1, BytesRead, nil)
            and (BytesRead > 0) do
      begin
        Buffer[BytesRead] := #0;
        Result := Result + string(AnsiString(Buffer));
      end;

      CloseHandle(PI.hProcess);
      CloseHandle(PI.hThread);
    end;
  finally
    if hReadPipe <> INVALID_HANDLE_VALUE then
      CloseHandle(hReadPipe);
    if hWritePipe <> INVALID_HANDLE_VALUE then
      CloseHandle(hWritePipe);
  end;
end;

{ ---------------------------------------------------------------------------
  ParseBcdeditValue
  bcdedit 출력 문자열에서 AKey 에 해당하는 값을 추출한다.

  bcdedit 출력 예:
    Windows Boot Loader
    -------------------
    identifier              {current}
    device                  partition=C:
    hypervisorlaunchtype    Auto

  - 줄 단위 TStringList 로 분리
  - 각 줄을 Trim + LowerCase 후 AKey 로 StartsWith 확인
  - 일치 시 첫 번째 공백 뒤를 Trim 하여 값 반환
  - 이 방식은 키-값 사이 공백 개수와 무관하게 동작한다.
--------------------------------------------------------------------------- }
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
        Line     := Trim(Lines[I]);
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

{ ---------------------------------------------------------------------------
  GetHyperVStatus
  bcdedit /enum {current} 를 실행해 hypervisorlaunchtype 값을 읽고
  THyperVStatus 열거형으로 반환한다.

  반환값:
    hvsOn      - hypervisorlaunchtype = auto  (Hyper-V 활성화)
    hvsOff     - hypervisorlaunchtype = off   (Hyper-V 비활성화)
    hvsUnknown - 항목 없음(Home 에디션) 또는 명령 실행 실패
--------------------------------------------------------------------------- }
function GetHyperVStatus: THyperVStatus;
var
  Output, Value: string;
  BcdeditPath: string;
begin
  Result := hvsUnknown;

  // %SystemRoot% 확장으로 bcdedit.exe 절대 경로 구성
  BcdeditPath := ExpandEnvironmentStrings('%SystemRoot%') +
                 '\System32\bcdedit.exe';

  Output := RunCommandAndGetOutput(BcdeditPath + ' /enum {current}');

  if Output = '' then
    Exit;  // 명령 실행 실패 또는 타임아웃

  Value := ParseBcdeditValue(Output, 'hypervisorlaunchtype');

  if Value = '' then
    Result := hvsUnknown       // 항목 미존재 = 미지원 OS (Windows Home 등)
  else if Value = 'auto' then
    Result := hvsOn
  else if Value = 'off' then
    Result := hvsOff;
  // 그 외 알 수 없는 값 -> hvsUnknown 유지
end;

end.
