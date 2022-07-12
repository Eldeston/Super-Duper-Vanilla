// Wave calculation function
void getVertexAnimations(inout vec3 vertexPos, in vec3 worldPos, in vec2 texCoord, in vec2 midTexCoord, in float id, in float outSide){
	float windWeight = sin(worldPos.x + worldPos.z + newFrameTimeCounter * 1.32 * WIND_SPEED) * outSide;
	float currentWeight = sin(worldPos.x + worldPos.z + newFrameTimeCounter * 1.64 * CURRENT_SPEED);

	// For terrain and shadow program
	#if defined TERRAIN || defined SHADOW
		// -----Calculate weights for certain objects----- //
		// For grounded objects
		if((id >= 10004 && id <= 10006) || (id >= 10009 && id <= 10011) || id == 10036){
			float offSet = float(texCoord.y < midTexCoord.y) + float(id == 10006 || id == 10011);
			
			windWeight *= offSet;
			currentWeight *= offSet;
		}

		// For hanged objects
		if(id == 10014){
			float offSet = float(texCoord.y > midTexCoord.y);
			
			windWeight *= offSet;
			currentWeight *= offSet;
		}

		// Lantern
		if(id == 10051){
			float offSet = 1.0 - fract(worldPos.y - 0.001);

			windWeight *= offSet;
			currentWeight *= offSet;
		}

		// -----Apply offsets----- //

		if(CURRENT_SPEED > 0){
			// Lava
			if(id == 10001) vertexPos.y += currentWeight * 0.05;

			// Single and doubles grounded and hanged underwater
			if(id >= 10009 && id <= 10012) vertexPos.x += currentWeight * 0.1;

			// Floaters
			if(id == 10013) vertexPos.y += currentWeight * 0.1;
		}

		if(WIND_SPEED > 0){
			// Leaves
			if(id == 10003) vertexPos.xz += windWeight * 0.1;

			// Single and doubles grounded and hanged land
			if((id >= 10004 && id <= 10007) || id == 10014 || id == 10033 || id == 10036) vertexPos.x += windWeight * 0.125;
			// Sided land
			if(id == 10008) vertexPos.x += windWeight * 0.05;

			// Lanterns
			if(id == 10051) vertexPos.xz += windWeight * 0.075;
		}
	#endif

	// For water and shadow program
	#if defined WATER || defined SHADOW
		// -----Apply offsets----- //
		// Water
		if(CURRENT_SPEED > 0 && id == 10000) vertexPos.y += currentWeight * 0.075;
	#endif
}