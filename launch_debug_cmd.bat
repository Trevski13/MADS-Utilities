@echo off
set debug=true
set "core=.\"
set "modules=.\"
if exist "settings.ini" (
	for /F "usebackq delims=" %%a in ("%~dp0settings.ini") do (
		echo %%a | findstr /r /C:"^[a-z][a-z]*  *=  *.*" > nul
		if NOT ERRORLEVEL 1 (
			for /F "usebackq tokens=1" %%b in (`echo %%a`) do (
				if %%b == core (
					for /F "usebackq tokens=3" %%c in (`echo %%a`) do (
						set "core=%%c"
					)
				)
				if %%b == modules (
					for /F "usebackq tokens=3" %%c in (`echo %%a`) do (
						set "modules=%%c"
					)
				)
			)
		)
	)
) else (
	echo error reading settings.ini file, setting defaults
)
for %%P in ("%core%") do set core=%%~dpP
for %%P in ("%modules%") do set modules=%%~dpP
set "path=%path%;%core%extensions\;%core%modlets\;%~dp0"
cd /d %core%modlets\
start cmd.exe