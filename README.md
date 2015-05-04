# Deconst Jekyll Preparer

.md :point_right: .json :point_right: :wrench: :point_right: content service

*preparermd* builds each page of a [Jekyll site](http://jekyllrb.com/) into custom JSON metadata envelopes and broadcasts them to a [content service](https://github.com/deconst/content-service) that performs storage and indexing for presentation and search.

It's intended to be used within a CI system to present content to the rest of the build pipeline.

## Running Locally

To run the Jekyll preparer locally, you'll need to install:

 * [Docker](https://docs.docker.com/installation/#installation) for your platform. Choose the boot2docker option for Mac OS X or Windows.

Once you have Docker set up, export any desired configuration variables, run `deconst-preparer-jekyll.sh` with the path of a control repository clone to prepare the Jekyll content found there.

```bash
export CONTENT_STORE_URL=http://my-content-store.com:9000/
export CONTENT_ID_BASE=https://github.com/myorg/myrepo

./deconst-preparer-jekyll.sh /path/to/control-repo
```

### Configuration

The following values must be present in the build environment to submit assets:

 * `CONTENT_STORE_URL` must be the base URL of the publicly available content store service. The prepare script defaults this to one consistent with our docker-compose setups.
 * `CONTENT_ID_BASE` must be set to a prefix that's unique among the content repositories associated with the target deconst instance. Our convention is to use the base URL of the GitHub repository.
 * `TRAVIS_PULL_REQUEST` must be set to `"false"`. Travis automatically sets this value for your build environment on the primary branch of your repository.
