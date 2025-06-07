package metrics;

class Metrics {
	public var frameTimes = new RingBuffer<Float>(1024);
	public var partialFrameCount:Int = 0;
	public var frameCount:Int = 0;

	public function new() {}
}
