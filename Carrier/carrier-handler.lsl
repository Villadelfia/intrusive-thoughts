#include <IT/globals.lsl>
key rezzer;
key urlt;
string url = "null";
key firstavatar = NULL_KEY;
integer volumelink;
key focuskey;
float fillfactor = 0.25;
integer ticks = 0;
integer dissolved = FALSE;
integer struggleEvents = 0;
integer struggleFailed = FALSE;
integer captured = FALSE;
integer firstattempt = TRUE;

list whitelist = ["boot",    "top",      "bangle", "armband", "bracer", "thigh",  "ring", 
                  "suit",    "lingerie", "bra",    "shoe",    "glove",  "sock",   "stocking", 
                  "leotard", "tight",    "skirt",  "warmers", "robe",   "kimono", "pant",
                  "sandal",  "jean",     "string", "bikini",  "heel",   "dress",  "sarong",
                  "glasses", "corset",   "tube",   "dress",   "legging"];

die()
{
    if(firstavatar) llRegionSayTo(rezzer, STRUGGLE_CHANNEL, "released|" + (string)firstavatar);
    llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES);
    llSetAlpha(0.0, ALL_SIDES);
    llSetPrimitiveParams([PRIM_TEMP_ON_REZ, TRUE]);
    llDie();
    while(TRUE) llSleep(60.0);
}

detachrandom()
{
    if(dissolved) return;
    if(fillfactor < 0.4) return;
    llResetTime();
    list worn = llGetAttachedList(llAvatarOnLinkSitTarget(volumelink));
    worn = llListRandomize(worn, 1);
    integer l = llGetListLength(worn);
    while(~--l)
    {
        key k = llList2Key(worn, l);
        string name = llList2String(llGetObjectDetails(k, [OBJECT_NAME]), 0);
        integer m = llGetListLength(whitelist);
        while(~--m)
        {
            if(contains(llToLower(name), llList2String(whitelist, m)))
            {
                llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), RLVRC, "acid," + (string)llAvatarOnLinkSitTarget(volumelink) + ",@remattach:" + (string)k + "=force");
                string oldn = llGetObjectName();
                llSetObjectName("The Acid");
                llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), 0, "/me in your predator's stomach has dissolved your '" + name + "'.");
                llSetObjectName(oldn);
                return;
            }
        }
    }
}

