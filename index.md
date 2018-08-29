---
layout: home
---
<div class="hero text-center">
    <div class="container-new px-3">
        <div class="pb-2">
            <h1 class="f00-light text-dark">
                {{ site.title }}
            </h1>
            <p class="col-md-8 mx-auto mb-4 f3-light">
                {{ site.description }}
            </p>
        </div>
    </div>
    <div style="max-width:900px" class="text-center container-new">
        <div class="d-md-flex flex-items-center flex-md-row-reverse mb-3">
            <div class="flex-auto text-md-center col-md-4 p-4 overflow-hidden">
                <div class="anim-fade-up">
                    <img src="{{ site.baseurl }}/public/png/delapan.png" alt="" class="app-screenshot" style="max-width:324px">
                </div>
            </div>
            <div class="flex-auto text-md-left col-md-4 p-4">
                <h4 class="f3-light text-dark text-bold">
                    PDF Direktori Layanan Perpajakan edisi 2018
                </h4>
                <p class="mt-2">
                    Buku Direktori Layanan Perpajakan ini disusun berdasarkan ketentuan peraturan perundang-undangan perpajakan yang berlaku
                    saat penyusunan buku ini.</p>
                <p>Apabila terdapat perbedaan antara isi buku ini dengan ketentuan yang berlaku karena kesalahan tulis atau
                    terjadi perubahan peraturan, maka peraturan perundang-undangan perpajakan yang sedang berlaku menjadi
                    acuan.
                </p>
                <a class="mx-1 my-3 f3 btn btn-large btn-purple" href="http://www.pajak.go.id/sites/default/files/Buku%20De-la-pan%20v.2018%20Edisi%201.pdf"
                    data-for-os="windows" data-download="windows">Download</a>
            </div>
        </div>
        {% include share-button.html %}
        <!-- SECTION -->
    </div>
</div>

<!-- post list -->
<ul>
    {% for post in paginator.posts %}
    <li><a href="{{post.url | prepend: site.baseurl}}">{{post.title}}</a>
        <p>{{ post.excerpt }}</p>
    </li>
    {% endfor %}
</ul>


<!-- pagination -->
{% if paginator.total_pages > 1 %}
<div class="pagination">
    {% if paginator.previous_page %}
    <a href="{{ paginator.previous_page_path | prepend: site.baseurl | replace: '//', '/' }}">&laquo; Prev</a>
    {% else %}
    <span>&laquo; Prev</span>
    {% endif %}

    {% for page in (1..paginator.total_pages) %}
    {% if page == paginator.page %}
    <span class="webjeda">{{ page }}</span>
    {% elsif page == 1 %}
    <a href="/">{{ page }}</a>
    {% else %}
    <a href="{{ site.paginate_path | prepend: site.baseurl | replace: '//', '/' | replace: ':num', page }}">{{ page }}</a>
    {% endif %}
    {% endfor %}

    {% if paginator.next_page %}
    <a href="{{ paginator.next_page_path | prepend: site.baseurl | replace: '//', '/' }}">Next &raquo;</a>
    {% else %}
    <span>Next &raquo;</span>
    {% endif %}
</div>
{% endif %}