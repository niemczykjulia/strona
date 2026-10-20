# encoding: UTF-8
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8
require 'json'
require 'fileutils'
root = File.expand_path('..', __dir__)
source = '/Users/julianiemczyk/Desktop/do portfolio JN'
entries = []
add = lambda do |match, id, category, title, description, kind = 'video'|
  path = Dir.children(source, encoding: Encoding::UTF_8).find { |name| name == match || name.start_with?(match) }
  raise "Source not found: #{match}" unless path
  entries << {id: id, category: category, title: title, description: description, kind: kind, source: File.join(source, path), src: "assets/content/portfolio/#{category}/#{id}.#{kind == 'video' ? 'mp4' : 'jpg'}"}
end
add.call('White and Brown', 'reforme-metamorfoza', 'pilates', 'Reforme · letnia metamorfoza', 'Grafika promocyjna zajęć pilatesu. Oferta, zdjęcie i wyraźne zaproszenie do zapisów.', 'image')
add.call('1-kopia.png', 'reforme-kampania', 'pilates', 'Reforme · kreacja do kampanii', 'Pionowy format promocyjny łączący fotografię, typografię i wezwanie do działania.', 'image')
add.call('pila pila.mov', 'pila-pila', 'pilates', 'Pila Pila · wideo dla studia', 'Realizacja wideo z obszaru pilates & wellness.')
add.call('Dlaczego Paweł', 'platforma-tradingowa', 'fintech', 'Własna platforma tradingowa', 'Dłuższy format wideo o budowie własnej platformy tradingowej.')
add.call('Zdałeś'.unicode_normalize(:nfd), 'prop-trading', 'fintech', 'Prop trading · co po challenge’u?', 'Treść edukacyjna dla społeczności traderów.')
add.call('Pula nag', 'konkurs-trading', 'fintech', 'Konkurs dla społeczności', 'Rolka promocyjna zachęcająca do udziału i interakcji.')
add.call('IMG_9562.JPG', 'allincamp-grupa', 'eventy', 'ALLinCamp · społeczność na żywo', 'Zdjęcie grupowe z wydarzenia, przy którego organizacji i komunikacji pracowałam.', 'image')
add.call('Zało', 'allincamp-relacja', 'eventy', 'ALLinCamp · energia wydarzenia', 'Krótki format wideo z campu — ludzie, atmosfera i wspólne wspomnienia.')
add.call('1.png', 'tenis-camp', 'sport', 'Tenis camp · zapisy', 'Kreacja kampanii wyjazdu tenisowego do Marbelli.', 'image')
add.call('2.png', 'tenis-oboz', 'sport', 'Obóz tenisowy · oferta', 'Drugi wariant kreacji promocyjnej wyjazdu tenisowego.', 'image')
add.call('kreacje tenis.png', 'tenis-poziom-gry', 'sport', 'Tenis · wejdź na wyższy poziom', 'Grafika łącząca sportowy kadr z informacjami o wyjeździe.', 'image')
add.call('high heels', 'high-heels', 'taniec', 'High heels · grupa 30+', 'Pionowy materiał promujący zajęcia taneczne.')
add.call('18-40.mov', 'taniec-18-40', 'taniec', 'Taniec · grupa 18–40', 'Rolka promocyjna przygotowana dla studia tańca Passa Passa.')
add.call('kpop.mov', 'kpop', 'taniec', 'K-pop · energia w kadrze', 'Materiał wideo promujący zajęcia taneczne.')
add.call('sesja.mov', 'estate-street-sesja', 'nieruchomosci', 'Estate Street · sesja', 'Materiał wideo z sesji, przygotowany w ramach pracy dla biura nieruchomości.')
add.call('Dbamy o ka', 'beauty-paznokcie', 'pilates', 'Beauty · liczy się detal', 'Krótka rolka prezentująca stylizacje paznokci.')
external = Dir['/Users/julianiemczyk/Desktop/rolki/okulista */bezpłatne badanie/0319/0319.mov'].first
raise 'Missing optician film' unless external
entries << {id: 'bezplatne-badanie', category: 'taniec', title: 'Passa Passa · zajęcia dla kobiet 30+', description: 'Rolka promocyjna zajęć tanecznych dla kobiet w Passa Passa.', kind: 'video', source: external, src: 'assets/content/portfolio/taniec/ladies-30-plus.mp4'}
add.call('Rolka otwarcie.mov', 'otwarcie', 'pilates', 'Otwarcie · rolka promocyjna', 'Realizacja wideo pokazująca pracę z krótkim formatem.')
add.call('Dominik rolka', 'krotki-format', 'pilates', 'Krótki format · szybki przekaz', 'Krótka realizacja wideo do mediów społecznościowych.')
Dir.children(source, encoding: Encoding::UTF_8).select { |name| name.start_with?('copy_') }.sort.each_with_index do |name, i|
  add.call(name, "montaz-#{format('%02d', i + 1)}", 'pilates', "Pilates · rolka · #{format('%02d', i + 1)}", 'Wybrany materiał z mojego portfolio wideo.')
end
entries.each { |e| FileUtils.mkdir_p(File.dirname(File.join(root, 'dist', e[:src]))) }
File.write(File.join(root, 'tmp/portfolio/import.json'), JSON.pretty_generate(entries))
entries.select { |e| e[:kind] == 'image' }.each do |e|
  dest = File.join(root, 'dist', e[:src])
  next if File.size?(dest)
  raise "Image conversion failed: #{e[:id]}" unless system('sips', '-Z', '1800', '-s', 'format', 'jpeg', '-s', 'formatOptions', '85', e[:source], '--out', dest, out: File::NULL)
end
puts "Prepared #{entries.size} items (#{entries.count { |e| e[:kind] == 'image' }} images)."
