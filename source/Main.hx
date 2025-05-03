package;

// import crashdumper.CrashDumper;
// import crashdumper.SessionData;
import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite
{
	var _ipAddr:Null<String> = null;
	var _port:Null<Int> = null;

	public function new()
	{
		super();

		// var unique_id:String = SessionData.generateID("NetTennis_");
		// var crashDumper = new CrashDumper(unique_id);

		parseCliArgs();

		addChild(new FlxGame(0, 0, () -> new TennisState(_ipAddr, _port)));
	}

	function parseCliArgs():Void {
		final PROGRAM_PATH = Sys.programPath();
		var PROGRAM = PROGRAM_PATH.indexOf('/') != -1 ? 
			PROGRAM_PATH.substring(PROGRAM_PATH.lastIndexOf('/') + 1) :
			PROGRAM_PATH.substring(PROGRAM_PATH.lastIndexOf('\\') + 1);

		final USAGE = '${PROGRAM} [-h] [-i IP address -p port]';
		var args = Sys.args();
		var i = 0;
		while (i < Sys.args().length) {
			if (args[i] == "-h") {
				Sys.println(USAGE);
				Sys.exit(0);
			} else if (args[i] == "-i") {
				i++;
				_ipAddr = args[i];
			} else if (args[i] == "-p") {
				i++;
				_port = Std.parseInt(args[i]);
				trace('port=${_port}');
				if (_port == null) {
					Sys.println('Invalid port number: ${args[i]}');
					Sys.exit(-1);
				}
			}
			i++;
		}
		if ((_ipAddr != null && _port == null) ||
		    (_ipAddr == null && _port != null)) {
			Sys.print("Either ipAddr and port must be specified, ");
			Sys.println(" or neither must be specified.");
			Sys.exit(-1);
		} else if (_ipAddr != null && _port != null) {
			Sys.println('ip=${_ipAddr}, port=${_port}');
		}
	}
}
