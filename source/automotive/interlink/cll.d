module automotive.interlink.cll;

package
{
	extern(C) nothrow @nogc pure @system
	{
		/// Transmit a CAN frame
		int cll_canTx(ushort id, int length, ubyte* data);
		/// Get number of CAN messages available
		int cll_canRxPoll();
		/// Get first message in queue
		int cll_canRx(ushort* id, int* len, ubyte* arr);
	}
}