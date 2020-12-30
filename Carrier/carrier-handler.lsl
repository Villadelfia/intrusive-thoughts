#include <IT/globals.lsl>
key rezzer;
key firstavatar;

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
        llLinkSitTarget(1, <-0.51009, -0.68207, -0.59165>, <0.69741, -0.11671, 0.11671, 0.69741>);
        rezzer = llGetOwner();
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
            if(llAvatarOnSitTarget() != NULL_KEY)
            {
                if(firstavatar == NULL_KEY) firstavatar = llAvatarOnSitTarget();
                if(firstavatar != llAvatarOnSitTarget()) llUnSit(llAvatarOnSitTarget());
                llListen(RLVRC, "", NULL_KEY, "");
                llListen(COMMAND_CHANNEL, "", rezzer, "");
                llRequestPermissions(llAvatarOnSitTarget(), PERMISSION_TRIGGER_ANIMATION);
            }
        }
    }

    run_time_permissions(integer perm)
    {
        string oldn = llGetObjectName();
        llSetObjectName("Your stomach");
        llOwnerSay("Type /1acidlevel <0-100> to set the acid level in the carrier.");
        llSetObjectName(oldn);
        llRegionSayTo(llAvatarOnSitTarget(), MANTRA_CHANNEL, "onball " + (string)llGetKey());
        llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@shownames_sec:" + (string)llGetOwnerKey(rezzer) + "=n|@shownametags=n|@shownearby=n|@showhovertextall=n|@showworldmap=n|@showminimap=n|@showloc=n|@setcam_avdistmin:2=n|@setcam_avdistmax:2=n|@setcam_focus:" + (string)llAvatarOnSitTarget() + ";2;0/1/0=force|@buy=n|@pay=n|@unsit=n|@tplocal=n|@tplm=n|@tploc=n|@tplure_sec=n|@showinv=n|@interact=n|@sendgesture=n|@redirchat:" + (string)GAZE_CHAT_CHANNEL + "=add|@rediremote:" + (string)GAZE_CHAT_CHANNEL + "=add|@sendchannel_sec=n|@sendchannel_sec:" + (string)GAZE_CHAT_CHANNEL + "=add|@setoverlay=n|@setoverlay_texture:5ace8e33-db4a-3596-3dd2-98b82516b5d1=force");
        llStartAnimation(llGetInventoryName(INVENTORY_ANIMATION, 0));
        llSetTimerEvent(0.5);
    }

    listen(integer c, string n, key id, string m)
    {
        if(c == BALL_CHANNEL)
        {
            if(llGetOwnerKey(id) != rezzer) return;
            string oldn = llGetObjectName();
            llSetObjectName("Predator's Thoughts");
            llRegionSayTo(llAvatarOnSitTarget(), 0, m);
            llSetObjectName(oldn);
        }
        else if(c == MANTRA_CHANNEL)
        {
            if(llGetOwnerKey(id) != rezzer) return;
            if(m == "unsit")
            {
                if(llAvatarOnSitTarget() == NULL_KEY) die();
                llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES);
                llSetRegionPos(llList2Vector(llGetObjectDetails(rezzer, [OBJECT_POS]), 0));
                llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "release," + (string)llAvatarOnSitTarget() + ",!release");
                llSleep(0.5);
                llUnSit(llAvatarOnSitTarget());
                llSleep(0.5);
                die();
            }
            else if(m == "abouttotp")
            {
                if(llAvatarOnSitTarget() == NULL_KEY) die();
                llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES);
                llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "release," + (string)llAvatarOnSitTarget() + ",!release");
                llSleep(0.5);
                llUnSit(llAvatarOnSitTarget());
                llSleep(0.5);
                die();
            }
            else if(m == "check")
            {
                if(llAvatarOnSitTarget() == NULL_KEY) die();
            }
        }
        else if(c == COMMAND_CHANNEL)
        {
            if(startswith(m, "acidlevel"))
            {
                if(llAvatarOnSitTarget() == NULL_KEY) die();
                float height = (float)llDeleteSubString(m, 0, llStringLength("acidlevel"));
                height /= 100.0;
                llMessageLinked(LINK_SET, API_FILL_FACTOR, (string)height, (key)"");
            }
        }
        else if(c == RLVRC)
        {
            if(endswith(m, (string)llGetKey()+",!release,ok"))
            {
                llOwnerSay("Releasing captive...");
                llSetRegionPos(llList2Vector(llGetObjectDetails(rezzer, [OBJECT_POS]), 0));
                llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "release," + (string)llAvatarOnSitTarget() + ",!release");
                llSleep(0.5);
                llUnSit(llAvatarOnSitTarget());
                llSleep(10.0);
                die();
            }
        }
    }

    timer()
    {
        if(llGetNumberOfPrims() == 1)
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
                llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "release," + (string)llAvatarOnSitTarget() + ",!release");
                llSleep(0.5);
                llUnSit(llAvatarOnSitTarget());
                llSleep(0.5);
                die();
                return;
            }

            vector pos = llList2Vector(llGetObjectDetails(rezzer, [OBJECT_POS]), 0) - <0.0, 0.0, 10.0>;
            if(llVecDist(my, pos) > 365 || pos == ZERO_VECTOR)
            {
                llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES);
                llSetRegionPos(my + <0.0, 0.0, 10.0>);
                llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "release," + (string)llAvatarOnSitTarget() + ",!release");
                llSleep(0.5);
                llUnSit(llAvatarOnSitTarget());
                llSleep(0.5);
                die();
                return;
            }
            if(my != pos) llSetRegionPos(pos);
        }
    }
}