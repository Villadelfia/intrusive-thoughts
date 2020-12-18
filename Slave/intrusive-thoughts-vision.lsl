#define MANTRA_CHANNEL -216684563
#define VOICE_CHANNEL   166845631
#define MC_CHANNEL            999
#define API_RESET              -1
#define API_SELF_DESC          -2
#define API_SELF_SAY           -3
#define API_SAY                -4
key owner = NULL_KEY;
string name = "";
integer blind = FALSE;
string unblindmsg = "";
string blindmsg = "";
list blindcmd = [];
list unblindcmd = [];

integer getStringBytes(string msg)
{
    return (llStringLength((string)llParseString2List(llStringToBase64(msg), ["="], [])) * 3) >> 2;
}

integer random(integer min, integer max)
{
    return min + (integer)(llFrand(max - min + 1));
}

integer contains(string haystack, string needle)
{
    return ~llSubStringIndex(haystack, needle);
}

integer endswith(string haystack, string needle)
{
    return llDeleteSubString(haystack, 0x8000000F, ~llStringLength(needle)) == needle;
}

integer startswith(string haystack, string needle)
{
    return llDeleteSubString(haystack, llStringLength(needle), 0x7FFFFFF0) == needle;
}

handleHear(key skey, string sender, string message)
{
    integer l1;
    if(blind)
    {
        if(skey == owner || llGetOwnerKey(skey) == owner)
        {
            l1 = llGetListLength(unblindcmd)-1;
            for(;l1 >= 0; --l1)
            {
                if(contains(llToLower(message), llList2String(unblindcmd, l1)))
                {
                    blind = FALSE;
                    llMessageLinked(LINK_SET, API_SELF_DESC, unblindmsg, NULL_KEY);
                    llRegionSayTo(owner, 0, name + " can see again.");
                    checkSetup();
                }
            }
        }
    }
    else
    {
        if(skey == owner || llGetOwnerKey(skey) == owner)
        {
            l1 = llGetListLength(blindcmd)-1;
            for(;l1 >= 0; --l1)
            {
                if(contains(llToLower(message), llList2String(blindcmd, l1)))
                {
                    blind = TRUE;
                    llMessageLinked(LINK_SET, API_SELF_DESC, blindmsg, NULL_KEY);
                    llRegionSayTo(owner, 0, name + " can no longer see.");
                    checkSetup();
                }
            }
        }
    }
}

checkSetup()
{
    if(blind) llOwnerSay("@setoverlay=n,setoverlay_texture:1210e690-3eb8-239d-ceb9-3db4eb1a3fca=force,setoverlay_alpha:0=force,setoverlay_tween:1;;5=force");
    else      llOwnerSay("@setoverlay=y");
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
        if(id != NULL_KEY) checkSetup();
    }

    state_entry()
    {
        owner = llList2Key(llGetObjectDetails(llGetKey(), [OBJECT_LAST_OWNER_ID]), 0);
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
        llListen(0, "", NULL_KEY, "");
    }

    listen(integer c, string n, key k, string m)
    {
        if(c == 0) handleHear(k, n, m);
        if(k != owner && llGetOwnerKey(k) != owner) return;
        if(m == "RESET")
        {
            blind = FALSE;
            unblindmsg = "";
            blindmsg = "";
            blindcmd = [];
            unblindcmd = [];
            name = "";
            checkSetup();
        }
        else if(startswith(m, "NAME"))
        {
            m = llDeleteSubString(m, 0, llStringLength("NAME"));
            name = m;
        }
        else if(startswith(m, "BLIND_MSG"))
        {
            m = llDeleteSubString(m, 0, llStringLength("BLIND_MSG"));
            blindmsg = m;
        }
        else if(startswith(m, "UNBLIND_MSG"))
        {
            m = llDeleteSubString(m, 0, llStringLength("UNBLIND_MSG"));
            unblindmsg = m;
        }
        else if(startswith(m, "BLIND_CMD"))
        {
            m = llDeleteSubString(m, 0, llStringLength("BLIND_CMD"));
            blindcmd += [llToLower(m)];
        }
        else if(startswith(m, "UNBLIND_CMD"))
        {
            m = llDeleteSubString(m, 0, llStringLength("UNBLIND_CMD"));
            unblindcmd += [llToLower(m)];
        }
        else if(m == "END")
        {
            llRegionSayTo(owner, 0, "[" + llGetScriptName() + "]: " + (string)(llGetFreeMemory() / 1024.0) + "kb free.");
        }
    }
}