REM Configure and update conda, then install the dependencies into a new environment
REM using the file specified in the CONDA_REQUIREMENTS variable.

REM Enable extensions to use the IF DEFINED command
REM From http://www.robvanderwoude.com/battech_defined.php
VERIFY OTHER 2>nul
SETLOCAL ENABLEEXTENSIONS
IF ERRORLEVEL 1 ECHO Unable to enable extensions

ECHO.
ECHO Configuring conda
ECHO ===============================================
REM Don't change the prompt or request user input
conda config --set always_yes yes --set changeps1 no
REM Add conda-forge to the top of the channel list
conda config --add channels conda-forge

ECHO.
ECHO Updating conda
ECHO ===============================================
conda update --quiet conda

ECHO.
ECHO Creating the 'testing' environment
ECHO ===============================================
conda create --quiet --name testing python="%PYTHON%" pip
REM Need to use call in batch scripts: https://github.com/conda/conda/issues/794
call activate testing

ECHO.
ECHO Updating pip
ECHO ===============================================
python -m pip install --upgrade pip

ECHO.
ECHO Installing requirements from file
ECHO ===============================================
IF DEFINED REQUIREMENTS (conda install --quiet --channel conda-forge --file %REQUIREMENTS%) ELSE (ECHO No requirements file set)
IF DEFINED REQUIREMENTS_DEV (conda install --quiet --channel conda-forge --file %REQUIREMENTS_DEV%) ELSE (ECHO No requirements file set)

REM Check if the Python version is still correct
python -c "import sys; assert sys.version_info[:2] == tuple(int(i) for i in '%PYTHON%'.split('.'))"

ENDLOCAL
