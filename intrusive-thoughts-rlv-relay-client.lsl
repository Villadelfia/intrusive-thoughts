#include <IT/globals.lsl>

integer rlvid = 0;
integer channel = 1334612251;

key id = NULL_KEY;
string objectname;
key sitid = NULL_KEY;
list restrictions = [];

integer handlinghandover = FALSE;

release()
{
    if(restrictions != [])
    {
        integer l = llGetListLength(restrictions)-1;
        while(l >= 0) 
        {
            llOwnerSay("@" + llList2String(restrictions, l) + "=y");
            --l;
        }
        llRegionSayTo(id, RLVRC, "release,"+(string)id+",!release,ok");
        llOwnerSay("RLV Device " + (string)(rlvid + 1) + ": Released restrictions from " + objectname + ".");
    }
    llMessageLinked(LINK_SET, RLV_API_CLR_SRC, (string)rlvid, NULL_KEY);
    restrictions = [];
    id = NULL_KEY;
    sitid = NULL_KEY;
}

dohandover(key target, integer keep)
{
    llMessageLinked(LINK_SET, RLV_API_HANDOVER, (string)rlvid, target);
    id = target;
    objectname = llList2String(llGetObjectDetails(id, [OBJECT_NAME]), 0);
    if(keep == 0)
    {
        if(restrictions != [])
        {
            integer l = llGetListLength(restrictions)-1;
            while(l >= 0) 
            {
                llOwnerSay("@" + llList2String(restrictions, l) + "=y");
                --l;
            }
        }
    }
    handlinghandover = TRUE;
    llSetTimerEvent(30.0);
}

handlerlvrc(string msg)
{
    list args = llParseStringKeepNulls(msg,[","],[]);
    if(llGetListLength(args)!=3) return;
    if(llList2Key(args,1) != llGetOwner() && llList2Key(args, 1) != (key)"ffffffff-ffff-ffff-ffff-ffffffffffff") return;

    if(handlinghandover)
    {
        handlinghandover = FALSE;
        llSetTimerEvent(0.0);
    }

    string ident = llList2String(args,0);
    list commands = llParseString2List(llList2String(args,2),["|"],[]);
    integer i;
    string command;
    integer nc = llGetListLength(commands);

    for (i=0; i<nc; ++i) 
    {
        command = llList2String(commands,i);
        if (llGetSubString(command,0,0)=="@") 
        {
            if(command != "@detach=y" && command != "@permissive=y" && command != "@clear")
            {
                llOwnerSay(command);
                llRegionSayTo(id, RLVRC, ident+","+(string)id+","+command+",ok");
                list subargs = llParseString2List(command, ["="], []);
                string behav = llGetSubString(llList2String(subargs, 0), 1, -1);
                integer index = llListFindList(restrictions, [behav]);
                string comtype = llList2String(subargs, 1);                
                if (comtype == "n" || comtype == "add") 
                {
                    if(index == -1) restrictions += [behav];
                    if(behav == "unsit" && llGetAgentInfo(llGetOwner()) & AGENT_SITTING) llOwnerSay("@getsitid=" + (string)channel);
                }
                else if (comtype=="y" || comtype == "rem") 
                {
                    if (index != -1) restrictions = llDeleteSubList(restrictions, index, index);
                    if (behav == "unsit") sitid = NULL_KEY;
                }
            }
        }
        else if(command == "!pong")
        {
            llOwnerSay("@sit:"+(string)sitid+"=force,"+llDumpList2String(restrictions, "=n,")+"=n");
            llSetTimerEvent(0);
        }
        else if(command == "!version")
        {
            llRegionSayTo(id, RLVRC, ident+","+(string)id+",!version,1100");
        }
        else if(command == "!implversion")
        {
            llRegionSayTo(id, RLVRC, ident+","+(string)id+",!implversion,ORG=0004/Hana's Relay");
        }
        else if(command == "!x-orgversions")
        {
            llRegionSayTo(id, RLVRC, ident+","+(string)id+",!x-orgversions,ORG=0004/handover=001");
        }
        else if(startswith(command, "!x-handover"))
        {
            list args = llParseString2List(command, ["/"], []);
            dohandover((key)llList2String(args, 0), (integer)llList2String(args, 1));
            return;
        }
        else if(command == "!release")
        {
            release();
        }
        else
        {
            llRegionSayTo(id, RLVRC, ident+","+(string)id+","+command+",ko");
        }
    }
    if(restrictions == [])
    {
        release();
    }
}

default
{
    changed(integer change)
    {
        if(change & CHANGED_OWNER) llResetScript();
    }

    state_entry()
    {
        list tokens = llParseString2List(llGetScriptName(), [" "], []);
        rlvid = (integer)llList2String(tokens, -1);
        channel += rlvid;
        llListen(channel, "", llGetOwner(), "");
    }

    listen(integer c, string w, key id, string msg)
    {
        key k = (key)msg;
        if(k) sitid = k;
    }

    link_message(integer sender_num, integer num, string str, key k)
    {
        if(num == RLV_API_HANDLE_CMD && (string)k == (string)rlvid && id != NULL_KEY)  
        {
            handlerlvrc(str);
        }
        else if(num == RLV_API_SET_SRC && str == (string)rlvid)                        
        {
            if(id != NULL_KEY) release();
            id = k;
            objectname = llList2String(llGetObjectDetails(id, [OBJECT_NAME]), 0);
        }
        else if(num == RLV_API_SAFEWORD)                                               
        {
            release();
        }
    }

    on_rez(integer i) 
    {
        if(id) 
        {
            llSleep(30.0);
            llRegionSayTo(id, RLVRC, "ping,"+(string)id+",ping,ping");
            llSetTimerEvent(30.0);
        }
    }
 
    timer()
    {
        llSetTimerEvent(0.0);
        handlinghandover = FALSE;
        release();
    }
}