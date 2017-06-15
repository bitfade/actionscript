/*

	This is a base class that contains particles functions
	
*/

import flash.display.*
import flash.geom.*
import flash.filters.DropShadowFilter

class bitfade.AS2.intro.particles extends bitfade.AS2.intro.base {
		
	// max number of concurrent particles
	public static var maxParticles:Number = 1000

	// max particle life
	public static var maxLife:Number = 15*32
		
	// color transform 
	public var cT:ColorTransform
		
	// particle objects
	public var bPart:BitmapData
	public var bPartSingle:BitmapData
		
	public var activeParticles:Number = 0;
	public var lastParticle:Number = 0;
				
	// particles arrays
	public var px:Array
	public var py:Array
	public var pl:Array
	public var pm:Array
	public var pvx:Array
	public var pvy:Array
	public var pvl:Array
	public var pay:Array
		
	public var pp:Point;
		
	// default constructor
	public function particles(opts:Object){
		super(opts)		
	}
	
	// custom init
	public function customInit() {
			
		// create arrays for particles
		var aNames = ["px","py","pvx","pvy","pl","pvl","pm","pay"];
		
		for (var idx in aNames) {
			this[aNames[idx]] = new Array(maxParticles)
		}
		
		// some bitmaps
		bPart = bData.clone();
		// color transform
		cT = new ColorTransform(0,0,0,0.3,0,0,0,0)		
		// point
		pp = new Point()
			
		// draw particle
		buildParticle()	
	}
	
	// this draws particles at various light intensity
	public function buildParticle() {
		var ps:Number = 6;
		var psHalf:Number = 3
			
		var circle:MovieClip = conf.canvas.createEmptyMovieClip("circle",32)
			
		// this will contain all particles shapes
		bPartSingle = new BitmapData(ps*32,ps,true,0);
			
		// temp bitmaps 
		var bPartMask:BitmapData = new BitmapData(ps,ps,true,0);
		var bPartDraw:BitmapData = bPartMask.clone();
			
		// draw a particle using a radial gradient
		var gradM = new Matrix();
		gradM.createGradientBox(ps,ps,0,0,0);
			
		with (circle) {
			lineStyle(1,0,0);
			beginGradientFill(
				"radial", 
				[0,0,0], 
				[100,100,0], 
				[0,32,255], 
				gradM, 
				"pad"
			);
			var tan8:Number = Math.tan(Math.PI / 8)*psHalf
			var sin4:Number = Math.sin(Math.PI / 4)*psHalf
				
			// this is crap is due to AS2 missing drawCircle....
			moveTo(ps, psHalf);
			curveTo(ps, tan8 + psHalf, sin4 + psHalf, sin4 + psHalf);
			curveTo(tan8 + psHalf, ps, psHalf, ps);
			curveTo(-tan8 + psHalf, ps, -sin4 + psHalf, sin4 + psHalf);
			curveTo(0, tan8 + psHalf, 0, psHalf);
			curveTo(0, -tan8 + psHalf, -sin4 + psHalf, -sin4 + psHalf);
			curveTo(-tan8 + psHalf,0,psHalf,0);
			curveTo(tan8 + psHalf,0, sin4 + psHalf, -sin4 + psHalf);
			curveTo(ps, -tan8 + psHalf, ps, psHalf);
			endFill();
		}
			
		// now we create 32 level of light
		for (var i:Number = 0;i<32;i++) {
			bPartMask.fillRect(bPartMask.rectangle,int((32-i)*0xFF/32) << 24)
			bPartDraw.fillRect(bPartDraw.rectangle,0)
			bPartDraw.draw(circle)
			bPartSingle.copyPixels(bPartDraw,bPartDraw.rectangle,new Point(ps*(32-i-1),0),bPartMask,origin,true)
		}
		
		// remove useless circle temp mc
		circle.removeMovieClip()
	}

	// particles renderer
	public function renderParticles() {
		
		
		if (activeParticles == 0) {
			// if no particle active, just fade out
			bPart.colorTransform(box,cT);
			return
		}
			
		var cbox = new Rectangle(0,0,6,6)
		var pIdx:Number
			
		var cl:Number
		var cx:Number
		var cy:Number
		var cvx:Number
		var cvy:Number
			
		// fade out
		bPart.colorTransform(box,cT);
			
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
			pp.x = int(cx+0.5)
			pp.y = int(cy+0.5)
				
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