#include <IT/globals.lsl>

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
    attach(key id)
    {
        if(id)
        {
            llOwnerSay("This translator is tuned to hear everything said by wearers of the Intrusive Thoughts system.");
        }
    }

    state_entry()
    {
        llListen(SPEAK_CHANNEL, "", NULL_KEY, "");
        llOwnerSay("This translator is tuned to hear everything said by wearers of the Intrusive Thoughts system.");
    }

    listen(integer c, string n, key k, string m)
    {
        handleSelfSay(n, m);
    }
}