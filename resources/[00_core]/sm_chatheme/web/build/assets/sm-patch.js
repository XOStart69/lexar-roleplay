(function(){
var E=2;
function upd(t){
  var l=t.scrollLeft>E,r=t.scrollLeft+t.clientWidth<t.scrollWidth-E;
  if(t.classList.contains('sm-l')!==l)t.classList.toggle('sm-l',l);
  if(t.classList.contains('sm-r')!==r)t.classList.toggle('sm-r',r);
}
function all(){var n=document.querySelectorAll('.smtabs');for(var i=0;i<n.length;i++)upd(n[i]);}
var q=false;
function sched(){if(q)return;q=true;requestAnimationFrame(function(){q=false;all();});}
document.addEventListener('wheel',function(e){
  var t=e.target.closest&&e.target.closest('.smtabs');
  if(t&&t.scrollWidth>t.clientWidth){t.scrollBy({left:(e.deltaY||e.deltaX),behavior:'smooth'});e.preventDefault();}
},{passive:false});
document.addEventListener('scroll',function(e){var t=e.target;if(t&&t.classList&&t.classList.contains('smtabs'))upd(t);},true);
document.addEventListener('click',function(e){
  var t=e.target.closest&&e.target.closest('.smtabs');if(!t)return;
  var r=t.getBoundingClientRect(),cap=window.innerWidth*0.022,d=0;
  if(t.classList.contains('sm-r')&&e.clientX>r.right-cap)d=1;
  else if(t.classList.contains('sm-l')&&e.clientX<r.left+cap)d=-1;
  if(d){e.preventDefault();e.stopPropagation();t.scrollBy({left:d*t.clientWidth*0.6,behavior:'smooth'});return;}
  var c=e.target.closest('.smtabs>div');
  if(c)c.scrollIntoView({behavior:'smooth',block:'nearest',inline:'nearest'});
},true);
window.addEventListener('resize',sched);
document.addEventListener('DOMContentLoaded',function(){
  new MutationObserver(function(ms){for(var i=0;i<ms.length;i++){var ad=ms[i].addedNodes;for(var j=0;j<ad.length;j++){var n=ad[j];if(n.nodeType===1&&(n.classList.contains('smtabs')||n.querySelector('.smtabs'))){sched();return;}}}}).observe(document.getElementById('app'),{childList:true,subtree:true});
  sched();
});
})();
