@echo off
setlocal enabledelayedexpansion

rem Überprüfen, ob das Skript mit Administratorrechten ausgeführt wird
whoami /priv | find "SeIncreaseQuotaPrivilege" >nul
if %errorlevel% neq 0 (
    rem Fall 1: Das Skript wird ohne Administratorrechte mit einem Pfad als Parameter aufgerufen

    rem Speichern der Argumente in einer temporären Datei
    echo %* > "%TEMP%\arguments.tmp"

    rem UAC-Erhebung initiieren und das aktuelle Skript mit erhöhten Rechten neu starten
    powershell -ex unrestricted -Command "Start-Process -Verb RunAs -FilePath '%comspec%' -ArgumentList '/k \"%~fnx0\"'"
    rem Beenden des aktuellen Skripts, da es mit erhöhten Rechten erneut ausgeführt wird
    goto :eof
) else (
    rem Fall 2: Das Skript wird mit Administratorrechten und ohne Parameter aufgerufen

    rem Hauptteil des Skripts nach der UAC-Erhebung
    echo Skript wird mit Administratorrechten ausgeführt.

    rem Überprüfen, ob die temporäre Datei existiert und lesen der Argumente
    if exist "%TEMP%\arguments.tmp" (
        rem Überprüfen, ob ein Ordner als Parameter übergeben wurde
        for /f "usebackq delims=" %%a in ("%TEMP%\arguments.tmp") do (
            set "argument=%%~a"rem Anführungszeichen entfernen

            rem Löschen der temporären Datei
            del "%TEMP%\arguments.tmp" >nul 2>&1

            if "%%~a"=="" (
                echo Kein Ordner angegeben.
                goto :eof
            )

            rem Speichern des Quell- und Zielordners in Variablen und Leerzeichen am Ende entfernen
            set "source=%%~a"
            rem Leerzeichen am Ende entfernen
            set "source=!source:~0,-2!"
            set "target=!source:C:=D:!"

            rem Bestätigung vor dem Verschieben des Ordners
            echo Bitte bestätigen Sie den Verschiebevorgang:
            echo Quellordner: !source!
            echo Zielordner: !target!
            set /p confirm=Bestätigen Sie mit Enter, um fortzufahren: 
            if "!confirm!"=="" (
                rem Verschieben des Ordners auf Laufwerk D
                robocopy "!source!" "!target!" /MOVE /E >nul
                
                rem Überprüfen, ob der Zielordner existiert
                if exist "!target!" (
                    rem Erstellen des Symbolic Links (/J) vom alten zum neuen Pfad
                    mklink /J "!source!" "!target!" >nul
                    if errorlevel 1 (
                        echo Fehler beim Erstellen des Symbolic Links.
                        goto :eof
                    )
                    rem Erfolgsmeldung anzeigen
                    echo Ordner wurde erfolgreich verschoben und Symbolischer Link wurde erstellt
                    pause
                ) else (
                    echo Fehler beim Verschieben des Ordners.
                    goto :eof
                )
            ) else (
                echo Verschiebevorgang abgebrochen.
                goto :eof
            )
        )
    ) else (
        rem Die temporäre Datei existiert nicht, es liegen keine Parameter vor
        echo Es liegen keine Parameter vor.
        goto :eof
    )
)

:eof
pause
