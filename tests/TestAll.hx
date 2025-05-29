package;

import utest.Test;
import ai.bt.EstimateInterceptTest;
import CLITest.SubProcessCLITests;

class TestAll {
	public static function main() {
		// @formatter:off
		var tests:Array<Test> = [
      new CLITest(),
      new SubProcessCLITests(),
      new EstimateInterceptTest(),
    ];
		// @formatter:on
		utest.UTest.run(tests);
	}
}
