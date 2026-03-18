# Sprint 1 코드 리뷰 보고서

**리뷰 일시:** 2026-03-19
**리뷰 대상 브랜치:** sprint-01
**리뷰어:** Claude Sonnet 4.6 (자동 리뷰)

---

## 리뷰 요약

| 심각도 | 건수 |
|--------|------|
| Critical | 0 |
| High | 0 |
| Medium | 2 |
| Low | 3 |
| Info | 2 |

전반적으로 코드 품질이 우수합니다. Windows API 사용 패턴이 정확하고 리소스 관리가 체계적으로 되어 있습니다.

---

## Medium 이슈

### [M-1] HyperVControl.pas - WaitForSingleObject 순서 문제

**파일:** `src/HyperVControl.pas`, RunCommandAndGetOutput 함수

**현상:**
```pascal
WaitForSingleObject(PI.hProcess, 5000);  // 먼저 종료 대기

while ReadFile(hReadPipe, ...) do         // 이후 stdout 읽기
```

**문제점:** WaitForSingleObject로 자식 프로세스 종료를 먼저 기다린 후 ReadFile을 실행하는 구조입니다. 자식이 파이프 버퍼(기본 4KB)를 초과하는 stdout을 생성하면 파이프 버퍼가 가득 차서 자식 프로세스가 블로킹되고, WaitForSingleObject는 5초 후 타임아웃될 수 있습니다.

**현실적 영향:** `bcdedit /enum {current}` 출력은 통상 1-2KB 이내로 파이프 기본 버퍼(4KB)를 초과하지 않습니다. Sprint 1 범위에서는 실질적 문제가 발생하지 않습니다.

**권장 개선 방향 (Sprint 3 또는 기술 부채):** ReadFile 루프를 먼저 실행하여 파이프를 비우면서 자식 종료를 기다리는 방식으로 변경. 또는 `PeekNamedPipe`로 비동기 확인.

---

### [M-2] AdminHelper.pas - IsRunAsAdmin의 UAC elevation token 미처리

**파일:** `src/AdminHelper.pas`, IsRunAsAdmin 함수

**현상:** TokenGroups를 순회하여 Administrators SID를 찾는 방식입니다.

**문제점:** UAC가 활성화된 Windows Vista 이상에서 관리자 계정이 표준 권한으로 실행 중일 때(filtered token), TokenGroups에 Administrators SID가 있더라도 해당 그룹의 `SE_GROUP_ENABLED` 속성을 확인하지 않습니다. 그룹이 존재해도 disabled 상태면 실제 관리자 권한이 없는 상태입니다.

**현실적 영향:** Sprint 1에서는 IsRunAsAdmin을 실제로 호출하지 않으므로 영향 없음. Sprint 2에서 실제 호출 시 문제가 될 수 있습니다.

**권장 개선 방향 (Sprint 2 진입 전):** 그룹 속성 `SE_GROUP_ENABLED` 플래그 확인 추가, 또는 `CheckTokenMembership` API로 대체 (더 간결하고 정확).

```pascal
// 권장: CheckTokenMembership 사용 (더 정확, 코드 간결)
function IsRunAsAdmin: Boolean;
var
  AdminSid: PSID;
  SidAuth: SID_IDENTIFIER_AUTHORITY;
begin
  Result := False;
  FillChar(SidAuth, SizeOf(SidAuth), 0);
  SidAuth.Value[5] := 5; // SECURITY_NT_AUTHORITY
  if AllocateAndInitializeSid(SidAuth, 2, 32, 544, 0,0,0,0,0,0, AdminSid) then
  try
    CheckTokenMembership(0, AdminSid, Result);
  finally
    FreeSid(AdminSid);
  end;
end;
```

---

## Low 이슈

### [L-1] HyperVControl.pas - ParseBcdeditValue의 부분 일치 위험

**파일:** `src/HyperVControl.pas`, ParseBcdeditValue 함수

**현상:** `LLine.StartsWith(LKey)` 로 줄을 탐색합니다.

