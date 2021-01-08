#include <IT/globals.lsl>

string owner = "";
string objectprefix = "";
string foodname = "Food";
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
integer filter = FALSE;
integer configured = FALSE;

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
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
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
                if(await == "rv")
                {
                    key av = llGetOwnerKey(id);
                    if(accept)
                    {
                        llOwnerSay("Done re-eating.");
                        sensortimer(0.0);
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
                    sensortimer(0.0);
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
                        }
                        else llOwnerSay("Could not eat '" + lockedname + "'.");
                    }
                    else llOwnerSay("Could not eat '" + lockedname + "'.");
                    llRegionSayTo(vorecarrier, MANTRA_CHANNEL, "check");
                    await = "";
                }
            }
        }
        else if(c == MANTRA_CHANNEL)
        {
            if(startswith(m, "rlvresponse") && id == vorecarrier)
            {
                sensortimer(0.0);
                llMessageLinked(LINK_SET, M_API_TPOK_V, "", NULL_KEY);
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
        sensortimer(0.0);
        vorecarrier = NULL_KEY;
        vorevictim = NULL_KEY;
        vorename = "";
        intp = FALSE;
        if(filter)
        {
            filter = FALSE;
            llMessageLinked(LINK_SET, M_API_SET_FILTER, "vore", (key)((string)filter));
        }
        if(await != "rv" && await != "cv") llMessageLinked(LINK_SET, M_API_TPOK_V, "", NULL_KEY);
        await = "";
    }

    object_rez(key id)
    {
        if(llList2String(llGetObjectDetails(id, [OBJECT_NAME]), 0) != "carrier") return;
        vorecarrier = id;
        sensortimer(60.0);
        llSetObjectName("RLV Capture");
        if(intp)
        {
            llRegionSayTo(vorecarrier, MANTRA_CHANNEL, "acidlevel " + (string)fillfactor);
            llOwnerSay("Set stomach acid level to " + (string)fillfactor + "%");
            await = "rv";
            llRegionSayTo(target, RLVRC, "rv," + (string)target + ",@sit:" + (string)id + "=force|!x-handover/" + (string)id + "/0|!release");
        }
        else
        {
            fillfactor = 25;
            await = "cv";
            llRegionSayTo(target, RLVRC, "cv," + (string)target + ",@sit:" + (string)id + "=force|!x-handover/" + (string)id + "/0|!release");
            vorename = targetname;
            vorevictim = target;
        }
        llSetObjectName("");
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == M_API_CONFIG_DONE) 
        {
            llSetTimerEvent(0.5);
            configured = TRUE;
        }
        else if(num == M_API_CONFIG_DATA)
        {
            if(configured)
            {
                configured = FALSE;
                owner = "";
                objectprefix = "";
                foodname = "Food";
                vorespoof = "";
                unvorespoof = "";
            }
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
                await = "";
                llRegionSayTo(vorecarrier, MANTRA_CHANNEL, "rlvforward " + str);
                sensortimer(10.0);
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
                if(fillfactor > 100)
                {
                    fillfactor = 100;
                    llRegionSayTo(vorecarrier, MANTRA_CHANNEL, "dissolve");
                    llOwnerSay("Your " + foodname + " has been fully digested.");
                }
                else
                {
                    llRegionSayTo(vorecarrier, MANTRA_CHANNEL, "acidlevel " + (string)fillfactor);
                    llOwnerSay("Set stomach acid level to " + (string)fillfactor + "%");
                }
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
            if(vorecarrier != NULL_KEY && (req == [] || llList2Key(req, 0) != llGetCreator()))
            {
                detachbelly();
                vorecarrier = NULL_KEY;
                vorevictim = NULL_KEY;
                vorename = "";
            }
            if(vorecarrier != NULL_KEY)
            {
                if(!filter)
                {
                    filter = TRUE;
                    llMessageLinked(LINK_SET, M_API_SET_FILTER, "vore", (key)((string)filter));
                }
            }
            else
            {
                if(filter)
                {
                    filter = FALSE;
                    llMessageLinked(LINK_SET, M_API_SET_FILTER, "vore", (key)((string)filter));
                }
            }
        }
        llSetTimerEvent(0.5);
    }
}