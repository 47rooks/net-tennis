package ui;

import ui.components.RealtimeLineChartComp;
import haxe.ui.containers.TableView;
import haxe.ui.components.Label;
import utils.Globals.G;
import haxe.ui.containers.VBox;

// FIXME might just inline the xml here
@:build(haxe.ui.macros.ComponentMacros.build("assets/ui/metrics-hud.xml"))
class MetricsHUD extends VBox {
	var _intMetricsBox:Null<TableView>;
	var _frameTimesChart:Null<RealtimeLineChartComp>;
	var _initialized = false;

	public function new() {
		super();
		_intMetricsBox = findComponent("intMetrics");
		_frameTimesChart = findComponent("frameTimes");
		@:privateAccess _frameTimesChart.series = G.metrics._timeSeriesMetics[0];
	}

	override public function update(elapsed:Float):Void {
		if (!_initialized) {
			if (_intMetricsBox != null) {
				@:privateAccess for (m in G.metrics._intMetrics) {
					var item = {metric: m.name, value: m.value};
					var i = _intMetricsBox.dataSource.add(item);
				}
				_initialized = true;
			}
		} else {
			@:privateAccess for (i => m in G.metrics._intMetrics) {
				var item:Dynamic = {};
				item.metric = m.name;
				item.value = m.value;
				_intMetricsBox.dataSource.update(i, item);
			}
		}
		super.update(elapsed);
	}

	override function destroy() {
		super.destroy();
		_intMetricsBox.destroy();
		_frameTimesChart.destroy();
	}
}
