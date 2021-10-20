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
list objectifiedurls = [];
list objectificationqueue = [];
string await = "";

integer timermode = 0;
integer countdown = 0;
list arrived = [];
string lastregion;
list buffered = [];
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
        llRegionSayTo(llList2Key(objectifiedballs, 0), 5, "menu");
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

    string prompt = "Who will you store as '" + llList2String(llGetObjectDetails(lastseenobject, [OBJECT_NAME]), 0) + "'?\n";
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
    objectifiedurls = llDeleteSubList(objectifiedurls, i, i);
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

handlequeue()
{
    if(objectificationqueue == [])
    {
        llOwnerSay("Done recapturing!");
        timermode = 0;
        llSetTimerEvent(2.5);
    }
    else
    {
        target = llList2Key(objectificationqueue, 0);
        targetname = llList2String(objectificationqueue, 1);
        targetdescription = llList2String(objectificationqueue, 2);
        objectificationqueue = llDeleteSubList(objectificationqueue, 0, 2);
        if(llGetAgentSize(target) == ZERO_VECTOR) 
        {
            llOwnerSay("Skipping " + targetname + ". Not present.");
            handlequeue();
        }
        else
        {
            llOwnerSay("Recapturing " + targetname + ".");
            llSetTimerEvent(10.0);
            llRezAtRoot("ball", llGetPos() - <0.0, 0.0, 3.0>, ZERO_VECTOR, ZERO_ROTATION, hideopt);
        }
    }
}

