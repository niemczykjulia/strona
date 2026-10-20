# encoding: UTF-8
# macOS helper using the installed CapCut FFmpeg 61 libraries; videos stay local.
require_relative 'extract-video-frame'
require 'json'
require 'fileutils'
root=File.expand_path('..',__dir__)
Dir.chdir(root) do
 items=JSON.parse(File.read('tmp/portfolio/import.json',encoding:'UTF-8'))
 config=JSON.parse(File.read('scripts/portfolio-presentation.json',encoding:'UTF-8'))
 FileUtils.mkdir_p('tmp/thumbnails/final')
 config.fetch('videos').each do |id,settings|
  item=items.find{|entry|entry['id']==id}
  raise "Missing video #{id}" unless item
  item.merge!(settings)
  poster=File.join('dist',settings.fetch('poster'))
  FileUtils.mkdir_p(File.dirname(poster))
  ppm="tmp/thumbnails/final/#{id}.ppm"
  Frames.extract(File.join('dist',item.fetch('src')),settings.fetch('posterTime'),ppm,[item.fetch('width'),1080].min,settings.fetch('posterDecodedFrames',8),settings.fetch('posterExactTime',false))
  raise "JPEG export failed: #{id}" unless system('sips','-s','format','jpeg','-s','formatOptions','88',ppm,'--out',poster,out:File::NULL)
  FileUtils.rm_f(ppm)
  puts "Poster ready: #{id}"
 end
end
