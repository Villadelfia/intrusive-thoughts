#include <IT/globals.lsl>
key primary = NULL_KEY;
list owners = [];
integer publicaccess = FALSE;
integer groupaccess = FALSE;

list statements = [];
integer timerMin = 0;
integer timerMax = 0;

integer tempListen = -1;
key afkChecker = NULL_KEY;
string afkMessage = "";
string correctAnswer = "";

afkCheck()
{
    sensortimer(0.0);
    if(tempListen != -1) 
    {
        llListenRemove(tempListen);
        tempListen = -1;
    }

    afkMessage = "AFK Check pop quiz!\n\n";
    integer x = llRound(llFrand(10)+1);
    integer y = llRound(llFrand(10)+1);
    correctAnswer = (string)(x + y);
    afkMessage += "What is " + (string)x + "+" + (string)y + "?\n\nQuickly now! Your owner is waiting and will only wait for 30 seconds!";

    tempListen = llListen(COMMAND_CHANNEL, "", llGetOwner(), "");
    llTextBox(llGetOwner(), afkMessage, COMMAND_CHANNEL);
    sensortimer(30.0);
}

default
{
    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == S_API_STARTED)
        {
            llRegionSayTo(llGetOwner(), MANTRA_CHANNEL, "CHECKPOS " + (string)llGetAttached());
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
        else if(num == S_API_AFK_CHECK)
        {
            afkChecker = llGetOwnerKey(id);                
            if(llGetAgentSize(afkChecker) != ZERO_VECTOR) llRegionSayTo(afkChecker, 0, "secondlife:///app/agent/" + (string)llGetOwner() + "/about has been given an AFK check. They have 30 seconds to succeed.");
            else                                          llInstantMessage(afkChecker, "secondlife:///app/agent/" + (string)llGetOwner() + "/about has been given an AFK check. They have 30 seconds to succeed.");
            afkCheck();
        }
    }

    state_entry()
    {
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
    }

    listen(integer c, string n, key k, string m)
    {
        if(c == MANTRA_CHANNEL)
        {
            if(startswith(m, "CHECKPOS") == TRUE && llGetOwnerKey(k) == llGetOwner())
            {
                integer attachedto = (integer)llDeleteSubString(m, 0, llStringLength("CHECKPOS"));
                if(attachedto == llGetAttached())
                {
                    llRegionSayTo(k, MANTRA_CHANNEL, "POSMATCH " + (string)llGetLocalPos());
                    llOwnerSay("Detected new IT Slave on this attachment point. Moving it in place and detaching myself.");
                    llOwnerSay("@clear,detachme=force");
                }
                else
                {
                    llOwnerSay("Detected new IT Slave on another attachment point. Detaching it.");
                    llRegionSayTo(k, MANTRA_CHANNEL, "POSNOMATCH " + (string)llGetAttached());
                }
            }
            else if(startswith(m, "POSMATCH") == TRUE && llGetOwnerKey(k) == llGetOwner())
            {
                vector newpos = (vector)llDeleteSubString(m, 0, llStringLength("POSMATCH"));
                llOwnerSay("Moving myself into the position of your old IT slave.");
                llSetPos(newpos);
            }
            else if(startswith(m, "POSNOMATCH") == TRUE && llGetOwnerKey(k) == llGetOwner())
            {
                integer attachedto = (integer)llDeleteSubString(m, 0, llStringLength("POSNOMATCH"));
                llOwnerSay("You already have another IT slave attached, but it is attached to " + attachpointtotext(attachedto) + ". Please attach me to that point instead. Detaching now.");
                llOwnerSay("@clear,detachme=force");
            }

            if(!isowner(k)) return;
            if(m == "RESET")
            {
                ownersay(k, "The " + VERSION_S + " worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about is resetting configuration and listening to new programming...");
                statements = [];
            }
            else if(m == "END")
            {
                ownersay(k, "[mantra]: " + (string)(llGetFreeMemory() / 1024.0) + "kb free.");
            }
            else if(m == "PING")
            {
                llRegionSayTo(k, PING_CHANNEL, "PING");
            }
            else if(startswith(m, "TIMER"))
            {
                list t = llParseString2List(m, [" "], []);
                timerMin = (integer)llList2String(t, 1);
                timerMax = (integer)llList2String(t, 2);
                if(timerMax != 0) llSetTimerEvent(random(timerMin * 60, timerMax * 60));
            }
            else if(startswith(m, "PHRASES"))
            {
                statements += [llDeleteSubString(m, 0, llStringLength("PHRASES"))];
            }
            else if(m == "AFKCHECK")
            {
                afkChecker = llGetOwnerKey(k);                
                if(llGetAgentSize(afkChecker) != ZERO_VECTOR) llRegionSayTo(afkChecker, 0, "secondlife:///app/agent/" + (string)llGetOwner() + "/about has been given an AFK check. They have 30 seconds to succeed.");
                else                                          llInstantMessage(afkChecker, "secondlife:///app/agent/" + (string)llGetOwner() + "/about has been given an AFK check. They have 30 seconds to succeed.");
                afkCheck();
            }
        }
        else if(c == COMMAND_CHANNEL)
        {
            m = llStringTrim(llToLower(m), STRING_TRIM);
            if(m == correctAnswer)
            {
                sensortimer(0.0);
                if(tempListen != -1) 
                {
                    llListenRemove(tempListen);
                    tempListen = -1;
                }
                llDialog(llGetOwner(), "Good job. Your owner will be pleased.", ["Phew..."], COMMAND_CHANNEL);
                if(llGetAgentSize(afkChecker) != ZERO_VECTOR) llRegionSayTo(afkChecker, 0, "secondlife:///app/agent/" + (string)llGetOwner() + "/about succeeded at their AFK check.");
                else                                          llInstantMessage(afkChecker, "secondlife:///app/agent/" + (string)llGetOwner() + "/about succeeded at their AFK check.");
            }
            else
            {
                llTextBox(llGetOwner(), afkMessage, COMMAND_CHANNEL);
            }
        }
    }

    no_sensor()
    {
        sensortimer(0.0);
        if(tempListen != -1) 
        {
            llListenRemove(tempListen);
            tempListen = -1;
        }                
        llDialog(llGetOwner(), "Too bad. You're out of time. What will your owner think of that?", ["Uh-oh..."], COMMAND_CHANNEL);
        if(llGetAgentSize(afkChecker) != ZERO_VECTOR) llRegionSayTo(afkChecker, 0, "secondlife:///app/agent/" + (string)llGetOwner() + "/about FAILED their AFK check.");
        else                                          llInstantMessage(afkChecker, "secondlife:///app/agent/" + (string)llGetOwner() + "/about FAILED their AFK check.");

    }

    timer()
    {
        if(timerMax == 0)
        {
            llSetTimerEvent(0.0);
            return;
        }
        llSetTimerEvent(random(timerMin * 60, timerMax * 60));
        if(statements == []) return;
        llMessageLinked(LINK_SET, S_API_SELF_DESC, llList2String(statements, llFloor(llFrand(llGetListLength(statements)))), NULL_KEY);
    }
}