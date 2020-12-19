#include <IT/globals.lsl>
integer rlvrc = -1812221819;
key wearer = NULL_KEY;
integer viewerlistener = -1;
integer listenhandle = -1;
key sitid = NULL_KEY;
integer sitidsetby = 0;
list sources = [];
list restrictions1 = [];
list restrictions2 = [];
list restrictions3 = [];
list restrictions4 = [];
list restrictions5 = [];
list replies = [];
 
release(key id, integer disable) 
{
    if(disable)
    {
        llOwnerSay("@clear");

        integer l = llGetListLength(sources);
        key source;
        while(l >= 0)
        {
            source = llList2Key(sources, l);
            llRegionSayTo(source, rlvrc, "release,"+(string)source+",!release,ok");
            l--;
        }

        sources = [];
        restrictions1 = [];
        restrictions2 = [];
        restrictions3 = [];
        restrictions4 = [];
        restrictions5 = [];
        sitid = NULL_KEY;
        disablerelay();
    }
    else
    {
        llRegionSayTo(id, rlvrc, "release,"+(string)id+",!release,ok");
        integer sourceid = llListFindList(sources, [id]) + 1;
        checkforclear(sourceid);
    }
}

checkforclear(integer sourceid)
{
    if(sourceid == 0) return;
    if(sitidsetby == sourceid) sitid = NULL_KEY;
    if(sourceid == 1) 
    {
        restrictions1 = restrictions2;
        restrictions2 = restrictions3;
        restrictions3 = restrictions4;
        restrictions4 = restrictions5;
        restrictions5 = [];
    }
    if(sourceid == 2)
    {
        restrictions2 = restrictions3;
        restrictions3 = restrictions4;
        restrictions4 = restrictions5;
        restrictions5 = [];
    }
    if(sourceid == 3)
    {
        restrictions3 = restrictions4;
        restrictions4 = restrictions5;
        restrictions5 = [];
    }
    if(sourceid == 4)
    {
        restrictions4 = restrictions5;
        restrictions5 = [];
    }
    if(sourceid == 5)
    {
        restrictions5 = [];
    }
    if(sourceid <= llGetListLength(sources)) sources = llDeleteSubList(sources, sourceid-1, sourceid-1);
    if(restrictions1 == [] && restrictions2 == [] && restrictions3 == [] && restrictions4 == [] && restrictions5 == []) llOwnerSay("@clear");
}

integer startswith(string haystack, string needle)
{
    return llDeleteSubString(haystack, llStringLength(needle), 0x7FFFFFF0) == needle;
}

enablerelay()
{
    llOwnerSay("Enabling RLV relay. Click the purple half-circle to release yourself from any restrictions and to deactivate it again.");
    if(listenhandle != -1) llListenRemove(listenhandle);
    listenhandle = llListen(rlvrc, "", NULL_KEY, "");
}

disablerelay()
{
    llOwnerSay("Disabling RLV relay. Click the purple half-circle to activate it again.");
    if(listenhandle != -1) llListenRemove(listenhandle);
    listenhandle = -1;
}
 
