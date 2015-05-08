# Deconst Jekyll Preparer

.md :point_right: .json :point_right: :wrench: :point_right: content service

[![Docker Repository on Quay.io](https://quay.io/repository/deconst/preparer-jekyll/status "Docker Repository on Quay.io")](https://quay.io/repository/deconst/preparer-jekyll)

*preparermd* builds each page of a [Jekyll site](http://jekyllrb.com/) into custom JSON metadata envelopes and broadcasts them to a [content service](https://github.com/deconst/content-service) that performs storage and indexing for presentation and search.

It's intended to be used within a CI system to present content to the rest of the build pipeline.

## Running Locally

To run the Jekyll preparer locally, you'll need to install:

 * [Docker](https://docs.docker.com/installation/#installation) for your platform. Choose the boot2docker option for Mac OS X or Windows.

Once you have Docker set up, export any desired configuration variables, run `deconst-preparer-jekyll.sh` with the path of a control repository clone to prepare the Jekyll content found there.

```bash
export CONTENT_STORE_URL=http://my-content-store.com:9000/
export CONTENT_STORE_APIKEY="cd54a09f6593cb5b17177..."
export CONTENT_ID_BASE=https://github.com/myorg/myrepo

./deconst-preparer-jekyll.sh /path/to/content-repo
```

### Configuration

The following values must be present in the build environment to submit assets:

 * `CONTENT_STORE_URL` must be the base URL of the publicly available content store service. The prepare script defaults this to one consistent with our docker-compose setups.
 * `CONTENT_STORE_APIKEY` must be a valid API key issued by the content service. See [the content service documentation](https://github.com/deconst/content-service#post-keysnamedname) for instructions on generating an API key.
 * `CONTENT_ID_BASE` must be set to a prefix that's unique among the content repositories associated with the target deconst instance. Our convention is to use the base URL of the GitHub repository.
 * `TRAVIS_PULL_REQUEST` must be set to `"false"`. Travis automatically sets this value for your build environment on the primary branch of your repository.

## Markdown integration

The Deconst layout key for any Jekyll page can be controlled explicitly by setting the `deconst_layout` attribute in its frontmatter. If `deconst_layout` is not present, the page's Jekyll
`layout` name will be used.

Other frontmatter keys that have special meaning to Deconst include:

 * `title`
 * `categories`
 * `tags`
 * `author`
 * `bio`
 * `date`
 * `disqus`. If present, this must be a dictionary containing `short_name` or `mode` subattributes:
   * `short_name` will be used as the Disqus "short name", used to identify the associated Disqus account.
   * `mode` must be either `count` or `embed`. If unspecified,

All of these keys are optional. If present, each will be included within the metadata envelope generated for that page, and will be made available to the Handlebars templates in the control repository for rendering.

`disqus_short_name` and `disqus_default_mode` may also be specified globally in the Jekyll site's `_config.yml` file. If so, Disqus attributes will be included in *all* metadata envelopes generated from this content repository. `disqus` settings present in a specific page will override the site-global settings for that page.
