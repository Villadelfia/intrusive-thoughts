#include <IT/globals.lsl>
key rezzer;
key firstavatar;
integer volumelink;
key focuskey;
float fillfactor = 0.25;
integer ticks = 0;
integer dissolved = FALSE;

list whitelist = ["boot",    "top",      "bangle", "armband", "bracer", "thigh",  "ring", 
                  "suit",    "lingerie", "bra",    "shoe",    "glove",  "sock",   "stocking", 
                  "leotard", "tight",    "skirt",  "warmers", "robe",   "kimono", "pant",
                  "sandal",  "jean",     "string", "bikini",  "heel",   "dress",  "sarong",
                  "glasses", "corset",   "tube",   "dress",   "legging"];

die()
{
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
                llRequestPermissions(llAvatarOnLinkSitTarget(volumelink), PERMISSION_TRIGGER_ANIMATION);
            }
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
        llResetTime();
        llSetTimerEvent(0.5);
    }

    touch_start(integer num)
    {
        if(llDetectedKey(0) != llAvatarOnLinkSitTarget(volumelink)) return;
        ticks = 0;
        llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), RLVRC, "focus," + (string)llAvatarOnLinkSitTarget(volumelink) + ",@setcam_focus:" + (string)rezzer + ";2;0/1/0=force");
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
            else if(startswith(m, "rlvforward"))
            {
                if(llAvatarOnLinkSitTarget(volumelink) == NULL_KEY) die();
                m = llDeleteSubString(m, 0, llStringLength("rlvforward"));
                llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), RLVRC, "cmd," + (string)llAvatarOnLinkSitTarget(volumelink) + "," + m);
                llRegionSayTo(rezzer, MANTRA_CHANNEL, "rlvresponse ok");
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
                llMessageLinked(LINK_SET, X_API_FILL_FACTOR, (string)height, (key)"");
            }
            else if(startswith(m, "dissolve"))
            {
                if(llAvatarOnLinkSitTarget(volumelink) == NULL_KEY) die();
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
        }
    }

    timer()
    {
        if(llAvatarOnLinkSitTarget(volumelink) == NULL_KEY)
        {
            die();
        }
        else
        {
            vector my = llGetPos();

            if(llGetAgentSize(rezzer) == ZERO_VECTOR)
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

            vector pos = llList2Vector(llGetObjectDetails(rezzer, [OBJECT_POS]), 0);
            float dist = llVecDist(my, pos);
            my.z = pos.z;
            float xydist = llVecDist(my, pos);
            if(xydist > 365.0 || pos == ZERO_VECTOR)
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
}