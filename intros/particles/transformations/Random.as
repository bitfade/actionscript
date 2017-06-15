/*

	Particles transformations: Morph

*/
package bitfade.intros.particles.transformations {

	import bitfade.data.*
	import bitfade.data.particles.*
	import bitfade.utils.*

	public class Random {
		public static function apply(pOutput:LinkedListPool):void {
		
			var node: Particle3dLife = Particle3dLife(pOutput.head.next)
  			
  			for (;node;node = Particle3dLife(node.next)) {
  				
  				node.x = Math.random()*800-400
  				node.y = Math.random()*800-400
  				node.z = Math.random()*800-400
  				
  				node.life = Math.random()*500
  				
  			}
		}
	}

}