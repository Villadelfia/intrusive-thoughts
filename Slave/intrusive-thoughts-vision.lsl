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

softReset()
{
    blind = FALSE;
    checkSetup(0, 0);
}

hardReset()
{
    blind = FALSE;
    unblindmsg = "";
    blindmsg = "";
    blindcmd = [];
    unblindcmd = [];
    name = "";
    checkSetup(0, 0);
}

handleHear(key skey, string sender, string message)
{
    integer l1;
    if(blind)
    {
#ifndef PUBLIC_SLAVE
        if(isowner(skey))
        {
#endif
            l1 = llGetListLength(unblindcmd)-1;
            for(;l1 >= 0; --l1)
            {
                if(contains(llToLower(message), llList2String(unblindcmd, l1)))
                {
                    blind = FALSE;
                    llSetObjectName("");
                    ownersay(skey, name + " can see again.", 0);
                    llSetObjectName(slave_base);
                    llMessageLinked(LINK_SET, S_API_SELF_DESC, unblindmsg, NULL_KEY);
                    checkSetup(0, 0);
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
            l1 = llGetListLength(blindcmd)-1;
            for(;l1 >= 0; --l1)
            {
                if(contains(llToLower(message), llList2String(blindcmd, l1)))
                {
                    blind = TRUE;
                    llSetObjectName("");
                    ownersay(skey, name + " can no longer see.", 0);
                    llSetObjectName(slave_base);
                    llMessageLinked(LINK_SET, S_API_SELF_DESC, blindmsg, NULL_KEY);
                    checkSetup(128, currentVision);
                }
            }
#ifndef PUBLIC_SLAVE
        }
#endif
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
        else if(num == S_API_MANTRA_DONE)
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
                llSetObjectName("");
                if(name != "") ownersay(id, name + " can see again.", 0);
                else           ownersay(id, "secondlife:///app/agent/" + (string)llGetOwner() + "/about can see again.", 0);
                llSetObjectName(slave_base);
                llMessageLinked(LINK_SET, S_API_SELF_DESC, unblindmsg, NULL_KEY);
                checkSetup(0, 0);
            }
            else
            {
                blind = TRUE;
                llSetObjectName("");
                if(name != "") ownersay(id, name + " can no longer see.", 0);
                else           ownersay(id, "secondlife:///app/agent/" + (string)llGetOwner() + "/about can no longer see.", 0);
                llSetObjectName(slave_base);
                llMessageLinked(LINK_SET, S_API_SELF_DESC, blindmsg, NULL_KEY);
                checkSetup(128, currentVision);
            }
        }
        else if(num == S_API_BLIND_LEVEL)
        {
            checkSetup(currentVision, (float)str);
            currentVision = (float)str;
            llSetObjectName("");
            if(name != "") ownersay(id, name + " has had their vision distance adjusted to " + formatfloat(currentVision, 2) + " meters.", 0);
            else           ownersay(id, "secondlife:///app/agent/" + (string)llGetOwner() + "/about has had their vision distance adjusted to " + formatfloat(currentVision, 2) + " meters.", 0);
            llSetObjectName(slave_base);
        }
        else if(num == S_API_EMERGENCY)
        {
            softReset();
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
                llSetObjectName("");
#ifndef PUBLIC_SLAVE
                if(llGetAgentSize(primary) != ZERO_VECTOR) ownersay(primary, "The " + VERSION_S + " worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about does not have RLV enabled.", 0);
                else                                       llInstantMessage(primary, "The " + VERSION_S + " worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about does not have RLV enabled.");
#endif
                llOwnerSay("Hey! Your RLV is (probably) turned off and I won't work properly until you turn it on and relog. If it is on, you're just experiencing some lag and you shouldn't worry about it.");
                llSetObjectName(slave_base);
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
            llSetObjectName("");
            llOwnerSay("Intrusive thoughts is good to go! Type /1" + prefix + " or click [secondlife:///app/chat/1/" + prefix + " here] to see your available actions.\nNote that, if present, you can type ((RED)) to clear the RLV relay, or ((FORCERED)) to clear and detach it.");
            llSetObjectName(slave_base);
            gotreply = TRUE;
            rlvtries = 0;
            llSetTimerEvent(0.0);
            llMessageLinked(LINK_THIS, S_API_RLV_CHECK, "", "");
            return;
        }
        if(c == 0)
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
            llSetObjectName("");
            ownersay(k, "[vision]: " + (string)(llGetFreeMemory() / 1024.0) + "kb free.", HUD_SPEAK_CHANNEL);
        }
    }
}
