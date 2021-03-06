module automotive.option;

import std.traits;

@safe:

/// A result can contain a value (success) or an error code (failure)
/// Params:
///     T: type for result
///     E: type for error
struct Result(T, E)
{
	private alias E_ = E;

	private T payload;
	private E error_;
	private bool payloadExists;

    /// Success
	this(T t) 
	{
		payload = t;
		payloadExists = true;
		error_ = E.init;
	}

    /// Failure
	this(E e) 
	{
		payload = T.init;
		error_ = e;
		payloadExists = false;
	}

	@property isError() const { return !payloadExists; }
	@property error() const { return error_; }

	/// Return a pointer to the data, or if error, to `orelse`
	/+T* unwrapOrElse(return ref T orelse) 
	{
		if(isError)
			return &orelse;
		return &payload;
	}
	alias uwElse = unwrapOrElse;+/

	/// Return a pointer to the data, or if error, a null
	T* unwrapOrNull() 
	{ return isError ? null : &payload; }
	alias uwNull = unwrapOrNull;
}

/++ Perform pattern match against result or error 
+ params:
+		onResult = function or lambda to call if result exists (must accept result as param)
+		onError = function or lambda to call if error exists (must accept error as param). Allows noreturn ++/
auto match(alias onResult, alias onError, T)(return ref T t)
	if(is(T : Result!(R, E), R, E))
{
	if(t.isError)
	{
		static if(is(ReturnType!onError == noreturn))
			onError(t.error);
		else return onError(t.error);
	}
	else return onResult(t.payload);
}

/// An `Optional!T` can either be a `T` type, or `null`
struct Optional(T)
{
	private T payload;
	private bool exists;

	/// Construct an `Optional` with data
	this(T t)
	{
		payload = t;
		exists = true;
	}

	/// Construct a null `Optional`
	static Optional null_() @trusted
	{
		Optional result = void; /// since payload can never be observed, do not initialise it
		result.exists = false;
		return result;
	}

	@property bool isNull() const { return !exists; }

	/// Returns a pointer to the data, or panics if null
	T* unwrapOrPanic() return
	in(!isNull, typeof(this).stringof ~ " was null")
	{ return &payload; }
	/// ditto
	alias uw = unwrapOrPanic;

	/// Returns a pointer to the data, or null
	T* unwrapOrNull() return
	{ return isNull ? null : &payload; }
	/// ditto
	alias uwNull = unwrapOrNull;

	/// Returns a pointer to the data, or `orelse`
	/+T* unwrapOrElse(return ref T orElse) return
	{
		if(isNull) return &orElse;
		else return &payload;
	}
	/// ditto
	alias uwElse = unwrapOrElse;+/
}

/++ Perform pattern match against result or null 
+ params:
+		onResult = function or lambda to call if result exists (must accept result as param)
+		onNull = function or lambda to call if null. 
Allows noreturn ++/
auto match(alias onResult, alias onNull, T)(return ref T t)
	if(is(T : Optional!Args, Args...))
{
	if(t.exists) return onResult(t.payload);
	else
	{
		static if(is(ReturnType!(onNull) == noreturn))
			onNull();
		else return onNull();
	}
}