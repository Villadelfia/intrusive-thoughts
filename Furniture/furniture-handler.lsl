#include <IT/globals.lsl>
key storedobject = NULL_KEY;
string storedname = "";

default
{
    state_entry()
    {
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
        llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES);
    }

    listen(integer c, string n, key id, string m)
    {
        // The IT controller is asking if we have anything stored.
        if(m == "furniture")
        {
            if(storedobject == NULL_KEY) llRegionSayTo(id, MANTRA_CHANNEL, "furniture 0");
            else                         llRegionSayTo(id, MANTRA_CHANNEL, "furniture 1");
        }

        // We've been by the IT controller that we have to give up whatever we are storing.
        else if(startswith(m, "puton"))
        {
            if(storedobject == NULL_KEY) return;
            llRegionSayTo(storedobject, MANTRA_CHANNEL, "puton " + (string)llGetOwnerKey(id) + "|||" + storedname);
            llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES);
            llSetTimerEvent(0.0);
        }

        // We've been told by the IT controller that whatever it is storing is now ours.
        else if(startswith(m, "putdown"))
        {
            // If we already had an object, we do an exchange.
            if(storedobject != NULL_KEY) llRegionSayTo(storedobject, MANTRA_CHANNEL, "puton " + (string)llGetOwnerKey(id) + "|||" + storedname);

            // We store the object.
            list params = llParseString2List(llDeleteSubString(m, 0, llStringLength("putdown")), ["|||"], []);
            storedobject = (key)llList2String(params, 0);
            storedname = llList2String(params, 1);

            // Let the object know to follow us now.
            llRegionSayTo(storedobject, MANTRA_CHANNEL, "putdown " + (string)llGetKey() + "|||" + llGetObjectName());
            llRegionSayTo(id, MANTRA_CHANNEL, "putdown");
            llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES);
            llSetTimerEvent(5.0);
        }
    }

    timer()
    {
        if(llGetObjectDetails(storedobject, [OBJECT_POS]) == []) llResetScript();
    }
}