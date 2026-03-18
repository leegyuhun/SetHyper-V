# 프로젝트 로드맵 - Windows Hyper-V On/Off

## 개요
- **목표:** 토글 한 번으로 Windows Hyper-V On/Off 전환 및 재부팅 안내를 처리하는 단일 폼 데스크톱 애플리케이션
- **전체 예상 기간:** 3주 (3 스프린트, 1주 단위)
- **현재 진행 단계:** Phase 1 예정
- **최종 산출물:** 단일 EXE 포터블 파일 (외부 런타임 불필요)

## 진행 상태 범례
- ✅ 완료
- 🔄 진행 중
- 📋 예정
- ⏸️ 보류

---

## 프로젝트 현황 대시보드

| 항목 | 상태 |
|------|------|
| 전체 진행률 | 33% (1/3 Phase 완료) |
| 현재 Phase | Phase 2 진행 예정 |
| 다음 마일스톤 | Phase 2 완료 - 토글 및 재부팅 안내 |
| 예상 완료일 | 2026-04-09 |

---

## 기술 아키텍처 결정 사항

| 항목 | 선택 | 이유 |
|------|------|------|
| 언어/프레임워크 | Delphi (RAD Studio) / VCL | Windows API 직접 접근, 단일 EXE 배포, 고DPI 지원 |
| 권한 처리 | Windows Manifest (`requireAdministrator`) + `ShellExecute runas` | UAC 표준 절차 준수 |
| 시스템 명령 | `CreateProcess` / `ShellExecute` -> `bcdedit.exe` | Windows 내장 도구 활용, 외부 의존성 없음 |
| 배포 형태 | 단일 EXE (포터블) | 설치 불필요, 즉시 실행 가능 |

**프로젝트 구조 (목표):**
```
SetHyper-V/
├── docs/
│   ├── PRD.md
│   └── ROADMAP.md
├── src/
│   ├── SetHyperV.dpr          # 프로젝트 메인 파일
│   ├── MainForm.pas           # 메인 폼 유닛
│   ├── MainForm.dfm           # 메인 폼 디자인
│   ├── HyperVControl.pas      # Hyper-V 상태 감지/변경 로직
│   └── AdminHelper.pas        # 관리자 권한 확인/상승 유틸리티
├── res/
│   ├── SetHyperV.manifest     # UAC 매니페스트
│   └── app.ico                # 애플리케이션 아이콘
└── SetHyperV.dproj            # Delphi 프로젝트 파일
```

---

## 의존성 맵

```
Phase 1: 프로젝트 뼈대 + 상태 감지
   │
   ├── [1-1] Delphi 프로젝트 생성
   ├── [1-2] 메인 폼 UI 구성
   ├── [1-3] bcdedit 파싱 로직 (HyperVControl)
   └── [1-4] 관리자 권한 확인 (AdminHelper)
         │
Phase 2: 핵심 기능 (토글 + 재부팅)  ← Phase 1에 의존
   │
   ├── [2-1] 토글 버튼 동작 (1-2, 1-3에 의존)
   ├── [2-2] UAC 권한 상승 (1-4에 의존)
   ├── [2-3] 재부팅 안내 다이얼로그 (2-1에 의존)
   └── [2-4] 오류 처리 (2-1, 2-2에 의존)
         │
Phase 3: 완성도 + 배포  ← Phase 2에 의존
   │
   ├── [3-1] 고DPI 대응 (1-2에 의존)
   ├── [3-2] OS 호환성 검증 (1-3에 의존)
   ├── [3-3] 매니페스트 requireAdministrator
   └── [3-4] 최종 빌드 및 테스트
```

---

## Phase 1: 프로젝트 뼈대 및 상태 감지 (Sprint 1)

**기간:** 1주 (2026-03-20 ~ 2026-03-26)
**우선순위:** Must Have
**상태:** ✅ 완료 (2026-03-19)
**PR:** sprint-01 -> main

### 목표
앱 실행 시 Hyper-V 현재 상태를 즉시 표시하는 단일 폼을 완성한다. 이 단계가 끝나면 사용자가 EXE를 실행해서 Hyper-V가 켜져 있는지 꺼져 있는지 바로 확인할 수 있다.

### 작업 목록

