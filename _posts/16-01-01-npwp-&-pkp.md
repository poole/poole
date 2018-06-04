---
anchor: npwp_pkp
---

# NPWP & PKP {#npwp_pkp}

<nav class="site-navigation">
            <input type="checkbox" id="toggle"/>
            <label for="toggle">Table of Contents</label>
            <ul>
                {% comment %}
                <li><a href="/#welcome">Welcome</a>
                    <ul>
                        <li><a href="/#translations">Translations</a></li>
                        <li><a href="/#how-to-contribute">How to Contribute</a></li>
                        <li><a href="/#spread-the-word">Spread the Word!</a></li>
                    </ul>
                </li>
                {% endcomment %}
                {% assign lastIsChild = false %}
                {% for post in site.posts reversed %}
                    {% if post.isChild != true %}
                        {% if insideSection %}
                            </ul>
                            </li>
                            {% assign insideSection = false %}
                        {% endif %}
                    {% endif %}
                    <li><a href="{{ site.url }}{{ post.url }}">{{ post.title }}</a>
                    {% if post.isChild %}
                        </li>
                    {% else %}
                        <ul>
                        {% assign insideSection = true %}
                    {% endif %}
                    {% assign lastIsChild = post.isChild %}
                {% endfor %}
                    </ul>
                </li>
            </ul>
        </nav>