#include <IT/globals.lsl>

integer rlvid = 0;
integer channel = 1334612251;

key id = NULL_KEY;
string objectname;
key sitid = NULL_KEY;
list restrictions = [];
list filters = [];

integer handlinghandover = FALSE;
integer ismaster = FALSE;

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

integer isAllowed(string c)
{
    // Force to lower, remove the @, and remove spaces.
    if(llGetSubString(c, 0, 0) == "@") c = llDeleteSubString(c, 0, 0);
    c = llToLower(c);
    c = llDumpList2String(llParseStringKeepNulls(c, [" "], []), "");

    // Try all the filters for a match.
    integer i;
    integer j;
    integer fc = llGetListLength(filters);
    for(i = 0; i < fc; ++i)
    {
        // Working copy of command.
        string cmd = c;

        // Get the filter, split into tokens.
        string testing = llList2String(filters, i);
        list filter = llParseString2List(testing, [], ["+", "*"]);
        integer fl = llGetListLength(filter);
        integer skipping = FALSE;

        // Parse through the tokens.
        for(j = 0; j < fl; ++j)
        {
            string token = llList2String(filter, j);

            // If the token is "*" or "+", set skipping. If "+", eat a letter.
            // Either way, skip to the acceptance check due to exhausted filter.
            // In the case of a malformed filter with a +*, *+, ++, or ** sequence, it will not double trigger.
            // It will instead warn the user of a malformed filter and deny the command.
            if(token == "*" || token == "+")
            {
                if(skipping)
                {
                    llOwnerSay("Error: RLV filter \"" + testing + "\" is malformed due to consecutive wildcards. Denying all RLV commands until remedied.");
                    return FALSE;
                }
                skipping = TRUE;
                if(token == "+") cmd = llDeleteSubString(cmd, 0, 0);
                jump skiploop;
            }

            // If skipping flag is set, eat characters until the command starts with the token.
            while(skipping && llStringLength(cmd) != 0 && startswith(cmd, token) == FALSE) cmd = llDeleteSubString(cmd, 0, 0);

            // Check if cmd starts with token, if it does not, this means this filter does not match.
            // If it does, eat away the filter from the command string and unset skipping.
            if(startswith(cmd, token) == FALSE)
            {
                jump nextfilter;
            }
            else
            {
                cmd = llDeleteSubString(cmd, 0, llStringLength(token)-1);
                skipping = FALSE;
            }

            // If we are at the end of the filter, and have not rejected the filter, that means it must be accepted.
            @skiploop;
            if(j == fl-1) 
            {
                llOwnerSay("Command \"" + c + "\" denied due to filter \"" + testing + "\".");
                return FALSE;
            }
        }
        @nextfilter;
    }

    // No filter matched. Allow the command.
    return TRUE;
}


checkSend(string command)
{
    if(llListFindList(restrictions, ["sendchannel:1", "sendchannel:5", "sendchannel:7", "sendchannel:8", "sendchannel:9"]) != -1) return;
    list subargs = llParseString2List(command, ["="], []);
    string behav = llGetSubString(llList2String(subargs, 0), 1, -1);
    integer index = llListFindList(restrictions, [behav]);
    string comtype = llList2String(subargs, 1);
    if(index != -1) return;
    if(comtype == "y" || comtype == "rem") return;
    if(startswith(behav, "sendchannel"))
    {
        restrictions += ["sendchannel:1", "sendchannel:5", "sendchannel:7", "sendchannel:8", "sendchannel:9"];
        llOwnerSay("@sendchannel:1=add,sendchannel:5=add,sendchannel:7=add,sendchannel:8=add,sendchannel:9=add");
    }
}

                

