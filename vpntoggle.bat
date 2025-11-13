@echo off

SETLOCAL ENABLEDELAYEDEXPANSION
SET "VpnName=MyVPN"
SET "VpnAdapter=WAN Miniport (IKEv2)"
SET /A "ConnectionStatus=1"
SET /A "RasTimeoutLimit=6"
SET /A "RasStep=1"
SET /A "AdapterTimeoutLimit=6"
SET /A "AdapterStep=1"

:MAIN

	CALL :STATUS
	IF %ConnectionStatus% == 0 CALL :CONNECT
	IF %ConnectionStatus% == 1 CALL :DISCONNECT

EXIT

:STATUS
	ipconfig|find /i "%VpnName%" >nul && ECHO Disconnecting %VpnName%...
	IF %errorlevel%==1 (
		SET /A "ConnectionStatus=0"
	)
	REM Reset errorlevel
	ver >nul
EXIT /b

:CONNECT
	REM Cloudflare warp disconnect optional
  warp-cli disconnect >nul 2>&1
	:: maybe these calls for checks shoule be in main??
  CALL :CHECK_RAS
	IF !ERRORLEVEL! GTR 0 CALL :ERROR_HANDLER !ERRORLEVEL!
	CALL :CHECK_ADAPTER
	IF !ERRORLEVEL! GTR 0 CALL :ERROR_HANDLER !ERRORLEVEL!
	CALL :VPNCONNECT
EXIT /b

:DISCONNECT
	rasdial %VpnName% /d
EXIT /b

:VPNCONNECT
:: Run inline PowerShell script to connect VPN
Powershell -Command ^
"rasphone '%VpnName%'; ^
    $wshell = New-Object -ComObject wscript.shell; ^
    $wshell.AppActivate('Network Connections'^); ^
    Start-Sleep -Milliseconds 20; ^
    $wshell.SendKeys('~'^); ^
    Start-Sleep -Milliseconds 700; ^
    $wshell.SendKeys('~'^);"
EXIT /b

:ERROR_HANDLER
ECHO.
ECHO [ERROR] A critical check failed with error code %1.
ECHO Press any key to acknowledge and close this script.
pause >nul
EXIT

:CHECK_RAS
:: --- Check RasMan state directly using net start output ---
ECHO [INIT] Checking Remote Access Connection Manager service...

for /l %%T in (0,%RasStep%,%RasTimeoutLimit%) do (
    for /f "usebackq delims=" %%A in (`net start RasMan 2^>^&1`) do (
        echo %%A | find /i "already been started" >nul && (
            ECHO [OK] RasMan service already running.
            exit /b 0
        )
        echo %%A | find /i "was started successfully" >nul && (
            ECHO [OK] RasMan service started successfully.
            exit /b 0
        )
    )
    ECHO [WAIT] RasMan not ready (%%T seconds elapsed^)...
    timeout /t %RasStep% >nul
)
ECHO [FAIL] RasMan service failed to start within timeout limit.
exit /b 1

:CHECK_ADAPTER
:: --- Wait for VPN adapter to appear with timeout using PowerShell check ---
ECHO [INIT] Checking for VPN adapters...

for /l %%T in (0,%AdapterStep%,%AdapterTimeoutLimit%) do (
    set "DeviceReady="
    for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "if (Get-CimInstance Win32_PnPEntity | Where-Object { $_.Name -like '*!VpnAdapter!*' }) { Write-Host Ready }"`) do set "DeviceReady=%%A"
    if /I "!DeviceReady!"=="Ready" (
        ECHO [OK] VPN adapter detected.
        exit /b 0
    ) else (
        call ECHO [WAIT] VPN adapter not yet initialized (%%T seconds elapsed^)
        timeout /t %AdapterStep% >nul
    )
)
ECHO [FAIL] VPN adapter not detected within timeout limit.
exit /b 2
