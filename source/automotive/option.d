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

	@property isError() const { return !payloadExists; }
	@property error() const { return error_; }

	/// Return a pointer to the data, or if error, to `orelse`
	T* unwrapOrElse(return ref T orelse) 
	{
		if(isError)
			return &orelse;
		return &payload;
	}

	/// Return a pointer to the data, or if error, a null
	T* unwrapOrNull() 
	{ return isError ? null : &payload; }

	auto match(alias onResult, alias onError)()
	{
		if(isError)
		{
			static if(is(ReturnType!onError == noreturn))
				onError(error);
			else return onError(error);
		}
        else onResult(payload);
	}
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

	/// Returns a pointer to the data, or null
	T* unwrapOrNull()
	{ return isNull ? null : &payload; }

	/// Returns a pointer to the data, or `orelse`
	T* unwrapOrElse(return ref T orelse)
	{
		if(isNull) return &orelse;
		else return &payload;
	}

	auto match(alias onResult, alias onNull)()
    {
        if(exists) return onResult(payload);
        else
        {
            static if(is(ReturnType!onNull == noreturn))
                onNull();
            else return onNull();
        }
    }
}