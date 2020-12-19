#include <IT/globals.lsl>
key owner = NULL_KEY;
integer deaf = FALSE;
string name = "";
list auditoryfilterfrom = [];
list auditoryfilterto = [];
integer auditorybimbolimit = 0;
float auditorybimboodds = 1.0;
list auditorybimbocensor = ["_"];
list auditorybimboreplace = ["blah"];
list auditorybimboexcept = [];
string deafenmsg = "";
string undeafenmsg = "";
list deafencmd = [];
list undeafencmd = [];
list deafenexcept = [];
integer setup = FALSE;

handleHear(key skey, string sender, string message)
{
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
        if(skey == owner || llGetOwnerKey(skey) == owner)
        {
            l1 = llGetListLength(undeafencmd)-1;
            for(;l1 >= 0; --l1)
            {
                if(contains(llToLower(message), llList2String(undeafencmd, l1)))
                {
                    deaf = FALSE;
                    llMessageLinked(LINK_SET, API_SELF_DESC, undeafenmsg, NULL_KEY);
                    llRegionSayTo(owner, HUD_SPEAK_CHANNEL, name + " can hear the conversation again.");
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
                llRegionSayTo(owner, HUD_SPEAK_CHANNEL, name + " heard that message because of exceptions.");
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
    if((skey == owner || llGetOwnerKey(skey) == owner) && deaf == FALSE)
    {
        l1 = llGetListLength(deafencmd)-1;
        for(;l1 >= 0; --l1)
        {
            if(contains(llToLower(message), llList2String(deafencmd, l1)))
            {
                deaf = TRUE;
                llRegionSayTo(owner, HUD_SPEAK_CHANNEL, name + " can no longer hear the conversation.");
                jump cont2;
            }
        }
    }
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
        else if(auditorybimbolimit > 0 && 
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

    message = prefix + message;
    llMessageLinked(LINK_SET, API_SELF_SAY, message, "");
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

    if(deaf)
    {
        llOwnerSay("@recvchat_sec=n,recvemote_sec=n");
    }
}

default
{
    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == API_RESET && id == llGetOwner()) llResetScript();
        if(num == API_DEAF_TOGGLE)
        {
            if(deaf)
            {
                deaf = FALSE;
                llMessageLinked(LINK_SET, API_SELF_DESC, undeafenmsg, NULL_KEY);
                if(name != "") llRegionSayTo(owner, HUD_SPEAK_CHANNEL, name + " can hear the conversation again.");
                else           llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "secondlife:///app/agent/" + (string)llGetOwner() + "/about can hear the conversation again.");
                checkSetup();
            }
            else
            {
                deaf = TRUE;
                llMessageLinked(LINK_SET, API_SELF_DESC, deafenmsg, NULL_KEY);
                if(name != "") llRegionSayTo(owner, HUD_SPEAK_CHANNEL, name + " can no longer hear the conversation.");
                else           llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "secondlife:///app/agent/" + (string)llGetOwner() + "/about can no longer hear the conversation.");
                checkSetup();
            }
        }
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
            auditorybimboreplace = ["blah"];
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
        else if(m == "END")
        {
            llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "[" + llGetScriptName() + "]: " + (string)(llGetFreeMemory() / 1024.0) + "kb free.");
        }
        checkSetup();
    }
}