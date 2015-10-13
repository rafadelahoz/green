package text;

import flixel.FlxG;
import flixel.text.FlxBitmapTextField;
import flixel.text.pxText.PxTextAlign;
import flixel.system.FlxSound;
import flixel.util.FlxRandom;

/**
 * Manages long chunks of text pixel font text, waiting for the user to confirm 
 * before clearing a full text box
 * This is loosely based on the FlxTypeText class inspired by TypeText by Noel Berry
 * @author Rafa de la Hoz
 */
class TypeWriter extends FlxBitmapTextField
{
	/**
	 * The delay between each character, in seconds.
	 */
	public var delay:Float = 0.05;
	
	/**
	 * The delay between each character erasure, in seconds.
	 */
	public var eraseDelay:Float = 0.02;
	
	/**
	 * Set to true to show a blinking cursor at the end of the text.
	 */
	public var showCursor:Bool = false;
	
	/**
	 * The character to blink at the end of the text.
	 */
	public var cursorCharacter:String = "|";
	
	/**
	 * The speed at which the cursor should blink, if shown at all.
	 */
	public var cursorBlinkSpeed:Float = 0.5;
	
	/**
	 * Text to add at the beginning, without animating.
	 */
	public var prefix:String = "";
	
	/**
	 * Whether or not to erase this message when it is complete.
	 */
	public var autoErase:Bool = false;
	
	/**
	 * How long to pause after finishing the text before erasing it. Only used if autoErase is true.
	 */
	public var waitTime:Float = 1.0;
	
	/**
	 * Whether or not to animate the text. Set to false by start() and erase().
	 */
	public var paused:Bool = false;
	
	/**
	 * If this is set to true, this class will use typetext.wav from flixel-addons for the type sound unless you specify another.
	 */
	public var useDefaultSound:Bool = false;
	
	/**
	 * The sound that is played when letters are added; optional.
	 */
	public var sound:FlxSound;
	
	/**
	 * An array of keys as string values (e.g. "SPACE", "L") that will advance the text.
	 */
	public var skipKeys:Array<String>;
	
	/**
	 * The text that will ultimately be displayed.
	 */
	private var _finalText:String = "";
	
	/**
	 * This function is called when the message is done typing.
	 */
	private var _onComplete:Dynamic = null;
	
	/**
	 * Optional parameters that will be passed to the _onComplete function.
	 */
	private var _onCompleteParams:Array<Dynamic>;
	
	/**
	 * This function is called when the message is done erasing, if that is enabled.
	 */
	private var _onErase:Dynamic = null;
	
	/**
	 * Optional parameters that will be passed to the _onErase function.
	 */
	private var _onEraseParams:Array<Dynamic>;
	
	/**
	 * This is incremented every frame by FlxG.elapsed, and when greater than delay, adds the next letter.
	 */
	private var _timer:Float = 0.0;
	
	/**
	 * A timer that is used while waiting between typing and erasing.
	 */
	private var _waitTimer:Float = 0.0;
	
	/**
	 * Internal tracker for current string length, not counting the prefix.
	 */
	private var _length:Int = 0;
	
	/**
	 * Whether or not to type the text. Set to true by start() and false by pause().
	 */
	private var _typing:Bool = false;
	
	/**
	 * Whether or not to erase the text. Set to true by erase() and false by pause().
	 */
	private var _erasing:Bool = false;
	
	/**
	 * Whether or not we're waiting between the type and erase phases.
	 */
	private var _waiting:Bool = false;
	
	/**
	 * Internal tracker for cursor blink time.
	 */
	private var _cursorTimer:Float = 0.0;
	
	/**
	 * Whether or not to add a "natural" uneven rhythm to the typing speed.
	 */
	private var _typingVariation:Bool = false;
	
	/**
	 * How much to vary typing speed, as a percent. So, at 0.5, each letter will be "typed" up to 50% sooner or later than the delay variable is set.
	 */
	private var _typeVarPercent:Float = 0.5;
	
