# Deconst Jekyll Preparer

.md :point_right: .json :point_right: :wrench: :point_right: content service

*preparermd* builds each page of a [Jekyll site](http://jekyllrb.com/) into custom JSON metadata envelopes and broadcasts them to a [content service](https://github.com/deconst/content-service) that performs storage and indexing for presentation and search.

It's intended to be used within a CI system to present content to the rest of the build pipeline.
