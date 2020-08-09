@echo off

if exist %1.obj del b64.obj
if exist %1.exe del b64.exe

: -----------------------------------------
: assemble b64.asm into an OBJ file
: -----------------------------------------
\MASM32\BIN\Ml.exe /c /coff b64.asm
if errorlevel 1 goto errasm

: -----------------------
: link the main OBJ file
: -----------------------
\MASM32\BIN\PoLink.exe /SUBSYSTEM:WINDOWS /merge:.data=.text b64.obj > nul
if errorlevel 1 goto errlink
goto TheEnd

:errlink
: ----------------------------------------------------
: display message if there is an error during linking
: ----------------------------------------------------
echo.
echo There has been an error while linking this project.
echo.
goto TheEnd

:errasm
: -----------------------------------------------------
: display message if there is an error during assembly
: -----------------------------------------------------
echo.
echo There has been an error while assembling this project.
echo.
goto TheEnd

:TheEnd