	/**
	 * Helper string to reduce garbage generation.
	 */
	private static var helperString:String = "";
	
	public var finished : Bool;
	
	private static var lineHeight : Int = 10;
	
	private var targetHeight : Int;
	
	private var targetLines : Int;
	
	private var remainingText : String;
	
	public var thereIsMoreText (get, null) : Bool;
	public function get_thereIsMoreText() : Bool
	{
		return remainingText != null;
	}
	
	/**
	 * Line handling
	 */
	private var textLines : Array<String>;
	
	/**
	 * Create a FlxTypeText object, which is very similar to FlxText except that the text is initially hidden and can be
	 * animated one character at a time by calling start().
	 * 
	 * @param	X				The X position for this object.
	 * @param	Y				The Y position for this object.
	 * @param	Width			The width of this object. Text wraps automatically.
	 * @param	Text			The text that will ultimately be displayed.
	 * @param	Size			The size of the text.
	 * @param	EmbeddedFont	Whether this text field uses embedded fonts or not.
	 */
	public function new(X:Float, Y:Float, Width:Int, ?Height : Int = -1, Text:String, ?Color : Int = 0xFFFFFFFF, ?Size:Int = 8)
	{
		super(PixelText.font);
		textLines = [];
		
		x = X;
		y = Y;
		width = Width;
		text = "";
		color = 0xFFFFFFFF;
		useTextColor = false;
		textColor = Color;
		
		wordWrap = true;
		fixedWidth = true;
		width = Width;
		multiLine = true;
		lineSpacing = 4;
		
		_finalText = Text;
		
		lineHeight = Size;
		targetHeight = Height;
		targetLines = Std.int(targetHeight / lineHeight);
		
		_onComplete = null;
		_onErase = null;
		_onCompleteParams = [];
		_onEraseParams = [];
		skipKeys = [];
	}
	
	/**
	 * Set a function to be called when typing the message is complete.
	 * 
	 * @param	Callback	The callback function.
	 * @param	Params		Any params you want to pass to the function. Optional!
	 */
	public function setCompleteCallback(Callback:Dynamic, ?Params:Array<Dynamic>):Void
	{
		_onComplete = Callback;
		
		if (Params == null)
		{
			Params = [];
		}
		
		_onCompleteParams = Params;
	}
	
	/**
	 * Set a function to be called when erasing is complete.
	 * Make sure to set erase = true or else this will never be called!
	 * 
	 * @param	Callback		The callback function.
	 * @param	Params			Any params you want to pass to the function. Optional!
	 */
	public function setEraseCallback(Callback:Dynamic, ?Params:Array<Dynamic>):Void
	{
		_onErase = Callback;
		
		if (Params == null)
		{
			Params = [];
		}
		
		_onEraseParams = Params;
	}
	
	/**
	 * Start the text animation.
	 * 
	 * @param	Delay			Optionally, set the delay between characters. Can also be set separately.
	 * @param	ForceRestart	Whether or not to start this animation over if currently animating; false by default.
	 * @param	AutoErase		Whether or not to begin the erase animation when the typing animation is complete. Can also be set separately.
	 * @param	Sound			A FlxSound object to play when a character is typed. Can also be set separately.
	 * @param	SkipKeys		An array of keys as string values (e.g. "SPACE", "L") that will advance the text. Can also be set separately.
	 * @param	Callback		An optional callback function, to be called when the typing animation is complete.
	 * @param 	Params			Optional parameters to pass to the callback function.
	 */
	public function start(?Delay:Float, ForceRestart:Bool = false, AutoErase:Bool = false, ?Sound:FlxSound, ?SkipKeys:Array<String>, ?Callback:Dynamic, ?Params:Array<Dynamic>):Void
	{
		if (Delay != null)
		{
			delay = Delay;
		}
		
		_typing = true;
		_erasing = false;
		paused = false;
		_waiting = false;
		
		if (ForceRestart)
		{
			text = "";
			_length = 0;
		}
		
		autoErase = AutoErase;
		
		/*#if !FLX_NO_SOUND_SYSTEM
		if (Sound != null)
		{
			sound = Sound;
		}
		else if (useDefaultSound)
		{
			sound = FlxG.sound.load(new TypeSound());
		}
		#end*/
		
		if (SkipKeys != null)
		{
			skipKeys = SkipKeys;
		}
		
		if (Callback != null)
		{
			_onComplete = Callback;
		}
		
		if (Params != null)
		{
			_onCompleteParams = Params;
		}
		
		remainingText = null;
		finished = false;
	}
	
