import bitfade.AS2.presets.gradients

class bitfade.AS2.utils.colors {

	// helper: convert hex color to object
	public static function hex2rgb(hex) {
		return {
			a:hex >>> 24,
			r:hex >>> 16 & 0xff,
			g:hex >>> 8 & 0xff, 
			b:hex & 0xff 
		}
	}

	// build gradient based on preset or custom colors
	public static function buildColorMap(colorMap,c) {
		if (c == undefined) c = "ocean";
		
		if (typeof(c) == "string") {
			c = gradients[c]
			if (!c) c=gradients.ocean
		} else if (typeof(c) == "Number") {
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
		
		var cur:Object,next:Object;
		var rs:Number,gs:Number,bs:Number,al:Number,color:Number
		
		// for each sub gradient
		for (var g=0;g<ng;g++) {
			// we compute the difference between 2 colors 
		
			// current color
			cur = hex2rgb(c[g])
			// next color
			next = hex2rgb(c[g+1])
			
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
	}
}

	