package metrics;

import metrics.Metric.IntMetric;
import metrics.Metric.TimeseriesMetric;

class Metrics {
	// Time series metrics ID/indexes
	public static final FRAME_TIMES = 0;

	// In metric ID/indexes
	public static final PARTIAL_FRAME_COUNT = 0;
	public static final FRAME_COUNT = 1;

	var _timeSeriesMetics:Array<TimeseriesMetric<Float>>;
	var _intMetrics:Array<IntMetric>;

	public function new() {
		_timeSeriesMetics = new Array<TimeseriesMetric<Float>>();
		_intMetrics = new Array<IntMetric>();

		_timeSeriesMetics[0] = new TimeseriesMetric<Float>("frameTimes", new RingBuffer<Float>(64));
		_intMetrics[0] = new IntMetric("Partial frames", 0);
		_intMetrics[1] = new IntMetric("Frames", 0);
	}

	inline public function INC(id:Int) {
		_intMetrics[id].increment();
	}

	inline public function PUSH(id:Int, value:Float) {
		_timeSeriesMetics[id].push(value);
	}
}
