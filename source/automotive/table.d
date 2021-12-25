module automotive.table;

import std.traits;
import automotive.math;

@safe:

/++ A 2D table with linear interpolation between defined points.
 + Params:
 +	TVal: Type for the values
 +	TAxis: Type for the axis
 +	N: Dimensions ++/
struct Table2D(TVal, TAxis, ubyte N)
	if(isNumeric!TVal && isNumeric!TAxis && N > 0)
{
	enum size_t numBytes = TVal.sizeof * cast(size_t)N + TAxis.sizeof * cast(size_t)N;
	enum isTable = true;

	private TAxis previousAxis;
	private TVal previousVal;

	private TAxis[N] axis;
	private TVal[N] values;

	@property TAxis axisMin() const { return axis[0]; }
	@property TAxis axisMax() const { return axis[N - 1]; }

	/// Sets axis at `n`. Returns success of operation.
	bool setAxis(const ubyte n, const TAxis a)
	{
		if(n >= N)
			return false;

		axis[n] = a;
		return true;
	}

	/// Sets value at `index`. Return success of operation.
	bool setValueByIndex(const ubyte index, const TVal v)
	{
		if(index >= N)
			return false;

		values[index] = v;
		return true;
	}

	/// Set value at axis point. Returns success of operation
	bool setValue(const TAxis a, const TVal v)
	{
		int selectedBin = -1;
		foreach(i, n; axis)
			if(n == a)
				selectedBin = cast(int)i;

		if(selectedBin < 0)
			return false;

		values[selectedBin] = v;
		return true;
	}

	TVal opIndex(TAxis input)
	{
		// clamp input to be between axis start and end
		clampRef(input,	axisMin, axisMax);

		if(input == previousAxis) return previousVal;
		previousAxis = input;

		// if input exact axis min or max, return that value
		if(input == axisMin)
		{
			previousVal = values[0];
			return values[0];
		}
		if(input == axisMax)
		{
			previousVal = values[N-1];
			return values[N-1];
		}

		ubyte selectedBin;
		// else, we need to interpolate
		foreach(ubyte bin; 0 .. N-1)
		{
			auto c = axis[bin];
			auto n = axis[bin+1];
			if(input >= c && (bin == N-2 ? input <= n : input < n))
			{
				selectedBin = bin;
				break;
			}
		}

		float axialMin = axis[selectedBin], axialMax = axis[selectedBin + 1];
		float valMin = values[selectedBin], valMax = values[selectedBin + 1];

		if(input == axialMin)
		{
			previousVal = cast(TVal)valMin;
			return previousVal;
		}
		if(input == axialMax)
		{
			previousVal = cast(TVal)valMax;
			return previousVal;
		}

		TVal val = cast(TVal)linterp2D!float(axialMin, axialMax, valMin, valMax, input);

		previousVal = cast(TVal)val;
		return val;
	}

	@system ubyte readByte(size_t i, ref bool read) const
	{
		immutable axisSize = TAxis.sizeof * N,
			valSize = TVal.sizeof * N;
		if(i < axisSize) // in axis
		{
			read = true;
			return (cast(ubyte*)axis.ptr)[i];
		}
		else if(i >= axisSize && i < valSize + axisSize) // in values
		{
			read = true;
			return (cast(ubyte*)values.ptr)[i - axisSize];
		}
		else 
		{
			read = false;
			return ubyte.max;
		}
	}

	@system bool writeByte(ubyte b, size_t i)
	{
		immutable axisSize = TAxis.sizeof * N,
			valSize = TVal.sizeof * N;
		if(i < axisSize) // in axis
		{
			(cast(ubyte*)axis.ptr)[i] = b;
			return true;
		}
		else if(i >= axisSize && i < valSize + axisSize) // in values
		{
			(cast(ubyte*)values.ptr)[i - axisSize] = b;
			return true;
		}
		return false;
	}

	@system bool writeBytes(immutable ubyte* buffer, const size_t sz)
	{
		if(sz != numBytes) return false;

		bool failure;
		foreach(size_t i; 0 .. numBytes)
			failure |= !writeByte(buffer[i], i);
		return !failure;
	}
}

@system unittest
{
	Table2D!(ubyte, ubyte, 3) table;
	ubyte[] data = [50, 112, 150, 0, 128, 254];
	assert(table.writeBytes(cast(immutable)data.ptr, data.length));
	assert(table[50] == 0);
	assert(table[150] == 254);
	assert(table[112] == 128);
	assert(table[113] == 131);
	assert(table[148] == 247);
	bool dump;
	foreach(i; 0 .. table.numBytes)
		assert(table.readByte(i, dump) == data[i]);

	import std.stdio : writeln;
	import std.array : split;
	writeln("`" ~ Table2D.stringof.split('(')[0] ~ "` unit test passed.");
}

