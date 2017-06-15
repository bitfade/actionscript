/*

	Pure actionscript 3.0 loader

*/
package bitfade.ui.spinners.loaders { 
	
	import flash.geom.*
	import flash.display.*
	import flash.events.*
	import flash.filters.*
	import flash.utils.*
	
	import bitfade.ui.spinners.engines.*
	import bitfade.core.IDestroyable
	import bitfade.utils.*
	import bitfade.ui.*
	import bitfade.ui.text.*
	import bitfade.ui.spinners.*
	import bitfade.ui.backgrounds.engines.*
	
	public class Layer extends Sprite implements bitfade.core.IDestroyable {
		
		protected var delayedRun:RunNode;
		protected var blinkLoop:RunNode;
		protected var background:bitfade.ui.Empty;
		protected var top:Sprite;
		
		protected var w:uint = 0
		protected var h:uint = 0
		
		protected var bar:Shape
		
		protected var total:uint = 0
		protected var loaded:uint = 0;
		
		protected var mat:Matrix = new Matrix()
		protected var counter:uint = 0; 
		
		protected var color:uint = 0xFE3834
		
		// constructor
		public function Layer(...args) {
			super()
			init.apply(null,args)
		}
		
		// create the gfxs
		public function init(w:uint,h:uint,color:int = -1):void {
		
			visible = false
			this.w = w
			this.h = h
			
			if (color > 0) this.color = color
			
			// background
			background = new Empty(w,h,true)
			background.buttonMode = false
			addChild(background)
			
			top = new Sprite();
			addChild(top)
			
			var bh:uint = 18
			
			// bar
			mat.createGradientBox(200,bh*3, Math.PI/2,0,-bh);
			
			bar = new Shape()
			bar.graphics.beginGradientFill(GradientType.RADIAL, 
				[0x404040,0x0],
				[1,0],
				[0,255],
				mat,"pad","linear")
			bar.graphics.drawRect(0, 0, 200,bh)
			bar.graphics.endFill()
			
			bar.graphics.lineStyle(0,1)
			bar.graphics.lineGradientStyle(GradientType.RADIAL, 
				[0xFFFFFF,0xFFFFFF],
				[1,0],
				[0,255],
				mat,"pad","linear")
			bar.graphics.moveTo(0, 0)
			bar.graphics.lineTo(200, 0)
			bar.graphics.moveTo(0, bh)
			bar.graphics.lineTo(200, bh)
			
			bar.graphics.lineGradientStyle(GradientType.RADIAL, 
				[0,0],
				[1,0],
				[0,255],
				mat,"pad","linear")
			bar.graphics.moveTo(0, -1)
			bar.graphics.lineTo(200, -1)
			bar.graphics.moveTo(0, bh+1)
			bar.graphics.lineTo(200, bh+1)
			
			
			top.addChild(bar)
			
			bar.x = int(w - bar.width) >>> 1
			bar.y = int(h - bar.height) >>> 1
			
			bar = new Shape()
			top.addChild(bar)
			
			showRate(0)
			
			bar.filters = [ new GlowFilter(0xFFFFFF,1,2,2,2,2,false)]
			
			top.alpha = 1
			
			blinkLoop = Run.every(Run.FRAME,blink)
			
		}
		
		// display current loaded progress
		protected function showRate(r:Number = 0,t:uint = 0,l:uint = 0) {
			//bar.y = 0
			
			if (!top) return
			
			var half:Number = 4
			var margin:Number = 0
			
			var rad=half-margin
			
			bar.graphics.clear()
			
			var a:Number = 0;
			var c1:uint = 0,c2:uint = 0;
			
			// draw circles
			for (var i:uint = 0; i<t; i++) {
			
				a = 0.1
				c1 = 0xFFFFFF
				c2 = 0xA0A0A0
				if (i<l) {
					a = 1
				} else if ( i == l) {
					a = Math.max(0.1,r/100)
					if (a==1) { 
						a=0.1
					} else {
						c1 = color
						c2 = color
					}
					
				} 
				
				mat.createGradientBox(half*2,half*2, Math.PI/2,0,0);
				bar.graphics.beginGradientFill(GradientType.LINEAR, 
				[c2,c1],
				[a,a],
				[0,255],
				mat,"pad","linear")
				bar.graphics.drawCircle(half+half*3*i, half, rad)
			
				bar.graphics.endFill()
				
			}
			
			bar.x = int(w - bar.width) >>> 1
			bar.y = int(h - bar.height) >>> 1
			
			
		}
		
		// blink effect
		protected function blink() {
			counter = (counter % 20) + 1
			var bc:Number = 0.1*Math.abs(Math.min(counter-10,counter))
			
			
			top.getChildAt(0).alpha = 0.7+bc*0.3
			
		}
		
		// link the loader with asset loader
		public function link(source:EventDispatcher) {
			Events.add(source,[ResLoaderEvent.PROGRESS],progressHandler,this)
		}
		
		protected function progressHandler(e:ResLoaderEvent) {
			//trace(e.total,e.loaded)
			showRate(e.ratio,e.total,e.loaded)
		
			//trace(e.ratio)
		}
		
  		protected function showSpinner() {
  			top.visible = true
  		}
  		
  		// show spinner (after wait seconds)
		public function show():void {
			if (!visible) {
				showRate()
				visible = true
				delayedRun = Run.after(0.3,showSpinner,delayedRun,false)		
			}
		}
  			
		// hide spinner
		public function hide():void {
			Run.reset(delayedRun)
			visible = false
			top.visible = false
			showRate()
		}
		
		// desctroy spinner
		public function destroy():void {
			Run.reset(blinkLoop)
			hide()
			Gc.destroy(this)
		}
		
	}
}
/* commentsOK */