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