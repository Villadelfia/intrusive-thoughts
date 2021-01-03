#include <IT/globals.lsl>
key primary = NULL_KEY;
list owners = [];
integer publicaccess = FALSE;
integer groupaccess = FALSE;

list statements = [];
integer timerMin = 0;
integer timerMax = 0;

default
{
    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == S_API_STARTED)
        {
            llRegionSayTo(llGetOwner(), MANTRA_CHANNEL, "CHECKPOS " + (string)llGetAttached());
        }
        else if(num == S_API_OWNERS)
        {
            owners = [];
            list new = llParseString2List(str, [","], []);
            integer n = llGetListLength(new);
            while(~--n)
            {
                owners += [(key)llList2String(new, n)];
            }
            primary = id;
        }
        else if(num == S_API_OTHER_ACCESS)
        {
            publicaccess = (integer)str;
            groupaccess = (integer)((string)id);
        }
    }

    state_entry()
    {
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
    }

    listen(integer c, string n, key k, string m)
    {
        if(startswith(m, "CHECKPOS") == TRUE && llGetOwnerKey(k) == llGetOwner())
        {
            integer attachedto = (integer)llDeleteSubString(m, 0, llStringLength("CHECKPOS"));
            if(attachedto == llGetAttached())
            {
                ownersay(k, "POSMATCH " + (string)llGetLocalPos());
                llOwnerSay("Detected new IT Slave on this attachment point. Moving it in place and detaching myself.");
                llOwnerSay("@clear,detachme=force");
            }
            else
            {
                llOwnerSay("Detected new IT Slave on another attachment point. Detaching it.");
                ownersay(k, "POSNOMATCH " + (string)llGetAttached());
            }
        }
        else if(startswith(m, "POSMATCH") == TRUE && llGetOwnerKey(k) == llGetOwner())
        {
            vector newpos = (vector)llDeleteSubString(m, 0, llStringLength("POSMATCH"));
            llOwnerSay("Moving myself into the position of your old IT slave.");
            llSetPos(newpos);
        }
        else if(startswith(m, "POSNOMATCH") == TRUE && llGetOwnerKey(k) == llGetOwner())
        {
            integer attachedto = (integer)llDeleteSubString(m, 0, llStringLength("POSNOMATCH"));
            llOwnerSay("You already have another IT slave attached, but it is attached to " + attachpointtotext(attachedto) + ". Please attach me to that point instead. Detaching now.");
            llOwnerSay("@clear,detachme=force");
        }

        if(!isowner(k)) return;
        if(m == "RESET")
        {
            ownersay(k, "The " + VERSION_S + " worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about is resetting configuration and listening to new programming...");
            statements = [];
        }
        else if(m == "END")
        {
            ownersay(k, "[mantra]: " + (string)(llGetFreeMemory() / 1024.0) + "kb free.");
        }
        else if(m == "PING")
        {
            llRegionSayTo(k, PING_CHANNEL, "PING");
        }
        else if(startswith(m, "TIMER"))
        {
            list t = llParseString2List(m, [" "], []);
            timerMin = (integer)llList2String(t, 1);
            timerMax = (integer)llList2String(t, 2);
            if(timerMax != 0) llSetTimerEvent(random(timerMin * 60, timerMax * 60));
        }
        else if(startswith(m, "PHRASES"))
        {
            statements += [llDeleteSubString(m, 0, llStringLength("PHRASES"))];
        }
    }

    timer()
    {
        if(timerMax == 0)
        {
            llSetTimerEvent(0.0);
            return;
        }
        llSetTimerEvent(random(timerMin * 60, timerMax * 60));
        if(statements == []) return;
        llMessageLinked(LINK_SET, S_API_SELF_DESC, llList2String(statements, llFloor(llFrand(llGetListLength(statements)))), NULL_KEY);
    }
}