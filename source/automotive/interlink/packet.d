module automotive.interlink.packet;

import automotive.interlink.cll;
import automotive.byteconv;
import automotive.option;

enum canbusMaxID = 2048;
enum canbusMaxPacketSize = 8;

struct CanBusPacket
{
	ushort id;
	ubyte[8] payload;
	ubyte length;
}

@nogc nothrow:

mixin template canReadFunc()
{
	alias TThis = typeof(this);

	/// Read this descriptive CAN packet from a generic `CanBusPacket`
	static bool readFromCanPacket(const ref CanBusPacket p, out TThis ot) @trusted
	{
		if(p.id != ot.id) return 
			false;

		//ot = fromByteArr!(typeof(this))(p.payload[0..8]);
		ubyte[] resultArr = (*cast(ubyte[TThis.sizeof]*)&ot);
		foreach(b; 0 .. TThis.sizeof) 
			resultArr[b] = p.payload[b];
		return true;
	}

	/// Read this descriptive CAN packet from a generic `CanBusPacket`
	bool readFromCanPacket(const ref CanBusPacket p) @safe
	{
		return readFromCanPacket(p, this);
	}

	/// Instantiate this descriptive CAN packet from a generic `CanBusPacket`
	this(const ref CanBusPacket p) @safe
	{
		readFromCanPacket(p, this);
	}
}

mixin template canWriteFunc()
{
	alias TThis = typeof(this);

	/// Write this descriptive CAN packet to a generic `CanBusPacket`
	static void writeToCanPacket(out CanBusPacket p, const ref TThis ot) @trusted
	{
		p.id = TThis.id;
		p.payload[] = 0;
		p.payload[0 .. TThis.sizeof] = (*cast(ubyte[TThis.sizeof]*)&ot)[0 .. TThis.sizeof];
		p.length = TThis.sizeof;
	}

	/// Write this descriptive CAN packet to a generic `CanBusPacket`
	void writeToCanPacket(out CanBusPacket p) @safe
	{
		writeToCanPacket(p, this);
	}
}

/// Packet header for a descriptive CAN packet.
mixin template packetHeader(ushort pid)
{
	static assert(pid < canbusMaxID, "Invalid ID");
	static assert(is(typeof(this) == struct), "Must be a struct!");

	enum id = pid;

	mixin canReadFunc;
	mixin canWriteFunc;
	mixin verifySizeConstraint;
}

mixin template verifySizeConstraint()
{
	static assert(typeof(this).sizeof <= canbusMaxPacketSize, 
				  "Size must not exceed canbusMaxPacketSize");
}

/// Verify that the current type is same size as `targetSize`
mixin template verifySizeExact(byte targetSize)
{
	static assert(typeof(this).sizeof == targetSize,
				  "Size of this must be equal to targetSize for " ~ typeof(this).stringof);
}

static struct CanBus
{
	@disable this();
	@disable this(this);

	/// Checks if any CAN bus messages are available for reading
	static bool available() { return cll_canRxPoll > 0; }

	/// Read a CAN bus message
	static Optional!CanBusPacket rx() @trusted {
		if(cll_canRxPoll <= 0)
			return Optional!(CanBusPacket).null_;

		ushort id;
		int len;
		ubyte[8] p = void;

		auto result = cll_canRx(&id, &len, &p[0]);
		if(result == 0)
			return Optional!(CanBusPacket).null_;

		CanBusPacket pkt;
		pkt.id = id;
		pkt.length = cast(ubyte)len;
		foreach(i; 0 .. len)
			pkt.payload[i] = p[i];

		return Optional!CanBusPacket(pkt);
	}

	/// Transmit a CAN message
	static bool tx(ref CanBusPacket pkt) @trusted
	{
		return cast(bool)cll_canTx(pkt.id, pkt.length, &pkt.payload[0]);
	}
}