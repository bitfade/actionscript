/*
	Linear ease function
*/
package bitfade.easing {
	public class Linear {
		public static function In(t:Number, b:Number, c:Number, d:Number):Number {
			return c*t/d + b;
		}
		public static function Out(t:Number, b:Number, c:Number, d:Number):Number {
			return c*t/d + b;
		}
		public static function InOut(t:Number, b:Number, c:Number, d:Number):Number {
			return c*t/d + b;
		}
	}
}
/* commentsOK */