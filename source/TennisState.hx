package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class TennisState extends FlxState
{
	var _ball:Ball;
	var _leftPaddle:Paddle;
	var _rightPaddle:Paddle;
	var _net:FlxSprite;
	var _leftScore:FlxText;
	var _rightScore:FlxText;

	final LEFT_X = 10;
	final RIGHT_X = FlxG.width - 20;
	final PADDLE_SPEED = 100;

	var _leftPoints = 0;
	var _rightPoints = 0;

	override public function create()
	{
		super.create();

		// Create the ball and paddles
		_ball = new Ball();
		_ball.makeGraphic(10, 10, FlxColor.RED);
		_ball.screenCenter();
		_ball.elasticity = 1.0;

		_leftPaddle = new Paddle(LEFT_X, FlxG.height / 2.0 - 20);
		_leftPaddle.makeGraphic(10, 40, FlxColor.WHITE);
		_leftPaddle.immovable = true;

		_rightPaddle = new Paddle(RIGHT_X, FlxG.height / 2.0 - 20);
		_rightPaddle.makeGraphic(10, 40, FlxColor.WHITE);
		_rightPaddle.immovable = true;

		_net = new FlxSprite();
		_net.loadGraphic('assets/images/Net.png');
		_net.screenCenter();
		_net.y = 0;

		_leftScore = new FlxText(FlxG.width / 4.0, 10, 20, '${_leftPoints}', 20);
		_leftScore.textField.antiAliasType = ADVANCED;
		_leftScore.textField.sharpness = 400;

		_rightScore = new FlxText(3 * FlxG.width / 4.0, 10, 20, '${_rightPoints}', 20);
		_rightScore.textField.antiAliasType = ADVANCED;
		_rightScore.textField.sharpness = 400;

		add(_leftPaddle);
		add(_rightPaddle);
		add(_ball);
		add(_net);
		add(_leftScore);
		add(_rightScore);
	}

	public function leftPaddleMove(x:Float, y:Float):Void
	{
		_leftPaddle.x += x;
		_leftPaddle.y += y;
		if (_leftPaddle.y < 0)
		{
			_leftPaddle.y = 0;
		}
		if (_leftPaddle.y > FlxG.height - _leftPaddle.height)
		{
			_leftPaddle.y = FlxG.height - _leftPaddle.height;
		}

	}

	public function rightPaddleMove(x:Float, y:Float):Void
	{
		_rightPaddle.x += x;
		_rightPaddle.y += y;
		if (_rightPaddle.y < 0)
		{
			_rightPaddle.y = 0;
		}
		if (_rightPaddle.y > FlxG.height - _rightPaddle.height)
		{
			_rightPaddle.y = FlxG.height - _rightPaddle.height;
		}

	}

	public function serve(x:Float, y:Float, speed:Float, degrees:Float):Void
	{
		_ball.x = x;
		_ball.y = y;
		_ball.velocity.setPolarDegrees(speed, degrees);
	}

	function resetForNewServe():Void
	{
		_leftPaddle.x = LEFT_X;
		_leftPaddle.y = (FlxG.height - _leftPaddle.height) / 2.0;
		_rightPaddle.x = RIGHT_X;
		_rightPaddle.y = (FlxG.height - _rightPaddle.height) / 2.0;
		_ball.x = (FlxG.width - _ball.width) / 2.0;
		_ball.y = 0;
		_ball.velocity.set(0.0, 0.0);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		FlxG.collide(_ball, _leftPaddle);
		FlxG.collide(_ball, _rightPaddle);

		if (_ball.y < 0)
		{
			_ball.velocity.bounce(FlxPoint.get(0, 1));
		}
		if (_ball.y > FlxG.height - 10)
		{
			_ball.velocity.bounce(FlxPoint.get(0, -1));
		}
		if (_ball.x < 0)
		{
			_rightPoints++;
			_rightScore.text = '${_rightPoints}';
			_rightScore.textField.antiAliasType = ADVANCED;
			_rightScore.textField.sharpness = 400;

			resetForNewServe();
		}
		if (_ball.x > FlxG.width)
		{
			_leftPoints++;
			_leftScore.text = '${_leftPoints}';
			_leftScore.textField.antiAliasType = ADVANCED;
			_leftScore.textField.sharpness = 400;
			resetForNewServe();
		}

		// Keyboard input
		if (FlxG.keys.pressed.W) {
			leftPaddleMove(0, -200 * elapsed);
		}
		if (FlxG.keys.pressed.S) {
			leftPaddleMove(0, 200 * elapsed);
		}
		if (FlxG.keys.pressed.O) {
			rightPaddleMove(0, -200 * elapsed);
		}
		if (FlxG.keys.pressed.K) {
			rightPaddleMove(0, 200 * elapsed);
		}
		if (FlxG.keys.pressed.T) {
			serve((FlxG.width) / 2.0, 0, 200, 135);
		}
	}
}
