#define MANTRA_CHANNEL -216684563
#define VOICE_CHANNEL   166845631
#define MC_CHANNEL            999
#define API_RESET              -1
#define API_SELF_DESC          -2
#define API_SELF_SAY           -3
#define API_SAY                -4
key owner = NULL_KEY;
integer deaf = FALSE;
string name = "";
list auditoryfilterfrom = [];
list auditoryfilterto = [];
integer auditorybimbolimit = 0;
float auditorybimboodds = 1.0;
list auditorybimbocensor = ["_"];
list auditorybimboexcept = [];
string deafenmsg = "";
string undeafenmsg = "";
list deafencmd = [];
list undeafencmd = [];
list deafenexcept = [];
integer setup = FALSE;

integer getStringBytes(string msg)
{
    return (llStringLength((string)llParseString2List(llStringToBase64(msg), ["="], [])) * 3) >> 2;
}

integer contains(string haystack, string needle)
{
    return 0 <= llSubStringIndex(haystack, needle);
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
    if(!setup) return;
    if(startswith(message, "((") == TRUE && endswith(message, "))") == TRUE) return;
    while(startswith(message, "@")) message = llDeleteSubString(message, 0, 0);
    integer l1;
    string messagecopy;
    string word;
    integer replaceidx;
    string oldword;
    string prefix;
    string nameSay;

    if(deaf)
    {
        // Handle undeafening by owner.
        if(skey == owner || llGetOwnerKey(skey) == owner)
        {
            l1 = llGetListLength(undeafencmd)-1;
            for(;l1 >= 0; --l1)
            {
                if(contains(llToLower(message), llList2String(undeafencmd, l1)))
                {
                    deaf = FALSE;
                    llMessageLinked(LINK_SET, API_SELF_DESC, undeafenmsg, NULL_KEY);
                    llRegionSayTo(owner, 0, name + " can hear the conversation again.");
                    jump cont1;
                }
            }
        }
        
        // Handle deafen exceptions.
        l1 = llGetListLength(deafenexcept)-1;
        for(;l1 >= 0; --l1)
        {
            if(contains(llToLower(message), llList2String(deafenexcept, l1)))
            {
                llMessageLinked(LINK_SET, API_SELF_DESC, undeafenmsg, NULL_KEY);
                llRegionSayTo(owner, 0, name + " heard that message because of exceptions.");
                jump cont1;
            }
        }

        if(startswith(message, "/me") == TRUE && contains(message, "\"") == FALSE) jump cont1;
        return;
    }
    @cont1;

    if(skey != llGetOwnerKey(skey))
    {
        nameSay = sender;
    }
    else
    {
        if(endswith(sender, " Resident"))
        {
            sender = llDeleteSubString(sender, -9, -1);
        }
        if(llGetDisplayName(skey) != sender)
        {
            if(contains(sender, " Resident"))
            {
                sender = llDeleteSubString(sender, llSubStringIndex(sender, " Resident"), llStringLength("Resident"));
            }
            prefix = llGetDisplayName(skey) + " (" + sender + ")";
            if(startswith(message, "/me"))
            {
                message = llDeleteSubString(message, 0, 2);
            }
            else
            {
                prefix += ": ";
            }
            sender = "";
        }
        nameSay = sender;
    }

    // Handle deafening by owner.
    if((skey == owner || llGetOwnerKey(skey) == owner) && deaf == FALSE)
    {
        l1 = llGetListLength(deafencmd)-1;
        for(;l1 >= 0; --l1)
        {
            if(contains(llToLower(message), llList2String(deafencmd, l1)))
            {
                deaf = TRUE;
                llRegionSayTo(owner, 0, name + " can no longer hear the conversation.");
                jump cont2;
            }
        }
    }
    @cont2;

    // Handle replacement.
    messagecopy = message;
    message = "";
    while(llStringLength(messagecopy) > 0)
    {
        word = llList2String(llParseStringKeepNulls(messagecopy, [" ", ",", "\"", ";", ":", ".", "?", "!"], []), 0);
        oldword = word;

        // First we check if it gets replaced.
        replaceidx = llListFindList(auditoryfilterfrom, [llToLower(word)]);
        if(replaceidx != -1)
        {
            word = llList2String(auditoryfilterto, replaceidx);
        }

        // Then we bimbofy if the word is unchanged, too long and not in the exception list.
        else if(auditorybimbolimit > 0 && llStringLength(word) > auditorybimbolimit && llListFindList(auditorybimboexcept, [llToLower(word)]) == -1)
        {
            string newword;
            while(llStringLength(word) > 0)
            {
                if(llFrand(1.0) < auditorybimboodds)
                {
                    newword += llGetSubString(word, 0, 0);
                    word = llDeleteSubString(word, 0, 0);
                }
                else
                {
                    newword += llList2String(auditorybimbocensor, llFloor(llFrand(llGetListLength(auditorybimbocensor))));
                    word = llDeleteSubString(word, 0, 0);
                }
            }
            word = newword;
        }

        message += word;
        if(llStringLength(messagecopy) != llStringLength(oldword))
        {
            message += llGetSubString(messagecopy, llStringLength(oldword), llStringLength(oldword));
        }
        messagecopy = llDeleteSubString(messagecopy, 0, llStringLength(oldword));
    }

    message = prefix + message;
    llMessageLinked(LINK_SET, API_SELF_SAY, message, (key)nameSay);
    if(deaf) llMessageLinked(LINK_SET, API_SELF_DESC, deafenmsg, NULL_KEY);
}

