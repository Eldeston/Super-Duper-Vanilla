// This raytracer is so fast I swear...
// Based from Belmu's raytracer https://github.com/BelmuTM/NobleRT
// Basically an upgrade to Shadax's raytracer https://github.com/Shadax-stack/MinecraftSSR
vec3 rayTraceScene(in vec3 screenPos, in vec3 viewPos, in vec3 rayDir, in float dither){
	// Fix for the blob when player is near a surface. From Bálint#1673
	if(rayDir.z > -viewPos.z) return vec3(0);

	// Get screenspace rayDir
	vec3 screenPosRayDir = fastNormalize(getScreenPos(gbufferProjection, viewPos + rayDir) - screenPos) * rayTracerStepsInv;

	// Add dithering to our "startPos"
	vec3 startPos = screenPos + screenPosRayDir * dither;

	for(int i = 0; i < RAYTRACER_STEPS; i++){
		// We raytrace here
		startPos += screenPosRayDir;

		// If current pos is out of bounds, exit immediately
		if(startPos.x < 0 || startPos.y < 0 || startPos.x > 1 || startPos.y > 1) return vec3(0);

		// Get current texture depth
		float currDepth = textureLod(depthtex0, startPos.xy, 0).x;

		// If hand return immediately
		if(currDepth <= 0.56) return vec3(0);

		// Check intersection
		bool intersection = currDepth < startPos.z;

		// If intersection
		if(intersection){
			// Integrated binary refinement
			#if RAYTRACER_BISTEPS != 0
				for(int i = 0; i < RAYTRACER_BISTEPS; i++){
					// If sky return immediately
					if(currDepth == 1) return vec3(0);

					// Continue refinement
					screenPosRayDir *= 0.5;
					startPos += intersection ? -screenPosRayDir : screenPosRayDir;

					// Get current texture depth
					currDepth = textureLod(depthtex0, startPos.xy, 0).x;
					// Check intersection
					intersection = currDepth < startPos.z;
				}
			#else
				// If sky return immediately
				if(currDepth == 1) return vec3(0);
			#endif

			// Return final results
			return vec3(startPos.xy, 1);
		}
	}

	return vec3(0);
}