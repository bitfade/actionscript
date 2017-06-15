/*
	scaling functions
*/
package bitfade.utils {

	import flash.geom.*
	
	public class Geom {
	
		public static const origin:Point = new Point()
		public static var sMatrix:Matrix = new Matrix()
		
		public static var pt:Point = new Point()
		public static var rect:Rectangle = new Rectangle()
		
		// split a string in object
		public static function splitProps(comma:String,numeric:Boolean = false):Object {
			var token:Array = comma.split(/,/);
			
			return numeric ? { h:parseFloat(token[0]), w:parseFloat(token[1])} : { h:token[0], w:token[1]}
		}
		
		// get a scaler object
		public static function getScaler(scaleMode:*,halign:String,valign:String,w:uint,h:uint,tw:uint,th:uint):Object {
			
			var info:Object = {}
			
			var rw:Number = w/tw
			var rh:Number = h/th
			var r:Number
			
		
						
			// get scale ratio
			if (scaleMode is String) {
				switch (scaleMode) {
					case "fill":
					case "fillmax":
						r = rw > rh ? rw : rh
						if (scaleMode == "fill") r = Math.min(1,r)
					break
					case "fit":
					case "fitmax":
						r = rw < rh ? rw : rh
						if (scaleMode == "fit") r = Math.min(1,r)
					break;
					case "none":
						r = 1
					break
				}
			} else {
				r = scaleMode
			}
			
			// scale ration
			info.ratio = r
			
			info.diff = {}
			info.offset = {}
			info.align = {w:halign,h:valign}
			
			// now compute offset with requested alignment
			with (info) {
				diff.w = offset.w = w-tw*r
				diff.h = offset.h = h-th*r
				
				switch (halign) {
					case "center":
						offset.w = diff.w / 2
					break
					case "left":
						offset.w = 0
				}
			
				switch (valign) {
					case "center":
						offset.h = diff.h / 2
					break
					case "top":
						offset.h = 0
				}
				
			}
			
			
			// return the scaler object
			return info
		}
		
		// get a scale matrix from a scaler object
		public static function getScaleMatrix(info:Object):Matrix {
			with (info) sMatrix.createBox(ratio,ratio,0,offset.w,offset.h)
			return sMatrix
		}
		
		// set a scale matrix using just offsets
		public static function getTranslateMatrix(tx:Number,ty:Number):Matrix {
			sMatrix.createBox(1,1,0,tx,ty)	
			return sMatrix
		}
		
		// set a scale matrix using just offsets
		public static function createBox(scaleX:Number,scaleY:Number,rotation:Number,tx:Number,ty:Number):Matrix {
			sMatrix.createBox(scaleX,scaleY,rotation,tx,ty)	
			return sMatrix
		}
		
		// return a point with given coordinates
		public static function point(x:int,y:int):Point {
			pt.x = x
			pt.y = y
			return pt
		}
		
		// return a rectangle with given parameters
		public static function rectangle(x:int,y:int,width:uint,height:uint):Rectangle {
			rect.x = x
			rect.y = y
			rect.width = width
			rect.height = height
			return rect
		}
	
	}

}
/* commentsOK */