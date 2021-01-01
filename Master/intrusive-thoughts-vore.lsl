#include <IT/globals.lsl>

string owner = "";
string objectprefix = "";
string foodname = "food";
string vorespoof = "";
string unvorespoof = "";
key lockedavatar = NULL_KEY;
string lockedname = "";
key vorecarrier = NULL_KEY;
key vorevictim = NULL_KEY;
string vorename = "";
key target;
string targetname;
integer intp = FALSE;
string await;
integer fillfactor = 25;

detachbelly()
{
    llOwnerSay("@detach:~IT/vore/on=force");
    llOwnerSay("@attachover:~IT/vore/off=force");
}

attachbelly()
{
    llOwnerSay("@detach:~IT/vore/off=force");
    llOwnerSay("@attachover:~IT/vore/on=force");
}

integer canrez(vector pos)
{
    integer flags = llGetParcelFlags(pos);
    if(flags & PARCEL_FLAG_ALLOW_CREATE_OBJECTS) return TRUE;
    list details = llGetParcelDetails(pos, [PARCEL_DETAILS_OWNER, PARCEL_DETAILS_GROUP]);
    if(llList2Key(details, 0) == llGetOwner()) return TRUE;
    return(flags & PARCEL_FLAG_ALLOW_CREATE_GROUP_OBJECTS) && llSameGroup(llList2Key(details, 1));
}

unvore()
{
    if(vorecarrier == NULL_KEY) return;
    detachbelly();
    string spoof;
    spoof = llDumpList2String(llParseStringKeepNulls(unvorespoof, ["%ME%"], []), owner);
    spoof = llDumpList2String(llParseStringKeepNulls(spoof, ["%OBJ%"], []), foodname);
    spoof = llDumpList2String(llParseStringKeepNulls(spoof, ["%VIC%"], []), vorename);
    llSay(0, spoof);
    llRegionSayTo(vorecarrier, MANTRA_CHANNEL, "unsit");
    llRegionSayTo(vorevictim, RLVRC, "release," + (string)vorevictim + ",!release");
    vorecarrier = NULL_KEY;
    vorevictim = NULL_KEY;
    vorename = "";
}

vore()
{
    if(lockedavatar == llGetOwner()) return;
    
    if(!canrez(llGetPos()))
    {
        llOwnerSay("Can't rez here, trying to set land group.");
        llOwnerSay("@setgroup:" + (string)llList2Key(llGetParcelDetails(llGetPos(), [PARCEL_DETAILS_GROUP]), 0) + "=force");
        llSleep(2.5);
    }

    if(!canrez(llGetPos())) 
    {
        llOwnerSay("Can't rez here. Not eating.");
        return;
    }

    llOwnerSay("Eating '" + lockedname + "'.");
    target = lockedavatar;
    targetname = lockedname;
    llRezAtRoot("carrier", llGetPos(), ZERO_VECTOR, ZERO_ROTATION, 1);
}

handletp()
{
    integer delayed = FALSE;
    if(!canrez(llGetPos()))
    {
        llOwnerSay("Can't rez here, trying to set land group.");
        llOwnerSay("@setgroup:" + (string)llList2Key(llGetParcelDetails(llGetPos(), [PARCEL_DETAILS_GROUP]), 0) + "=force");
        llSleep(10.0);
        delayed = TRUE;
    }

    if(!canrez(llGetPos()))
    {
        llOwnerSay("Can't rez here. Not recapturing.");
        vorecarrier = NULL_KEY;
        vorevictim = NULL_KEY;
        vorename = "";
        intp = FALSE;
    }
    else
    {
        if(delayed)
        {
            llOwnerSay("Re-eating your prey.");
        }
        else
        {
            llOwnerSay("Re-eating your prey in 10 seconds.");
            llSleep(10.0);
        }
        target = vorevictim;
        targetname = vorename;
        llRezAtRoot("carrier", llGetPos(), ZERO_VECTOR, ZERO_ROTATION, 1);
    }
}

