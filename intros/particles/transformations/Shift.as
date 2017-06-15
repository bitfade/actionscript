/*

	Particles transformations: Shift

*/
package bitfade.intros.particles.transformations {

	import bitfade.data.*
	import bitfade.data.particles.*
	import bitfade.utils.*

	public class Shift {
		public static function apply(pFrom:LinkedListPool,pOutput:LinkedListPool):void {
		
			var nodeFrom: Particle3dLife = Particle3dLife(pFrom.head.next)
			var node: Particle3dLife = Particle3dLife(pOutput.head.next)
  			
  			for (;nodeFrom;
  					nodeFrom = Particle3dLife(nodeFrom.next), 
  					node = Particle3dLife(node.next)) {
  				
  				node.x = nodeFrom.x 
  				node.y = nodeFrom.y 
  				node.z = 200+Math.random()*100
  				
  				node.life = 500
  				
  				
  			}
		}
	}

}