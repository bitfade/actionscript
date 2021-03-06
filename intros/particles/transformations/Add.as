/*

	Particles transformations: Add

*/
package bitfade.intros.particles.transformations {

	import bitfade.data.*
	import bitfade.data.particles.*
	import bitfade.utils.*

	public class Add {
		public static function apply(pFrom:LinkedListPool,pTo:LinkedListPool,pOutput:LinkedListPool):void {
		
			var nodeFrom: Particle3dLife = Particle3dLife(pFrom.head.next)
			var nodeTo: Particle3dLife = Particle3dLife(pTo.head.next)
			var node: Particle3dLife = Particle3dLife(pOutput.head.next)
  			
  			for (;nodeFrom;
  					nodeFrom = Particle3dLife(nodeFrom.next), 
  					nodeTo = Particle3dLife(nodeTo.next), 
  					node = Particle3dLife(node.next)) {
  				
  				node.x = nodeFrom.x + nodeTo.x
  				node.y = nodeFrom.y + nodeTo.y 
  				node.z = nodeFrom.z + nodeTo.z 
  				//node.life = nodeFrom.life + nodeTo.life
  				
  			}
		}
	}

}