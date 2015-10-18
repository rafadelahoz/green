package;

import flixel.FlxG;

class GamePad
{
	public static var Left : Int = 0;
	public static var Right : Int = 1;
	
	static var CurrentState : Map<Int, Bool>;
	static var PreviousState : Map<Int, Bool>;
	
	public static function init()
	{
		CurrentState = new Map<Int, Bool>();
		CurrentState.set(Left, false);
		CurrentState.set(Right, false);
		
		PreviousState = new Map<Int, Bool>();
		PreviousState.set(Left, false);
		PreviousState.set(Right, false);
	}
	
	public static function update()
	{
		PreviousState = CurrentState;
		
		var touchRight : Bool = false;
		var touchLeft : Bool = false;
	
	#if !desktop
		for (touch in FlxG.touches.list)
		{
			if (touch.pressed)
			{
				touchLeft 	= (touch.screenX < FlxG.width / 2);
				touchRight 	= (touch.screenX > FlxG.width / 2);
			}
		}
	#end
		
		CurrentState = new Map<Int, Bool>();
		CurrentState.set(Left, touchLeft || FlxG.keys.pressed.LEFT);
		CurrentState.set(Right, touchRight || FlxG.keys.pressed.RIGHT);
	}
	
	public static function checkButton(button : Int) : Bool
	{
		return CurrentState.get(button);
	}

	public static function justPressed(button : Int) : Bool
	{
		return CurrentState.get(button) && !PreviousState.get(button);
	}

	public static function justReleased(button : Int) : Bool
	{
		return !CurrentState.get(button) && PreviousState.get(button);
	}
}