---
layout: post
title: Using Solr Facet Heatmap with 10 Million GeoNames
---

A recent addition in Solr 5.1 is a new type of facet ability, [Heatmap Faceting](https://cwiki.apache.org/confluence/display/solr/Spatial+Search#SpatialSearch-HeatmapFaceting). It looks like this is another great addition added to Solr by [David Smiley](https://twitter.com/davidwsmiley). I was excited to see this feature in the release notes but was curious about the practicality and performance.

## Heatmap Facet basics

The Heatmap Facet will return a grid of counts for documents over a given area. The return type defaults to a 2D array of values, but can also be returned as a 4-byte PNG. These type of return values can be used to generate a heatmap visualization of result hits. Additionally, the Heatmap Facet will take several parameters that modify how the heatmap is calculated or returned. For my experimentation purposes I have only been using the `facet.heatmap.geom` parameter. `facet.heatmap.geom` will limit the region that the heatmap is computed on.

## Indexing spatial data

I knew that I was going to want to put this feature through some performance trials, so I opted to start with large corpus of spatial data, the [GeoNames.org](http://geonames.org) seemed like a suitable dataset to start with. More on indexing GeoNames data into Solr in another post.

## Heatmap requests and returns

For this blogpost, I only dealt with the Solr Heatmap Facet return using the 2D array of hit counts. The basic idea of the feature is that I can request a bounding area, and get return hit counts for items within that area.

### An example request

A basic Facet Heatmap request:

```
http://localhost:8983/solr/[core-name]/select?facet=true&facet.heatmap=[Solr Geometry Field]
```

This request, asks for a heatmap facet for the entire world.


### An example return

## Visualizing with Leaflet.js

