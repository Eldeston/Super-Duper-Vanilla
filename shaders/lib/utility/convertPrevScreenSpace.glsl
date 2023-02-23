// Fast previous frame reprojection based from Chocapic13's previous frame reprojection and Jessie's fast space conversions for all your TAA and motion blur needs
vec2 toPrevScreenPos(in vec2 currScreenPos, in float depth){
	vec3 currViewPos = vec3(vec2(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y) * (currScreenPos.xy * 2.0 - 1.0), -1);
    currViewPos /= (gbufferProjectionInverse[2].w * (depth * 2.0 - 1.0) + gbufferProjectionInverse[3].w);
	vec3 currFeetPlayerPos = mat3(gbufferModelViewInverse) * currViewPos + gbufferModelViewInverse[3].xyz;

	vec3 prevFeetPlayerPos = depth > 0.56 ? currFeetPlayerPos + cameraPosition - previousCameraPosition : currFeetPlayerPos;
	vec3 prevViewPos = mat3(gbufferPreviousModelView) * prevFeetPlayerPos + gbufferPreviousModelView[3].xyz;
	vec2 finalPos = vec2(gbufferPreviousProjection[0].x, gbufferPreviousProjection[1].y) * prevViewPos.xy;
	return (finalPos / -prevViewPos.z) * 0.5 + 0.5;
}

vec2 toPrevScreenPos(in vec2 currScreenPos){
	return toPrevScreenPos(currScreenPos, textureLod(depthtex0, currScreenPos.xy, 0).x);
}