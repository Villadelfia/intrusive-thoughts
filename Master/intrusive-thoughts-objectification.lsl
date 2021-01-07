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

integer dialog = 0;
integer filter = FALSE;
integer configured = FALSE;

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

givereleasemenu()
{
    integer l = llGetListLength(objectifiednames);
    if(l == 1)
    {
        release(0);
        return;
    }

    string prompt = "Who will you release?\n";
    integer i;
    if(l > 11) l = 11;
    list buttons = [];
    for(i = 0; i < l; ++i)
    {
        buttons += [(string)i];
        prompt += "\n" + (string)i + ": " + llList2String(objectifiednames, i) + " (" + objectprefix + llList2String(objectifieddescriptions, i) + ")";
    }
    while(llGetListLength(buttons) < 11) buttons += [" "];
    buttons += ["ALL"];
    dialog = 1;
    llDialog(llGetOwner(), prompt, orderbuttons(buttons), O_DIALOG_CHANNEL);
}

giveeditmenu()
{
    integer l = llGetListLength(objectifiednames);
    if(l == 1)
    {
        llRegionSayTo(llList2Key(objectifiedballs, 0), MANTRA_CHANNEL, "edit");
        return;
    }

    string prompt = "Whose position will you edit?\n";
    integer i;
    if(l > 12) l = 12;
    list buttons = [];
    for(i = 0; i < l; ++i)
    {
        buttons += [(string)i];
        prompt += "\n" + (string)i + ": " + llList2String(objectifiednames, i) + " (" + objectprefix + llList2String(objectifieddescriptions, i)+ ")";
    }
    while(llGetListLength(buttons) < 12) buttons += [" "];
    dialog = 2;
    llDialog(llGetOwner(), prompt, orderbuttons(buttons), O_DIALOG_CHANNEL);
}

givestoremenu()
{
    integer l = llGetListLength(objectifiednames);
    if(l == 1)
    {
        store = 0;
        llRegionSayTo(lastseenobject, MANTRA_CHANNEL, "furniture");
        return;
    }

    string prompt = "Who will you store in as '" + llList2String(llGetObjectDetails(lastseenobject, [OBJECT_NAME]), 0) + "'?\n";
    integer i;
    if(l > 12) l = 12;
    list buttons = [];
    for(i = 0; i < l; ++i)
    {
        buttons += [(string)i];
        prompt += "\n" + (string)i + ": " + llList2String(objectifiednames, i) + " (" + objectprefix + llList2String(objectifieddescriptions, i)+ ")";
    }
    while(llGetListLength(buttons) < 12) buttons += [" "];
    dialog = 3;
    llDialog(llGetOwner(), prompt, orderbuttons(buttons), O_DIALOG_CHANNEL);
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
        if(c == O_DIALOG_CHANNEL)
        {
            if(dialog == 0)
            {
                addobject(llStringTrim(m, STRING_TRIM));
            }
            else if(dialog == 1)
            {
                if(m == " ")        return;
                else if(m == "ALL") releaseall();
                else                release((integer)m);
            }
            else if(dialog == 2)
            {
                if(m == " ") return;
                llRegionSayTo(llList2Key(objectifiedballs, (integer)m), MANTRA_CHANNEL, "edit");
            }
            else if(dialog == 3)
            {
                if(m == " ") return;
                store = (integer)m;
                llRegionSayTo(lastseenobject, MANTRA_CHANNEL, "furniture");
            }
        }
        else if(c == MANTRA_CHANNEL)
        {
            if(startswith(m, "furniture"))
            {
                storingon = n;
                if(store == -1)
                {
                    if(m == "furniture 0")
                    {
                        if(lockedavatar == NULL_KEY) llOwnerSay("No object is stored in " + n + ".");
                        else
                        {
                            llRegionSayTo(id, MANTRA_CHANNEL, "capture " + (string)lockedavatar);
                        }
                    }
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
            else if(startswith(m, "rlvresponse"))
            {
                responses += [id];
                if(llGetListLength(responses) == llGetListLength(objectifiedavatars))
                {
                    llSensorRemove();
                    if(responses == []) intp = FALSE;
                    llMessageLinked(LINK_SET, M_API_TPOK_O, "", NULL_KEY);
                }
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
                if(await == "r")
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
                        }
                        else llOwnerSay("Could not capture '" + lockedname + "'.");
                    }
                    else llOwnerSay("Could not capture '" + lockedname + "'.");
                    await = "";
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
        if(await == "r")
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
        else
        {
            integer l = llGetListLength(objectifiedballs);
            while(~--l)
            {
                if(llListFindList(responses, [llList2Key(objectifiedballs, l)]) == -1)
                {
                    objectifiednames = llDeleteSubList(objectifiednames, l, l);
                    objectifiedavatars = llDeleteSubList(objectifiedavatars, l, l);
                    objectifiedballs = llDeleteSubList(objectifiedballs, l, l);
                    objectifieddescriptions = llDeleteSubList(objectifieddescriptions, l, l);
                }
            }
            await = "";
            if(responses == []) intp = FALSE;
            if(filter)
            {
                filter = FALSE;
                llMessageLinked(LINK_SET, M_API_SET_FILTER, "object", (key)((string)filter));
            }
            llMessageLinked(LINK_SET, M_API_TPOK_O, "", NULL_KEY);
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
            llRegionSayTo(target, RLVRC, "r," + (string)target + ",@sit:" + (string)id + "=force|!x-handover/" + (string)id + "/0|!release");
            objectifiedballs += [id];
            handling++;
            handletp();
        }
        else
        {
            await = "c";
            llRegionSayTo(target, RLVRC, "c," + (string)target + ",@sit:" + (string)id + "=force|!x-handover/" + (string)id + "/0|!release");
            objectifiedballs += [id];
            objectifiedavatars += [target];
            objectifiednames += [targetname];
            objectifieddescriptions += [targetdescription];
        }
        llSetObjectName("");
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == M_API_CONFIG_DONE) 
        {
            lockedavatar = NULL_KEY;
            lockedname = "";
            intp = FALSE;
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
                capturespoof = "";
                releasespoof = "";
                putonspoof = "";
                putdownspoof = "";
                hideopt = 1;
            }

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
                await = "";
                while(~--l) llRegionSayTo(llList2Key(objectifiedballs, l), MANTRA_CHANNEL, "rlvforward " + str);
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
            if(str == "furniture")
            {
                store = -1;
                llRegionSayTo(id, MANTRA_CHANNEL, "furniture");
            }
            else if(str == "store")
            {
                lastseenobject = id;
                givestoremenu();
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
                dialog = 0;
                llTextBox(llGetOwner(), "As what do you wish to wear " + lockedname + "?", O_DIALOG_CHANNEL);
            }
        }
    }

    timer()
    {
        llSetTimerEvent(0.0);
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
            if(objectifiedballs != [])
            {
                if(!filter)
                {
                    filter = TRUE;
                    llMessageLinked(LINK_SET, M_API_SET_FILTER, "object", (key)((string)filter));
                }
            }
            else
            {
                if(filter)
                {
                    filter = FALSE;
                    llMessageLinked(LINK_SET, M_API_SET_FILTER, "object", (key)((string)filter));
                }
            }
        }
        llSetTimerEvent(0.5);
    }
}