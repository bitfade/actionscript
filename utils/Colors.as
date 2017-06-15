/*
	this are helper functions used build gradients
*/
package bitfade.utils { 

	import bitfade.presets.Gradients

	public class Colors {
		
		// helper: convert hex color to object (used internally)
		public static function hex2rgb(hex:uint,forceAlpha:int = -1):RgbaColor {
			return new RgbaColor(
				(forceAlpha >= 0) ? forceAlpha : hex >>> 24,
				hex >>> 16 & 0xFF,
				hex >>> 8 & 0xFF, 
				hex & 0xFF
			)		
		}
		
		// build gradient based on preset or custom colors
		public static function buildColorMap(c = "ocean",forceAlpha:int = -1,forceBlackStart:Boolean = false):Array {
		
			var colorMap:Array = new Array(256)
		
			if (c is String) {
				c = Gradients[c]
				if (!c) c=Gradients.ocean
			} else if (c is uint) {
				if (c < 0x01000000) {
					c=[0,0xFF000000 | c ]
				} else {
					c=[0,c]
				}
			} 
			
			// we have c.length colors
			// final gradient will have 256 values (0xFF) 
			
			var idx=0;
			
			// number of sub gradients = number of colors - 1
			var ng=c.length-1
			
			// each sub gradient has 256/ng values
			var step=256/ng;
			
			var cur:RgbaColor,next:RgbaColor;
			var rs:Number,gs:Number,bs:Number,al:Number,color:uint
			
			if (forceBlackStart) {
				c[0] = 0
			}
			
			// for each sub gradient
			for (var g=0;g<ng;g++) {
				// we compute the difference between 2 colors 
			
				// current color
				cur = hex2rgb(c[g],forceAlpha)
				// next color
				next = hex2rgb(c[g+1],forceAlpha)
				
				// RED delta
				rs = (next.r-cur.r)/(step)
				// GREEN delta
				gs = (next.g-cur.g)/(step)
				// BLUE delta
				bs = (next.b-cur.b)/(step)
				// ALPHA delta
				al = (next.a-cur.a)/(step)
				
				// compute each value of the sub gradient
				for (var i=0;i<=step;i++) {
					colorMap[idx] = cur.a << 24 | cur.r << 16 | cur.g << 8 | cur.b;
					cur.r += rs
					cur.g += gs
					cur.b += bs
					cur.a += al
					idx++
				}
			}
			
			return colorMap
		}
		
		// mix 2 palettes 
		public static function mix(from:Array,to:Array,target:Array,factor:Number):void {
			var a:uint,r:uint,g:uint,b:uint,i:uint,cf:uint,ct:uint
		
			for (i=1;i<256;i++) {
				cf = from[i]
				ct = to[i]
				a = uint(((cf >>> 24)*(100-factor) + (ct >>> 24)*factor)/100 + .5)
				r = uint(((cf >>> 16 & 0xFF)*(100-factor) + (ct >>> 16 & 0xFF)*factor)/100 + .5)
				g = uint(((cf >>> 8 & 0xFF)*(100-factor) + (ct >>> 8 & 0xFF)*factor)/100 + .5)
				b = uint(((cf & 0xFF)*(100-factor) + (ct & 0xFF)*factor)/100 + .5)
				target[i] = a << 24 | r << 16 | g << 8 | b
			}
		}
 		
	}
}

internal class RgbaColor {
	public var r:Number
	public var g:Number
	public var b:Number
	public var a:Number
	
	public function RgbaColor(av,rv,gv,bv) {
		r = rv
		g = gv
		b = bv
		a = av
	}
	
}
/* commentsOK */