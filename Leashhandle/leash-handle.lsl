#include <IT/globals.lsl>

default
{
    state_entry()
    {
        llSetTimerEvent(5.0);
    }

    timer()
    {
        llRegionSay(MANTRA_CHANNEL, "leashpoint");
    }
}