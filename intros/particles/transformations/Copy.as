/*

	Particles transformations: Copy

*/
package bitfade.intros.particles.transformations {

	import bitfade.data.*
	import bitfade.data.particles.*
	import bitfade.utils.*

	public class Copy {
		public static function apply(pFrom:LinkedListPool,pOutput:LinkedListPool):void {
		
			var nodeFrom: Particle3dLife = Particle3dLife(pFrom.head.next)
			var node: Particle3dLife = Particle3dLife(pOutput.head.next)
  			
  			for (;nodeFrom;
  					nodeFrom = Particle3dLife(nodeFrom.next), 
  					node = Particle3dLife(node.next)) {
  				
  				node.x = nodeFrom.x 
  				node.y = nodeFrom.y 
  				node.z = nodeFrom.z 
  				node.life = nodeFrom.life 
  				
  			}
		}
	}

}