#include <IT/globals.lsl>
key primary = NULL_KEY;
list owners = [];
integer publicaccess = FALSE;
integer groupaccess = FALSE;

string name = "";
list speechblacklistfrom = [];
list speechblacklistwordsfrom = [];
list speechblacklistto = [];
list speechblacklistwordsto = [];
list speechblacklisttripped = [];
list speechrequiredlist = [];
string speechrequiredlisttripped = "";
list speechfilterfrom = [];
list speechfilterto = [];
list speechfilterpartialfrom = [];
list speechfilterpartialto = [];
integer mute = FALSE;
integer mindless = FALSE;
string mutemsg = "";
string unmutemsg = "";
list mutecensor = [];
list mutecmd = [];
list unmutecmd = [];
string mutetype = "DROP";
integer blindmute = FALSE;
integer vocalbimbolimit = 0;
float vocalbimboodds = 1.0;
integer tempDisable = FALSE;

softReset()
{
    tempDisable = TRUE;
    mute = FALSE;
    mindless = FALSE;
    checkSetup();
}

hardReset()
{
    tempDisable = FALSE;
    name = "";
    speechblacklistfrom = [];
    speechblacklistwordsfrom = [];
    speechblacklistto = [];
    speechblacklistwordsto = [];
    speechblacklisttripped = [];
    speechrequiredlist = [];
    speechrequiredlisttripped = "";
    speechfilterfrom = [];
    speechfilterto = [];
    speechfilterpartialfrom = [];
    speechfilterpartialto = [];
    mute = FALSE;
    mindless = FALSE;
    mutemsg = "";
    unmutemsg = "";
    mutecmd = [];
    unmutecmd = [];
    mutecensor = [];
    blindmute = FALSE;
    vocalbimbolimit = 0;
    vocalbimboodds = 1.0;
    checkSetup();
}

handleHear(key skey, string sender, string message)
{
    integer l1;
    if(mute)
    {
#ifndef PUBLIC_SLAVE
        if(isowner(skey))
        {
#endif
            l1 = llGetListLength(unmutecmd)-1;
            for(;l1 >= 0; --l1)
            {
                if(contains(llToLower(message), llList2String(unmutecmd, l1)))
                {
                    mute = FALSE;
                    llSetObjectName("");
                    ownersay(skey, name + " can speak again.", 0);
                    llSetObjectName(slave_base);
                    llMessageLinked(LINK_SET, S_API_SELF_DESC, unmutemsg, NULL_KEY);
                    llMessageLinked(LINK_SET, S_API_MUTE_SYNC, "0", NULL_KEY);
                }
            }
#ifndef PUBLIC_SLAVE
        }
#endif
    }
    else
    {
#ifndef PUBLIC_SLAVE
        if(isowner(skey))
        {
#endif
            l1 = llGetListLength(mutecmd)-1;
            for(;l1 >= 0; --l1)
            {
                if(contains(llToLower(message), llList2String(mutecmd, l1)))
                {
                    mute = TRUE;
                    llSetObjectName("");
                    ownersay(skey, name + " can no longer speak.", 0);
                    llSetObjectName(slave_base);
                    llMessageLinked(LINK_SET, S_API_SELF_DESC, mutemsg, NULL_KEY);
                    llMessageLinked(LINK_SET, S_API_MUTE_SYNC, "1", NULL_KEY);
                }
            }
#ifndef PUBLIC_SLAVE
        }
#endif
    }
}

