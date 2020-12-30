#include <IT/globals.lsl>
#define avataroffset <0.0, 0.0, -3.0>
string animation = "";
key rezzer;
key firstavatar;
integer keyisavatar;
integer saton;
integer editmode;
vector seatedoffset;
vector oldpos;
string name;
integer waitingstate;

die()
{
    llSetAlpha(0.0, ALL_SIDES);
    llSetPrimitiveParams([PRIM_TEMP_ON_REZ, TRUE]);
    llDie();
    while(TRUE) llSleep(60.0);
}

toggleedit()
{
    if(editmode == FALSE && (keyisavatar == FALSE || (llGetAgentInfo(rezzer) & AGENT_SITTING) == 0))
    {
        string oldn = llGetObjectName();
        llSetObjectName(name);
        llOwnerSay("I must be following a seated avatar to edit my position.");
        llSetObjectName(oldn);
        return;
    }
    editmode = !editmode;
    if(editmode)
    {
        oldpos = llList2Vector(llGetObjectDetails(rezzer, [OBJECT_POS]), 0) + seatedoffset;
        llSetRegionPos(oldpos);
        llSetAlpha(1.0, ALL_SIDES);
        llSetScale(<0.1, 0.1, 5.0>);
    }
    else
    {
        vector offset = llGetPos() - oldpos;
        seatedoffset += offset;
        llSetAlpha(0.0, ALL_SIDES);
        llSetScale(<0.1, 0.1, 0.1>);
    }
}

