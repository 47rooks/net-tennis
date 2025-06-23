package ui.dv;

import flixel.FlxSprite;
import flixel.group.FlxSpriteContainer;
import flixel.math.FlxMath;
import flixel.text.FlxBitmapFont;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import metrics.Metric.TimeseriesMetric;

using flixel.util.FlxSpriteUtil;

class RealtimeLineChart extends FlxSpriteContainer {
	@:isVar
	public var series(get, set):Null<TimeseriesMetric<Float>> = null;

	// public var series(get, set):Null<Array<Float>> = null;
	@:isVar
	public var fullWidth(get, set):Int;
	@:isVar
	public var fullHeight(get, set):Int;
	@:isVar
	public var fontSize(get, set):Int = 12;

	var _title:FlxText;

	// final TITLE_HEIGHT = 15;
	var _chart:FlxSprite;
	var _chartWidth:Int;
	var _chartHeight:Int;

	var _yAxisX:Float;
	var _yAxisWidth:Int;
	var _yAxisLabelWidth:Int;

	var _xAxisY:Float;
	var _xAxisHeight:Int;
	var _xAxisLabelHeight:Int;

	final DEFAULT_FONT_SIZE = 12;
	var _axisLabelFontSize:Int;
	var _axisLabelFont:FlxBitmapFont;

	var _backgroundColor:FlxColor;

	var _max:FlxText;
	var _current:FlxText;
	var _min:FlxText;

	var _maxV:Float;
	var _currentV:Float;
	var _minV:Float = 10000;

	final MAX_Y = 10;
	final CURRENT_Y = 30;
	final MIN_Y = 50;

	var _reverse = true; // Latest data on the left.

	@:isVar
	public var title(get, set):String;

	var _initialized = false;

	public function new(x:Float, y:Float, backgroundColor:FlxColor) {
		super(x, y);
		trace('x=$x, y=$y, w=$fullWidth, h=$fullHeight');

		_backgroundColor = backgroundColor;
	}

	public function init():Void {
		if (_initialized) {
			return;
		}

		trace('initializing');

		// Create test text to get size
		// FIXME number of digits in this actually depends on the data
		//       to be displayed. This needs to be configurable.
		var testText = new FlxText(0, 0, 0, "19.999", fontSize);
		_yAxisLabelWidth = Std.int(testText.width);
		var pitch = Std.int(testText.height + 2);

		_max = new FlxText(0, pitch, 0, "80.0", fontSize);
		_current = new FlxText(0, 2 * pitch, 0, "65.0", fontSize);
		_min = new FlxText(0, 3 * pitch, 0, "50.0", fontSize);
		_title = new FlxText(0, 0, 0, title, fontSize);

		_yAxisWidth = 1;
		_yAxisX = _yAxisLabelWidth + 2;
		_xAxisLabelHeight = 0;
		_xAxisHeight = 1;
		_xAxisY = _xAxisLabelHeight + 2;
		_chartWidth = Std.int(fullWidth - _yAxisX);
		_chartHeight = Std.int(fullHeight - (_xAxisLabelHeight + 2) - _xAxisHeight - testText.height);

		_chart = new FlxSprite(0, 0);
		_chart.makeGraphic(_chartWidth, _chartHeight, _backgroundColor);
		_chart.setPosition(_yAxisX, testText.height);
		_title.setPosition(x + (fullWidth - _title.width) / 2.0, y);

		add(_title);
		add(_max);
		add(_current);
		add(_min);
		add(_chart);

		_initialized = true;
	}

	function set_series(value:TimeseriesMetric<Float>):TimeseriesMetric<Float> {
		return series = value;
	}

	function get_series():TimeseriesMetric<Float> {
		return series;
	}

	function set_title(value:String):String {
		title = value;
		// FIXME this indicates fragile initialization.
		//       the title attribute must be processed before the init()
		//       function runs. Harden this and init() to work either way
		// _title.text = title;
		// _title.setPosition(x + (fullWidth - _title.width) / 2.0, y);

		return title;
	}

	function get_title():String {
		return title;
	}

	/**
	 * Redraws the axes of the graph.
	 */
	function drawAxes():Void {
		// x-Axis
		_chart.drawLine(0, _chartHeight, _chartWidth, _chartHeight, {thickness: 1, color: 0x80ffffff});
		// y-Axis
		_chart.drawLine(0, _chartHeight - _xAxisLabelHeight, 0, 0, {thickness: 1, color: 0x80ffffff});
	}

	function drawLabels() {
		_max.draw();
		_current.draw();
		_min.draw();
		_title.draw();
	}

	override public function update(elapse:Float) {
		// Compute min, max and average
		_current.text = '${FlxMath.roundDecimal(series.getValue(0), 3)}';

		// FIXME Can be optimized
		//   1. can just do this once initially and then incrementally add
		//      values to the average
		//   2. Could support stats on metrics and just ask for the min/max
		//      values
		// trace('series #elts=${series.count()}');
		_minV = 10000;
		_maxV = 0;
		for (i in 0...series.count()) {
			var v = series.getValue(i);
			// trace('\t${v}');
			_minV = Math.min(_minV, v);
			_maxV = Math.max(_maxV, v);
		}
		_min.text = '${FlxMath.roundDecimal(_minV, 3)}';
		_max.text = '${FlxMath.roundDecimal(_maxV, 3)}';
	}

	override public function draw():Void {
		super.draw();
		// drawLabels();

		if (series == null) {
			return;
		}
		_chart.fill(_backgroundColor);
		drawAxes();

		var x_int = 1.0 * _chartWidth / series.count();
		// FIXME this needs rework to allow axis to start other than at 0.
		var range = _maxV - 0;
		if (Math.abs(range) < 0.00001) {
			return;
		}
		for (i in 0...series.count() - 1) {
			_chart.drawLine(i * x_int, _chartHeight - (series.getValue(i) * _chartHeight / range), (i + 1) * x_int,
				_chartHeight - (series.getValue(i + 1) / range * _chartHeight), {
					thickness: 1,
					color: 0xffffffff
				});
		}
	}

	function set_fullWidth(value:Int):Int {
		return fullWidth = value;
	}

	function get_fullWidth():Int {
		return fullWidth;
	}

	function set_fullHeight(value:Int):Int {
		return fullHeight = value;
	}

	function get_fullHeight():Int {
		return fullHeight;
	}

	override public function set_width(value:Float):Float {
		// Distribute the width over the chart components
		var t = new FlxText(0, 0, 0, title, fontSize);
		fullWidth = Std.int(value);
		if (fullWidth < t.width) {
			fullWidth = Std.int(t.width);
		}
		trace('set fullwidth=${fullWidth} t.width=${t.width}');
		t.destroy();
		return width = fullWidth;
	}

	override public function set_height(value:Float):Float {
		// Distribute the height over the chart components
		var t = new FlxText(0, 0, 0, "9", fontSize);
		var fourPitch = Std.int(4 * (t.height + 2));
		fullHeight = Std.int(value);
		if (value < fourPitch) {
			fullHeight = fourPitch;
		}
		trace('set fullheight to ${fullHeight} t.height=${t.height}');
		t.destroy();
		return height = fullHeight;
	}

	override public function get_width():Float {
		return width;
	}

	override public function get_height():Float {
		return height;
	}

	function set_fontSize(value:Int):Int {
		return fontSize = value;
	}

	function get_fontSize():Int {
		return fontSize;
	}

	override function destroy() {
		super.destroy();
		_chart.destroy();
		_min.destroy();
		_current.destroy();
		_max.destroy();
	}
}
