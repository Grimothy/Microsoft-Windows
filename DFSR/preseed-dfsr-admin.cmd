@echo off

set sourcefolderUNC=E:\ACTSFileServices\VillageNursingCare

set destionationfolderPath=F:\ACTSFileServices\VillageNursingCare

REM **************************************************
REM ***** set up logging *****

for /f "tokens=2" %%i in ('date /t') do set thedate=%%i

set mm=%thedate:~0,2%
set dd=%thedate:~3,2%
set yyyy=%thedate:~6,4%
set two-digit-year=%thedate:~8,2%

set logfile="c:\temp\preseed-dfsr-VillageNursingCare.%mm%%dd%%yyyy%.log"

pause
REM **************************************************
robocopy %sourcefolderUNC% %destionationfolderPath% /e /b /copyall /r:6 /w:5 /MT:64 /xd DfsrPrivate /tee /log:%logfile% /v


