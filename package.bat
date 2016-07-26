@echo off
setlocal EnableDelayedExpansion
if NOT defined packagedepth (
	set packagedepth=1
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
	set "path=%path%;!core!extensions\;!core!modlets\;%~dp0"
	pushd !modules!
) else (
	set /a packagedepth+=1
)

if "[%1]"=="[]" (
	set /p "script=Script to Package Up: "
) else (
	set "script=%~1"
)


if %packagedepth% == 1 (
	setlocal enabledelayedexpansion
	rem Initialization
	rem check if we have s_which
	set s_which=false
	call s_which s_which.bat
	cls
	if !s_which!==false (
		echo Initialization failed because s_which wasn't found
		pause
		exit 1
	)
	rem check for batch tester
	call s_which mod_SelfTest.bat
	if not "!_path!" == "" (
		echo Running Self Test on Script to be Packaged...
		call mod_SelfTest %script%
		rem echo Self Test Completed Sucessfully
		echo.
	) else (
		echo Initialization failed because modSelfTest wasn't found
		pause
		exit 1
	)
	endlocal
	rem set comcounter=0
	if NOT exist %temp%\packager\ (
		mkdir %temp%\packager\ 2>&1 >nul
	)
	del /q %temp%\packager\*
	if exist %temp%\packager\*.bat (
		echo error deleting old files
		pause
		exit 1
	)
	del /q %script:.bat=%_package.bat
	echo Packaging Script...
) else (
	call s_which %script%
	if "!_path!" == "" (
		echo File "%script%" doesn't exist
		pause
		exit 1
	) else (
		rem echo Path: !_path!
	)
)
if exist %script% (
	set _path=.\%script%
)
if %packagedepth% gtr 1 (
	(
		echo/:%script:.bat=%
	) >> %temp%\packager\%script%.bat
)
set errorcheck=fail
for /F "tokens=*" %%i in (%_path%) do (
	set errorcheck=pass
	call mod_spinner /speedhack
	echo "%%i" 2>nul | findstr /B /I /R /C:.call.* > nul
	if NOT ERRORLEVEL 1 (
		rem echo 0.1: %%i
		set item=%%i
		rem echo 0.2: !item!
		rem trim whitespace
		for /f "tokens=* delims= " %%a in ("!item!") do set "item=%%a"
		for /l %%a in (1,1,100) do if "!item:~-1!"==" " set "item=!item:~0,-1!"
		rem echo 0.3: !item!
		rem workaround because... reasons...
		set errorlevel=%%errorlevel%%
		for /F "tokens=2,*" %%j IN ('echo "!item! " 2^>nul') do (
			rem echo 1.0: %%k
			set "args=%%k"
			rem echo 2.0: !args!
			set "args=!args:~0,-2!"
			rem echo 3.0: !args!
			echo "%%j" 2>nul | findstr /i /c:"s_which" /c:"mod_SelfTest" > nul
			if ERRORLEVEL 1 (
				echo "!checked!" 2>nul | findstr /i /C:"%%j" 2>&1 >nul
				if ERRORLEVEL 1 (
					rem set /a comcounter+=1
					if %packagedepth% gtr 1 (
						(
							echo/call :%%j !args!
						) >> %temp%\packager\%script%.bat
					) else (
						(
							echo/call :%%j !args!
						) >> %script:.bat=%_package.bat
					)
					rem set %%j_comcounter=!comcounter!
					rem echo %%j_comcounter=!%%j_comcounter!
					call %~n0 %%j.bat
				) else (
					if %packagedepth% gtr 1 (
						(
							echo/call :%%j !args!
						) >> %temp%\packager\%script%.bat
					) else (
						(
							echo/call :%%j !args!
						) >> %script:.bat=%_package.bat
					)
				)
			) else (
				if %packagedepth% gtr 1 (
					(
						echo/call :s_which !args!
					) >> %temp%\packager\%script%.bat
				) else (
					(
						echo/set "s_which=true" ^& set "_path=.\"
					) >> %script:.bat=%_package.bat
				)
			)
		)
	) else (
		setlocal disabledelayedexpansion
		if %packagedepth% gtr 1 (
			(
				echo/%%i
			) >> %temp%\packager\%script%.bat
		) else (
			(
				echo/%%i 
			) >> %script:.bat=%_package.bat
		)
		endlocal
	)
)
if %errorcheck%==fail (
	echo Could Not Access File Aborting...
	pause
	exit 1
)
if %packagedepth% gtr 1 (
	(
		echo/exit /b
	) >> %temp%\packager\%script%.bat
)
if %packagedepth% == 1 (
	call mod_spinner /clear
	echo/Finishing Up...
	call mod_spinner /speedhack
	call s_which s_which.bat
	if NOT "!_path!" == "" (
		echo :s_which > %temp%\packager\s_which.bat
		type !_path! >> %temp%\packager\s_which.bat
		echo.        >> %temp%\packager\s_which.bat
		echo exit /b >> %temp%\packager\s_which.bat
	) else (
		echo Error Loading s_which
		echo The Script is NOT complete
		pause
		exit 1
	)
		for /f %%f in ('dir /b %temp%\packager\') do (
		call mod_spinner /speedhack
		type %temp%\packager\%%f | findstr /vbc:"rem" >> %script:.bat=%_package.bat
	)
	call mod_spinner /clear
	rem for /f "usebackq delims==" %%i IN (`set ^| findstr /i /c:"_comcounter"`) do echo %%i=!%%i!
	echo/Done
	popd
	pause
)
rem this is to bypass annoying stuff
set "setstring="
rem for /f "usebackq delims==" %%i IN (`set ^| findstr /i /c:"_comcounter"`) do set "setstring=!setstring! ^& set ""%%i=!%%i!"""
rem echo setstring=%setstring%
set /a packagedepth-=1
endlocal & set "checked=%checked% %~n1" & set "spinner=%spinner%" 
rem & set "comcounter=%comcounter%" %setstring%