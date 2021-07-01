#ifndef GBUFFERS
	void getPosVectors(inout positionVectors posVec, vec2 screenCoord){
		// Assign positions
		posVec.screenPos = toScreenSpacePos(screenCoord);
		posVec.clipPos = posVec.screenPos * 2.0 - 1.0;
		posVec.viewPos = toView(posVec.screenPos);
		posVec.eyePlayerPos = mat3(gbufferModelViewInverse) * posVec.viewPos;
		posVec.feetPlayerPos = posVec.eyePlayerPos + gbufferModelViewInverse[3].xyz;
		posVec.worldPos = posVec.feetPlayerPos + cameraPosition;
		posVec.worldPos.y /= 256.0; // Divide by max build height...
		posVec.lightPos = mat3(gbufferModelViewInverse) * shadowLightPosition;
		
		posVec.shdPos = toShadow(posVec.feetPlayerPos);
	}
#endif

void getPosVectors(inout positionVectors posVec, vec3 screenPos){
    // Assign positions
	posVec.screenPos = screenPos;
	posVec.clipPos = screenPos * 2.0 - 1.0;
	posVec.viewPos = toView(posVec.screenPos);
	posVec.eyePlayerPos = mat3(gbufferModelViewInverse) * posVec.viewPos;
	posVec.feetPlayerPos = posVec.eyePlayerPos + gbufferModelViewInverse[3].xyz;
	posVec.worldPos = posVec.feetPlayerPos + cameraPosition;
	posVec.lightPos = mat3(gbufferModelViewInverse) * shadowLightPosition;
	
	posVec.shdPos = toShadow(posVec.feetPlayerPos);
}