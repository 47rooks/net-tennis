package metrics;

import haxe.ds.Vector;
import utest.Assert;
import utest.Test;

class RingBufferTest extends Test {
	public function testSizeLessThanFourCon() {
		var rb = new RingBuffer(3);
		@:privateAccess Assert.equals(4, rb.a.length);
	}

	public function testSizeFourCon() {
		var rb = new RingBuffer(4);
		@:privateAccess Assert.equals(4, rb.a.length);
	}

	public function testSizeGreaterThanFourCon() {
		var rb = new RingBuffer(10);
		@:privateAccess Assert.equals(16, rb.a.length);
	}

	public function testPushWhenFull() {
		var rb = new RingBuffer(4);
		rb.push(1);
		rb.push(2);
		rb.push(3);
		rb.push(4);
		rb.push(5);
		@:privateAccess Assert.equals(4, rb.a.length);

		var exp = Vector.fromArrayCopy([5, 2, 3, 4]);

		@:privateAccess Assert.same(exp, rb.a);
	}

	public function testPushNotFull() {
		var rb = new RingBuffer(4);
		rb.push(1);
		rb.push(2);

		@:privateAccess Assert.equals(4, rb.a.length);

		var exp = Vector.fromArrayCopy([1, 2, 0, 0]);

		@:privateAccess Assert.same(exp, rb.a);
	}

	public function testPopWhenEmpty() {
		var rb = new RingBuffer(4);
		var v = rb.pop();
		Assert.isNull(v);
	}

	public function testPopWhenNotEmpty() {
		var rb = new RingBuffer(4);
		rb.push(1);
		rb.push(2);
		var v = rb.pop();

		Assert.equals(2, v);
	}

	public function testShiftWhenNotEmpty() {
		var rb = new RingBuffer(4);
		rb.push(1);
		rb.push(2);

		var v = rb.shift();
		Assert.equals(1, v);
	}

	public function testShiftWhenEmpty() {
		var rb = new RingBuffer(4);
		var v = rb.shift();
		Assert.isNull(v);
	}

	public function testUnshiftWhenFull() {
		var rb = new RingBuffer(4);
		rb.unshift(1);
		rb.unshift(2);
		rb.unshift(3);
		rb.unshift(4);

		rb.unshift(17);

		@:privateAccess Assert.same([4, 3, 2, 17], rb.a);
	}

	public function testUnshiftWhenNotFull() {
		var rb = new RingBuffer(6);
		rb.unshift(1);
		rb.unshift(2);
		rb.unshift(3);
		rb.unshift(4);
		rb.unshift(5);
		rb.unshift(6);
		@:privateAccess Assert.same([null, null, 6, 5, 4, 3, 2, 1], rb.a);
	}

	public function testStringRingBuffer() {
		var rb = new RingBuffer<String>(4);
		rb.push('foo');
		rb.push('baa');

		@:privateAccess Assert.equals('baa', rb.a[1]);
	}

	public function testObjectRingBuffer() {
		var rb = new RingBuffer<TestObj>(4);
		rb.unshift(new TestObj(10, 'hello'));
		rb.unshift(new TestObj(21, 'goodbye'));

		@:privateAccess Assert.same(new TestObj(21, 'goodbye'), rb.a[2]);
	}

	public function testToString() {
		var rb = new RingBuffer<String>(4);
		rb.push('foo');
		rb.push('baa');

		Assert.equals("[head: 2, tail: 0, capacity: 3]", rb.toString());
	}

	public function testSpaceWhenEmpty() {
		var rb = new RingBuffer(4);
		Assert.equals(3, rb.space());
	}

	public function testSpace() {
		var rb = new RingBuffer(4);
		rb.push(1);
		rb.push(2);

		Assert.equals(1, rb.space());
	}

	public function testSpaceWhenFull() {
		var rb = new RingBuffer(4);
		rb.push(1);
		rb.push(1);
		rb.push(1);
		Assert.equals(0, rb.space());
	}

	public function testCount() {
		var rb = new RingBuffer(4);
		rb.push(1);
		rb.push(1);
		rb.push(1);
		rb.push(1);

		trace('RB: ${rb.toString()}, count=${rb.count()}, space=${rb.space()}');
		Assert.equals(3, rb.count());
		Assert.equals(0, rb.space());
	}
}

class TestObj {
	var a:Int;
	var s:String;

	public function new(a:Int, s:String) {
		this.a = a;
		this.s = s;
	}
}
