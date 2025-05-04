package;

import CLITest.SubProcessCLITests;

class TestAll {
  public static function main() {
    utest.UTest.run([new CLITest(), new SubProcessCLITests()]);
  }
}