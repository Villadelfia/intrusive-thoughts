#include <IT/globals.lsl>

integer ready = FALSE;
string owner = "";
string objectprefix = "";
string capturespoof = "";
string releasespoof = "";
string putonspoof = "";
string putdownspoof = "";
key lastseenavatar = NULL_KEY;
string lastseenavatarname = " ";
key lastseenobject = NULL_KEY;
string lastseenobjectname = " ";
key lockedavatar = NULL_KEY;
string lockedname = "";
key target;
string targetname;
string targetdescription;
list objectifiedavatars = [];
list objectifiednames = [];
list objectifieddescriptions = [];
list objectifiedballs = [];
list responses = [];
string await = "";
integer intp = FALSE;
integer handling;
integer store = -1;
string storingon;
integer disabled = FALSE;
key closestavatar = NULL_KEY;
integer hideopt = 1;
key lastrezzed;

detachobject(string o)
{
    if(o == "") return;
    llOwnerSay("@detach:~IT/" + llToLower(o) + "=force");
}

attachobject(string o)
{
    if(o == "") return;
    llOwnerSay("@attachover:~IT/" + llToLower(o) + "=force");
}

updatetitle()
{
    if(disabled) return;
    if(lockedavatar)
    {
        llSetText("« " + lockedname + " »\n" + lastseenobjectname + "\n \n \n \n \n \n ", <1.0, 1.0, 0.0>, 1.0);
    }
    else
    {
        llSetText(lastseenavatarname + "\n" + lastseenobjectname + "\n \n \n \n \n \n ", <1.0, 1.0, 0.0>, 1.0);
    }
}

integer canrez(vector pos)
{
    integer flags = llGetParcelFlags(pos);
    if(flags & PARCEL_FLAG_ALLOW_CREATE_OBJECTS) return TRUE;
    list details = llGetParcelDetails(pos, [PARCEL_DETAILS_OWNER, PARCEL_DETAILS_GROUP]);
    if(llList2Key(details, 0) == llGetOwner()) return TRUE;
    return(flags & PARCEL_FLAG_ALLOW_CREATE_GROUP_OBJECTS) && llSameGroup(llList2Key(details, 1));
}

givemenu()
{
    llOwnerSay("Intrusive Thoughts Controller Menu:");
    if(lockedavatar != NULL_KEY) llOwnerSay("Locked avatar: " + lockedname);
    else                         llOwnerSay("Locked avatar: -no avatar-");
    llOwnerSay("Last seen avatar: " + lastseenavatarname);
    llOwnerSay("Last seen object: " + lastseenobjectname);
    llOwnerSay(" ");
    llOwnerSay("Objectification options:");
    llOwnerSay("[secondlife:///app/chat/" + (string)GAZE_CHANNEL + "/transfer Take stored object from last seen object]");
    llOwnerSay(" ");
    llOwnerSay("[secondlife:///app/chat/" + (string)GAZE_CHANNEL + "/capture Objectify the locked avatar]");
    llOwnerSay("—or— manually type /1capture <objectname>");
    integer l = llGetListLength(objectifiednames)-1;
    if(l >= 0) llOwnerSay(" ");
    while(l >= 0)
    {
        llOwnerSay("[secondlife:///app/chat/" + (string)GAZE_CHANNEL + "/release%20" + (string)l + " Release " + llList2String(objectifiednames, l) + " (" + objectprefix + llList2String(objectifieddescriptions, l)+ ")] " + 
                   "[secondlife:///app/chat/" + (string)GAZE_CHANNEL + "/edit%20" + (string)l + " (edit position)] " +
                   "[secondlife:///app/chat/" + (string)GAZE_CHANNEL + "/transfer%20" + (string)l + " (store object)]");
        l--;
    }
    if(llGetListLength(objectifiednames) > 1) 
    {
        llOwnerSay(" ");
        llOwnerSay("[secondlife:///app/chat/" + (string)GAZE_CHANNEL + "/releaseall Release everyone]");
    }
    llOwnerSay(" ");
    llMessageLinked(LINK_SET, API_GIVE_VORE_MENU, "", NULL_KEY);
}

