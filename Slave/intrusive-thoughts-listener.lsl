#include <IT/globals.lsl>
list statements = [];
key owner = NULL_KEY;
integer timerMin = 0;
integer timerMax = 0;
integer locked = FALSE;

default
{
    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == API_RESET && id == llGetOwner()) llResetScript();
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
            if(locked) llOwnerSay("@detach=n");
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
        if(k != owner && llGetOwnerKey(k) != owner) return;
        if(m == "RESET")
        {
            llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "The intrusive thoughts slave worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about is resetting configuration and listening to new programming...");
            statements = [];
        }
        else if(m == "LOCK")
        {
            if(locked)
            {
                llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "The intrusive thoughts slave worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about is unlocked.");
                locked = FALSE;
                llOwnerSay("@detach=y");
            }
            else
            {
                llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "The intrusive thoughts slave worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about is locked.");
                locked = TRUE;
                llOwnerSay("@detach=n");
            }
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
        llMessageLinked(LINK_SET, API_SELF_DESC, llList2String(statements, llFloor(llFrand(llGetListLength(statements)))), NULL_KEY);
    }
}