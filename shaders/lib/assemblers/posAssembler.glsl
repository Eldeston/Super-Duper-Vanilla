void getPosVectors(inout positionVectors posVec){
    // Assign positions
	posVec.clipPos = posVec.screenPos * 2.0 - 1.0;
	posVec.viewPos = toView(posVec.screenPos);
	posVec.eyePlayerPos = mat3(gbufferModelViewInverse) * posVec.viewPos;
	posVec.feetPlayerPos = posVec.eyePlayerPos + gbufferModelViewInverse[3].xyz;
	posVec.worldPos = posVec.feetPlayerPos + cameraPosition;

	#if !defined COMPOSITE && !defined DEFERRED
		#ifdef END
			posVec.lightPos = shadowLightPosition;
		#else
			posVec.lightPos = mat3(gbufferModelViewInverse) * shadowLightPosition + gbufferModelViewInverse[3].xyz;
		#endif
	
		#if defined SHD_ENABLE && !defined ENTITIES_GLOWING
			posVec.shdPos = mat3(shadowProjection) * (mat3(shadowModelView) * posVec.feetPlayerPos + shadowModelView[3].xyz) + shadowProjection[3].xyz;
		#endif
	#endif
}