release(integer i)
{
    detachobject(llList2String(objectifieddescriptions, i));
    string spoof;
    spoof = llDumpList2String(llParseStringKeepNulls(releasespoof, ["%ME%"], []), owner);
    spoof = llDumpList2String(llParseStringKeepNulls(spoof, ["%OBJ%"], []), llList2String(objectifieddescriptions, i));
    spoof = llDumpList2String(llParseStringKeepNulls(spoof, ["%VIC%"], []), llList2String(objectifiednames, i));
    llSay(0, spoof);
    llRegionSayTo(llList2Key(objectifiedballs, i), MANTRA_CHANNEL, "unsit");
    llRegionSayTo(llList2Key(objectifiedavatars, i), RLVRC, "release," + (string)llList2Key(objectifiedavatars, i) + ",!release");
    objectifiednames = llDeleteSubList(objectifiednames, i, i);
    objectifiedavatars = llDeleteSubList(objectifiedavatars, i, i);
    objectifiedballs = llDeleteSubList(objectifiedballs, i, i);
    objectifieddescriptions = llDeleteSubList(objectifieddescriptions, i, i);
}

releaseall()
{
    integer l = llGetListLength(objectifiedballs) - 1;
    while(l >= 0)
    {
        release(l);
        l--;
    }
}

addobject(string desc)
{
    if(lockedavatar == llGetOwner()) return;
    if(lockedavatar == NULL_KEY) return;
    if(desc == "") desc = "object";
    targetdescription = desc;
    
    if(!canrez(llGetPos()))
    {
        llOwnerSay("Can't rez here, trying to set land group.");
        llOwnerSay("@setgroup:" + (string)llList2Key(llGetParcelDetails(llGetPos(), [PARCEL_DETAILS_GROUP]), 0) + "=force");
        llSleep(2.5);
    }

    if(!canrez(llGetPos())) 
    {
        llOwnerSay("Can't rez here. Not capturing.");
        return;
    }

    llOwnerSay("Capturing '" + lockedname + "'.");
    target = lockedavatar;
    targetname = lockedname;
    llRezAtRoot("ball", llGetPos() - <0.0, 0.0, 3.0>, ZERO_VECTOR, ZERO_ROTATION, hideopt);
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
        objectifiedavatars = [];
        objectifiednames = [];
        objectifiedballs = [];
        objectifieddescriptions = [];
        intp = FALSE;
    }
    else
    {
        if(handling == 0)
        {
            if(delayed)
            {
                llOwnerSay("Recapturing everyone.");
            }
            else
            {
                llOwnerSay("Recapturing everyone in 10 seconds.");
                llSleep(10.0);
            }
        }
        if(handling < llGetListLength(objectifiedavatars))
        {
            target = llList2Key(objectifiedavatars, handling);
            llRezAtRoot("ball", llGetPos() - <0.0, 0.0, 3.0>, ZERO_VECTOR, ZERO_ROTATION, hideopt);
        }
    }
}

