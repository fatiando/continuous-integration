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
ECHO Installing requirements from file %CONDA_REQUIREMENTS%
ECHO ===============================================
IF DEFINED CONDA_REQUIREMENTS (conda install --quiet --channel conda-forge --file %CONDA_REQUIREMENTS% python="%PYTHON%") ELSE (ECHO No requirements file set)
ECHO.
ECHO Installing requirements from file %CONDA_REQUIREMENTS_DEV%
ECHO ===============================================
IF DEFINED CONDA_REQUIREMENTS_DEV (conda install --quiet --channel conda-forge --file %CONDA_REQUIREMENTS_DEV% python="%PYTHON%") ELSE (ECHO No requirements file set)

ECHO.
ECHO Check that Python really is %PYTHON%
ECHO ===============================================
REM Check if the Python version is still correct after installing all dependencies
python -c "import sys; assert sys.version_info[:2] == tuple(int(i) for i in '%PYTHON%'.split('.'))"

ENDLOCAL
