module automotive.byteconv;

import std.traits;

@system:

ubyte[] toByteArr(T)(T item) pure if(isPointer!T) {
	alias target = PointerTarget!T;
	return (*cast(ubyte[target.sizeof]*)item)[0 .. target.sizeof];
}

ubyte[] toByteArr(T)(ref T item) pure if(!isPointer!T){
	return (*cast(ubyte[T.sizeof]*)&item)[0 .. T.sizeof];
}

T fromByteArr(T)(ubyte[] item) {
	static assert(!isPointer!T);

	T result;
	ubyte[] resultArr = (*cast(ubyte[T.sizeof]*)&result);
	foreach(b; 0 .. T.sizeof) 
		resultArr[b] = item[b];
	return result;
}

unittest {
	long c = 9;
	ubyte[] cArr = c.toByteArr;
	assert(cArr.length == 8);
	assert(cArr[0] == 9);

	long* d = &c;
	*d = 10;
	ubyte[] dArr = d.toByteArr;
	assert(dArr.length == 8);
	assert(dArr[0] == 10);

	dArr[0] = 11;
	long e = fromByteArr!long(dArr);
	assert(e == 11);
}