handleSay(string message)
{
    if(tempDisable)
    {
        llMessageLinked(LINK_SET, S_API_SAY, message, (key)name);
        return;
    }
    if(startswith(message, "((") == TRUE && endswith(message, "))") == TRUE) return;
    integer emote = FALSE;
    if(startswith(llToLower(message), "/me") || startswith(llToLower(message), "/shout/me") || startswith(llToLower(message), "/shout /me") ||
       startswith(llToLower(message), "/whisper/me") || startswith(llToLower(message), "/whisper /me")) emote = TRUE;
    integer l1;
    integer l2 = llGetListLength(speechfilterpartialfrom);
    string messagecopy;
    string word;
    string oldword;
    string newword;
    integer replaceidx;
    integer quotecnt = 0;

    // In case of a blacklisted word, replace the message and emit the replacement message. Skip the entire rest of the process.
    l1 = llGetListLength(speechblacklistfrom)-1;
    for(;l1 >= 0; --l1)
    {
        if(contains(llToLower(message), llList2String(speechblacklistfrom, l1)))
        {
            message = llList2String(speechblacklisttripped, llList2Integer(speechblacklistto, l1));
            jump blacklisttripped;
        }
    }

    l1 = llGetListLength(speechblacklistwordsfrom)-1;
    list words = llParseStringKeepNulls(llToLower(message), [" ", ",", "\"", ";", ":", ".", "!", "?"], []);
    for(;l1 >= 0; --l1)
    {
        l2 = llGetListLength(words)-1;
        for(;l2 >= 0; --l2)
        {
            if(llList2String(words, l2) == llList2String(speechblacklistwordsfrom, l1))
            {
                message = llList2String(speechblacklisttripped, llList2Integer(speechblacklistwordsto, l1));
                jump blacklisttripped;
            }
        }
    }

    // In case of NO requiredlisted word, replace the message with the replacement message. Rest of the process is skipped.
    if(speechrequiredlist != [])
    {
        if(emote == FALSE || contains(message, "\"") == TRUE)
        {
            l1 = llGetListLength(speechrequiredlist)-1;
            for(;l1 >= 0; --l1)
            {
                if(contains(llToLower(message), llList2String(speechrequiredlist, l1))) jump maycontinue;
            }
            message = speechrequiredlisttripped;
            jump blacklisttripped;
            @maycontinue;
        }
    }

    // URLs should never be filtered, enclose them in [[[ and ]]]. This is checked for later.
    // Partial filters are also applied here.
    messagecopy = message;
    message = "";
    l2 = llGetListLength(speechfilterpartialfrom);
    integer inurl = 0;
    while(llStringLength(messagecopy) > 0)
    {
        if(inurl > 0)
        {
            if(llGetSubString(messagecopy, 0, 0) == " ")
            {
                message += "]]]";
                inurl--;
            }
        }
        else
        {
            if(startswith(messagecopy, "http://") || startswith(messagecopy, "https://") || startswith(messagecopy, "secondlife://"))
            {
                message += "[[[";
                inurl++;
            }
            else if(emote == FALSE || quotecnt % 2 != 0)
            {
                for(l1 = 0; l1 < l2; ++l1)
                {
                    string fromCheck = llList2String(speechfilterpartialfrom, l1);
                    if(startswith(llToLower(messagecopy), fromCheck))
                    {
                        message += llList2String(speechfilterpartialto, l1);
                        messagecopy = llDeleteSubString(messagecopy, 0, llStringLength(fromCheck)-1);
                        jump replacedpartial;
                    }
                }
            }
        }

        message += llGetSubString(messagecopy, 0, 0);
        messagecopy = llDeleteSubString(messagecopy, 0, 0);

        @replacedpartial;
        if(llGetSubString(message, -1, -1) == "\"") quotecnt++;
    }

    // Main filtering loop. Split by word, then word by word:
    //   - If a word starts a URL, skip until end of URL.
    //   - If word is in filter list, replace.
    //   - If word is not in filter list, but is above allowable bimbo limit, garble according to odds.
    list letters = [];
    messagecopy = message;
    message = "";
    inurl = 0;
    quotecnt = 0;
    while(llStringLength(messagecopy) > 0)
    {
        word = llList2String(llParseStringKeepNulls(messagecopy, [" ", ",", "\"", ";", ":", ".", "!", "?"], []), 0);
        oldword = word;

        if(startswith(oldword, "[[["))
        {
            word = llGetSubString(word, 3, -1);
            inurl++;
        }
        if(inurl > 0) jump skipfilter;

        replaceidx = llListFindList(speechfilterfrom, [llToLower(word)]);
        if(replaceidx != -1)
        {
            word = llList2String(speechfilterto, replaceidx);
        }
        else if(vocalbimbolimit > 0 &&
                llStringLength(word) >= vocalbimbolimit &&
                word != "" &&
                llFrand(1.0) >= vocalbimboodds &&
                (emote == FALSE || quotecnt % 2 != 0))
        {
            letters = [];
            l2 = llStringLength(word)-1;
            for(l1 = 1; l1 < l2; ++l1) letters += [llGetSubString(word, l1, l1)];
            word = llGetSubString(word, 0, 0) + llDumpList2String(llListRandomize(letters, 1), "") + llGetSubString(word, -1, -1);
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

    // Logic on *how* to emit text:
    //   - If not muted or a full emote, just say.
    //   - If muted, and type is set to DROP, say only to wearer of device. Do not show message to outside world.
    //   - If muted, and type is set to REPLACE, show original line to wearer, but output a replacement line to outside world.
    //   - If muted, and type is set to CENSOR, show original line to wearer, but output a replacement with every word replaced with random words to outside world.
    @blacklisttripped;
    integer bypass = emote == TRUE && llToLower(llStringTrim(message, STRING_TRIM)) != "/me" && contains(message, "\"") == FALSE;
    if(mute == FALSE || bypass == TRUE)
    {
        llMessageLinked(LINK_SET, S_API_SAY, message, (key)name);
    }
    else
    {
        if(mutetype == "DROP" || mutecensor == [])
        {
            llMessageLinked(LINK_SET, S_API_SELF_SAY, message, (key)name);
        }
        else if(mutetype == "REPLACE")
        {
            if(blindmute)
            {
                llMessageLinked(LINK_SET, S_API_SELF_SAY, message, (key)name);
                llMessageLinked(LINK_SET, S_API_ONLY_OTHERS_SAY, llList2String(mutecensor, llFloor(llFrand(llGetListLength(mutecensor)))), (key)name);
            }
            else
            {
                llMessageLinked(LINK_SET, S_API_SAY, llList2String(mutecensor, llFloor(llFrand(llGetListLength(mutecensor)))), (key)name);
            }
        }
        else
        {
            if(blindmute) llMessageLinked(LINK_SET, S_API_SELF_SAY, message, (key)name);
            messagecopy = message;
            message = "";
            quotecnt = 0;
            while(llStringLength(messagecopy) > 0)
            {
                word = llList2String(llParseStringKeepNulls(messagecopy, [" ", ",", "\"", ";", ":", ".", "!", "?"], []), 0);
                oldword = word;

                if((emote == FALSE || quotecnt % 2 != 0) && word != "")
                {
                    newword = llList2String(mutecensor, llFloor(llFrand(llGetListLength(mutecensor))));
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

                message += word;
                if(llStringLength(messagecopy) != llStringLength(oldword))
                {
                    message += llGetSubString(messagecopy, llStringLength(oldword), llStringLength(oldword));
                    if(llGetSubString(message, -1, -1) == "\"") quotecnt++;
                }
                messagecopy = llDeleteSubString(messagecopy, 0, llStringLength(oldword));
            }
            if(blindmute) llMessageLinked(LINK_SET, S_API_ONLY_OTHERS_SAY, message, (key)name);
            else          llMessageLinked(LINK_SET, S_API_SAY, message, (key)name);
        }
    }
}

checkSetup()
{
    if(name != "" || mute || mindless) llOwnerSay("@redirchat:" + (string)VOICE_CHANNEL + "=add,rediremote:" + (string)VOICE_CHANNEL + "=add");
    else                               llOwnerSay("@redirchat:" + (string)VOICE_CHANNEL + "=rem,rediremote:" + (string)VOICE_CHANNEL + "=rem");
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
        else if(num == S_API_MUTE_TOGGLE)
        {
            if(mute)
            {
                mute = FALSE;
                llSetObjectName("");
                if(name != "") ownersay(id, name + " can speak again.", 0);
                else           ownersay(id, "secondlife:///app/agent/" + (string)llGetOwner() + "/about can speak again.", 0);
                llSetObjectName(slave_base);
                llMessageLinked(LINK_SET, S_API_SELF_DESC, unmutemsg, NULL_KEY);
                llMessageLinked(LINK_SET, S_API_MUTE_SYNC, "0", NULL_KEY);
                checkSetup();
            }
            else
            {
                mute = TRUE;
                llSetObjectName("");
                if(name != "") ownersay(id, name + " can no longer speak.", 0);
                else           ownersay(id, "secondlife:///app/agent/" + (string)llGetOwner() + "/about can no longer speak.", 0);
                llSetObjectName(slave_base);
                llMessageLinked(LINK_SET, S_API_SELF_DESC, mutemsg, NULL_KEY);
                llMessageLinked(LINK_SET, S_API_MUTE_SYNC, "1", NULL_KEY);
                checkSetup();
            }
        }
        else if(num == S_API_MIND_SYNC)
        {
            mindless = (integer)str;
            checkSetup();
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
        setupVoiceChannel();
        llListen(VOICE_CHANNEL, "", llGetOwner(), "");
    }

    listen(integer c, string n, key k, string m)
    {
        if(c == VOICE_CHANNEL)
        {
            if(mindless) return;
            handleSay(m);
            return;
        }
        else if(c == 0)
        {
            handleHear(k, n, m);
            return;
        }
#ifndef PUBLIC_SLAVE
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
            checkSetup();
        }
        else if(startswith(m, "SPEECH_BLACKLIST_ENTRY"))
        {
            m = llDeleteSubString(m, 0, llStringLength("SPEECH_BLACKLIST_ENTRY"));
            list split = llParseString2List(m, ["="], []);
            string sequence = llToLower(llList2String(split, 0));
            if(startswith(sequence, "\\"))
            {
                speechblacklistwordsfrom += [llDeleteSubString(sequence, 0, 0)];
                speechblacklistwordsto += [(integer)llList2String(split, 1)];
            }
            else
            {
                speechblacklistfrom += [sequence];
                speechblacklistto += [(integer)llList2String(split, 1)];
            }
        }
        else if(startswith(m, "SPEECH_BLACKLIST_TRIPPED"))
        {
            m = llDeleteSubString(m, 0, llStringLength("SPEECH_BLACKLIST_TRIPPED"));
            speechblacklisttripped += [m];
        }
        else if(startswith(m, "SPEECH_REQUIREDLIST_ENTRY"))
        {
            m = llDeleteSubString(m, 0, llStringLength("SPEECH_REQUIREDLIST_ENTRY"));
            speechrequiredlist += [llToLower(m)];
        }
        else if(startswith(m, "SPEECH_REQUIREDLIST_TRIPPED"))
        {
            m = llDeleteSubString(m, 0, llStringLength("SPEECH_REQUIREDLIST_TRIPPED"));
            speechrequiredlisttripped = m;
        }
        else if(startswith(m, "SPEECH_FILTER_PARTIAL"))
        {
            m = llDeleteSubString(m, 0, llStringLength("SPEECH_FILTER_PARTIAL"));
            list split = llParseStringKeepNulls(m, ["="], []);
            speechfilterpartialfrom += [llToLower(llList2String(split, 0))];
            speechfilterpartialto += [llList2String(split, 1)];
        }
        else if(startswith(m, "SPEECH_FILTER"))
        {
            m = llDeleteSubString(m, 0, llStringLength("SPEECH_FILTER"));
            list split = llParseStringKeepNulls(m, ["="], []);
            speechfilterfrom += [llToLower(llList2String(split, 0))];
            speechfilterto += [llList2String(split, 1)];
        }
        else if(startswith(m, "MUTE_MSG"))
        {
            m = llDeleteSubString(m, 0, llStringLength("MUTE_MSG"));
            mutemsg = m;
        }
        else if(startswith(m, "UNMUTE_MSG"))
        {
            m = llDeleteSubString(m, 0, llStringLength("UNMUTE_MSG"));
            unmutemsg = m;
        }
        else if(startswith(m, "MUTE_CMD"))
        {
            m = llDeleteSubString(m, 0, llStringLength("MUTE_CMD"));
            mutecmd += [llToLower(m)];
        }
        else if(startswith(m, "UNMUTE_CMD"))
        {
            m = llDeleteSubString(m, 0, llStringLength("UNMUTE_CMD"));
            unmutecmd += [llToLower(m)];
        }
        else if(startswith(m, "MUTE_CENSOR"))
        {
            m = llDeleteSubString(m, 0, llStringLength("MUTE_CENSOR"));
            mutecensor += [llToLower(m)];
        }
        else if(startswith(m, "MUTE_TYPE"))
        {
            m = llToUpper(llDeleteSubString(m, 0, llStringLength("MUTE_TYPE")));
            if(m == "DROP" || m == "REPLACE" || m == "CENSOR") mutetype = m;
        }
        else if(startswith(m, "BLIND_MUTE"))
        {
            m = llDeleteSubString(m, 0, llStringLength("BLIND_MUTE"));
            if(m != "0") blindmute = TRUE;
            else         blindmute = FALSE;
        }
        else if(startswith(m, "VOCAL_BIMBO_LIMIT"))
        {
            m = llDeleteSubString(m, 0, llStringLength("VOCAL_BIMBO_LIMIT"));
            vocalbimbolimit = (integer)m;
        }
        else if(startswith(m, "VOCAL_BIMBO_ODDS"))
        {
            m = llDeleteSubString(m, 0, llStringLength("VOCAL_BIMBO_ODDS"));
            vocalbimboodds = (float)m;
        }
        else if(m == "END")
        {
            llSetObjectName("");
            ownersay(k, "[vocal]: " + (string)(llGetFreeMemory() / 1024.0) + "kb free.", HUD_SPEAK_CHANNEL);
        }
    }
}
