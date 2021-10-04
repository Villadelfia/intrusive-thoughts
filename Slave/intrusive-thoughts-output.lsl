#include <IT/globals.lsl>
key primary = NULL_KEY;
list owners = [];
integer publicaccess = FALSE;
integer groupaccess = FALSE;

integer blindmute = FALSE;
integer focus = FALSE;
integer disabled = FALSE;
integer speakon = 0;
string name;
float randomprefixchance = 0.0;
list randomprefixwords = [];
key focustarget = NULL_KEY;
float currentFocus = 2.0;
integer tempDisable = FALSE;

softReset()
{
    tempDisable = TRUE;
    focus = FALSE;
}

hardReset()
{
    
    tempDisable = FALSE;
    blindmute = FALSE;
    focus = FALSE;
    randomprefixchance = 0.0;
    randomprefixwords = [];
    name = llGetDisplayName(llGetOwner());
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
    integer bytes = getstringbytes(message);
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
            while(bytes >= 1024) bytes = getstringbytes(llGetSubString(message, 0, --offset));
            if(blindmute) llRegionSayTo(llGetOwner(), 0, llGetSubString(message, 0, offset));
            else          llOwnerSay(message);
            message = llDeleteSubString(message, 0, offset);
            bytes = getstringbytes(message);
        }
    }
    llSetObjectName(currentObjectName);
}

handleSay(string name, string message, integer excludeSelf)
{
    list agents;
    integer l;
    vector pos;
    float range;

    if(blindmute == TRUE || excludeSelf == TRUE)
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
    integer bytes = getstringbytes(message);
    while(bytes > 0)
    {
        if(bytes <= 1024)
        {
            if(blindmute == TRUE || excludeSelf == TRUE)
            {
                l = llGetListLength(agents)-1;
                for(; l >= 0; --l)
                {
                    key a = llList2Key(agents,l);
                    if(a == llGetOwner()) 
                    {
                        if(excludeSelf == FALSE) llRegionSayTo(a, 0, message);
                    }
                    else
                    {
                        llRegionSayTo(a, speakon, message);
                    }
                }
            }
            else
            {
                llSay(speakon, message);
                if(speakon != 0 && blindmute == TRUE) llRegionSayTo(llGetOwner(), 0, message);
                if(speakon != 0 && blindmute == FALSE) llOwnerSay(message);
            }
            bytes = 0;
            if(blindmute == TRUE || excludeSelf == TRUE || speakon != 0) llRegionSay(HOME_HUD_CHANNEL, message);
        }
        else
        {
            integer offset = 0;
            while(bytes >= 1024) bytes = getstringbytes(llGetSubString(message, 0, --offset));
            if(blindmute == TRUE || excludeSelf == TRUE)
            {
                l = llGetListLength(agents)-1;
                for(; l >= 0; --l)
                {
                    key a = llList2Key(agents,l);
                    if(a == llGetOwner())
                    {
                        if(excludeSelf == FALSE) llRegionSayTo(a, 0, llGetSubString(message, 0, offset));
                    }
                    else
                    {
                        llRegionSayTo(a, speakon, llGetSubString(message, 0, offset));
                    }
                }
            }
            else
            {
                llSay(speakon, llGetSubString(message, 0, offset));
                if(speakon != 0 && blindmute == TRUE) llRegionSayTo(llGetOwner(), 0, llGetSubString(message, 0, offset));
                if(speakon != 0 && blindmute == FALSE) llOwnerSay(llGetSubString(message, 0, offset));
            }
            if(blindmute == TRUE || excludeSelf == TRUE || speakon != 0) llRegionSay(HOME_HUD_CHANNEL, llGetSubString(message, 0, offset));
            message = llDeleteSubString(message, 0, offset);
            bytes = getstringbytes(message);
        }
    }
    llSetObjectName(currentObjectName);
}

focusToggle(key target)
{
    target = llGetOwnerKey(target);
    focustarget = target;
    focus = !focus;
    if(focus) ownersay(target, name + " is now forced to look at you.");
    else      ownersay(target, name + " is no longer forced to look at you.");
    llSetTimerEvent(0.1);
}

