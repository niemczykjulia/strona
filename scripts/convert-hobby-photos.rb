# encoding: UTF-8
require_relative 'extract-video-frame'
include Frames
Frames.fn('av_log_set_level',[Frames::I],Frames::V).call(-8)
Dir.glob('/Users/julianiemczyk/Desktop/do portfolio JN/*.HEIC').each do |source|
 r=Frames.ref;Frames.check(Frames::OPEN.call(r,source,0,0),'open');f=Frames.ptr_at(r);Frames.check(Frames::INFO.call(f,0),'info')
 raise 'No image grid' unless f[56,4].unpack1('L')>0
 g=Frames.ptr_at(Frames.ptr_at(f,64));t=Frames.ptr_at(g,56)
 n,cw,ch=t[8,12].unpack('Lii');x0,y0,w,h,rotation=t[36,20].unpack('iiiii');raise 'Invalid grid' unless n>0&&n<300&&w>0&&h>0
 offsets=Frames.ptr_at(t,24);streams=Frames.ptr_at(g,80);contexts={};placements={}
 n.times do |i|
  local,x,y=offsets[i*12,12].unpack('Lii');s=Frames.ptr_at(streams,local*8);idx=s[8,4].unpack1('i');params=Frames.ptr_at(s,16)
  codec=Frames.fn('avcodec_find_decoder',[Frames::I],Frames::P).call(params[4,4].unpack1('i'));ctx=Frames::ALLOC.call(codec)
  Frames.check(Frames::PARAMS.call(ctx,params),'params');Frames.check(Frames::CODECOPEN.call(ctx,codec,0),'decoder');contexts[idx]=ctx;placements[idx]=[x-x0,y-y0]
 end
 rgb="\0".b*(w*h*3);packet=Frames::PACKET.call;frame=Frames::FRAME.call;done={}
 while Frames::READ.call(f,packet)>=0
  idx=packet[36,4].unpack1('i');ctx=contexts[idx]
  if ctx && !done[idx] && Frames::SEND.call(ctx,packet)>=0 && Frames::RECV.call(ctx,frame)>=0
   tw,th,_,format=frame[104,16].unpack('iiii');sws=Frames::SWS.call(tw,th,format,tw,th,2,4,0,0,0);tile=Fiddle::Pointer.malloc(tw*th*3)
   Frames.check(Frames::SCALE.call(sws,frame,frame+64,0,th,Frames.ref(tile),Fiddle::Pointer[[tw*3].pack('i')]),'scale');x,y=placements[idx];visible=[tw,w-x].min
   [th,h-y].min.times{|row|rgb[((y+row)*w+x)*3,visible*3]=tile[row*tw*3,visible*3]};Frames::SWSFREE.call(sws);done[idx]=true
  end
  Frames::UNREF.call(packet)
  break if done.size==contexts.size
 end
 raise 'Incomplete photo' unless done.size==contexts.size
 base=File.basename(source,'.HEIC').downcase;ppm="tmp/thumbnails/#{base}.ppm";jpg="dist/assets/content/poza-praca/#{base}.jpg"
 File.binwrite(ppm,"P6\n#{w} #{h}\n255\n"+rgb)
 args=['sips','-s','format','jpeg','-s','formatOptions','82','-Z','1400'];args+=['-r',((360-rotation)%360).to_s] if rotation!=0
 raise 'Conversion failed' unless system(*args,ppm,'--out',jpg,out:File::NULL)
 puts "#{base}: #{w}x#{h}, rotation #{rotation}, #{File.size(jpg)} bytes"
 contexts.each_value{|c|Frames::FREECODEC.call(Frames.ref(c))};Frames::FREEPACKET.call(Frames.ref(packet));Frames::FREEFRAME.call(Frames.ref(frame));Frames::CLOSE.call(r)
end