handlerlvrc(string msg, integer echo)
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
        if(llGetSubString(command,0,0)=="@") 
        {
            if(command != "@detach=y" && command != "@permissive=y" && command != "@clear" && isAllowed(command) == TRUE)
            {
                if(ismaster) checkSend(command);
                llOwnerSay(command);
                if(echo) llRegionSayTo(id, RLVRC, ident+","+(string)id+","+command+",ok");
                list subargs = llParseString2List(command, ["="], []);
                string behav = llGetSubString(llList2String(subargs, 0), 1, -1);
                integer index = llListFindList(restrictions, [behav]);
                string comtype = llList2String(subargs, 1);                
                if(comtype == "n" || comtype == "add") 
                {
                    if(index == -1) restrictions += [behav];
                    if(behav == "unsit" && llGetAgentInfo(llGetOwner()) & AGENT_SITTING) llOwnerSay("@getsitid=" + (string)channel);
                }
                else if(comtype == "y" || comtype == "rem") 
                {
                    if(index != -1) restrictions = llDeleteSubList(restrictions, index, index);
                    if(behav == "unsit") sitid = NULL_KEY;
                }
            }
        }
        else if(command == "!pong")
        {
            if(echo) llOwnerSay("@sit:"+(string)sitid+"=force,"+llDumpList2String(restrictions, "=n,")+"=n");
            llSetTimerEvent(0);
        }
        else if(command == "!version")
        {
            if(echo) llRegionSayTo(id, RLVRC, ident+","+(string)id+",!version,1100");
        }
        else if(command == "!implversion")
        {
            if(echo) llRegionSayTo(id, RLVRC, ident+","+(string)id+",!implversion,ORG=0004/Hana's Relay");
        }
        else if(command == "!x-orgversions")
        {
            if(echo) llRegionSayTo(id, RLVRC, ident+","+(string)id+",!x-orgversions,ORG=0004/handover=001");
        }
        else if(startswith(command, "!x-handover"))
        {
            list args = llParseString2List(command, ["/"], []);
            dohandover((key)llList2String(args, 1), (integer)llList2String(args, 2));
            return;
        }
        else if(command == "!release")
        {
            release();
        }
        else
        {
            if(echo) llRegionSayTo(id, RLVRC, ident+","+(string)id+","+command+",ko");
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
        if(num < -999 && num > -2000) ismaster = FALSE;
        if(num < -1999 && num > -3000) ismaster = TRUE;
        
        if(num == RLV_API_HANDLE_CMD && (string)k == (string)rlvid && id != NULL_KEY)            handlerlvrc(str, TRUE);
        else if(num == RLV_API_HANDLE_CMD_QUIET && (string)k == (string)rlvid && id != NULL_KEY) handlerlvrc(str, FALSE);
        else if(num == RLV_API_GET_RESTRICTIONS)
        {
            if(id) llMessageLinked(LINK_SET, RLV_API_RESP_RESTRICTIONS, (string)rlvid, (key)(llDumpList2String(restrictions, "\n")));
            else   llMessageLinked(LINK_SET, RLV_API_RESP_RESTRICTIONS, (string)rlvid, (key)"");
        }
        else if(num == RLV_API_SET_FILTERS)
        {                    
            str = llToLower(str);
            str = llDumpList2String(llParseStringKeepNulls(str, [" "], []), "");
            filters = llParseString2List(str, ["\n"], []);
        }
        else if(num == RLV_API_SET_SRC && str == (string)rlvid)                        
        {
            if(id != NULL_KEY) release();
            id = k;
            llSetTimerEvent(5.0);
            objectname = llList2String(llGetObjectDetails(id, [OBJECT_NAME]), 0);
        }
        else if(num == RLV_API_SAFEWORD)                                               
        {
            release();
        }
        else if(num == S_API_MANTRA_DONE)
        {
            if(restrictions != []) llOwnerSay("@"+llDumpList2String(restrictions, "=n,")+"=n");
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
        if(handlinghandover)
        {
            handlinghandover = FALSE;
            release();
        }
        
        if(id)
        {
            if(llList2Vector(llGetObjectDetails(id, [OBJECT_POS]), 0) == ZERO_VECTOR)
            {
                release();
            }
        }
        
        if(id) llSetTimerEvent(5.0);
    }
}