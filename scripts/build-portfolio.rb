# encoding: UTF-8
Encoding.default_external = Encoding::UTF_8
require 'json'
require 'cgi'
root = File.expand_path('..', __dir__)
items = JSON.parse(File.read(File.join(root, 'tmp/portfolio/import.json'), encoding: 'UTF-8'))
labels = {'pilates'=>'Pilates & wellness','fintech'=>'Fintech & trading','eventy'=>'Eventy','sport'=>'Tenis & sport','taniec'=>'Taniec','nieruchomosci'=>'Nieruchomości','beauty'=>'Beauty','optyka'=>'Optyk'}
presentation_path = File.join(root, 'scripts/portfolio-presentation.json')
presentation = File.file?(presentation_path) ? JSON.parse(File.read(presentation_path, encoding: 'UTF-8')) : {'order'=>[], 'videos'=>{}}
presentation.fetch('videos', {}).each do |id, settings|
  item = items.find { |entry| entry['id'] == id }
  item.merge!(settings) if item
end
order = presentation.fetch('order', [])
items.sort_by! { |entry| order.index(entry['id']) || order.size }
labels.select! { |id, label| items.any? { |entry| entry['category'] == id } }
esc = ->(s){CGI.escapeHTML(s.to_s)}
buttons = [['all','Wszystkie']] + labels.to_a
filters = buttons.map do |id,label|
  count = id == 'all' ? items.size : items.count{|e|e['category']==id}
  %(<button type="button" class="portfolio-filter" data-filter="#{id}" aria-pressed="#{id=='all'}" aria-controls="portfolio-grid">#{esc.call(label)} <span>#{count}</span></button>)
end.join("\n")
cards = items.each_with_index.map do |item,index|
  category = esc.call(item['category']);title = esc.call(item['title']);description = esc.call(item['description']);src=esc.call(item['src']);badge=item['kind']=='video' ? 'WIDEO' : 'GRAFIKA';badge='ZDJĘCIE' if item['id']=='allincamp-grupa'
  if item['kind']=='video'
    seconds=item.fetch('duration'); duration="#{seconds/60}:#{format('%02d',seconds%60)}"
poster = item['poster']
image = poster ? %(<img class="portfolio-poster" src="#{esc.call(poster)}" alt="" loading="lazy" decoding="async" width="#{item.fetch('width', 720)}" height="#{item.fetch('height', 1280)}"/>) : ''
visual=<<~HTML
<div class="portfolio-visual portfolio-video#{poster ? ' has-poster' : ''}" data-video-card>
  <button type="button" class="portfolio-play" data-video-src="#{src}" aria-label="Odtwórz: #{title}">
    #{image}
    <span class="portfolio-duration">#{duration}</span>
    <span class="portfolio-cover-title">#{title.sub(' · ', '<br/>')}</span>
    <span class="portfolio-play-circle" aria-hidden="true">▶</span>
    <span class="portfolio-play-caption">Obejrzyj rolkę</span>
  </button>
  <video controls playsinline preload="none"#{poster ? %( poster="#{esc.call(poster)}") : ''} aria-label="#{title}" hidden></video>
  <p class="portfolio-video-error" hidden>Nie udało się odtworzyć filmu. <a href="#{src}">Otwórz plik wideo ↗</a></p>
</div>
HTML
  else
    visual=%(<a class="portfolio-visual portfolio-image" href="#{src}" data-gallery-image aria-label="Powiększ: #{title}"><img src="#{src}" alt="#{title}" loading="lazy" decoding="async"/><span class="portfolio-enlarge" aria-hidden="true">Powiększ ↗</span></a>)
  end
  %(<article class="portfolio-item"#{index >= 3 ? " hidden" : ""} data-category="#{category}" data-asset-id="#{esc.call(item['id'])}"><div class="portfolio-item-top"><span>#{esc.call(labels[item['category']])}</span><span>#{badge}</span></div>#{visual}<h3>#{title}</h3><p>#{description}</p></article>)
end.join("\n")
gallery = <<~HTML
<section class="portfolio-gallery section-pad" id="realizacje" aria-labelledby="portfolio-title">
<div class="section-heading reveal"><div><p class="eyebrow">OD POMYSŁU DO PUBLIKACJI</p><h2 id="portfolio-title">Moja praca.<br/><em>W konkretnych kadrach.</em></h2></div><p>To tylko wybrane realizacje z mojego portfolio.<br/>Rolki, kampanie i materiały z wydarzeń.</p></div>
<div class="portfolio-filters" role="group" aria-label="Wybierz temat realizacji">#{filters}</div>
<p class="portfolio-results" role="status" aria-live="polite">Wszystkie — pokazuję #{[3, items.size].min} z #{items.size} realizacji</p>
<div class="portfolio-grid" id="portfolio-grid">#{cards}</div>
<p class="portfolio-watch-note">Wybierz temat i zajrzyj do środka. Grafiki możesz powiększyć, a filmy odtworzyć z dźwiękiem.</p>
<noscript><style>.portfolio-item[hidden]{display:block!important}.portfolio-filters,.portfolio-results{display:none}.portfolio-video{display:none}</style><p>Pełny podgląd wideo wymaga JavaScript.</p></noscript>
<dialog class="portfolio-lightbox" aria-label="Podgląd realizacji"><button type="button" class="portfolio-lightbox-close" aria-label="Zamknij podgląd">Zamknij ×</button><img alt=""/><p></p></dialog>
</section>
HTML
htmlpath = File.join(root,'dist/index.html')
html = File.read(htmlpath, encoding: 'UTF-8')
if html.include?('id="realizacje"')
  html.sub!(/<section class="portfolio-gallery.*?<\/section>/m, gallery)
else
  raise 'Missing gallery' unless html.match?(/<section class="content-gallery.*?<\/section>/m)
  html.sub!(/<section class="content-gallery.*?<\/section>/m, gallery)
end
# Keep only media slots for which an appropriate real asset was supplied.
allowed = %w[julia-portret reforme-material camp-wydarzenie tenis-wyjazd]
html.gsub!(/<figure class="media-slot" data-media="([^"]+)".*?<\/figure>/m) do |figure|
  allowed.include?($1) ? figure : ''
end
html.sub!(/<section class="creative section-pad".*?<\/section>/m,'')
html.sub!('<a href="#projekty">Wybrane projekty</a>', '<a href="#realizacje">Realizacje</a>')
html.sub!('Miejsce na historie,', 'Historie,')
html.sub!('style.css?v=3','style.css?v=4')
html.sub!('script.js?v=3','script.js?v=4')
File.write(htmlpath,html)
media_path=File.join(root,'dist/assets/media.json')
media=JSON.parse(File.read(media_path,encoding:'UTF-8'))
{'reforme-material'=>['reforme-metamorfoza','1 / 1'],'camp-wydarzenie'=>['allincamp-grupa','1.91 / 1'],'tenis-wyjazd'=>['tenis-camp','4 / 5']}.each do |slot,(id,ratio)|
  item=items.find{|e|e['id']==id};media[slot].merge!('src'=>item['src'],'alt'=>item['title'],'fit'=>'contain','ratio'=>ratio)
end
File.write(media_path,JSON.pretty_generate(media)+"\n")
public_items=items.map{|e|e.reject{|k,v| k=='source'}}
File.write(File.join(root,'dist/assets/portfolio.json'),JSON.pretty_generate(public_items)+"\n")
report="# Materiały w portfolio\n\nOryginały pozostają w folderach użytkowniczki. Kopie do podglądu są w `dist/assets/content/portfolio/`, w podfolderach tematycznych. Filmy zostały przepisane do MP4 z układem do odtwarzania przez sieć, bez utraty jakości. Nie były kompresowane; część filmów używa HEVC i wymaga przeglądarki obsługującej ten format.\n\nFilmy z nazwami `copy_…` oraz pozostałe rolki z dawnej grupy „Montaż & reels” przypisano do „Pilates & wellness” zgodnie ze wskazaniem właścicielki portfolio.\n\n"
labels.each do |id,label|
  report<<"## #{label}\n\n"
  items.select{|e|e['category']==id}.each{|e|report<<"- **#{e['title']}** — `#{e['src']}`\n  Źródło: `#{e['source']}`\n"}
  report<<"\n"
end
File.write(File.join(root,'PORTFOLIO-MEDIA.md'),report)
puts "Gallery built: #{items.size} assets, #{items.count { |item| item['poster'] }} video posters, #{labels.size} categories."
