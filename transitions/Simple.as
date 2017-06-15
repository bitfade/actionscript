/*

	Transition manager, handles bitmap transition

*/
package bitfade.transitions { 

	import flash.geom.*
	import flash.display.*
	import flash.filters.*
	
	import bitfade.easing.*
	
	public class Simple {
		
		// some needed stuff
		public static const origin:Point = new Point()
		
		protected var target:BitmapData
		protected var buffer:BitmapData
		protected var box:Rectangle
		protected var w:uint = 0;
		protected var h:uint = 0;
		
		protected var current:uint = 0;
		
		protected var p:Point;
		protected var r:Rectangle;
		protected var bF:BlurFilter;
		
		public var crossFade:Boolean = false;
	
		// constructor
		public function Simple(t,b=null) {
			
			// set target
			target = t
			
			// if no buffer, create one
			buffer = b ? b : t.clone()
			box = target.rect
			
			// set dimentions
			w = target.width
			h = target.height
			
			// create geom stuff
			p = new Point();
			r = new Rectangle()
			
			// create the blur filter
			bF = new BlurFilter(0,0,1)
		} 
	
		// resets things
		public function clear() {
			r.x = p.x = 0
			r.y = p.y = 0
			
			r.width = w
			r.height = h
			
		}
	
		// fade transition
		public function fade(from,to,t,duration) {
			current = uint(Linear.In(t,0,0xFF,duration))
			
			if (from) {
				if (crossFade) {
					// if crossFade, copy faded out "from"
					buffer.fillRect(box,(0xFF-current) << 24)
					target.fillRect(box,0)
					target.copyPixels(from,box,origin,buffer,origin,true)
				} else {
					// no crossfade, copy "from"
					target.copyPixels(from,box,origin)
				}
			} else {
				// no original, just clear
				target.fillRect(box,0)
			}
			
			// copy "to"
			if (to) {
				buffer.fillRect(box,current << 24)
				target.copyPixels(to,box,origin,buffer,origin,true)
			}
		}
		
		public function slideLeft(from,to,t,duration) {
			slide(from,to,t,duration,-1,false)
		}
		
		public function slideRight(from,to,t,duration) {
			slide(from,to,t,duration,1,false)
		}
		
		public function slideTop(from,to,t,duration) {
			slide(from,to,t,duration,-1,true)
		}
		
		public function slideBottom(from,to,t,duration) {
			slide(from,to,t,duration,1,true)
		}
		
		// slide transition
		public function slide(from,to,t,duration,dir:int=-1,vertical:Boolean = false) {
			
			// clear stuff
			clear()
			
			// set axe and dimention by direction/vertical options
			var axe:String="x"
			var dim:String="width"
			var max:uint=w
			
			if (vertical) {
				axe = "y"
				dim = "height"
				max = h
			} 
			
			// get current transition value
			current = uint(Cubic.Out(t,0,max,duration))
			
			// set blur to right axe
			bF.blurX = bF.blurY = 2
			bF["blur"+axe.toUpperCase()] = uint(Cubic.Out(t,max/4,-max/4,duration))
			
			// clear buffer
			buffer.fillRect(box,0)
			
			if (from) {
				if (dir<0) {
					r[axe] = current
				} else {
					p[axe] = current
				}
				r[dim] = max-current
				
				// copy "from"
				buffer.copyPixels(from,r,p,null,null,true)
			} 
			
			if (dir < 0) {
				p[axe] = max-current
				r[axe] = 0
			} else {
				p[axe] = 0
				r[axe] = max-current
			}
			r[dim] = current
			
			// copy "to"
			if (bF.blurX > 0 && bF.blurY > 0) {
				if (to) buffer.copyPixels(to,r,p,null,null,true)
				target.applyFilter(buffer,box,origin,bF)
			} else if (to) {
				target.fillRect(box,0)
				target.copyPixels(to,r,p,null,null,true)
			}
			
		}
		
		// saw transition
		public function saw(from,to,t,duration) {
		
			// clear stuff
			clear()
			
			// get current value
			current = uint(Cubic.Out(t,0,0xFF,duration))
			
			// set blur filter
			bF.blurX = uint(Cubic.Out(t,w/4,-w/4,duration))
			bF.blurY = 0
			
			var cw:uint = uint(current*w/0xFF)
			var icw:uint = w-cw
			
			// copy "from" (same code as fade transition)
			if (from) {
				if (crossFade) {
					buffer.fillRect(box,(0xFF-current) << 24)
					target.fillRect(box,0)
					target.copyPixels(from,box,origin,buffer,origin,true)
				} else {
					target.copyPixels(from,box,origin)
				}
			} else {
				target.fillRect(box,0)
			}
			

			r.height = 1
			
			var invert:Boolean = false;
			
			// copy to
			if (to) {
				for (var yp:uint = 0; yp<h; yp += 1) {
					r.y = p.y = yp
					if (invert) {
						r.x = 0
						p.x = icw
						r.width = cw
						target.copyPixels(to,r,p,null,null,true)
					} else {
						p.x = 0
						r.x = icw
						r.width = cw
						target.copyPixels(to,r,p,null,null,true)
					}
					invert = !invert
				}
			}
			
		}
		
	}
}