# Scripts for managing Continuous Integration services

Automate the process of installing miniconda, setting up a build environment, and
deploying to PyPI and Github Pages from Continuous Integration (CI) services.

[![TravisCI build status](http://img.shields.io/travis/fatiando/continuous-integration/master.svg?style=flat-square&label=TravisCI)](https://travis-ci.org/fatiando/continuous-integration)
[![Azure build status](https://img.shields.io/azure-devops/build/fatiando/01ec751a-085e-4c86-9a39-2c8204668b47/4/master.svg?label=Azure&style=flat-square)](https://dev.azure.com/fatiando/continuous-integration/_build?definitionId=4)
[![Latest release](https://img.shields.io/github/release/fatiando/continuous-integration.svg?style=flat-square)](https://github.com/fatiando/continuous-integration/releases/latest)


## Contents

* [Getting the scripts](#getting-the-scripts)
* [TravisCI (linux|mac)](#travisci)
    * [Miniconda](#miniconda)
    * [Github Pages](#github-pages)
    * [Deploying to PyPI](#deploying-to-pypi)
    * [Releasing](#releasing)
* [Azure Pipelines (win|linux|mac)](#azure-pipelines)


## Getting the scripts

On the CI configuration script, clone a specific release of this repository:

    git clone --branch=VERSION --depth=1 https://github.com/fatiando/continuous-integration.git

Replace `VERSION` with the release you want to use, like `1.0.0`. See the
[Releases page](https://github.com/fatiando/continuous-integration/releases) for a list
of versions available and changes made in each.

We use [**semantic versioning**](https://semver.org/) to mark our releases:

* Major version number change (e.g. `1.2.1 -> 2.0.0`): Break in backward compatibility.
  You will need to update your CI configuration to use this new version.
* Minor version number change (e.g. `1.2.1 -> 1.3.0`): New features/options added
  without breaking existing builds. You can update to the new version without changing
  your configuration.
* Patch version number change (e.g. `1.2.1 -> 1.2.2`): Fix a bug without breaking
  existing builds. You can update to the new version without changing your
  configuration.


## TravisCI

Travis has the option to run jobs on Linux and OSX.
The first thing to do is go to your profile page on https://travis-ci.org and
enable building your repository. New repos can take a while to appear on the
list.

See the sample `.travis.yml` configuration included in this repository.

### Miniconda

Install and setup Miniconda by sourcing the `travis/setup-miniconda.sh` script.
Must use `source` because the script sets the `PATH` environment variable.
This script will download and install the latest miniconda, configure it to use
conda-forge, update conda, create a testing environment, and install
dependencies specified in a requirements file. This last step is optional and
only happens if you specify the name of a requirements file in the environment
variable `CONDA_REQUIREMENTS`.

Include this in the `install` or `before_install` steps in `.travis.yml`:

    source continuous-integration/travis/setup-miniconda.sh

It's a good idea to run `conda list` to print out a full list of packages
installed.

### Github Pages

Our strategy is to have the documentation for different versions (marked by git
tags) in different folder in the `gh-pages` branch. Docs built from *master*
will be placed in a `dev` folder and a `latest` folder is a link to the last
tag build. This way, the project docs can be accessed as
`http://fatiando.org/PROJECT/latest`,  `http://fatiando.org/PROJECT/dev`, or
`http://fatiando.org/PROJECT/0.5`.

#### Setting up your repository

A few steps must be done on your local clone before setting up Travis.
Run the following on your repository clone (**not** in `.travis.yml`).

You must first create an orphan `gh-pages` branch in your repository (skip this
step if it already exists). :

    git checkout --orphan gh-pages
    git rm -rf --cached .

Now create an `index.html` file that will redirect to the content of `latest`:

    echo "<meta http-equiv=\"Refresh\" content=\"0;url=latest/\"/>" > index.html

We need to tell GitHub to not try to build this as a Jekyll site:

    touch .nojekyll
    
Commit this to `gh-pages`:

    git add index.html .nojekyll
    git commit -m "Setup index.html to redirect to 'latest'"

If you want to initially point `latest` to the `dev` build, for example if you haven't
made a release yet):

    mkdir dev
    ln -sf dev latest
    git add dev latest
    git commit -m "Link 'latest' to 'dev' until we make a release"

After that, the first release will update `latest` to link to it instead.

Make sure to push your changes and then go back to master.

#### Getting a Github token

Travis needs a way to write to your repository. This can be done using Github
"personal access tokens". These are unique strings that allow write access to
your repository. **Use them with great care and never commit them to a
repository**. We will use the [Travis command-line
client](https://github.com/travis-ci/travis.rb) to encrypt this token so that
it can only be accessed from a Travis build.

First, go install the Travis command-line client.
Then, go to https://github.com/settings/tokens and generate a new token and
give it access to your public repositories.

Now, on the master branch of your repository run (replacing `YOUR_TOKEN_HERE`
with the token you just got from Github):

    travis encrypt GH_TOKEN=YOUR_TOKEN_HERE

This will generate a big jumble of characters that is your encrypted token.
Include it in `.travis.yml`:

    env:
        global:
            # Github token (GH_TOKEN)
            - secure: "BIG JUMBLE OF CHARACTERS"

This jumble will be decrypted by Travis and assigned to the `GH_TOKEN`
environment variable.

Again, **be very careful not to reveal your token**. Make sure you pasted the
**encrypted** version in `.travis.yml`. If you suspect that your token was
revealed, go to https://github.com/settings/tokens and delete it immediately.
It's also a good idea to change your Github password.

#### Deploy

Now that you have a `gh-pages` branch and an encrypted token, setup a `deploy`
action in `.travis.yml` to push the built HTML. The deploy will only happen if
the build is on the *master* branch or a *tag* (meaning a release).

    deploy:
        # Push the built HTML in doc/_build/html to the gh-pages branch
        - provider: script
          script: continuous-integration/travis/deploy-gh-pages.sh
          skip_cleanup: true
          on:
              branch: master
              condition: '$DEPLOY_DOCS == "true"'
        # Push HTML when building tags as well
        - provider: script
          script: continuous-integration/travis/deploy-gh-pages.sh
          skip_cleanup: true
          on:
              tags: true
              condition: '$DEPLOY_DOCS == "true"'

You must also set the environment variable `DEPLOY_DOCS` to `true` in the build
that you want to deploy. This is to avoid deploying more than once in case your
testing using different package versions or OS.

### Deploying to PyPI

Uploading source distributions and wheels to PyPI can happen automatically when
a git tag is built by Travis. The `travis/deploy.pypi.sh` script generates
source distributions and wheels and uploads them using
[twine](https://pypi.org/project/twine/).

You must first encrypt your https://pypi.org/ password using the [same method
we used to encrypt the token above](#getting-a-github-token):

    travis encrypt TWINE_PASSWORD=YOUR_PASSWORD

Again copy the jumble of characters to `.travis.yml` in the `env` block. Also
create an environment variable with your user name (you can encrypt this as
well if you want).

    env:
        global:
            # PyPI password (TWINE_PASSWORD)
            - secure: "BIG JUMBLE OF CHARACTERS"
            # PyPI user (TWINE_USERNAME)
            - TWINE_USERNAME=your-user-name

Finally, setup a deploy action in your `.travis.yml` (append to an existing one
if it exists):

    deploy:
        # Make a release on PyPI
        - provider: script
          script: continuous-integration/travis/deploy-pypi.sh
          on:
              tags: true
              condition: '$DEPLOY_PYPI == "true"'

You must also set the environment variable `DEPLOY_PYPI` to `true` in the build
that you want to deploy. This is to avoid deploying more than once in case your
testing using different package versions or OS.

### Releasing

Now you can make a release by simply tagging a commit with a version number.
TravisCI will create a new folder in the HTML documentation and upload the
built package to PyPI.

## Azure Pipelines

Pipelines is the new CI service by Microsoft Azure. It works on all three platforms and
is a lot faster than AppVeyor or TravisCI (for Mac). Setup is a bit more complicated and
requires setting up a few layers if you've never used Azure before. You'll also need a
Microsoft account (free).

We provide a sample configuration file in `.azure-pipelines.yml` that sets up up jobs
for all three platforms.
After you've setup a branch with the configuration files in your repository:

1. Go to https://dev.azure.com
2. Create an organization (if you haven't already). Fatiando projects are in the
   `fatiando` organization. Open an issue here to request access.
3. Create a project for your repository in the organization. Use the repository name as
   the project name.
4. Create a new pipeline in your project and select the configuration file in your new
   branch.
5. Run the pipeline

After this, the pipelines should start automatically with new updates to PRs and the
master branch.
