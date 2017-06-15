/*

	This class handles a thumbnail

*/
package bitfade.ui.thumbs { 
	
	import flash.display.*
	import flash.geom.*
	import bitfade.core.*
	import bitfade.ui.frames.*
	import bitfade.utils.*
	import bitfade.easing.*
	import bitfade.ui.spinners.*
	import flash.utils.Dictionary
	
	
	public class Thumb extends Sprite implements bitfade.core.IDestroyable {
	
		// here we keep default configuration
		protected static var defaults:Object = {
			type: "dark",
			width: 160,
			height: 120,
			margins: "9,8",
			scale: "fillmax",
			align: "center,center",
			frame: 3,
			enlight: 3,
			enlightMode: "default"
		}
		
		public static var spinnerClass:Class = bitfade.ui.spinners.Cube
		public static var lightBlendMode:String = "overlay"
		
		protected var conf:Object
	
		// bitmapDatas shared between all instances 
		private static var backgroundData:BitmapData
		private static var glossData:BitmapData
	
		// background
		protected var background:Bitmap
		
		// gloss effect
		protected var gloss:Bitmap
		
		// highlight bitmaps
		protected var enlightBackground:Bitmap
		protected var enlightGloss:Bitmap
		protected var enlightObj:Bitmap
		
		// holds thumbnail
		protected var container:Bitmap
		
		// spinner
		protected var spinner:bitfade.ui.spinners.Spinner
		
		// fade/enlight run entries
		protected var fadeInLoop:RunNode
		protected var enlightLoop:RunNode
		
		protected var w:uint = 0
		protected var h:uint = 0
		
		protected var mw:uint = 5
		protected var mh:uint = 6
		
		protected var loading:String
		
		protected var mouseOver:Boolean = false
		public var updating:Boolean = false;
		
		public function Thumb(opts:Object) {
			super()
			init(opts)
		}	
  		
  		public function init(opts:Object = null) {
  		
			// get the conf overriding defaults
			configure(opts)
			
			// set defaults
			this.w = conf.width
			this.h = conf.height
			this.mw = conf.margins.w 
			this.mh = conf.margins.h 
			
			
			buttonMode = true
  			
			if (conf.frame & 1) {
				// build and set background
				buildBackground()
				background = new Bitmap(backgroundData)
  				addChild(background)
			}
  			
  			// add spinner
  			spinner = new spinnerClass()
  			spinner.x = int((w-2*mw-spinner.width)/2 + .5)+mw
  			spinner.y = int((h-2*mh-spinner.height)/2 + .5)+mh
  			
  			addChild(spinner)
  			
  			// create container
  			container = new Bitmap()
  			container.x = mw
  			container.y = mh
  			
  			addChild(container)
  			
  			var enBlendMode:String
  			
  			if (conf.enlightMode == "default") {
  				enBlendMode = conf.type == "dark" ? "add" : lightBlendMode
  			} else {
  				enBlendMode = conf.enlightMode
  			}
  			
  			if (conf.frame & 2) {
  				// build and set gloss
  				buildGloss()
  				gloss = new Bitmap(glossData)
  				addChild(gloss)
  			}
  			
  			if (conf.enlight & 1) {
  				// set background enlight
  				buildBackground()
				enlightBackground = new Bitmap(backgroundData)
				addChild(enlightBackground)
				enlightBackground.alpha = 0
				enlightBackground.blendMode = enBlendMode
  			}
  			
  			if (conf.enlight & 2) {
  				// set gloss enlight
  				buildGloss()
  				enlightGloss = new Bitmap(glossData)
  				addChild(enlightGloss)
  				enlightGloss.alpha = 0
  				enlightGloss.blendMode = enBlendMode
  			}
  			
  			if (conf.enlight & 4) {
  				// set object enlight
  				enlightObj = new Bitmap()
  				addChild(enlightObj)
  				enlightObj.x = mw
  				enlightObj.y = mh
  				enlightObj.alpha = 0
	  			enlightObj.blendMode = enBlendMode
  			}
  			
  			
  		}
  		
  		// configure settings
  		protected function configure(opts:Object):void {
  			conf = Misc.setDefaults(opts,defaults,true)		
			conf.align = Geom.splitProps(conf.align)
			conf.margins = Geom.splitProps(conf.margins,true)
  		}
  		
  		// set scale mode
  		public function scaleMode(scale:String,align:String) {
  			if (scale) conf.scale = scale
  			if (align) conf.align = Geom.splitProps(align)
  		}
  		
  		// build background bitmapdata
  		protected function buildBackground() {
  			if (!backgroundData || backgroundData.width != w || backgroundData.height != h) {
  				backgroundData = Snapshot.take(bitfade.ui.frames.Shape.create("default."+conf.type,w,h,mw,mh))
  			}
  		}
  		
  		// build gloss bitmapdata
  		protected function buildGloss() {
  			if (!glossData || glossData.width != w || glossData.height != h) {
				glossData = Snapshot.take(bitfade.ui.frames.Gloss.create(w,h),null,w,h)
				glossData.copyPixels(glossData,glossData.rect,new Point(),backgroundData,new Point(),false)
			}
  		}
  		
  		// load external resource
  		public function load(url:String) {
  			reset()
  			if (url) {
  				updating = true
  				spinner.show(0.1)
  				loading = url
  				ResLoader.load(url,loaded)
  			} else {
  				loaded(null)
  			}
  		}
  		
  		// reset a loading resource
  		public function reset() {
  			container.alpha = 0
  			Run.reset(fadeInLoop)
  			if (loading) {
  				ResLoader.reset(loading,loaded)
  				loading = undefined
  			}
  			
  		}
  		
  		// called when resource fully loaded
  		protected function loaded(target:*) {
  			
  			loading = undefined
  			updating = false
  			
  			if (!target) {
  				// target is not found (bad url)
  				spinner.hide()
  				return
  			} 
  			
  			// set a scaler object
  			var scaler:Object = Geom.getScaler(conf.scale,conf.align.w,conf.align.h,w-2*mw,h-2*mh,target.width,target.height)
					
			// get a target snapshot
			Snapshot.take(target,container,w-2*mw,h-2*mh,Geom.getScaleMatrix(scaler))
			
			if (enlightObj) enlightObj.bitmapData = container.bitmapData
			
			// destroy target
			Gc.destroy(target)
			
			if (spinner.visible) {
				// fade in content
  				fadeInLoop = Run.every(Run.FRAME,showContainer,5,0,true,fadeInLoop)
  			} else {
  				// hide spinner
  				container.alpha = 1
  				spinner.hide()
  				if (mouseOver) over(true)
  			}
  			
  			
  		}
  		
  		// fade in container
  		protected function showContainer(ratio:Number) {
  			container.alpha = ratio
  			if (ratio == 1) {
  				spinner.hide()
  				if (mouseOver) over(true)
  			}
  		}
  		
  		// set bMap alpha
  		protected function setAlpha(bMap:Bitmap,a:Number) {
  			if (bMap) {
  				bMap.alpha = a
  				bMap.visible = (a > 0)
  			}
  		}
  		
  		// enlight effect
  		protected function enlight(ratio:Number,show:Boolean) {
  			updating = (ratio < 1)
  			ratio = show ? ratio : 1-ratio
  			setAlpha(enlightBackground,ratio)
  			setAlpha(enlightGloss,ratio)
  			setAlpha(enlightObj,ratio)
  		}
  		
  		// call this when mouse is over thumbnail
  		public function over(isOver:Boolean = false):void {
  			mouseOver = isOver
  			if (loading) return
  			enlightLoop = Run.every(Run.FRAME,enlight,isOver ? 3 : 6,0,true,enlightLoop,isOver)
  		}
  		
  		// clean stuff
  		public function destroy():void {
  			Run.reset(enlightLoop)
  			Run.reset(fadeInLoop)
  			// needed to prevent gc from destroying shared bitmapDatas
  			if (background)	removeChild(background)
  			if (enlightBackground) removeChild(enlightBackground)
  			if (gloss) removeChild(gloss)
  			if (enlightGloss) removeChild(enlightGloss)
  			Gc.destroy(this)
  		}
  		
	}
}
/* commentsOK */