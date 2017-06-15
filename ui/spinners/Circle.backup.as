/*

	Pure actionscript 3.0 spinner

*/
package bitfade.ui.spinners { 
	
	import flash.geom.*
	import flash.display.*
	import flash.events.*
	import flash.filters.*
	import flash.utils.Timer
	
	import bitfade.core.IDestroyable
	import bitfade.utils.events
	import bitfade.utils.gc
	
	public class circle extends Sprite implements bitfade.core.IDestroyable {
		
		/*
			default conf
		
			color: 	fill color
			border:	border color	
			size: 	size
			speed:	rotation speed
			width:	arc width
			blur: 	motion blur amount
			
		*/
		private var conf:Object = {
			color:0xE0E0E0,
			border:0x0,
			size:30,
			speed:5,
			width:3,
			blur: .8				
		};
		
		
		private var bMap:Bitmap
		private var bData:BitmapData
		private var bBuffer:BitmapData;
		private var bCirc:BitmapData;
		private var wboard:Shape;
		
		private var origin:Point
		private var box:Rectangle
		private var fadeCT:ColorTransform;
		private var bF:BlurFilter
		private var idx:uint=0
		
		private var status:uint = 1
		
		// timer for delay
		protected var tim:Timer;
		
			
		// constructor
		public function circle(opts:Object=null){
			super()
			// get the conf
			if (opts) for (var p:String in opts) conf[p] = opts[p];
			
			mouseEnabled = false;
			
			conf.half = conf.size/2
			
			bMap = new Bitmap()
			origin = new Point(0,0);
			
			wboard = new Shape();
			
			fadeCT = new ColorTransform(1,1,1,conf.blur,0,0,0,0);
				
			bF = new BlurFilter(2,2,1)
			
			// initialize timer
			tim = new Timer(1000,1)
			events.add(tim,TimerEvent.TIMER, _show,this)
			
			addEventListener(Event.ADDED,init)					
		}
		
		// init stuff, gets called where the spinner is added to the stage
		private function init(e:Event = null):void {
			removeEventListener(Event.ADDED,init)
			
			var s:uint = conf.size
			
			addChild(bMap)			
			// create empty bitmapDatas
			bData = new BitmapData(s,s,true,0);
			bMap.bitmapData = bData;
			
			box = bData.rect
			
			bBuffer = bData.clone();
			bCirc = bData.clone();
			
			if (conf.x) x = conf.x
			if (conf.y) y = conf.y
			
			var half:Number = conf.half
			
			// draw the circles
			with (wboard.graphics) {
				clear()
				lineStyle(5,conf.border,.2)
				drawCircle(half, half, half-5)
				lineStyle(3,conf.color,1)
				drawCircle(half, half, half-5)
			}
			
			// render the vectorial stuff in a bitmap
			bCirc.draw(wboard,null,null,null,box,true)
			
			events.add(this,Event.ENTER_FRAME,update)
		}  		
  		
  		private function _show(e:Event=null):void {
  			visible = true
			status = 1
  		}
  		
  		// show spinner (after wait milliseconds)
		public function show(wait:uint = 0):void {
			if (status == 1) return
			if (wait == 0) return _show()
			with (tim) {
				delay = wait
				reset()
				start();
			}
		}
		
		// hide spinner
		public function hide():void {
			tim.reset()
			visible = false
			status = 0
		}
		
		public function get enabled():Boolean {
			return visible || tim.running
		}
		
		// main loop
		public function update(e:Event=null):void {
			if (status == 0) return
			
			idx = (idx + conf.speed) % 100
			
			var half:Number = conf.half
			
			var dPI:Number = Math.PI*2
			var a1:Number = (idx/100)*dPI;
			var a2:Number = ((idx+conf.width*conf.speed)/100)*dPI;
			
			var wg = wboard.graphics
			
			wg.clear()
			wg.beginFill(0,1)
			wg.moveTo(half,half)
			wg.lineTo(half+Math.cos(a1)*half,half+Math.sin(a1)*half)
			wg.lineTo(half+Math.cos(a2)*half,half+Math.sin(a2)*half)
			wg.lineTo(half,half)
			
			// render the mask
			bBuffer.fillRect(box,0)
			bBuffer.draw(wboard)
			bBuffer.applyFilter(bBuffer,box,origin,bF)
			
			bData.lock()
			// fade out
			bData.colorTransform(box,fadeCT)
			// copy the prerendered circle using the mask
			bData.copyPixels(bCirc,box,origin,bBuffer,origin,true)
			bData.unlock()
		}
		
		public function destroy():void {
			Gc.destroy(this)
			bData.dispose()
			bBuffer.dispose()
			bCirc.dispose()
			wboard = undefined
		}
		
	}
}