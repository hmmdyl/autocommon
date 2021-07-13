module automotive.option;

@safe:

/// A result can contain a value (success) or an error code (failure)
/// Params:
///     T: type for result
///     E: type for error
struct Result(T, E)
{
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

	@property bool isError() const { return !payloadExists; }
	@property E error() const { return error_; }

	/// Return a pointer to the data, or if error, to `orelse`
	T* unwrapOrElse(ref T orelse) const 
	{
		if(isError)
			return &orelse;
		return &payload;
	}

	/// Return a pointer to the data, or if error, a null
	T* unwrapOrNull() 
	{ return isError ? null : &payload; }
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

	@property bool isNull() const { return !payloadExists; }

	/// Returns a pointer to the data, or null
	T* unwrapOrNull()
	{ return isNull ? null : &payload; }

	/// Returns a pointer to the data, or `orelse`
	T* unwrapOrElse(ref T orelse)
	{
		if(isNull) return &orelse;
		else return &payload;
	}
}