default
{
    state_entry()
    {
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
        llListen(BALL_CHANNEL, "", NULL_KEY, "");
        llSitTarget(<0.0, 0.0, 0.001>, ZERO_ROTATION);
        rezzer = llGetOwner();
    }

    on_rez(integer start_param)
    {
        rezzer = llGetOwnerKey((key)llList2String(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0));
        firstavatar = NULL_KEY;
        keyisavatar = TRUE;
        saton = FALSE;
        editmode = FALSE;
        seatedoffset = ZERO_VECTOR;
        waitingstate = 0;
        if(start_param & 1)      animation = "hide_a";
        else if(start_param & 2) animation = "hide_b";
        else                     return;
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
                saton = TRUE;
                llListen(GAZE_CHAT_CHANNEL, "", llAvatarOnSitTarget(), "");
                llListen(RLVRC, "", NULL_KEY, "");
                llRequestPermissions(llAvatarOnSitTarget(), PERMISSION_TRIGGER_ANIMATION);
            }
        }
    }

    run_time_permissions(integer perm)
    {
        llRegionSayTo(llAvatarOnSitTarget(), MANTRA_CHANNEL, "onball " + (string)llGetKey());
        llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@shownames_sec:" + (string)llGetOwnerKey(rezzer) + "=n|@shownametags=n|@shownearby=n|@showhovertextall=n|@showworldmap=n|@showminimap=n|@showloc=n|@setcam_focus:" + (string)rezzer + ";;1/0/0=force|@setcam_origindistmax:10=n|@buy=n|@pay=n|@unsit=n|@tplocal=n|@tplm=n|@tploc=n|@tplure_sec=n|@showinv=n|@interact=n|@showself=n|@sendgesture=n|@redirchat:" + (string)GAZE_CHAT_CHANNEL + "=add|@rediremote:" + (string)GAZE_CHAT_CHANNEL + "=add|@sendchannel_sec=n|@sendchannel_sec:" + (string)GAZE_CHAT_CHANNEL + "=add|@recvim:10=n|@sendim:10=n");
        llStartAnimation(animation);
        llSetTimerEvent(0.5);
    }

    touch_start(integer num_detected)
    {
        if(llDetectedKey(0) == llGetOwnerKey(rezzer) && editmode == TRUE) toggleedit();
    }

    listen(integer c, string n, key id, string m)
    {
        if(c == GAZE_CHAT_CHANNEL)
        {
            if(keyisavatar == TRUE) return;
            string oldn = llGetObjectName();
            llSetObjectName(name);
            if(llToLower(llStringTrim(m, STRING_TRIM)) == "/me" || startswith(m, "/me") == FALSE || contains(m, "\"") == TRUE)
            {
                llRegionSayTo(llAvatarOnSitTarget(), 0, m);
            }
            else
            {
                llSay(0, m);
            }
            llSetObjectName(oldn);
        }
        else if(c == BALL_CHANNEL)
        {
            if(keyisavatar == FALSE || llGetOwnerKey(id) != rezzer) return;
            string oldn = llGetObjectName();
            llSetObjectName("Wearer's Thoughts");
            llRegionSayTo(llAvatarOnSitTarget(), 0, m);
            llSetObjectName(oldn);
        }
        else if(c == MANTRA_CHANNEL)
        {
            if(m == "unsit")
            {
                if(llAvatarOnSitTarget() == NULL_KEY) die();
                llSetRegionPos(llList2Vector(llGetObjectDetails(rezzer, [OBJECT_POS]), 0));
                llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "release," + (string)llAvatarOnSitTarget() + ",@shownames_sec=y|@shownametags=y|@shownearby=y|@showhovertextall=y|@showworldmap=y|@showminimap=y|@showloc=y|@setcam_origindistmax:10=y|@buy=y|@pay=y|@unsit=y|@tplocal=y|@tplm=y|@tploc=y|@tplure_sec=y|@showinv=y|@interact=y|@showself=y|@sendgesture=y|@redirchat:" + (string)GAZE_CHAT_CHANNEL + "=rem|@rediremote:" + (string)GAZE_CHAT_CHANNEL + "=rem|@sendchannel_sec=y|@sendchannel_sec:" + (string)GAZE_CHAT_CHANNEL + "=rem");
                llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "release," + (string)llAvatarOnSitTarget() + ",!release");
                llSleep(0.5);
                llUnSit(llAvatarOnSitTarget());
                if(animation == "hide_b")
                {
                    string oldn = llGetObjectName();
                    llSetObjectName("");
                    llRegionSayTo(llAvatarOnSitTarget(), 0, "Note: The animation currently making you invisible can be a little tricky to get rid of. If you remain invisible after you are freed, try undeforming yourself via the Avatar -> Avatar Health menu. If that doesn't work, teleport to a different region, and as a last resort, you can relog.");
                    llSetObjectName(oldn);
                }
                llSleep(10.0);
                die();
            }
            else if(m == "abouttotp")
            {
                if(llAvatarOnSitTarget() == NULL_KEY) die();
                llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "release," + (string)llAvatarOnSitTarget() + ",@shownames_sec=y|@shownametags=y|@shownearby=y|@showhovertextall=y|@showworldmap=y|@showminimap=y|@showloc=y|@setcam_origindistmax:10=y|@buy=y|@pay=y|@unsit=y|@tplocal=y|@tplm=y|@tploc=y|@tplure_sec=y|@showinv=y|@interact=y|@showself=y|@sendgesture=y|@redirchat:" + (string)GAZE_CHAT_CHANNEL + "=rem|@rediremote:" + (string)GAZE_CHAT_CHANNEL + "=rem|@sendchannel_sec=y|@sendchannel_sec:" + (string)GAZE_CHAT_CHANNEL + "=rem");
                llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "release," + (string)llAvatarOnSitTarget() + ",!release");
                llSleep(0.5);
                llUnSit(llAvatarOnSitTarget());
                llSleep(10.0);
                die();
            }
            else if(m == "check")
            {
                if(llAvatarOnSitTarget() == NULL_KEY) die();
            }
            else if(m == "edit" && llGetOwnerKey(id) == llGetOwnerKey(rezzer) && keyisavatar == TRUE)
            {
                toggleedit();
            }
            else if(startswith(m, "puton"))
            {
                if(llAvatarOnSitTarget() == NULL_KEY) die();
                list params = llParseString2List(llDeleteSubString(m, 0, llStringLength("puton")), ["|||"], []);
                rezzer = (key)llList2String(params, 0);
                name = llList2String(params, 1);
                llRegionSayTo(rezzer, MANTRA_CHANNEL, "puton " + (string)llAvatarOnSitTarget() + "|||" + name);
                keyisavatar = TRUE;
                llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@shownames_sec:" + (string)llGetOwnerKey(rezzer) + "=n");
            }
            else if(startswith(m, "putdown"))
            {
                if(llAvatarOnSitTarget() == NULL_KEY) die();
                list params = llParseString2List(llDeleteSubString(m, 0, llStringLength("putdown")), ["|||"], []);
                rezzer = (key)llList2String(params, 0);
                name = llList2String(params, 1);
                keyisavatar = FALSE;
                llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "unrestrict," + (string)llAvatarOnSitTarget() + ",@recvim:10=y|@sendim:10=y");
            }
        }
        else if(c == RLVRC && waitingstate < 4)
        {
            if(m == "ping," + (string)llGetKey() + ",ping,ping") 
            {
                string oldn = llGetObjectName();
                llSetObjectName(name);
                llSay(0, "Attempting recapture...");
                llSetObjectName(oldn);
                llRegionSay(RLVRC, "ping," + (string)llGetOwnerKey(id) + ",!pong");
            }
            else if(endswith(m, (string)llGetKey()+",!release,ok"))
            {
                string oldn = llGetObjectName();
                llSetObjectName(name);
                llSay(0, "Releasing captive...");
                llSetRegionPos(llList2Vector(llGetObjectDetails(rezzer, [OBJECT_POS]), 0));
                llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "release," + (string)llAvatarOnSitTarget() + ",@shownames_sec=y|@shownametags=y|@shownearby=y|@showhovertextall=y|@showworldmap=y|@showminimap=y|@showloc=y|@setcam_origindistmax:10=y|@buy=y|@pay=y|@unsit=y|@tplocal=y|@tplm=y|@tploc=y|@tplure_sec=y|@showinv=y|@interact=y|@showself=y|@sendgesture=y|@redirchat:" + (string)GAZE_CHAT_CHANNEL + "=rem|@rediremote:" + (string)GAZE_CHAT_CHANNEL + "=rem|@sendchannel_sec=y|@sendchannel_sec:" + (string)GAZE_CHAT_CHANNEL + "=rem");
                llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "release," + (string)llAvatarOnSitTarget() + ",!release");
                llSleep(0.5);
                llUnSit(llAvatarOnSitTarget());
                if(animation == "hide_b")
                {
                    llSetObjectName("");
                    llRegionSayTo(llAvatarOnSitTarget(), 0, "Note: The animation currently making you invisible can be a little tricky to get rid of. If you remain invisible after you are freed, try undeforming yourself via the Avatar -> Avatar Health menu. If that doesn't work, teleport to a different region, and as a last resort, you can relog.");
                    llSetObjectName(oldn);
                }
                llSleep(10.0);
                die();
            }
        }
    }

    timer()
    {
        if(editmode)
        {
            llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@setcam_focus:" + (string)rezzer + ";;=force");
            return;
        }

        if(llGetNumberOfPrims() == 1)
        {
            integer hours = (integer)llGetObjectDesc();
            
            // If we were never sat on, delete.
            if(saton == FALSE) die();

            // If the key is an avatar, delete.
            if(keyisavatar) die();

            // Just recently vacated.
            if(waitingstate == 0)
            {
                string oldn = llGetObjectName();
                llSetObjectName(name);
                llSay(0, "Captive has disappeared. Waiting for " + (string)hours + " hours before resetting.");
                llSetObjectName(oldn);
                waitingstate = 1;
                llResetTime();
            }

            // 10 second cooldown
            else if(waitingstate == 1)
            {
                if(llGetTime() < 10.0) return;
                waitingstate = 2;
            }

            // Die if too long without sitter, go to next step if we see the sitter in the region.
            else if(waitingstate == 2)
            {
                if(llGetTime() > (hours * 3600)) die();
                if(llGetAgentSize(firstavatar) != ZERO_VECTOR)
                {
                    waitingstate = 3;
                    llResetTime();
                }
            }

            // We saw the avatar, wait 45 seconds for a recapture.
            else if(waitingstate == 3)
            {
                if(llGetTime() < 45.0) return;
                waitingstate = 4;
            }

            // Recapture didn't happen, try manual capture.
            else if(waitingstate == 4)
            {
                llRegionSayTo(firstavatar, RLVRC, "recapture," + (string)firstavatar + ",@sit:" + (string)llGetKey() + "=force");
                llResetTime();
                waitingstate = 5;
            }

            // And if still not sat on after 60 more seconds... die.
            else if(waitingstate == 5)
            {
                if(llGetTime() < 60.0) return;
                die();
            }
        }
        else
        {
            waitingstate = 0;
            vector my = llGetPos();
            vector offset = ZERO_VECTOR;
            if(keyisavatar == TRUE)
            {
                if((llGetAgentInfo(rezzer) & AGENT_SITTING) == 0) offset = avataroffset;
                else                                              offset = seatedoffset;
            }

            if(keyisavatar == TRUE && llGetAgentSize(rezzer) == ZERO_VECTOR)
            {
                llSetRegionPos(my - offset);
                llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "release," + (string)llAvatarOnSitTarget() + ",@shownames_sec=y|@shownametags=y|@shownearby=y|@showhovertextall=y|@showworldmap=y|@showminimap=y|@showloc=y|@setcam_origindistmax:10=y|@buy=y|@pay=y|@unsit=y|@tplocal=y|@tplm=y|@tploc=y|@tplure_sec=y|@showinv=y|@interact=y|@showself=y|@sendgesture=y|@redirchat:" + (string)GAZE_CHAT_CHANNEL + "=rem|@rediremote:" + (string)GAZE_CHAT_CHANNEL + "=rem|@sendchannel_sec=y|@sendchannel_sec:" + (string)GAZE_CHAT_CHANNEL + "=rem");
                llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "release," + (string)llAvatarOnSitTarget() + ",!release");
                llSleep(0.5);
                llUnSit(llAvatarOnSitTarget());
                llSleep(10.0);
                die();
                return;
            }

            vector pos = llList2Vector(llGetObjectDetails(rezzer, [OBJECT_POS]), 0) + offset;
            my.z = pos.z;
            if(llVecDist(my, pos) > 365 || pos == ZERO_VECTOR)
            {
                llSetRegionPos(llGetPos() - offset);
                llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "release," + (string)llAvatarOnSitTarget() + ",@shownames_sec=y|@shownametags=y|@shownearby=y|@showhovertextall=y|@showworldmap=y|@showminimap=y|@showloc=y|@setcam_origindistmax:10=y|@buy=y|@pay=y|@unsit=y|@tplocal=y|@tplm=y|@tploc=y|@tplure_sec=y|@showinv=y|@interact=y|@showself=y|@sendgesture=y|@redirchat:" + (string)GAZE_CHAT_CHANNEL + "=rem|@rediremote:" + (string)GAZE_CHAT_CHANNEL + "=rem|@sendchannel_sec=y|@sendchannel_sec:" + (string)GAZE_CHAT_CHANNEL + "=rem");
                llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "release," + (string)llAvatarOnSitTarget() + ",!release");
                llSleep(0.5);
                llUnSit(llAvatarOnSitTarget());
                llSleep(10.0);
                die();
                return;
            }
            llSetRegionPos(pos);
            llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@setcam_focus:" + (string)rezzer + ";;=force");
        }
    }
}