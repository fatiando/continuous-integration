#!/bin/bash
# Installs Miniconda (Python 3), set's the PATH, updates conda, configures to
# use conda-forge, creates a "testing" environment and activates it, and
# installs dependencies from a requirements file (given in CONDA_REQUIREMENTS)

# To return a failure if any commands inside fail
set -e

MINICONDA_URL="http://repo.continuum.io/miniconda"

if [ "$TRAVIS_OS_NAME" == "osx" ]; then
    MINICONDA_FILE=Miniconda3-latest-MacOSX-x86_64.sh
else
    MINICONDA_FILE=Miniconda3-latest-Linux-x86_64.sh
fi

CONDA_PREFIX=$HOME/miniconda

# Download and install miniconda
wget $MINICONDA_URL/$MINICONDA_FILE -O miniconda.sh
bash miniconda.sh -b -p $CONDA_PREFIX

# Add it to the path
export PATH="$CONDA_PREFIX/bin:$PATH"

# Don't change the prompt or request user input
conda config --set always_yes yes --set changeps1 no

# Add conda-forge to the top of the channel list
conda config --add channels conda-forge

# Update conda to the latest version
conda update conda --quiet

# Create and activate an environment for testing
conda create --quiet --name testing python=$PYTHON pip
source activate testing

# Install dependencies if a requirements file is specified
if [ ! -z "$CONDA_REQUIREMENTS" ]; then
    conda install --quiet --file $CONDA_REQUIREMENTS
fi

# Workaround for https://github.com/travis-ci/travis-ci/issues/6522
# Turn off exit on failure.
set +e
