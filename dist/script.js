(()=>{
document.documentElement.classList.add('js');
const reducedMotion=matchMedia('(prefers-reduced-motion: reduce)').matches;
const observer=new IntersectionObserver(entries=>{entries.forEach(entry=>{if(!entry.isIntersecting)return;entry.target.classList.add('visible');observer.unobserve(entry.target);});},{threshold:.09});
document.querySelectorAll('.reveal').forEach(el=>observer.observe(el));
const progress=document.querySelector('.progress');let scheduled=false;
function updateProgress(){const range=document.documentElement.scrollHeight-innerHeight;progress.style.width=(range>0?scrollY/range*100:0)+'%';scheduled=false;}
addEventListener('scroll',()=>{if(!scheduled){scheduled=true;requestAnimationFrame(updateProgress)}},{passive:true});updateProgress();
const count=document.querySelector('[data-count]');
if(!reducedMotion){const counter=new IntersectionObserver(entries=>{if(!entries[0].isIntersecting)return;counter.disconnect();const start=performance.now();function frame(now){const t=Math.min((now-start)/1300,1);count.textContent=Math.round(150*(1-Math.pow(1-t,3)));if(t<1)requestAnimationFrame(frame)}requestAnimationFrame(frame)},{threshold:.7});counter.observe(count);}

// Subtle scroll and pointer movement; disabled for reduced-motion preferences.
const motionQuery=matchMedia('(prefers-reduced-motion: reduce)');
const heroVisual=document.querySelector('.hero-visual');
const portrait=document.querySelector('.portrait');
let motionFrame=false;
function movePortrait(){
 if(motionQuery.matches||document.body.dataset.motion==='paused'){portrait.style.removeProperty('--portrait-y');motionFrame=false;return;}
 const rect=heroVisual.getBoundingClientRect();
 if(rect.bottom>0&&rect.top<innerHeight){const offset=Math.max(-10,Math.min(10,-rect.top*.018));portrait.style.setProperty('--portrait-y',offset+'px');}
 motionFrame=false;
}
addEventListener('scroll',()=>{if(!motionFrame){motionFrame=true;requestAnimationFrame(movePortrait)}},{passive:true});
motionQuery.addEventListener('change',movePortrait);
document.querySelectorAll('.project-art').forEach(art=>{
 art.addEventListener('pointermove',event=>{
  if(motionQuery.matches||document.body.dataset.motion==='paused'||event.pointerType!=='mouse')return;
  const r=art.getBoundingClientRect();
  art.style.setProperty('--pointer-x',((event.clientX-r.left)/r.width-.5)*14+'px');
  art.style.setProperty('--pointer-y',((event.clientY-r.top)/r.height-.5)*14+'px');
 });
 art.addEventListener('pointerleave',()=>{art.style.setProperty('--pointer-x','0px');art.style.setProperty('--pointer-y','0px')});
});

// Supply media paths in assets/media.json; empty entries keep the designed placeholders.
async function loadPortfolioMedia(){
 try{
  const response=await fetch('assets/media.json?v=4');
  if(!response.ok)return;
  const items=await response.json();
  document.querySelectorAll('[data-media]').forEach(slot=>{
   const item=items[slot.dataset.media];
   if(!item||typeof item.src!=='string'||!item.src.trim())return;
   const isVideo=item.type==='video';
   const media=document.createElement(isVideo?'video':'img');
   media.style.objectPosition=item.position||'50% 50%';
   if(item.fit)media.style.objectFit=item.fit;
   if(item.ratio)slot.style.setProperty('--media-ratio',item.ratio);
   if(isVideo){media.controls=true;media.preload='metadata';media.playsInline=true;media.setAttribute('aria-label',item.alt||'Materiał wideo Julii');if(item.poster)media.poster=item.poster;}
   else{media.alt=item.alt||'';media.loading='lazy';media.decoding='async';}
   const ready=()=>slot.classList.add('has-media');
   media.addEventListener(isVideo?'loadedmetadata':'load',ready,{once:true});
   media.addEventListener('error',()=>{slot.classList.remove('has-media');media.remove();},{once:true});
   media.src=item.src;
   slot.querySelector('.media-frame').append(media);
  });
 }catch{/* Keep placeholders if a configuration cannot be loaded. */}
}
loadPortfolioMedia();

// Topic filters and click-to-load portfolio films.
const portfolioGallery=document.querySelector('.portfolio-gallery');
if(portfolioGallery){
 function stopPortfolioEmbeds(except=null){
  portfolioGallery.querySelectorAll('.portfolio-player[open]').forEach(player=>{if(player!==except)player.open=false;});
 }
 portfolioGallery.querySelectorAll('.portfolio-control').forEach(control=>control.addEventListener('change',()=>stopPortfolioEmbeds()));
 portfolioGallery.querySelectorAll('[data-video-src]').forEach(button=>{
  button.addEventListener('click',()=>{
   const container=button.closest('[data-video-card]');
   const video=container.querySelector('video');
   const error=container.querySelector('.portfolio-video-error');
   portfolioGallery.querySelectorAll('video').forEach(other=>{if(other!==video)other.pause()});
   stopPortfolioEmbeds();
   button.hidden=true;video.hidden=false;error.hidden=true;
   if(!video.getAttribute('src')){video.src=button.dataset.videoSrc;video.load();}
   video.addEventListener('error',()=>{error.hidden=false},{once:true});
   video.play().catch(()=>{if(video.error)error.hidden=false;});
   video.focus();
  });
 });
 portfolioGallery.querySelectorAll('.portfolio-player').forEach(player=>{
  player.addEventListener('toggle',()=>{
   if(player.open){
    stopPortfolioEmbeds(player);
    portfolioGallery.querySelectorAll('video').forEach(video=>video.pause());
   }else{
    const frame=player.querySelector('iframe');
    // Reload a closed player to stop its audio, while native details still works without JS.
    if(frame)frame.src=frame.getAttribute('src');
   }
  });
 });
 portfolioGallery.querySelectorAll('video').forEach(video=>video.addEventListener('play',()=>{
  portfolioGallery.querySelectorAll('video').forEach(other=>{if(other!==video)other.pause()});
 }));
 const lightbox=portfolioGallery.querySelector('.portfolio-lightbox');
 const enlarged=lightbox.querySelector('img');
 portfolioGallery.querySelectorAll('[data-gallery-image]').forEach(link=>link.addEventListener('click',event=>{
  if(typeof lightbox.showModal!=='function')return;
  event.preventDefault();
  const original=link.querySelector('img');
  enlarged.src=link.href;enlarged.alt=original.alt;
  lightbox.querySelector('p').textContent=original.alt;
  lightbox.showModal();
 }));
 lightbox.querySelector('button').addEventListener('click',()=>lightbox.close());
 lightbox.addEventListener('click',event=>{if(event.target===lightbox)lightbox.close()});
 lightbox.addEventListener('close',()=>enlarged.removeAttribute('src'));
}

// Keep brand names readable if a logo cannot be loaded.
document.querySelectorAll('.brand-mark img').forEach(logo=>{
 const mark=logo.closest('.brand-mark');
 const update=()=>mark.classList.toggle('brand-has-logo',logo.complete&&logo.naturalWidth>0);
 logo.addEventListener('load',update);
 logo.addEventListener('error',update);
 update();
});

})();
