---
layout: post
title: Indexing GeoNames into Solr
tags:
 - solr
 - geonames
---

This post walks through a quick and easy way to index [GeoNames.org](http://geonames.org) locations into Solr 5.2.1. It uses the Solr default configuration for the `gettingstarted` collection. 

For more on Solr [collections vs cores](http://wiki.apache.org/solr/SolrCloud#Glossary).

<div class="message">
  The first part of this post is borrowed from the <a href="http://lucene.apache.org/solr/quickstart.html">Solr quickstart</a>
</div>

## Getting Solr 5.2.1 up and going

[Download](http://www.apache.org/dyn/closer.cgi/lucene/solr/5.2.1) and unzip Solr 5.2.1

{% highlight sh %}
$ ls solr*
solr-5.2.1.zip
$ unzip -q solr-5.2.1.zip
$ cd solr-5.2.1/
{% endhighlight %}

Start Solr

{% highlight sh %}
$ bin/solr start -e cloud -noprompt
{% endhighlight %}

You should now be able to successfully navigate to [http://127.0.0.1:8983/solr](http://127.0.0.1:8983/solr)

## Formatting GeoNames.org data for Solr

GeoNames provides several data download types available on [their website](http://download.geonames.org/export/dump/). This post will focus on indexing `allCountries.txt` which includes all features from GeoNames. This file unzipped is ~1.2 GB which could be troublesome for some. Beginning users may want to start with a smaller dataset such as `cities1000.txt` which is a smaller subset of the GeoNames data.

Someone out there probably could do all of this in an awesome one liner. These steps are broken up for better understanding of whats going on. We first need to format the GeoNames data into something that is indexable into Solr.

### Download and unzip allCountries.zip

[Download](http://download.geonames.org/export/dump/allCountries.zip) available from GeoNames.

{% highlight sh %}
$ unzip -q allCountries.zip
{% endhighlight %}

`allCountries.txt` comes in a tab-delimited text file in utf-8 encoding. The following fields are provided:

Field | Description
----- | -----------
geonameid | integer id of record in geonames database
name | name of geographical point (utf8) varchar(200)
asciiname | name of geographical point in plain ascii characters, varchar(200)
alternatenames | alternatenames, comma separated, ascii names automatically transliterated, convenience attribute from alternatename table, varchar(10000)
latitude | latitude in decimal degrees (wgs84)
longitude | longitude in decimal degrees (wgs84)
more ... | we don't need the rest of these

We won't use most of these columns, so let's get rid of the ones we don't need.

### Get rid of columns we don't need

We only need the 1st, 2nd, 5th, and 6th columns.

{% highlight sh %}
$ cut  -f1-2,5-6 allCountries.txt > allCountries_red.txt
{% endhighlight %}

### Add a header row

Add in a header row to the tsv text file. Note, whitespace delimiters (between `id`, `title_t`, `lat`, `lng`) should be tab literals.
{% highlight sh %}
$ sed '1s/^/id  title_t lat lng\
/g' allCountries_red.txt > allCountries_head.txt
{% endhighlight %}

### Add a WKT column

This command requires the [csvpys](https://github.com/cypreess/csvkit/blob/master/docs/scripts/csvpys.rst) version of csvkit software. Running the command will create a new WKT point column `loc_srpt` using the existing `lat` and `lng` columns. `*_srpt` is a [Spatial Recursive Prefix Tree Field Type](https://cwiki.apache.org/confluence/display/solr/Spatial+Search#SpatialSearch-SpatialRecursivePrefixTreeFieldType(abbreviatedasRPT)) dynamic Solr field shipped with the default `gettingstarted` Solr schema.

{% highlight sh %}
$ csvpys --tab -s loc_srpt "'POINT(' + ch['lng'] + ' ' + ch['lat'] + ')'" allCountries_head.txt > allCountries_wkt.txt
{% endhighlight %}

### Only keep the columns we need

Get rid of the `lat` and `lng` columns
{% highlight sh %}
$ csvcut -c 1,2,5 allCountries_wkt.txt > allCountries_wkt_cut.txt
{% endhighlight %}

### Convert the tsv to json

{% highlight sh %}
$ csvjson -i 2 allCountries_wkt_cut.txt > allCountries.json
{% endhighlight %}

## Index into Solr

If you are doing this using the full `allCountries.txt` file, this command can take a while (at least 5 minutes). This command will index over 10 million records into your Solr index. You can check the status of this command by seeing if the document counts in your Solr collection are increasing. You can see this by using the [Solr admin](http://127.0.0.1:8983/solr/#) interface.
{% highlight sh %}
$ curl 'http://localhost:8983/solr/gettingstarted/update?commit=true' --data-binary @allCountries.json -H 'Content-type:application/json'
{% endhighlight %}

You should now have your GeoNames data indexed in Solr!

Checkout a [Solr query](http://127.0.0.1:8983/solr/gettingstarted/select?q=*:*&wt=json&indent=true).

{% highlight js %}
// http://127.0.0.1:8983/solr/gettingstarted/select?q=*:*&wt=json&indent=true
{
  "responseHeader":{
    "status":0,
    "QTime":39,
    "params":{
      "indent":"true",
      "q":"*:*",
      "wt":"json"}},
  "response":{"numFound":144573,"start":0,"maxScore":1.0,"docs":[
      {
        "title_t":["El Tarter"],
        "id":"3039154",
        "loc_srpt":"POINT(1.65362 42.57952)",
        "_version_":1504146876751937536},
      {
        "title_t":["Sant Julià de Lòria"],
        "id":"3039163",
        "loc_srpt":"POINT(1.49129 42.46372)",
        "_version_":1504146876821143552},
      {
        "title_t":["Pas de la Casa"],
        "id":"3039604",
        "loc_srpt":"POINT(1.73361 42.54277)",
        "_version_":1504146876823240704},
      ...
  }
}
{% endhighlight %}

You can now do all sorts of fun spatial search things in Solr!