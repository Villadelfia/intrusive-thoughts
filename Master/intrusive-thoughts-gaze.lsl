#include <IT/globals.lsl>

string owner = "Hana";
string pronoun = "her";
key lastseenavatar;
string lastseenavatarname;
key lastseenobject;
string lastseenobjectname;
key lockedavatar;
string lockedname;
key target;
string targetname;
string targetdescription;
list objectifiedavatars;
list objectifiednames;
list objectifieddescriptions;
list objectifiedballs;
list responses;
string await = "";
integer intp = FALSE;
integer handling;

updatetitle()
{
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
    string oldn = llGetObjectName();
    llSetObjectName("");
    llOwnerSay("Objectification:");
    if(lockedavatar != NULL_KEY) 
    {
        llOwnerSay("[secondlife:///app/chat/" + (string)GAZE_CHANNEL + "/capture Objectify " + lockedname + ".]");
        llOwnerSay("Manually type /1capture <description> to choose what your object will be.");
    }
    integer l = llGetListLength(objectifiednames) - 1;
    while(l >= 0)
    {
        llOwnerSay("[secondlife:///app/chat/" + (string)GAZE_CHANNEL + "/release\%20" + (string)l + " Release " + llList2String(objectifiednames, l) +".]");
        l--;
    }
    if(llGetListLength(objectifiednames) > 1) llOwnerSay("[secondlife:///app/chat/" + (string)GAZE_CHANNEL + "/releaseall Release everyone.]");
    llSetObjectName(oldn);
}

release(integer i)
{
    llSay(0, owner + " releases the soul trapped within " + pronoun + " " + llList2String(objectifieddescriptions, i) + " back into the living form of " + llList2String(objectifiednames, i) + ".");
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
    if(desc == "") desc = "object";
    targetdescription = desc;
    
    if(!canrez(llGetPos()))
    {
        llOwnerSay("Can't rez here, trying to set land group.");
        llOwnerSay("@setgroup:" + (string)llList2Key(llGetParcelDetails(llGetPos(), [PARCEL_DETAILS_GROUP]), 0) + "=force");
        llSleep(5.0);
    }

    if(!canrez(llGetPos())) 
    {
        llOwnerSay("Can't rez here. Not capturing.");
        return;
    }

    llOwnerSay("Capturing '" + lockedname + "'.");
    target = lockedavatar;
    targetname = lockedname;
    llRezAtRoot("ball", llGetPos() - <0.0, 0.0, 3.0>, ZERO_VECTOR, ZERO_ROTATION, 1);
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
            llRezAtRoot("ball", llGetPos() - <0.0, 0.0, 3.0>, ZERO_VECTOR, ZERO_ROTATION, 1);
        }
    }
}

