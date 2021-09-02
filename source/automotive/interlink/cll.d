module automotive.interlink.cll;

package
{
	nothrow  @nogc pure @trusted
	{
		int cll_canRxPollTrusted() { return cll_canRxPoll; }

		int cll_canRxTrusted(ref ushort id, ref int len, ref ubyte[8] arr)
		{
			ushort id_;
			int len_;
			ubyte[8] arr_;
			int returnVal = cll_canRx(&id_, &len_, arr_.ptr);
			id = id_;
			len = len_;
			arr = arr_;
			return returnVal;
		}
	}
	extern(C) nothrow @nogc pure @system
	{
		version(unittest)
		{
			/// Transmit a CAN frame
			int cll_canTx(ushort id, int length, ubyte* data) { return 0; }
			/// Get number of CAN messages available
			int cll_canRxPoll() {return 0;}
			/// Get first message in queue
			int cll_canRx(ushort* id, int* len, ubyte* arr) {return 0;}
		}
		else
		{
			/// Transmit a CAN frame
			int cll_canTx(ushort id, int length, ubyte* data);
			/// Get number of CAN messages available
			int cll_canRxPoll();
			/// Get first message in queue
			int cll_canRx(ushort* id, int* len, ubyte* arr);
		}
	}
}