	/**
	 * Begin an animated erase of this text.
	 * 
	 * @param	Delay			Optionally, set the delay between characters. Can also be set separately.
	 * @param	ForceRestart	Whether or not to start this animation over if currently animating; false by default.
	 * @param	Sound			A FlxSound object to play when a character is typed. Can also be set separately.
	 * @param	SkipKeys		An array of keys as string values (e.g. "SPACE", "L") that will advance the text. Can also be set separately.
	 * @param	Callback		An optional callback function, to be called when the erasing animation is complete.
	 * @param	Params			Optional parameters to pass to the callback function.
	 */
	public function erase(?Delay:Float, ForceRestart:Bool = false, ?Sound:FlxSound, ?SkipKeys:Array<String>, ?Callback:Dynamic, ?Params:Array<Dynamic>):Void
	{
		_erasing = true;
		_typing = false;
		paused = false;
		_waiting = false;
		
		if (Delay != null)
		{
			eraseDelay = Delay;
		}
		
		if (ForceRestart)
		{
			_length = _finalText.length;
			text = _finalText;
		}
		
		/*#if !FLX_NO_SOUND_SYSTEM
		if (Sound != null)
		{
			sound = Sound;
		}
		else if (useDefaultSound)
		{
			sound = FlxG.sound.load(new TypeSound());
		}
		#end*/
		
		if (SkipKeys != null)
		{
			skipKeys = SkipKeys;
		}
		
		if (Callback != null)
		{
			_onErase = Callback;
		}
		
		if (Params != null)
		{
			_onEraseParams = Params;
		}
	}
	
	/**
	 * Reset the text with a new text string. Automatically cancels typing, and erasing.
	 * 
	 * @param	Text	The text that will ultimately be displayed.
	 */
	public function resetText(Text:String):Void
	{
		text = "";
		_finalText = Text;
		_typing = false;
		_erasing = false;
		paused = false;
		_waiting = false;
		finished = false;
		remainingText = null;
	}
	
	/**
	 * Define the keys that can be used to advance text.
	 * 
	 * @param	Keys	An array of keys as string values (e.g. "SPACE", "L") that will advance the text.
	 */
	public function setSkipKeys(Keys:Array<String>):Void
	{
		skipKeys = Keys;
	}
	
	/**
	 * Set a sound that will be played each time a letter is added to the text.
	 * 
	 * @param	Sound	A FlxSound object.
	 */
	public function setSound(Sound:FlxSound):Void
	{
		sound = Sound;
	}
	
	/**
	 * If called with On set to true, a random variation will be added to the rate of typing.
	 * Especially with sound enabled, this can give a more "natural" feel to the typing.
	 * Much more noticable with longer text delays.
	 * 
	 * @param	Amount		How much variation to add, as a percentage of delay (0.5 = 50% is the maximum amount that will be added or subtracted from the delay variable). Only valid if >0 and <1.
	 * @param	On			Whether or not to add the random variation. True by default.
	 */
	public function setTypingVariation(Amount:Float = 0.5, On:Bool = true):Void
	{
		_typingVariation = On;
		
		if (Amount > 0 && Amount < 1)
		{
			_typeVarPercent = Amount;
		}
		else
		{
			_typeVarPercent = 0.5;
		}
	}
	
