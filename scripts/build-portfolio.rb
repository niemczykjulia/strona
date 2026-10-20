# encoding: UTF-8
Encoding.default_external = Encoding::UTF_8
require 'json'
require 'cgi'
require 'digest'
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
controls = buttons.map { |id,label| %(<input class="portfolio-control" type="radio" name="portfolio-category" id="portfolio-filter-#{id}" value="#{id}"#{id=='all' ? ' checked' : ''}/>) }.join("\n")
controls << %(<input class="portfolio-control" type="checkbox" id="portfolio-expanded"/>)
filters = buttons.map do |id,label|
  count = id == 'all' ? items.size : items.count{|e|e['category']==id}
  %(<label class="portfolio-filter" for="portfolio-filter-#{id}" data-filter="#{id}">#{esc.call(label)} <span>#{count}</span></label>)
end.join("\n")
filter_styles = buttons.map do |id,label|
  selector = "#portfolio-filter-#{id}:checked"
  rule = "#{selector}~.portfolio-filters [for=portfolio-filter-#{id}]{background:var(--ink);border-color:var(--ink);color:var(--paper)}"
  if id != 'all'
    rule << "#{selector}~.portfolio-grid>.portfolio-item:not([data-category=#{id}]){display:none}"
    rule << "#{selector}~.portfolio-more{display:none}"
  end
  rule << "#{selector}~.portfolio-results [data-result=#{id}]{display:inline}"
  rule
end.join("\n")
results = buttons.map do |id,label|
  count = id == 'all' ? items.size : items.count{|e|e['category']==id}
  text = id == 'all' ? %(pokazuję <span class="portfolio-count-collapsed">3</span><span class="portfolio-count-expanded">#{count}</span> z #{count} realizacji) : "liczba realizacji: #{count}"
  %(<span data-result="#{id}">#{esc.call(label)} — #{text}</span>)
end.join
cards = items.each_with_index.map do |item,index|
  category = esc.call(item['category']);title = esc.call(item['title']);description = esc.call(item['description']);src=esc.call(item['src']);badge=item['kind']=='video' ? 'WIDEO' : 'GRAFIKA';badge='ZDJĘCIE' if item['id']=='allincamp-grupa'
  if item['kind']=='video'
    seconds=item.fetch('duration'); duration="#{seconds/60}:#{format('%02d',seconds%60)}"
poster = item['poster']
embed = item['embed']
image = poster ? %(<img class="portfolio-poster" src="#{esc.call(poster)}" alt="" loading="lazy" decoding="async" width="#{item.fetch('width', 720)}" height="#{item.fetch('height', 1280)}"/>) : ''
if embed
player_url = embed + (embed.include?('?') ? '&' : '?') + 'autoplay=1'
visual=<<~HTML
<div class="portfolio-visual portfolio-video#{poster ? ' has-poster' : ''}" data-video-card>
  <details class="portfolio-player">
    <summary class="portfolio-play" aria-label="Odtwórz: #{title}">
      #{image}
      <span class="portfolio-duration">#{duration}</span>
      <span class="portfolio-play-circle" aria-hidden="true">▶</span>
      <span class="portfolio-play-caption">Odtwórz film</span>
    </summary>
    <iframe class="portfolio-embed" src="#{esc.call(player_url)}" title="#{title}" allow="autoplay; fullscreen; picture-in-picture; clipboard-write; encrypted-media; web-share" referrerpolicy="strict-origin-when-cross-origin" loading="lazy" allowfullscreen></iframe>
  </details>
</div>
<a class="portfolio-vimeo-link" href="#{esc.call(player_url)}" target="_blank" rel="noopener noreferrer">Otwórz film w Vimeo ↗</a>
HTML
else
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
end
  else
    visual=%(<a class="portfolio-visual portfolio-image" href="#{src}" data-gallery-image aria-label="Powiększ: #{title}"><img src="#{src}" alt="#{title}" loading="lazy" decoding="async"/><span class="portfolio-enlarge" aria-hidden="true">Powiększ ↗</span></a>)
  end
  %(<article class="portfolio-item" data-category="#{category}" data-asset-id="#{esc.call(item['id'])}"><div class="portfolio-item-top"><span>#{esc.call(labels[item['category']])}</span><span>#{badge}</span></div>#{visual}<h3>#{title}</h3><p>#{description}</p></article>)
end.join("\n")
gallery = <<~HTML
<section class="portfolio-gallery section-pad" id="realizacje" aria-labelledby="portfolio-title">
<div class="section-heading reveal"><div><p class="eyebrow">OD POMYSŁU DO PUBLIKACJI</p><h2 id="portfolio-title">Moja praca.<br/><em>W konkretnych kadrach.</em></h2></div><p>To tylko wybrane realizacje z mojego portfolio.<br/>Rolki, kampanie i materiały z wydarzeń.</p></div>
<style>#{filter_styles}</style>
#{controls}
<div class="portfolio-filters" role="group" aria-label="Wybierz temat realizacji">#{filters}</div>
<p class="portfolio-results" role="status" aria-live="polite">#{results}</p>
<div class="portfolio-grid" id="portfolio-grid">#{cards}</div>
<label class="portfolio-more" for="portfolio-expanded"><span class="portfolio-count-collapsed">Zobacz więcej (#{items.size - 3}) ↓</span><span class="portfolio-count-expanded">Pokaż mniej ↑</span></label>
<p class="portfolio-watch-note">Wybierz temat i zajrzyj do środka. Grafiki możesz powiększyć, a filmy odtworzyć z dźwiękiem.</p>

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
# Asset fingerprints prevent older scripts from being combined with new gallery HTML.
%w[script.js style.css].each do |asset|
  version = Digest::SHA256.file(File.join(root, 'dist', asset)).hexdigest[0, 12]
  html.gsub!(/#{Regexp.escape(asset)}\?v=[a-zA-Z0-9]+/, "#{asset}?v=#{version}")
end
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
