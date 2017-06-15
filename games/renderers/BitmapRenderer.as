/*

	Particles Renderer: Bitmap
	
	will render a particles list into a BitmapData

*/
package bitfade.games.renderers {

	import flash.geom.*
	import flash.display.BitmapData
	
	import bitfade.data.*
	import bitfade.games.data.* 
	import bitfade.raster.*
		

	public class BitmapRenderer {
		
		public var center:Point 
		public var output:BitmapData
		
		public var nullV:Vector.<uint>
		//public var drawer:bitfade.raster.AAGradientLine
		public var drawer:bitfade.raster.AALine
		//public var pGfx:Vector.<BitmapData>
			
		public function BitmapRenderer() {
			center = new Point();
			
		}
			
		public function render(particles:LinkedList):void {
		
			var x: Number;
			var y: Number;
			var l: uint;
			
			var xi: int;
			var yi: int;

			var cx: Number = center.x ;
			var cy: Number = center.y ;

			
			var current:Particle2d = Particle2d(particles.head.next)
			
			var offs:uint = 0
			
			var idx:uint
			var wc:Number
			
			var output:BitmapData = this.output
			
			
			drawer.target = nullV.concat()
			
			particles.rewind()
			
			
			//var maxIndex = pGfx.length - 1
			while (current = particles.next) {
			//for (;current;current = Particle2d(current.next)) {
			
				//l = current.life
				
				x = current.x + cx;
				y = current.y + cy;
				
				
				if (current.ox) {
				
					if (current.x < 0 || current.y > 800 || current.y < 0 || current.y > 600 ) {
						particles.deleteCurrent()
						continue;
					}
				
					//drawer.draw(current.ox,current.oy,x,y,0xFFFFFFFF)
					drawer.draw(current.ox,current.oy,x,y,0)
				}
				
				//output.setPixel32(x,y,0xFFFFFFFF)
				
				current.ox = x
				current.oy = y
				
				current.x += current.vx
				current.y += current.vy
				
				current.vx += current.ax
				current.vy += current.ay
				
				
			}
		
		
		}
	}

}