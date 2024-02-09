@echo off
title Mini10 Automatic Builder
cd /d %~dp0
echo Mini10 Automatic Builder
echo Version 1.0
echo.
echo Image Version 1809 (Windows 10 LTSC 2019)
net file >nul 2>&1
if "%errorlevel%" neq "0" (
	"%~dp0Bin\NSudo.exe" -U:T -P:E -Priority:RealTime %0% >nul 2>&1
	goto :eof
)
echo.
if exist "%~dp0DVD.iso" (echo ISO was found, skipping...) else (
echo Downloading with aria2...
"%~dp0Bin\aria2\aria2c.exe" -x16 -s16 -oDVD.iso "https://archive.org/download/tiny-10-b-2/Tiny10%20B2.iso"
)
echo Extracting...
"%~dp0Bin\7z.exe" x DVD.iso -o"%~dp0DVD"
echo Deleting Useless stuffs...
rd /q /s "%~dp0DVD\sources\$OEM$"
del /f /q "%~dp0DVD\Auto-saved*.xml"
del /f /q "%~dp0DVD\NTLite.log"
del /f /q "%~dp0DVD\sources\install.ini"
echo Copying unattended file...
copy /Y "%~dp0Plugins\Unattend\autounattend.xml" "%~dp0DVD\autounattend.xml"
echo Modifying images...
md "%~dp0Mount"
md "%~dp0Boot_Mount"
dism /export-image /SourceImageFile:"%~dp0DVD\sources\install.esd" /SourceIndex:1 /DestinationImageFile:"%~dp0DVD\sources\install.wim" /Compress:max
del /f /q "%~dp0DVD\sources\install.esd"
dism /mount-image /imageFile:"%~dp0DVD\sources\install.wim" /Index:1 /MountDir:""%~dp0Mount"
dism /mount-image /imageFile:"%~dp0DVD\sources\boot.wim" /Index:1 /MountDir:""%~dp0Boot_Mount"
reg load HKEY_LOCAL_MACHINE\MINI10_NTUSER "%~dp0Mount\Users\Default\ntuser.dat"
reg load HKEY_LOCAL_MACHINE\MINI10_SOFTWARE "%~dp0Mount\Windows\System32\config\SOFTWARE"
reg load HKEY_LOCAL_MACHINE\MINI10_SYSTEM "%~dp0Mount\Windows\System32\config\SYSTEM"
reg load HKEY_LOCAL_MACHINE\MINI10_SOFTWARE_BOOT "%~dp0Boot_Mount\Windows\System32\config\SOFTWARE"
reg load HKEY_LOCAL_MACHINE\MINI10_SYSTEM_BOOT "%~dp0Boot_Mount\Windows\System32\config\SYSTEM"
for /F %%f in ('dir "%~dp0Plugins\Registry\*.reg" /s /b') do (regedit /s %%f)
reg unload HKEY_LOCAL_MACHINE\MINI10_NTUSER
reg unload HKEY_LOCAL_MACHINE\MINI10_SOFTWARE
reg unload HKEY_LOCAL_MACHINE\MINI10_SYSTEM
reg unload HKEY_LOCAL_MACHINE\MINI10_SOFTWARE_BOOT
reg unload HKEY_LOCAL_MACHINE\MINI10_SYSTEM_BOOT
md "%~dp0Mount\Windows\Setup\RunOnce"
robocopy "%~dp0Plugins\RunOnce" "%~dp0Mount\Windows\Setup\RunOnce" /E
del /f /q "%~dp0Mount\Windows\Panther\RunOnce\_README.txt"
copy /Y "%~dp0Plugins\DefaultWallpaper\img0.jpg" "%~dp0Mount\Windows\Web\Wallpaper\Windows\img0.jpg"
copy /Y "%~dp0Plugins\DefaultWallpaper\img0.jpg" "%~dp0Mount\Windows\Web\Screen\img100.jpg"
robocopy "%~dp0Plugins\AdditionalFiles" "%~dp0Mount" /E
robocopy "%~dp0Plugins\AdditionalBootFiles" "%~dp0Boot_Mount" /E
robocopy "%~dp0Plugins\ISOAdditionalFiles" "%~dp0DVD" /E
del /f /q "%~dp0Mount\_README.txt"
del /f /q "%~dp0Boot_Mount\_README.txt"
del /f /q "%~dp0DVD\_README.txt"
md "%~dp0DVD\sources\$OEM$"
robocopy "%~dp0Plugins\OEM" "%~dp0DVD\sources\$OEM$" /E
del /f /q "%~dp0DVD\sources\$OEM$\_README.txt"
takeown /f "%~dp0Boot_Mount\sources\MediaSetupUIMgr.dll"
icacls "%~dp0Boot_Mount\sources\MediaSetupUIMgr.dll" /grant everyone:F
del /q /f "%~dp0Boot_Mount\sources\MediaSetupUIMgr.dll"
takeown /f "%~dp0Boot_Mount\sources\SetupHost.exe"
icacls "%~dp0Boot_Mount\sources\SetupHost.exe" /grant everyone:F
del /q /f "%~dp0Boot_Mount\sources\SetupHost.exe"
for /f %%f in ('dir "%~dp0Boot_Mount\Windows\WinSxS\Backup" /s /b') do (takeown /f %%f && icacls %%f /grant everyone:F)
takeown /f "%~dp0Boot_Mount\Windows\WinSxS\Backup"
icacls "%~dp0Boot_Mount\Windows\WinSxS\Backup" /grant everyone:F
rd /s /q "%~dp0Boot_Mount\Windows\WinSxS\Backup"
rd /s /q "%~dp0Boot_Mount\Windows\WinSxS\InstallTemp"
rd /s /q "%~dp0Boot_Mount\Windows\WinSxS\ManifestCache"
rd /s /q "%~dp0Boot_Mount\Windows\WinSxS\Temp"
takeown /F "%~dp0Mount\Windows\System32\themeui.dll"
icacls "%~dp0Mount\Windows\System32\themeui.dll" /grant everyone:F
takeown /F "%~dp0Mount\Windows\System32\uxinit.dll"
icacls "%~dp0Mount\Windows\System32\uxinit.dll" /grant everyone:F
rename "%~dp0Mount\Windows\System32\uxinit.dll" uxinit.dll.backup
copy /Y "%~dp0Plugins\UXThemePatch\uxinit.dll" "%~dp0Mount\Windows\System32\uxinit.dll"
rename "%~dp0Mount\Windows\System32\themeui.dll" themeui.dll.backup
copy /Y "%~dp0Plugins\UXThemePatch\themeui.dll" "%~dp0Mount\Windows\System32\themeui.dll"
robocopy "%~dp0Plugins\Themes" "%~dp0Mount\Windows\Resources\Themes" /E
del /f /q "%~dp0Mount\Windows\Resources\Themes\_README.txt"
for /f %%f in ('dir "%~dp0Plugins\Packages\*.cab" /s /b') do (dism /image:"%~dp0Mount" /add-package /packagepath:%%f /IgnoreCheck /PreventPending)
for /f %%f in ('dir "%~dp0Plugins\WinPEPackages\*.cab" /s /b') do (dism /image:"%~dp0Boot_Mount" /add-package /packagepath:%%f /IgnoreCheck /PreventPending)
for /f %%f in ('dir "%~dp0Plugins\Updates\*.msu" /s /b') do (dism /image:"%~dp0Mount" /add-package /packagepath:%%f /IgnoreCheck /PreventPending)
dism /Image:"%~dp0Mount" /Add-Driver /Driver:"%~dp0Plugins\Drivers" /Recurse
dism /Image:"%~dp0Boot_Mount" /Add-Driver /Driver:"%~dp0Plugins\BootDrivers" /Recurse
dism /unmount-image /MountDir:"%~dp0Mount" /Commit
dism /unmount-image /MountDir:"%~dp0Boot_Mount" /Commit
echo Compressing images...
dism /export-image /SourceImageFile:"%~dp0DVD\sources\install.wim" /SourceIndex:1 /DestinationImageFile:"%~dp0DVD\sources\install.esd" /Compress:recovery
dism /export-image /SourceImageFile:"%~dp0DVD\sources\boot.wim" /SourceIndex:1 /DestinationImageFile:"%~dp0DVD\sources\boot2.wim" /Compress:max
del /f /q "%~dp0DVD\sources\boot.wim"
rename "%~dp0DVD\sources\boot2.wim" boot.wim
del /f /q "%~dp0DVD\sources\install.wim"
echo Copying custom files to ISO...
robocopy "%~dp0Plugins\ISOAdditionalFiles" "%~dp0DVD" /E
del /f /q "%~dp0DVD\_README.txt"
echo Making ISO...
"%~dp0Bin\oscdimg.exe" -h -m -o -u2 -udfver102 -bootdata:"2#p0,e,b%~dp0DVD\boot\etfsboot.com#pEF,e,b%~dp0DVD\efi\microsoft\boot\efisys.bin" -lMini10 "%~dp0DVD" "%~dp0Mini10.iso"
echo Cleaning up...
rd /s /q "%~dp0DVD"
rd /s /q "%~dp0Mount"
rd /s /q "%~dp0Boot_Mount"
goto :eof