#define MANTRA_CHANNEL -216684563
#define VOICE_CHANNEL   166845631
#define MC_CHANNEL            999
#define API_RESET              -1
#define API_SELF_DESC          -2
#define API_SELF_SAY           -3
#define API_SAY                -4
list statements = [];
key owner = NULL_KEY;
integer timerMin = 0;
integer timerMax = 0;
integer locked = FALSE;

integer startswith(string haystack, string needle)
{
    return llDeleteSubString(haystack, llStringLength(needle), 0x7FFFFFF0) == needle;
}

integer random(integer min, integer max)
{
    return min + (integer)(llFrand(max - min + 1));
}

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
            llRegionSayTo(owner, 0, "Receiving new commands...");
            statements = [];
        }
        else if(m == "LOCK")
        {
            if(locked)
            {
                llRegionSayTo(owner, 0, "The intrusive thoughts slave worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about is unlocked.");
                locked = FALSE;
                llOwnerSay("@detach=y");
            }
            else
            {
                llRegionSayTo(owner, 0, "The intrusive thoughts slave worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about is locked.");
                locked = TRUE;
                llOwnerSay("@detach=n");
            }
        }
        else if(m == "END")
        {
            llRegionSayTo(owner, 0, "Reprogrammed.");
        }
        else if(m == "PING")
        {
            llRegionSayTo(owner, MANTRA_CHANNEL-1, "PING");
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
        else if(startswith(m, "TRIGGER_THOUGHT"))
        {
            m = llDeleteSubString(m, 0, llStringLength("TRIGGER_THOUGHT"));
            llMessageLinked(LINK_SET, API_SELF_DESC, m, NULL_KEY);
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