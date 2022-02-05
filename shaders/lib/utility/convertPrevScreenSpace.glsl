vec2 toPrevScreenPos(vec2 currentPos){
	// Previous frame reprojection from Chocapic13
	vec4 viewPosPrev = gbufferProjectionInverse * vec4(vec3(currentPos.xy, texture2D(depthtex0, currentPos.xy).x) * 2.0 - 1.0, 1);
	viewPosPrev /= viewPosPrev.w;
	viewPosPrev = gbufferModelViewInverse * viewPosPrev;

	vec4 prevPosition = viewPosPrev + vec4(cameraPosition - previousCameraPosition, 0);
	prevPosition = gbufferPreviousModelView * prevPosition;
	prevPosition = gbufferPreviousProjection * prevPosition;
	return prevPosition.xy / prevPosition.w * 0.5 + 0.5;
}