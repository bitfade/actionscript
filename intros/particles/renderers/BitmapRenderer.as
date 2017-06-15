/*

	Particles Renderer: Bitmap
	
	will render a particles list into a BitmapData

*/
package bitfade.intros.particles.renderers {

	public class BitmapRenderer {
	
		import flash.geom.*
		import flash.display.BitmapData
	
		import bitfade.data.*
		import bitfade.data.particles.Particle3dLife
		
			
		public var minZ:int = -600;
		public var maxZ:int = -150;
		public var focalLength:Number = -300;
		public var center:Point 
		public var output:BitmapData
		public var pGfx:Vector.<BitmapData>
			
		public function BitmapRenderer() {
			center = new Point();
			
		}
			
		public function render(particles:LinkedList):void {
		
			var x: Number;
			var y: Number;
			var z: Number;
			var l: uint;
			
			var pz: Number;
			
			var xi: int;
			var yi: int;


			var fL:Number = focalLength;
			
			var minZ:int = this.minZ
			var maxZ:int = this.maxZ
			
			
			
			var cx: Number = center.x ;
			var cy: Number = center.y ;

			
		
			var current:Particle3dLife = Particle3dLife(particles.head.next)
			
			var offs:uint = 0
			
			var idx:uint
			var wc:Number
			
			var sourceBD:BitmapData
			var maxIndex = pGfx.length - 1
			
			for (;current;current = Particle3dLife(current.next)) {
			
				x = current.x
				y = current.y
				z = current.z
				
				l = current.life
				
				pz = fL + z
				wc = fL / pz
				
				xi = int(wc*current.x + cx) ;
				yi = int(wc*current.y + cy) ;
				
				if (pz>0) continue	
					
				if (pz<minZ) pz = minZ
				
				idx = Math.min(maxIndex-1,uint(maxIndex*l*(pz-minZ)/(500*(maxZ-minZ))))
				
				sourceBD = pGfx[idx]
				offs = sourceBD.width >> 1
				
				output.copyPixels(sourceBD,sourceBD.rect,new Point(xi-offs,yi-offs),null,null,true)
					
			}
			
		
		
		}
	}

}