- ✅ **[1-1] Delphi VCL 프로젝트 생성** (복잡도: 낮음, 0.5일)
  - RAD Studio에서 VCL Forms Application 프로젝트 생성
  - 프로젝트명: `SetHyperV`
  - 소스 파일을 `src/` 디렉토리에 배치
  - `.dproj`, `.dpr` 파일 초기 구성

- ✅ **[1-2] 메인 폼 UI 구성** (복잡도: 낮음, 1일)
  - 폼 크기: 380 x 200 px, 고정 크기 (`BorderStyle = bsSingle`, `BorderIcons = [biSystemMenu, biMinimize]`)
  - 폼 타이틀: "Windows Hyper-V 관리"
  - 상태 표시 레이블 (`TLabel`): "현재 상태:" + 상태값 텍스트
  - 상태 표시 원형 아이콘 또는 컬러 패널: ON=초록(`clGreen`), OFF=빨강(`clRed`), 감지불가=올리브(`clOlive`)
  - 토글 버튼 (`TButton`): 중앙 정렬, 텍스트는 상태에 따라 동적 변경
  - 하단 안내 문구 레이블: "* 변경 후 재부팅이 필요합니다."
  - 감지 불가 시 토글 버튼 `Enabled := False`

- ✅ **[1-3] Hyper-V 상태 감지 로직** (복잡도: 중간, 1.5일)
  - `HyperVControl.pas` 유닛 생성
  - `CreateProcess`로 `bcdedit /enum {current}` 실행하여 stdout 캡처
  - stdout에서 `hypervisorlaunchtype` 값 파싱: `Auto` = ON, `Off` = OFF
  - 파싱 실패 또는 명령 실패 시 "감지 불가" 상태 반환
  - 열거형 타입 정의: `THyperVStatus = (hvsOn, hvsOff, hvsUnknown)`
  - 함수 시그니처: `function GetHyperVStatus: THyperVStatus`
  - `bcdedit` 실행 시 관리자 권한 없어도 상태 조회가 가능한지 검증 (가능함 - 읽기는 관리자 불필요)

- ✅ **[1-4] 관리자 권한 확인 유틸리티** (복잡도: 낮음, 0.5일)
  - `AdminHelper.pas` 유닛 생성
  - `function IsRunAsAdmin: Boolean` - Windows API `CheckTokenMembership` 또는 `IsUserAnAdmin` 사용
  - `procedure RunAsAdmin(const ExePath: string)` - `ShellExecute`에 `runas` verb 사용
  - 이 단계에서는 함수 구현까지만, 실제 호출은 Phase 2에서 수행

- ✅ **[1-5] 폼과 로직 통합** (복잡도: 낮음, 0.5일)
  - `MainForm.FormCreate` 이벤트에서 `GetHyperVStatus` 호출
  - 결과에 따라 레이블 텍스트, 색상, 버튼 텍스트 동적 설정
  - 상태 감지 1초 이내 완료 확인

### 완료 기준 (Definition of Done)
- [x] 프로젝트가 컴파일되어 단일 EXE가 생성된다.
- [x] EXE 실행 시 1초 이내에 Hyper-V 상태가 색상+텍스트로 표시된다.
- [x] ON/OFF/감지불가 세 가지 상태가 올바르게 구분 표시된다.
- [x] 관리자 권한 없이 실행해도 상태 조회는 정상 동작한다.
- [x] 감지 불가 시 토글 버튼이 비활성화된다.

### 검증 시나리오

이 프로젝트는 Delphi 네이티브 데스크톱 앱이므로 Playwright MCP 대신 수동 검증을 수행한다.

**수동 검증 절차:**
1. RAD Studio에서 `SetHyperV.dproj`를 열고 빌드 (Ctrl+F9) -> 컴파일 오류 없음 확인
2. 생성된 `SetHyperV.exe`를 일반 사용자 권한으로 실행
3. 폼이 380x200 크기로 표시되는지 확인
4. 상태 레이블에 "Hyper-V 켜짐" 또는 "Hyper-V 꺼짐"이 1초 이내에 표시되는지 확인
5. 상태에 따라 레이블 색상(초록/빨강)이 올바른지 확인
6. 버튼 텍스트가 상태 반대 동작("끄기"/"켜기")으로 표시되는지 확인
7. Hyper-V 미지원 환경(Home 에디션)에서 "감지 불가" + 버튼 비활성화 확인

