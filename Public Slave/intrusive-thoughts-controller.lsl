#include <IT/globals.lsl>
integer started = FALSE;
key wearer;
string prefix;

default
{
    changed(integer change)
    {
        if(change & CHANGED_OWNER) resetscripts();
    }

    // This script bootstraps the entire IT Slave system.
    attach(key id)
    {
        if(id != NULL_KEY)
        {
            if(wearer != llGetOwner()) return;
            llMessageLinked(LINK_SET, S_API_STARTED, "", NULL_KEY);
        }
    }

    // Set up the owner and prefix on first wear.
    state_entry()
    {
        wearer = llGetOwner();
        prefix = llGetSubString(llGetUsername(llGetOwner()), 0, 1);
        llListen(COMMAND_CHANNEL, "", NULL_KEY, "");
        llSetObjectName("");
        llOwnerSay("This version of the IT Slave can be configured by *anyone* (including yourself). If this is incorrect, detach me immediately.");
        llSetObjectName(slave_base);
        started = TRUE;
        llMessageLinked(LINK_SET, S_API_STARTED, "", NULL_KEY);
    }

    link_message(integer sender_num, integer num, string str, key id )
    {
        if(num == S_API_HARD_RESET)
        {
            llOwnerSay("@clear");
            resetother();
            llSleep(5.0);
            llMessageLinked(LINK_SET, S_API_STARTED, "", NULL_KEY);
        }
    }
}
