#include <IT/globals.lsl>

string owner = "";
string objectprefix = "";
string foodname = "Food";
key lockedavatar = NULL_KEY;
string lockedname = "";
key vorecarrier = NULL_KEY;
string voreurl = "null";
key vorevictim = NULL_KEY;
string vorename = "";
key target;
string targetname;
string await;
integer fillfactor = 25;
integer filter = FALSE;
integer configured = FALSE;
key buffered = NULL_KEY;
integer timermode = 0;
string lastregion;
integer countdown = 0;

detachbelly()
{
    llOwnerSay("@detach:~IT/vore/on=force");
    llOwnerSay("@attachover:~IT/vore/off=force");
    bellypercent(-1, fillfactor);
}

attachbelly()
{
    llOwnerSay("@detach:~IT/vore/off=force");
    llOwnerSay("@attachover:~IT/vore/on=force");
    bellypercent(fillfactor, -1);
}

bellypercent(integer old, integer new)
{
    if(old != -1) llOwnerSay("@detach:~IT/vore/" + (string)old + "=force");
    if(new != -1) llOwnerSay("@attachover:~IT/vore/" + (string)new + "=force");
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
    llMessageLinked(LINK_SET, M_API_SPOOF, "vorerelease", (key)(owner + "|||" + foodname + "|||" + vorename));
    llRegionSayTo(vorecarrier, MANTRA_CHANNEL, "unsit");
    vorecarrier = NULL_KEY;
    vorevictim = NULL_KEY;
    voreurl = "null";
    vorename = "";
}

vore()
{
    if(lockedavatar == llGetOwner()) return;
    llSetObjectName("");

    if(!canrez(llGetPos()))
    {
        llOwnerSay("Can't rez here, trying to set land group.");
        llOwnerSay("@setgroup:" + (string)llList2Key(llGetParcelDetails(llGetPos(), [PARCEL_DETAILS_GROUP]), 0) + "=force");
        llSleep(2.5);
    }

    if(!canrez(llGetPos()))
    {
        llOwnerSay("Can't rez here. Not eating.");
        llSetObjectName(master_base);
        return;
    }

    llOwnerSay("Eating '" + lockedname + "'.");
    llSetObjectName(master_base);
    target = lockedavatar;
    targetname = lockedname;
    llRezAtRoot("carrier", llGetPos(), ZERO_VECTOR, ZERO_ROTATION, 1);
}

voredirect(string carrier, key who)
{
    if(vorecarrier != NULL_KEY) return;

    // We ignore the "carrier" argument for now. We don't have full multiple carrier support yet.

    llSetObjectName("");

    target = who;
    targetname = llGetDisplayName(who);
    llSetObjectName("");
    llOwnerSay("Automatically eating '" + targetname + "' because of an EZPlay Relay request.");

    if(!canrez(llGetPos()))
    {
        llOwnerSay("Can't rez here, trying to set land group.");
        llOwnerSay("@setgroup:" + (string)llList2Key(llGetParcelDetails(llGetPos(), [PARCEL_DETAILS_GROUP]), 0) + "=force");
        llSleep(2.5);
    }

    if(!canrez(llGetPos()))
    {
        llOwnerSay("Can't rez here. Not eating.");
        llSetObjectName(master_base);
        return;
    }

    llSetObjectName(master_base);
    llRezAtRoot("carrier", llGetPos(), ZERO_VECTOR, ZERO_ROTATION, 1);
}

