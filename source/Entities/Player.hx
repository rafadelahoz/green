package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.util.FlxPoint;
import flixel.util.FlxSpriteUtil;

class Player extends Entity
{
	public var Gravity : Float = 600;

	public var HSpeed : Float = 90;
	public var VSpeed : Float = 250;
	
	public var onAir : Bool;
	public var canJump : Bool;
	
	var jumpHoldTime : Float;
	var jumpHoldDelta : Float;
	var maxJumpHold : Float;
	
	var display : FlxSprite;

	public function new(X : Float, Y : Float, World : World)
	{
		super(X, Y, World);

		makeGraphic(16, 16, 0xFF8AF507);
		
		onAir = true;
		canJump = false;
		
		jumpHoldTime = 0;
		jumpHoldDelta = 1;
		maxJumpHold = 20;
		
		maxVelocity.set(400, 400);
		
		display = new FlxSprite(x - 2, y - 4).makeGraphic(20, 4, 0x00000000);
	}

	override public function update()
	{	
		onAir = !isTouching(FlxObject.DOWN);
		
		if (GamePad.checkButton(GamePad.Right) || GamePad.checkButton(GamePad.Left))
		{
			jumpHoldTime = Math.min(jumpHoldTime + jumpHoldDelta, maxJumpHold);
		}
		
		if (!onAir)
		{
			canJump = true;
			acceleration.y = 0;
			
			velocity.set();
		}
		else
		{
			acceleration.y = Gravity;
		}

		if (canJump)
		{
			if (GamePad.justReleased(GamePad.Right))
			{
				velocity = calculateJumpSpeed(FlxObject.RIGHT);
				canJump = false;
				jumpHoldTime = 0;
			}
			else if (GamePad.justReleased(GamePad.Left))
			{
				velocity = calculateJumpSpeed(FlxObject.LEFT);
				canJump = false;
				jumpHoldTime = 0;
			}
		}
		
		if (!GamePad.checkButton(GamePad.Right) && !GamePad.checkButton(GamePad.Left))
		{
			jumpHoldTime = 0;
		}

		super.update();
		
		updateDisplay();
	}
	
	function updateDisplay()
	{
		display.x = x - 2;
		display.y = y - 5;
		
		var length : Int = Std.int(jumpHoldTime / maxJumpHold * 20);
		
		FlxSpriteUtil.fill(display, 0x00000000);
		FlxSpriteUtil.drawRect(display, 0, 0, length, 4, 0xFF8AF507);
		
		if (FlxG.keys.pressed.RIGHT)
			FlxSpriteUtil.drawRect(display, 2, 0, 4, 4, 0xFF8888FF);
		if (FlxG.keys.justReleased.RIGHT)
			FlxSpriteUtil.drawRect(display, 8, 0, 4, 4, 0xFFFF8888);
		
		// display.update();
	}
	
	override public function draw()
	{
		super.draw();
		// display.draw();
	}
	
	function calculateJumpSpeed(direction : Int) : FlxPoint
	{
		var speed : FlxPoint = new FlxPoint();
		
		var powerBase : Float = jumpHoldTime / maxJumpHold;
		powerBase = powerBase * 0.5;
		
		speed.x = (0.5 + powerBase) * HSpeed * (direction == FlxObject.LEFT ? -1 : 1);
		speed.y = -(0.5 + powerBase) * VSpeed;
		
		return speed;
	}
}