void getPosVectors(inout positionVectors posVec){
    // Assign positions
	posVec.clipPos = posVec.screenPos * 2.0 - 1.0;
	posVec.viewPos = toView(posVec.screenPos);
	posVec.eyePlayerPos = mat3(gbufferModelViewInverse) * posVec.viewPos;
	posVec.feetPlayerPos = posVec.eyePlayerPos + gbufferModelViewInverse[3].xyz;
	posVec.worldPos = posVec.feetPlayerPos + cameraPosition;
	posVec.lightPos = mat3(gbufferModelViewInverse) * shadowLightPosition;
	
	posVec.shdPos = toShadow(posVec.feetPlayerPos);
}