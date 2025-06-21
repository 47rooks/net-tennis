package ui.components;

import flixel.math.FlxRandom;
import haxe.ui.containers.VBox;
import haxe.ui.events.UIEvent;
import metrics.Metric.TimeseriesMetric;
import ui.dv.RealtimeLineChart;

@:build(haxe.ui.macros.ComponentMacros.build("assets/ui/components/realtime-line-chart-comp.xml"))
class RealtimeLineChartComp extends VBox {
	var _rtlc:RealtimeLineChart;
	var _r:FlxRandom;
	final _MIN = 50.0;
	final _MAX = 70.5;

	public var series(get, set):TimeseriesMetric<Float>;
	public var title(get, set):String;
	public var fontSize(get, set):Int;

	var _cacheAdjustedWidth:Float;
	var _cacheAdjustedHeight:Float;
	var _dirtyAdjustedSize:Bool = false;

	public function new() {
		super();

		_rtlc = new RealtimeLineChart(x, y, 0x14ffffff);
		_r = new FlxRandom();
	}

	@:bind(this, UIEvent.RESIZE)
	function resize(e:UIEvent) {
		if (_rtlc == null) {
			return;
		}
		trace('e.w=${e.target.width}, e.h=${e.target.height}');
		trace('this.w=${this.width}, this.h=${this.height}');

		_rtlc.width = e.target.width;
		_rtlc.height = e.target.height;

		if (_rtlc.width != e.target.width || _rtlc.height != e.target.height) {
			_cacheAdjustedWidth = _rtlc.width;
			_cacheAdjustedHeight = _rtlc.height;
			_dirtyAdjustedSize = true;
		}
	}

	override public function validateComponentLayout():Bool {
		trace('validating rtlc layout');
		if (_dirtyAdjustedSize) {
			trace('resizing');
			resizeComponent(_cacheAdjustedWidth, _cacheAdjustedHeight);
			_dirtyAdjustedSize = false;
		}
		return super.validateComponentLayout();
	}

	override public function update(elapsed:Float) {
		_rtlc.init();
		add(_rtlc);

		super.update(elapsed);
	}

	function set_title(value:String):String {
		return _rtlc.title = value;
	}

	function get_title():String {
		return _rtlc.title;
	}

	function set_series(value:TimeseriesMetric<Float>):TimeseriesMetric<Float> {
		return _rtlc.series = value;
	}

	function get_series():TimeseriesMetric<Float> {
		return _rtlc.series;
	}

	function set_fontSize(value:Int):Int {
		return _rtlc.fontSize = value;
	}

	function get_fontSize():Int {
		return _rtlc.fontSize;
	}

	override function destroy() {
		super.destroy();
		_rtlc.destroy();
	}
}
