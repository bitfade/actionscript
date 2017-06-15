/*

	This is a base class used by all particles-based text.effects
	this extends bitfade.text.effect which has other common functions

*/
package bitfade.text {

	import flash.display.*
	import flash.filters.*
	import flash.geom.*
	import flash.events.*
	
	public class particles extends bitfade.text.effect {
	
		// max number of concurrent particles
		public static const maxParticles:uint = 10000	

		// max particle life
		public static const maxLife:uint = 15*32
		
		// color transform 
		protected var cT:ColorTransform
		
		// particle objects
		protected var bPart:BitmapData
		protected var bPartSingle:BitmapData
		
		protected var activeParticles:uint = 0;
		protected var lastParticle:uint = 0;
		
		// Xorshift RNGs -> rw = random uint
  		protected var rndX:uint=123456789
  		protected var rndY:uint=362436069
  		protected var rndZ:uint=521288629
  		protected var rndW:uint=88675123
  		protected var rndT:uint
		
		// particles arrays
		protected var px:Array
		protected var py:Array
		protected var pl:Array
		protected var pm:Array
		protected var pvx:Array
		protected var pvy:Array
		protected var pvl:Array
		protected var pay:Array
		
		protected var pp:Point;
		
		// use default constructor
		public function particles(conf) {
			super(conf)
		}
		
		// custom init
		override protected function customInit() {
			
			// create arrays for particles
			for each (var item in ["px","py","pvx","pvy","pl","pvl","pm","pay"]) {
				this[item] = new Array(maxParticles) 
   			}
			
			// some bitmaps
			bPart = bData.clone();
			// color transform
			cT = new ColorTransform(0,0,0,0.99,0,0,0,0)		
			// point
			pp = new Point()
			
			// draw particle
			buildParticle()
			
		}
		
		
		// this draws particles at various light intensity
		private function buildParticle(ps=6) {
			
			// use a circle
			var circle:Shape = new Shape();
			
			// this will contain all particles shapes
			bPartSingle = new BitmapData(ps*32,ps,true,0);
			
			// temp bitmaps 
			var bPartMask:BitmapData = new BitmapData(ps,ps,true,0);
			var bPartDraw:BitmapData = bPartMask.clone();
			
			// draw a particle using a radial gradient
			var gradM = new Matrix();
			gradM.createGradientBox(ps,ps,0,0,0);
			
			with (circle.graphics) {
				beginGradientFill(
					GradientType.RADIAL, 
					[0,0,0], 
					[1,1,0], 
					[0,32,255], 
					gradM, 
					SpreadMethod.PAD
				);
				drawCircle(ps/2,ps/2,ps/2)
				endFill()
			}
			
			// now we create 32 level of light
			for (var i:uint = 0;i<32;i++) {
				bPartMask.fillRect(bPartMask.rect,uint((32-i)*0xFF/32) << 24)
				bPartDraw.fillRect(bPartDraw.rect,0)
				bPartDraw.draw(circle,null,null,null,bPartSingle.rect)
				bPartSingle.copyPixels(bPartDraw,bPartDraw.rect,new Point(ps*(32-i-1),0),bPartMask,origin,true)
			}
		}
		
		
		// particles renderer
		public function renderParticles() {
			
			if (activeParticles == 0) {
				// if no particle active, just fade out
				bPart.colorTransform(bData.rect,cT);
				return
			}
			
			var cbox = new Rectangle(0,0,6,6)
			var pIdx:uint
			
			var cl:int
			var cx:Number
			var cy:Number
			var cvx:Number
			var cvy:Number
			
			// fade out
			bPart.colorTransform(bData.rect,cT);
			
			activeParticles = 0
					
			for (pIdx=0;pIdx<=maxParticles;pIdx++) {
			
				// particle life
				cl = pl[pIdx]
				
				if (cl <= 0 ) {
					// 0 = dead particle, do nothing for it
					continue
				} else {
					// else particle is active
					activeParticles++
				}
				
				
				// decrement life
				pl[pIdx] -= pvl[pIdx]
				
				// update position
				cx = px[pIdx] += pvx[pIdx]
				cy = py[pIdx] += pvy[pIdx]
				
				// update velocity
				if (pay[pIdx]) pvy[pIdx] += pay[pIdx]
				
				// point uses integer particle coordinates
				pp.x = uint(cx+0.5)
				pp.y = uint(cy+0.5)
				
				if (pm[pIdx] == 1) {
					// if mode = 1, particle has full light at end
					cbox.x = ((maxLife - cl) >> 5)*6
				} else {
					// if mode = 0, particle has full light at start
					cbox.x = (cl >> 5)*6
				}
				
				// add particle
				bPart.copyPixels(bPartSingle,cbox,pp,null,null,true)
			}
			
		}
		
		
	
	}

}
	