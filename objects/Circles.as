package bitfade.objects { 
	import flash.geom.*
	import flash.display.*
	import flash.filters.*
	import flash.events.*;
	import flash.text.*;
	import flash.utils.*
	
	[Embed('../../objects/circles/circles.swf', symbol='circles')]
	public class circles extends MovieClip {
	
		private var conf:Object = {
			spin: true,
			xm:true,
			ym:true,

			margin: 10,
			dx: 3,
			dy: 1,
			
			ty:150,
			k:.005,
			vy:3,
			ay:0,
			
			idx:0,
			steps:0,
			xs:0,
			ys:0,
			
			autoUpdate:true
		}
		
		private var w:uint
		private var h:uint
		
		public function circles(opts=null) {
			configure(opts)
			
			w = conf.w
			h = conf.h
			
			x = w/2
			y = h/2
			
			if (conf.autoUpdate) addEventListener(Event.ENTER_FRAME, update)
  		}
  		
  		public function configure(opts) {
  			if (!opts) return
  			
  			for (var p in opts) {
				conf[p] = opts[p];
			}
  			
  			with (conf) {
  				steps = 0
  				// stop spin
  				if (!spin) {
  					if (currentFrame > 1) {
	 					idx = 0
  						steps = ((currentFrame < 15) ? totalFrames :  2*totalFrames) - currentFrame			
  					
  					} else {
  						stop()
  					}
  				} else {
  					play()
  				}
  				// stop motion
  				if (!xm || !ym) {
  					xs = x
  					ys = y
  					if (steps == 0) steps = totalFrames/2
  					if (!ym) {
  						vy = 3
  						ay = 0
  					}
  				}
  			}
  		}
  		
  		
  		public function update(e=null) {
  			with (conf) {
  				if (xm) {
  					if (x > (w-(width/2)-margin) || x < width/2+margin) dx = -dx;
  					x += dx
  				}
  				
  				if (ym) {
	  				ay = (ty-y)*k;
					vy += ay;
					y = uint (y+vy);
	  			}
	  					
	  			if (steps > 0) {
	  				if (idx < steps) {
	  					if (!xm) x = uint((xs*(steps-idx)+w/2*idx)/steps)
	  					if (!ym) y = uint((ys*(steps-idx)+h/2*idx)/steps)
	 
	  					idx ++ 
	  				} else {
	  					steps = 0
	  					if (!spin) stop()
	  				}
	  			}
  			}
  			
  		}
 
	}
}