	/**
	 * Internal function that is called when typing is complete.
	 */
	private function onComplete():Void
	{
		_timer = 0;
		_typing = false;
	
		if (_onComplete != null)
		{
			Reflect.callMethod(null, _onComplete, _onCompleteParams);
		}
		
		if (autoErase && waitTime <= 0)
		{
			_erasing = true;
		}
		else if (autoErase)
		{
			_waitTimer = waitTime;
			_waiting = true;
		}
	}
	
	private function onErased():Void
	{
		_timer = 0;
		_erasing = false;
		
		if (_onErase != null)
		{
			Reflect.callMethod(null, _onErase, _onEraseParams);
		}
	}
	
	override public function update():Void
	{
		// If the skip key was pressed, complete the animation.
		
		/*#if !FLX_NO_KEYBOARD
		if (skipKeys != null && skipKeys.length > 0 && FlxG.keys.anyJustPressed(skipKeys))
		{
			skip();
		}
		#end*/
		
		// When the message has finished, wait for the user to 
		// press a key before closing or continuing with the text
		if (finished)
		{
			if (GamePad.justPressed(GamePad.A))
			{
				finished = false;
				// If there is more text, we have not finished
				if (remainingText != null)
				{				
					resetText(remainingText);
					start(delay, true);
				}
				// If there is no more text, we are done
				else if (_typing)
				{
					onComplete();
				}
				// Or maybe we were erasing and we are done
				else if (_erasing)
				{
					onErased();
				}
			}
			
			return;
		}
		
		if (_waiting && !paused)
		{
			_waitTimer -= FlxG.elapsed;
			
			if (_waitTimer <= 0)
			{
				_waiting = false;
				_erasing = true;
			}
		}
		
		// So long as we should be animating, increment the timer by time elapsed.
		
		if (!_waiting && !paused)
		{
			if (_length < _finalText.length && _typing)
			{
				_timer += FlxG.elapsed * (GamePad.checkButton(GamePad.A) ? 10 : 1);
			}
			
			if (_length > 0 && _erasing)
			{
				_timer += FlxG.elapsed * (GamePad.checkButton(GamePad.A) ? 10 : 1);
			}
		}
		
		// If the timer value is higher than the rate at which we should be changing letters, increase or decrease desired string length.
		
		if (_typing || _erasing)
		{
			if (_typing && _timer >= delay)
			{
				_length ++;
			}
			
			if (_erasing && _timer >= eraseDelay)
			{
				_length --;
			}
			
			if ((_typing && _timer >= delay) || (_erasing && _timer >= eraseDelay))
			{
				if (_typingVariation )
				{
					if (_typing)
					{
						_timer = FlxRandom.floatRanged( -delay * _typeVarPercent / 2, delay * _typeVarPercent / 2);
					}
					else
					{
						_timer = FlxRandom.floatRanged( -eraseDelay * _typeVarPercent / 2, eraseDelay * _typeVarPercent / 2);
					}
				}
				else
				{
					_timer = 0;
				}
				
				/*#if !FLX_NO_SOUND_SYSTEM
				if (sound != null)
				{
					sound.play(true);
				}
				#end*/
			}
		}
		
		// Update the helper string with what could potentially be the new text.
		
		helperString = prefix + _finalText.substr(0, _length);
		
		// Append the cursor if needed.
		
		if (showCursor)
		{
			_cursorTimer += FlxG.elapsed;
			
			if (_cursorTimer > cursorBlinkSpeed / 2)
			{
				helperString += cursorCharacter.charAt(0);
			}
			
			if (_cursorTimer > cursorBlinkSpeed)
			{
				_cursorTimer = 0;
			}
		}
		
		// If the text changed, update it.
		
		if (helperString != text && !finished)
		{
			text = helperString;
			
			// Check for dramatic wrapping in the last line
			var alreadyFull : Bool = false;
			
			if (textLines.length >= targetLines-1)
			{
				var lineText = textLines[textLines.length-1];
				if (validWrapChar(lineText.charAt(lineText.length-1)))
				{
					var remainer : String = _finalText.substring(_length - 1);
					var remainerWords : Array<String> = remainer.split(" ");
					var nextWordChunk : String = remainerWords[0];
					
					var currentLineWidth = PixelText.font.getTextWidth(lineText);
					var nextWordWidth = PixelText.font.getTextWidth(nextWordChunk);
					if (currentLineWidth + nextWordWidth > width)
					{
						/*trace("Current line: " + lineText);
						trace("Cutting at:   " + lineText.charAt(lineText.length-1));
						trace("Remainer:     " + remainer);
						trace("Next word:    " + nextWordChunk);*/
						alreadyFull = true;
					}
				}
			}
			
			if (alreadyFull && targetHeight > 0 && _length < _finalText.length)
			{
				finished = true;

				// Remove 1 character
				text = text.substring(0, text.length-1);
				
				// We have run out of space!
				remainingText = _finalText.substring(_length - 1);
				
				// trace("There is no more space for: \n" + remainingText);
			}
			else
			{
			
				// If we're done typing, call the onComplete() function
				
				if (_length >= _finalText.length && _typing && !_waiting && !_erasing)
				{
					finished = true;					
				}
				
				// If we're done erasing, call the onErased() function
				
				if (_length == 0 && _erasing && !_typing && !_waiting)
				{
					finished = true;
				}
			}
		}
		
		super.update();
	}
	
