// Fast previous frame reprojection based from Chocapic13's previous frame reprojection and Jessie's fast space conversions for all your TAA and motion blur needs
vec2 getPrevScreenCoord(in vec2 currScreenPos, in float screenDepth){
	vec3 currViewPos = getViewPos(gbufferProjectionInverse, vec3(currScreenPos, screenDepth));
	vec3 currFeetPlayerPos = mat3(gbufferModelViewInverse) * currViewPos + gbufferModelViewInverse[3].xyz;

	if(screenDepth > 0.56) currFeetPlayerPos += cameraPosition - previousCameraPosition;

	vec3 prevViewPos = mat3(gbufferPreviousModelView) * currFeetPlayerPos + gbufferPreviousModelView[3].xyz;
	return getScreenCoord(gbufferPreviousProjection, prevViewPos);
}

vec2 getPrevScreenCoord(in vec2 currScreenPos){
	return getPrevScreenCoord(currScreenPos, textureLod(depthtex0, currScreenPos, 0).x);
}