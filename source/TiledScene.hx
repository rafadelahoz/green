package;

import haxe.io.Path;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.util.FlxRect;
import flixel.util.FlxPoint;
import flixel.group.FlxGroup;
import flixel.tile.FlxTilemap;

import utils.tiled.TiledMap;
import utils.tiled.TiledObject;
import utils.tiled.TiledObjectGroup;
import utils.tiled.TiledTileSet;
import utils.tiled.TiledImage;

class TiledScene extends TiledMap
{
	private inline static var spritesPath = "assets/images/";
	private inline static var tilesetPath = "assets/tilesets/";
	
	public var name : String;

	public var x : Int;
	public var y : Int;

	public var overlayTiles    : FlxGroup;
	public var foregroundTiles : FlxGroup;
	public var backgroundTiles : FlxGroup;
	public var collidableTileLayers : Array<FlxTilemap>;
	
	public var meltingsPerSecond : Float;

	public function new(X : Float, Y : Float, sceneName : String, ?offsetByWidth : Bool = false, 
						?floorHeight : Float = 0, ?entryDoor : String = null)
	{
		name = sceneName;
		var tiledLevel : String = "assets/scenes/" + sceneName + ".tmx";

		super(tiledLevel);
		
		x = Std.int(X);
		y = Std.int(Y);
		
		if (offsetByWidth)
			x -= fullWidth;
			
		// Match floor height with the specified entry door
		if (entryDoor != null)
		{
			var door : TiledObject = locateDoor(entryDoor);
			if (door != null)
			{
				y = Std.int(y + door.y - floorHeight);
				trace("Found exit '" + entryDoor + "', new Y is: " + y);
			}
		}

		overlayTiles = new FlxGroup();
		foregroundTiles = new FlxGroup();
		backgroundTiles = new FlxGroup();
		collidableTileLayers = new Array<FlxTilemap>();

		/* Read config info */
		
		/* Read tile info */
		for (tileLayer in layers)
		{
			var tilesetName : String = tileLayer.properties.get("tileset");
			if (tilesetName == null)
				throw "'tileset' property not defined for the " + tileLayer.name + " layer. Please, add the property to the layer.";

			// Locate the tileset
			var tileset : TiledTileSet = null;
			for (ts in tilesets) {
				if (ts.name == tilesetName) 
				{
					tileset = ts;
					break;
				}
			}

			// trace(tilesetName);

			if (tileset == null)
				throw "Tileset " + tilesetName + " could not be found. Check the name in the layer 'tileset' property or something.";

			var processedPath = buildPath(tileset);

			var tilemap : FlxTilemap = new FlxTilemap();
			tilemap.widthInTiles = width;
			tilemap.heightInTiles = height;
			tilemap.loadMap(tileLayer.tileArray, processedPath, tileset.tileWidth, tileset.tileHeight, 0, 1, 1, 1);
			tilemap.x = x;
			tilemap.y = y;
			
			if (tileLayer.properties.contains("overlay"))
			{
				overlayTiles.add(tilemap);
			}
			else if (tileLayer.properties.contains("solid")) 
			{
				collidableTileLayers.push(tilemap);
			}
			else
			{
				backgroundTiles.add(tilemap);
			}
		}
	}

	public function loadObjects(state : World) : Void
	{
		for (group in objectGroups)
		{
			for (o in group.objects)
			{
				loadObject(o, group, state);
			}
		}
	}

	private function loadObject(o : TiledObject, g : TiledObjectGroup, state : World) : Void
	{
		var x : Int = o.x + this.x;
		var y : Int = o.y + this.y;

		// The Y position of objects created from tiles must be corrected by the object height
		if (o.gid != -1) {
			y -= o.height;
		}

		switch (o.type.toLowerCase()) 
		{
			case "exit":
				// trace("Exit at ("+x+","+y+")");
				var dir : String = o.custom.get("direction");
				var name : String = o.custom.get("name");
				
				var exit : Exit = new Exit(x, y, state, this, o.width, o.height);
				exit.init(name, dir);
				state.exits.add(exit);
		
			/*case "oneway":
				var oneway : FlxObject = new FlxObject(x, y, o.width, o.height);
				oneway.allowCollisions = FlxObject.UP;
				oneway.immovable = true;
				state.oneways.add(oneway);*/
		
		/** Collectibles **/
		
		/** Elements **/
			case "decoration":
				// trace("adding decoration!");
				var gid = o.gid;
				var tiledImage : TiledImage = getImageSource(gid);
				if (tiledImage == null)
				{
					trace("Could not locate image source for gid=" + gid + "!");
				}
				else
				{
					var decoration : Decoration = new Decoration(x, y, state, tiledImage);
					state.decoration.add(decoration);
				}
				
		/** Enemies **/
			/*case "runner":
				var jumper : Bool = o.custom.contains("jumper");
				var runner : EnemyRunner = new EnemyRunner(x, y, state, jumper);
				initEnemy(runner, o);
				state.addEnemy(runner);
			case "walker": 
				var hazardType : Hazard.HazardType = getHType(o);
				var walker : EnemyWalker = new EnemyWalker(x, y, state);
				initEnemy(walker, o);
				walker.hazardType = hazardType;
				state.addEnemy(walker);*/
			default:
				// !
		}
	}
	
	function getImageSource(gid : Int) : TiledImage
	{
		var image : TiledImage = imageCollection.get(gid);
		image.imagePath = "assets/tilesets/detail/" + image.sourceImage;
		return image;
	}

	public function collideWithLevel(obj : FlxObject, ?notifyCallback : FlxObject -> FlxObject -> Void, ?processCallback : FlxObject -> FlxObject -> Bool) : Bool
	{
		if (collidableTileLayers != null)
		{
			for (map in collidableTileLayers) 
			{
				// Remember: Collide the map with the objects, not the other way around!
				return FlxG.overlap(map, obj, notifyCallback, processCallback != null ? processCallback : FlxObject.separate);
			}
		}

		return false;
	}
	
	private function buildPath(tileset : TiledTileSet, ?spritesCase : Bool  = false) : String
	{
		var imagePath = new Path(tileset.imageSource);
		var processedPath = (spritesCase ? spritesPath : tilesetPath) + 
			imagePath.file + "." + imagePath.ext;

		return processedPath;
	}

	public function destroy() 
	{
		backgroundTiles.destroy();
		foregroundTiles.destroy();
		overlayTiles.destroy();
		for (layer in collidableTileLayers)
			layer.destroy();
	}
	
	function locateDoor(name : String) : TiledObject
	{
		for (group in objectGroups)
		{
			for (o in group.objects)
			{
				if (o.type.toLowerCase() == "exit" && o.custom.get("name") == name)
				{
					return o;
				}
			}
		}
		
		return null;
	}
	
	public function getBounds() : FlxRect
	{
		return new FlxRect(x, y, x + fullWidth, y + fullHeight);
	}
}