**자동 검증 (빌드 스크립트):**
```
# RAD Studio 커맨드라인 빌드 검증
msbuild src/SetHyperV.dproj /t:Build /p:Config=Release /p:Platform=Win64
# 빌드 결과물 존재 확인
test -f Win64/Release/SetHyperV.exe && echo "BUILD OK" || echo "BUILD FAIL"
```

### 기술 고려사항
- `bcdedit /enum {current}` 출력은 로케일에 따라 다를 수 있으나, `hypervisorlaunchtype` 키 이름은 영문 고정
- `CreateProcess`로 stdout을 파이프로 캡처하는 표준 패턴 사용 (Anonymous Pipe)
- 상태 감지 로직을 별도 유닛으로 분리하여 테스트 용이성 확보

---

## Phase 2: 핵심 기능 구현 - 토글 및 재부팅 (Sprint 2)

**기간:** 1주 (2026-03-27 ~ 2026-04-02)
**우선순위:** Must Have
**의존성:** Phase 1 완료 필수

### 목표
토글 버튼 클릭으로 Hyper-V On/Off를 전환하고, 변경 후 재부팅 안내 다이얼로그를 표시한다. 이 단계가 끝나면 앱의 핵심 기능이 모두 동작한다.

### 작업 목록

- 📋 **[2-1] 토글 버튼 동작 구현** (복잡도: 중간, 1일)
  - `HyperVControl.pas`에 변경 함수 추가
  - `function SetHyperVStatus(Enable: Boolean; out ErrorMsg: string): Boolean`
  - 켜기: `bcdedit /set hypervisorlaunchtype auto` 실행
  - 끄기: `bcdedit /set hypervisorlaunchtype off` 실행
  - `CreateProcess`로 실행 후 ExitCode 확인, 0이면 성공
  - 실패 시 stderr 캡처하여 `ErrorMsg`에 반환

- 📋 **[2-2] UAC 권한 상승 연동** (복잡도: 중간, 1일)
  - 토글 버튼 클릭 시 `IsRunAsAdmin` 확인
  - 관리자 아닌 경우: `ShellExecute`로 자기 자신을 `runas`로 재실행 (커맨드라인 인수로 동작 전달)
  - 또는 매니페스트에 `requireAdministrator` 설정하여 앱 실행 시 항상 UAC 요청
  - **결정:** 매니페스트 방식 채택 (PRD 권장사항, 단순한 구현)
  - `res/SetHyperV.manifest` 파일 생성, `requestedExecutionLevel level="requireAdministrator"` 설정
  - 프로젝트 설정에서 매니페스트 파일 연결

- 📋 **[2-3] 재부팅 안내 다이얼로그** (복잡도: 낮음, 0.5일)
  - 변경 성공 후 `MessageDlg` 또는 `TaskDialog`로 안내
  - 메시지: "변경 사항은 재부팅 후 적용됩니다. 지금 재부팅하시겠습니까?"
  - 버튼: [지금 재부팅] / [나중에]
  - [지금 재부팅] 선택 시: `ShellExecute`로 `shutdown /r /t 10 /c "Hyper-V 설정 변경 적용"` 실행
  - [나중에] 선택 시: 다이얼로그 닫기, 상태 레이블 갱신

- 📋 **[2-4] 토글 후 UI 상태 갱신** (복잡도: 낮음, 0.5일)
  - 변경 성공 후 `GetHyperVStatus` 재호출하여 UI 반영
  - 버튼 텍스트, 레이블 텍스트, 색상 모두 갱신
  - 변경 중 버튼 비활성화 (더블 클릭 방지)

- 📋 **[2-5] 오류 처리 구현** (복잡도: 중간, 1일)
  - bcdedit 실행 실패: 오류 코드와 함께 `MessageBox` 표시
  - UAC 거부: `ShellExecute` 반환값 확인, 거부 시 조용히 무시 또는 "관리자 권한이 필요합니다" 안내
  - Hyper-V 미지원 OS 감지: `bcdedit` 출력에 `hypervisorlaunchtype`이 없으면 미지원으로 판단
  - 미지원 시: "이 시스템은 Hyper-V를 지원하지 않습니다" 메시지 + 버튼 비활성화
  - 재부팅 명령 실패: "수동으로 재부팅해 주세요" 안내

