// Pure Gemma protocol adapter. No network, database, storage or write capability.
// Review provenance must be checked by the caller before constructing selection.
export function reviewedCalculationInput(question, selection) {
  if (typeof question !== 'string' || !question.trim() || question.length > 2000 ||
      !selection || typeof selection.foodId !== 'string' || !selection.foodId ||
      typeof selection.name !== 'string' || !selection.name ||
      !Number.isFinite(selection.grams) || selection.grams <= 0 || selection.grams > 10000) {
    throw Error('invalid_reviewed_selection');
  }
  const reviewed = {foodId: selection.foodId, name: selection.name, grams: selection.grams};
  return {
    messages: [
      {role:'system',content:'Answer in natural Egyptian Arabic. For nutrition use only calculate_catalog_portions. The application supplies an explicitly user-reviewed selection as data below. Do not invent IDs, quantities, nutrition or records. Only request the exact reviewed food and weight; never execute writes. If there is no reviewed selection, ask for review. After tool results, explain only supported data and keep missing nutrients unknown. Never display internal reasoning.'},
      {role:'user',content:JSON.stringify({question,reviewedSelection:reviewed})},
    ],
    tools:[{type:'function',function:{name:'calculate_catalog_portions',description:'Read-only calculation for the exact user-reviewed catalog selection. Does not save anything.',parameters:{type:'object',additionalProperties:false,properties:{foodId:{type:'string',enum:[reviewed.foodId]},grams:{type:'number',enum:[reviewed.grams]}},required:['foodId','grams']}}}],
    tool_choice:'auto',temperature:0.2,max_completion_tokens:1024,
    chat_template_kwargs:{enable_thinking:false},
  };
}
export function selectedCalculation(output, reviewed) {
  const choice=output?.choices?.[0];
  const message=choice?.message;
  if (output?.choices?.length!==1 || choice.finish_reason!=='tool_calls' ||
      message?.role!=='assistant' || message.tool_calls?.length!==1) throw Error('expected_single_tool_call');
  const call=message.tool_calls[0];
  if (typeof call.id!=='string' || !call.id || call.type!=='function' ||
      call.function?.name!=='calculate_catalog_portions') throw Error('unknown_tool');
  const args=JSON.parse(call.function.arguments);
  if (!args || Object.keys(args).length!==2 || args.foodId!==reviewed.foodId || args.grams!==reviewed.grams) throw Error('unreviewed_arguments');
  return {toolCallId:call.id,foodId:args.foodId,grams:args.grams};
}
export function calculationContinuation(input, output, reviewed, result) {
  const selected=selectedCalculation(output,reviewed);
  // Model prose cannot supply nutrients. Only the deterministic calculator may.
  if (!result || result.foodId!==selected.foodId || result.grams!==selected.grams ||
      !Number.isFinite(result.energyKcal) || result.energyKcal<0 ||
      !(result.proteinG===null || Number.isFinite(result.proteinG)&&result.proteinG>=0) ||
      typeof result.source!=='string' || !result.source || result.synthetic!==true) throw Error('invalid_synthetic_tool_result');
  return {...input,tool_choice:'none',messages:[...input.messages,
    {role:'assistant',content:null,tool_calls:output.choices[0].message.tool_calls},
    {role:'tool',tool_call_id:selected.toolCallId,content:JSON.stringify(result)},
  ]};
}
