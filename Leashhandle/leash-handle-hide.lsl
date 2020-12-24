#include <IT/globals.lsl>
key leashedto = NULL_KEY;

default
{
    state_entry()
    {
        llSetTimerEvent(5.0);
        llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES);
        llListen(LEASH_CHANNEL, "", NULL_KEY, "");
    }

    attach(key id)
    {
        leashedto = NULL_KEY;
    }

    listen(integer c, string n, key id, string m)
    {
        if(m == "leashed")
        {
            leashedto = id;
            llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES);
        }
        else if(m == "unleashed")
        {
            leashedto = NULL_KEY;
            llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES);
        }
    }

    timer()
    {
        llRegionSay(MANTRA_CHANNEL, "leashpoint");
        if(leashedto)
        {
            if(llList2Vector(llGetObjectDetails(leashedto, [OBJECT_POS]), 0) == ZERO_VECTOR)
            {
                leashedto = NULL_KEY;
                llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES);
            }
        }
    }
}