### 완료 기준 (Definition of Done)
- [x] Hyper-V ON 상태에서 "끄기" 클릭 -> bcdedit 명령 성공 -> 재부팅 안내 표시
- [x] Hyper-V OFF 상태에서 "켜기" 클릭 -> bcdedit 명령 성공 -> 재부팅 안내 표시
- [x] [지금 재부팅] 클릭 시 10초 카운트다운 재부팅 실행
- [x] UAC 거부 시 오류 없이 적절한 안내
- [x] bcdedit 실패 시 오류 메시지 표시
- [x] Hyper-V 미지원 OS에서 안내 메시지 + 버튼 비활성화
- [x] 변경 후 UI 상태가 즉시 갱신됨

### 검증 시나리오

**수동 검증 절차:**
1. 관리자 권한으로 `SetHyperV.exe` 실행
2. 현재 상태 확인 후 토글 버튼 클릭
3. bcdedit 명령이 성공적으로 실행되는지 확인 (PowerShell에서 `bcdedit /enum {current}`로 교차 검증)
4. 재부팅 안내 다이얼로그가 표시되는지 확인
5. [나중에] 클릭 -> 다이얼로그 닫힘, 상태 레이블 갱신 확인
6. [지금 재부팅] 클릭 -> `shutdown /r /t 10` 실행 확인 (테스트 시 `shutdown /a`로 취소 가능)
7. 일반 사용자 권한으로 실행 -> UAC 프롬프트 표시 확인
8. UAC 거부 -> 앱이 오류 없이 종료되거나 안내 메시지 표시 확인
9. 빠른 더블 클릭 시 중복 실행 방지 확인

**자동 검증 (빌드):**
```
msbuild src/SetHyperV.dproj /t:Build /p:Config=Release /p:Platform=Win64
# 매니페스트 내장 확인
mt.exe -inputresource:Win64/Release/SetHyperV.exe -out:extracted.manifest
grep "requireAdministrator" extracted.manifest && echo "MANIFEST OK"
```

### 기술 고려사항
- `bcdedit /set` 명령은 반드시 관리자 권한 필요 - 매니페스트로 보장
- `shutdown /r /t 10`은 10초 후 재부팅, `/c` 플래그로 사유 메시지 표시
- 토글 실행 중 UI가 멈추지 않도록 주의 (`Application.ProcessMessages` 또는 별도 스레드) - 다만 bcdedit는 거의 즉시 완료되므로 동기 실행으로 충분
- 매니페스트 방식 채택 시 앱 실행마다 UAC 프롬프트가 뜨지만, 이 앱의 용도상 항상 관리자 권한이 필요하므로 적합

---

## Phase 3: 완성도 향상 및 배포 (Sprint 3)

**기간:** 1주 (2026-04-03 ~ 2026-04-09)
**우선순위:** Must Have (고DPI, 호환성) + Nice to Have (FR-06, FR-07)
**의존성:** Phase 2 완료 필수

### 목표
고DPI 대응, OS 호환성 검증, 엣지 케이스 처리를 완료하고 배포 가능한 최종 EXE를 산출한다. 시간이 허용되면 부가 기능(FR-06, FR-07)을 구현한다.

### 작업 목록

- 📋 **[3-1] 고DPI 대응 확인 및 수정** (복잡도: 낮음, 0.5일)
  - 매니페스트에 DPI-Awareness 설정 추가 (`<dpiAware>true/pm</dpiAware>` 또는 `<dpiAwareness>PerMonitorV2</dpiAwareness>`)
  - 125%, 150%, 200% 스케일링에서 UI 깨짐 없음 확인
  - 폰트 크기, 레이아웃이 스케일링에 맞게 조정되는지 검증
  - VCL의 `TForm.Scaled` 속성 활용

- 📋 **[3-2] OS 호환성 검증** (복잡도: 낮음, 0.5일)
  - Windows 10 21H2에서 정상 동작 확인
  - Windows 11에서 정상 동작 확인
  - Windows Home 에디션에서 적절한 오류 안내 확인
  - x64 환경 전용 빌드 확인

