package;

import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.math.FlxRandom;
import flixel.tweens.FlxTween;

class Fly extends Entity
{
	public function new(X : Float, Y : Float, World : World)
	{
		super(X, Y, World);

		makeGraphic(8, 8, 0xFFFF004D);

		calculatePath();
	}

	function calculatePath() : Void
	{
		var targetX : Float = 0;

		if (x > FlxG.width / 2)
		{
			targetX = FlxG.random.float(0, FlxG.width / 2);
		}
		else
		{
			targetX = FlxG.random.float(FlxG.width / 2, FlxG.width);
		}

		var targetY : Float = y;

		/*var controlX : Float = Math.abs(targetX - x) / 2;
		var controlY : Float = FlxG.random.float(FlxG.height / 2, 3 * FlxG.height / 4);*/
		var mousePos : FlxPoint = FlxG.mouse.getWorldPosition();

		var duration : Float = FlxG.random.float(1, 2);

		FlxTween.quadMotion(this, x, y, mousePos.x, mousePos.y, targetX, targetY, duration);
	}

	override public function update(elapsed : Float)
	{
		if (velocity.y < 0 && !isOnScreen())
			destroy();
	}
}
