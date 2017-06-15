package gl.utils
{
	import flash.display.Sprite;
	import flash.geom.Point;

	public class dynSprite extends Sprite
	{
		public var rp:Point;

		function dynSprite()
		{
			setRegistration();
		}

		public function setRegistration(x:Number=0, y:Number=0):void
		{
			rp = new Point(x, y);
		}

		public function get x2():Number
		{
			var p:Point = parent.globalToLocal(localToGlobal(rp));
			return p.x;
		}

		public function set x2(value:Number):void
		{
			var p:Point = parent.globalToLocal(localToGlobal(rp));
			x += value - p.x;
		}

		public function get y2():Number
		{
			var p:Point = parent.globalToLocal(localToGlobal(rp));
			return p.y;
		}

		public function set y2(value:Number):void
		{
			var p:Point = parent.globalToLocal(localToGlobal(rp));
			y += value - p.y;
		}

		public function get scaleX2():Number
		{
			return scaleX;
		}

		public function set scaleX2(value:Number):void
		{
			setProperty2("scaleX", value);
		}

		public function get scaleY2():Number
		{
			return scaleY;
		}

		public function set scaleY2(value:Number):void
		{
			setProperty2("scaleY", value);
		}

		public function get rotation2():Number
		{
			return rotation;
		}

		public function set rotation2(value:Number):void
		{
			setProperty2("rotation", value);
		}

		public function get mouseX2():Number
		{
			return Math.round(mouseX - rp.x);
		}

		public function get mouseY2():Number
		{
			return Math.round(mouseY - rp.y);
		}

		public function setProperty2(prop:String, n:Number):void
		{
			var a:Point = parent.globalToLocal(localToGlobal(rp));

			this[prop] = n;

			var b:Point = parent.globalToLocal(localToGlobal(rp));

			x -= b.x - a.x;
			y -= b.y - a.y;
		}
	}
}