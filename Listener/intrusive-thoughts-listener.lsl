#include <IT/globals.lsl>

default
{
    changed( integer change )
    {
        if(change & CHANGED_OWNER) llResetScript();
    }

    attach(key id)
    {
        if(id) llSetObjectName("");
    }

    state_entry()
    {
        llSetObjectName("");
        llListen(HUD_SPEAK_CHANNEL, "", NULL_KEY, "");
    }

    listen(integer channel, string name, key id, string message)
    {
        llOwnerSay(message);
    }
}