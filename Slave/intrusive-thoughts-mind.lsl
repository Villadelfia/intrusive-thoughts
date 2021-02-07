#include <IT/globals.lsl>
key primary = NULL_KEY;
list owners = [];
integer publicaccess = FALSE;
integer groupaccess = FALSE;

string name = "";
integer mindless = FALSE;
integer mute = FALSE;
string mindonmsg = "";
string mindoffmsg = "";
list mindoffcmd = [];
list mindoncmd = [];
list mindfrom = [];
list mindto = [];
integer blindmute = FALSE;

handleHear(key skey, string sender, string message)
{
    integer l1;
    if(mindless)
    {
        if(isowner(skey))
        {
            l1 = llGetListLength(mindoncmd)-1;
            for(;l1 >= 0; --l1)
            {
                if(contains(llToLower(message), llList2String(mindoncmd, l1)))
                {
                    mindless = FALSE;
                    llMessageLinked(LINK_SET, S_API_SELF_DESC, mindonmsg, NULL_KEY);
                    llMessageLinked(LINK_SET, S_API_MIND_SYNC, "0", NULL_KEY);
                    ownersay(skey, name + " is no longer mindless.");
                }
            }
        }
    }
    else
    {
        if(isowner(skey))
        {
            l1 = llGetListLength(mindoffcmd)-1;
            for(;l1 >= 0; --l1)
            {
                if(contains(llToLower(message), llList2String(mindoffcmd, l1)))
                {
                    mindless = TRUE;
                    llMessageLinked(LINK_SET, S_API_SELF_DESC, mindoffmsg, NULL_KEY);
                    llMessageLinked(LINK_SET, S_API_MIND_SYNC, "1", NULL_KEY);
                    ownersay(skey, name + " has been rendered mindless.");
                }
            }
        }
    }
}

handleSay(string message)
{
    if(startswith(message, "((") == TRUE && endswith(message, "))") == TRUE) return;
    message = llToLower(message);
    integer l = llGetListLength(mindfrom);
    while(~--l)
    {
        if(message == llList2String(mindfrom, l))
        {
            message = llList2String(mindto, l);
            if(blindmute)
            {
                llMessageLinked(LINK_SET, S_API_SELF_SAY, message, (key)name);
                llMessageLinked(LINK_SET, S_API_ONLY_OTHERS_SAY, message, (key)name);
            }
            else llMessageLinked(LINK_SET, S_API_SAY, message, (key)name);
            return;
        }
    }
    llMessageLinked(LINK_SET, S_API_SELF_DESC, "You are mindless, you may only express yourself using the following phrases: " + llDumpList2String(mindfrom, ", "), NULL_KEY);
}

default
{
    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == S_API_OWNERS)
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
        if(num == S_API_MIND_TOGGLE)
        {
            if(mindless)
            {
                mindless = FALSE;
                llMessageLinked(LINK_SET, S_API_SELF_DESC, mindonmsg, NULL_KEY);
                if(name != "") ownersay(id, name + " is no longer mindless.");
                else           ownersay(id, "secondlife:///app/agent/" + (string)llGetOwner() + "/about is no longer mindless.");
                llMessageLinked(LINK_SET, S_API_MIND_SYNC, "0", NULL_KEY);
            }
            else
            {
                mindless = TRUE;
                llMessageLinked(LINK_SET, S_API_SELF_DESC, mindoffmsg, NULL_KEY);
                if(name != "") ownersay(id, name + " has been rendered mindless.");
                else           ownersay(id, "secondlife:///app/agent/" + (string)llGetOwner() + "/about has been rendered mindless.");
                llMessageLinked(LINK_SET, S_API_MIND_SYNC, "1", NULL_KEY);
            }
        }
        else if(num == S_API_MUTE_SYNC)
        {
            mute = (integer)str;
        }
    }

    state_entry()
    {
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
        llListen(VOICE_CHANNEL, "", llGetOwner(), "");
        llListen(0, "", NULL_KEY, "");
    }

    listen(integer c, string n, key k, string m)
    {
        if(c == VOICE_CHANNEL)
        {
            if(mindless && !mute) handleSay(m);
            return;
        }
        if(c == 0) 
        {
            handleHear(k, n, m);
            return;
        }
        if(!isowner(k)) return;
        if(m == "RESET")
        {
            mindless = FALSE;
            mute = FALSE;
            mindonmsg = "";
            mindoffmsg = "";
            mindoffcmd = [];
            mindoncmd = [];
            mindfrom = [];
            mindto = [];
            name = "";
            blindmute = FALSE;
        }
        else if(startswith(m, "NAME"))
        {
            m = llDeleteSubString(m, 0, llStringLength("NAME"));
            name = m;
        }
        else if(startswith(m, "MIND_OFF_MSG"))
        {
            m = llDeleteSubString(m, 0, llStringLength("MIND_OFF_MSG"));
            mindoffmsg = m;
        }
        else if(startswith(m, "MIND_ON_MSG"))
        {
            m = llDeleteSubString(m, 0, llStringLength("MIND_ON_MSG"));
            mindonmsg = m;
        }
        else if(startswith(m, "MIND_OFF_CMD"))
        {
            m = llDeleteSubString(m, 0, llStringLength("MIND_OFF_CMD"));
            mindoffcmd += [llToLower(m)];
        }
        else if(startswith(m, "MIND_ON_CMD"))
        {
            m = llDeleteSubString(m, 0, llStringLength("MIND_ON_CMD"));
            mindoncmd += [llToLower(m)];
        }
        else if(startswith(m, "MIND_ON_CMD"))
        {
            m = llDeleteSubString(m, 0, llStringLength("MIND_ON_CMD"));
            mindoncmd += [llToLower(m)];
        }
        else if(startswith(m, "MINDLESS_PHRASES"))
        {
            m = llDeleteSubString(m, 0, llStringLength("MINDLESS_PHRASES"));
            list split = llParseString2List(m, ["="], []);
            mindfrom += [llToLower(llList2String(split, 0))];
            mindto += [llList2String(split, 1)];
        }
        else if(startswith(m, "BLIND_MUTE"))
        {
            m = llDeleteSubString(m, 0, llStringLength("BLIND_MUTE"));
            if(m != "0") blindmute = TRUE;
            else         blindmute = FALSE;
        }
        else if(m == "END")
        {
            ownersay(k, "[mind]: " + (string)(llGetFreeMemory() / 1024.0) + "kb free.");
        }
    }
}