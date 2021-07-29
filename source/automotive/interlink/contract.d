module automotive.interlink.contract;

import automotive.interlink.primitive;
import automotive.interlink.packet;

/+
Interlink contracts.

These are basic mechanisms to check if the data
required by one module is produced/sent by another module.
+/

/// Check if any device sends a packet we want
struct InterlinkCheckForPacketSender
{
	mixin packetHeader!4;
	mixin verifySizeExact!3;
	align(1):

	ubyte requestingDeviceID; /// The ID of the device that requires the CAN packet
	ushort packetID; /// The packet this contract refers to
}

/// Affirm device sends/produces required CAN packet
struct InterlinkAffirmPacketSender
{
	mixin packetHeader!3;
	mixin verifySizeExact!4;
	align(1):

	ubyte requestingDeviceID; /// The ID of the device that initiated the requesting
	ubyte replyingDeviceID; /// The ID of the device that produces/sends the CAN packet
	ushort packetID; /// The packet this contract refers to
}