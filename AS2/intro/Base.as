/*

	This is a base class that contains common functions
	no magic here
	
*/

import flash.display.*
import flash.geom.*
import bitfade.AS2.utils.colors
	
class bitfade.AS2.intro.base extends MovieClip {
		
	// default conf
	public var conf:Object = {
		mcControl: true,
		multipleInstances: false
	};
	
	// keep count of instances
	private static var instances:Number = 0;
				
	// bitmaps
	private var bData:BitmapData
	private var bDraw:BitmapData;
	private var bBuffer:BitmapData;
		
	// stuff
	private var origin:Point
	private var pt:Point;
	private var box:Rectangle
	private var hitR:Rectangle;
	private var colorMap:Array;
	
	// dimentions
	public var w:Number;
	public var h:Number;
	
	// intro step
	public var step:Number = 0;
	
		
	// constructor
	function base(opts:Object){
		instances++
		// protect from looped animation
		if (!conf.multipleInstances && instances>1) return
		// get the conf
		for (var p in opts) {
			conf[p] = opts[p];
		}
			
		w = conf.width
		h = conf.height
		
		// some geom stuff needed
		origin = new Point(0,0);
		pt = new Point(0,0)
		box = new Rectangle(0,0,w,h);
		hitR = new Rectangle()
			
		colorMap = new Array(256)
			
		init();
	}
	
	// create the color gradient
	public function buildColorMap(c) {
		bitfade.AS2.utils.colors.buildColorMap(colorMap,c);
	}
		
	// init stuff
	public function init() {
		
		// stop the parent
		var canvas = conf.canvas;
		conf.parent = canvas
		
		if (conf.mcControl) canvas.stop();
		// create a new mc and use that
		canvas = canvas.createEmptyMovieClip("canvas",canvas.getNextHighestDepth()) 
		
		conf.canvas = canvas
			
		bData = new BitmapData(w,h,true,0);
			
		bBuffer = bData.clone();
		bDraw = bData.clone();
			
		// attach bitmap that hold effect	
		canvas.attachBitmap(bData,canvas.getNextHighestDepth())
		
		// use a temp mc to draw target
		var target = canvas.attachMovie(conf.target,"target",1)
		target._visible = false;
				
		bBuffer.draw(target)
		target.removeMovieClip()
		
		// crop empty regions
		hitR = bitfade.AS2.utils.crop.hitBox(bBuffer)
		
		// drawed target
		bDraw.copyPixels(bBuffer,hitR,origin)
		
		
		with (hitR) {
			x = 0
			y = 0		
		}
		
		// center target
		pt.x = int((w - hitR.width)/2)
		pt.y = int((h - hitR.height)/2)
		
		// build gradient
		buildColorMap(conf.colorScheme)
			
		// call extenders custom init
		customInit();
		
		var self = this
		
		// update loop
		conf.canvas.onEnterFrame = function() {
			self.update()
		}
	}
	
	// destructor
	public function destroy() {
		with (conf) {
			// clean up
			canvas.onEnterFrame = null
			canvas.removeMovieClip();
			
			bData.dispose();
			bDraw.dispose();
			bBuffer.dispose();
			
			// restart timeline, if needed
			if (conf.mcControl && parent._totalframes > 1) parent.play();
		}
	}
	
	public function customInit() {
	}
		
	public function update() {
	}
		
}