	static inline function validWrapChar(char : String) : Bool
	{
		return char == " " || char == "." || char == ",";
	}
	
	/**
	 * Immediately finishes the animation. Called if any of the skipKeys is pressed.
	 * Handy for custom skipping behaviour (for example with different inputs like mouse or gamepad).
	 */
	/*public function skip():Void
	{
		if (_erasing || _waiting)
		{
			_length = 0;
			_waiting = false;
		}
		else if (_typing)
		{
			_length = _finalText.length;
		}
	}*/
	
	/**
	 * Don't look! Stop!
	 */ 
	override private function updateBitmapData():Void 
	{
		if (!_pendingTextChange) 
		{
			return;
		}
		
		if (_font == null)
		{
			return;
		}
		
		var preparedText:String = (_autoUpperCase) ? _text.toUpperCase() : _text;
		var calcFieldWidth:Int = 0; // Std.int(width);
		var rows:Array<String> = [];
		
		#if FLX_RENDER_BLIT
		var fontHeight:Int = Math.floor(_font.getFontHeight() * _fontScale);
		#else
		var fontHeight:Int = _font.getFontHeight();
		#end
		
		var alignment:Int = _alignment;
		
		// Cut text into pices
		var lineComplete:Bool;
		
		// Get words
		var lines:Array<String> = preparedText.split("\n");
		var i:Int = -1;
		var j:Int = -1;
		
		if (!_multiLine)
		{
			lines = [lines[0]];
		}
		
		var wordLength:Int;
		var word:String;
		var tempStr:String;
		
		while (++i < lines.length) 
		{
			if (_fixedWidth)
			{
				lineComplete = false;
				var words:Array<String> = [];
				
				if (!wordWrap)
				{
					words = lines[i].split("\t").join(_tabSpaces).split(" ");
				}
				else
				{
					words = lines[i].split("\t").join(" \t ").split(" ");
				}
				
				if (words.length > 0) 
				{
					var wordPos:Int = 0;
					var txt:String = "";
					
					while (!lineComplete) 
					{
						word = words[wordPos];
						var changed:Bool = false;
						var currentRow:String = txt + word;
						
						if (_wordWrap)
						{
							var prevWord:String = (wordPos > 0) ? words[wordPos - 1] : "";
							var nextWord:String = (wordPos < words.length) ? words[wordPos + 1] : "";
							if (prevWord != "\t") currentRow += " ";
							
							if (_font.getTextWidth(currentRow, _letterSpacing, _fontScale) > width) 
							{
								if (txt == "")
								{
									words.splice(0, 1);
								}
								else
								{
									rows.push(txt.substr(0, txt.length - 1));
								}
								
								txt = "";
								
								if (_multiLine)
								{
									if (word == "\t" && (wordPos < words.length))
									{
										words.splice(0, wordPos + 1);
									}
									else
									{
										words.splice(0, wordPos);
									}
								}
								else
								{
									words.splice(0, words.length);
								}
								
								wordPos = 0;
								changed = true;
							}
							else
							{
								if (word == "\t")
								{
									txt += _tabSpaces;
								}
								if (nextWord == "\t" || prevWord == "\t")
								{
									txt += word;
								}
								else
								{
									txt += word + " ";
								}
								wordPos++;
							}
						}
						else
						{
							if (_font.getTextWidth(currentRow, _letterSpacing, _fontScale) > width) 
							{
								if (word != "")
								{
									j = 0;
									tempStr = "";
									wordLength = word.length;
									while (j < wordLength)
									{
										currentRow = txt + word.charAt(j);
										
										if (_font.getTextWidth(currentRow, _letterSpacing, _fontScale) > width) 
										{
											rows.push(txt.substr(0, txt.length - 1));
											txt = "";
											word = "";
											wordPos = words.length;
											j = wordLength;
											changed = true;
										}
										else
										{
											txt += word.charAt(j);
										}
										
										j++;
									}
								}
								else
								{
									changed = false;
									wordPos = words.length;
								}
							}
							else
							{
								txt += word + " ";
								wordPos++;
							}
						}
						
						if (wordPos >= words.length) 
						{
							if (!changed) 
							{
								calcFieldWidth = Std.int(Math.max(calcFieldWidth, _font.getTextWidth(txt, _letterSpacing, _fontScale)));
								rows.push(txt);
							}
							lineComplete = true;
						}
					}
				}
				else
				{
					rows.push("");
				}
			}
			else
			{
				var lineWithoutTabs:String = lines[i].split("\t").join(_tabSpaces);
				calcFieldWidth = Std.int(Math.max(calcFieldWidth, _font.getTextWidth(lineWithoutTabs, _letterSpacing, _fontScale)));
				rows.push(lineWithoutTabs);
			}
		}
		
		var finalWidth:Int = (_fixedWidth) ? Std.int(width) : calcFieldWidth + _padding * 2 + (_outline ? 2 : 0);
		
		#if FLX_RENDER_BLIT
		var finalHeight:Int = Std.int(_padding * 2 + Math.max(1, (rows.length * fontHeight + (_shadow ? 1 : 0)) + (_outline ? 2 : 0))) + ((rows.length >= 1) ? _lineSpacing * (rows.length - 1) : 0);
		#else
		
		var finalHeight:Int = Std.int(_padding * 2 + Math.max(1, (rows.length * fontHeight * _fontScale + (_shadow ? 1 : 0)) + (_outline ? 2 : 0))) + ((rows.length >= 1) ? _lineSpacing * (rows.length - 1) : 0);
		
		width = frameWidth = finalWidth;
		height = frameHeight = finalHeight;
		frames = 1;
		origin.x = width * 0.5;
		origin.y = height * 0.5;
		
		_halfWidth = origin.x;
		_halfHeight = origin.y;
		#end
		
		#if FLX_RENDER_BLIT
		if (pixels == null || (finalWidth != pixels.width || finalHeight != pixels.height)) 
		{
			pixels = new BitmapData(finalWidth, finalHeight, !_background, _backgroundColor);
		} 
		else 
		{
			pixels.fillRect(cachedGraphics.bitmap.rect, _backgroundColor);
		}
		#else
		_drawData.splice(0, _drawData.length);
		_bgDrawData.splice(0, _bgDrawData.length);
		
		if (cachedGraphics == null)
		{
			return;
		}
		
		// Draw background
		if (_background)
		{
			// Tile_ID
			_bgDrawData.push(_font.bgTileID);		
			_bgDrawData.push( -_halfWidth);
			_bgDrawData.push( -_halfHeight);
			
			#if FLX_RENDER_TILE
			var colorMultiplier:Float = 1 / (255 * 255);
			
			var red:Float = (_backgroundColor >> 16) * colorMultiplier;
			var green:Float = (_backgroundColor >> 8 & 0xff) * colorMultiplier;
			var blue:Float = (_backgroundColor & 0xff) * colorMultiplier;
			
			red *= (color >> 16);
			green *= (color >> 8 & 0xff);
			blue *= (color & 0xff);
			#end
			
			_bgDrawData.push(red);
			_bgDrawData.push(green);
			_bgDrawData.push(blue);
		}
		#end
		
		if (_fontScale > 0)
		{
			#if FLX_RENDER_BLIT
			pixels.lock();
			#end
			
			// Render text
			var row:Int = 0;
			
			for (t in rows) 
			{
				// LEFT
				var ox:Int = 0;
				var oy:Int = 0;
				
				if (alignment == PxTextAlign.CENTER) 
				{
					if (_fixedWidth)
					{
						ox = Std.int((width - _font.getTextWidth(t, _letterSpacing, _fontScale)) / 2);
					}
					else
					{
						ox = Std.int((finalWidth - _font.getTextWidth(t, _letterSpacing, _fontScale)) / 2);
					}
				}
				if (alignment == PxTextAlign.RIGHT) 
				{
					if (_fixedWidth)
					{
						ox = Std.int(width) - Std.int(_font.getTextWidth(t, _letterSpacing, _fontScale));
					}
					else
					{
						ox = finalWidth - Std.int(_font.getTextWidth(t, _letterSpacing, _fontScale)) - 2 * padding;
					}
				}
				if (_outline) 
				{
					for (py in 0...(2 + 1)) 
					{
						for (px in 0...(2 + 1)) 
						{
							#if FLX_RENDER_BLIT
							_font.render(pixels, _preparedOutlineGlyphs, t, _outlineColor, px + ox + _padding, py + row * (fontHeight + _lineSpacing) + _padding, _letterSpacing);
							#else
							_font.render(_drawData, t, _outlineColor, color, alpha, px + ox + _padding - _halfWidth, py + row * (fontHeight * _fontScale + _lineSpacing) + _padding - _halfHeight, _letterSpacing, _fontScale);
							#end
						}
					}
					ox += 1;
					oy += 1;
				}
				if (_shadow) 
				{
					#if FLX_RENDER_BLIT
					_font.render(pixels, _preparedShadowGlyphs, t, _shadowColor, 1 + ox + _padding, 1 + oy + row * (fontHeight + _lineSpacing) + _padding, _letterSpacing);
					#else
					_font.render(_drawData, t, _shadowColor, color, alpha, 1 + ox + _padding - _halfWidth, 1 + oy + row * (fontHeight * _fontScale + _lineSpacing) + _padding - _halfHeight, _letterSpacing, _fontScale);
					#end
				}
				
				#if FLX_RENDER_BLIT
				_font.render(pixels, _preparedTextGlyphs, t, _textColor, ox + _padding, oy + row * (fontHeight + _lineSpacing) + _padding, _letterSpacing);
				#else
				_font.render(_drawData, t, _textColor, color, alpha, ox + _padding - _halfWidth, oy + row * (fontHeight * _fontScale + _lineSpacing) + _padding - _halfHeight, _letterSpacing, _fontScale, _useTextColor);
				#end
				row++;
			}
			
			#if FLX_RENDER_BLIT
			pixels.unlock();
			resetFrameBitmapDatas();
			dirty = true;
			#end
			
			textLines = rows;
		}
		
		_pendingTextChange = false;
	}
}