checkSetup()
{
    if(auditoryfilterfrom != [] || auditorybimbolimit != 0 || auditorybimboodds != 1.0 || deafencmd != [])
    {
        setup = TRUE;
        llOwnerSay("@recvchat_sec=n,recvemote_sec=n");
    }
    else
    {
        setup = FALSE;
        llOwnerSay("@recvchat_sec=y,recvemote_sec=y");
    }
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
            deaf = FALSE;
            name = "";
            auditoryfilterfrom = [];
            auditoryfilterto = [];
            auditorybimbolimit = 0;
            auditorybimboodds = 1.0;
            auditorybimbocensor = ["_"];
            auditorybimboexcept = [];
            deafenmsg = "";
            undeafenmsg = "";
            deafencmd = [];
            undeafencmd = [];
            deafenexcept = [];
            setup = FALSE;
        }
        else if(startswith(m, "NAME"))
        {
            m = llDeleteSubString(m, 0, llStringLength("NAME"));
            name = m;
        }
        else if(startswith(m, "AUDITORY_FILTER"))
        {
            m = llDeleteSubString(m, 0, llStringLength("AUDITORY_FILTER"));
            list split = llParseString2List(m, ["="], []);
            auditoryfilterfrom += [llToLower(llList2String(split, 0))];
            auditoryfilterto += [llList2String(split, 1)];
        }
        else if(startswith(m, "AUDITORY_BIMBO_LIMIT"))
        {
            m = llDeleteSubString(m, 0, llStringLength("AUDITORY_BIMBO_LIMIT"));
            auditorybimbolimit = (integer)m;
        }
        else if(startswith(m, "AUDITORY_BIMBO_ODDS"))
        {
            m = llDeleteSubString(m, 0, llStringLength("AUDITORY_BIMBO_ODDS"));
            auditorybimboodds = (float)m;
        }
        else if(startswith(m, "AUDITORY_BIMBO_CENSOR"))
        {
            if(auditorybimbocensor == ["_"]) auditorybimbocensor = [];
            m = llDeleteSubString(m, 0, llStringLength("AUDITORY_BIMBO_CENSOR"));
            list split = llParseString2List(m, [","], []);
            integer i = llGetListLength(split)-1;
            for(;i >= 0; --i) auditorybimbocensor += [llList2String(split, i)];
        }
        else if(startswith(m, "AUDITORY_BIMBO_EXCEPT"))
        {
            m = llDeleteSubString(m, 0, llStringLength("AUDITORY_BIMBO_EXCEPT"));
            auditorybimboexcept += [llToLower(m)];
        }
        else if(startswith(m, "DEAFEN_MSG"))
        {
            m = llDeleteSubString(m, 0, llStringLength("DEAFEN_MSG"));
            deafenmsg = m;
        }
        else if(startswith(m, "UNDEAFEN_MSG"))
        {
            m = llDeleteSubString(m, 0, llStringLength("UNDEAFEN_MSG"));
            undeafenmsg = m;
        }
        else if(startswith(m, "DEAFEN_CMD"))
        {
            m = llDeleteSubString(m, 0, llStringLength("DEAFEN_CMD"));
            deafencmd += [llToLower(m)];
        }
        else if(startswith(m, "UNDEAFEN_CMD"))
        {
            m = llDeleteSubString(m, 0, llStringLength("UNDEAFEN_CMD"));
            undeafencmd += [llToLower(m)];
        }
        else if(startswith(m, "DEAFEN_EXCEPT"))
        {
            m = llDeleteSubString(m, 0, llStringLength("DEAFEN_EXCEPT"));
            deafenexcept += [llToLower(m)];
        }
        checkSetup();
    }
}