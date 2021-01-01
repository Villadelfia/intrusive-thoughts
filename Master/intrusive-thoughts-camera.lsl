#include <IT/globals.lsl>
key closestavatar;
key closestobject;

default
{
    attach(key id)
    {
        llSetTimerEvent(0.0);
    }

    run_time_permissions(integer perm)
    {
        if(perm & PERMISSION_TRACK_CAMERA) llSetTimerEvent(0.5);
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == M_API_CONFIG_DATA)
        {
            if(str == "name") llOwnerSay(VERSION_C + ": Set spoof name prefix to " + (string)id);
            else if(str == "objectprefix") llOwnerSay(VERSION_C + ": Set spoof object prefix to " + (string)id);
            else if(str == "capture") llOwnerSay(VERSION_C + ": Set capture phrase to '" + (string)id + "'");
            else if(str == "release") llOwnerSay(VERSION_C + ": Set release phrase to '" + (string)id + "'");
            else if(str == "puton") llOwnerSay(VERSION_C + ": Set put on phrase to '" + (string)id + "'");
            else if(str == "putdown") llOwnerSay(VERSION_C + ": Set put down phrase to '" + (string)id + "'");
            else if(str == "food") llOwnerSay(VERSION_C + ": Set food name to '" + (string)id + "'");
            else if(str == "vore") llOwnerSay(VERSION_C + ": Set vore phrase to '" + (string)id + "'");
            else if(str == "unvore") llOwnerSay(VERSION_C + ": Set unvore phrase to '" + (string)id + "'");
            else if(str == "ball" && ((string)id == "1" || (string)id == "2")) 
            {
                if((integer)((string)id) == 1)
                {
                    llOwnerSay(VERSION_C + ": Objectifiying something will put it below the floor.");
                }
                else
                {
                    llOwnerSay(VERSION_C + ": Objectifiying something will make it invisible.");
                }
            }
        }
        else if(num == M_API_HUD_STARTED)
        {
            llRequestPermissions(llGetOwner(), PERMISSION_TRACK_CAMERA);
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
            if(target != NULL_KEY)
            {
                closestavatar = target;
                llMessageLinked(LINK_SET, M_API_CAM_AVATAR, llGetDisplayName(closestavatar), closestavatar);
            }
        }
        else
        {
            if(newclosest != NULL_KEY)
            {
                closestavatar = newclosest;
                llMessageLinked(LINK_SET, M_API_CAM_AVATAR, llGetDisplayName(closestavatar), closestavatar);
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
            closestobject = target;
            llMessageLinked(LINK_SET, M_API_CAM_OBJECT, name, target);
        }

        llSetTimerEvent(0.5);
    }
}