#include <IT/globals.lsl>

default
{
    state_entry()
    {
        llSetTimerEvent(5.0);
    }

    timer()
    {
        llRegionSayTo(llGetOwner(), MANTRA_CHANNEL, "leashpoint");
    }
}