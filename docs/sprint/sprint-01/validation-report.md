# Sprint 1 검증 보고서

**검증 일시:** 2026-03-19
**검증 환경:** Windows 11 Enterprise (10.0.22621), 개발 머신 (RAD Studio 미설치)
**브랜치:** sprint-01

---

## 자동 검증 결과 요약

| 항목 | 결과 | 비고 |
|------|------|------|
| 산출물 파일 존재 확인 | PASS | 7개 파일 모두 정상 |
| HyperVControl.pas 정적 분석 | PASS | 8개 패턴 모두 확인 |
| AdminHelper.pas 정적 분석 | PASS | 8개 패턴 모두 확인 |
| MainForm.pas 정적 분석 | PASS | 8개 패턴 모두 확인 |
| MainForm.dfm 정적 분석 | PASS | 6개 속성 모두 확인 |
| msbuild 빌드 검증 | SKIP | RAD Studio 미설치 환경 - 수동 검증 필요 |
| bcdedit 교차 검증 | SKIP | 현재 환경 관리자 권한 없음 - 수동 검증 필요 |

---

## 산출물 파일 검증

모든 Sprint 1 산출물 파일이 올바른 위치에 존재합니다.

| 파일 | 크기 | 상태 |
|------|------|------|
| src/SetHyperV.dpr | 312 bytes | PASS |
| src/SetHyperV.dproj | 3,269 bytes | PASS |
| src/MainForm.pas | 1,591 bytes | PASS |
| src/MainForm.dfm | 1,926 bytes | PASS |
| src/HyperVControl.pas | 6,357 bytes | PASS |
| src/AdminHelper.pas | 4,598 bytes | PASS |
| build.ps1 | 3,733 bytes | PASS |

---

## 정적 코드 분석 결과

### HyperVControl.pas

| 검증 항목 | 결과 |
|-----------|------|
| CreatePipe 사용 (Anonymous Pipe) | PASS |
| SetHandleInformation (읽기 핸들 상속 제거) | PASS |
| WaitForSingleObject 5초 타임아웃 | PASS |
| try/finally 블록 대칭 (2개 / 2개) | PASS |
| ExpandEnvironmentStrings (bcdedit 절대 경로) | PASS |
| THyperVStatus 3가지 상태 (hvsOn / hvsOff / hvsUnknown) | PASS |
| TStringList 줄 단위 파싱 + StartsWith | PASS |
| INVALID_HANDLE_VALUE 초기화 | PASS |

### AdminHelper.pas

| 검증 항목 | 결과 |
|-----------|------|
| OpenProcessToken | PASS |
| AllocateAndInitializeSid | PASS |
| FreeSid (SID 리소스 정리) | PASS |
| FreeMem (버퍼 리소스 정리) | PASS |
| CloseHandle (토큰 핸들 정리) | PASS |
| ShellExecuteEx (runas) | PASS |
| runas verb 사용 | PASS |
| try/finally 블록 대칭 (3개 / 3개) | PASS |

### MainForm.pas

| 검증 항목 | 결과 |
|-----------|------|
| FormCreate 이벤트 핸들러 | PASS |
| GetHyperVStatus 호출 | PASS |
| UpdateStatusUI 메서드 분리 | PASS |
| case문으로 3가지 상태 처리 | PASS |
| 감지불가 시 토글 버튼 비활성화 (Enabled := False) | PASS |
| ON 상태 초록색 (clGreen) | PASS |
| OFF 상태 빨간색 (clRed) | PASS |
| 감지불가 올리브색 (clOlive) | PASS |

### MainForm.dfm

| 검증 항목 | 결과 |
|-----------|------|
| 폼 너비 380px (ClientWidth = 380) | PASS |
| 폼 높이 170px (ClientHeight = 170) | PASS |
| 고정 크기 폼 (BorderStyle = bsSingle) | PASS |
| 화면 중앙 배치 (Position = poScreenCenter) | PASS |
| OnCreate 이벤트 연결 (OnCreate = FormCreate) | PASS |
| BorderIcons 설정 ([biSystemMenu, biMinimize]) | PASS |

---

## Sprint 1 완료 기준 (Definition of Done) 검증

