ObjC.import('Foundation');
ObjC.import('AVFoundation');
ObjC.import('CoreMedia');
$.NSBundle.bundleWithPath('/System/Library/Frameworks/AVFoundation.framework').load;
var root='/Users/julianiemczyk/julia-niemczyk-portfolio';
var items=JSON.parse(ObjC.unwrap($.NSString.stringWithContentsOfFileEncodingError(root+'/tmp/portfolio/import.json', $.NSUTF8StringEncoding, $())));
var failed=[];
for(var i=0;i<items.length;i++){
 var item=items[i]; if(item.kind!=='video')continue;
 var asset=$.NSClassFromString('AVURLAsset').URLAssetWithURLOptions($.NSURL.fileURLWithPath(item.source),$());
 item.duration=Math.round($.CMTimeGetSeconds(asset.duration));
 var track=asset.tracksWithMediaType('vide').objectAtIndex(0);
 item.width=track.naturalSize.width; item.height=track.naturalSize.height;
 var n=$.CMFormatDescriptionGetMediaSubType(track.formatDescriptions.objectAtIndex(0));
 item.codec=String.fromCharCode(n>>>24,(n>>>16)&255,(n>>>8)&255,n&255);
 var dest=root+'/dist/'+item.src;
 if(!$.NSFileManager.defaultManager.fileExistsAtPath(dest)){
  var session=$.NSClassFromString('AVAssetExportSession').alloc.initWithAssetPresetName(asset,'AVAssetExportPresetPassthrough');
  session.outputURL=$.NSURL.fileURLWithPath(dest);session.outputFileType='public.mpeg-4';session.shouldOptimizeForNetworkUse=true;
  session.exportAsynchronouslyWithCompletionHandler(function(){});
  var deadline=Date.now()+180000;
  while(Number(session.status)<3&&Date.now()<deadline){$.NSRunLoop.currentRunLoop.runUntilDate($.NSDate.dateWithTimeIntervalSinceNow(.05));}
  if(Number(session.status)!==3){failed.push(item.id);console.log('FAILED '+item.id);continue;}
 }
 console.log('Imported '+item.id+' ('+item.duration+'s, '+item.codec+')');
}
$(JSON.stringify(items,null,2)).writeToFileAtomicallyEncodingError(root+'/tmp/portfolio/import.json',true,$.NSUTF8StringEncoding,$());
if(failed.length)throw new Error('Failed: '+failed.join(', '));
'All videos imported.';
