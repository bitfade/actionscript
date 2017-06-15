/*

	This class handle a thumbnail

*/
package bitfade.ui.thumbs { 
	
	import flash.display.*
	import flash.geom.*
	import bitfade.core.*
	import bitfade.ui.frames.shape
	import bitfade.utils.*
	import bitfade.easing.*
	import bitfade.ui.spinners.*
	import flash.utils.Dictionary
	
	import bitfade.debug
	
	public class thumb extends Sprite implements bitfade.core.IDestroyable {
	
		protected var background:Bitmap
		protected var gloss:Bitmap
		protected var container:Sprite
		protected var spinner:bitfade.ui.spinners.spinner
		
		private static var backgroundData:BitmapData
		private static var glossData:BitmapData
	
		protected var w:uint = 0
		protected var h:uint = 0
		protected var resource:String
		
		protected static var cache:Dictionary = new Dictionary()
		
		public function thumb(resource:String,w:uint,h:uint) {
			this.w = w
			this.h = h
			this.resource = resource
			
			super()
			init()
		}	
  		
  		protected function init() {
  			if (!backgroundData || backgroundData.width != w || backgroundData.height != h) buildBackGround()
  			background = new Bitmap(backgroundData)
  			
  			
  			//cacheAsBitmap = true
  			
  			addChild(background)
  			
  			container = new Sprite()
  			container.x = 8+1
  			container.y = 10+1
  			container.mouseEnabled = false
  			container.scrollRect = new Rectangle(0,0,w-18,h-32)
  			
  			
  			addChild(container)
  			
  			spinner = new bitfade.ui.spinners.cube()
  			
  			spinner.x = int((w-18-spinner.width)/2 + .5)
  			spinner.y = int((h-32-spinner.height)/2 + .5)
  			
  			container.addChild(spinner)
  			
  			gloss = new Bitmap(glossData)
  			addChild(gloss)
  			
  			load()
  		}
  		
  		public function load(url:String="") {
  			if (url == "") url = resource
  			if (url != "") {
  				resource = url
  				spinner.show(0.1)
  				ResLoader.load(url,loaded)
  			}
  		}
  		
  		public function reset() {
  			if (container.numChildren > 1) {
  				Gc.destroy(container.getChildAt(1))
  			}	
  		}
  		
  		protected function buildBackGround() {
  			backgroundData = Snapshot.take(bitfade.ui.frames.shape.create("default.dark",w,h))
  			glossData = Snapshot.take(bitfade.ui.frames.gloss.create(w,h),null,w,h)
  			glossData.copyPixels(glossData,glossData.rect,new Point(),backgroundData,new Point(),false)
  			
  		}
  		
  		protected function loaded(target:*) {
  			
  			//spinner.hide()
  			//return
  			
  			if (target === undefined) {
  				spinner.hide()
  				return
  			}
  			
  			var scaler:Object = geom.getScaler("fillmax","center","center",w-18,h-32,target.width,target.height)
			
			
			var bMap:Bitmap = new Bitmap()
			container.addChild(bMap)
			
			Snapshot.take(target,bMap,w-18,h-32,geom.getScaleMatrix(scaler))
			
			//cache[resource] = bMap
			
			Gc.destroy(target)
			
			/*
			
			// apply new scale value / offsets
			if (target is Bitmap) target.smoothing = true
			target.scaleX = target.scaleY = scaler.ratio
			
			target.x = int(scaler.offset.w+0.5)
			target.y = int(scaler.offset.h+0.5)
			
			target.alpha = 0
  			target.blendMode = "normal"
  			
  		
  			container.addChild(target)
  			
  			target.alpha = 1
  			*/
  			spinner.hide()
  			
  			//bitfade.utils.tw.to(target, .5, {alpha:1}, {ease:Cubic.In});
  			//Run.after(0,spinner.hide)
  			
  		}
  		
  		public function destroy():void {
  			Gc.destroy(this)
  		}
  		
	}
}