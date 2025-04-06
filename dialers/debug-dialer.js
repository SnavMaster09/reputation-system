import { cvToHex } from "@stacks/transactions";

console.log("initliasied");

async function postTransferSip010PrintEvent(context) {
  const selectedFunction = context.selectedFunction;

  // A fungible token complies with the SIP-010 standard if the transfer event
  // always emits the print event with the `memo` content.
  if (selectedFunction.name !== "transfer") {
    return;
  }

  const functionCallEvents = context.functionCall.events;

  // The `memo` parameter is the fourth parameter of the `rendezvous-token`'s
  // `transfer` function.
  const memoParameterIndex = 3;

  const memoGeneratedArgumentCV =
    context.clarityValueArguments[memoParameterIndex];

  // The `memo` argument is optional. If `none`, nothing has to be printed.
  if (memoGeneratedArgumentCV.type === 9) {
    return;
  }

  // If not `none`, the `memo` argument must be `some`. Otherwise, the
  // generated clarity argument is not an option type, so it does not comply
  // with the SIP-010 fungible token trait.
  if (memoGeneratedArgumentCV.type !== 10) {
    throw new Error("The memo argument has to be an option type!");
  }

  // Turn the inner value of the `some` type into a hex to compare it with the
  // print event data.
  const hexMemoArgumentValue = cvToHex(memoGeneratedArgumentCV.value);

  const sip010PrintEvent = functionCallEvents.find(
    (ev) => ev.event === "print_event"
  );

  if (!sip010PrintEvent) {
    throw new Error(
      "No print event found. The transfer function must emit the SIP-010 print event containing the memo!"
    );
  }
  console.log("blo");
  const sip010PrintEventValue = sip010PrintEvent.data.raw_value;

  if (sip010PrintEventValue !== hexMemoArgumentValue) {
    throw new Error(
      `The print event memo value is not equal to the memo parameter value: ${hexMemoArgumentValue} !== ${sip010PrintEventValue}`
    );
  }

  return;
}

module.exports =  { postTransferSip010PrintEvent };