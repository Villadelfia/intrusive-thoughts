#include <IT/globals.lsl>
key primary = NULL_KEY;
list owners = [];
integer publicaccess = FALSE;
integer groupaccess = FALSE;

integer deaf = FALSE;
string name = "";
list auditoryfilterfrom = [];
list auditoryfilterto = [];
integer auditorybimbolimit = 0;
float auditorybimboodds = 1.0;
list auditorybimbocensor = ["_"];
list auditorybimboreplace = ["blah"];
list auditorybimboexcept = [];
list auditorybimbooverride = [];
string deafenmsg = "";
string undeafenmsg = "";
list deafencmd = [];
list undeafencmd = [];
list deafenexcept = [];
integer maximumpostsperhour = 0;
list hearinghistory = [];
integer setup = FALSE;
integer tempDisable = FALSE;

softReset()
{
    deaf = FALSE;
    tempDisable = TRUE;
    checkSetup();
}

hardReset()
{
    tempDisable = FALSE;
    deaf = FALSE;
    name = "";
    auditoryfilterfrom = [];
    auditoryfilterto = [];
    auditorybimbolimit = 0;
    auditorybimboodds = 1.0;
    auditorybimbocensor = ["_"];
    auditorybimboexcept = [];
    auditorybimbooverride = [];
    auditorybimboreplace = ["blah"];
    deafenmsg = "";
    undeafenmsg = "";
    deafencmd = [];
    undeafencmd = [];
    deafenexcept = [];
    maximumpostsperhour = 0;
    hearinghistory = [];
    setup = FALSE;
    checkSetup();
}

evaluateMessagesPerHour()
{
    integer now = llGetUnixTime();
    integer t = 0;
    integer l = llGetListLength(hearinghistory);
    while(~--l)
    {
        t = llList2Integer(hearinghistory, l);
        if(t < (now - 3600)) hearinghistory = llDeleteSubList(hearinghistory, l, l);
    }
}

