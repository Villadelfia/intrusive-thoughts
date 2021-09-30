#include <IT/globals.lsl>
key primary = NULL_KEY;
list owners = [];
integer publicaccess = FALSE;
integer groupaccess = FALSE;

string name = "";
integer blind = FALSE;
integer gotreply = TRUE;
string unblindmsg = "";
string blindmsg = "";
list blindcmd = [];
list unblindcmd = [];
integer rlvtries = 0;
float currentVision = 4.0;

hardReset(string n)
{
    blind = FALSE;
    unblindmsg = "";
    blindmsg = "";
    blindcmd = [];
    unblindcmd = [];
    name = n;
    checkSetup(0, 0);
}

handleHear(key skey, string sender, string message)
{
    integer l1;
    if(blind)
    {
        if(isowner(skey))
        {
            l1 = llGetListLength(unblindcmd)-1;
            for(;l1 >= 0; --l1)
            {
                if(contains(llToLower(message), llList2String(unblindcmd, l1)))
                {
                    blind = FALSE;
                    llMessageLinked(LINK_SET, S_API_SELF_DESC, unblindmsg, NULL_KEY);
                    ownersay(skey, name + " can see again.");
                    checkSetup(0, 0);
                }
            }
        }
    }
    else
    {
        if(isowner(skey))
        {
            l1 = llGetListLength(blindcmd)-1;
            for(;l1 >= 0; --l1)
            {
                if(contains(llToLower(message), llList2String(blindcmd, l1)))
                {
                    blind = TRUE;
                    llMessageLinked(LINK_SET, S_API_SELF_DESC, blindmsg, NULL_KEY);
                    ownersay(skey, name + " can no longer see.");
                    checkSetup(128, currentVision);
                }
            }
        }
    }
}

checkSetup(float from, float to)
{
    if(blind) 
    {
        llOwnerSay("@clear=setsphere,setsphere=n,"+
                   "setsphere_distmin:0=force,setsphere_valuemin:0=force,setsphere_distmax:" + (string)from + "=force,"+
                   "setsphere_tween:5=force,setsphere_distmax:" + (string)to + "=force,setsphere_tween=force");
    }
    else      llOwnerSay("@clear=setsphere");
}

default
{
    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == S_API_STARTED)
        {
            rlvtries = 0;
            gotreply = FALSE;
            llOwnerSay("@version=" + (string)RLV_CHECK_CHANNEL);
            llSetTimerEvent(10.0);
        }
        else if(num == S_API_RLV_CHECK)
        {
            checkSetup(128, currentVision);
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
        else if(num == S_API_BLIND_TOGGLE)
        {
            if(blind)
            {
                blind = FALSE;
                llMessageLinked(LINK_SET, S_API_SELF_DESC, unblindmsg, NULL_KEY);
                if(name != "") ownersay(id, name + " can see again.");
                else           ownersay(id, "secondlife:///app/agent/" + (string)llGetOwner() + "/about can see again.");
                checkSetup(0, 0);
            }
            else
            {
                blind = TRUE;
                llMessageLinked(LINK_SET, S_API_SELF_DESC, blindmsg, NULL_KEY);
                if(name != "") ownersay(id, name + " can no longer see.");
                else           ownersay(id, "secondlife:///app/agent/" + (string)llGetOwner() + "/about can no longer see.");
                checkSetup(128, currentVision);
            }
        }
        else if(num == S_API_BLIND_LEVEL)
        {
            checkSetup(currentVision, (float)str);
            currentVision = (float)str;
            if(name != "") ownersay(id, name + " has had their vision distance adjusted to " + formatfloat(currentVision, 2) + " meters.");
            else           ownersay(id, "secondlife:///app/agent/" + (string)llGetOwner() + "/about has had their vision distance adjusted to " + formatfloat(currentVision, 2) + " meters.");
        }
        else if(num == S_API_EMERGENCY)
        {
            hardReset(name);
        }
    }

    attach(key id)
    {
        llSetTimerEvent(0.0);
    }

    state_entry()
    {
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
        llListen(0, "", NULL_KEY, "");
        llListen(RLV_CHECK_CHANNEL, "", llGetOwner(), "");
    }

    timer()
    {
        if(!gotreply)
        {
            if(rlvtries < 6)
            {
                rlvtries++;
                llOwnerSay("@version=" + (string)RLV_CHECK_CHANNEL);
            }
            else
            {
                llSetTimerEvent(0.0);
                string oldn = llGetObjectName();
                llSetObjectName("");
                if(llGetAgentSize(primary) != ZERO_VECTOR) ownersay(primary, "The " + VERSION_S + " worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about does not have RLV enabled.");
                else                                       llInstantMessage(primary, "The " + VERSION_S + " worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about does not have RLV enabled.");
                llSetObjectName(oldn);
                llOwnerSay("Hey! Your RLV is (probably) turned off and I won't work properly until you turn it on and relog. If it is on, you're just experiencing some lag and you shouldn't worry about it.");
                llMessageLinked(LINK_THIS, S_API_RLV_CHECK, "", "");
            }
        }
        else
        {
            llSetTimerEvent(0.0);
        }
    }

    listen(integer c, string n, key k, string m)
    {
        if(c == RLV_CHECK_CHANNEL && gotreply == FALSE)
        {
            string prefix = llGetSubString(llGetUsername(llGetOwner()), 0, 1);
            llOwnerSay("Intrusive thoughts is good to go! Type /1" + prefix + " or click [secondlife:///app/chat/1/" + prefix + " here] to see your available actions.\nNote that, if present, you can type ((RED)) to clear the RLV relay, or ((FORCERED)) to clear and detach it.");
            gotreply = TRUE;
            rlvtries = 0;
            llSetTimerEvent(0.0);
            llMessageLinked(LINK_THIS, S_API_RLV_CHECK, "", "");
        }
        if(c == 0) 
        {
            handleHear(k, n, m);
            return;
        }
        if(!isowner(k)) return;
        if(m == "RESET")
        {
            hardReset("");
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
            ownersay(k, "[vision]: " + (string)(llGetFreeMemory() / 1024.0) + "kb free.");
        }
    }
}