#include <IT/globals.lsl>
key primary = NULL_KEY;
list owners = [];
integer publicaccess = FALSE;
integer groupaccess = FALSE;

list statements = [];
integer timerMin = 0;
integer timerMax = 0;

integer locked = FALSE;
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
            llRegionSayTo(llGetOwner(), MANTRA_CHANNEL, "CHECKPOS " + (string)llGetAttached() + " " + VERSION_CMP);
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
            llSetObjectName("");
            if(llGetAgentSize(afkChecker) != ZERO_VECTOR) llRegionSayTo(afkChecker, 0, "secondlife:///app/agent/" + (string)llGetOwner() + "/about has been given an AFK check. They have 30 seconds to succeed.");
            else                                          llInstantMessage(afkChecker, "secondlife:///app/agent/" + (string)llGetOwner() + "/about has been given an AFK check. They have 30 seconds to succeed.");
            llSetObjectName(slave_base);
            afkCheck();
        }
        else if(num == S_API_SET_LOCK)
        {
            locked = (integer)str;
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
                list params = llParseString2List(m, [" "], []);
                integer attachedto = (integer)llList2String(params, 1);
                string oversion = llList2String(params, 2);
                if(llGetListLength(params) < 3) oversion = "00000000000";
                if(ishigherversion(oversion))
                {
                    if(attachedto == llGetAttached())
                    {
                        llRegionSayTo(k, MANTRA_CHANNEL, "POSMATCH " + (string)llGetLocalPos());
                        llRegionSayTo(k, MANTRA_CHANNEL, "POSLOCKED " + (string)locked);
                        llSetObjectName("");
                        llOwnerSay("Detected newer IT Slave on this attachment point. Moving it in place and detaching myself.");
                        llSetObjectName(slave_base);
                        llMessageLinked(LINK_SET, S_API_SCHEDULE_DETACH, "", NULL_KEY);
                    }
                    else
                    {
                        llSetObjectName("");
                        llOwnerSay("Detected newer IT Slave on another attachment point. Detaching it.");
                        llRegionSayTo(k, MANTRA_CHANNEL, "POSNOMATCH " + (string)llGetAttached());
                        llSetObjectName(slave_base);
                    }
                }
                else
                {
                    llSetObjectName("");
                    llOwnerSay("Detected older IT Slave. Detaching it.");
                    llRegionSayTo(k, MANTRA_CHANNEL, "POSNOMATCH -1");
                    llSetObjectName(slave_base);
                }
            }
            else if(startswith(m, "POSMATCH"))
            {
                llSetPos((vector)llDeleteSubString(m, 0, llStringLength("POSMATCH")));
            }
            else if(startswith(m, "POSNOMATCH"))
            {
                integer attachedto = (integer)llDeleteSubString(m, 0, llStringLength("POSNOMATCH"));
                llSetObjectName("");
                if(attachedto != -1) llOwnerSay("You have an older IT slave attached, but it is attached to " + attachpointtotext(attachedto) + ". Please attach me to that point instead. Detaching now.");
                else                 llOwnerSay("You have a newer IT slave attached. Detaching now.");
                llSetObjectName(slave_base);
                llMessageLinked(LINK_SET, S_API_SCHEDULE_DETACH, "", NULL_KEY);
            }
            else if(startswith(m, "POSLOCKED"))
            {
                list params = llParseString2List(m, [" "], []);
                integer olocked = (integer)llList2String(params, 1);
                if(olocked)
                {
                    llSetObjectName("");
                    llOwnerSay("Moving myself into the position of your old IT slave and locking myself.");
                    llMessageLinked(LINK_SET, S_API_SET_LOCK, (string)TRUE, primary);
                    llSetObjectName(slave_base);
                }
                else
                {
                    llSetObjectName("");
                    llOwnerSay("Moving myself into the position of your old IT slave.");
                    llSetObjectName(slave_base);
                }
            }

            if(!isowner(k)) return;
            if(m == "RESET")
            {
                llSetObjectName("");
                ownersay(k, "The " + VERSION_S + " worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about is resetting configuration and listening to new programming...", HUD_SPEAK_CHANNEL);
                llSetObjectName(slave_base);
                statements = [];
            }
            else if(m == "END")
            {
                llSetObjectName("");
                ownersay(k, "[listener]: " + (string)(llGetFreeMemory() / 1024.0) + "kb free.", HUD_SPEAK_CHANNEL);
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
                llSetObjectName("");
                if(llGetAgentSize(afkChecker) != ZERO_VECTOR) llRegionSayTo(afkChecker, 0, "secondlife:///app/agent/" + (string)llGetOwner() + "/about has been given an AFK check. They have 30 seconds to succeed.");
                else                                          llInstantMessage(afkChecker, "secondlife:///app/agent/" + (string)llGetOwner() + "/about has been given an AFK check. They have 30 seconds to succeed.");
                llSetObjectName(slave_base);
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
                llSetObjectName("");
                if(llGetAgentSize(afkChecker) != ZERO_VECTOR) llRegionSayTo(afkChecker, 0, "secondlife:///app/agent/" + (string)llGetOwner() + "/about succeeded at their AFK check.");
                else                                          llInstantMessage(afkChecker, "secondlife:///app/agent/" + (string)llGetOwner() + "/about succeeded at their AFK check.");
                llSetObjectName(slave_base);
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
        llSetObjectName("");
        if(llGetAgentSize(afkChecker) != ZERO_VECTOR) llRegionSayTo(afkChecker, 0, "secondlife:///app/agent/" + (string)llGetOwner() + "/about FAILED their AFK check.");
        else                                          llInstantMessage(afkChecker, "secondlife:///app/agent/" + (string)llGetOwner() + "/about FAILED their AFK check.");
        llSetObjectName(slave_base);

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
