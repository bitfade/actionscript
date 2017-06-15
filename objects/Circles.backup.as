package bitfade.objects { 
	import flash.geom.*
	import flash.display.*
	import flash.filters.*
	import flash.events.*;
	import flash.text.*;
	import flash.utils.*
	import org.osflash.thunderbolt.Logger
	
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
			ay:0
		}
		
		private var w:uint
		private var h:uint
		
		private var stopped:Boolean=false;
	
		public function circles(opts) {
			configure(opts)
			
			w = conf.w
			h = conf.h
			
			x = w/2
			y = h/2
			
			addEventListener(Event.ENTER_FRAME, update)
  		}
  		
  		public function configure(opts) {
  			if (opts.xm && !conf.xm) {
  				conf.xs = x
  				conf.idx = 0
  				conf.steps = 10
  			}

  		
  			for (var p in opts) {
				conf[p] = opts[p];
			}
		
  			
			spin(conf.spin)
			if (conf.xm || conf.ym) move() 
  		}
  		
  		public function spin(s=true) {
  			if (s) {
  				gotoAndPlay(1)
  			} else {
  				//stopped = true
  				stop()
  			}
  		}
  		
  		private function update(e=null) {
  			if (stopped) {
  				if (currentFrame != 1) {
  					with (conf) {
  						x = (xs*(steps-idx)+w/2*idx)/steps
  						y = (ys*(steps-idx)+h/2*idx)/steps
  						idx ++
  					}
  				} else {
  					stop()
  				}
  			} else {
  				with (conf) {
  					if (xm) {
  						if (x > (w-(width/2)-margin) || x < width/2+margin) dx = -dx;
	  					x += dx
  					} else {
  						if (idx < steps) {
  							x = (xs*(steps-idx)+w/2*idx)/steps
  							idx ++
  						}
  					}
	  				
	  				if (ym) {
	  	  				ay = (ty-y)*k;
						vy += ay;
						y += vy;
	  				}
  				}
  			}
  		}
  		
  		public function pause() {
  			stopped = true
  			conf.idx = 0
  			conf.steps = totalFrames - currentFrame
  			conf.xs = x
  			conf.ys = y
  		}
  		
  		public function move() {
  			stopped = false
  			gotoAndPlay(1)
  		}
  		

	}
}