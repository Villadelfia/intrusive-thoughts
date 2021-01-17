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
                    checkSetup();
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
        if(num == S_API_STARTED)
        {
            checkSetup();
            gotreply = FALSE;
            llOwnerSay("@version=" + (string)RLV_CHECK_CHANNEL);
            llSetTimerEvent(30.0);
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
        if(num == S_API_BLIND_TOGGLE)
        {
            if(blind)
            {
                blind = FALSE;
                llMessageLinked(LINK_SET, S_API_SELF_DESC, unblindmsg, NULL_KEY);
                if(name != "") ownersay(id, name + " can see again.");
                else           ownersay(id, "secondlife:///app/agent/" + (string)llGetOwner() + "/about can see again.");
                checkSetup();
            }
            else
            {
                blind = TRUE;
                llMessageLinked(LINK_SET, S_API_SELF_DESC, blindmsg, NULL_KEY);
                if(name != "") ownersay(id, name + " can no longer see.");
                else           ownersay(id, "secondlife:///app/agent/" + (string)llGetOwner() + "/about can no longer see.");
                checkSetup();
            }
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
        llSetTimerEvent(0.0);
        if(!gotreply)
        {
            string oldn = llGetObjectName();
            llSetObjectName("");
            if(llGetAgentSize(primary) != ZERO_VECTOR) ownersay(primary, "The " + VERSION_S + " worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about does not have RLV enabled.");
            else                                       llInstantMessage(primary, "The " + VERSION_S + " worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about does not have RLV enabled.");
            llSetObjectName(oldn);
            llOwnerSay("Hey! Your RLV is (probably) turned off and I won't work properly until you turn it on and relog. If it is on, you're just experiencing some lag and you shouldn't worry about it.");
        }
    }

    listen(integer c, string n, key k, string m)
    {
        if(c == RLV_CHECK_CHANNEL && gotreply == FALSE)
        {
            string prefix = llGetSubString(llGetUsername(llGetOwner()), 0, 1);
            llOwnerSay("Intrusive thoughts is good to go! Type /1" + prefix + " or click [secondlife:///app/chat/1/" + prefix + " here] to see your available actions.\nNote that, if present, you can type ((RED)) to clear the RLV relay, or ((FORCERED)) to clear and detach it.");
            gotreply = TRUE;
        }
        if(c == 0) 
        {
            handleHear(k, n, m);
            return;
        }
        if(!isowner(k)) return;
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
            ownersay(k, "[vision]: " + (string)(llGetFreeMemory() / 1024.0) + "kb free.");
        }
    }
}