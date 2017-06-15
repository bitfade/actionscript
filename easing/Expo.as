package bitfade.easing {
	public class Expo {
		public static function In(t:Number, b:Number, c:Number, d:Number):Number {
			return (t==0) ? b : c * Math.pow(2, 10 * (t/d - 1)) + b;
		}
		public static function Out(t:Number, b:Number, c:Number, d:Number):Number {
			return (t==d) ? b+c : c * (-Math.pow(2, -10 * t/d) + 1) + b;
		}
		public static function InOut(t:Number, b:Number, c:Number, d:Number):Number {
			if (t==0) return b;
			if (t==d) return b+c;
			if ((t/=d/2) < 1) return c/2 * Math.pow(2, 10 * (t - 1)) + b;
			return c/2 * (-Math.pow(2, -10 * --t) + 2) + b;
		}
		public static function OutIn (t:Number, b:Number, c:Number, d:Number):Number {
			if (t < d/2) return Out(t*2, b, c/2, d);
			return In((t*2)-d, b+c/2, c/2, d);
		}
	}
}