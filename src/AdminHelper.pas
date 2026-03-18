unit AdminHelper;
{
  AdminHelper.pas
  관리자 권한 확인 및 UAC 권한 상승 유틸리티 유닛.

  주요 함수:
    IsRunAsAdmin  - 현재 프로세스가 관리자 권한으로 실행 중인지 확인
    RunAsAdmin    - ShellExecute 'runas' 동사로 프로그램을 관리자 권한으로 재실행

  Sprint 1: 함수 구현 완료. 실제 호출은 Sprint 2(토글 버튼 + UAC 연동)에서 수행.
}

interface

function IsRunAsAdmin: Boolean;
procedure RunAsAdmin(const ExePath: string);

implementation

uses
  Winapi.Windows, Winapi.ShellAPI, System.SysUtils;

{ ---------------------------------------------------------------------------
  IsRunAsAdmin
  현재 프로세스 토큰에서 TokenGroups 정보를 조회하여 Administrators SID 가
  포함되어 있는지 확인한다.

  CheckTokenMembership 방식 대신 직접 토큰 그룹을 순회하는 이유:
  - UAC 가상화 환경에서도 실제 그룹 멤버십을 정확히 반영
  - IsUserAnAdmin() 은 deprecated 상태이므로 사용 지양

  Administrators SID: S-1-5-32-544
  - Authority : SECURITY_NT_AUTHORITY (Value[5] = 5)
  - SubAuth[0]: SECURITY_BUILTIN_DOMAIN_RID (32)
  - SubAuth[1]: DOMAIN_ALIAS_RID_ADMINS     (544)
--------------------------------------------------------------------------- }
function IsRunAsAdmin: Boolean;
var
  hToken: THandle;
  ptgGroups: PTOKEN_GROUPS;
  dwInfoBufferSize: DWORD;
  psidAdministrators: PSID;
  siaNtAuthority: SID_IDENTIFIER_AUTHORITY;
  I: Integer;
  bFound: Boolean;
begin
  Result := False;
  hToken := 0;
  psidAdministrators := nil;
  ptgGroups := nil;

  if not OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, hToken) then
    Exit;

  try
    // 1단계: 필요한 버퍼 크기 조회
    dwInfoBufferSize := 0;
    GetTokenInformation(hToken, TokenGroups, nil, 0, dwInfoBufferSize);
    if (GetLastError <> ERROR_INSUFFICIENT_BUFFER) or (dwInfoBufferSize = 0) then
      Exit;

    // 2단계: 버퍼 할당 후 토큰 그룹 정보 획득
    ptgGroups := AllocMem(dwInfoBufferSize);
    try
      if not GetTokenInformation(hToken, TokenGroups,
                                 ptgGroups, dwInfoBufferSize,
                                 dwInfoBufferSize) then
        Exit;

      // 3단계: Administrators SID 생성
      // SECURITY_NT_AUTHORITY = {0,0,0,0,0,5}
      FillChar(siaNtAuthority, SizeOf(siaNtAuthority), 0);
      siaNtAuthority.Value[5] := 5;

      if not AllocateAndInitializeSid(
        siaNtAuthority,
        2,                            // 서브권한 개수
        SECURITY_BUILTIN_DOMAIN_RID,  // = 32
        DOMAIN_ALIAS_RID_ADMINS,      // = 544
        0, 0, 0, 0, 0, 0,
        psidAdministrators
      ) then
        Exit;

      try
        // 4단계: 토큰 그룹에서 Administrators SID 탐색
        bFound := False;
        for I := 0 to Integer(ptgGroups^.GroupCount) - 1 do
        begin
          if EqualSid(psidAdministrators,
                      ptgGroups^.Groups[I].Sid) then
          begin
            bFound := True;
            Break;
          end;
        end;
        Result := bFound;
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

{ ---------------------------------------------------------------------------
  RunAsAdmin
  ShellExecuteEx 의 'runas' 동사를 사용해 ExePath 로 지정한 실행 파일을
  관리자 권한으로 재실행한다.

  호출 시나리오 (Sprint 2):
  1. IsRunAsAdmin = False 확인
  2. RunAsAdmin(Application.ExeName) 호출 -> UAC 프롬프트 표시
  3. 사용자가 승인하면 새 프로세스가 관리자 권한으로 실행됨
  4. 현재(비관리자) 프로세스는 Application.Terminate 로 종료

  UAC 거부 시: ShellExecuteEx 가 False 를 반환하며
              GetLastError = ERROR_CANCELLED (1223).
  이 경우 별도 오류 처리 없이 조용히 실패 (사용자 의사 존중).
--------------------------------------------------------------------------- }
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
  // 반환값 무시: UAC 거부(ERROR_CANCELLED)는 사용자 선택이므로 조용히 처리
  // Sprint 2에서 호출 측이 반환값 필요 시 Boolean 으로 시그니처 변경 가능
end;

end.
