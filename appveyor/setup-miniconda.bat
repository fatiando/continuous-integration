REM Configure and update conda, then install the dependencies into a new environment
REM using the file specified in the CONDA_REQUIREMENTS variable.

REM Enable extensions to use the IF DEFINED command
REM From http://www.robvanderwoude.com/battech_defined.php
VERIFY OTHER 2>nul
SETLOCAL ENABLEEXTENSIONS
IF ERRORLEVEL 1 ECHO Unable to enable extensions

ECHO/
ECHO Configuring conda
ECHO ===============================================
REM Don't change the prompt or request user input
conda config --set always_yes yes --set changeps1 no

REM Add conda-forge to the top of the channel list
conda config --prepend channels conda-forge
conda config --remove channels defaults
REM Add an extra channel that may be required
IF DEFINED CONDA_EXTRA_CHANNEL (
    conda config --append channels %CONDA_EXTRA_CHANNEL%
) ELSE (
    ECHO Not setting extra channels
)

REM Display all configuration options for diagnosis
conda config --show

ECHO/
ECHO Updating conda
ECHO ===============================================
conda update --quiet conda

ECHO/
ECHO Creating the 'testing' environment with python=%PYTHON%
ECHO ===============================================
conda create --quiet --name testing python="%PYTHON%" pip
REM Need to use call in batch scripts: https://github.com/conda/conda/issues/794
call activate testing

ECHO/
ECHO Installing dependencies
ECHO ===============================================
SET requirements_file=full-conda-requirements.txt
IF DEFINED CONDA_REQUIREMENTS (
    ECHO Capturing dependencies from %CONDA_REQUIREMENTS%
    TYPE %CONDA_REQUIREMENTS% >> %requirements_file%
)
IF DEFINED CONDA_REQUIREMENTS_DEV (
    ECHO Capturing dependencies from %CONDA_REQUIREMENTS_DEV%
    TYPE %CONDA_REQUIREMENTS_DEV% >> %requirements_file%
)
IF EXIST "%requirements_file%" (
    ECHO Installing collected dependencies:
    TYPE %requirements_file%
    IF DEFINED CONDA_REQUIREMENTS_DEV (
        ECHO %CONDA_INSTALL_EXTRA%
    )
    conda install --quiet --file %requirements_file% python=%PYTHON% %CONDA_INSTALL_EXTRA%
) ELSE (
    ECHO No requirements files defined.
)

REM Check if the Python version is still correct after installing all dependencies
ECHO/
ECHO Check that Python really is %PYTHON%
python -c "import sys; assert sys.version_info[:2] == tuple(int(i) for i in '%PYTHON%'.split('.'))"

ENDLOCAL
