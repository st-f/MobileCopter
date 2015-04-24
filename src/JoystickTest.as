package
{
	import com.Hero;
	import com.bit101.components.Label;
	import com.controls.Joystick;

	import flash.display.MovieClip;
	import flash.display.Sprite;

	public class JoystickTest extends Sprite
	{
		public function JoystickTest()
		{
			var hero:Hero=new Hero();
			hero.x=stage.stageWidth / 2;
			hero.y=stage.stageHeight / 2;
			addChild(hero);

			var joystick:Joystick=new Joystick(30, 30, hero);
			addChild(joystick);
			var label:Label=new Label();
			label.text="test";
			addChild(label);
		}
	}
}
