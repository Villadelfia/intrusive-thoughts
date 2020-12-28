#include <IT/globals.lsl>
float hoverheight = 0.0;

setheight()
{
    string oldn = llGetObjectName();
    llSetObjectName("");
    if(hoverheight != 0.0) llOwnerSay("Hover height set to " + (string)hoverheight + ".");
    llOwnerSay("@adjustheight:" + (string)hoverheight + "=force");
    llSetObjectName(oldn);
}

default
{
    changed(integer change)
    {
        if(change & CHANGED_OWNER) llResetScript();
    }

    attach(key id)
    {
        if(id) setheight();
    }

    state_entry()
    {
        llListen(BALL_CHANNEL, "", NULL_KEY, "");
    }

    listen(integer channel, string name, key id, string message)
    {
        string oldn = llGetObjectName();
        llSetObjectName("Your Thoughts");
        llOwnerSay(message);
        llSetObjectName(oldn);
    }

    touch_start(integer total_number)
    {
        string name = llGetLinkName(llDetectedLinkNumber(0));
        if(name == "reset")
        {
            hoverheight = 0.0;
            setheight();
        }
        else if(name == "++")
        {
            hoverheight += 3.0;
            setheight();
        }
        else if(name == "+")
        {
            hoverheight += 0.5;
            setheight();
        }
        else if(name == "--")
        {
            hoverheight -= 3.0;
            setheight();
        }
        else if(name == "-")
        {
            hoverheight -= 0.5;
            setheight();
        }
    }
}