default
{
    changed(integer change)
    {
        if(change & CHANGED_TELEPORT)
        {
            if(intp) handletp();
        }
    }

    state_entry()
    {
        llListen(RLVRC, "", NULL_KEY, "");
        llListen(GAZE_CHAT_CHANNEL, "", NULL_KEY, "");
    }

    attach(key id)
    {
        if(id == NULL_KEY) llSetTimerEvent(0.0);
    }

    listen(integer c, string n, key id, string m)
    {
        if(c == RLVRC)
        {
            list params = llParseString2List(m, [","], []);
            if(llGetListLength(params) != 4) return;
            if((key)llList2String(params, 1) != llGetKey()) return;
            integer accept = llList2String(params, 3) == "ok";
            string identifier = llList2String(params, 0);
            string command = llList2String(params, 2);

            if(identifier == await)
            {
                if(await == "tpv")
                {
                    if(!accept)
                    {
                        vorecarrier = NULL_KEY;
                        vorevictim = NULL_KEY;
                        vorename = "";
                        intp = FALSE;
                    }
                    llSensorRemove();
                    llMessageLinked(LINK_SET, M_API_TPOK_V, "", NULL_KEY);
                }
                else if(await == "rv")
                {
                    key av = llGetOwnerKey(id);
                    if(accept)
                    {
                        llOwnerSay("Done re-eating.");
                        llSensorRemove();
                        intp = FALSE;
                    }
                    else
                    {
                        llOwnerSay("Could not re-eat.");
                        vorecarrier = NULL_KEY;
                        vorevictim = NULL_KEY;
                        vorename = "";
                        intp = FALSE;
                    }
                }
                else if(await == "cv")
                {
                    if(accept == TRUE)
                    {
                        llSleep(1.0);
                        if((llGetAgentInfo(target) & AGENT_SITTING) != 0)
                        {
                            string spoof;
                            spoof = llDumpList2String(llParseStringKeepNulls(vorespoof, ["%ME%"], []), owner);
                            spoof = llDumpList2String(llParseStringKeepNulls(spoof, ["%OBJ%"], []), foodname);
                            spoof = llDumpList2String(llParseStringKeepNulls(spoof, ["%VIC%"], []), lockedname);
                            llSay(0, spoof);
                            attachbelly();
                            llMessageLinked(LINK_SET, M_API_LOCK, "", NULL_KEY);
                        }
                        else llOwnerSay("Could not eat '" + lockedname + "'.");
                    }
                    else llOwnerSay("Could not eat '" + lockedname + "'.");
                    llRegionSayTo(vorecarrier, MANTRA_CHANNEL, "check");
                }
            }
        }
        else if(c == GAZE_CHAT_CHANNEL)
        {
            if(llGetOwnerKey(id) != vorevictim) return;
            llSetObjectName(objectprefix + foodname);
            llSay(0, m);
            llSetObjectName("");
        }
    }

    no_sensor()
    {
        llSensorRemove();
        vorecarrier = NULL_KEY;
        vorevictim = NULL_KEY;
        vorename = "";
        intp = FALSE;
        llMessageLinked(LINK_SET, M_API_SET_FILTER, "vore", (key)((string)FALSE));
        if(await == "tpv") llMessageLinked(LINK_SET, M_API_TPOK_V, "", NULL_KEY);
        await = "";
    }

    object_rez(key id)
    {
        if(llList2String(llGetObjectDetails(id, [OBJECT_NAME]), 0) != "carrier") return;
        vorecarrier = id;
        llSensorRepeat("", "3d6181b0-6a4b-97ef-18d8-722652995cf1", PASSIVE, 0.0, PI, 10.0);
        llSetObjectName("RLV Capture");
        if(intp)
        {
            llRegionSayTo(vorecarrier, MANTRA_CHANNEL, "acidlevel " + (string)fillfactor);
            llOwnerSay("Set stomach acid level to " + (string)fillfactor + "%");
            await = "rv";
            llRegionSayTo(target, RLVRC, "rv," + (string)target + ",@sit:" + (string)id + "=force");
        }
        else
        {
            fillfactor = 25;
            await = "cv";
            llRegionSayTo(target, RLVRC, "cv," + (string)target + ",@sit:" + (string)id + "=force");
            vorename = targetname;
            vorevictim = target;
        }
        llSetObjectName("");
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == M_API_HUD_STARTED)
        {
            llSetTimerEvent(0.5);
        }
        if(num == M_API_CONFIG_DONE) 
        {
            llOwnerSay("[" + llGetScriptName() + "]: " + (string)(llGetFreeMemory() / 1024.0) + "kb free.");
        }
        else if(num == M_API_CONFIG_DATA)
        {
            if(str == "name") owner = (string)id;
            else if(str == "objectprefix") objectprefix = (string)id + " ";
            else if(str == "food") foodname = (string)id;
            else if(str == "vore") vorespoof = (string)id;
            else if(str == "unvore") unvorespoof = (string)id;
        }
        else if(num == M_API_DOTP)
        {
            if(vorecarrier == NULL_KEY || (string)id == llGetRegionName()) llMessageLinked(LINK_SET, M_API_TPOK_V, "", NULL_KEY);
            else
            {
                intp = TRUE;
                llRegionSayTo(vorecarrier, MANTRA_CHANNEL, "abouttotp");
                await = "tpv";
                llRegionSayTo(vorevictim, RLVRC, "release," + (string)vorevictim + ",!release");
                llSleep(0.25);
                llRegionSayTo(vorevictim, RLVRC, "tpv," + (string)vorevictim + "," + str);
                llSensorRepeat("", "3d6181b0-6a4b-97ef-18d8-722652995cf1", PASSIVE, 0.0, PI, 10.0);
            }
        }
        else if(num == M_API_LOCK)
        {
            lockedavatar = id;
            lockedname = str;
        }
        else if(num == M_API_BUTTON_PRESSED)
        {
            if(str == "vore")
            {
                vore();
            }
            else if(str == "unvore")
            {
                unvore();
            }
            else if(str == "acid+")
            {
                fillfactor += 5;
                if(fillfactor > 100) fillfactor = 100;
                llRegionSayTo(vorecarrier, MANTRA_CHANNEL, "acidlevel " + (string)fillfactor);
                llOwnerSay("Set stomach acid level to " + (string)fillfactor + "%");
            }
            else if(str == "acid-")
            {
                fillfactor -= 5;
                if(fillfactor < 0) fillfactor = 0;
                llRegionSayTo(vorecarrier, MANTRA_CHANNEL, "acidlevel " + (string)fillfactor);
                llOwnerSay("Set stomach acid level to " + (string)fillfactor + "%");
            }
        }
    }

    timer()
    {
        llSetTimerEvent(0.0);
        if(!intp)
        {
            list req = llGetObjectDetails(vorecarrier, [OBJECT_CREATOR]);
            if(req == [] || llList2Key(req, 0) != llGetCreator())
            {
                detachbelly();
                vorecarrier = NULL_KEY;
                vorevictim = NULL_KEY;
                vorename = NULL_KEY;
            }
            if(vorecarrier != NULL_KEY) llMessageLinked(LINK_SET, M_API_SET_FILTER, "vore", (key)((string)TRUE));
            else                        llMessageLinked(LINK_SET, M_API_SET_FILTER, "vore", (key)((string)FALSE));
        }
        llSetTimerEvent(0.5);
    }
}