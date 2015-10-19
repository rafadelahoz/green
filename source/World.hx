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
	public var decoration : FlxGroup;
	public var elements : FlxGroup;
	public var exits : FlxGroup;
	public var scene : TiledScene;
	public var nextScene : TiledScene;

	override public function create():Void
	{
		super.create();
		
		TextBox.Init(this);
		GamePad.init();
		
		FlxG.scaleMode = new flixel.system.scaleModes.PixelPerfectScaleMode();
		
		scene = new TiledScene("assets/scenes/0.tmx");
		add(scene.backgroundTiles);

		ground = new FlxGroup();
		add(ground);
		
		// buildHopwayScene();
		// buildBugCatcherScene();
		
		FlxG.watch.add(FlxG.camera, "deadzone");

		decoration = new FlxGroup();
		add(decoration);

		elements = new FlxGroup();
		add(elements);

		exits = new FlxGroup();
		add(exits);

		createPlayer(FlxG.width / 2, -10);

		scene.loadObjects(this);

		add(scene.overlayTiles);

		FlxG.camera.setBounds(0, 0, 4000, scene.fullHeight, true);
		FlxG.camera.follow(player, FlxCamera.STYLE_LOCKON, null, 14);
	}
	
	override public function destroy():Void
	{
		super.destroy();
	}

	override public function update():Void
	{
		GamePad.update();
		
		scene.collideWithLevel(player);
		FlxG.collide(ground, player);
		FlxG.collide(elements, player);

		FlxG.overlap(exits, player, onPlayerExitCollision);

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

	function onPlayerExitCollision(exit : Exit, player : Player)
	{
		if (player.facing == exit.direction)
		{
			if (exit.floor == null)
			{
				trace("exit");
				var length : Int = exit.hops * 100;

				var floor : FlxSprite = null;
				switch (exit.direction)
				{
					case FlxObject.RIGHT:
						floor = new FlxSprite(exit.x, exit.y + exit.height).makeGraphic(length, 32, 0xFF83769C);
					case FlxObject.LEFT:
						floor = new FlxSprite(exit.x - length, exit.y + exit.height).makeGraphic(length, 32, 0xFF83769C);
				}

				floor.immovable = true;

				exit.floor = floor;
				trace(exit.floor);

				ground.add(floor);

				/*nextScene = new TiledScene("assets/scenes/" + exit.target + ".tmx");
				// nextScene.backgroundTiles.x = exit.x + length;
				add(nextScene.backgroundTiles);
				nextScene.loadObjects(this);*/

				exits.remove(exit);
			}
		}
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