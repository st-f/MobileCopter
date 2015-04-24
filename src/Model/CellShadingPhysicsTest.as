package Model
{

	import away3d.containers.ObjectContainer3D;
	import away3d.containers.Scene3D;
	import away3d.entities.Mesh;
	import away3d.events.LoaderEvent;
	import away3d.events.MouseEvent3D;
	import away3d.materials.ColorMaterial;
	import away3d.materials.lightpickers.LightPickerBase;
	import away3d.materials.methods.CelDiffuseMethod;
	import away3d.materials.methods.CelSpecularMethod;
	import away3d.materials.methods.OutlineMethod;
	import away3d.primitives.CubeGeometry;
	import away3d.primitives.PlaneGeometry;
	import away3d.primitives.SphereGeometry;

	import awayphysics.collision.shapes.AWPConvexHullShape;
	import awayphysics.collision.shapes.AWPSphereShape;
	import awayphysics.collision.shapes.AWPStaticPlaneShape;
	import awayphysics.dynamics.AWPDynamicsWorld;
	import awayphysics.dynamics.AWPRigidBody;

	import flash.events.MouseEvent;
	import flash.geom.Vector3D;

	public class CellShadingPhysicsTest
	{
		private static const ITEMS_NUM:Number=40;
		private static const CUBE_SIZE:Number=120;
		private static const BULLET_SIZE:Number=5;
		private var _scene:Scene3D;
		private var _physicsWorld:AWPDynamicsWorld;
		private var _lightPicker:LightPickerBase;

		public function CellShadingPhysicsTest(scene:Scene3D, lightPicker:LightPickerBase, physicsWorld:AWPDynamicsWorld)
		{
			_physicsWorld=physicsWorld;
			_scene=scene;
			_lightPicker=lightPicker;
		}

		public function createTerrain():void
		{
			init();
			createGround();
			createObjects();
		}

		private function init():void
		{
			// init the physics world
			_physicsWorld=AWPDynamicsWorld.getInstance();
			_physicsWorld.initWithDbvtBroadphase();
			_physicsWorld.gravity=new Vector3D(0, -BULLET_SIZE, 0);
		}

		private function createGround():void
		{
			// create ground mesh
			var material:ColorMaterial=new ColorMaterial(0x252525);
			material.lightPicker=_lightPicker;
			var ground:Mesh=new Mesh(new PlaneGeometry(50000, 50000), material);
			ground.y=0;
			_scene.addChild(ground);
			// create ground shape and rigidbody
			var groundShape:AWPStaticPlaneShape=new AWPStaticPlaneShape(new Vector3D(0, 1, 0));
			var groundRigidbody:AWPRigidBody=new AWPRigidBody(groundShape, ground, 0);
			groundRigidbody.y=0;
			_physicsWorld.addRigidBody(groundRigidbody);
		}

		private var cubePool:Vector.<AWPRigidBody>;

		private function createObjects():void
		{
			cubePool=new Vector.<AWPRigidBody>();
			var materia:ColorMaterial=new ColorMaterial(0xEEEEEEE);
			materia.diffuseMethod=new CelDiffuseMethod();
			materia.specularMethod=new CelSpecularMethod(32);
			materia.addMethod(new OutlineMethod(0x111111, 0.1, true, true));
			materia.lightPicker=_lightPicker;
			var cube:CubeGeometry=new CubeGeometry(CUBE_SIZE, CUBE_SIZE, CUBE_SIZE);
			var model:Mesh=new Mesh(cube, materia);
			var shape:AWPConvexHullShape=new AWPConvexHullShape(model.geometry);
			//shape.localScaling=new Vector3D(1, 2, 0.5);
			var skin:Mesh;
			var body:AWPRigidBody;
			for (var i:int=0; i < ITEMS_NUM; i++)
			{
				skin=Mesh(model.clone());
				_scene.addChild(skin);
				body=new AWPRigidBody(shape, skin, 5);
				cubePool.push(body);
				body.friction=.9;
				body.position=new Vector3D(Math.random() * CUBE_SIZE, i * CUBE_SIZE + 200, Math.random() * 2 - 1000);
				_physicsWorld.addRigidBody(body);
			}
		}

		public function shake():void
		{
			var body:AWPRigidBody;
			for (var i:int=0; i < ITEMS_NUM; i++)
			{
				cubePool[i].position=new Vector3D(Math.random() * CUBE_SIZE, i * CUBE_SIZE + 200, Math.random() * 2 - 1000);
			}
		}

		public function shootSphere():void
		{
			/*var pos:Vector3D=_view.camera.position;
			var mpos:Vector3D=new Vector3D(event.localPosition.x, event.localPosition.y, event.localPosition.z);*/
			var pos:Vector3D=new Vector3D(0, 0, 0);
			var mpos:Vector3D=new Vector3D(0, 0, -600);

			var impulse:Vector3D=mpos.subtract(pos);
			impulse.normalize();
			impulse.scaleBy(200);

			// shoot a sphere
			var material:ColorMaterial=new ColorMaterial(0xb35b11);
			material.lightPicker=_lightPicker;

			var sphere:Mesh=new Mesh(new SphereGeometry(BULLET_SIZE), material);
			_scene.addChild(sphere);

			var shape:AWPSphereShape=new AWPSphereShape(BULLET_SIZE);
			var body:AWPRigidBody=new AWPRigidBody(shape, sphere, 2);
			body.position=pos;
			_physicsWorld.addRigidBody(body);

			body.applyCentralImpulse(impulse);
		}
	}
}
