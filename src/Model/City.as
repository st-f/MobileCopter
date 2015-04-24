package Model
{
	import away3d.containers.Scene3D;
	import away3d.core.base.Geometry;
	import away3d.entities.Mesh;
	import away3d.materials.ColorMaterial;
	import away3d.materials.lightpickers.LightPickerBase;
	import away3d.materials.methods.CelDiffuseMethod;
	import away3d.materials.methods.CelSpecularMethod;
	import away3d.materials.methods.OutlineMethod;
	import away3d.primitives.CubeGeometry;
	import away3d.primitives.PlaneGeometry;
	import away3d.primitives.WireframeCube;

	import com.greensock.TweenLite;

	import flash.geom.Vector3D;

	public class City
	{

		private static const ITEMS_NUM_PER_ROWS:Number=6;
		private static const ITEMS_ROWS:Number=36;
		private static const CUBE_SIZE_MIN:Number=1000;
		private static const CUBE_SIZE_MAX:Number=1400;
		private static const CUBE_HEIGHT_MIN:Number=8000;
		private static const CUBE_HEIGHT_MAX:Number=13500;
		private static const SPACING:Number=CUBE_SIZE_MIN / 2;
		private var _scene:Scene3D;
		private var _lightPicker:LightPickerBase;
		private var rowsPool:Vector.<Vector.<Mesh>>;
		private var cubesPool:Vector.<Mesh>;
		private var currentCube:CubeGeometry;
		private var currentMesh:Mesh;

		private var ground:Mesh;

		private var centerX:Number=CUBE_SIZE_MAX * ITEMS_NUM_PER_ROWS / -2;
		private var centerZ:Number=CUBE_SIZE_MAX * ITEMS_ROWS / -2;

		private static var material:ColorMaterial=new ColorMaterial(0x333333);

		public function City(scene:Scene3D, lightPicker:LightPickerBase)
		{
			_scene=scene;
			_lightPicker=lightPicker;
			material.lightPicker=_lightPicker;
			//material.diffuseMethod=new CelDiffuseMethod();
			//material.specularMethod=new CelSpecularMethod(32);
			//material.addMethod(new OutlineMethod(0xFFFFFF, 10, true, true));
		}

		public function createCity():void
		{
			ground=new Mesh(new PlaneGeometry(50000, 50000), material);
			ground.y=-CUBE_HEIGHT_MAX / 2;
			_scene.addChild(ground);
			rowsPool=new Vector.<Vector.<Mesh>>();
			createAll();
			positionAll();
			startAnimation();
		}

		private var currentCubeHeight:Number;

		private function createAll():void
		{
			for (var rowIndex:int=0; rowIndex < ITEMS_ROWS; rowIndex++)
			{
				cubesPool=new Vector.<Mesh>();
				for (var i:int=0; i < ITEMS_NUM_PER_ROWS; i++)
				{
					currentCubeHeight=(CUBE_HEIGHT_MAX - CUBE_HEIGHT_MIN) * Math.random() + CUBE_HEIGHT_MIN;
					currentCube=new CubeGeometry(CUBE_SIZE_MAX, currentCubeHeight, CUBE_SIZE_MAX);
					currentMesh=new Mesh(currentCube, material);
					currentMesh.position=new Vector3D(i * (CUBE_SIZE_MAX + SPACING) + centerX, currentCubeHeight / 2 - CUBE_HEIGHT_MAX, rowIndex * (-CUBE_SIZE_MAX - SPACING) + centerZ * 2);
					cubesPool.push(currentMesh);
					_scene.addChild(currentMesh);
				}
				rowsPool.push(cubesPool);
			}
		}

		private function restartAnimation():void
		{
			trace("RESTART ANIMATION");
			positionAll();
			startAnimation();
		}

		private function positionAll():void
		{
			for (var rowIndex:int=0; rowIndex < ITEMS_ROWS; rowIndex++)
			{
				for (var i:int=0; i < ITEMS_NUM_PER_ROWS; i++)
				{
					currentMesh=rowsPool[rowIndex][i];
					currentCubeHeight=currentMesh.maxY - currentMesh.minY;
					currentMesh.position=new Vector3D(i * (CUBE_SIZE_MAX + SPACING) + centerX, currentCubeHeight / 2 - CUBE_HEIGHT_MAX, rowIndex * (-CUBE_SIZE_MAX - SPACING) + centerZ * 1.5);
				}
			}
		}

		private function startAnimation():void
		{
			for (var rowIndex:int=0; rowIndex < ITEMS_ROWS; rowIndex++)
			{
				for (var i:int=0; i < ITEMS_NUM_PER_ROWS; i++)
				{
					if (rowIndex != ITEMS_ROWS - 1 && i != ITEMS_NUM_PER_ROWS - 1)
					{
						TweenLite.to(rowsPool[rowIndex][i], 11, {z: (rowsPool[rowIndex][i].z - centerZ * 4)});
					}
					else
					{
						//last one
						TweenLite.to(rowsPool[rowIndex][i], 11, {z: (rowsPool[rowIndex][i].z - centerZ * 4), onComplete: restartAnimation});
					}
				}
			}
		}
	}
}
