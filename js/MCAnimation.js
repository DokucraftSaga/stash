class MCAnimation{constructor(t,i){this.texture=new Image,this.texture.src=t,this.mcmeta="object"==typeof i?i:{animation:{}},this.mcmeta.animation||(this.mcmeta.animation={}),this.canvas=document.createElement("canvas"),this.canvas.className="mc-animation",this.context=this.canvas.getContext("2d"),this.frames=[],this.currentFrame=0,this.ticks=0,this.texture.addEventListener("load",()=>this.init())}init(){this.canvas.width=this.texture.width,this.canvas.height=this.texture.width;let t=Math.max(this.mcmeta.animation.frametime||1,1);if(Array.isArray(this.mcmeta.animation.frames)&&this.mcmeta.animation.frames.length>0){this.mcmeta.animation.interpolate||this.mcmeta.animation.frames.find(i=>"object"==typeof i&&i.time%t!=0)?this.interval=1:this.interval=t;for(let i=0;i<this.mcmeta.animation.frames.length;i++){const e=this.mcmeta.animation.frames[i];"number"==typeof e?this.frames.push({index:e,duration:t/this.interval}):this.frames.push({index:e.index,duration:Math.max(e.time,1)/this.interval})}}else{this.mcmeta.animation.interpolate?this.interval=1:this.interval=t;let i=this.texture.height/this.texture.width;for(let e=0;e<i;e++)this.frames.push({index:e,duration:t/this.interval})}this.draw(),this.play()}draw(t=0,i=0){this.context.clearRect(0,0,this.canvas.width,this.canvas.height),this.context.imageSmoothingEnabled=this.texture.width>this.canvas.width,this.context.globalAlpha=1,this.context.drawImage(this.texture,0,this.texture.width*this.frames[t].index,this.texture.width,this.texture.width,0,0,this.canvas.width,this.canvas.height),this.mcmeta.animation.interpolate&&(this.context.globalAlpha=i/this.frames[t].duration,this.context.drawImage(this.texture,0,this.texture.width*this.frames[(t+1)%this.frames.length].index,this.texture.width,this.texture.width,0,0,this.canvas.width,this.canvas.height))}update(){this.frames[this.currentFrame].duration<=++this.ticks?(this.currentFrame=(this.currentFrame+1)%this.frames.length,this.ticks=0,this.draw(this.currentFrame,this.ticks),"function"==typeof this.onNewFrame&&this.onNewFrame()):this.mcmeta.animation.interpolate&&this.draw(this.currentFrame,this.ticks)}play(){this.frames.length>1?this.timer=setInterval(()=>{window.requestAnimationFrame(()=>this.update())},50*this.interval):window.requestAnimationFrame(()=>this.draw())}pause(){this.timer&&(clearInterval(this.timer),this.timer=null)}stop(){this.pause(),this.currentFrame=0}get frameIndex(){return this.frames.length>0?this.frames[this.currentFrame].index:0}get playing(){return null!=this.timer}}