/*

	Transition manager, handles advanced bitmap transitions
	Extends bitfade.transitions.simple which has basic transitions

*/
package bitfade.transitions { 

	import flash.geom.*
	import flash.display.*
	import flash.filters.*
	
	import bitfade.utils.Geom
	import bitfade.easing.*
	import bitfade.transitions.Simple
	
	public class Advanced extends bitfade.transitions.Simple {
		
		protected var colorT:ColorTransform
		
		// some needed stuff
		public static const origin:Point = new Point()
		
		// constructor
		public function Advanced(t,b=null) {
			colorT = new ColorTransform(1,1,1,1,0,0,0,0)
			super(t,b)
		} 
	
		// hilight transition
		public function hilight(from,to,t,duration) {
			
			// cross fade 
			fade(from,to,t,duration)
			
			// clear stuff
			clear()
			
			if (t < duration/2) {
				// if first transition half, increase amount
				colorT.alphaMultiplier = Linear.In(t,0,1,duration/2)
			} else {
				// else decrease
				colorT.alphaMultiplier = Linear.In(t-duration/2,1,-1,duration/2)
			}
			// redraw target
			target.draw(target,null,colorT,"add")

			
		}
		
		// fade to white transition
		public function white(from,to,t,duration) {
			
			// fill buffer with white
			buffer.fillRect(box,0xFFFFFFFF)
			//buffer.fillRect(box,0xFFAAAAAA)
			
			if (from) {
				target.copyPixels(from,box,origin)
			}
			
			if (t < duration/2) {
				// if first transition half, increase amount
				colorT.alphaMultiplier = Expo.In(t,0,1,duration/2)
			} else {
				// else decrease
				if (to) {
					// copy "to"
					target.copyPixels(to,box,origin)
				} else {
					target.fillRect(box,0)
				}
				colorT.alphaMultiplier = Linear.In(t-duration/2,1,-1,duration/2)
			}
			// redraw target
			target.draw(buffer,null,colorT,"add")		
		}
		
		// color level compose transition
		public function compose(from,to,t,duration) {
			
			// get level
			current = uint(Linear.In(t,0,0xFF,duration))
			
			if (from) {
				// copy "from" if defined
				target.copyPixels(from,box,origin)
			} else {
				target.fillRect(box,0)
			}
			
			if (to) {
				// if "to", copy pixels with red component < level
				buffer.threshold(to, box,origin,">=", current, 0,0xFF,true)
				target.copyPixels(buffer,box,origin,null,null,true)
			}
			
		}
		
		// hide previous, show next transition
		public function hideshow(from,to,t,duration) {
			
			target.fillRect(box,0)
			
			if (to) {
				// if "to", hide to bottom
				current = uint(Expo.Out(t,0,h,duration))
				p.y = h-current
				p.x = uint((h-current)/4)	
				target.copyPixels(to,box,p)
			} 
			
			if (from) {
				// if from, show to top
				current = uint(Expo.Out(t,0,h,duration))
				p.y = current
				p.x = -uint(current/4)
				target.copyPixels(from,box,p,null,null,true)
			} 
		}
		
		// expand height transition
		public function expandHeight(from,to,t,duration) {
			expand(from,to,t,duration,true)
		}
		
		// expand width transition
		public function expandWidth(from,to,t,duration) {
			expand(from,to,t,duration,false)
		}
		
		// expand transition
		public function expand(from,to,t,duration,vertical:Boolean = true) {
			
			clear()
			
			// copy "from" or clear target
			if (from) {
				target.copyPixels(from,box,origin)
			} else {
				target.fillRect(box,0)
			}
			
			if (to) {
				// set axe and dimention by direction/vertical options
				var axe:String="x"
				var max:uint=w
			
				if (vertical) {
					axe = "y"
					max = h
				} 
				
				// center
				var half:uint = max/2
				
				// current axe position
				current = uint(Expo.Out(t,0,half,duration))
				
				var dbl:uint = current << 1
				// alpha level
				var alpha:int = uint(0xFF*current/half)
				
				// clear buffer
				buffer.fillRect(box,0)
				
				// fill max alpha box
				r[axe] = half-current
				r.width = vertical ? w : dbl
				r.height = vertical ? dbl : h
				buffer.fillRect(r,alpha << 24)
				
				if (vertical) {
					r.height = 1
				} else {
					r.width = 1
				}
				
				// draw a gradient with decreasing alpha 
				for (var pos:int = r[axe];pos >= 0 && alpha > 0x10;pos-- ) {
					r[axe] = pos;
					alpha -= 2
					buffer.fillRect(r,alpha << 24)
					r[axe] = max-pos
					buffer.fillRect(r,alpha << 24)
				}
				
				// copy "to" using buffer mask
				target.copyPixels(to,box,origin,buffer,origin,true)
			}
			
			
		}
		
	}
}