#include <IT/globals.lsl>
#define avataroffset <0.0, 0.0, -3.0>
string animation = "";
key rezzer;
key firstavatar = NULL_KEY;
integer keyisavatar = TRUE;
integer saton = FALSE;
string name;
integer waitingstate = 0;

default
{
    state_entry()
    {
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
        llSitTarget(<0.0, 0.0, 0.001>, ZERO_ROTATION);
    }

    on_rez(integer start_param)
    {
        if(start_param & 1)      animation = "hide_a";
        else if(start_param & 2) animation = "hide_b";
        else                     return;
        rezzer = llGetOwnerKey((key)llList2String(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0));
        llSetTimerEvent(10.0);
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
        llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@shownames_sec:" + (string)llGetOwnerKey(rezzer) + "=n|@shownametags=n|@shownearby=n|@showhovertextall=n|@showworldmap=n|@showminimap=n|@showloc=n|@setcam_focus:" + (string)rezzer + ";;1/0/0=force|@setcam_origindistmax:10=n|@buy=n|@pay=n|@unsit=n|@tplocal=n|@tplm=n|@tploc=n|@tplure_sec=n|@showinv=n|@interact=n|@showself=n|@sendgesture=n|@redirchat:" + (string)GAZE_CHAT_CHANNEL + "=add|@rediremote:" + (string)GAZE_CHAT_CHANNEL + "=add");
        llStartAnimation(animation);
        llSetTimerEvent(0.25);
    }

    listen(integer c, string n, key id, string m)
    {
        if(c == GAZE_CHAT_CHANNEL)
        {
            if(keyisavatar == TRUE || startswith(m, "/me") == FALSE || contains(m, "\"") == TRUE) return;
            string oldn = llGetObjectName();
            llSetObjectName(name);
            llSay(0, m);
            llSetObjectName(oldn);
        }
        else if(c == MANTRA_CHANNEL)
        {
            if(m == "unsit")
            {
                if(llAvatarOnSitTarget() == NULL_KEY) llDie();
                llSetRegionPos(llList2Vector(llGetObjectDetails(rezzer, [OBJECT_POS]), 0));
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
                llDie();
            }
            else if(m == "abouttotp")
            {
                if(llAvatarOnSitTarget() == NULL_KEY) llDie();
                llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "release," + (string)llAvatarOnSitTarget() + ",!release");
                llSleep(0.5);
                llUnSit(llAvatarOnSitTarget());
                llSleep(10.0);
                llDie();
            }
            else if(startswith(m, "puton"))
            {
                if(llAvatarOnSitTarget() == NULL_KEY) llDie();
                list params = llParseString2List(llDeleteSubString(m, 0, llStringLength("puton")), ["|||"], []);
                rezzer = (key)llList2String(params, 0);
                name = llList2String(params, 1);
                llRegionSayTo(rezzer, MANTRA_CHANNEL, "puton " + (string)llAvatarOnSitTarget() + "|||" + name);
                keyisavatar = TRUE;
                llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@shownames_sec:" + (string)llGetOwnerKey(rezzer) + "=n");
            }
            else if(startswith(m, "putdown"))
            {
                if(llAvatarOnSitTarget() == NULL_KEY) llDie();
                list params = llParseString2List(llDeleteSubString(m, 0, llStringLength("putdown")), ["|||"], []);
                rezzer = (key)llList2String(params, 0);
                name = llList2String(params, 1);
                keyisavatar = FALSE;
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
                llRegionSayTo(id, RLVRC, "ping," + (string)llGetOwnerKey(id) + ",!pong");
            }
            else if(endswith(m, (string)llGetKey()+",!release,ok"))
            {
                if(llAvatarOnSitTarget() == NULL_KEY) llDie();
                llSetRegionPos(llList2Vector(llGetObjectDetails(rezzer, [OBJECT_POS]), 0));
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
                llDie();
            }
        }
    }

    timer()
    {
        llSetTimerEvent(0.0);
        if(llGetNumberOfPrims() == 1)
        {
            integer hours = (integer)llGetObjectDesc();
            
            // If we were never sat on, delete.
            if(saton == FALSE) llDie();

            // If the key is an avatar, delete.
            if(keyisavatar) llDie();

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
                if(llGetTime() > (hours * 3600)) llDie();
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
                llDie();
            }
        }
        else
        {
            waitingstate = 0;
            vector my = llGetPos();
            vector offset = ZERO_VECTOR;
            if(keyisavatar) offset = avataroffset;
            if(keyisavatar == TRUE && llGetAgentSize(rezzer) == ZERO_VECTOR)
            {
                llSetRegionPos(my - offset);
                llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "release," + (string)llAvatarOnSitTarget() + ",!release");
                llSleep(0.5);
                llUnSit(llAvatarOnSitTarget());
                llSleep(10.0);
                llDie();
                return;
            }

            vector pos = llList2Vector(llGetObjectDetails(rezzer, [OBJECT_POS]), 0) + offset;
            my.z = pos.z;
            if(llVecDist(my, pos) > 365 || pos == ZERO_VECTOR)
            {
                llSetRegionPos(llGetPos() - offset);
                llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "release," + (string)llAvatarOnSitTarget() + ",!release");
                llSleep(0.5);
                llUnSit(llAvatarOnSitTarget());
                llSleep(10.0);
                llDie();
                return;
            }
            llSetRegionPos(pos);
            llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@setcam_focus:" + (string)rezzer + ";;=force");
            
        }
        llSetTimerEvent(0.25);
    }
}