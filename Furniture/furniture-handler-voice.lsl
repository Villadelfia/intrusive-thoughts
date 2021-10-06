#include <IT/globals.lsl>
key storedobject = NULL_KEY;
key storedavatar = NULL_KEY;
key capturing = NULL_KEY;
string storedname = "";

whichperson()
{
    storedavatar = NULL_KEY;
    if(storedobject == NULL_KEY) return;

    list agents = llGetAgentList(AGENT_LIST_REGION, []);
    integer n = llGetListLength(agents);
    while(~--n)
    {
        key agent = llList2Key(agents, n);
        if(llList2Key(llGetObjectDetails(agent, [OBJECT_ROOT]), 0) == storedobject)
        {
            storedavatar = agent;
            return;
        }
    }

    // If we get here, something has gone horribly wrong.
    llRegionSayTo(storedobject, MANTRA_CHANNEL, "unsit");
    llResetScript();
}

saytoobject(string n, string m)
{
    string old = llGetObjectName();
    llSetObjectName(n);
    llRegionSayTo(storedavatar, GAZE_ECHO_CHANNEL, m);
    llSetObjectName(old);
}

default
{
    state_entry()
    {
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
        llListen(GAZE_CHAT_CHANNEL, "", NULL_KEY, "");
        llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES);
    }

    listen(integer c, string n, key id, string m)
    {
        if(c == MANTRA_CHANNEL)
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
                storedobject = NULL_KEY;
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
                whichperson();

                // Let the object know to follow us now.
                llRegionSayTo(storedobject, MANTRA_CHANNEL, "putdown " + (string)llGetKey() + "|||" + llGetObjectName());
                llRegionSayTo(id, MANTRA_CHANNEL, "putdown");
                llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES);
                llSetTimerEvent(2.5);
            }

            // We've been told by the IT controller to capture someone.
            else if(startswith(m, "capture"))
            {
                // If we have an object, refuse.
                if(storedobject != NULL_KEY) return;

                // If we don't have a ball, refuse.
                if(llGetInventoryType("ball") != INVENTORY_OBJECT) return;

                // Set the uuid of who to capture.
                capturing = (key)llDeleteSubString(m, 0, llStringLength("putdown"));

                // Then do it.
                integer option = 4 | 1;
                if(contains(llGetObjectDesc(), "invis")) option = 4 | 2;
                llRezAtRoot("ball", llGetPos(), ZERO_VECTOR, ZERO_ROTATION, option);
            }
        }
        else if(c == GAZE_CHAT_CHANNEL)
        {
            // Don't bother if we have no object.
            if(storedobject == NULL_KEY) return;

            // First we check if the message would already be allowed...
            if(llToLower(llStringTrim(m, STRING_TRIM)) != "/me" && startswith(m, "/me") == TRUE && contains(m, "\"") == FALSE) return;

            // If it's the right avatar, we say it.
            if(storedavatar == id) llSay(0, m);
        }
    }

    object_rez(key id)
    {
        if(llList2String(llGetObjectDetails(id, [OBJECT_NAME]), 0) != "ball") return;
        storedobject = id;
        storedavatar = capturing;
        storedname = llGetObjectName();
        llRegionSayTo(capturing, RLVRC, "c," + (string)capturing + ",@sit:" + (string)id + "=force|!x-handover/" + (string)id + "/0|!release");
        llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES);
        llSay(0, "A magical force begins acting on the body of " + llGetDisplayName(capturing) + " as they find themselves being transformed into the form of a " + llGetObjectName() + ".");
        llSetTimerEvent(15.0);
    }

    timer()
    {
        if(llGetObjectDetails(storedobject, [OBJECT_POS]) == []) llResetScript();
        llSetTimerEvent(2.5);
    }
}