default
{
    state_entry()
    {
        llRequestPermissions(llGetOwner(), PERMISSION_TRACK_CAMERA);
        llListen(GAZE_CHANNEL, "", llGetOwner(), "");
        llListen(RLVRC, "", NULL_KEY, "");
    }

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
        if(id != NULL_KEY) llRequestPermissions(llGetOwner(), PERMISSION_TRACK_CAMERA);
        else               
        {
            llSetTimerEvent(0.0);
            llSetText("", <1.0, 1.0, 0.0>, 1.0);
        }
    }

    run_time_permissions(integer perm)
    {
        if(perm & PERMISSION_TRACK_CAMERA) 
        {
            llSetTimerEvent(0.5);
            lastseenavatar = NULL_KEY;
            lastseenavatarname = "-no avatar-";
            lastseenobject = NULL_KEY;
            lastseenobjectname = "-no object-";
            lockedavatar = NULL_KEY;
            lockedname = "";
            objectifiedavatars = [];
            objectifiednames = [];
            objectifiedballs = [];
            objectifieddescriptions = [];
            intp = FALSE;
        }
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
                if(await == "simplesit" && startswith(command, "@sit"))
                {
                    if(accept) llOwnerSay("Successfully sat down '" + lockedname + "'.");
                    else       llOwnerSay("Could not sit down '" + lockedname + "'.");
                    await = "";
                }
                else if(await == "dotp" && startswith(command, "@tpto"))
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
                        await = "";
                        if(responses == []) intp = FALSE;
                        llMessageLinked(LINK_SET, API_TPOK, "", NULL_KEY);
                    }
                }
                else if(await == "recapture" && startswith(command, "@sit"))
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
                        llOwnerSay("Done recapturing.");
                        llSensorRemove();
                        await = "";
                        intp = FALSE;
                    }
                }
                else if(await == "capture" && startswith(command, "@sit"))
                {
                    if(accept) 
                    {
                        llSay(0, owner + " chants in an ancient forbidden language as " + lockedname + " finds themselves being drawn into the inanimate form of " + pronoun + " " + targetdescription + ".");
                        key av = llGetOwnerKey(id);
                    }
                    else llOwnerSay("Could not capture '" + lockedname + "'.");
                    await = "";
                }
            }
        }
        else if(c == GAZE_CHAT_CHANNEL && startswith(m, "/me") == TRUE && contains(m, "\"") == FALSE)
        {
            string oldn = llGetObjectName();
            integer i = llListFindList(objectifiedavatars, [id]);
            if(i == -1) return;
            llSetObjectName(owner + "'s " + llList2String(objectifieddescriptions, i));
            llSay(0, m);
            llSetObjectName(oldn);
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
            llMessageLinked(LINK_SET, API_TPOK, "", NULL_KEY);
        }
        else if(await == "recapture")
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
                lockedavatar = lastseenavatar;
                lockedname = lastseenavatarname;
            }
            else if(lockedavatar != NULL_KEY)
            {
                lockedavatar = NULL_KEY;
                lockedname = "";
            }
        }
        else if(name == "sit")
        {
            if(lockedavatar != NULL_KEY && llGetAgentSize(lockedavatar) != ZERO_VECTOR && lastseenobject != NULL_KEY)
            {
                llOwnerSay("Sitting '" + lockedname + "' on '" + lastseenobjectname + "'.");
                await = "simplesit";
                if(lockedavatar == llGetOwner()) llOwnerSay("@sit:" + (string)lastseenobject + "=force");
                else                             llRegionSayTo(lockedavatar, RLVRC, "simplesit," + (string)lockedavatar + ",@sit:" + (string)lastseenobject + "=force");
            }
        }
        else if(name == "objectify")
        {
            givemenu();
        }
    }

    object_rez(key id)
    {
        llSleep(2.5);
        llSensorRepeat("", "3d6181b0-6a4b-97ef-18d8-722652995cf1", PASSIVE, 0.0, PI, 10.0);
        if(intp)
        {
            await = "recapture";
            llOwnerSay("Recapturing " + llList2String(objectifiednames, handling-1) + ".");
            llRegionSayTo(target, RLVRC, "recapture," + (string)target + ",@sit:" + (string)id + "=force");
            objectifiedballs += [id];
            handling++;
            handletp();
        }
        else
        {
            await = "capture";
            llRegionSayTo(target, RLVRC, "capture," + (string)target + ",@sit:" + (string)id + "=force");
            objectifiedballs += [id];
            objectifiedavatars += [target];
            objectifiednames += [targetname];
            objectifieddescriptions += [targetdescription];
            lockedavatar = NULL_KEY;
        }
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == API_DOTP)
        {
            if(objectifiedavatars == [] || (string)id == llGetRegionName())
            {
                llMessageLinked(LINK_SET, API_TPOK, "", NULL_KEY);
            }
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
    }

    timer()
    {
        llSetTimerEvent(0.0);
        if(llGetPermissions() & PERMISSION_TRACK_CAMERA == 0) return;
        vector startpos = llGetCameraPos();
        rotation rot = llGetCameraRot();
        vector endpos = startpos + (llRot2Fwd(rot) * 10);

        list results = llCastRay(startpos, endpos, [
            RC_REJECT_TYPES, RC_REJECT_LAND | RC_REJECT_PHYSICAL | RC_REJECT_NONPHYSICAL,
            RC_DETECT_PHANTOM, FALSE,
            RC_DATA_FLAGS, 0,
            RC_MAX_HITS, 1
        ]);

        if(llList2Integer(results, -1) == 1)
        {
            key target = llList2Key(results, 0);
            if(lastseenavatar != target)
            {
                lastseenavatar = target;
                lastseenavatarname = llGetDisplayName(target);
            }
        }

        results = llCastRay(startpos, endpos, [
            RC_REJECT_TYPES, RC_REJECT_LAND | RC_REJECT_PHYSICAL | RC_REJECT_AGENTS,
            RC_DETECT_PHANTOM, TRUE,
            RC_DATA_FLAGS, RC_GET_ROOT_KEY,
            RC_MAX_HITS, 1
        ]);

        if(llList2Integer(results, -1) == 1)
        {
            key target = llList2Key(results, 0);
            list data = llGetObjectDetails(target, [OBJECT_NAME]);
            string name = llList2String(data, 0);
            if(lastseenobject != target)
            {
                lastseenobject = target;
                lastseenobjectname = name;
            }
        }

        if(lockedavatar != NULL_KEY && llGetAgentSize(lockedavatar) == ZERO_VECTOR)
        {
            lockedavatar = NULL_KEY;
            lockedname = "";
        }

        if(intp == FALSE)
        {
            integer l = llGetListLength(objectifiedballs) - 1;
            while(l >= 0)
            {
                list req = llGetObjectDetails(llList2Key(objectifiedballs, l), [OBJECT_CREATOR]);
                if(req == [] || llList2Key(req, 0) != llGetCreator())
                {
                    objectifiednames = llDeleteSubList(objectifiednames, l, l);
                    objectifiedavatars = llDeleteSubList(objectifiedavatars, l, l);
                    objectifiedballs = llDeleteSubList(objectifiedballs, l, l);
                    objectifieddescriptions = llDeleteSubList(objectifieddescriptions, l, l);
                }
                --l;
            }
        }

        llSetTimerEvent(0.5);
        updatetitle();
    }
}