# encoding: UTF-8
require 'fiddle'
require 'fileutils'
module Frames
 extend self
 P=Fiddle::TYPE_VOIDP; I=Fiddle::TYPE_INT; L=Fiddle::TYPE_LONG_LONG; V=Fiddle::TYPE_VOID
 ROOT='/Applications/CapCut.app/Contents/Frameworks/'
 LIBS=%w[libavutil libswresample libdav1d libavcodec libswscale libavformat].map{|n|Fiddle.dlopen(ROOT+n+'.dylib')}
 def fn(name,args,ret)
  handle=LIBS.reverse.find{|h|begin h[name];true;rescue Fiddle::DLError;false;end};raise name unless handle
  Fiddle::Function.new(handle[name],args,ret)
 end
 VERSION=fn('avformat_version',[],I).call
 raise 'This extractor requires the bundled FFmpeg 61 ABI' unless VERSION >> 16 == 61
 OPEN=fn('avformat_open_input',[P,P,P,P],I);INFO=fn('avformat_find_stream_info',[P,P],I);BEST=fn('av_find_best_stream',[P,I,I,I,P,I],I)
 ALLOC=fn('avcodec_alloc_context3',[P],P);PARAMS=fn('avcodec_parameters_to_context',[P,P],I);CODECOPEN=fn('avcodec_open2',[P,P,P],I)
 PACKET=fn('av_packet_alloc',[],P);FRAME=fn('av_frame_alloc',[],P);READ=fn('av_read_frame',[P,P],I);SEND=fn('avcodec_send_packet',[P,P],I);RECV=fn('avcodec_receive_frame',[P,P],I);UNREF=fn('av_packet_unref',[P],V)
 SEEK=fn('av_seek_frame',[P,I,L,I],I);FLUSH=fn('avcodec_flush_buffers',[P],V)
 SWS=fn('sws_getContext',[I,I,I,I,I,I,I,P,P,P],P);SCALE=fn('sws_scale',[P,P,P,I,I,P,P],I);SWSFREE=fn('sws_freeContext',[P],V)
 CLOSE=fn('avformat_close_input',[P],V);FREECODEC=fn('avcodec_free_context',[P],V);FREEFRAME=fn('av_frame_free',[P],V);FREEPACKET=fn('av_packet_free',[P],V)
 def ptr_at(p,offset=0);Fiddle::Pointer.new(p[offset,8].unpack1('Q'));end
 def ref(p=0);Fiddle::Pointer[[p.to_i].pack('Q')];end
 def check(n,label);raise "#{label}: #{n}" if n<0;n;end
 def extract(source,time,dest,width=360,decoded_frames=8,exact_time=false)
  fmtref=ref;check(OPEN.call(fmtref,source,0,0),'open');fmt=ptr_at(fmtref);check(INFO.call(fmt,0),'info')
  coderef=ref;idx=check(BEST.call(fmt,0,-1,-1,coderef,0),'stream');codec=ptr_at(coderef)
  streams=ptr_at(fmt,48);stream=ptr_at(streams,idx*8)
  params=ptr_at(stream,16);raise 'Not video' unless params[0,4].unpack1('i')==0
  ctx=ALLOC.call(codec);check(PARAMS.call(ctx,params),'params');check(CODECOPEN.call(ctx,codec,0),'decoder')
  num,den=stream[32,8].unpack('ii');raise 'Invalid timebase' unless num>0&&den>0
  check(SEEK.call(fmt,idx,(time*den/num).round,1),'seek');FLUSH.call(ctx)
  packet=PACKET.call;frame=FRAME.call;got=0;done=false
  while READ.call(fmt,packet)>=0
   if packet[36,4].unpack1('i')==idx
    sent=SEND.call(ctx,packet)
    if sent>=0
     while RECV.call(ctx,frame)>=0
      got+=1
      done = exact_time ? frame[136,8].unpack1('q')*num.to_f/den >= time : got>=decoded_frames
      break if done
     end
    end
   end
   UNREF.call(packet)
   break if done
  end
  raise 'No decoded frame' if got==0
  w,h,_,format=frame[104,16].unpack('iiii');raise "Invalid dimensions #{w} #{h} #{format}" unless w>0&&h>0&&w<20000&&h<20000
  height=(h.to_f/w*width).round
  sws=SWS.call(w,h,format,width,height,2,4,0,0,0);raise 'Scaler failed' if sws.null?
  rgb=Fiddle::Pointer.malloc(width*height*3);dst=ref(rgb);stride=Fiddle::Pointer[[width*3].pack('i')]
  check(SCALE.call(sws,frame,frame+64,0,h,dst,stride),'scale')
  File.binwrite(dest,"P6\n#{width} #{height}\n255\n"+rgb[0,width*height*3])
  SWSFREE.call(sws);FREEPACKET.call(ref(packet));FREEFRAME.call(ref(frame));FREECODEC.call(ref(ctx));CLOSE.call(fmtref)
  [width,height]
 end
end
if $PROGRAM_NAME==__FILE__
 p Frames.extract(ARGV[0],ARGV[1].to_f,ARGV[2],(ARGV[3]||360).to_i)
end