**잠재적 문제:** 만약 bcdedit 출력에 `hypervisorlaunchtype` 보다 앞에 위치하는 다른 키가 해당 문자열로 시작하면 오탐될 수 있습니다. 실제 bcdedit 출력에서 `hypervisorlaunchtype`으로 시작하는 다른 키가 존재하지 않으므로 실용적 문제는 없습니다.

**권장:** `LLine.StartsWith(LKey + ' ')` 또는 `LLine.StartsWith(LKey + #9)` 로 키 뒤에 공백/탭이 오는 경우만 매칭하도록 강화 가능.

---

### [L-2] HyperVControl.pas - RunCommandAndGetOutput의 반환형 공개 여부

**파일:** `src/HyperVControl.pas`, interface 절

`RunCommandAndGetOutput`과 `ParseBcdeditValue`가 interface에 공개되어 있습니다. 이 함수들은 내부 구현 세부사항으로 외부에 노출할 필요가 없습니다.

**권장:** `implementation` 절로 이동하고 interface에서는 `GetHyperVStatus`만 공개. 추후 단위 테스트가 필요한 경우 별도 테스트 유닛에서 접근하는 방식 고려.

---

### [L-3] build.ps1 - BDS 경로 탐색이 CodeGear.Delphi.Targets 파일에 의존

**파일:** `build.ps1`

BDS 자동 감지 시 `bin\CodeGear.Delphi.Targets` 파일 존재 여부로 확인합니다. 일부 버전에서는 파일명이 다를 수 있습니다. 단순히 디렉토리 존재 여부로 확인하는 것이 더 안전합니다.

---

## Info (개선 참고)

### [I-1] HyperVControl.pas - Buffer 크기 4095 바이트 고정

단일 ReadFile 호출 버퍼가 4095 바이트로 고정되어 있습니다. 루프로 전체 출력을 읽으므로 실제로는 문제가 없습니다. 다만 명시적으로 `4 * 1024 - 1` 등 상수로 의미를 명확히 하면 가독성이 향상됩니다.

---

### [I-2] SetHyperV.dpr - uses 절에 HyperVControl, AdminHelper 불필요 포함

`SetHyperV.dpr`의 `uses` 절에 `HyperVControl`과 `AdminHelper`가 포함되어 있습니다. 이 유닛들은 `MainForm.pas`에서 이미 `uses`하므로 `.dpr`에 중복 선언할 필요가 없습니다. 컴파일에는 영향 없지만 정리 가능합니다.

---

## 긍정적 사항

- **파이프 핸들 관리 정확:** `hWritePipe`를 부모 측에서 `CreateProcess` 직후 닫아 `ReadFile`이 EOF를 정상 인식하도록 처리. 이 부분이 가장 흔히 실수하는 지점인데 정확하게 구현됨.
- **INVALID_HANDLE_VALUE 초기화:** `hReadPipe`, `hWritePipe` 모두 `INVALID_HANDLE_VALUE`로 초기화하여 이중 닫기 방지.
- **bcdedit 절대 경로:** `ExpandEnvironmentStrings('%SystemRoot%')` 사용으로 PATH 의존성 제거.
- **줄 단위 파싱:** 공백 개수에 의존하지 않는 `TStringList + StartsWith + Trim` 패턴으로 견고한 파싱.
- **try/finally 일관성:** `RunCommandAndGetOutput` 2중, `IsRunAsAdmin` 3중 try/finally로 리소스 누수 없음.
- **주석 품질:** 각 함수마다 목적, 주의사항, 호출 시나리오가 잘 문서화되어 있음.
- **UI 상태 분리:** `UpdateStatusUI`를 별도 메서드로 분리하여 Sprint 2에서 재사용 가능한 구조.

---

## Sprint 2 진입 전 권장 조치

1. **[M-2] 필수:** `IsRunAsAdmin`에서 `SE_GROUP_ENABLED` 플래그 확인 추가 또는 `CheckTokenMembership`으로 대체.
2. **[M-1] 선택적:** `WaitForSingleObject` 이전에 `ReadFile` 루프를 실행하는 방식으로 순서 변경 (안전성 향상).
3. **[L-2] 선택적:** `RunCommandAndGetOutput`, `ParseBcdeditValue`를 `implementation` 전용으로 이동.
