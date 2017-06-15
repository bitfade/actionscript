package bitfade.easing {
	public class Cubic {
		public static function In(t:Number, b:Number, c:Number, d:Number):Number {
			return c*(t/=d)*t*t + b;
		}
		public static function Out(t:Number, b:Number, c:Number, d:Number):Number {
			return c*((t=t/d-1)*t*t + 1) + b;
		}
		public static function InOut(t:Number, b:Number, c:Number, d:Number):Number {
			if ((t/=d/2) < 1) return c/2*t*t*t + b;
			return c/2*((t-=2)*t*t + 2) + b;
		}
		public static function OutIn(t:Number, b:Number, c:Number, d:Number):Number {
			if (t < d/2) return Out(t*2, b, c/2, d);
            return In((t*2)-d, b+c/2, c/2, d);
        }

	}
}
/* commentsOK */