---
layout: page
title: projects
permalink: /projects
---

Some things I've worked on:

{% for post in site.posts %}
  * {{ post.date | date_to_string }} &nbsp; &nbsp; [ {{ post.title }} ]({{ post.url }})
{% endfor %}