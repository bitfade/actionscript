/*

	Particles transformations: Explode

*/
package bitfade.intros.particles.transformations {

	import bitfade.data.*
	import bitfade.data.particles.*
	import bitfade.utils.*

	public class Explode {
		public static function apply(pFrom:LinkedListPool,pOutput:LinkedListPool):void {
		
			var nodeFrom: Particle3dLife = Particle3dLife(pFrom.head.next)
			var node: Particle3dLife = Particle3dLife(pOutput.head.next)
  			
  			for (;nodeFrom;
  					nodeFrom = Particle3dLife(nodeFrom.next), 
  					node = Particle3dLife(node.next)) {
  				
  				node.x = nodeFrom.x + Math.random()*(nodeFrom.x > 0 ? -20 : 20)
  				node.y = nodeFrom.y + Math.random()*(nodeFrom.y > 0 ? -20 : 20)
  				node.z = 300
  				node.life = 500
  				
  			}
		}
	}

}