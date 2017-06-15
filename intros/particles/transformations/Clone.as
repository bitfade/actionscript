/*

	Particles transformations: Clone

*/
package bitfade.intros.particles.transformations {

	import bitfade.data.*
	import bitfade.data.particles.*
	import bitfade.utils.*

	public class Clone {
		public static function from(pFrom:LinkedListPool):LinkedListPool {
		
			var p3dList:LinkedListPool = new LinkedListPool(Particle3dLife,Single.instance("Particle3dStack",Stack))
				
			var node: Particle3dLife 
			var nodeFrom: Particle3dLife = Particle3dLife(pFrom.head.next)
  			
  			for (;nodeFrom;nodeFrom = Particle3dLife(nodeFrom.next)) {
  				node = p3dList.create()
  				node.x = nodeFrom.x
  				node.y = nodeFrom.y
  				node.z = nodeFrom.z
  				node.life = nodeFrom.life
  				p3dList.append(node)
  			}
			return p3dList
		}
	}

}