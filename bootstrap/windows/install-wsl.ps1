<##  설치 대상: Windows 10 1903+ 또는 Windows 11
      작업: WSL2 활성화 + Ubuntu 24.04 배포판 설치  ##>

# 최신 Windows 11 (22H2 +) 는 한 줄이면 끝납니다
wsl --install -d Ubuntu-24.04

# ⬇ Windows 10 구버전 지원 분기(필요시)
# Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
# Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform      -NoRestart
# wsl --set-default-version 2
# wsl --install -d Ubuntu-24.04

wsl --update      # 커널 최신화
wsl --shutdown    # 재시작하여 커널 반영
Write-Host "✅ WSL 설치 완료! 새 Ubuntu 터미널을 열어 다음 단계로 진행하세요." -ForegroundColor Green