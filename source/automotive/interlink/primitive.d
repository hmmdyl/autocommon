module automotive.interlink.primitive;

import automotive.interlink.packet;

@safe @nogc nothrow:

alias InterlinkDeviceID = ubyte;

struct InterlinkError
{
	mixin packetHeader!1;

	/// Level of severity of this error
	enum Level : ubyte
	{ 
		/// Recoverable
		error,
		/// Non-recoverable
		panic 
	}

	/// Recovery method of error
	enum Recovery : ubyte 
	{ 
		/// Software will perform recovery
		software,
		/// Hardware will now restart
		hardwareRestart,
		/// Hardware will not shutdown
		hardwareShutdown
	}

	InterlinkDeviceID senderID; /// sender ID
	Level level; /// Level of error
	Recovery recovery; /// Recovery method
	ubyte[5] data; /// Error-specific data
}

struct InterlinkWarning
{
	mixin packetHeader!2;

	/// Recovery method
	enum Recovery : ubyte 
	{
		/// No recovery needed 
		none,
		/// The offending data will set to a default value
		defaultValue,
		/// The offending data will be clamped within acceptable bounds
		clampValue,
		/// Unknown recovery method
		other
	}

	InterlinkDeviceID senderID; /// Sender ID
	Recovery recovery; /// Recovery method
	ubyte[6] data; /// Warning-specific data
}

struct InterlinkHeartbeat
{
	mixin packetHeader!2047;
	mixin verifySizeExact!2;

	InterlinkDeviceID senderID; /// Sender ID
	ubyte status; /// Status of sender
}