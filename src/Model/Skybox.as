package Model
{
	import away3d.primitives.SkyBox;
	import away3d.textures.BitmapCubeTexture;

	import flash.display.BitmapData;
	import flash.filters.BlurFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	public class Skybox
	{

		[Embed(source="/assets/skybox/posx.jpg")]
		private var EnvPosX2:Class;
		[Embed(source="/assets/skybox/posy.jpg")]
		private var EnvPosY2:Class;
		[Embed(source="/assets/skybox/posz.jpg")]
		private var EnvPosZ2:Class;
		[Embed(source="/assets/skybox/negx.jpg")]
		private var EnvNegX2:Class;
		[Embed(source="/assets/skybox/negy.jpg")]
		private var EnvNegY2:Class;
		[Embed(source="/assets/skybox/negz.jpg")]
		private var EnvNegZ2:Class;

		//private var skyBoxCubeMap:SkyBox;
		//public var skyBox:SkyBox;
		public var bitmapCubeTexture:BitmapCubeTexture;

		public function Skybox(day:Boolean)
		{
			if (day)
			{
				bitmapCubeTexture=new BitmapCubeTexture(new EnvPosX2().bitmapData, new EnvNegX2().bitmapData, new EnvPosY2().bitmapData, new EnvNegY2().bitmapData, new EnvPosZ2().bitmapData, new EnvNegZ2().bitmapData);
			}
			else
			{
				bitmapCubeTexture=nightSkybox();
			}
		}

		public function nightSkybox():BitmapCubeTexture
		{
			var r:Rectangle=new Rectangle();
			var bmps:Vector.<BitmapData>=new Vector.<BitmapData>;
			var p:Point=new Point();

			var size:int=512;
			var num:int=900;
			for (var j:int=0; j < 6; j++)
			{
				var bmpd:BitmapData=new BitmapData(size, size, true, 0xFF000000);
				for (var i:int=0; i < num; i++)
				{
					r.x=size * Math.random();
					r.y=size * Math.random();
					if (i < 0.92 * num)
					{
						r.width=r.height=1;
					}
					else if (i < 0.98 * num)
					{
						r.width=r.height=2;
					}
					else
					{
						r.width=r.height=3;
					}

					var red:int=0xFF * (0.7 + 0.3 * Math.random());
					var green:int=0xFF * (0.7 + 0.3 * Math.random());
					var blue:int=0xFF * (0.7 + 0.3 * Math.random());
					var color:uint=(red << 16) | (green << 8) | (blue);
					bmpd.fillRect(r, 0xFF000000 | color);
				}
				r.x=r.y=0;
				r.width=size;
				r.height=size;
				bmpd.applyFilter(bmpd, r, p, new BlurFilter(1, 1, 5));

				bmps.push(bmpd);
			}
			return new BitmapCubeTexture(bmps[0], bmps[1], bmps[2], bmps[3], bmps[4], bmps[5]);
		}

	}
}