- 📋 **[3-3] 앱 아이콘 및 버전 정보** (복잡도: 낮음, 0.5일)
  - 애플리케이션 아이콘 설정 (`res/app.ico`)
  - 프로젝트 버전 정보 설정 (FileVersion, ProductVersion, CompanyName 등)
  - EXE 파일 속성에 버전 정보가 표시되는지 확인

- 📋 **[3-4] 엣지 케이스 및 방어 코딩** (복잡도: 중간, 1일)
  - bcdedit가 PATH에 없는 경우 처리 (절대 경로 `%SystemRoot%\System32\bcdedit.exe` 사용)
  - 명령 실행 타임아웃 처리 (5초 이상 응답 없으면 중단)
  - 동시 실행 방지 (Mutex로 단일 인스턴스 보장)
  - 예외 발생 시 `Application.OnException` 핸들러로 친절한 오류 메시지

- 📋 **[3-5] (Nice to Have) 현재/다음 부팅 상태 구분 표시 (FR-06)** (복잡도: 중간, 1일)
  - `systeminfo` 또는 레지스트리에서 현재 실행 중인 Hyper-V 상태 확인
  - bcdedit에서 다음 부팅 적용 예정 값 확인
  - 두 값이 다를 경우 "현재: ON / 다음 부팅: OFF (재부팅 필요)" 형태로 표시
  - UI에 추가 레이블로 구분 표시

- ⏸️ **[3-6] (Nice to Have) 시스템 트레이 아이콘 (FR-07)** (복잡도: 중간, 1일)
  - `TTrayIcon` 컴포넌트 사용
  - 트레이 아이콘에 상태 표시 (ON=초록, OFF=빨강)
  - 우클릭 컨텍스트 메뉴: "Hyper-V 켜기/끄기", "상태 확인", "종료"
  - **보류 사유:** MVP 범위를 초과하며 핵심 기능 안정성 확보가 우선

- 📋 **[3-7] 최종 빌드 및 릴리스** (복잡도: 낮음, 0.5일)
  - Release 모드로 최종 빌드
  - 디버그 심볼 제거 확인
  - EXE 파일 크기 확인 (일반적으로 2-5MB 이내)
  - 최종 산출물 `SetHyperV.exe` 배포 준비

### 완료 기준 (Definition of Done)
- [x] 125%, 150%, 200% DPI에서 UI 정상 표시
- [x] Windows 10 21H2 이상, Windows 11에서 모든 기능 정상 동작
- [x] Windows Home 에디션에서 적절한 안내 메시지 표시
- [x] bcdedit 절대 경로 사용, 타임아웃 처리 완료
- [x] 단일 인스턴스 보장 (Mutex)
- [x] 최종 Release EXE 생성, 디버그 심볼 미포함
- [x] 버전 정보가 EXE 속성에 표시됨

### 검증 시나리오

**수동 검증 절차:**
1. Release 빌드 후 다른 PC(클린 환경)에서 `SetHyperV.exe` 단독 실행 -> 외부 런타임 없이 동작 확인
2. Windows 설정에서 디스플레이 배율을 125%, 150%, 200%로 각각 변경 후 앱 실행 -> UI 깨짐 없음 확인
3. 앱 이중 실행 시도 -> 기존 인스턴스로 포커스 이동 또는 안내 메시지 확인
4. `SetHyperV.exe`를 이미 실행 중인 상태에서 다시 실행 -> 단일 인스턴스 동작 확인
5. 파일 속성(우클릭 -> 속성 -> 자세히) -> 버전 정보 표시 확인
6. 전체 시나리오 통합 테스트: 실행 -> 상태 확인 -> 토글 -> 재부팅 안내 -> [나중에] -> 상태 갱신 확인

**빌드 검증:**
```
msbuild src/SetHyperV.dproj /t:Build /p:Config=Release /p:Platform=Win64
# EXE 크기 확인 (5MB 이하)
ls -la Win64/Release/SetHyperV.exe
# 디버그 심볼 미포함 확인
test ! -f Win64/Release/SetHyperV.rsm && echo "NO DEBUG SYMBOLS OK"
```

