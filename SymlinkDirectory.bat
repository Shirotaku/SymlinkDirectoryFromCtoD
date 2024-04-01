@echo off
setlocal enabledelayedexpansion

rem Checking if the script is being run with administrator privileges
whoami /priv | find "SeIncreaseQuotaPrivilege" >nul
if %errorlevel% neq 0 (
    rem Case 1: The script is called without administrator rights with a path as a parameter

    rem Saving the arguments to a temporary file
    echo %* > "%TEMP%\arguments.tmp"

    rem Initiating UAC elevation and restarting the current script with elevated rights
    powershell -ex unrestricted -Command "Start-Process -Verb RunAs -FilePath '%comspec%' -ArgumentList '/k \"%~fnx0\"'"
    rem Exiting the current script as it will be rerun with elevated rights
    goto :eof
) else (
    rem Case 2: The script is called with administrator rights and without parameters

    rem Main part of the script after UAC elevation
    echo Script is running with administrator privileges.

    rem Checking if the temporary file exists and reading the arguments
    if exist "%TEMP%\arguments.tmp" (
        rem Checking if a folder was passed as a parameter
        for /f "usebackq delims=" %%a in ("%TEMP%\arguments.tmp") do (
            set "argument=%%~a"rem Removing quotes

            rem Deleting the temporary file
            del "%TEMP%\arguments.tmp" >nul 2>&1

            if "%%~a"=="" (
                echo No folder specified.
                goto :eof
            )

            rem Storing the source and target folders in variables and removing trailing spaces
            set "source=%%~a"
            rem Removing trailing space
            set "source=!source:~0,-2!"
            set "target=!source:C:=D:!"

            rem Confirmation before moving the folder
            echo Please confirm the move operation:
            echo Source folder: !source!
            echo Target folder: !target!
            set /p confirm=Press Enter to confirm and proceed: 
            if "!confirm!"=="" (
                rem Moving the folder to drive D
                robocopy "!source!" "!target!" /MOVE /E >nul
                
                rem Checking if the target folder exists
                if exist "!target!" (
                    rem Creating the symbolic link (/J) from the old to the new path
                    mklink /J "!source!" "!target!" >nul
                    if errorlevel 1 (
                        echo Error creating symbolic link.
                        goto :eof
                    )
                    rem Displaying success message
                    echo Folder moved successfully, and symbolic link created.
                ) else (
                    echo Error moving the folder.
                    goto :eof
                )
            ) else (
                echo Move operation aborted.
                goto :eof
            )
        )
    ) else (
        rem The temporary file doesn't exist, no parameters are present
        echo No parameters provided.
        goto :eof
    )
)

:eof
pause
