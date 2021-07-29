module automotive.interlink.cll;

package
{
	extern(C) nothrow @nogc pure @system
	{
		version(Windows)
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
