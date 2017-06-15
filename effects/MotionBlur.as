package bitfade.effects { 
	
	import flash.geom.*
	import flash.display.*
	import flash.events.*
	import flash.filters.*
	
	public class motionBlur extends Sprite {
		// hold the effect
		private var bMap:Bitmap;
		private var bData:BitmapData;
		
		// default conf
		// autoUpdate: ... you guess it
		private var conf:Object = {autoUpdate:true};
		
		// see later
		private var copyCT:ColorTransform;
		private var fadeCT:ColorTransform;
		private var bF:BlurFilter
		private var box:Rectangle;
		private var wdir:Point;
		
		// stuff
		private var origin:Point;
		private var inited:Boolean=false;
		
		
		function motionBlur(opts:Object){
			
			// get the conf
			for (var p in opts) {
				conf[p] = opts[p];
			}
			var t = conf.target
			
			// if no width or height was given, try to autodetect
			if (!conf.width) conf.width = t.width;
			if (!conf.height) conf.height = t.height;
			
			// same position as container
			x = t.x
			y = t.y
			
			// this will hold the effect
			bMap = new Bitmap()
			
			// colorTrasform used to copy the target
			fadeCT = new ColorTransform(1,1,1,0.9,0,0,0,0);
			// colorTrasform used to fade out the effect
			copyCT = new ColorTransform(1,1,1,0.15,0,0,0,0);
			// blur filter
			bF = new BlurFilter(0,0,1);
			
			// wind direction
			wdir = new Point(0,0);

			
			// some stuff
			origin = new Point(0,0);
			box = new Rectangle(0,0,conf.width,conf.height);
			
			// if auto update is false, you need to maually call init() and update()
			if (conf.autoUpdate) init();
			
		}
		
		
		// this is used to set basic parameters
		// copy: alpha value for copy
		// fade: alpha value for fade
		// x,y,q : used to set the blur filter
		public function blur(copy=15,fade=90,x=0,y=0,q=1) {
			copyCT.alphaMultiplier = copy/100;
			fadeCT.alphaMultiplier = fade/100;
			with(bF) {
				blurX = x;
				blurY = y;
				quality = q;
			}
		}
		
		// add wind 
		public function wind(x=0,y=0) {
			wdir.x = x;
			wdir.y = y;
		}
		
		// advanced parameters 
		// cCol: hex color used as rgb multipliers for copy
		// fCol: hex color used as rgb multipliers for fade
		// mode: blend mode
		public function color(cCol=0xffffff,fCol=0xffffff,mode="normal") {
			bMap.blendMode = mode
			CT("copyCT",cCol)
			CT("fadeCT",fCol)

		}
		
		// helper: convert hex color to object (used internally)
		private function hex2rgb(hex) {
			return {
				a:hex >>> 24,
				r:hex >>> 16 & 0xff,
				g:hex >>> 8 & 0xff, 
				b:hex & 0xff 
			}
		}
		
		// helper: set the colortrasform
		public function CT(which,col) {
			var c=hex2rgb(col)
			with(this[which]) {
				redMultiplier=c.r/0xff
				greenMultiplier=c.g/0xff
				blueMultiplier=c.b/0xff
			}
		}
		
		// set defaults
		public function reset() {
			blur();
			wind();
			color();
		}
		
		// init stuff
		public function init() {
		
			if (inited) {
				bData.dispose();
			} else {
				addChild(bMap)
			}
			// create the bitmap	
			bData = new BitmapData(conf.width, conf.height, true,0x000000);
			bMap.bitmapData = bData;
			
			// add handler for auto update, if needed
			if (!inited && conf.autoUpdate) {
				addEventListener(Event.ENTER_FRAME,update)
			}
			inited = true;
			update()
		}
		
		// do the magic
		public function update(e=null) {
			// lock the bitmap, so no change will be display until we finish
			bData.lock()
			// apply a blur filter, if defined
			if (bF.blurX != 0 || bF.blurY != 0) bData.applyFilter(bData,box,origin, bF);
			
			/*
				now, we need to fade out what we have drawn at previous steps.
				for this, we use a colorTrasform ()
				
				-----------------------------------------------------------------------------------------------
				from: http://livedocs.adobe.com/flash/9.0/ActionScriptLangRefV3/flash/geom/ColorTransform.html
				
				The ColorTransform class lets you adjust the color values in a display object. 
				The color adjustment or color transformation can be applied to all four channels: 
				red, green, blue, and alpha transparency. 
				
				When a ColorTransform object is applied to a display object, a new value for each color channel is calculated like this:
				
				New red value = (old red value * redMultiplier) + redOffset 
				New green value = (old green value * greenMultiplier) + greenOffset 
				New blue value = (old blue value * blueMultiplier) + blueOffset 
				New alpha value = (old alpha value * alphaMultiplier) + alphaOffset 
				
				If any of the color channel values is greater than 255 after the calculation, it is set to 255. 
				If it is less than 0, it is set to 0.
				-----------------------------------------------------------------------------------------------
				
				so, basicly, we just need to set alphaMultiplier < 1
				
			*/
			bData.colorTransform(box,fadeCT);
			
			// scroll the bitmap to wind direction, if defined
			if (wdir.x != 0 || wdir.y != 0 ) bData.scroll(wdir.x,wdir.y);
			
			// draw our target using a different colorTrasform, so we can tweak more
			bData.draw(conf.target,null,copyCT,null,box)
			// unlock the bitmap
			bData.unlock();
		}
		
	}
}