handleHear(key skey, string sender, string message)
{
    if(tempDisable == TRUE && setup == TRUE)
    {
        llMessageLinked(LINK_SET, S_API_SELF_SAY, message, "");
        return;
    }

    if(!setup) return;
    if(startswith(message, "((") == TRUE && endswith(message, "))") == TRUE) return;
    integer emote = FALSE;
    if(startswith(llToLower(message), "/me")) emote = TRUE;
    while(startswith(message, "@")) message = llDeleteSubString(message, 0, 0);
    integer l1;
    string messagecopy;
    string word;
    integer replaceidx;
    string oldword;
    string prefix;
    string nameSay;
    string newword;
    integer quotecnt = 0;

    if(deaf)
    {
        // Handle undeafening by owner.
#ifndef PUBLIC_SLAVE
        if(isowner(skey))
        {
#endif
            l1 = llGetListLength(undeafencmd);
            while(~--l1)
            {
                if(contains(llToLower(message), llList2String(undeafencmd, l1)))
                {
                    llSetObjectName("");
                    deaf = FALSE;
                    ownersay(skey, name + " can hear the conversation again.", 0);
                    llSetObjectName(slave_base);
                    llMessageLinked(LINK_SET, S_API_SELF_DESC, undeafenmsg, NULL_KEY);
                    jump cont1;
                }
            }
#ifndef PUBLIC_SLAVE
        }
#endif

        // Handle deafen exceptions.
        l1 = llGetListLength(deafenexcept);
        while(~--l1)
        {
            if(contains(llToLower(message), llList2String(deafenexcept, l1)))
            {
                llSetObjectName("");
                ownersay(skey, name + " heard that message because of exceptions.", 0);
                llSetObjectName(slave_base);
                llMessageLinked(LINK_SET, S_API_SELF_DESC, undeafenmsg, NULL_KEY);
                jump cont1;
            }
        }

        if(startswith(message, "/me") == TRUE && contains(message, "\"") == FALSE) jump cont1;
        return;
    }
    @cont1;

    if(skey != llGetOwnerKey(skey))
    {
        string group = "";
        if((string)llGetObjectDetails(skey, [OBJECT_OWNER]) == NULL_KEY)
        {
            group = "&groupowned=true";
        }
        vector pos = llList2Vector(llGetObjectDetails(skey, [OBJECT_POS]), 0);
        string slurl = llEscapeURL(llGetRegionName()) + "/"+ (string)((integer)pos.x) + "/"+ (string)((integer)pos.y) + "/"+ (string)(llCeil(pos.z));
        prefix = "[secondlife:///app/objectim/" + (string)skey +
                 "?name=" + llEscapeURL(sender) +
                 "&owner=" + (string)llGetOwnerKey(skey) +
                 group +
                 "&slurl=" + llEscapeURL(slurl) + " " + sender + "]";
    }
    else
    {
        prefix = "secondlife:///app/agent/" + (string)skey + "/about";
    }

    if(startswith(message, "/me"))
    {
        prefix = "/me " + prefix;
        message = llDeleteSubString(message, 0, 2);
    }
    else
    {
        prefix += ": ";
    }

    // Handle deafening by owner.
#ifndef PUBLIC_SLAVE
    if(isowner(skey) && deaf == FALSE)
    {
#endif
        l1 = llGetListLength(deafencmd);
        while(~--l1)
        {
            if(contains(llToLower(message), llList2String(deafencmd, l1)))
            {
                deaf = TRUE;
                llSetObjectName("");
                ownersay(skey, name + " can no longer hear the conversation.", 0);
                llSetObjectName(slave_base);
                llMessageLinked(LINK_SET, S_API_SELF_DESC, deafenmsg, NULL_KEY);
                jump cont2;
            }
        }
#ifndef PUBLIC_SLAVE
    }
#endif
    @cont2;

    // Handle URLS.
    messagecopy = message;
    message = "";
    integer inurl = FALSE;
    while(llStringLength(messagecopy) > 0)
    {
        if(inurl)
        {
            if(llGetSubString(messagecopy, 0, 0) == " ")
            {
                message += "]]]";
                inurl = FALSE;
            }
        }
        else
        {
            if(startswith(messagecopy, "http://") || startswith(messagecopy, "https://") || startswith(messagecopy, "secondlife://"))
            {
                message += "[[[";
                inurl = TRUE;
            }
        }

        message += llGetSubString(messagecopy, 0, 0);
        messagecopy = llDeleteSubString(messagecopy, 0, 0);
    }

    // Handle replacement.
    messagecopy = message;
    message = "";
    inurl = 0;

    integer tryBimbofy = TRUE;
    l1 = llGetListLength(auditorybimbooverride);
    while(~--l1)
    {
        if(contains(llToLower(message), llList2String(auditorybimbooverride, l1)))
        {
            tryBimbofy = FALSE;
            jump goOn;
        }
    }
    @goOn;
    while(llStringLength(messagecopy) > 0)
    {
        word = llList2String(llParseStringKeepNulls(messagecopy, [" ", ",", "\"", ";", ":", ".", "?", "!"], []), 0);
        oldword = word;

        if(startswith(oldword, "[[["))
        {
            word = llGetSubString(word, 3, -1);
            inurl++;
        }
        if(inurl > 0) jump skipfilter;

        // First we check if it gets replaced.
        replaceidx = llListFindList(auditoryfilterfrom, [llToLower(word)]);
        if(replaceidx != -1)
        {
            word = llList2String(auditoryfilterto, replaceidx);
        }

        // Then we bimbofy if the word is unchanged, too long and not in the exception list.
        else if(tryBimbofy &&
                auditorybimbolimit > 0 &&
                llStringLength(word) >= auditorybimbolimit &&
                llListFindList(auditorybimboexcept, [llToLower(word)]) == -1 &&
                (emote == FALSE || quotecnt % 2 != 0))
        {
            if(auditorybimboodds > 0.0)
            {
                newword = "";
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
            else
            {
                if(word != "")
                {
                    if(llFrand(1.0) < 0.01) newword = llList2String(auditorybimboexcept, llFloor(llFrand(llGetListLength(auditorybimboexcept))));
                    else                    newword = llList2String(auditorybimboreplace, llFloor(llFrand(llGetListLength(auditorybimboreplace))));
                    if(llToUpper(word) == word)
                    {
                        word = llToUpper(newword);
                    }
                    else if(llToUpper(llGetSubString(word, 0, 0)) == llGetSubString(word, 0, 0))
                    {
                        word = llToUpper(llGetSubString(newword, 0, 0)) + llGetSubString(newword, 1, -1);
                    }
                    else
                    {
                        word = newword;
                    }
                }
            }
        }

        @skipfilter;
        if(endswith(oldword, "]]]") && inurl > 0)
        {
            word = llGetSubString(word, 0, -4);
            inurl--;
        }

        message += word;
        if(llStringLength(messagecopy) != llStringLength(oldword))
        {
            message += llGetSubString(messagecopy, llStringLength(oldword), llStringLength(oldword));
            if(llGetSubString(message, -1, -1) == "\"") quotecnt++;
        }
        messagecopy = llDeleteSubString(messagecopy, 0, llStringLength(oldword));
    }

    // Check messages per hour.
    if(maximumpostsperhour > 0)
    {
        evaluateMessagesPerHour();
        if(llGetListLength(hearinghistory) >= maximumpostsperhour)
        {
            return;
        }
        else
        {
            hearinghistory += [llGetUnixTime()];
        }
    }

    message = prefix + message;
    llMessageLinked(LINK_SET, S_API_SELF_SAY, message, "");
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

    if(deaf)
    {
        setup = TRUE;
        llOwnerSay("@recvchat_sec=n,recvemote_sec=n");
    }
}

default
{
    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == S_API_RLV_CHECK)
        {
            tempDisable = FALSE;
            checkSetup();
        }
        else if(num == S_API_MANTRA_DONE)
        {
            if(tempDisable) return;
            checkSetup();
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
        else if(num == S_API_DEAF_TOGGLE)
        {
            if(deaf)
            {
                deaf = FALSE;
                llSetObjectName("");
                if(name != "") ownersay(id, name + " can hear the conversation again.", 0);
                else           ownersay(id, "secondlife:///app/agent/" + (string)llGetOwner() + "/about can hear the conversation again.", 0);
                llSetObjectName(slave_base);
                llMessageLinked(LINK_SET, S_API_SELF_DESC, undeafenmsg, NULL_KEY);
                checkSetup();
            }
            else
            {
                deaf = TRUE;
                llSetObjectName("");
                if(name != "") ownersay(id, name + " can no longer hear the conversation.", 0);
                else           ownersay(id, "secondlife:///app/agent/" + (string)llGetOwner() + "/about can no longer hear the conversation.", 0);
                llSetObjectName(slave_base);
                llMessageLinked(LINK_SET, S_API_SELF_DESC, deafenmsg, NULL_KEY);
                checkSetup();
            }
        }
        else if(num == S_API_EMERGENCY)
        {
            softReset();
        }
    }

    state_entry()
    {
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
        llListen(0, "", NULL_KEY, "");
    }

    listen(integer c, string n, key k, string m)
    {
        if(c == 0)
        {
            handleHear(k, n, m);
            return;
        }
#ifdef PUBLIC_SLAVE
        if(!isowner(k)) return;
#endif
        if(m == "RESET")
        {
            hardReset();
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
            checkSetup();
        }
        else if(startswith(m, "AUDITORY_BIMBO_LIMIT"))
        {
            m = llDeleteSubString(m, 0, llStringLength("AUDITORY_BIMBO_LIMIT"));
            auditorybimbolimit = (integer)m;
            checkSetup();
        }
        else if(startswith(m, "AUDITORY_BIMBO_ODDS"))
        {
            m = llDeleteSubString(m, 0, llStringLength("AUDITORY_BIMBO_ODDS"));
            auditorybimboodds = (float)m;
            checkSetup();
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
        else if(startswith(m, "AUDITORY_BIMBO_OVERRIDE"))
        {
            m = llDeleteSubString(m, 0, llStringLength("AUDITORY_BIMBO_OVERRIDE"));
            auditorybimbooverride += [llToLower(m)];
        }
        else if(startswith(m, "AUDITORY_BIMBO_REPLACE"))
        {
            if(llList2String(auditorybimboreplace, 0) == "blah" && llGetListLength(auditorybimboreplace) == 1) auditorybimboreplace = [];
            m = llDeleteSubString(m, 0, llStringLength("AUDITORY_BIMBO_REPLACE"));
            auditorybimboreplace += [m];
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
            checkSetup();
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
        else if(startswith(m, "MAXIMUM_HEARD_POSTS_PER_HOUR"))
        {
            m = llDeleteSubString(m, 0, llStringLength("MAXIMUM_HEARD_POSTS_PER_HOUR"));
            maximumpostsperhour = (integer)m;
        }
        else if(m == "END")
        {
            llSetObjectName("");
            ownersay(k, "[auditory]: " + (string)(llGetFreeMemory() / 1024.0) + "kb free.", HUD_SPEAK_CHANNEL);
            llSetObjectName(slave_base);
        }
    }
}