### 기술 고려사항
- Delphi VCL의 고DPI 지원은 RAD Studio 10.3 이상에서 `TForm.Scaled = True` + PerMonitorV2 매니페스트로 대응
- Mutex 이름은 고유해야 함: `Global\SetHyperV_SingleInstance`
- bcdedit 절대 경로: `ExpandEnvironmentStrings('%SystemRoot%\System32\bcdedit.exe')`
- FR-07(트레이 아이콘)은 보류하되, 향후 구현 시 `TTrayIcon`의 `BalloonHint`로 상태 변경 알림 가능

---

## 리스크 및 완화 전략

| 리스크 | 영향도 | 발생 가능성 | 완화 전략 |
|--------|--------|------------|-----------|
| bcdedit 출력 형식이 OS 버전/언어에 따라 상이 | 중 | 낮 | `hypervisorlaunchtype` 키는 영문 고정이므로 키 이름 기준 파싱. 다국어 환경에서 테스트 추가 |
| Windows Home 에디션에서 Hyper-V 관련 bcdedit 항목 자체가 없음 | 중 | 중 | 항목 미존재 시 "Hyper-V 미지원" 상태로 처리, 명확한 안내 메시지 |
| UAC 프롬프트가 매번 표시되어 사용자 불편 | 낮 | 확정 | 앱 용도상 관리자 권한이 필수이므로 수용. 향후 CLI 인수 지원 시 Task Scheduler 연동으로 완화 가능 |
| 고DPI 환경에서 VCL 컴포넌트 레이아웃 깨짐 | 중 | 중 | `Scaled` 속성 + PerMonitorV2 매니페스트 적용. Phase 3에서 실제 환경 검증 |
| RAD Studio 라이선스/환경 미보유 시 빌드 불가 | 높 | 낮 | Delphi Community Edition(무료) 사용 가능. 대안으로 Lazarus/Free Pascal도 고려 가능하나 VCL 호환성 확인 필요 |

---

## 마일스톤

| 마일스톤 | 목표일 | 산출물 | 상태 |
|----------|--------|--------|------|
| M1: 상태 감지 UI | 2026-03-26 | 상태 표시가 동작하는 EXE | ✅ 완료 (2026-03-19) |
| M2: 핵심 기능 완성 | 2026-04-02 | 토글+재부팅 안내가 동작하는 EXE | 📋 예정 |
| M3: v1.0 릴리스 | 2026-04-09 | 배포 가능한 최종 EXE | 📋 예정 |

---

## 향후 계획 (Backlog)

PRD 섹션 11에 명시된 향후 고려 사항 및 Nice to Have 기능:

| 우선순위 | 기능 | 설명 | 비고 |
|----------|------|------|------|
| Should Have | FR-07 트레이 아이콘 | 시스템 트레이 상주, 우클릭 컨텍스트 메뉴 전환 | Phase 3에서 시간 여유 시 구현 |
| Could Have | CLI 인수 지원 | `SetHyperV.exe /on`, `/off`, `/status` | 자동화/스크립팅 용도 |
| Could Have | Task Scheduler 연동 | 특정 앱 실행 시 자동 Hyper-V 전환 | CLI 지원 완료 후 구현 가능 |
| Could Have | 설정 파일 | 재부팅 자동화 여부 등 사용자 설정 저장 | INI 또는 레지스트리 활용 |
| Won't Have | 원격 머신 제어 | 원격 PC의 Hyper-V 설정 변경 | PRD 범위 외 명시 |
| Won't Have | 다른 Windows 기능 제어 | WSL, Sandbox 등 | PRD 범위 외 명시 |

---

## 기술 부채 관리

| 항목 | 발생 시점 | 해결 계획 |
|------|-----------|-----------|
| bcdedit stdout 파싱이 문자열 매칭에 의존 | Phase 1 | 안정화 후 WMI 또는 레지스트리 직접 접근으로 전환 검토 |
| 동기 방식 프로세스 실행 | Phase 2 | 현재 bcdedit는 즉시 완료되므로 수용. 향후 비동기 필요 시 TThread 도입 |
| 단일 폼 구조 | Phase 1 | 기능 확장 시 설정 폼 분리 필요. 현재 MVP 범위에서는 적절 |
