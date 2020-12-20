#include <IT/globals.lsl>

key lastseenavatar;
string lastseenavatarname;
key lastseenobject;
string lastseenobjectname;
key lockedavatar;
string lockedname;
key target;
string targetname;
list objectifiedavatars;
list objectifiednames;
list objectifiedballs;
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
    llOwnerSay("[secondlife:///app/chat/" + (string)GAZE_CHANNEL + "/add Objectify " + lockedname + ".]");
    integer l = llGetListLength(objectifiednames) - 1;
    while(l >= 0)
    {
        llOwnerSay("[secondlife:///app/chat/" + (string)GAZE_CHANNEL + "/" + (string)l + " Release " + llList2String(objectifiednames, l) +".]");
        l--;
    }
    llOwnerSay("[secondlife:///app/chat/" + (string)GAZE_CHANNEL + "/all Release all.]");
    llSetObjectName(oldn);
}

release(integer i)
{
    llOwnerSay("Releasing '" + llList2String(objectifiednames, i) + "'.");
    llRegionSayTo(llList2Key(objectifiedballs, i), MANTRA_CHANNEL, "unsit");
    objectifiednames = llDeleteSubList(objectifiednames, i, i);
    objectifiedavatars = llDeleteSubList(objectifiedavatars, i, i);
    objectifiedballs = llDeleteSubList(objectifiedballs, i, i);
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

addobject()
{
    if(lockedavatar == llGetOwner()) return;
    if(!canrez(llGetPos())) return;
    llOwnerSay("Capturing '" + lockedname + "'.");
    target = lockedavatar;
    targetname = lockedname;
    llRezAtRoot("ball", llGetPos() - <0.0, 0.0, 3.0>, ZERO_VECTOR, ZERO_ROTATION, 1);
}

handletp()
{
    if(!canrez(llGetPos()))
    {
        llOwnerSay("Can't rez here. Not recapturing.");
        objectifiedavatars = [];
        objectifiednames = [];
        objectifiedballs = [];
        intp = FALSE;
    }
    else
    {
        llOwnerSay("Recapturing everyone in 10 seconds.");
        llSleep(10.0);
        if(handling < llGetListLength(objectifiedavatars))
        {
            target = llList2Key(objectifiedavatars, handling);
            llRezAtRoot("ball", llGetPos() - <0.0, 0.0, 3.0>, ZERO_VECTOR, ZERO_ROTATION, 1);
            ++handling;
        }
        else
        {
            llOwnerSay("Done recapturing.");
            intp = FALSE;
        }
    }
}

default
{
    state_entry()
    {
        llRequestPermissions(llGetOwner(), PERMISSION_TRACK_CAMERA);
        llListen(GAZE_CHANNEL, "", llGetOwner(), "");
    }

    changed(integer change)
    {
        if(change & CHANGED_OWNER) llResetScript();
        if(change & CHANGED_TELEPORT)
        {
            if(intp)
            {
                llOwnerSay("@setgroup:" + (string)llList2Key(llGetParcelDetails(llGetPos(), [PARCEL_DETAILS_GROUP]), 0) + "=force");
                llSleep(5.0);
                handling = 0;
                objectifiedballs = [];
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
            intp = FALSE;
        }
    }

    listen(integer channel, string name, key id, string m)
    {
        if(m == "add")
        {
            addobject();
        }
        else if(m == "all")
        {
            releaseall();
        }
        else
        {
            release((integer)m);
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
                if(lockedavatar == llGetOwner()) llOwnerSay("@sit:" + (string)lastseenobject + "=force");
                else                             llRegionSayTo(lockedavatar, RLVRC, "Sit," + (string)lockedavatar + ",@sit:" + (string)lastseenobject + "=force|!release");
            }
        }
        else if(name == "objectify")
        {
            if(objectifiedavatars != [])
            {
                givemenu();
            }
            else if(lockedavatar != NULL_KEY && llGetAgentSize(lockedavatar) != ZERO_VECTOR)
            {
                addobject();
            }
        }
    }

    object_rez(key id)
    {
        llRegionSayTo(target, RLVRC, "Sit," + (string)target + ",@unsit=force|@sit:" + (string)id + "=force|!release");
        if(intp)
        {
            llOwnerSay("Recapturing " + llList2String(objectifiednames, handling-1) + ".");
            objectifiedballs += [id];
            handletp();
        }
        else
        {
            objectifiedballs += [id];
            objectifiedavatars += [target];
            objectifiednames += [targetname];
            lockedavatar = NULL_KEY;
            lockedname = "";
        }
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == API_DOTP)
        {
            if(objectifiedavatars == [])
            {
                llMessageLinked(LINK_SET, API_TPOK, "", NULL_KEY);
            }
            else
            {
                integer l = llGetListLength(objectifiedavatars) - 1;
                while(l >= 0)
                {
                    key av = llList2Key(objectifiedavatars, l);
                    llRegionSayTo(llList2Key(objectifiedballs, l), MANTRA_CHANNEL, "unsit");
                    llRegionSayTo(av, RLVRC, "Sit," + (string)av + "," + str);
                    --l;
                }
                intp = TRUE;
                llSetTimerEvent(0.0);
                llMessageLinked(LINK_SET, API_TPOK, "", NULL_KEY);
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
            list data = llGetObjectDetails(target, [OBJECT_NAME]);
            string name = llList2String(data, 0);
            if(lastseenavatar != target)
            {
                lastseenavatar = target;
                lastseenavatarname = name;
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
                if(llGetAgentSize(llList2Key(objectifiedavatars, l)) == ZERO_VECTOR)
                {
                    objectifiednames = llDeleteSubList(objectifiednames, l, l);
                    objectifiedavatars = llDeleteSubList(objectifiedavatars, l, l);
                    objectifiedballs = llDeleteSubList(objectifiedballs, l, l);
                }
                --l;
            }
        }

        llSetTimerEvent(0.5);
        updatetitle();
    }
}