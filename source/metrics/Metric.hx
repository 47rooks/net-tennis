package metrics;

class Metric<T> {
	var name:String;
	var value:Null<T>;

	public function new(name:String, ?initialValue:T) {
		this.name = name;
		value = initialValue;
	}

	inline public function set(v:T):Void {
		value = v;
	}

	public function toString():String {
		return '[name=${name}, value=${value}]';
	}
}

class IntMetric extends Metric<Int> {
	inline public function increment():Void {
		value++;
	}

	inline public function decrement():Void {
		value--;
	}
}

class TimeseriesMetric<T> extends Metric<RingBuffer<T>> {
	inline public function push(value:T) {
		this.value.push(value);
	}

	inline public function reset():Void {
		value.reset();
	}

	inline public function count():Int {
		return value.count();
	}

	/**
	 * Return the idx'th value from the ringbuffer relative to head and 
	 * respecting the ring behaviour.
	 * @param idx 
	 * @return Float
	 * @throws ValueException for a reference beyond the tail or before the head.
	 */
	inline public function getValue(idx:Int):T {
		return value.getValue(idx);
	}
}
