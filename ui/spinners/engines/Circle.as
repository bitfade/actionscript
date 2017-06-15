/*

	Pure actionscript 3.0 spinner

*/
package bitfade.ui.spinners.engines { 
	
	import flash.display.*
	import flash.geom.*
	import flash.filters.*
	import bitfade.utils.*
	import bitfade.ui.spinners.Spinner
	
	public class Circle extends bitfade.ui.spinners.engines.Engine {
		
		/*
			default conf
		
			color: 	fill color
			border:	border color	
			size: 	size
			speed:	rotation speed
			width:	arc width
			blur: 	motion blur amount
			
		*/
		public static var conf:Object = {
			color:0xE0E0E0,
			border:0x0,
			size:30,
			speed:5,
			width:3,
			blur: .8				
		};
		
		private var bBuffer:BitmapData;
		private var bCirc:BitmapData;
		private var wboard:Shape;
		
		private var origin:Point
		private var box:Rectangle
		private var fadeCT:ColorTransform;
		private var bF:BlurFilter;
		
		private var idx:uint=0;
		
		public static function register(s:bitfade.ui.spinners.Spinner):void {
			if (!_instance) _instance = new Circle()
			Engine.register(s)
		}
		
		override protected function build() {
			var half:Number = conf.half = conf.size/2
			
			origin = new Point(0,0);
			wboard = new Shape();
			fadeCT = new ColorTransform(1,1,1,conf.blur,0,0,0,0);
				
			bF = new BlurFilter(2,2,1)
			bData = new BitmapData(conf.size,conf.size,true,0);
			
			box = bData.rect
			bBuffer = bData.clone();
			bCirc = bData.clone();
			
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
			
		}
		
		override public function tick():void {
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
		
		override public function destroy():void {
			Run.reset(tick)
			bBuffer.dispose()
			bCirc.dispose()
			wboard = undefined
			super.destroy()
		}
				
	}
}