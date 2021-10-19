#include <IT/globals.lsl>
key rezzer;
list sitTargetLinks = [];
key urlt;
string url = "null";
integer firstattempt = TRUE;

die()
{
    llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES);
    llSetAlpha(0.0, ALL_SIDES);
    llSetPrimitiveParams([PRIM_TEMP_ON_REZ, TRUE]);
    llDie();
    while(TRUE) llSleep(60.0);
}

default
{
    state_entry()
    {
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
        llListen(BALL_CHANNEL, "", NULL_KEY, "");
        llListen(RLVRC, "", NULL_KEY, "");
        rezzer = llGetOwner();
        llVolumeDetect(TRUE);
        llSetStatus(STATUS_ROTATE_X | STATUS_ROTATE_Y | STATUS_ROTATE_Z, FALSE);
        llSetStatus(STATUS_PHYSICS, FALSE);
    }

    on_rez(integer start_param)
    {
        rezzer = llGetOwnerKey((key)llList2String(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0));
        urlt = llRequestURL();
        if(start_param == 0) return;
        llSetTimerEvent(60.0);
    }

    changed(integer change)
    {
        integer i;
        integer l = llGetListLength(sitTargetLinks);
        if(change & CHANGED_LINK)
        {
            integer avatars = llGetNumberOfPrims() - llGetObjectPrimCount(llGetKey());
            if(avatars > 0)
            {
                llRegionSayTo(rezzer, MANTRA_CHANNEL, "carrierfree " + (string)(llGetListLength(sitTargetLinks) - avatars));
                for(i = 0; i < l; ++i) 
                {
                    if(llAvatarOnLinkSitTarget(llList2Integer(sitTargetLinks, i))) 
                    {
                        llRegionSayTo(llAvatarOnLinkSitTarget(llList2Integer(sitTargetLinks, i)), MANTRA_CHANNEL, "onball " + (string)llGetKey());
                        llRegionSayTo(llAvatarOnLinkSitTarget(llList2Integer(sitTargetLinks, i)), RLVRC, "restrict," + (string)llAvatarOnLinkSitTarget(llList2Integer(sitTargetLinks, i)) + ",@unsit=n|@tplocal=n|@tplm=n|@tploc=n|@tplure_sec=n|@redirchat:" + (string)GAZE_CHAT_CHANNEL + "=add|@rediremote:" + (string)GAZE_CHAT_CHANNEL + "=add|@sendchannel_sec=n|@sendchannel_sec:" + (string)GAZE_CHAT_CHANNEL + "=add");
                    }
                }
                llSetTimerEvent(0.5);
            }
        }
        if(change & CHANGED_REGION)
        {
            url = "null";
            llRegionSayTo(rezzer, MANTRA_CHANNEL, "objurl " + url);
            urlt = llRequestURL();
        }
    }

    listen(integer c, string n, key id, string m)
    {
        integer i;
        integer l = llGetListLength(sitTargetLinks);
        if(c == BALL_CHANNEL)
        {
            if(llGetOwnerKey(id) != rezzer) return;
            string oldn = llGetObjectName();
            llSetObjectName("Predator's Thoughts");
            for(i = 0; i < l; ++i) if(llAvatarOnLinkSitTarget(llList2Integer(sitTargetLinks, i))) llRegionSayTo(llAvatarOnLinkSitTarget(llList2Integer(sitTargetLinks, i)), 0, m);
            llSetObjectName(oldn);
        }
        else if(c == MANTRA_CHANNEL)
        {
            if(llGetOwnerKey(id) != rezzer) return;
            if(m == "unsit")
            {
                integer avatars = llGetNumberOfPrims() - llGetObjectPrimCount(llGetKey());
                if(avatars == 0) die();
                llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES);
                llSetRegionPos(llList2Vector(llGetObjectDetails(rezzer, [OBJECT_POS]), 0) + <0.0, 0.0, 10.0>);
                for(i = 0; i < l; ++i) if(llAvatarOnLinkSitTarget(llList2Integer(sitTargetLinks, i))) llRegionSayTo(llAvatarOnLinkSitTarget(llList2Integer(sitTargetLinks, i)), RLVRC, "release," + (string)llAvatarOnLinkSitTarget(llList2Integer(sitTargetLinks, i)) + ",!release");
                llSleep(0.5);
                for(i = 0; i < l; ++i) if(llAvatarOnLinkSitTarget(llList2Integer(sitTargetLinks, i))) llUnSit(llAvatarOnLinkSitTarget(llList2Integer(sitTargetLinks, i)));
                llSleep(0.5);
                die();
            }
            else if(startswith(m, "sit"))
            {
                m = llDeleteSubString(m, 0, llStringLength("sit"));
                llRegionSayTo((key)m, RLVRC, "cv," + m + ",@sit:" + (string)llGetKey() + "=force|@shownearby=n");
            }
            else if(m == "check")
            {
                integer avatars = llGetNumberOfPrims() - llGetObjectPrimCount(llGetKey());
                if(avatars == 0) die();
            }
            else if(startswith(m, "acidlevel"))
            {
                integer avatars = llGetNumberOfPrims() - llGetObjectPrimCount(llGetKey());
                if(avatars == 0) die();
                llMessageLinked(LINK_SET, IT_CARRIER_ACID, llDeleteSubString(m, 0, llStringLength("acidlevel")), (key)"");
            }
            else if(startswith(m, "dissolve"))
            {
                integer avatars = llGetNumberOfPrims() - llGetObjectPrimCount(llGetKey());
                if(avatars == 0) die();
                llMessageLinked(LINK_SET, IT_CARRIER_ACID_MAX, "", (key)"");
            }
        }
        else if(c == RLVRC)
        {
            if(endswith(m, (string)llGetKey()+",!release,ok"))
            {
                for(i = 0; i < l; ++i) 
                {
                    if(llAvatarOnLinkSitTarget(llList2Integer(sitTargetLinks, i)) == llGetOwnerKey(id))
                    {
                        llRegionSayTo(llAvatarOnLinkSitTarget(llList2Integer(sitTargetLinks, i)), RLVRC, "release," + (string)llAvatarOnLinkSitTarget(llList2Integer(sitTargetLinks, i)) + ",!release");
                        llSleep(0.5);
                        llUnSit(llAvatarOnLinkSitTarget(llList2Integer(sitTargetLinks, i)));
                    }
                }
                integer avatars = llGetNumberOfPrims() - llGetObjectPrimCount(llGetKey());
                if(avatars == 0) die();
            }
            else if(startswith(m, "cv,"))
            {
                llSleep(1.0);
                if(llList2Key(llGetObjectDetails(llGetOwnerKey(id), [OBJECT_ROOT]), 0) == llGetKey()) llRegionSayTo(rezzer, RLVRC, "cv," + llList2String(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0) + ",@sit=n,ok");
                else llRegionSayTo(rezzer, RLVRC, "cv," + llList2String(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0) + ",@sit=n,ko");
            }
        }
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == IT_CARRIER_REGISTER)
        {
            sitTargetLinks = llParseString2List(str, [","], []);
            llRegionSayTo(rezzer, MANTRA_CHANNEL, "carrierfree " + (string)(llGetListLength(sitTargetLinks)));
        }
        else if(num == IT_CARRIER_APPLY_RLV)
        {
            llRegionSayTo(id, RLVRC, "cmd," + (string)id + "," + str);
        }
    }

    timer()
    {
        llRegionSayTo(rezzer, MANTRA_CHANNEL, "objurl " + url);

        integer i;
        integer l = llGetListLength(sitTargetLinks);
        integer avatars = llGetNumberOfPrims() - llGetObjectPrimCount(llGetKey());
        if(avatars == 0) 
        {
            die();
        }
        else
        {
            vector my = llGetPos();
            vector pos = llList2Vector(llGetObjectDetails(rezzer, [OBJECT_POS]), 0);
            float dist = llVecDist(my, pos);

            if(llGetAgentSize(rezzer) == ZERO_VECTOR)
            {
                if(firstattempt)
                {
                    firstattempt = FALSE;
                    llSetTimerEvent(30.0);
                    return;
                }
                else
                {
                    llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES);
                    llSetRegionPos(my + <0.0, 0.0, 10.0>);
                    for(i = 0; i < l; ++i) if(llAvatarOnLinkSitTarget(llList2Integer(sitTargetLinks, i))) llRegionSayTo(llAvatarOnLinkSitTarget(llList2Integer(sitTargetLinks, i)), RLVRC, "release," + (string)llAvatarOnLinkSitTarget(llList2Integer(sitTargetLinks, i)) + ",!release");
                    llSleep(0.5);
                    for(i = 0; i < l; ++i) if(llAvatarOnLinkSitTarget(llList2Integer(sitTargetLinks, i))) llUnSit(llAvatarOnLinkSitTarget(llList2Integer(sitTargetLinks, i)));
                    llSleep(0.5);
                    die();
                    return;
                }
            }
            else
            {
                firstattempt = TRUE;
            }   

            if(dist > 60.0)
            {
                llStopMoveToTarget();
                llSetStatus(STATUS_PHYSICS, FALSE);
                llSetRegionPos(pos);
            }
            else if(dist > 0.05)
            {
                llSetStatus(STATUS_PHYSICS, TRUE);
                llMoveToTarget(pos, 0.1);
            }
            else if(llGetStatus(STATUS_PHYSICS))
            {
                llStopMoveToTarget();
                llSetStatus(STATUS_PHYSICS, FALSE);
            }
        }
    }

    http_request(key id, string method, string body)
    {
        if(id == urlt)
        {
            urlt = NULL_KEY;
            if(method == URL_REQUEST_GRANTED) 
            {
                url = body;
                llRegionSayTo(rezzer, MANTRA_CHANNEL, "objurl " + url);
            }
        }
        else if(method == "POST")
        {
            if(body == "die")
            {
                firstattempt = FALSE;
                llSetTimerEvent(0.1);
            }
            else
            {
                llSetTimerEvent(0.0);
                integer i;
                integer l = llGetListLength(sitTargetLinks);
                for(i = 0; i < l; ++i) if(llAvatarOnLinkSitTarget(llList2Integer(sitTargetLinks, i))) llRegionSayTo(llAvatarOnLinkSitTarget(llList2Integer(sitTargetLinks, i)), RLVRC, "cantp," + (string)llAvatarOnLinkSitTarget(llList2Integer(sitTargetLinks, i)) + ",@unsit=y|@tplocal=y|@tplm=y|@tploc=y|@tpto:" + body + "=force|!release");
                llHTTPResponse(id, 200, "OK");
                llSleep(10.0);
                die();
            }
        }
    }
}