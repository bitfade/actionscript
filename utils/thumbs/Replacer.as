/*

	This class is used to replace simple thumbnails with nice styled one

*/
package bitfade.utils.thumbs { 
	import flash.display.*
	import flash.events.*
	import flash.net.*
	import flash.geom.*
	import flash.filters.*
	
	import bitfade.utils.geom
	
	public class replacer extends Sprite {  
		
		// image loader
		protected var ldr:Loader
		
		// bitmaps used for effects
		protected var bMap:Bitmap
		protected var bMapC:Bitmap
		protected var bMapR:Bitmap
		
		protected var bData:BitmapData
		protected var bDataC:BitmapData
		protected var bDataR:BitmapData
		
		// used to handle interactive events
		protected var eSprite:Sprite;
		
		// geom stuff
		protected var origin:Point = new Point()
		protected var p:Point = new Point()
		protected var box:Rectangle
		
		// some counters
		protected var counter:uint = 0;
		protected var counterMax:uint = 5;
		protected var refCounter:uint = 0;
		
		// true when cursor over thumbnail
		protected var mouseOver:Boolean = false
		
		// color schemes, you can add more
		protected var colors:Object =  {
			black: [0xFFFFFF,0x000000,0xFFFFFF],
			white: [0xA0A0A0,0xFFFFFF,0x000000]
		}
		
		// default configuration: * DO NOT EDIT HERE, USE JAVASCRIPT TO OVERRIDE *
		protected var conf:Object = {
			w: 0,
			h: 0,
			scale:"fill",
			align:["h,w",["center","center"]],
			margins:["top,right,bottom,left",[0,4,4,4]],
			frame:["enabled,h,w,colors,outerCorner,innerCorner,background",[true,8,8,"white",32,32,true]],
			shadow:["size,angle,alpha,blur",[4,45,.7,2]],
			link: ["url,target",["",""]],
			color: ["enabled,brightness,color",[false,0,0]],
			over: ["enabled,alpha,original,mode",[true,1,true,"add"]],
			reflection: 30,
			scaler:null
			
		}
		
		// get a typed value from a string
		protected function getTyped(str:String,defaults) {
			if (str == null) return defaults;
			if (defaults is Number) return parseFloat(str)
			if (defaults is Boolean) return str == "true"
			return str
		}
		
		// split a string in separate properties
		protected function splitProps(str:String,defaults) {
			// simple value
			if (!(defaults is Array)) return getTyped(str,defaults)
		
			// multiple values, let's split 
			var token:Array = str ? str.split(/,/) : [];
			var names:Array = defaults[0].split(/,/)
			defaults = defaults[1]
			
			var res:Object = {}
			// cycle for properties and set typed value
			for (var idx:int=defaults.length-1;idx >= 0; idx--) {
				res[names[idx]] = getTyped(token[idx],defaults[idx])
			}
			return res
		}
		
		// constructor
  		public function replacer() {
  			// call init when added to stage
  			addEventListener(Event.ADDED_TO_STAGE,init) 			
  			super()
  		}
  		
  		// init stuff when added to stage
  		protected function init(e:Event) {
  		
  			// remove now useless listener
  			removeEventListener(Event.ADDED_TO_STAGE,init)
  			
  			// set stage properties
  			stage.scaleMode = "noScale";
			stage.align = "TL";
  			
  			// get settings from flashVars
  			var settings:Object = loaderInfo.parameters
  			
  			if (!settings.src) {
  				trace("compile ok, refer to help / supplied template for how to use me");
  				return
  			}
  			
 			for each (var prop:String in  ["w","h","scale","align","margins","frame","shadow","reflection","link","over","color"]) {
  				conf[prop] = splitProps(settings[prop],conf[prop])
  			}
  			
  			// create the main sprite
  			eSprite = new Sprite();
  			addChild(eSprite)
  			
  			// create main bitmap
  			bData = new BitmapData(conf.w,conf.h-conf.reflection,true,0)
  			bMap = new Bitmap(bData)
  			eSprite.addChild(bMap)
  			
  			if (conf.reflection) {
  				// if reflection enabled, create bitmap
  				bDataR = new BitmapData(conf.w,conf.reflection,true,0)
  				bMapR = new Bitmap(bDataR)
  				bMapR.y = conf.h-conf.reflection
 	 			addChild(bMapR)
  			}
  			
  			if (conf.link.url) {
  				with (eSprite) {
  					// if image has link, set listeners for interactive events
	  				buttonMode = true
	  				addEventListener(MouseEvent.CLICK,evHandler)
  					addEventListener(MouseEvent.MOUSE_OVER,evHandler)
  					addEventListener(MouseEvent.MOUSE_OUT,evHandler)
  					addEventListener(Event.ENTER_FRAME,evHandler)
  				}
  				
  				if (conf.over.original) {
  					// if over original enabled, create another bitmap
  					bDataC = bData.clone();
  					bMapC = new	Bitmap(bDataC)
  					bMapC.blendMode = conf.over.mode
  					eSprite.addChild(bMapC)
  					conf.showOriginal = true;
  				}
  			
  			}
  			
  			
  			// create the loader
  			ldr = new Loader()
  			
  			// add listeners
  			with (ldr.contentLoaderInfo) {
  				addEventListener(Event.COMPLETE, loadComplete);
  				addEventListener(IOErrorEvent.IO_ERROR,loadError);
  			}
  			
  			// load the image			
  			ldr.load(new URLRequest(settings.src))
  			
  		}
  		
  		// gets called when load complete
  		protected function loadComplete(e:Event) {
  			var content = ldr.content
  			ldr.unload()
  			process(content)
  		}
  		
  		// process the image
  		protected function process(target) {
  			// set smoothing if needed
			if (target is Bitmap) {
				target.smoothing = true
			}
  			
  			// make main bitmap invisible until finished
  			bMap.visible = false
  			bData.lock()
  			
  			with (conf) {
  				// compute real size taking account of margins, reflection and frame
  				var realH:uint = h-reflection-margins.top-margins.bottom-frame.h*2
  				var realW:uint = w-margins.left-margins.right-frame.w*2
  			
  				// get the scaler
  				scaler = geom.getScaler(
  					scale,
  					align.w,
  					align.h,
  					realW,
  					realH,
  					target.width,
  					target.height
  				)
  				
  				box = new Rectangle(0,0,realW,realH)
  				
  				// draw the scaled image
  				var bTemp = bData.clone() 				
  				bTemp.draw(target,geom.getScaleMatrix(conf.scaler),null,null,box)
  				
  				p.x = margins.left + frame.w
  				p.y = margins.top + frame.h
  				
  				// copy on bitmap
  				bData.copyPixels(bTemp,bTemp.rect,p)
  				
  				if (frame.enabled) {
  					// frame enabled, create a temp shape
  					var s:Shape = new Shape();
  					
  					// draw inner rect
  					with (s.graphics) {
  						beginFill(colors[frame.colors][1],1)
  						drawRoundRect(margins.left+frame.w,margins.top+frame.w,realW,realH,frame.innerCorner,frame.innerCorner)
  						endFill()
  					}
  					
  					// render the inner rect
  					bTemp.fillRect(bTemp.rect,0)
  					bTemp.draw(s)
  					
  					// copy image
  					bTemp.copyPixels(bData,bTemp.rect,origin,bTemp,origin,frame.background)
  					bData.copyPixels(bTemp,bTemp.rect,origin)
  					
  					if (conf.showOriginal) {
  						// save the colored version for over effect
  						bDataC.copyPixels(bData,bTemp.rect,origin,bTemp,origin,frame.background)
  					}
  					
  					if (color.enabled) {
  						// create and apply the color filter
  						var cM = new ColorMatrixFilter([
							.34,.33,.33,color.brightness,color.color >>> 16 & 0xFF,
							.33,.34,.33,color.brightness,color.color >>> 8 & 0xFF,
							.33,.33,.34,color.brightness,color.color & 0xFF,
 							0,0,0,1,0 
						])
						bData.applyFilter(bData,bData.rect,origin,cM)
  					}
  					
  					if (frame.w > 0 || frame.h > 0) {
  						// outer frame enabled
  						var mat = new Matrix()
  						
  						// draw the gradient
  						mat.createGradientBox(w*2, (h-reflection)*2, Math.atan(w/h), -w/2,-(h-reflection)/2);
  						with (s.graphics) {
  							clear()
  							// set line style
  							lineStyle(1,colors[frame.colors][2],0.2,true)
  							
  							var c1:uint = colors[frame.colors][0]
  							var c2:uint = colors[frame.colors][1]
  							
  							// set the gradient
  							beginGradientFill(GradientType.LINEAR, 
  								[c1,c2,c2,c1], 
  								[1,1,1,1], 
  								[0,90,255-90,255], 
  								mat
  							);
  						
  							// draw rect
  							drawRoundRect(margins.left,margins.top,realW+2*frame.w,realH+2*frame.h,frame.outerCorner,frame.outerCorner)
  							endFill()
  						}
  						
  						// render the outer rect
  						bTemp.fillRect(bTemp.rect,0)
  						bTemp.draw(s)
  						bTemp.copyPixels(bData,bData.rect,origin,null,null,true)
  						
  						// clean stuff
  						bData.dispose()
  						bMap.bitmapData = bData = bTemp
  						s = null
  					
  					}
  					
  				} else if (conf.showOriginal) {
  					// save the colored version for over effect
  					bDataC.copyPixels(bData,bData.rect,origin)
  				}
  			}
  			
  			with (conf.shadow) {
  				if (size > 0) {
  					// apply the drop shadow filter
  					bData.applyFilter(bData,bData.rect,origin,new DropShadowFilter(size,angle,0,alpha,blur,blur,1,2))
  				}
  				
  			}
  			
  			// make main bitmap visible again
  			bData.unlock()
  			bMap.visible = true
  			target = null
  			
  			// add reflection
  			if (conf.reflection > 0) drawReflection()
  			
  		}
  		
  		// this will add reflection
  		protected function drawReflection() {
  			refCounter = counter;
  			
  			
  			var refH:uint = conf.reflection
  			var m = new Matrix();
  			m.createBox(1,-1,0, 0,conf.h - refH)
  			// clear
  			bDataR.fillRect(bDataR.rect,0)
  			// draw sprite flipped
  			bDataR.draw(eSprite,m,null,null,null)
  			
  			// create the alpha mask
  			var r = new Rectangle(0,0,conf.w,1)
  			var bAlpha = new BitmapData(conf.w,refH,true,0)
  			
  			for (var yp:uint = 0; yp < refH; yp += 1 ) {
				r.y = yp
				bAlpha.fillRect(r,uint(0x40*(refH-yp)/refH+1) << 24)
			}
			
			// copy reflection using alpha mask
			bDataR.copyPixels(bDataR,bDataR.rect,origin,bAlpha,origin)
  		}
  		
  		// event handler
  		protected function evHandler(e:Event) {
  			switch (e.type) {
  				case MouseEvent.MOUSE_OVER:
  					// mouse is over thumbnail
  					mouseOver = true
  				break;
  				case MouseEvent.MOUSE_OUT:
  					// mouse is not over thumbnail
  					mouseOver = false
  				break;
  				case MouseEvent.CLICK:
  					// go to url
  					navigateToURL(new URLRequest(conf.link.url), conf.link.target);
 				break;
  				case Event.ENTER_FRAME:
  					if (conf.over.enabled) {
  						// if mouse over thumbnail, update counter
						if (mouseOver) {
							if (counter < counterMax) counter++
						} else if (counter > 0) {
							counter--
						}
						
						if (conf.showOriginal) {
							// set colored alpha based on counter value
							bMapC.alpha = counter/counterMax
						} 
						if (conf.over.alpha < 1) {
							// set alpha based on counter value
							bMap.alpha = conf.over.alpha+(1-conf.over.alpha)*counter/counterMax
						}
						// draw reflection only when needed
						if (refCounter != counter && conf.reflection > 0) drawReflection()
					}
  					
  				break;
  			}
  		}
  		
  		// gets called on load errors
  		protected function loadError(e:Event) {
  			trace("error while trying to load file")
  		}
  		
	}
}