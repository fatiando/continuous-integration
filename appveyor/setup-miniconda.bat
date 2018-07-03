REM Configure and update conda, then install the dependencies into a new environment
REM using the file specified in the CONDA_REQUIREMENTS variable.

REM Enable extensions to use the IF DEFINED command
REM From http://www.robvanderwoude.com/battech_defined.php
VERIFY OTHER 2>nul
SETLOCAL ENABLEEXTENSIONS
IF ERRORLEVEL 1 ECHO Unable to enable extensions

REM Don't change the prompt or request user input
conda config --set always_yes yes --set changeps1 no

REM Add conda-forge to the top of the channel list
conda config --add channels conda-forge

ECHO Updating conda
ECHO ===============================================
conda update --quiet conda

ECHO Creating the 'testing' environment
ECHO ===============================================
conda create --quiet --name testing python="%PYTHON%" pip
activate testing

ECHO Installing requirements from file
ECHO ===============================================
IF DEFINED CONDA_REQUIREMENTS (conda install --quiet --file %CONDA_REQUIREMENTS%) ELSE (ECHO No requirements file set)

ENDLOCAL