struct Table3D(TVal, TxAxis, TyAxis, ubyte SX, ubyte SY)
if(isNumeric!TVal && isNumeric!TxAxis && isNumeric!TyAxis 
   && SX > 0 && SY > 0)
{
	enum size_t numBytes = (TVal.sizeof * SX * SY) + (TxAxis.sizeof * SX) + (TyAxis.sizeof * SY);
	enum isTable = true;

	private TxAxis previousX;
	private TyAxis previousY;
	private TVal previousVal;

	private TxAxis[SX] xAxis;
	private TyAxis[SY] yAxis;
	private TVal[SY][SX] values;

	private size_t flatten(ubyte x, ubyte y)
	{
		return y * SX + x;
	}

	TVal opIndex(TxAxis x, TyAxis y)
	{
		clampRef(x, xAxis[0], xAxis[SX-1]);
		clampRef(y, yAxis[0], yAxis[SY-1]);

		if(x == previousX && y == previousY)
			return previousVal;
		previousX = x;
		previousY = y;

		if(x == xAxis[0] && y == yAxis[0])
		{
			previousVal = values[0][0];
			return previousVal;
		}
		if(x == xAxis[SX-1] && y == yAxis[0])
		{
			previousVal = values[SX-1][0];
			return previousVal;
		}
		if(x == xAxis[0] && y == yAxis[SY-1])
		{
			previousVal = values[0][SY-1];
			return previousVal;
		}
		if(x == xAxis[SX-1] && y == yAxis[SY-1])
		{
			previousVal = values[SX-1][SY-1];
			return previousVal;
		}

		ubyte binx, biny;
		foreach(ubyte b; 0 .. SX-1)
		{
			auto c = xAxis[b], n = xAxis[b+1];
			if(x >= c && (b == SX - 2 ? x <= n : x < n))
			{
				binx = b;
				break;
			}
		}
		foreach(ubyte b; 0 .. SY-1)
		{
			auto c = yAxis[b], n = yAxis[b+1];
			if(y >= c && (b == SX - 2 ? y <= n : y < n))
			{
				biny = b;
				break;
			}
		}

		immutable float xmin = xAxis[binx], xmax = xAxis[binx+1],
			ymin = yAxis[biny], ymax = yAxis[biny+1];

		float z_x0y0 = values[binx][biny];
		if(x == xmin && y == ymin)
		{
			previousVal = cast(TVal)z_x0y0;
			return previousVal;
		}
		float z_x1y0 = values[binx+1][biny];
		if(x == xmax && y == ymin)
		{
			previousVal = cast(TVal)z_x1y0;
			return previousVal;
		}
		float z_x0y1 = values[binx][biny+1];
		if(x == xmin && y == ymax)
		{
			previousVal = cast(TVal)z_x0y1;
			return previousVal;
		}
		float z_x1y1 = values[binx+1][biny+1];
		if(x == xmax && y == ymax)
		{
			previousVal = cast(TVal)z_x1y1;
			return previousVal;
		}

		immutable TVal val = cast(TVal)linterp3D!float(
													   x, xmin, xmax, y, ymin, ymax,
													   z_x0y0, z_x1y0, z_x0y1, z_x1y1);
		previousVal = val;
		return previousVal;
	}

	private enum axisXStart = 0, axisXEnd = TxAxis.sizeof * SX,
		axisYStart = axisXEnd, axisYEnd = axisYStart + TyAxis.sizeof * SY,
		valStart = axisYEnd, valEnd = valStart + TVal.sizeof * SX * SY;

	@system ubyte readByte(size_t i, ref bool read) const
	{
		if(i >= axisXStart && i < axisXEnd)
		{
			read = true;
			return (cast(ubyte*)xAxis.ptr)[i - axisXStart];
		}
		else if(i >= axisYStart && i < axisYEnd)
		{
			read = true;
			return (cast(ubyte*)yAxis.ptr)[i - axisYStart];
		}
		else if(i >= valStart && i < valEnd)
		{
			return (cast(ubyte*)values.ptr)[i - valStart];
		}
		else
		{
			read = false;
			return ubyte.max;
		}
	}

	@system bool writeByte(const ubyte b, const size_t i)
	{
		if(i >= axisXStart && i < axisXEnd)
		{
			(cast(ubyte*)xAxis.ptr)[i - axisXStart] = b;
			return true;
		}
		else if(i >= axisYStart && i < axisYEnd)
		{
			(cast(ubyte*)yAxis.ptr)[i - axisYStart] = b;
			return true;
		}
		else if(i >= valStart && i < valEnd)
		{
			(cast(ubyte*)values.ptr)[i - valStart] = b;
			return true;
		}
		else return false;
	}

	@system bool writeBytes(immutable ubyte* buffer, const size_t sz)
	{
		if(sz != numBytes) return false;

		bool failure = false;
		foreach(i; 0 .. numBytes)
			failure |= !writeByte(buffer[i], i);
		return !failure;
	}
}

@system unittest 
{
	Table3D!(ubyte, ubyte, ubyte, 3, 3) table;
	immutable ubyte[] tableData = [
		0, 50, 100,
		50, 100, 150,
		// in arr, x goes down, y goes across
		0, 55, 105,
		50, 140, 170,
		100, 150, 200
	];

	assert(table.writeBytes(tableData.ptr, tableData.length));
	assert(table[100, 150] == 200);
	assert(table[100, 149] == 199);
	assert(table[100, 148] == 198);
	assert(table[99, 150] == 199);
	assert(table[98, 150] == 198);
	bool dump;
	foreach(i; 0 .. table.numBytes)
		assert(table.readByte(i, dump) == tableData[i]);

	import std.stdio;
	import std.array : split;
	writeln("`" ~ Table3D.stringof.split('(')[0] ~ "` unit test passed.");
}