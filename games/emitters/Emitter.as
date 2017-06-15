/*

	Particles emitter

*/
package bitfade.games.emitters {

	import bitfade.data.*
	import bitfade.games.data.*
	import bitfade.utils.*

	public class Emitter {
	
		public var max:uint
		protected var active
		public var x:Number = 0
		public var y:Number = 0
		public var r:Number = 50
		public var vx:Number = 20
		public var vy:Number = 20
		
		public var list = LinkedListPool
		
		public function Emitter(max:uint = 100) {		
			init(max)
		}
		
		public function init(max:uint = 100) {
			this.max = max
			list = new LinkedListPool(Particle2d,Single.instance("Particle3dStack",Stack))
		}
			
		
		public function emit(n:uint = 0) {
			n = n || max
			
			var node: Particle2d
			
			var x:Number = x
			var y:Number = y
			var r:Number = this.r
			var r2:Number = this.r/2
			
			var vx:Number = this.vx
			var vx2:Number = this.vx / 2
			
			var vy:Number = this.vy
			var vy2:Number = this.vy / 2
			
			active = list.length
			for (var i:uint = 0;i<n; i++) {
				if (active >= max) break;
				active++
				
				node = list.create()
				
				node.ox = 0
				node.oy = 0
				
				//node.x = x+Math.random()*r-r2
				//node.y = y+Math.random()*r-r2
				node.x = x
				node.y = y
				
				node.vx = Math.random()*vx-vx2
				node.vy = Math.random()*vy-vy2
				
				//node.vx = Math.random()*vx
				//node.vy = Math.random()*vy
				
				
				list.append(node)
				
			}
		}
	}

}