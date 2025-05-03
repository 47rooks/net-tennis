package;

// import crashdumper.CrashDumper;
// import crashdumper.SessionData;
import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();

		// var unique_id:String = SessionData.generateID("NetTennis_");
		// var crashDumper = new CrashDumper(unique_id);

		addChild(new FlxGame(0, 0, TennisState));
	}
}
