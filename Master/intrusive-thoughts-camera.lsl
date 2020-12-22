#include <IT/globals.lsl>
key closestavatar;

default
{
    state_entry()
    {
        llRequestPermissions(llGetOwner(), PERMISSION_TRACK_CAMERA);
    }

    attach(key id)
    {
        if(id) llRequestPermissions(llGetOwner(), PERMISSION_TRACK_CAMERA);
    }

    run_time_permissions(integer perm)
    {
        if(perm & PERMISSION_TRACK_CAMERA) llSetTimerEvent(0.5);
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == API_CONFIG_DATA)
        {
            if(str == "name")
            {
                llSetObjectName("");
                llOwnerSay(VERSION_C + ": Set spoof name prefix to " + (string)id);
            }
            else if(str == "objectprefix")
            {
                llSetObjectName("");
                llOwnerSay(VERSION_C + ": Set spoof object prefix to " + (string)id);
            }
            else if(str == "capture")
            {
                llSetObjectName("");
                llOwnerSay(VERSION_C + ": Set capture phrase to '" + (string)id + "'");
            }
            else if(str == "release")
            {
                llSetObjectName("");
                llOwnerSay(VERSION_C + ": Set release phrase to '" + (string)id + "'");
            }
            else if(str == "puton")
            {
                llSetObjectName("");
                llOwnerSay(VERSION_C + ": Set put on phrase to '" + (string)id + "'");
            }
            else if(str == "putdown")
            {
                llSetObjectName("");
                llOwnerSay(VERSION_C + ": Set put down phrase to '" + (string)id + "'");
            }
        }
    }

    timer()
    {
        llSetTimerEvent(0.0);
        if(llGetPermissions() & PERMISSION_TRACK_CAMERA == 0) return;
        vector startpos = llGetCameraPos();
        rotation rot = llGetCameraRot();
        vector endpos = startpos + (llRot2Fwd(rot) * 3);

        key newclosest = NULL_KEY;
        float closest = 10.0;

        list agents = llGetAgentList(AGENT_LIST_REGION, []);
        integer num = llGetListLength(agents);
 
        if(!num) return;
 
        integer i;
        while(i < num)
        {
            key id = llList2Key(agents, i);
            float dist = llVecDist(endpos, llList2Vector(llGetObjectDetails(id, [OBJECT_POS]), 0));
            if(dist < closest) 
            {
                newclosest = id;
                closest = dist;
            }
            ++i;
        }

        endpos = startpos + (llRot2Fwd(rot) * 10);
        list results = llCastRay(startpos, endpos, [
            RC_REJECT_TYPES, RC_REJECT_LAND | RC_REJECT_PHYSICAL | RC_REJECT_NONPHYSICAL,
            RC_DETECT_PHANTOM, FALSE,
            RC_DATA_FLAGS, 0,
            RC_MAX_HITS, 1
        ]);

        if(llList2Integer(results, -1) == 1)
        {
            key target = llList2Key(results, 0);
            if(target != NULL_KEY && closestavatar != target)
            {
                closestavatar = target;
                llMessageLinked(LINK_SET, API_CLOSEST_TO_CAM, "", closestavatar);
            }
        }
        else
        {
            if(newclosest != NULL_KEY && closestavatar != newclosest)
            {
                closestavatar = newclosest;
                llMessageLinked(LINK_SET, API_CLOSEST_TO_CAM, "", closestavatar);
            }
        }
        llSetTimerEvent(0.5);
    }
}