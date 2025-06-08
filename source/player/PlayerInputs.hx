package player;

class PlayerInputs {
	public var framenumber:Int;
	public var up:Bool;
	public var down:Bool;
	public var serve:Bool;

	public function new() {
		framenumber = -2;
		up = false;
		down = false;
		serve = false;
	}

	public function toString():String {
		return '[fn=${framenumber}, up=${up}, down=${down}, serve=${serve}]';
	}
}