default 
{
    state_entry() 
    {
        wearer = llGetOwner();
        llListen(1, "", wearer, "red");
        llListen(1, "", wearer, "RED");
        llListen(0, "", wearer, "((red))");
        llListen(0, "", wearer, "((RED))");
        llOwnerSay("RLV relay good to go. Click the purple half-circle to enable it.");
    }
 
    touch_start(integer total_number) 
    {
        if(listenhandle == -1)
        {
            enablerelay();
        }
        else if(sources == [])
        {
            disablerelay();
        }
        else
        {
            llOwnerSay("Releasing RLV restrictions and disabling the relay.");
            release(NULL_KEY, TRUE);
        }
    }
 
    listen(integer c, string w, key id, string msg) 
    {
        if(c == 12345) 
        {
            if(msg) sitid = (key)msg;
            if(viewerlistener != -1) llListenRemove(viewerlistener);
            viewerlistener = -1;
            return;
        }
        else if(c == 1 || c == 0)
        {
            if(sources == []) return;
            llOwnerSay("Releasing RLV restrictions and disabling the relay.");
            release(NULL_KEY, TRUE);
        }

        if(llGetListLength(sources) == 5 && llListFindList(sources, [id]) == -1) 
        { 
            llOwnerSay("Another device is trying to access your RLV relay, but you're already being controlled by five devices!");
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
        integer sourceid = llListFindList(sources, [id]) + 1;
        if(sourceid == 0) sourceid = llGetListLength(sources) + 1;

        for(i=0; i < nc; ++i)
        {
            command = llList2String(commands, i);
            if(llGetSubString(command, 0, 0) == "@") 
            {
                llOwnerSay(command);
                llRegionSayTo(id, rlvrc, ident + "," + (string)id + "," + command + ",ok");
                list subargs = llParseString2List(command, ["="], []);
                string behav = llGetSubString(llList2String(subargs, 0), 1, -1);
                if(behav == "version" || behav == "versionnew" || behav == "versionnum" || behav == "versionnumbl") llOwnerSay("Getting scanned by '" + w + "'.");
                integer index;
                if(sourceid == 1) index = llListFindList(restrictions1, [behav]);
                if(sourceid == 2) index = llListFindList(restrictions2, [behav]);
                if(sourceid == 3) index = llListFindList(restrictions3, [behav]);
                if(sourceid == 4) index = llListFindList(restrictions4, [behav]);
                if(sourceid == 5) index = llListFindList(restrictions5, [behav]);
                string comtype = llList2String(subargs, 1);                
                if(comtype == "n" || comtype == "add")
                {
                    if(index == -1) 
                    {
                        if(sourceid == 1) restrictions1 += [behav];
                        if(sourceid == 2) restrictions2 += [behav];
                        if(sourceid == 3) restrictions3 += [behav];
                        if(sourceid == 4) restrictions4 += [behav];
                        if(sourceid == 5) restrictions5 += [behav];
                    }
                    if(behav == "unsit" && llGetAgentInfo(wearer) & AGENT_SITTING)
                    {
                        if(viewerlistener != -1) llListenRemove(viewerlistener);
                        viewerlistener = llListen(12345, "", wearer, "");
                        llOwnerSay("@getsitid=12345");
                        sitidsetby = sourceid;
                    }
                }
                else if(comtype=="y" || comtype == "rem") 
                {
                    if(index == -1) 
                    {
                        if(sourceid == 1) restrictions1 = llDeleteSubList(restrictions1, index, index);
                        if(sourceid == 2) restrictions2 = llDeleteSubList(restrictions2, index, index);
                        if(sourceid == 3) restrictions3 = llDeleteSubList(restrictions3, index, index);
                        if(sourceid == 4) restrictions4 = llDeleteSubList(restrictions4, index, index);
                        if(sourceid == 5) restrictions5 = llDeleteSubList(restrictions5, index, index);
                    }
                    if(behav == "unsit") sitid = NULL_KEY;
                }
            }
            else if(command == "!pong") 
            {
                llOwnerSay("Reapplying RLV restrictions from '" + w + "'.");
                if(sourceid == 1) llOwnerSay("@sit:"+(string)sitid+"=force,"+llDumpList2String(restrictions1, "=n,")+"=n");
                if(sourceid == 2) llOwnerSay("@sit:"+(string)sitid+"=force,"+llDumpList2String(restrictions2, "=n,")+"=n");
                if(sourceid == 3) llOwnerSay("@sit:"+(string)sitid+"=force,"+llDumpList2String(restrictions3, "=n,")+"=n");
                if(sourceid == 4) llOwnerSay("@sit:"+(string)sitid+"=force,"+llDumpList2String(restrictions4, "=n,")+"=n");
                if(sourceid == 5) llOwnerSay("@sit:"+(string)sitid+"=force,"+llDumpList2String(restrictions5, "=n,")+"=n");
                replies += [id];
            }
            else if(command == "!version")
            {
                llOwnerSay("RLV relay version requested by '" + w + "'.");
                llRegionSayTo(id, rlvrc, ident+","+(string)id+",!version,1100");
            }
            else if(command == "!implversion")
            {
                llOwnerSay("ORG RLV relay version requested by '" + w + "'.");
                llRegionSayTo(id, rlvrc, ident+","+(string)id+",!implversion,ORG=0003/Hana's Relay");
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
                llOwnerSay("The device '" + w + "' is releasing you.");
                release(id, FALSE);
            }
            else 
            {
                llRegionSayTo(id, rlvrc, ident + "," + (string)id + "," + command + ",ko");            
            }
        }

        if((sourceid == 1 && restrictions1 != []) ||
           (sourceid == 2 && restrictions2 != []) ||
           (sourceid == 3 && restrictions3 != []) ||
           (sourceid == 4 && restrictions4 != []) ||
           (sourceid == 5 && restrictions5 != [])) 
        {
            if(sourceid > llGetListLength(sources)) 
            {
                sources += [id];
                llOwnerSay("You got restricted by '" + w +"'. It is device number " + (string)llGetListLength(sources) + " out of a maximum number of 5 that is currently controlling you.\n\nReminder: Type /1RED or click the purple half-circle to release yourself immediately.");
                llOwnerSay("@detach=n");
            }
        }
        else 
        {
            checkforclear(sourceid);
        }
    }
 
    changed(integer c) 
    {
        if(c & CHANGED_OWNER) llResetScript();
    }
 
    on_rez(integer i) 
    {
        if(sources != []) 
        {
            llSetTimerEvent(0);
            llSleep(30);
            llOwnerSay("Waking up from relog, attempting re-capture...");
            replies = [];
            integer l = llGetListLength(sources);
            key source;
            while(l >= 0)
            {
                source = llList2Key(sources, l);
                llRegionSayTo(source, rlvrc, "ping," + (string)source + ",ping,ping");
                l--;
            }
            llSetTimerEvent(30);
        }
    }
 
    timer() 
    {
        if(llGetListLength(replies) == llGetListLength(sources))
        {
            llSetTimerEvent(0);
            return;
        }
        else
        {
            llOwnerSay("Capturing device(s) no longer responding. Releasing from them.");
            llSetTimerEvent(0);
            integer l = llGetListLength(sources);
            key source;
            while(l >= 0)
            {
                source = llList2Key(sources, l);
                if(llListFindList(replies, [source]) == -1) release(source, FALSE);
                l--;
            }
        }
    }
}