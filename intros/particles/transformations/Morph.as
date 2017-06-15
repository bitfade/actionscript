/*

	Particles transformations: Morph
	
	will morph particlesListFrom to particlesListTo with a given ratio

*/
package bitfade.intros.particles.transformations {

	import bitfade.data.*
	import bitfade.data.particles.*
	import bitfade.utils.*

	public class Morph {
		public static function apply(pFrom:LinkedListPool,pTo:LinkedListPool,pOutput:LinkedListPool,ratio:Number):void {
		
			var nodeFrom: Particle3dLife = Particle3dLife(pFrom.head.next)
			var nodeTo: Particle3dLife = Particle3dLife(pTo.head.next)
			var node: Particle3dLife = Particle3dLife(pOutput.head.next)
  			
  			for (;nodeFrom;
  					nodeFrom = Particle3dLife(nodeFrom.next), 
  					nodeTo = Particle3dLife(nodeTo.next), 
  					node = Particle3dLife(node.next)) {
  				
  				node.x = nodeFrom.x + (nodeTo.x - nodeFrom.x)*ratio
  				node.y = nodeFrom.y + (nodeTo.y - nodeFrom.y)*ratio
  				node.z = nodeFrom.z + (nodeTo.z - nodeFrom.z)*ratio
  				node.life = nodeFrom.life + (nodeTo.life - nodeFrom.life)*ratio
  				
  			}
		}
	}

}