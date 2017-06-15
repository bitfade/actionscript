/*

	Particles transformations: Morph

*/
package bitfade.intros.particles.transformations {

	import bitfade.data.*
	import bitfade.data.particles.*
	import bitfade.utils.*

	public class Zero {
		public static function apply(pOutput:LinkedListPool):void {
		
			var node: Particle3dLife = Particle3dLife(pOutput.head.next)
  			
  			for (;node;node = Particle3dLife(node.next)) {
  				
  				node.x = 0
  				node.y = 0
  				//node.y = 0
  				//node.x = Math.random()*40-20
  				//node.y = Math.random()*40-20
  				
  				node.z = -Math.random()*200-200
  				
  			}
		}
	}

}