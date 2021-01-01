#include <IT/globals.lsl>

string owner = "";
string objectprefix = "";
string capturespoof = "";
string releasespoof = "";
string putonspoof = "";
string putdownspoof = "";
integer hideopt = 1;

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
key closestavatar = NULL_KEY;
key lastrezzed;
key lastseenobject;

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

integer canrez(vector pos)
{
    integer flags = llGetParcelFlags(pos);
    if(flags & PARCEL_FLAG_ALLOW_CREATE_OBJECTS) return TRUE;
    list details = llGetParcelDetails(pos, [PARCEL_DETAILS_OWNER, PARCEL_DETAILS_GROUP]);
    if(llList2Key(details, 0) == llGetOwner()) return TRUE;
    return(flags & PARCEL_FLAG_ALLOW_CREATE_GROUP_OBJECTS) && llSameGroup(llList2Key(details, 1));
}

giveeditmenu()
{
    integer l = llGetListLength(objectifiednames);
    while(~--l)
    {
        llOwnerSay(llList2String(objectifiednames, l) + " (" + objectprefix + llList2String(objectifieddescriptions, l)+ ") " + 
                   "[secondlife:///app/chat/" + (string)COMMAND_CHANNEL + "/ite%20" + (string)l + " (edit position)] " +
                   "[secondlife:///app/chat/" + (string)COMMAND_CHANNEL + "/its%20" + (string)l + " (store object)]");
    }
}

givereleasemenu()
{
    integer l = llGetListLength(objectifiednames);
    if(l == 1)
    {
        release(0);
        return;
    }
    while(~--l) llOwnerSay("[secondlife:///app/chat/" + (string)COMMAND_CHANNEL + "/itr%20" + (string)l + " Release " + llList2String(objectifiednames, l) + " (" + objectprefix + llList2String(objectifieddescriptions, l)+ ")]");
    llOwnerSay("[secondlife:///app/chat/" + (string)COMMAND_CHANNEL + "/itr Release everyone.]");
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
    integer l = llGetListLength(objectifiedballs);
    while(~--l) release(l);
}

addobject(string desc)
{
    if(lockedavatar == llGetOwner()) return;
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

    state_entry()
    {
        llListen(COMMAND_CHANNEL, "", llGetOwner(), "");
        llListen(O_DIALOG_CHANNEL, "", llGetOwner(), "");
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
        if(c == COMMAND_CHANNEL)
        {
            if(m == "itr")
            {
                releaseall();
            }
            else if(startswith(llToLower(m), "itr"))
            {
                release((integer)llDeleteSubString(m, 0, llStringLength("itr")));
            }
            else if(startswith(llToLower(m), "ite"))
            {
                integer i = (integer)llDeleteSubString(m, 0, llStringLength("ite"));
                llRegionSayTo(llList2Key(objectifiedballs, i), MANTRA_CHANNEL, "edit");
            }
            else if(startswith(llToLower(m), "its"))
            {
                store = (integer)llDeleteSubString(m, 0, llStringLength("its"));
                llRegionSayTo(lastseenobject, MANTRA_CHANNEL, "furniture");
            }
        }
        else if(c == O_DIALOG_CHANNEL)
        {
            addobject(llStringTrim(m, STRING_TRIM));
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
                        llMessageLinked(LINK_SET, M_API_TPOK_O, "", NULL_KEY);
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
                            llMessageLinked(LINK_SET, M_API_LOCK, "", NULL_KEY);
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
                while(~--n) llRegionSayTo(llList2Key(objectifiedavatars, n), 0, m);
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
            integer l = llGetListLength(objectifiedavatars);
            while(~--l)
            {
                if(llListFindList(responses, [llList2Key(objectifiedavatars, l)]) == -1)
                {
                    objectifiednames = llDeleteSubList(objectifiednames, l, l);
                    objectifiedavatars = llDeleteSubList(objectifiedavatars, l, l);
                    objectifiedballs = llDeleteSubList(objectifiedballs, l, l);
                    objectifieddescriptions = llDeleteSubList(objectifieddescriptions, l, l);
                }
            }
            await = "";
            if(responses == []) intp = FALSE;
            llMessageLinked(LINK_SET, M_API_SET_FILTER, "object", (key)((string)FALSE));
            llMessageLinked(LINK_SET, M_API_TPOK_O, "", NULL_KEY);
        }
        else if(await == "r")
        {
            llOwnerSay("Done recapturing.");
            integer l = llGetListLength(objectifiedavatars);
            while(~--l)
            {
                if(llListFindList(responses, [llList2Key(objectifiedavatars, l)]) == -1)
                {
                    objectifiednames = llDeleteSubList(objectifiednames, l, l);
                    objectifiedavatars = llDeleteSubList(objectifiedavatars, l, l);
                    objectifiedballs = llDeleteSubList(objectifiedballs, l, l);
                    objectifieddescriptions = llDeleteSubList(objectifieddescriptions, l, l);
                }
            }
            await = "";
            intp = FALSE;
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
        if(num == M_API_HUD_STARTED)
        {
            lockedavatar = NULL_KEY;
            lockedname = "";
            intp = FALSE;
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
            else if(str == "capture") capturespoof = (string)id;
            else if(str == "release") releasespoof = (string)id;
            else if(str == "puton") putonspoof = (string)id;
            else if(str == "putdown") putdownspoof = (string)id;
            else if(str == "ball") hideopt = (integer)((string)id);
        }
        else if(num == M_API_DOTP)
        {
            if(objectifiedavatars == [] || (string)id == llGetRegionName()) llMessageLinked(LINK_SET, M_API_TPOK_O, "", NULL_KEY);
            else
            {
                intp = TRUE;
                responses = [];
                integer l = llGetListLength(objectifiedavatars);
                while(~--l)
                {
                    key av = llList2Key(objectifiedavatars, l);
                    llRegionSayTo(llList2Key(objectifiedballs, l), MANTRA_CHANNEL, "abouttotp");
                    await = "dotp";
                    llRegionSayTo(av, RLVRC, "release," + (string)av + ",!release");
                    llSleep(0.25);
                    llRegionSayTo(av, RLVRC, "dotp," + (string)av + "," + str);
                }
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
            if(str == "take")
            {
                store = -1;
                llRegionSayTo(id, MANTRA_CHANNEL, "furniture");
            }
            else if(str == "edit")
            {
                lastseenobject = id;
                giveeditmenu();
            }
            else if(str == "release")
            {
                givereleasemenu();
            }
            else if(str == "objectify")
            {
                llTextBox(llGetOwner(), "As what do you wish to wear " + lockedname + "?", O_DIALOG_CHANNEL);
            }
        }
    }

    timer()
    {
        llSetTimerEvent(0.0);
        if(lockedavatar != NULL_KEY && llGetAgentSize(lockedavatar) == ZERO_VECTOR) llMessageLinked(LINK_SET, M_API_LOCK, "", NULL_KEY);
        if(!intp)
        {
            integer l = llGetListLength(objectifiedballs);
            while(~--l)
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
            }
            if(objectifiedballs != []) llMessageLinked(LINK_SET, M_API_SET_FILTER, "object", (key)((string)TRUE));
            else                       llMessageLinked(LINK_SET, M_API_SET_FILTER, "object", (key)((string)FALSE));
        }
        llSetTimerEvent(5.0);
    }
}