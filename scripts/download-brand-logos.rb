# encoding: UTF-8
require 'uri'
require 'cgi'
require 'open3'
require 'fileutils'
require 'tmpdir'
ROOT=File.expand_path('..',__dir__)
def fetch(url)
 body,status=Open3.capture2('curl','--fail','--location','--silent','--show-error','--max-time','30','--user-agent','Mozilla/5.0',url)
 raise "Nie udało się pobrać #{url}" unless status.success?
 body
end
def absolute(value,base)
 URI.join(base,CGI.unescapeHTML(value)).to_s
rescue URI::Error
 nil
end
def candidates(html,base)
 found=[]
 html.scan(/<img\b[^>]*>/im).each do |tag|
  next unless tag.match?(/logo/i)
  score=tag.match?(/custom-logo|site-logo|logo-main|header-logo/i) ? 100 : 60
  tag.scan(/(?:src|data-src)\s*=\s*["']([^"']+)["']/i).flatten.each do |path|
   url=absolute(path,base);found<<[url,score] if url && !url.start_with?('data:')
  end
 end
 html.scan(/(?:url\(\s*["']?|["'])([^\s"'<>\)]+\.(?:svg|png|webp|jpe?g)(?:\?[^\s"'<>\)]*)?)/i).flatten.each do |path|
  next unless path.match?(/logo/i)
  url=absolute(path,base);next unless url
  score=30;score-=15 if path.match?(/footer|white|bial|icon|favicon/i)
  found<<[url,score]
 end
 found
end
failures=[]
[['green-credit','https://greencredit.pl/','Green Credit'],['michal-przysiezny','https://michalprzysiezny.pl/o-mnie/','Michał Przysiężny']].each do |id,page,label|
 begin
  puts "Szukam logo: #{label}…"
  html=fetch(page).force_encoding('UTF-8').scrub
  choices=candidates(html,page)
  if choices.empty?
   html.scan(/<link\b[^>]*>/im).select{|tag|tag.match?(/stylesheet/i)}.first(16).each do |tag|
    href=tag[/\bhref\s*=\s*["']([^"']+)["']/i,1];next unless href
    cssurl=absolute(href,page);next unless cssurl
    begin;choices.concat(candidates(fetch(cssurl).force_encoding('UTF-8').scrub,cssurl));rescue;end
   end
  end
  selected=nil
  choices.sort_by{|_,score|-score}.uniq{|url,_|url}.each do |url,_|
   begin
    data=fetch(url)
    ext=if data.include?('<svg') then 'svg'
    elsif data.start_with?("\x89PNG".b) then 'png'
    elsif data.start_with?("\xFF\xD8".b) then 'jpg'
    elsif data.start_with?('RIFF')&&data[8,4]=='WEBP' then 'webp'
    end
    next unless ext && data.bytesize>100
    selected=[url,data,ext];break
   rescue;end
  end
  raise 'Nie znalazłam pliku logo na stronie.' unless selected
  url,data,ext=selected;relative="assets/logos/#{id}.#{ext}"
  FileUtils.mkdir_p(File.join(ROOT,'dist/assets/logos'))
  File.binwrite(File.join(ROOT,'dist',relative),data)
  path=File.join(ROOT,'dist/index.html');index=File.read(path,encoding:'UTF-8')
  pattern=/(<a\b[^>]*class="brand-mark brand-#{Regexp.escape(id)}"[^>]*>)(.*?)(<\/a>)/m
  raise 'Nie znalazłam marki w portfolio.' unless index.match?(pattern)
  index.sub!(pattern){$1+%(<img alt="" aria-hidden="true" src="#{relative}" loading="lazy" decoding="async"/>)+$2.gsub(/<img\b[^>]*>/m,'')+$3}
  temp=path+'.logos-tmp';File.write(temp,index);File.rename(temp,path)
  File.open(File.join(ROOT,'BRAND-ASSETS.md'),'a'){|f|f.puts "\n#{label}: #{relative}\nŹródło logo: #{url}\n"}
  puts "Gotowe: #{label} — logo dodane do portfolio."
 rescue => error
  failures<<label;puts "#{label}: #{error.message}"
 end
end
puts failures.empty? ? "\nOba logotypy dodane. Odśwież stronę: Command + Shift + R." : "\nNie udało się dodać: #{failures.join(', ')}. Skopiuj komunikat z tego okna do rozmowy."
exit(failures.empty? ? 0 : 1)
