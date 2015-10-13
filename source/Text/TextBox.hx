package text;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.text.FlxBitmapTextField;
import flixel.text.pxText.PxBitmapFont;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;

import openfl.Assets;

/**
 * @author Simon Zeni (Bl4ckb0ne)
 */

class TextBox extends FlxGroup
{
	var originX : Int = 8;
	var originY : Int = 10;
	
	var borderX : Int = 8;
	var borderY : Int = 8;
		
	var boxWidth : Int = Std.int(FlxG.width - 16);
	var boxHeight: Int = Std.int(FlxG.height / 2 - 16);

	private var _background:FlxSprite;
	private var _name:FlxBitmapTextField;
	private var _typetext:TypeWriter;
	private var _isTalking:Bool;
	private var _skip:FlxBitmapTextField;
	private var _callback:Dynamic;

	private static var textBox : TextBox;
	public static function Message(name : String, message : String, ?completeCallback:Dynamic)
	{
		if (textBox == null) 
		{
			textBox = new TextBox(name);
			textBox._callback = completeCallback;
			textBox.talk(message);
		}
	}

	override public function new(Name:String):Void
	{
		super();
		
		// Initialize the background image, you can use a simple FlxSprite fill with one color
		_background = new FlxSprite(originX, originY).makeGraphic(boxWidth, boxHeight, 0xFF010101);
		_background.scrollFactor.set(0, 0);
		
	 	// The name of the person who talk, from the arguments
		_name = PixelText.New(originX, originY, Name, 0xffbcbcbc);
		_name.scrollFactor.set(0, 0);

	 	// The skip text, you can change the key
		_skip = PixelText.New(originX + boxWidth - 32, originY + boxHeight - 8, "[OK!]", 0xffbcbcbc);
		_skip.scrollFactor.set(0, 0);

	 	// Initialize all the bools for the TextBox system
		_isTalking = false;
	}

	public function show():Void
	{
		add(_background);
		add(_name);
		add(_skip);
	}

	public function hide():Void	
	{
		remove(_background);
		remove(_name);
		remove(_typetext);
		remove(_skip);

		textBox.destroy();
		textBox = null;
	}

	public function talk(TEXT:String):Void
	{	
		if(!_isTalking) {
			_isTalking = true;
			
			_name.visible = false;
			_skip.visible = false;
			
			show();
			
			_background.scale.y = 0;			
			FlxTween.tween(_background.scale, {y: 1}, 0.08, { complete: function(_t:FlxTween) {
				// Set up a new TypeWriter for each text
				_typetext = new TypeWriter(originX + borderX, 
										   originY + borderY, 
										   boxWidth - borderX*2, 
										   boxHeight - borderY*2,
										   TEXT, 0xffdedede, 12);

				_typetext.scrollFactor.set();
				// _typetext.showCursor = true;
				// _typetext.cursorBlinkSpeed = 1.0;
				_typetext.setTypingVariation(0.75, true);
				_typetext.useDefaultSound = true;
				
				// Add it to the screen and start it
				add(_typetext);
				
				_name.visible = true;
				_skip.visible = true;
				
				_typetext.start(0.01, onCompleted);
			}});
		}
	}

	public function onCompleted(TIMER:FlxTimer = null):Void 
	{
		_name.visible = false;
		_skip.visible = false;
		_typetext.visible = false;
		
		FlxTween.tween(_background.scale, {y: 0}, 0.08, { complete: function(_t:FlxTween) {
			hide();	
			_isTalking = false;

			if (_callback != null)
				_callback();
		}});
	}

	override public function destroy():Void
	{
		super.destroy();
	}

	override public function update():Void
	{
		super.update();
		
		if (_typetext != null)
		{	
			if (_typetext.finished)
			{
				if (_typetext.thereIsMoreText)
					_skip.text = "[>>]"
				else
					_skip.text = "[Ok]";
			}
			else
			{
				_skip.text = "[...]";
			}
				
			
			if (GamePad.checkButton(GamePad.A))
				_skip.color = 0xFFffb300;
			else
				_skip.color = 0xFFbcbcbc;
		}
	}	
}