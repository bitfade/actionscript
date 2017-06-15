package gl.photogallery{ 
	import flash.display.*;
	import flash.net.URLRequest;
	import flash.events.*;
	import flash.utils.Timer;
	import gl.utils.dynSprite;
	import org.osflash.thunderbolt.Logger;
	import flash.external.*;
	
	public class simple extends Sprite{
		
		public static const IMG_EMPTY:Number = 0;
		public static const IMG_LOADING:Number = 1;
		public static const IMG_LOADED:Number = 2;		
		
	
		protected var conf:Object;
		protected var images:Object;
		protected var loader:Loader;
		protected var loadingImg:Object;
		protected var request:URLRequest;
		protected var currDir:String="";
		protected var currImages:Object;
		protected var currIdx:Number=0;
		protected var ssTimer:Timer;
		protected var galleryMC:Sprite;
		
		function simple(args:Object){
			conf = args
			if (!args.padBottom) conf.padBottom=0
			if (!args.delay) conf.delay=3
			if (!args.firstDelay) conf.firstDelay = conf.delay
			
			loader = new Loader();
    		request = new URLRequest();
    		
			images= {};
			if (conf.xml) {
			/* 
				
				request.url = conf.xml;
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, parseXML);
				
				//loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, parseXML);
    			loader.load(request);
   			
 				
				for each (var d in conf.images.dir) {
					if (currDir == "") currDir = d.@name;
					images[d.@name] = new Array();
					var idx:Number=0;
					for each (var i in d.img) {
						images[d.@name].push({
							url:d.@path+i.@url,
							status:IMG_EMPTY,
							idx:idx++
						})
					}
				}
				*/
    			
    		} else {
    			currDir = "default";
   				images.default = new Array();
   				for (var i=1; i<=conf.n; i++) {
   					var url = i;
    				if (i<10) {
    					url = "00"+i;    		
    				} else if (i<100) {
    					url = "0"+i;
    				}
    				images.default.push({
    					url:conf.path+url+ ".jpg",
    					status:IMG_EMPTY,
    					idx:i-1
    				});
    			}		
    		}
    		
    		loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, progressLoadHandler);
    		loader.contentLoaderInfo.addEventListener(Event.COMPLETE, completeLoadHandler);
    		addEventListener(Event.ADDED,init) 
  		}
  		
  		protected function parseXML(e) {
  			//Logger.info("debug",e.bytesLoaded)
  			//loader.unload()
  		}
 		
 		protected function init(e) {
 			removeEventListener(Event.ADDED,init) 			
 			galleryMC = new Sprite();
    		addChild(galleryMC);
    		if (!conf.width) conf.width = stage.stageWidth;
			if (!conf.height) conf.height = stage.stageHeight;
			if (conf.onClick) {
				galleryMC.addEventListener(MouseEvent.CLICK, onClick);
				galleryMC.buttonMode = true;
				galleryMC.useHandCursor = true;
			}
			layout();
			
	   		currIdx = 0;
    		currImages = images[currDir];
 			
    		first()
    	}
 		
 		protected function layout(e=null) {
 			for (var i=0;i<galleryMC.numChildren;i++) {
 				position(galleryMC.getChildAt(i))
 			}
 				
 		}
 		
 		public function resize(w,h) {
 			conf.width = w;
 			conf.height = h;
 			layout();
 		}
 		
 		public function setTimer() {
 			if (ssTimer) {
 				ssTimer.delay = ((currIdx == 0 ) ? conf.firstDelay : conf.delay)*1000;
 			} else {
 				ssTimer = new Timer(conf.firstDelay*1000); 
 				ssTimer.addEventListener(TimerEvent.TIMER, slideShow);
				ssTimer.start();
 			}
 			
 		}
 		
 		public function first() {
 			loadImg(currImages[0]);
 			if (conf.delay > 0) {
 				setTimer()
   			}
 		}
 		
 		public function next() {
 			if (currImages[currIdx].status != IMG_LOADED) {
 				//ssTimer.stop()
 				return;
 			}
 			currIdx = ((++currIdx) % currImages.length);
 			
 			loadImg(currImages[currIdx]);
 		}
 		
 		public function slideShow(e=null) {
 			next();
 			setTimer()
 		}
 		
 			
 		public function loadImg(img) {
 			if (img.status == IMG_LOADED) return queueImg(img)
 			if (img.status != IMG_EMPTY) return
 			request.url = img.url;
 			img.status = IMG_LOADING;
 			loadingImg = img;
 			loader.load(request);
 		}
 		
 		protected function completeLoadHandler(e) {
 			var bMap = e.currentTarget.content
 			
 			loadingImg.status = IMG_LOADED;
 			loader.unload()
 			
 			initImg(loadingImg,bMap)
 			queueImg(loadingImg)
 		}
 		
 		protected function onClick(e) {
 			ExternalInterface.call(conf.onClick,{idx:currIdx,img:currImages[currIdx].url})
 		}
 		
 		protected function initImg(img,bMap=null) {
 			
 			img.w = bMap.width;
 			img.h = bMap.height;
 			
 			var mc = new dynSprite();
 			
 			if (bMap.width > conf.width || bMap.height > conf.height ) {
 				bMap.scaleX = bMap.scaleY = Math.min(conf.width/bMap.width,conf.height/bMap.height)
 			}
 			
 			mc.setRegistration(bMap.width/2,bMap.height/2)
 			
 			
 			if (conf.border > 0) {
 			
 				mc.graphics.beginFill(0xFFFFFF);
            	mc.graphics.lineStyle(1, 0x888888);
            
            	mc.graphics.drawRect(0, 0, bMap.width+12, bMap.height+12);
            	bMap.x = 6;
            	bMap.y = 6;
            	mc.graphics.endFill();
 			}
 			
 			mc.addChild(bMap)
 			
 			img.bMap = mc
 			
 		}
 		
 		protected function progressLoadHandler(e) {
 		}
 		
 		protected function queueImg(img) {
 			if (currIdx == img.idx) {
 				showImg(img.bMap);
 				var preloadIdx = currIdx+1
 				if ((preloadIdx < currImages.length) && (currImages[preloadIdx].status == IMG_EMPTY)) {
 					loadImg(currImages[preloadIdx])
 				}
 				
 			}
 		}
 		
 		public function position(bMap) {
 			bMap.x = (conf.width-bMap.width)/2
 			bMap.y = (conf.height-bMap.height)-conf.padBottom
 		}
 		
 		
 		public function hideImg(bMap) {
 			galleryMC.removeChild(bMap)
 		}
 		
 		public function showImg(bMap) {
 			if (galleryMC.numChildren > 0) hideImg(galleryMC.getChildAt(0));
 			position(bMap)
 			galleryMC.addChild(bMap);
 			fadeIn(bMap)
 		}
 		
 		public function fadeIn(bMap) {
 		}
		
	}
}
