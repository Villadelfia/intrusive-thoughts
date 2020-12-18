#define SUPPORT_TOUCH 1

integer rlvrc = -1812221819;
key source = NULL_KEY;
key wearer = NULL_KEY;
integer viewerlistener = -1;
key sitid;
list restrictions = [];
 
release(key id) 
{
    llOwnerSay("@clear");
    llRegionSayTo(id, rlvrc, "release,"+(string)id+",!release,ok");
    llResetScript();
}

integer startswith(string haystack, string needle)
{
    return llDeleteSubString(haystack, llStringLength(needle), 0x7FFFFFF0) == needle;
}
 
default 
{
    state_entry() 
    {
        llOwnerSay("Delaying startup for 10 seconds... If a device is spamming your relay, you can safely detach me now.");
        llSleep(10.0);
        wearer = llGetOwner();
        llListen(rlvrc, "", NULL_KEY, "");
        llListen(1, "", wearer, "red");
        llListen(1, "", wearer, "RED");
        llListen(0, "", wearer, "((red))");
        llListen(0, "", wearer, "((RED))");
        llOwnerSay("RLV relay active and listening.");
    }
 
    touch_start(integer total_number) 
    {
        if(SUPPORT_TOUCH == 0) return;
        if(source == NULL_KEY) return;
        llOwnerSay("Releasing RLV restrictions and resetting...");
        release(source);
    }
 
    listen(integer c, string w, key id, string msg) 
    {
        if(c == 12345) 
        {
            if(msg) sitid = (key)msg;
            llListenRemove(viewerlistener);
            viewerlistener = -1;
            return;
        }
        else if(c == 1 || c == 0)
        {
            if(source == NULL_KEY) return;
            llOwnerSay("Releasing RLV restrictions and resetting...");
            release(source);
        }

        if(source != NULL_KEY && source != id) 
        { 
            llOwnerSay("Another device is trying to access your RLV relay, but you're already being controlled!");
            return;
        }

        list args = llParseStringKeepNulls(msg, [","], []);
        if(llGetListLength(args) != 3) return;
        if(llList2Key(args, 1) != wearer && llList2Key(args, 1) != (key)"ffffffff-ffff-ffff-ffff-ffffffffffff") return;

        string ident = llList2String(args,0);
        list commands = llParseString2List(llList2String(args,2),["|"],[]);
        integer i;
        string command;
        integer nc = llGetListLength(commands);
        integer skiprest = FALSE;

        for(i=0; i < nc; ++i)
        {
            if(skiprest) jump skip;
            command = llList2String(commands, i);
            if(llGetSubString(command, 0, 0) == "@") 
            {
                llOwnerSay("Applying RLV command from '" + w + "': " + command);
                llOwnerSay(command);
                llRegionSayTo(id, rlvrc, ident + "," + (string)id + "," + command + ",ok");
                list subargs = llParseString2List(command, ["="], []);
                string behav = llGetSubString(llList2String(subargs, 0), 1, -1);
                integer index = llListFindList(restrictions, [behav]);
                string comtype = llList2String(subargs, 1);                
                if(comtype == "n" || comtype == "add")
                {
                    if(index == -1) restrictions += [behav];
                    if(behav == "unsit" && llGetAgentInfo(wearer) & AGENT_SITTING)
                    {
                        if(viewerlistener != -1) llListenRemove(viewerlistener);
                        viewerlistener = llListen(12345, "", wearer, "");
                        llOwnerSay("@getsitid=12345");
                    }
                }
                else if(comtype=="y" || comtype == "rem") 
                {
                    if(index != -1) restrictions = llDeleteSubList(restrictions, index, index);
                    if(behav == "unsit") sitid = NULL_KEY;
                }
            }
            else if(command == "!pong") 
            {
                llOwnerSay("Reapplying RLV restrictions from '" + w + "': @sit:" + (string)sitid + "=force," + llDumpList2String(restrictions, "=n,") + "=n");
                llOwnerSay("@sit:"+(string)sitid+"=force,"+llDumpList2String(restrictions, "=n,")+"=n");
                llSetTimerEvent(0);
            }
            else if(command == "!version")
            {
                llOwnerSay("RLV relay version requested by '" + w + "'.");
                llRegionSayTo(id, rlvrc, ident+","+(string)id+",!version,1100");
            }
            else if(command == "!implversion")
            {
                llOwnerSay("ORG RLV relay version requested by '" + w + "'.");
                llRegionSayTo(id, rlvrc, ident+","+(string)id+",!implversion,ORG=0003/Hana's Relay/mode=auto");
            }
            else if(command == "!x-orgversions")
            {
                llOwnerSay("ORG RLV relay capabilities requested by '" + w + "'.");
                llRegionSayTo(id, rlvrc, ident+","+(string)id+",!x-orgversions,ORG=0004/who=001");
            }
            else if(startswith(command, "!x-who"))
            {
                list sub = llParseString2List(command, ["/"], []);
                llOwnerSay("The device '" + w + "' wants you to know that the person responsible for your restrictions is secondlife:///app/agent/" + llList2String(sub, 1) +"/about.");
                llRegionSayTo(id, rlvrc, ident + "," + (string)id + "," + command + ",ok");  
            }
            else if(command == "!release") 
            {
                release(id);
            }
            else 
            {
                llRegionSayTo(id, rlvrc, ident + "," + (string)id + "," + command + ",ko");            
            }
        }

        @skip;
        if(restrictions) 
        {
            llOwnerSay("Reminder: Type /1RED or click me to release yourself immediately.");
            source = id; 
            llOwnerSay("@detach=n"); 
        }
        else 
        { 
            llOwnerSay("@clear"); 
            source = NULL_KEY;
            sitid = NULL_KEY;
            restrictions = [];
        }
    }
 
    changed(integer c) 
    {
        if(c & CHANGED_OWNER) llResetScript();
    }
 
    on_rez(integer i) 
    {
        if (source) 
        {
            llOwnerSay("Waking up from relog, attempting re-capture...");
            llSleep(30);
            llRegionSayTo(source, rlvrc, "ping," + (string)source + ",ping,ping");
            llSetTimerEvent(30);
        }
    }
 
    timer() 
    {
        llResetScript();
    }
}