#include <IT/globals.lsl>
list statements = [];
key owner = NULL_KEY;
integer timerMin = 0;
integer timerMax = 0;

default
{
    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == S_API_RESET && id == llGetOwner()) llResetScript();
    }

    changed(integer change)
    {
        if(change & CHANGED_OWNER) llResetScript();
    }

    attach(key id)
    {
        if(id == NULL_KEY)
        {
            llOwnerSay("@clear");
        }
        else
        {
            llRegionSayTo(id, MANTRA_CHANNEL, "CHECKPOS " + (string)llGetAttached());
        }
    }

    on_rez(integer start)
    {
        if(llGetAttached() == 0)
        {
            llDie();
        }
        else
        {
            llSetObjectDesc((string)owner);
        }
    }

    state_entry()
    {
        owner = llList2Key(llGetObjectDetails(llGetKey(), [OBJECT_LAST_OWNER_ID]), 0);
        llOwnerSay("Your owner has been detected as secondlife:///app/agent/" + (string)owner + "/about. If this is incorrect, detach me immediately because this person can configure me.");
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
        llSetTimerEvent(0.0);
    }

    listen(integer c, string n, key k, string m)
    {
        if(startswith(m, "CHECKPOS") == TRUE && llGetOwnerKey(k) == llGetOwner())
        {
            integer attachedto = (integer)llDeleteSubString(m, 0, llStringLength("CHECKPOS"));
            if(attachedto == llGetAttached())
            {
                llRegionSayTo(k, MANTRA_CHANNEL, "POSMATCH " + (string)llGetLocalPos());
                llOwnerSay("Detected new IT Slave on this attachment point. Moving it in place and detaching myself.");
                llOwnerSay("@clear,detachme=force");
            }
            else
            {
                llOwnerSay("Detected new IT Slave on another attachment point. Detaching it.");
                llRegionSayTo(k, MANTRA_CHANNEL, "POSNOMATCH " + (string)llGetAttached());
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

        if(k != owner && llGetOwnerKey(k) != owner) return;
        if(m == "RESET")
        {
            llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "The " + VERSION_S + " worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about is resetting configuration and listening to new programming...");
            statements = [];
        }
        else if(m == "END")
        {
            llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "[" + llGetScriptName() + "]: " + (string)(llGetFreeMemory() / 1024.0) + "kb free.");
        }
        else if(m == "PING")
        {
            llRegionSayTo(owner, PING_CHANNEL, "PING");
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
            m = llDeleteSubString(m, 0, llStringLength("PHRASES"));
            statements += [m];
        }
    }

    timer()
    {
        if(timerMax != 0) 
        {
            llSetTimerEvent(random(timerMin * 60, timerMax * 60));
        }
        else
        {
            llSetTimerEvent(0.0);
            return;
        }
        if(statements == []) return;
        llMessageLinked(LINK_SET, S_API_SELF_DESC, llList2String(statements, llFloor(llFrand(llGetListLength(statements)))), NULL_KEY);
    }
}