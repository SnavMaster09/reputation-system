// 1. Required imports - using ES module syntax
import { cvToValue, hexToCV } from "@stacks/transactions";

// 2. Function names MUST start with "pre" or "post"
function preExecutionLogger(context) {
  console.log("⏳ RUNNING FUNCTION:", context.selectedFunction.name);
  console.log("  WITH ARGUMENTS:", JSON.stringify(context.clarityValueArguments));
}

function postExecutionLogger(context) {
  console.log("✅ FUNCTION COMPLETED:", context.selectedFunction.name);
  console.log("  RESULT:", JSON.stringify(context.functionCall.result));
}

// 3. Export using ES module syntax
export {
  preExecutionLogger,
  postExecutionLogger
};