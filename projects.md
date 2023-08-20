---
layout: page
title: Projects
permalink: /_posts/
---

Every once in a while I write things on here:

{% for post in site.posts %}
  * {{ post.date | date_to_string }} &nbsp; &nbsp; [ {{ post.title }} ]({{ post.url }})
{% endfor %}