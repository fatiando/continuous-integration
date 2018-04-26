# Scripts for managing Continuous Integration services

Automate the process of installing miniconda and deploying to PyPI and Github
pages.

## TravisCI

### Getting the scripts

Clone this repository in the `install` or `before_install` steps in
`.travis.yml`:

    git clone https://github.com/fatiando/continuous-integration.git


### Miniconda

Install Miniconda by sourcing the `travis/install-miniconda.sh` script. Must
use `source` because the script sets the `PATH` environment variable. Include
this in the `install` or `before_install` steps in `.travis.yml`:

    source continuous-integration/travis/install-miniconda.sh


### Deploy to Github pages

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

Now create an `index.html` file that will redirect to the content of `latest`:

    echo "<meta http-equiv=\"Refresh\" content=\"0;url=latest/\"/>" > index.html

Commit this to `gh-pages`:

    git add index.html
    git commit -m "Setup index.html to redirect to 'latest'"

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
