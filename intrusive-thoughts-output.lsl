#define MANTRA_CHANNEL -216684563
#define VOICE_CHANNEL   166845631
#define SPEAK_CHANNEL   166845632
#define MC_CHANNEL            999
#define API_RESET              -1
#define API_SELF_DESC          -2
#define API_SELF_SAY           -3
#define API_SAY                -4
key owner = NULL_KEY;
integer blindmute = FALSE;
integer speakon = 0;

integer getStringBytes(string msg)
{
    return (llStringLength((string)llParseString2List(llStringToBase64(msg), ["="], [])) * 3) >> 2;
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

handleSelfDescribe(string message)
{
    integer firstSpace = llSubStringIndex(message, " ");
    while(firstSpace == 0)
    {
        message = llDeleteSubString(message, 0, 0);
        firstSpace = llSubStringIndex(message, " ");
    }
    string currentObjectName = llGetObjectName();
    if(firstSpace == -1)
    {
        llSetObjectName(".");
        llOwnerSay("/me " + message);
    }
    else
    {
        llSetObjectName(llGetSubString(message, 0, firstSpace-1));
        message = llDeleteSubString(message, 0, firstSpace);
        llOwnerSay("/me " + message);
    }
    llSetObjectName(currentObjectName);
}

handleSelfSay(string name, string message)
{
    string currentObjectName = llGetObjectName();
    llSetObjectName(name);
    integer bytes = getStringBytes(message);
    while(bytes > 0)
    {
        if(bytes <= 1024)
        {
            if(blindmute) llRegionSayTo(llGetOwner(), 0, message);
            else          llOwnerSay(message);
            bytes = 0;
        }
        else
        {
            integer offset = 0;
            while(bytes >= 1024) bytes = getStringBytes(llGetSubString(message, 0, --offset));
            if(blindmute) llRegionSayTo(llGetOwner(), 0, llGetSubString(message, 0, offset));
            else          llOwnerSay(message);
            message = llDeleteSubString(message, 0, offset);
            bytes = getStringBytes(message);
        }
    }
    llSetObjectName(currentObjectName);
}

handleSay(string name, string message)
{
    list agents;
    integer l;
    vector pos;
    float range;

    if(blindmute)
    {
        agents = llGetAgentList(AGENT_LIST_REGION, []);
        l = llGetListLength(agents)-1;
        pos = llGetPos();
        range = 20.0;

        if(startswith(message, "/whisper")) 
        {
            message = llDeleteSubString(message, 0, 7);
            range = 10.0;
        }
        else if(startswith(message, "/shout"))
        {
            message = llDeleteSubString(message, 0, 5);
            range = 100.0;
        }
 
        for(; l >= 0; --l)
        {
            vector target = llList2Vector(llGetObjectDetails(llList2Key(agents,l), [OBJECT_POS]), 0);
            if(llVecDist(target, pos) > range) agents = llDeleteSubList(agents, l, l);
        }
    }

    string currentObjectName = llGetObjectName();
    llSetObjectName(name);
    integer bytes = getStringBytes(message);
    while(bytes > 0)
    {
        if(bytes <= 1024)
        {
            if(blindmute)
            {
                l = llGetListLength(agents)-1;
                for(; l >= 0; --l)
                {
                    key a = llList2Key(agents,l);
                    if(a == llGetOwner()) llRegionSayTo(a, 0, message);
                    else                  llRegionSayTo(a, speakon, message);
                }
            }
            else
            {
                llSay(speakon, message);
                if(speakon != 0 && blindmute == TRUE) llRegionSayTo(llGetOwner(), 0, message);
                if(speakon != 0 && blindmute == FALSE) llOwnerSay(message);
            }
            bytes = 0;
        }
        else
        {
            integer offset = 0;
            while(bytes >= 1024) bytes = getStringBytes(llGetSubString(message, 0, --offset));
            if(blindmute)
            {
                l = llGetListLength(agents)-1;
                for(; l >= 0; --l)
                {
                    key a = llList2Key(agents,l);
                    if(a == llGetOwner()) llRegionSayTo(a, 0, llGetSubString(message, 0, offset));
                    else                  llRegionSayTo(a, speakon, llGetSubString(message, 0, offset));
                }
            }
            else
            {
                llSay(speakon, llGetSubString(message, 0, offset));
                if(speakon != 0 && blindmute == TRUE) llRegionSayTo(llGetOwner(), 0, llGetSubString(message, 0, offset));
                if(speakon != 0 && blindmute == FALSE) llOwnerSay(llGetSubString(message, 0, offset));
            }
            message = llDeleteSubString(message, 0, offset);
            bytes = getStringBytes(message);
        }
    }
    llSetObjectName(currentObjectName);
}

default
{
    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == API_RESET && id == llGetOwner()) llResetScript();
        else if(num == API_SELF_DESC) handleSelfDescribe(str);
        else if(num == API_SELF_SAY) handleSelfSay((string)id, str);
        else if(num == API_SAY) handleSay((string)id, str);
    }

    changed(integer change)
    {
        if(change & CHANGED_OWNER) llResetScript();
    }

    state_entry()
    {
        owner = llList2Key(llGetObjectDetails(llGetKey(), [OBJECT_LAST_OWNER_ID]), 0);
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
    }

    listen(integer c, string n, key k, string m)
    {
        if(k != owner && llGetOwnerKey(k) != owner) return;
        if(m == "RESET")
        {
            blindmute = FALSE;
        }
        else if(startswith(m, "BLIND_MUTE"))
        {
            m = llDeleteSubString(m, 0, llStringLength("BLIND_MUTE"));
            if(m != "0") blindmute = TRUE;
        }
        else if(startswith(m, "DIALECT"))
        {
            m = llDeleteSubString(m, 0, llStringLength("DIALECT"));
            if(m != "0") speakon = SPEAK_CHANNEL;
            else         speakon = 0;
        }
    }
}