default
{
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

            if(identifier == await && await == "cv")
            {
                key creator = llList2Key(llGetObjectDetails(id, [OBJECT_CREATOR]), 0);
                if((string)creator == "bc50a813-5b31-4cbe-9ae6-0031d1b7d53e" && accept == FALSE) return;
                if(accept == TRUE)
                {
                    llMessageLinked(LINK_SET, M_API_SPOOF, "vorecapture", (key)(owner + "|||" + foodname + "|||" + vorename));
                    attachbelly();
                }
                else
                {
                    llSetObjectName("");
                    llOwnerSay("Could not eat '" + lockedname + "'. RLV Permission denied.");
                    llSetObjectName(master_base);
                }
                llRegionSayTo(vorecarrier, MANTRA_CHANNEL, "check");
                await = "";
            }
        }
        else if(c == GAZE_CHAT_CHANNEL)
        {
            if(llGetOwnerKey(id) != vorevictim) return;
            llSetObjectName(objectprefix + foodname);
            llSay(0, m);
            llSetObjectName(master_base);
        }
        else if(c == MANTRA_CHANNEL)
        {
            if(startswith(m, "objurl"))
            {
                m = llDeleteSubString(m, 0, llStringLength("objurl"));
                if(vorecarrier == id) voreurl = m;
            }
            else if(startswith(m, "vorerequest|||"))
            {
                m = llStringTrim(llList2String(llParseString2List(m, ["|||"], []), 1), STRING_TRIM);
                voredirect(m, llGetOwnerKey(id));
            }
        }
    }

    object_rez(key id)
    {
        if(llList2String(llGetObjectDetails(id, [OBJECT_NAME]), 0) != "carrier") return;
        vorecarrier = id;
        vorename = targetname;
        vorevictim = target;
        voreurl = "null";
        if(timermode == 0)
        {
            fillfactor = 25;
            await = "cv";
        }
        else
        {
            llSetObjectName("");
            llOwnerSay("Done re-eating!");
            llSetObjectName(master_base);
            timermode = 0;
            llSetTimerEvent(2.5);
        }
        llRegionSayTo(id, MANTRA_CHANNEL, "sit " + (string)target);
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == M_API_CONFIG_DONE)
        {
            llSetTimerEvent(2.5);
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
            }
            if(str == "name")
            {
                owner = (string)id;
                if(owner == "" || owner == "Avatar") owner = guessname();
            }
            else if(str == "objectprefix")
            {
                objectprefix = (string)id + " ";
                if(objectprefix == " " || objectprefix == "Avatar's ") objectprefix = guessprefix();
            }
            else if(str == "food") foodname = (string)id;
        }
        else if(num == M_API_LOCK)
        {
            lockedavatar = id;
            lockedname = str;
        }
        else if(num == M_API_BUTTON_PRESSED)
        {
            if(timermode != 0) return;
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
                integer old = fillfactor;
                fillfactor += 5;
                if(fillfactor > 100)
                {
                    fillfactor = 100;
                    llRegionSayTo(vorecarrier, MANTRA_CHANNEL, "dissolve");
                    llSetObjectName("");
                    llOwnerSay("Your " + foodname + " has been fully digested.");
                    llSetObjectName(master_base);
                }
                else
                {
                    llRegionSayTo(vorecarrier, MANTRA_CHANNEL, "acidlevel " + (string)fillfactor);
                    llSetObjectName("");
                    llOwnerSay("Set stomach acid level to " + (string)fillfactor + "%");
                    llSetObjectName(master_base);
                }
                if(old != fillfactor) bellypercent(old, fillfactor);
            }
            else if(str == "acid-")
            {
                integer old = fillfactor;
                fillfactor -= 5;
                if(fillfactor < 0) fillfactor = 0;
                llRegionSayTo(vorecarrier, MANTRA_CHANNEL, "acidlevel " + (string)fillfactor);
                llSetObjectName("");
                llOwnerSay("Set stomach acid level to " + (string)fillfactor + "%");
                llSetObjectName(master_base);
                if(old != fillfactor) bellypercent(old, fillfactor);
            }
        }
    }

    timer()
    {
        llSetTimerEvent(0.0);
        if(timermode == 0)
        {
            integer differentRegion = lastregion != llGetRegionName();
            list req = llGetObjectDetails(vorecarrier, [OBJECT_CREATOR]);
            if(vorecarrier != NULL_KEY && (req == [] || llList2Key(req, 0) != llGetCreator()))
            {
                if(differentRegion)
                {
                    timermode = 1;
                    buffered = NULL_KEY;
                    jump timermode1;
                }
                else if(buffered == vorecarrier)
                {
                    detachbelly();
                    vorecarrier = NULL_KEY;
                    vorevictim = NULL_KEY;
                    vorename = "";
                    voreurl = "null";
                }
                else
                {
                    buffered = vorecarrier;
                }
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

            llSetTimerEvent(2.5);
            lastregion = llGetRegionName();
            return;
            @timermode1;
            llSetTimerEvent(0.5);
        }
        else if(timermode == 1)
        {
            vector pos = llGetPos();
            string region = llGetRegionName();
            if(!canrez(llGetPos()))
            {
                llSetObjectName("");
                llOwnerSay("Can't rez here, trying to set land group.");
                llSetObjectName(master_base);
                llOwnerSay("@setgroup:" + (string)llList2Key(llGetParcelDetails(llGetPos(), [PARCEL_DETAILS_GROUP]), 0) + "=force");
                llSleep(2.5);
            }

            integer teleportothers = canrez(llGetPos());
            llSetObjectName("");
            if(teleportothers) llOwnerSay("Fetching your vore victim and giving them 30 seconds to arrive...");
            else               llOwnerSay("Can't rez here, not fetching your vore victim...");
            llSetObjectName(master_base);

            if(voreurl == "null")
            {
                detachbelly();
                vorecarrier = NULL_KEY;
                vorevictim = NULL_KEY;
                vorename = "";
            }
            else
            {
                if(teleportothers) llHTTPRequest(voreurl, [HTTP_METHOD, "POST"], region + "/" + (string)llRound(pos.x) + "/" + (string)llRound(pos.y)+ "/" + (string)llRound(pos.z));
                else               llHTTPRequest(voreurl, [HTTP_METHOD, "POST"], "die");
            }

            if(teleportothers)
            {
                timermode = 2;
                countdown = 11;
                llSetTimerEvent(3.0);
            }
            else
            {
                timermode = 0;
                llSetTimerEvent(2.5);
            }
        }
        else if(timermode == 2)
        {
            if(countdown > 0)
            {
                countdown--;

                integer arrived = llListFindList(llGetAgentList(AGENT_LIST_REGION, []), [vorevictim]);

                if(arrived != -1)
                {
                    countdown = 0;
                    llSleep(5.0);
                }

                if(countdown != 0) llSetTimerEvent(3.0);
            }

            if(countdown == 0)
            {
                if(llGetAgentSize(vorevictim) == ZERO_VECTOR)
                {
                    detachbelly();
                    vorecarrier = NULL_KEY;
                    vorevictim = NULL_KEY;
                    vorename = "";
                    voreurl = "null";
                }

                if(vorecarrier == NULL_KEY)
                {
                    llSetObjectName("");
                    llOwnerSay("Your vore victim didn't arrive in time.");
                    llSetObjectName(master_base);
                    timermode = 0;
                    llSetTimerEvent(2.5);
                }
                else
                {
                    llSetObjectName("");
                    llOwnerSay("Re-eating " + vorename + "...");
                    llSetObjectName(master_base);
                    timermode = 3;
                    target = vorevictim;
                    targetname = vorename;
                    llRezAtRoot("carrier", llGetPos(), ZERO_VECTOR, ZERO_ROTATION, 1);
                    llSetTimerEvent(10.0);
                }
            }
        }
        else if(timermode == 3)
        {
            llOwnerSay("Could not re-eat!");
            llSetObjectName(master_base);
            timermode = 0;
            llSetTimerEvent(2.5);
        }

        lastregion = llGetRegionName();
    }
}