| 완료 기준 | 자동 검증 | 결과 |
|-----------|-----------|------|
| src/SetHyperV.dpr, src/SetHyperV.dproj 생성 | 파일 존재 확인 | PASS |
| GetHyperVStatus: THyperVStatus 함수 구현 | 정적 분석 | PASS |
| IsRunAsAdmin: Boolean, RunAsAdmin 함수 구현 | 정적 분석 | PASS |
| MainForm.pas / MainForm.dfm UI 레이아웃 | 정적 분석 | PASS |
| FormCreate에서 GetHyperVStatus 호출 후 UI 반영 | 정적 분석 | PASS |
| ON 초록 / OFF 빨강 / 감지불가 올리브 | 정적 분석 | PASS |
| EXE 실행 시 1초 이내 상태 표시 | 수동 검증 필요 | SKIP |
| 관리자 권한 없이 상태 조회 정상 동작 | 수동 검증 필요 | SKIP |
| 감지 불가 시 토글 버튼 Enabled = False | 정적 분석 | PASS |
| Release 모드 빌드 성공 (Win64/Release/SetHyperV.exe) | 수동 검증 필요 | SKIP |

**자동 검증 통과율:** 7/10 (수동 검증 필요 항목 3개 별도)

---

## 코드 리뷰 결과 요약

상세 내용: [code-review.md](code-review.md)

| 심각도 | 건수 | Sprint 2 전 조치 필요 |
|--------|------|-----------------------|
| Critical | 0 | - |
| High | 0 | - |
| Medium | 2 | [M-2] IsRunAsAdmin SE_GROUP_ENABLED 확인 필요 |
| Low | 3 | 선택적 개선 |
| Info | 2 | 참고용 |

**Sprint 2 진입 전 필수 조치:** `AdminHelper.pas`의 `IsRunAsAdmin` 함수에서 `SE_GROUP_ENABLED` 플래그 확인 추가 또는 `CheckTokenMembership` API로 대체 권장.

---

## 수동 검증 필요 항목

아래 항목은 RAD Studio가 설치된 환경에서 수동으로 검증해야 합니다.

### 빌드 검증
```powershell
# RAD Studio 설치 환경에서 실행
.\build.ps1 -Config Release -Platform Win64

# 또는 msbuild 직접 실행
msbuild src\SetHyperV.dproj /t:Build /p:Config=Release /p:Platform=Win64

# 산출물 확인
Test-Path Win64\Release\SetHyperV.exe
```

### 실행 검증 (수동)
1. 생성된 `Win64\Release\SetHyperV.exe`를 일반 사용자 권한으로 실행
2. 폼이 380x200 크기로 화면 중앙에 표시되는지 확인
3. 1초 이내에 상태 레이블이 업데이트되는지 확인
4. PowerShell 교차 검증:
   ```powershell
   bcdedit /enum '{current}' | Select-String 'hypervisorlaunchtype'
   ```
   앱 표시 상태와 PowerShell 출력이 일치하는지 확인

### bcdedit 상태 교차 검증
```powershell
# 관리자 권한 PowerShell에서 실행
bcdedit /enum '{current}' | Select-String 'hypervisorlaunchtype'
# 예상 출력: hypervisorlaunchtype    Auto  (ON 상태)
#           hypervisorlaunchtype    Off   (OFF 상태)
#           (항목 없음)                   (Home 에디션 - 감지불가)
```

---

## bcdedit 검증 불가 사유

현재 검증 실행 환경에서 `bcdedit /enum` 명령이 접근 거부됩니다. Windows 환경에 따라 `bcdedit` 읽기(/enum)도 관리자 권한을 요구하는 경우가 있습니다. 실제 애플리케이션 동작 시에는 `CreateProcess`가 동일한 권한으로 실행되므로 동일한 결과를 반환합니다.

> 참고: sprint-01.md의 기술 고려사항에는 "bcdedit 읽기는 관리자 불필요"라고 명시되어 있으나, 실제 환경에 따라 다를 수 있습니다. Release EXE 실행 시 직접 검증 권장.

---

## 원격 저장소 푸시 필요

원격 저장소(`https://github.com/leegyuhun/SetHyper-V.git`) 접근 권한 오류로 자동 푸시 및 PR 생성이 수행되지 않았습니다.

**수동으로 실행해야 하는 명령:**
```bash
# 올바른 자격증명으로 실행
git push -u origin main
git push -u origin sprint-01

# PR 생성 (gh CLI 사용 시)
gh pr create --base main --head sprint-01 \
  --title "feat: Sprint 1 완료 - Delphi VCL 프로젝트 뼈대 및 Hyper-V 상태 감지" \
  --body "Sprint 1 구현 내용..."
```
