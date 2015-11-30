# Deconst Jekyll Preparer

.md :point_right: .json :point_right: :wrench: :point_right: content service

[![Build Status](https://travis-ci.org/deconst/preparer-jekyll.svg?branch=master)](https://travis-ci.org/deconst/preparer-jekyll)
[![Docker Repository on Quay.io](https://quay.io/repository/deconst/preparer-jekyll/status "Docker Repository on Quay.io")](https://quay.io/repository/deconst/preparer-jekyll)

*preparermd* builds each page of a [Jekyll site](http://jekyllrb.com/) into custom JSON metadata envelopes and broadcasts them to a [content service](https://github.com/deconst/content-service) that performs storage and indexing for presentation and search.

It's intended to be used within a CI system to present content to the rest of the build pipeline.

## Running Locally

To run the Jekyll preparer locally, you'll need to install:

 * [Docker](https://docs.docker.com/installation/#installation) for your platform. Choose the boot2docker option for Mac OS X or Windows.
 * [Docker Compose](https://docs.docker.com/compose/install/)

Once you have Docker set up, create a copy of the file `env.example` named `env` and customize it with your Rackspace credentials, container names, local content service API Key, and path to your Jekyll repo.

Run the preparer to build the Jekyll site and submit content to the content service:

```
bin/submit [document-path]
```

When the `document-path` argument is provided, only that page will be submitted to the content service. This can be useful when debugging things on a large site. `document-path` should be a root-relative URL, such as `/blog/index.html`. When `document-path` is not provided, all pages and assets in the site will be submitted to the content service.

### Configuration

The following values must be present in the build environment to submit assets:

 * `CONTENT_STORE_URL` must be the base URL of the publicly available content store service. The prepare script defaults this to one consistent with our docker-compose setups.
 * `CONTENT_STORE_APIKEY` must be a valid API key issued by the content service. See [the content service documentation](https://github.com/deconst/content-service#post-keysnamedname) for instructions on generating an API key.
 * `CONTENT_STORE_TLS_VERIFY` may be set to `"false"` to disable certificate verification. 🚨 *Only use this feature for development and local clusters with self-signed certificates. It defeats a lot of the point of encrypting traffic.* 🚨
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
   * `mode` must be either `count` or `embed`. If unspecified, will default to `embed`.
 * `content_type`

All of these keys are optional. If present, each will be included within the metadata envelope generated for that page, and will be made available to the Handlebars templates in the control repository for rendering.

`disqus_short_name` and `disqus_default_mode` may also be specified globally in the Jekyll site's `_config.yml` file. If so, Disqus attributes will be included in *all* metadata envelopes generated from this content repository. `disqus` settings present in a specific page will override the site-global settings for that page.