default
{
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
                llRegionSayTo(llList2Key(objectifiedballs, (integer)m), 5, "menu");
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
                    objectifiedurls = llDeleteSubList(objectifiedurls, store, store);
                }
            }
            else if(startswith(m, "puton"))
            {
                list params = llParseString2List(llDeleteSubString(m, 0, llStringLength("puton")), ["|||"], []);
                key av = (key)llList2String(params, 0);
                string desc = llList2String(params, 1);
                string url = llList2String(params, 2);
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
                objectifiedurls += [url];
            }
            else if(startswith(m, "objrename"))
            {
                m = llDeleteSubString(m, 0, llStringLength("objrename"));
                integer i = llListFindList(objectifiedballs, [id]);
                if(i != -1) 
                {
                    detachobject(llList2String(objectifieddescriptions, i));
                    attachobject(m);
                    objectifieddescriptions = llListReplaceList(objectifieddescriptions, [m], i, i);
                }
            }
            else if(startswith(m, "objurl"))
            {
                m = llDeleteSubString(m, 0, llStringLength("objurl"));
                integer i = llListFindList(objectifiedballs, [id]);
                if(i != -1) objectifiedurls = llListReplaceList(objectifiedurls, [m], i, i);
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

            if(identifier == await && await == "c")
            {
                if(accept == TRUE)
                {
                    string spoof;
                    spoof = llDumpList2String(llParseStringKeepNulls(capturespoof, ["%ME%"], []), owner);
                    spoof = llDumpList2String(llParseStringKeepNulls(spoof, ["%OBJ%"], []), targetdescription);
                    spoof = llDumpList2String(llParseStringKeepNulls(spoof, ["%VIC%"], []), targetname);
                    llSay(0, spoof);
                    attachobject(targetdescription);
                }
                else
                {
                    llOwnerSay("Could not capture '" + lockedname + "'.");
                }
                await = "";
                llRegionSayTo(lastrezzed, MANTRA_CHANNEL, "check");
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
                while(~--n) llRegionSayTo(llList2Key(objectifiedballs, n), GAZE_ECHO_CHANNEL, m);
                llOwnerSay(m);
            }
            llSetObjectName("");
        }
    }

    object_rez(key id)
    {
        if(llList2String(llGetObjectDetails(id, [OBJECT_NAME]), 0) != "ball") return;
        lastrezzed = id;
        objectifiedballs += [id];
        objectifiedavatars += [target];
        objectifiednames += [targetname];
        objectifieddescriptions += [targetdescription];
        objectifiedurls += ["null"];
        llRegionSayTo(id, MANTRA_CHANNEL, "sit " + (string)target);
        if(timermode == 0) await = "c";
        else
        {
            attachobject(targetdescription);
            handlequeue();
        }
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == M_API_CONFIG_DONE) 
        {
            lockedavatar = NULL_KEY;
            lockedname = "";
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
            llMessageLinked(LINK_SET, M_API_TPOK_O, "", NULL_KEY);
        }
        else if(num == M_API_LOCK)
        {
            lockedavatar = id;
            lockedname = str;
        }
        else if(num == M_API_BUTTON_PRESSED)
        {
            if(timermode != 0) return;
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
        if(timermode == 0)
        {
            integer l = llGetListLength(objectifiedballs);
            while(~--l)
            {
                integer differentRegion = lastregion != llGetRegionName();
                list req = llGetObjectDetails(llList2Key(objectifiedballs, l), [OBJECT_CREATOR]);
                if(req == [] || llList2Key(req, 0) != llGetCreator())
                {
                    // If we're in a different region, that means we teleported. So don't give up on those people yet.
                    if(differentRegion)
                    {
                        timermode = 1;
                        buffered = [];
                        jump timermode1;
                    }
                    else
                    {
                        integer inbuffered = llListFindList(buffered, [llList2Key(objectifiedballs, l)]);
                        if(inbuffered == -1)
                        {
                            buffered += [llList2Key(objectifiedballs, l)];
                        }
                        else
                        {
                            detachobject(llList2String(objectifieddescriptions, l));
                            objectifiednames = llDeleteSubList(objectifiednames, l, l);
                            objectifiedavatars = llDeleteSubList(objectifiedavatars, l, l);
                            objectifiedballs = llDeleteSubList(objectifiedballs, l, l);
                            objectifieddescriptions = llDeleteSubList(objectifieddescriptions, l, l);
                            objectifiedurls = llDeleteSubList(objectifiedurls, l, l);
                            buffered = llDeleteSubList(buffered, inbuffered, inbuffered);
                        }
                    }
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
            integer l = llGetListLength(objectifiedballs);
            if(!canrez(llGetPos()))
            {
                llOwnerSay("Can't rez here, trying to set land group.");
                llOwnerSay("@setgroup:" + (string)llList2Key(llGetParcelDetails(llGetPos(), [PARCEL_DETAILS_GROUP]), 0) + "=force");
                llSleep(2.5);
            }

            integer teleportothers = canrez(llGetPos());
            if(teleportothers) llOwnerSay("Fetching your objectified avatars and giving them 30 seconds to arrive...");
            else               llOwnerSay("Can't rez here, not fetching your objectified avatars...");

            while(~--l)
            {
                if(llList2String(objectifiedurls, l) == "null")
                {
                    detachobject(llList2String(objectifieddescriptions, l));
                    objectifiednames = llDeleteSubList(objectifiednames, l, l);
                    objectifiedavatars = llDeleteSubList(objectifiedavatars, l, l);
                    objectifiedballs = llDeleteSubList(objectifiedballs, l, l);
                    objectifieddescriptions = llDeleteSubList(objectifieddescriptions, l, l);
                    objectifiedurls = llDeleteSubList(objectifiedurls, l, l);
                }
                else
                {
                    if(teleportothers) llHTTPRequest(llList2String(objectifiedurls, l), [HTTP_METHOD, "POST"], region + "/" + (string)llRound(pos.x) + "/" + (string)llRound(pos.y)+ "/" + (string)llRound(pos.z));
                    else               llHTTPRequest(llList2String(objectifiedurls, l), [HTTP_METHOD, "POST"], "die");
                }
            }

            if(teleportothers)
            {
                timermode = 2;
                countdown = 11;
                arrived = [];
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

                integer l = llGetListLength(objectifiedballs);
                list agents = llGetAgentList(AGENT_LIST_REGION, []);
                while(~--l)
                {
                    key av = llList2Key(objectifiedavatars, l);
                    integer inarrived = llListFindList(arrived, [av]);
                    integer inagents = llListFindList(agents, [av]);
                    if(inarrived == -1 && inagents != -1) arrived += [av];
                }

                if(llGetListLength(arrived) == llGetListLength(objectifiedballs)) 
                {
                    countdown = 0;
                    llSleep(5.0);
                }

                if(countdown != 0) llSetTimerEvent(3.0);
            }

            if(countdown == 0)
            {
                arrived = [];
                integer l = llGetListLength(objectifiedballs);
                while(~--l)
                {
                    detachobject(llList2String(objectifieddescriptions, l));
                    if(llGetAgentSize(llList2Key(objectifiedavatars, l)) == ZERO_VECTOR)
                    {
                        objectifiednames = llDeleteSubList(objectifiednames, l, l);
                        objectifiedavatars = llDeleteSubList(objectifiedavatars, l, l);
                        objectifiedballs = llDeleteSubList(objectifiedballs, l, l);
                        objectifieddescriptions = llDeleteSubList(objectifieddescriptions, l, l);
                        objectifiedurls = llDeleteSubList(objectifiedurls, l, l);
                    }
                }

                if(objectifiedballs == [])
                {
                    llOwnerSay("Nobody arrived in time.");
                    timermode = 0;
                    llSetTimerEvent(2.5);
                }
                else
                {
                    llOwnerSay("Starting to recapture...");
                    objectificationqueue = [];
                    integer l = llGetListLength(objectifiedballs);
                    while(~--l)
                    {
                        objectificationqueue += [
                            llList2Key(objectifiedavatars, l),
                            llList2String(objectifiednames, l),
                            llList2String(objectifieddescriptions, l)
                        ];
                    }
                    timermode = 3;
                    objectifiednames = [];
                    objectifiedavatars = [];
                    objectifiedballs = [];
                    objectifieddescriptions = [];
                    objectifiedurls = [];
                    handlequeue();
                }
            }
        }
        else if(timermode == 3)
        {
            handlequeue();
        }

        lastregion = llGetRegionName();
    }
}