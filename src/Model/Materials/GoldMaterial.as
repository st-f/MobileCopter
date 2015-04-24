package Model.Materials
{
	import away3d.materials.ColorMaterial;
	import away3d.materials.methods.FresnelEnvMapMethod;

	public class GoldMaterial
	{
		public var material:ColorMaterial;

		public function GoldMaterial()
		{
			var material:ColorMaterial=new ColorMaterial(0xFFFF00);
			material.gloss=.2;
			material.specular=.2;
			var fres:FresnelEnvMapMethod=new FresnelEnvMapMethod()
			fres.normalReflectance=.3;
			fres.fresnelPower=.5;
			material.addMethod(fres);
			material.ambient=.7
		}
	}
}
