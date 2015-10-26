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
	
	public var overridenControl : Bool = false;

	public function new(X : Float, Y : Float, World : World)
	{
		super(X, Y, World);

		loadGraphic("assets/images/frog-sheet-v0.png", true, 32, 24);
		animation.add("idle", [0]);
		animation.add("jump", [1]);
		animation.add("fall", [2]);

		animation.play("idle");

		setSize(12, 14);
		offset.set(10, 10);
		
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
		// Control can be overriden by others as required
		if (!overridenControl)
		{
			onAir = !isTouching(FlxObject.DOWN);
			
			// TODO: Handle only one direction, restart count if pressing another key
			if (GamePad.checkButton(GamePad.Right) || GamePad.checkButton(GamePad.Left))
			{
				jumpHoldTime = Math.min(jumpHoldTime + jumpHoldDelta, maxJumpHold);
			}
			
			if (!onAir)
			{
				// Allow jumping when touching ground
				canJump = true;
				
				// Stop moving
				velocity.x = 0;
				velocity.y = 0;

				// And display the idle graphic
				animation.play("idle");
			}
			else
			{
				// Gravity affects when onAir
				acceleration.y = Gravity;

				// Display the appropriate graphic when rising and falling
				if (velocity.y < 0)
					animation.play("jump");
				else if (velocity.y > 0)
					animation.play("fall");

				// When falling, hitting a wall stops horizontal movement
				if (velocity.y > 0 && (isTouching(FlxObject.RIGHT) || isTouching(FlxObject.RIGHT)))
				{
					velocity.x = 0;
				}
			}

			// Handle jumping
			if (canJump)
			{
				if (GamePad.justReleased(GamePad.Right))
				{
					velocity = calculateJumpSpeed(FlxObject.RIGHT);
					canJump = false;
					jumpHoldTime = 0;

					facing = FlxObject.RIGHT;
					flipX = false;
				}
				else if (GamePad.justReleased(GamePad.Left))
				{
					velocity = calculateJumpSpeed(FlxObject.LEFT);
					canJump = false;
					jumpHoldTime = 0;

					facing = FlxObject.LEFT;
					flipX = true;
				}
			}
			
			if (!GamePad.checkButton(GamePad.Right) && !GamePad.checkButton(GamePad.Left))
			{
				jumpHoldTime = 0;
			}
		}

		super.update();
		
		// Update debug jump strength display
		// updateDisplay();
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
		
		display.update();
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