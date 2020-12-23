#include <IT/globals.lsl>
key tuned = NULL_KEY;
key owner = NULL_KEY;

handleSelfSay(string name, string message)
{
    string currentObjectName = llGetObjectName();
    llSetObjectName(name);
    integer bytes = getstringbytes(message);
    while(bytes > 0)
    {
        if(bytes <= 1024)
        {
            llOwnerSay(message);
            bytes = 0;
        }
        else
        {
            integer offset = 0;
            while(bytes >= 1024) bytes = getstringbytes(llGetSubString(message, 0, --offset));
            llOwnerSay(message);
            message = llDeleteSubString(message, 0, offset);
            bytes = getstringbytes(message);
        }
    }
    llSetObjectName(currentObjectName);
}

default
{
    changed(integer change)
    {
        if(change & CHANGED_OWNER) llResetScript();
    }

    attach(key id)
    {
        if(id)
        {
            if(owner != llGetOwner()) return;
            llOwnerSay("This translator is tuned to hear only speech said with the Intrusive Thoughts system worn by secondlife:///app/agent/" + (string)tuned + "/about.");
        }
    }

    state_entry()
    {
        tuned = llList2Key(llGetObjectDetails(llGetKey(), [OBJECT_LAST_OWNER_ID]), 0);
        owner = llGetOwner();
        llOwnerSay("This translator is tuned to hear only speech said with the Intrusive Thoughts system worn by secondlife:///app/agent/" + (string)tuned + "/about.");
        llListen(SPEAK_CHANNEL, "", NULL_KEY, "");
    }

    listen(integer c, string n, key k, string m)
    {
        if(llGetOwnerKey(k) != tuned) return;
        handleSelfSay(n, m);
    }
}