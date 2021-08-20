module automotive.math;

@safe:

import std.traits : isNumeric;

/// Clamp between `min` and `max`
T clamp(T)(immutable T v, immutable T min, immutable T max)
	if(isNumeric!T)
{
	T ret = v;
	if(v < min) ret = min;
	if(v > max) ret = max;
	return ret;
}

/// Clamp `ref v` between `min` and `max`
T clampRef(T)(ref T v, immutable T min, immutable T max)
	if(isNumeric!T)
{
	if(v < min) v = min;
	if(v > max) v = max;
	return v;
}

/// Map value of `x` between [`inMin`, `inMax`] to output set [`outMin`, `outMax`]
T map(T)(T x, T inMin, T inMax, T outMin, T outMax)
	if(isNumeric!T)
{
	return (x - inMin) * (outMax - outMin) / (inMax - inMin) + outMin;
}

/// Interpolate `xInterpPoint` between [`xLo`, `xHi`] to output set [`yLo`, `yHi`]
T linterp2D(T)(T xLo, T xHi, T yLo, T yHi, T xInterpPoint)
	if(isNumeric!T)
{
	return yLo + ((yHi - yLo) / (xHi - xLo)) * (xInterpPoint - xLo);
}

/// 3D linear interpolation
T linterp3D(T)(T x, T xLo, T xHi, T y, T yLo, T yHi, T z_x0y0, T z_x1y0, T z_x0y1, T z_x1y1)
	if(isNumeric!T)
{
	float lerpX0 = 
        ((xHi - x) / (xHi - xLo) * z_x0y0) + 
		((x - xLo) / (xHi - xLo) * z_x1y0);
	float lerpX1 = 
        ((xHi - x) / (xHi - xLo) * z_x0y1) +
		((x - xLo) / (xHi - xLo) * z_x1y1);
	float lerpY = 
        ((yHi - y) / (yHi - yLo) * lerpX0) +
		((y - yLo) / (yHi - yLo) * lerpX1);
	return lerpY;
}