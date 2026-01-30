@echo off
REM CALMA - Instalador de Dependencias para Windows
REM Execute este ficheiro para instalar todas as dependencias

echo.
echo ==========================================
echo    CALMA - Instalador de Dependencias
echo ==========================================
echo.

REM Verificar se Python esta instalado
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Python nao encontrado!
    echo.
    echo Por favor, instale Python 3.8 ou superior:
    echo https://www.python.org/downloads/
    echo.
    echo Certifique-se de marcar "Add Python to PATH" durante a instalacao.
    pause
    exit /b 1
)

REM Executar o instalador Python
echo A iniciar instalacao...
echo.
python "%~dp0install.py"

if errorlevel 1 (
    echo.
    echo [ERRO] A instalacao falhou!
    pause
    exit /b 1
)

echo.
pause
