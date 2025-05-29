package ai.bt;

import bitdecay.behavior.tree.NodeStatus;
import bitdecay.behavior.tree.leaf.Condition;

class WaitForCondition extends Condition {
	override function process(delta:Float):NodeStatus {
		switch type {
			case VAR_SET(v):
				if (ctx.get(v) != null) {
					return SUCCESS;
				}
			case VAR_CMP(vName, cmp):
				var outcome = doComparison(ctx.get(vName), cmp);
				if (outcome) {
					trace('condition: hit ball');
					return SUCCESS;
				}
			case FUNC(fn):
				if (fn.func(ctx)) {
					return SUCCESS;
				}
		}

		return RUNNING;
	}
}
