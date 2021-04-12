float getAmbient(matPBR material, positionVectors posVec){
	return max(max((abs(material.normal_m.x) * 0.25 + material.normal_m.y * 0.25 + 0.75) * smootherstep(material.light_m.y), 0.75), material.light_m.x);
}