string prefixfilter(string m)
{
    if(tempDisable) return m;
    if(randomprefixchance == 0.0) return m;
    if(randomprefixwords == []) return m;
    integer emote = FALSE;
    if(startswith(llToLower(m), "/me") || startswith(llToLower(m), "/shout/me") || startswith(llToLower(m), "/shout /me") ||
       startswith(llToLower(m), "/whisper/me") || startswith(llToLower(m), "/whisper /me")) emote = TRUE;
    if(emote == TRUE && llToLower(llStringTrim(m, STRING_TRIM)) != "/me" && contains(m, "\"") == FALSE) return m;

    integer quotecnt = 0;
    string word;
    string oldword;
    string mcpy = m;
    m = llList2String(llParseStringKeepNulls(mcpy, [" ", ",", "\"", ".", "!", "?"], []), 0);
    if(llStringLength(mcpy) != llStringLength(m))
    {
        m += llGetSubString(mcpy, llStringLength(m), llStringLength(m));
        if(llGetSubString(m, -1, -1) == "\"") quotecnt++;
    }
    mcpy = llDeleteSubString(mcpy, 0, llStringLength(m)-1);
    while(llStringLength(mcpy) > 0)
    {
        word = llList2String(llParseStringKeepNulls(mcpy, [" ", ",", "\"", ".", "!", "?"], []), 0);
        oldword = word;

        if(word != "")
        {
            if(emote == FALSE || quotecnt % 2 != 0)
            {
                if(llFrand(1.0) < randomprefixchance)
                {
                    word = llList2String(randomprefixwords, llFloor(llFrand(llGetListLength(randomprefixwords)))) + " " + word;
                }
            }
        }

        m += word;
        if(llStringLength(mcpy) != llStringLength(oldword))
        {
            m += llGetSubString(mcpy, llStringLength(oldword), llStringLength(oldword));
            if(llGetSubString(m, -1, -1) == "\"") quotecnt++;
        }
        mcpy = llDeleteSubString(mcpy, 0, llStringLength(oldword));
    }
    return m;
}

default
{
    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == S_API_RLV_CHECK)
        {
            tempDisable = FALSE;
            if(focus) llSetTimerEvent(0.1);
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
        else if(num == S_API_EMERGENCY)
        {
            softReset();
        }
        else if(num == S_API_FOCUS_LEVEL)
        {
            currentFocus = (float)str;
            if(name != "") ownersay(id, name + " has had their focus distance adjusted to " + formatfloat(currentFocus, 2) + " meters.");
            else           ownersay(id, "secondlife:///app/agent/" + (string)llGetOwner() + "/about has had their focus distance adjusted to " + formatfloat(currentFocus, 2) + " meters.");
        }

        if(num == S_API_SELF_DESC && str != "")     handleSelfDescribe(str);
        else if(num == S_API_FOCUS_TOGGLE)          focusToggle(id);
        else if(num == S_API_ENABLE)                disabled = FALSE;
        else if(num == S_API_DISABLE)               disabled = TRUE;
        else if(num == S_API_SELF_SAY && str != "") handleSelfSay((string)id, str);
        
        if(disabled) return;

        if(num == S_API_SAY && str != "")                  handleSay((string)id, prefixfilter(str), FALSE);
        else if(num == S_API_ONLY_OTHERS_SAY && str != "") handleSay((string)id, prefixfilter(str), TRUE);
    }

    state_entry()
    {
        name = llGetDisplayName(llGetOwner());
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
    }

    timer()
    {
        llSetTimerEvent(0.0);
        if(!focus) return;

        vector pos = llList2Vector(llGetObjectDetails(focustarget, [OBJECT_POS]), 0);
        if(pos != ZERO_VECTOR)
        {
            list data;
            list uuids = llGetAttachedList(focustarget);
            integer n = llGetListLength(uuids);
            while(~--n)
            {
                data = llGetObjectDetails(llList2Key(uuids, n), [OBJECT_NAME, OBJECT_CREATOR, OBJECT_DESC]);
                if(startswith((string)data[0], "Intrusive Thoughts Focus Target") && (key)data[1] == llGetCreator())
                {
                    llOwnerSay("@setcam_focus:" + (string)llList2Key(uuids, n) + ";" + (string)currentFocus + ";" + (string)data[2] + "=force");
                    jump skipold;
                }
            }
            llOwnerSay("@setcam_focus:" + (string)focustarget + ";" + (string)currentFocus + ";=force");
            @skipold;
            llSetTimerEvent(0.1);
        }
        else
        {
            focus = FALSE;
        }
    }

    attach(key id)
    {
        llSetTimerEvent(0.0);
    }

    listen(integer c, string n, key k, string m)
    {
        if(!isowner(k)) return;
        if(m == "RESET")
        {
            hardReset();
        }
        else if(startswith(m, "NAME") && c == MANTRA_CHANNEL)
        {
            m = llDeleteSubString(m, 0, llStringLength("NAME"));
            name = m;
        }
        else if(startswith(m, "BLIND_MUTE"))
        {
            m = llDeleteSubString(m, 0, llStringLength("BLIND_MUTE"));
            if(m != "0") blindmute = TRUE;
            else         blindmute = FALSE;
        }
        else if(startswith(m, "DIALECT"))
        {
            m = llDeleteSubString(m, 0, llStringLength("DIALECT"));
            if(m != "0") speakon = SPEAK_CHANNEL;
            else         speakon = 0;
        }
        else if(startswith(m, "RANDOM_PREFIX_WORDS"))
        {
            randomprefixwords += [llDeleteSubString(m, 0, llStringLength("RANDOM_PREFIX_WORDS"))];
        }
        else if(startswith(m, "RANDOM_PREFIX_CHANCE"))
        {
            randomprefixchance = (float)llDeleteSubString(m, 0, llStringLength("RANDOM_PREFIX_CHANCE"));
        }
        else if(m == "END")
        {
            ownersay(k, "[output]: " + (string)(llGetFreeMemory() / 1024.0) + "kb free.");
        }
    }
}