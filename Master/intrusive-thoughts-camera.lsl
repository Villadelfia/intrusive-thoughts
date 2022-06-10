#include <IT/globals.lsl>
key closestavatar;
key closestobject;
integer hidden = FALSE;

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
            llSetObjectName("");
            if(str == "name")
            {
                string owner = (string)id;
                if(owner == "" || owner == "Avatar") owner = guessname();
                llOwnerSay(VERSION_M + ": Set spoof name prefix to " + owner);
            }
            else if(str == "objectprefix")
            {
                string objectprefix = (string)id + " ";
                if(objectprefix == " " || objectprefix == "Avatar's ") objectprefix = guessprefix();
                llOwnerSay(VERSION_M + ": Set spoof object prefix to " + objectprefix);
            }
            else if(str == "food") llOwnerSay(VERSION_M + ": Set food name to '" + (string)id + "'");
            else if(str == "capture") llOwnerSay(VERSION_M + ": Set capture phrase to '" + (string)id + "'");
            else if(str == "release") llOwnerSay(VERSION_M + ": Set release phrase to '" + (string)id + "'");
            else if(str == "puton") llOwnerSay(VERSION_M + ": Set put on phrase to '" + (string)id + "'");
            else if(str == "putdown") llOwnerSay(VERSION_M + ": Set put down phrase to '" + (string)id + "'");
            else if(str == "vore") llOwnerSay(VERSION_M + ": Set vore phrase to '" + (string)id + "'");
            else if(str == "unvore") llOwnerSay(VERSION_M + ": Set unvore phrase to '" + (string)id + "'");
            else if(str == "possess") llOwnerSay(VERSION_M + ": Set possess phrase to '" + (string)id + "'");
            else if(str == "unpossess") llOwnerSay(VERSION_M + ": Set unpossess phrase to '" + (string)id + "'");
            else if(str == "ball" && ((string)id == "1" || (string)id == "2"))
            {
                if((integer)((string)id) == 1)
                {
                    llOwnerSay(VERSION_M + ": Objectifiying something will put it below the floor.");
                }
                else
                {
                    llOwnerSay(VERSION_M + ": Objectifiying something will make it invisible.");
                }
            }
            else if(startswith(str, "capture:")) llOwnerSay(VERSION_M + ": Set capture phrase for '" + llGetSubString(str, 8, -1) + "' to '" + (string)id + "'");
            else if(startswith(str, "release:")) llOwnerSay(VERSION_M + ": Set release phrase for '" + llGetSubString(str, 8, -1) + "' to '" + (string)id + "'");
            llSetObjectName(master_base);
        }
        else if(num == M_API_CONFIG_DONE)
        {
            llRequestPermissions(llGetOwner(), PERMISSION_TRACK_CAMERA | PERMISSION_TRIGGER_ANIMATION);
            hidden = FALSE;
        }
        else if(num == M_API_TOGGLE_HIDE)
        {
            llSetObjectName("");
            if(hidden)
            {
                hidden = FALSE;
                llOwnerSay("You're visible again.");
                llStopAnimation("hide");
            }
            else
            {
                hidden = TRUE;
                llOwnerSay("You're invisible now.");
                llStartAnimation("hide");
            }
            llSetObjectName(master_base);
        }
        else if(num == M_API_HIDE_OFF)
        {
            llSetObjectName("");
            if(hidden)
            {
                hidden = FALSE;
                llOwnerSay("You're visible again.");
                llStopAnimation("hide");
            }
            llSetObjectName(master_base);
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
