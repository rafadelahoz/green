package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.tile.FlxTilemap;

import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxMath;
import flixel.util.FlxPoint;
import flixel.util.FlxRandom;
import flixel.group.FlxGroup;

import text.TextBox;

import world.Node;

class World extends FlxState
{
	public var player : Player;
	public var ground : FlxGroup;
	public var decoration : FlxGroup;
	public var elements : FlxGroup;
	public var exits : FlxGroup;
	
	public var SceneGraph : Map<String, Node>;
	public var currentSceneName : String;
	public var nextSceneName : String;
	
	public var currentScene : TiledScene;
	public var nextScene : TiledScene;
	
	public var currentGround : FlxObject;

	override public function create():Void
	{
		super.create();
		
		TextBox.Init(this);
		GamePad.init();
		
		FlxG.scaleMode = new flixel.system.scaleModes.PixelPerfectScaleMode();
				
		ground = new FlxGroup();
		add(ground);
		
		decoration = new FlxGroup();
		add(decoration);

		elements = new FlxGroup();
		add(elements);

		exits = new FlxGroup();
		add(exits);
		
		currentSceneName = null;
		nextSceneName = null;
		currentScene = null;
		nextScene = null;
		currentGround = null;
		
		loadScenesGraph();
		
		// buildHopwayScene();
		// buildBugCatcherScene();
		
		currentScene = loadScene(currentSceneName, 0, 0);
		
		createPlayer(FlxG.width / 2, -10);

		FlxG.camera.setBounds(-3750, 0, 10000, FlxG.height, true);
		FlxG.camera.follow(player, FlxCamera.STYLE_LOCKON, null, 14);
		
		FlxG.watch.add(FlxG.camera, "scroll");
	}
	
	override public function destroy():Void
	{
		super.destroy();
	}

	override public function update():Void
	{
		GamePad.update();
		
		if (currentScene != null)
			currentScene.collideWithLevel(player);
		FlxG.collide(ground, player);
		FlxG.collide(elements, player);

		FlxG.overlap(exits, player, onPlayerExitCollision);

		super.update();

		debugRoutines();
	}	
	
	function loadScene(sceneName : String, x : Int, y : Int, ?direction : Int = FlxObject.RIGHT) : TiledScene
	{
		var scene = new TiledScene(x, y, "assets/scenes/" + sceneName + ".tmx", (direction == FlxObject.LEFT));
		
		if (scene != null)
			add(scene.backgroundTiles);

		if (scene != null)
			scene.loadObjects(this);

		if (scene != null)
			add(scene.overlayTiles);
		
		trace("Loading scene " + sceneName + " at (" + scene.x + ", " + scene.y + ")");		
			
		return scene;
	}
	
	function createPlayer(x : Float, y : Float)
	{
		player = new Player(x, y, this);
		add(player);
		
		FlxG.camera.focusOn(player.getMidpoint());
		
		/*FlxG.watch.add(player, 	"x");
		FlxG.watch.add(player, 	"y");
		FlxG.watch.add(player, 	"onAir");*/
	}
	
	function buildHopwayScene()
	{
		var wallcolor : Int = 0x0083769C;
		
		FlxG.camera.setBounds(-3750, 0, 10000, FlxG.height, true);
		
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
		var currentNode : Node = SceneGraph.get(currentSceneName);
		var nextSceneNode : Node = null;
		if (nextSceneName != null)
			nextSceneNode = SceneGraph.get(nextSceneName);
			
		// TODO: This condition can be substituted by checking the state (in-scene, between-scenes)
		if (player.facing == exit.direction)
		{	
			if (!currentNode.exits.exists(exit.name))
			{
				trace("Invalid exit " + exit.name + " for current scene + " + currentSceneName);
				
				player.velocity.x *= -1;
				return;
			}
			
			var exitData : ExitData = currentNode.exits.get(exit.name);
		
			// Exiting!
			if (currentGround == null)
			{
				nextSceneName = exitData.node;
				
				trace("exiting towards " + nextSceneName);
				
				// Compute distance to next Scene
				var length : Int = exitData.hops * 10;

				var targetSceneX : Int = -1;
				// Generate the floor that joins the two scenes
				var floor : FlxSprite = null;
				switch (exit.direction)
				{
					case FlxObject.RIGHT:
						floor = new FlxSprite(exit.x, exit.y + exit.height).makeGraphic(length, 32, 0xFF83769C);
						targetSceneX = Std.int(exit.x + length);
					case FlxObject.LEFT:
						floor = new FlxSprite(exit.x - length, exit.y + exit.height).makeGraphic(length, 32, 0xFF83769C);
						targetSceneX = Std.int(exit.x - length);
				}
				floor.immovable = true;
				
				// Store and set it
				currentGround = floor;
				ground.add(currentGround);
					
				// TODO: Compute appropriate scene X considering taret exit X and scene height
				// TODO: Compute appropriate scene Y considering target exit floor alignment
				// TODO: Probably the scene will have to be loaded to compute the position
				
				// Load next scene tilemap & data at correct position
				nextScene = loadScene(exitData.node, targetSceneX, 0, exit.direction);
			}
		}
		else if (player.facing == oppositeDirectionOf(exit.direction))
		{
			if (nextSceneName == null)
				return;
		
			trace("Entering " + nextSceneName);
		
			if (nextSceneNode == null)
			{
				trace("Node not found: " + nextSceneName);
				return;
			}
			else if (!nextSceneNode.exits.exists(exit.name))
			{
				trace("Invalid entry " + exit.name + " for current scene + " + nextSceneName);
				return;
			}
			
			// NextScene tilemap and entity data is already loaded
			// free currentScene
			currentScene.destroy();
			// set currentScene = nextScene
			currentScene = nextScene;
			// set nextScene = null
			nextScene = null;
			
			// set currentNode = nextNode
			currentSceneName = nextSceneName;
			// set nextNode = null
			nextSceneName = null;
			// destroy currentGround & currentGround = null
			if (currentGround != null)
			{
				ground.remove(currentGround);
				currentGround.destroy();
				currentGround = null;
			}
		}
	}
	
	public static function oppositeDirectionOf(direction : Int) : Int
	{
		if (direction == FlxObject.LEFT)
			return FlxObject.RIGHT;
		else if (direction == FlxObject.RIGHT)
			return FlxObject.LEFT;
		else
			return FlxObject.NONE;
	}
	
	function loadScenesGraph()
	{
		SceneGraph = new Map<String, Node>();
		
		var s1 : Node = new Node("0");
		s1.exits.set("R1", { node : "1", exit : "L1", hops : 10 });
		s1.exits.set("L1", { node : "1", exit : "R1", hops : 10 });
		
		var s2 : Node = new Node("1");
		s2.exits.set("R1", { node : "0", exit : "L1", hops : 10 });
		s2.exits.set("L1", { node : "0", exit : "R1", hops : 10 });
		
		SceneGraph.set(s1.name, s1);
		SceneGraph.set(s2.name, s2);
		
		currentSceneName = "0";
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
		
		if (FlxG.keys.justPressed.P)
		{
			trace("Cam bounds: " + FlxG.camera.bounds);
			trace("World bounds: " + FlxG.worldBounds);
			trace("Zoom: " + FlxG.camera.zoom);
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