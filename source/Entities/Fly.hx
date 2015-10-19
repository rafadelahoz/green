package;

import flixel.FlxG;
import flixel.util.FlxPoint;
import flixel.util.FlxRandom;
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
			targetX = FlxRandom.floatRanged(0, FlxG.width / 2);
		}
		else
		{
			targetX = FlxRandom.floatRanged(FlxG.width / 2, FlxG.width);
		}
		
		var targetY : Float = y;
		
		/*var controlX : Float = Math.abs(targetX - x) / 2;
		var controlY : Float = FlxRandom.floatRanged(FlxG.height / 2, 3 * FlxG.height / 4);*/
		var mousePos : FlxPoint = FlxG.mouse.getWorldPosition();
		
		var duration : Float = FlxRandom.floatRanged(1, 2);
		
		FlxTween.quadMotion(this, x, y, mousePos.x, mousePos.y, targetX, targetY, duration);
	}
	
	override public function update()
	{
		if (velocity.y < 0 && !isOnScreen())
			destroy();
	}
}