default
{
    changed(integer change)
    {
        if(change & CHANGED_OWNER) llResetScript();
        if(change & CHANGED_TELEPORT)
        {
            if(intp)
            {
                handling = 0;
                objectifiedballs = [];
                responses = [];
                handletp();
            }
        }
    }

    attach(key id)
    {
        if(id != NULL_KEY)
        {
            lastseenavatar = NULL_KEY;
            lastseenavatarname = " ";
            lastseenobject = NULL_KEY;
            lastseenobjectname = " ";
            lockedavatar = NULL_KEY;
            lockedname = "";
            objectifiedavatars = [];
            objectifiednames = [];
            objectifiedballs = [];
            objectifieddescriptions = [];
            intp = FALSE;
            llSetTimerEvent(0.5);
        }
        else               
        {
            llSetTimerEvent(0.0);
            llSetText("", <1.0, 1.0, 0.0>, 1.0);
        }
    }

    state_entry()
    {
        llSetTimerEvent(0.5);
    }

    listen(integer c, string n, key id, string m)
    {
        if(c == GAZE_CHANNEL)
        {
            if(m == "capture")
            {
                addobject("");
            }
            else if(startswith(llToLower(m), "capture"))
            {
                addobject(llDeleteSubString(m, 0, llStringLength("capture")));
            }
            else if(m == "releaseall")
            {
                releaseall();
            }
            else if(startswith(llToLower(m), "release"))
            {
                release((integer)llDeleteSubString(m, 0, llStringLength("release")));
            }
            else if(startswith(llToLower(m), "edit"))
            {
                integer i = (integer)llDeleteSubString(m, 0, llStringLength("edit"));
                llRegionSayTo(llList2Key(objectifiedballs, i), MANTRA_CHANNEL, "edit");
            }
            else if(m == "transfer")
            {
                store = -1;
                llRegionSayTo(lastseenobject, MANTRA_CHANNEL, "furniture");
            }
            else if(startswith(llToLower(m), "transfer"))
            {
                store = (integer)llDeleteSubString(m, 0, llStringLength("transfer"));
                llRegionSayTo(lastseenobject, MANTRA_CHANNEL, "furniture");
            }
            else if(m == "leashto")
            {
                llRegionSayTo(lockedavatar, MANTRA_CHANNEL, "leashto " + (string)lastseenobject);
            }
            else if(m == "clear")
            {
                llRegionSayTo(lockedavatar, MANTRA_CHANNEL, "CLEAR");
            }
            else if(m == "forceclear")
            {
                llRegionSayTo(lockedavatar, MANTRA_CHANNEL, "FORCECLEAR");
            }
            else if(m == "resetrelay")
            {
                llRegionSayTo(lockedavatar, MANTRA_CHANNEL, "RESETRELAY");
            }
        }
        else if(c == MANTRA_CHANNEL)
        {
            if(startswith(m, "furniture"))
            {
                storingon = n;
                if(store == -1)
                {
                    if(m == "furniture 0") llOwnerSay("No object is stored in '" + n + "'.");
                    else
                    {
                        llOwnerSay("Taking object from '" + n + "'.");
                        llRegionSayTo(id, MANTRA_CHANNEL, "puton");
                    }
                }
                else
                {
                    detachobject(llList2String(objectifieddescriptions, store));
                    string spoof;
                    spoof = llDumpList2String(llParseStringKeepNulls(putdownspoof, ["%ME%"], []), owner);
                    spoof = llDumpList2String(llParseStringKeepNulls(spoof, ["%OBJ%"], []), llList2String(objectifieddescriptions, store));
                    spoof = llDumpList2String(llParseStringKeepNulls(spoof, ["%VIC%"], []), llList2String(objectifiednames, store));
                    spoof = llDumpList2String(llParseStringKeepNulls(spoof, ["%TAR%"], []), n);
                    llSay(0, spoof);
                    llRegionSayTo(id, MANTRA_CHANNEL, "putdown " + (string)llList2Key(objectifiedballs, store) + "|||" + llList2String(objectifieddescriptions, store));
                    objectifiednames = llDeleteSubList(objectifiednames, store, store);
                    objectifiedavatars = llDeleteSubList(objectifiedavatars, store, store);
                    objectifiedballs = llDeleteSubList(objectifiedballs, store, store);
                    objectifieddescriptions = llDeleteSubList(objectifieddescriptions, store, store);
                }
            }
            else if(startswith(m, "puton"))
            {
                list params = llParseString2List(llDeleteSubString(m, 0, llStringLength("puton")), ["|||"], []);
                key av = (key)llList2String(params, 0);
                string desc = llList2String(params, 1);
                attachobject(desc);
                string spoof;
                spoof = llDumpList2String(llParseStringKeepNulls(putonspoof, ["%ME%"], []), owner);
                spoof = llDumpList2String(llParseStringKeepNulls(spoof, ["%OBJ%"], []), desc);
                spoof = llDumpList2String(llParseStringKeepNulls(spoof, ["%VIC%"], []), llGetDisplayName(av));
                spoof = llDumpList2String(llParseStringKeepNulls(spoof, ["%TAR%"], []), storingon);
                llSay(0, spoof);
                objectifiedballs += [id];
                objectifiedavatars += [av];
                objectifiednames += [llGetDisplayName(av)];
                objectifieddescriptions += [desc];
            }
        }
        else if(c == RLVRC)
        {
            list params = llParseString2List(m, [","], []);
            if(llGetListLength(params) != 4) return;
            if((key)llList2String(params, 1) != llGetKey()) return;
            integer accept = llList2String(params, 3) == "ok";
            string identifier = llList2String(params, 0);
            string command = llList2String(params, 2);

            if(identifier == await)
            {
                if(await == "dotp" && startswith(command, "@tpto"))
                {
                    key av = llGetOwnerKey(id);
                    if(accept)
                    {
                        responses += [id];
                    }
                    else
                    {
                        integer i = llListFindList(objectifiedavatars, [av]);
                        objectifiednames = llDeleteSubList(objectifiednames, i, i);
                        objectifiedavatars = llDeleteSubList(objectifiedavatars, i, i);
                        objectifiedballs = llDeleteSubList(objectifiedballs, i, i);
                        objectifieddescriptions = llDeleteSubList(objectifieddescriptions, i, i);
                    }
                    if(llGetListLength(responses) == llGetListLength(objectifiedavatars))
                    {
                        llSensorRemove();
                        if(responses == []) intp = FALSE;
                        llMessageLinked(LINK_SET, API_TPOK_G, "", NULL_KEY);
                    }
                }
                else if(await == "r")
                {
                    key av = llGetOwnerKey(id);
                    integer i = llListFindList(objectifiedavatars, [av]);
                    if(accept)
                    {
                        responses += [0];
                        llRegionSayTo(llList2Key(objectifiedballs, i), MANTRA_CHANNEL, "check");
                    }
                    else
                    {
                        objectifiednames = llDeleteSubList(objectifiednames, i, i);
                        objectifiedavatars = llDeleteSubList(objectifiedavatars, i, i);
                        objectifiedballs = llDeleteSubList(objectifiedballs, i, i);
                        objectifieddescriptions = llDeleteSubList(objectifieddescriptions, i, i);
                    }
                    if(llGetListLength(responses) == llGetListLength(objectifiedavatars))
                    {
                        llOwnerSay("Done recapturing.");
                        llSensorRemove();
                        intp = FALSE;
                    }
                }
                else if(await == "c")
                {
                    if(accept == TRUE)
                    {
                        llSleep(1.0);
                        if((llGetAgentInfo(target) & AGENT_SITTING) != 0)
                        {
                            string spoof;
                            spoof = llDumpList2String(llParseStringKeepNulls(capturespoof, ["%ME%"], []), owner);
                            spoof = llDumpList2String(llParseStringKeepNulls(spoof, ["%OBJ%"], []), targetdescription);
                            spoof = llDumpList2String(llParseStringKeepNulls(spoof, ["%VIC%"], []), lockedname);
                            llSay(0, spoof);
                            attachobject(targetdescription);
                            llMessageLinked(LINK_SET, API_SET_LOCK, "", NULL_KEY);
                        }
                        else llOwnerSay("Could not capture '" + lockedname + "'.");
                    }
                    else llOwnerSay("Could not capture '" + lockedname + "'.");
                    llRegionSayTo(lastrezzed, MANTRA_CHANNEL, "check");
                }
            }
        }
        else if(c == GAZE_CHAT_CHANNEL)
        {
            integer i = llListFindList(objectifiedavatars, [id]);
            string obj = llList2String(objectifieddescriptions, i);
            if(i == -1) return;
            
            llSetObjectName(objectprefix + obj);
            if(llToLower(llStringTrim(m, STRING_TRIM)) != "/me" && startswith(m, "/me") == TRUE && contains(m, "\"") == FALSE) llSay(0, m);
            else 
            {
                integer n = llGetListLength(objectifiedavatars);
                while(~--n)
                {
                    llRegionSayTo(llList2Key(objectifiedavatars, n), 0, m);
                }
                llOwnerSay(m);
            }
            llSetObjectName("");
        }
    }

    no_sensor()
    {
        llSensorRemove();
        if(await == "dotp")
        {
            integer l = llGetListLength(objectifiedavatars)-1;
            while(l >= 0)
            {
                if(llListFindList(responses, [llList2Key(objectifiedavatars, l)]) == -1)
                {
                    objectifiednames = llDeleteSubList(objectifiednames, l, l);
                    objectifiedavatars = llDeleteSubList(objectifiedavatars, l, l);
                    objectifiedballs = llDeleteSubList(objectifiedballs, l, l);
                    objectifieddescriptions = llDeleteSubList(objectifieddescriptions, l, l);
                }
                --l;
            }
            await = "";
            if(responses == []) intp = FALSE;
            llMessageLinked(LINK_SET, API_TPOK_G, "", NULL_KEY);
        }
        else if(await == "r")
        {
            llOwnerSay("Done recapturing.");
            integer l = llGetListLength(objectifiedavatars)-1;
            while(l >= 0)
            {
                if(llListFindList(responses, [llList2Key(objectifiedavatars, l)]) == -1)
                {
                    objectifiednames = llDeleteSubList(objectifiednames, l, l);
                    objectifiedavatars = llDeleteSubList(objectifiedavatars, l, l);
                    objectifiedballs = llDeleteSubList(objectifiedballs, l, l);
                    objectifieddescriptions = llDeleteSubList(objectifieddescriptions, l, l);
                }
                --l;
            }
            await = "";
            intp = FALSE;
        }
    }

    touch_start(integer total_number)
    {
        string name = llGetLinkName(llDetectedLinkNumber(0));
        if(name == "lock")
        {
            if(lockedavatar == NULL_KEY && lastseenavatar != NULL_KEY)
            {
                llMessageLinked(LINK_SET, API_SET_LOCK, lastseenavatarname, lastseenavatar);
            }
            else if(lockedavatar != NULL_KEY)
            {
                llMessageLinked(LINK_SET, API_SET_LOCK, "", NULL_KEY);
            }
        }
        else if(name == "sit")
        {
            if(lockedavatar != NULL_KEY && llGetAgentSize(lockedavatar) != ZERO_VECTOR && lastseenobject != NULL_KEY)
            {
                llOwnerSay("Sitting '" + lockedname + "' on '" + lastseenobjectname + "'.");
                llSetObjectName("RLV Sit");
                if(lockedavatar == llGetOwner()) llOwnerSay("@sit:" + (string)lastseenobject + "=force");
                else                             llRegionSayTo(lockedavatar, RLVRC, "s," + (string)lockedavatar + ",@sit:" + (string)lastseenobject + "=force");
                llSetObjectName("");
            }
        }
        else if(name == "objectify" && ready == TRUE)
        {
            givemenu();
        }
    }

    object_rez(key id)
    {
        if(llList2String(llGetObjectDetails(id, [OBJECT_NAME]), 0) != "ball") return;
        lastrezzed = id;
        llSensorRepeat("", "3d6181b0-6a4b-97ef-18d8-722652995cf1", PASSIVE, 0.0, PI, 10.0);
        llSetObjectName("RLV Capture");
        if(intp)
        {
            llOwnerSay("Recapturing " + llList2String(objectifiednames, handling-1) + ".");
            await = "r";
            llRegionSayTo(target, RLVRC, "r," + (string)target + ",@sit:" + (string)id + "=force");
            objectifiedballs += [id];
            handling++;
            handletp();
        }
        else
        {
            await = "c";
            llRegionSayTo(target, RLVRC, "c," + (string)target + ",@sit:" + (string)id + "=force");
            objectifiedballs += [id];
            objectifiedavatars += [target];
            objectifiednames += [targetname];
            objectifieddescriptions += [targetdescription];
        }
        llSetObjectName("");
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == API_STARTUP_DONE) 
        {
            llListen(GAZE_CHANNEL, "", llGetOwner(), "");
            llListen(RLVRC, "", NULL_KEY, "");
            llListen(GAZE_CHAT_CHANNEL, "", NULL_KEY, "");
            llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
            llSetTimerEvent(0.5);
            ready = TRUE;
            llOwnerSay("[" + llGetScriptName() + "]: " + (string)(llGetFreeMemory() / 1024.0) + "kb free.");
        }
        else if(num == API_DOTP)
        {
            if(objectifiedavatars == [] || (string)id == llGetRegionName()) llMessageLinked(LINK_SET, API_TPOK_G, "", NULL_KEY);
            else
            {
                intp = TRUE;
                responses = [];
                integer l = llGetListLength(objectifiedavatars) - 1;
                while(l >= 0)
                {
                    key av = llList2Key(objectifiedavatars, l);
                    llRegionSayTo(llList2Key(objectifiedballs, l), MANTRA_CHANNEL, "abouttotp");
                    await = "dotp";
                    llRegionSayTo(av, RLVRC, "release," + (string)av + ",!release");
                    llSleep(0.25);
                    llRegionSayTo(av, RLVRC, "dotp," + (string)av + "," + str);
                    --l;
                }
                llSensorRepeat("", "3d6181b0-6a4b-97ef-18d8-722652995cf1", PASSIVE, 0.0, PI, 10.0);
            }
        }
        else if(num == API_CONFIG_DATA)
        {
            if(str == "name") owner = (string)id;
            else if(str == "objectprefix") objectprefix = (string)id + " ";
            else if(str == "capture") capturespoof = (string)id;
            else if(str == "release") releasespoof = (string)id;
            else if(str == "puton") putonspoof = (string)id;
            else if(str == "putdown") putdownspoof = (string)id;
            else if(str == "ball") hideopt = (integer)((string)id);
        }
        else if(num == API_ENABLE) disabled = FALSE;
        else if(num == API_DISABLE) disabled = TRUE;
        else if(num == API_CLOSEST_TO_CAM)
        {
            lastseenavatar = id;
            lastseenavatarname = str;
        }
        else if(num == API_CLOSEST_OBJ)
        {
            lastseenobject = id;
            lastseenobjectname = str;
        }
        else if(num == API_SET_LOCK)
        {
            lockedavatar = id;
            lockedname = str;
        }
    }

    timer()
    {
        llSetTimerEvent(0.0);

        if(lockedavatar != NULL_KEY && llGetAgentSize(lockedavatar) == ZERO_VECTOR) llMessageLinked(LINK_SET, API_SET_LOCK, "", NULL_KEY);

        if(!intp)
        {
            integer l = llGetListLength(objectifiedballs) - 1;
            while(l >= 0)
            {
                list req = llGetObjectDetails(llList2Key(objectifiedballs, l), [OBJECT_CREATOR]);
                if(req == [] || llList2Key(req, 0) != llGetCreator())
                {
                    detachobject(llList2String(objectifieddescriptions, l));
                    objectifiednames = llDeleteSubList(objectifiednames, l, l);
                    objectifiedavatars = llDeleteSubList(objectifiedavatars, l, l);
                    objectifiedballs = llDeleteSubList(objectifiedballs, l, l);
                    objectifieddescriptions = llDeleteSubList(objectifieddescriptions, l, l);
                }
                --l;
            }
        }

        updatetitle();
        llSetTimerEvent(0.5);
    }
}