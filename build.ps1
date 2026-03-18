# build.ps1
# SetHyperV Sprint 1 빌드 및 검증 스크립트
# 사용법: .\build.ps1 [-Config Release|Debug] [-Platform Win64|Win32]
#
# 요구사항: RAD Studio / Embarcadero Delphi 설치, msbuild 경로 설정

param(
    [string]$Config   = "Release",
    [string]$Platform = "Win64"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = $PSScriptRoot
$ProjectFile = Join-Path $ProjectRoot "src\SetHyperV.dproj"
$OutputExe   = Join-Path $ProjectRoot "Win64\$Config\SetHyperV.exe"

Write-Host "=== SetHyperV Build Script ===" -ForegroundColor Cyan
Write-Host "Config   : $Config"
Write-Host "Platform : $Platform"
Write-Host "Project  : $ProjectFile"
Write-Host ""

# --- 프로젝트 파일 존재 확인 ---
if (-not (Test-Path $ProjectFile)) {
    Write-Error "프로젝트 파일을 찾을 수 없습니다: $ProjectFile"
    exit 1
}

# --- BDS 환경 변수 확인 ---
$BDS = $env:BDS
if (-not $BDS) {
    # RAD Studio 기본 설치 경로 자동 탐색 (버전별)
    $CandidatePaths = @(
        "C:\Program Files (x86)\Embarcadero\Studio\23.0",  # RAD Studio 12 Athens
        "C:\Program Files (x86)\Embarcadero\Studio\22.0",  # RAD Studio 11 Alexandria
        "C:\Program Files (x86)\Embarcadero\Studio\21.0",  # RAD Studio 10.4 Sydney
        "C:\Program Files (x86)\Embarcadero\Studio\20.0"   # RAD Studio 10.3 Rio
    )
    foreach ($path in $CandidatePaths) {
        if (Test-Path (Join-Path $path "bin\CodeGear.Delphi.Targets")) {
            $BDS = $path
            Write-Host "BDS 자동 감지: $BDS" -ForegroundColor Yellow
            break
        }
    }
}

if (-not $BDS) {
    Write-Warning "BDS 환경 변수가 설정되지 않았습니다."
    Write-Warning "RAD Studio 가 설치되어 있으면 환경 변수 BDS 를 설정하거나"
    Write-Warning "RAD Studio IDE 에서 직접 빌드하세요."
    Write-Host ""
    Write-Host "수동 빌드 명령어:" -ForegroundColor Cyan
    Write-Host "  msbuild src\SetHyperV.dproj /t:Build /p:Config=$Config /p:Platform=$Platform"
    exit 1
}

# --- msbuild 실행 ---
$MsBuild = Join-Path $BDS "bin\msbuild.exe"
if (-not (Test-Path $MsBuild)) {
    # 시스템 msbuild fallback
    $MsBuild = "msbuild"
}

Write-Host "빌드 시작..." -ForegroundColor Green
& $MsBuild $ProjectFile /t:Build "/p:Config=$Config" "/p:Platform=$Platform" /nologo /verbosity:minimal

if ($LASTEXITCODE -ne 0) {
    Write-Error "빌드 실패 (종료 코드: $LASTEXITCODE)"
    exit $LASTEXITCODE
}

# --- 산출물 확인 ---
Write-Host ""
Write-Host "=== 빌드 결과 검증 ===" -ForegroundColor Cyan

if (Test-Path $OutputExe) {
    $FileInfo = Get-Item $OutputExe
    Write-Host "BUILD OK: $OutputExe" -ForegroundColor Green
    Write-Host "  크기   : $([math]::Round($FileInfo.Length / 1KB, 1)) KB"
    Write-Host "  생성일 : $($FileInfo.LastWriteTime)"
} else {
    Write-Error "BUILD FAIL: EXE 파일이 생성되지 않았습니다 - $OutputExe"
    exit 1
}

# --- Sprint 1 완료 기준 체크리스트 ---
Write-Host ""
Write-Host "=== Sprint 1 완료 기준 체크리스트 ===" -ForegroundColor Cyan
Write-Host "  [수동 확인 필요] EXE 실행 시 1초 이내 Hyper-V 상태 표시"
Write-Host "  [수동 확인 필요] ON(초록) / OFF(빨강) / 감지불가(올리브) 색상 구분"
Write-Host "  [수동 확인 필요] 관리자 권한 없이 실행해도 상태 조회 정상 동작"
Write-Host "  [수동 확인 필요] 감지 불가 시 토글 버튼 비활성화"
Write-Host ""
Write-Host "PowerShell 교차 검증 명령:" -ForegroundColor Yellow
Write-Host "  bcdedit /enum '{current}' | Select-String 'hypervisorlaunchtype'"
Write-Host ""
Write-Host "Sprint 1 빌드 완료." -ForegroundColor Green