default
{
    state_entry()
    {
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
        llListen(BALL_CHANNEL, "", NULL_KEY, "");
        llListen(STRUGGLE_CHANNEL, "", NULL_KEY, "");
        integer i = llGetNumberOfPrims();
        for (; i >= 0; --i)
        {
            if (llGetLinkName(i) == "volume")
            {
                volumelink = i;
                llLinkSitTarget(i, <-0.51009, -0.68207, -0.59165>, <0.69741, -0.11671, 0.11671, 0.69741>);
                llOwnerSay("Volume link found at link number " + (string)i + ".");
            }
            else
            {
                llLinkSitTarget(i, ZERO_VECTOR, ZERO_ROTATION);
            }
        }
        rezzer = llGetOwner();
        llVolumeDetect(TRUE);
        llSetStatus(STATUS_ROTATE_X | STATUS_ROTATE_Y | STATUS_ROTATE_Z, FALSE);
        llSetStatus(STATUS_PHYSICS, FALSE);
    }

    on_rez(integer start_param)
    {
        rezzer = llGetOwnerKey((key)llList2String(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0));
        urlt = llRequestURL();
        firstavatar = NULL_KEY;
        if(start_param == 0) return;
        llSetTimerEvent(60.0);
    }

    changed(integer change)
    {
        if(change & CHANGED_LINK)
        {
            if(llAvatarOnLinkSitTarget(volumelink) != NULL_KEY)
            {
                if(firstavatar == NULL_KEY)
                {
                    firstavatar = llAvatarOnLinkSitTarget(volumelink);
                    llListen(RLVRC, "", NULL_KEY, "");
                }
                if(firstavatar != llAvatarOnLinkSitTarget(volumelink)) llUnSit(llAvatarOnLinkSitTarget(volumelink));
                integer i = llGetNumberOfPrims();
                focuskey = NULL_KEY;
                for (; i >= 0; --i)
                {
                    if(llGetLinkName(i) == "focus")
                    {
                        focuskey = llGetLinkKey(i);
                    }
                }
                if(focuskey == NULL_KEY) focuskey = llAvatarOnLinkSitTarget(volumelink);
                if(!captured) 
                {
                    llRegionSayTo(rezzer, STRUGGLE_CHANNEL, "captured|" + (string)firstavatar + "|vore");
                    llRegionSayTo(rezzer, STRUGGLE_CHANNEL, "acid_level|" + (string)firstavatar + "|" + (string)fillfactor);
                    captured = TRUE;
                }
                llRequestPermissions(llAvatarOnLinkSitTarget(volumelink), PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS);
            }
        }
        if(change & CHANGED_REGION)
        {
            url = "null";
            llRegionSayTo(rezzer, MANTRA_CHANNEL, "objurl " + url);
            urlt = llRequestURL();
        }
    }

    run_time_permissions(integer perm)
    {
        llSleep(1.0);
        llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), MANTRA_CHANNEL, "onball " + (string)llGetKey());
        llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), RLVRC, "restrict," + (string)llAvatarOnLinkSitTarget(volumelink) + ",@shownames_sec:" + (string)llGetOwnerKey(rezzer) + "=n|@shownametags=n|@shownearby=n|@showhovertextall=n|@showworldmap=n|@showminimap=n|@showloc=n|@setcam_focus:" + (string)focuskey + ";0;0/1/0=force|@buy=n|@pay=n|@unsit=n|@tplocal=n|@tplm=n|@tploc=n|@tplure_sec=n|@showinv=n|@fartouch:5=n|@rez=n|@edit=n|@sendgesture=n|@redirchat:" + (string)GAZE_CHAT_CHANNEL + "=add|@rediremote:" + (string)GAZE_CHAT_CHANNEL + "=add|@sendchannel_sec=n|@sendchannel_sec:" + (string)GAZE_CHAT_CHANNEL + "=add|@setoverlay=n|@setoverlay_texture:5ace8e33-db4a-3596-3dd2-98b82516b5d1=force");
        llStartAnimation("sit");
        string oldn = llGetObjectName();
        llSetObjectName("Predator's Stomach");
        llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), 0, "Click me to see the outside world for 30 seconds.");
        llSetObjectName(oldn);
        ticks = 100;
        llTakeControls(CONTROL_FWD | CONTROL_BACK | CONTROL_LEFT | CONTROL_RIGHT | CONTROL_ROT_LEFT | CONTROL_ROT_RIGHT | CONTROL_UP | CONTROL_DOWN, TRUE, TRUE);
        llResetTime();
        llSetTimerEvent(0.5);
    }

    touch_start(integer num)
    {
        if(llDetectedKey(0) != llAvatarOnLinkSitTarget(volumelink)) return;
        ticks = 0;
        llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), RLVRC, "focus," + (string)llAvatarOnLinkSitTarget(volumelink) + ",@setcam_focus:" + (string)rezzer + ";2;0/1/0=force");
    }
    
    control(key id, integer level, integer edge)
    {
        integer start = level & edge;
        if(start) struggleEvents++;
    }

    listen(integer c, string n, key id, string m)
    {
        if(c == BALL_CHANNEL)
        {
            if(llGetOwnerKey(id) != rezzer) return;
            string oldn = llGetObjectName();
            llSetObjectName("Predator's Thoughts");
            llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), 0, m);
            llSetObjectName(oldn);
        }
        else if(c == MANTRA_CHANNEL)
        {
            if(llGetOwnerKey(id) != rezzer) return;
            if(m == "unsit")
            {
                if(llAvatarOnLinkSitTarget(volumelink) == NULL_KEY) die();
                llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES);
                llSetRegionPos(llList2Vector(llGetObjectDetails(rezzer, [OBJECT_POS]), 0) + <0.0, 0.0, 10.0>);
                if(dissolved)
                {
                    string oldn = llGetObjectName();
                    llSetObjectName("");
                    llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), 0, "Note: The animation currently making you invisible can be a little tricky to get rid of. If you remain invisible after you are freed, put on something and then take it off again. If this doesn't help, relog.");
                    llSetObjectName(oldn);
                }
                llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), RLVRC, "release," + (string)llAvatarOnLinkSitTarget(volumelink) + ",!release");
                llSleep(0.5);
                llUnSit(llAvatarOnLinkSitTarget(volumelink));
                llSleep(0.5);
                die();
            }
            else if(startswith(m, "sit"))
            {
                m = llDeleteSubString(m, 0, llStringLength("sit"));
                firstavatar = (key)m;
                llListen(RLVRC, "", NULL_KEY, "");
                llRegionSayTo((key)m, RLVRC, "cv," + m + ",@sit:" + (string)llGetKey() + "=force|@shownearby=n");
            }
            else if(m == "check")
            {
                if(llAvatarOnLinkSitTarget(volumelink) == NULL_KEY) die();
            }
            else if(startswith(m, "acidlevel"))
            {
                if(llAvatarOnLinkSitTarget(volumelink) == NULL_KEY) die();
                float height = (float)llDeleteSubString(m, 0, llStringLength("acidlevel"));
                height /= 100.0;
                fillfactor = height;
                llRegionSayTo(rezzer, STRUGGLE_CHANNEL, "acid_level|" + (string)firstavatar + "|" + (string)fillfactor);
                llMessageLinked(LINK_SET, X_API_FILL_FACTOR, (string)height, (key)"");
            }
            else if(startswith(m, "dissolve"))
            {
                if(llAvatarOnLinkSitTarget(volumelink) == NULL_KEY) die();
                llRegionSayTo(rezzer, STRUGGLE_CHANNEL, "acid_dissolve|" + (string)firstavatar);
                llStopAnimation("sit");
                llStartAnimation("digest");
                dissolved = TRUE;
                string oldn = llGetObjectName();
                llSetObjectName("The Acid");
                llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), 0, "/me in your predator's stomach has completely dissolved you.");
                llSetObjectName(oldn);
            }
        }
        else if(c == RLVRC)
        {
            if(endswith(m, (string)llGetKey()+",!release,ok"))
            {
                llSetRegionPos(llList2Vector(llGetObjectDetails(rezzer, [OBJECT_POS]), 0) + <0.0, 0.0, 10.0>);
                llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), RLVRC, "release," + (string)llAvatarOnLinkSitTarget(volumelink) + ",!release");
                llSleep(0.5);
                llUnSit(llAvatarOnLinkSitTarget(volumelink));
                llSleep(10.0);
                die();
            }
            else if(startswith(m, "cv,"))
            {
                llSleep(1.0);
                if(llList2Key(llGetObjectDetails(firstavatar, [OBJECT_ROOT]), 0) == llGetKey()) llRegionSayTo(rezzer, RLVRC, "cv," + llList2String(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0) + ",@sit=n,ok");
                else llRegionSayTo(rezzer, RLVRC, "cv," + llList2String(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0) + ",@sit=n,ko");
            }
        }
        else if(c == STRUGGLE_CHANNEL)
        {
            if(llGetOwnerKey(id) != rezzer) return;
            if(llAvatarOnLinkSitTarget(volumelink) == NULL_KEY) die();
            if(startswith(m, "struggle_fail"))
            {
                list params = llParseString2List(m, ["|"], []);
                m = llList2String(llParseString2List(m, ["|"], []), -1);
                if(llGetListLength(params) == 2 || (llGetListLength(params) == 3 && (key)llList2String(params, 1) == firstavatar))
                {
                    llSetObjectName("");
                    llRegionSayTo(firstavatar, 0, m);
                    llReleaseControls();
                    struggleFailed = FALSE;
                }
            }
            else if(startswith(m, "struggle_success"))
            {
                list params = llParseString2List(m, ["|"], []);
                m = llList2String(llParseString2List(m, ["|"], []), -1);
                if(llGetListLength(params) == 2 || (llGetListLength(params) == 3 && (key)llList2String(params, 1) == firstavatar))
                {
                    llSetObjectName("");
                    llRegionSayTo(firstavatar, 0, m);
                    llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES);
                    llSetRegionPos(llList2Vector(llGetObjectDetails(rezzer, [OBJECT_POS]), 0) + <0.0, 0.0, 10.0>);
                    if(dissolved) llRegionSayTo(firstavatar, 0, "Note: The animation currently making you invisible can be a little tricky to get rid of. If you remain invisible after you are freed, put on something and then take it off again. If this doesn't help, relog.");
                    llRegionSayTo(firstavatar, RLVRC, "release," + (string)firstavatar + ",!release");
                    llSleep(0.5);
                    llUnSit(firstavatar);
                    llSleep(0.5);
                    die();
                }
            }
        }
    }

    timer()
    {
        llRegionSayTo(rezzer, MANTRA_CHANNEL, "objurl " + url);

        if(struggleEvents > 0 && struggleFailed == FALSE)
        {
            llRegionSayTo(rezzer, STRUGGLE_CHANNEL, "struggle_count|" + (string)firstavatar + "|" + (string)struggleEvents);
            struggleEvents = 0;
        }

        if(llAvatarOnLinkSitTarget(volumelink) == NULL_KEY)
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
                    llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), RLVRC, "release," + (string)llAvatarOnLinkSitTarget(volumelink) + ",!release");
                    llSleep(0.5);
                    llUnSit(llAvatarOnLinkSitTarget(volumelink));
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

            ticks++;
            if(ticks > 60) llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), RLVRC, "focus," + (string)llAvatarOnLinkSitTarget(volumelink) + ",@setcam_focus:" + (string)focuskey + ";0;0/1/0=force");
            if(llGetTime() > 60.0) detachrandom();
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
                llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), RLVRC, "cantp," + (string)llAvatarOnLinkSitTarget(volumelink) + ",@unsit=y|@tplocal=y|@tplm=y|@tploc=y|@tpto:" + body + "=force|!release");
                llHTTPResponse(id, 200, "OK");
                llSleep(10.0);
                die();
            }
        }
    }
}