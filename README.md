# DEPRECATED. Use https://gitlab.com/deconst-next/preparer-jekyll

## Deconst Jekyll Preparer

.md :point_right: .json :point_right: :wrench: :point_right: content service

[![Build Status](https://travis-ci.org/deconst/preparer-jekyll.svg?branch=master)](https://travis-ci.org/deconst/preparer-jekyll)
[![Docker Repository on Quay.io](https://quay.io/repository/deconst/preparer-jekyll/status "Docker Repository on Quay.io")](https://quay.io/repository/deconst/preparer-jekyll)

*deconst-preparer-jekyll* builds each page of a [Jekyll site](http://jekyllrb.com/) into custom JSON metadata envelopes and broadcasts them to a [content service](https://github.com/deconst/content-service) that performs storage and indexing for presentation and search.

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

 * `ENVELOPE_DIR` must be set to a directory that metadata envelopes should be written to.
 * `ASSET_DIR` must be set to a directory that assets should be written to.
 * `CONTENT_ID_BASE` must be set to a prefix that's unique among the content repositories associated with the target deconst instance. Our convention is to use the base URL of the GitHub repository.
 * `TRAVIS_PULL_REQUEST` must be set to `"false"`. Travis automatically sets this value for your build environment on the primary branch of your repository.

## Markdown integration

The Deconst layout key for any Jekyll page can be controlled explicitly by setting the `deconst_layout` attribute in its frontmatter. If `deconst_layout` is not present, the page's Jekyll
`layout` name will be used.

Other frontmatter keys that have special meaning to Deconst include:

 * `title`
 * `categories`
 * `deconst_categories`
 * `tags`
 * `author`
 * `bio`
 * `date`
 * `disqus`. If present, this must be a dictionary containing `short_name` or `mode` subattributes:
   * `short_name` will be used as the Disqus "short name", used to identify the associated Disqus account.
   * `mode` must be either `count` or `embed`. If unspecified, will default to `embed`.
 * `content_type`
 * `unsearchable` may be `true` to exclude this document from full-text search indexing.

All of these keys are optional. If present, each will be included within the metadata envelope generated for that page, and will be made available to the Handlebars templates in the control repository for rendering.

Some keys may be set globally for the repository in your `_config.yml` file:

 * `deconst_default_unsearchable` will set the default value of `unsearchable` for all documents.
 * `deconst_tags` specifies tags that should be set on *all* documents within this repository. Tags listed here will be merged with tags specified on individual documents.
 * `deconst_post_tags` is similar, but only for blog posts (in `_posts/`). `deconst_page_tags` applies to non-posts instead.
 * `deconst_categories` will globally apply one or more categories to each generated envelope.

`disqus_short_name` and `disqus_default_mode` may also be specified globally in the Jekyll site's `_config.yml` file. If so, Disqus attributes will be included in *all* metadata envelopes generated from this content repository. `disqus` settings present in a specific page will override the site-global settings for that page.
