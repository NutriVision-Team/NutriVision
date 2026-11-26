export const GEMMA_VISION_MODEL='@cf/google/gemma-4-26b-a4b-it';
// Same bounded, non-streaming vision request qualified with public food photos.
export async function gemmaVisionAnswer(ai,image,prompt){
 const output=await ai.run(GEMMA_VISION_MODEL,{messages:[{role:'user',content:[{type:'text',text:prompt},{type:'image_url',image_url:{url:image}}]}],max_completion_tokens:700,temperature:0,stream:false,store:false,response_format:{type:'json_object'},chat_template_kwargs:{enable_thinking:false}});
 const choices=output?.choices;
 if(!Array.isArray(choices)||choices.length!==1||choices[0].finish_reason!=='stop'||typeof choices[0].message?.content!=='string')throw Error('incomplete');
 return {answer:choices[0].message.content};
}
