package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxCamera;

import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxMath;
import flixel.util.FlxPoint;
import flixel.util.FlxRandom;
import flixel.group.FlxGroup;

import text.TextBox;

class World extends FlxState
{
	public var player : Player;

	public var ground : FlxGroup;

	public var elements : FlxGroup;

	override public function create():Void
	{
		super.create();
		
		// bgColor= 0xFF222202;
		
		TextBox.Init(this);
		GamePad.init();
		
		FlxG.scaleMode = new flixel.system.scaleModes.PixelPerfectScaleMode();
		// FlxG.fixedTimestep = false;
		// FlxG.scaleMode = new flixel.system.scaleModes.StageSizeScaleMode();
		
		ground = new FlxGroup();
		add(ground);
		
		buildHopwayScene();
		// buildBugCatcherScene();
		
		FlxG.watch.add(FlxG.camera, "deadzone");

		elements = new FlxGroup();
		add(elements);

		FlxG.camera.follow(player, FlxCamera.STYLE_LOCKON, null, 14);
	}
	
	override public function destroy():Void
	{
		super.destroy();
	}

	override public function update():Void
	{
		GamePad.update();
		
		FlxG.collide(ground, player);
		FlxG.collide(elements, player);

		super.update();

		debugRoutines();
	}	
	
	function createPlayer(x : Float, y : Float)
	{
		player = new Player(x, y, this);
		add(player);
		
		FlxG.camera.focusOn(player.getMidpoint());
		
		FlxG.watch.add(player, 	"x");
		FlxG.watch.add(player, 	"y");
		FlxG.watch.add(player, 	"velocity");
		FlxG.watch.add(player, 	"onAir");
		FlxG.watch.add(FlxG, 	"worldBounds");
	}
	
	function buildHopwayScene()
	{
		var wallcolor : Int = 0x0083769C;
		
		FlxG.camera.setBounds(-3750, 0, 10000, FlxG.height, true);
		// FlxG.camera.setBounds(0, 0, FlxG.width, FlxG.height, true);
		
		var g : FlxSprite = new FlxSprite(-4000, FlxG.height - 16).makeGraphic(Std.int(FlxG.camera.bounds.width), 2, wallcolor);
		g.solid = true;
		g.immovable = true;
		
		ground.add(g);
		
		createPlayer(FlxG.camera.bounds.x + FlxG.camera.bounds.width / 2, -16);
	}
	
	function buildBugCatcherScene()
	{
		FlxG.camera.setBounds(0, 0, FlxG.width, FlxG.height, true);
	
		var wallcolor : Int = 0x0083769C;
		var wallwidth : Int = 32;
	
		var g : FlxSprite = new FlxSprite(0, FlxG.height - 16).makeGraphic(FlxG.width, 2, wallcolor);
		g.solid = true;
		g.immovable = true;
		
		ground.add(g);

		g = new FlxSprite(0, 0).makeGraphic(wallwidth, FlxG.height, wallcolor);
		g.immovable = true;
		ground.add(g);

		g = new FlxSprite(FlxG.width - wallwidth, 0).makeGraphic(wallwidth, FlxG.height, wallcolor);
		g.immovable = true;
		ground.add(g);
		
		createPlayer(FlxG.width / 2, 0);
	}

	function debugRoutines()
	{
		var mousePos : FlxPoint = FlxG.mouse.getWorldPosition();

		if (FlxG.keys.pressed.ONE)
		{
			add(new Fly(FlxRandom.floatRanged(0, FlxG.width), -10, this));
		}
		else if (FlxG.keys.justPressed.TWO) 
		{
			elements.add(new Balloon(mousePos.x, mousePos.y, this));
		}
		
		if (FlxG.keys.justPressed.T)
		{
			FlxG.camera.followLerp = 0;
			player.x += 100;
			FlxG.camera.focusOn(player.getMidpoint());
		}
		else
		{
			FlxG.camera.followLerp = 14;
		}
	}
}