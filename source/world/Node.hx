package world;

class Node 
{
	public var name : String;
	public var exits : Map<String, ExitData>;
	
	public function new(Name : String)
	{
		this.name = Name;
		
		exits = new Map<String, ExitData>();
	}
}

typedef ExitData = {
	node : String,
	exit : String,
	hops : Int
}