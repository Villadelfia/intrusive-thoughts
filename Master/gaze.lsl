#include <IT/globals.lsl>

key lastseenavatar;
string lastseenavatarname;
key lastseenobject;
string lastseenobjectname;
key lockedavatar;
string lockedname;

default
{
    state_entry()
    {
        llRequestPermissions(llGetOwner(), PERMISSION_TRACK_CAMERA);
    }

    changed(integer change)
    {
        if(change & CHANGED_OWNER) llResetScript();
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
        }
    }

    touch_start(integer total_number)
    {
        string name = llGetLinkName(llDetectedLinkNumber(0));
        if(name == "lock")
        {
            if(lastseenavatarname != "")
            {
                lockedavatar = lastseenavatar;
                lockedname = lastseenavatarname;
                llOwnerSay("Avatar lock set to '" + lastseenavatarname + "'.");
            }
        }
        else if(name == "sit")
        {
            if(llGetAgentSize(lockedavatar) != ZERO_VECTOR && lastseenobjectname != "")
            {
                llOwnerSay("Sitting '" + lockedname + "' on '" + lastseenobjectname + "'.");
                if(lockedavatar == llGetOwner()) llOwnerSay("@sit:" + (string)lastseenobject + "=force");
                else                             llRegionSayTo(lockedavatar, RLVRC, "Sit," + (string)lockedavatar + ",@sit:" + (string)lastseenobject + "=force|!release");
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
                llSetText(lastseenavatarname + "\n" + lastseenobjectname + "\n \n \n \n \n \n ", <1.0, 1.0, 0.0>, 1.0);
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
                llSetText(lastseenavatarname + "\n" + lastseenobjectname + "\n \n \n \n \n \n ", <1.0, 1.0, 0.0>, 1.0);
            }
        }
        llSetTimerEvent(0.5);
    }
}