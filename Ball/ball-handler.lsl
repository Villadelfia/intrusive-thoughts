#include <IT/globals.lsl>
#define avataroffset <0.0, 0.0, -3.0>
string animation = "";
key rezzer;
integer keyisavatar = TRUE;
string name;

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
        if(start_param & 4)      keyisavatar = FALSE;
        rezzer = llGetOwnerKey((key)llList2String(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0));
        llSetTimerEvent(10.0);
    }

    changed(integer change)
    {
        if(change & CHANGED_LINK)
        {
            if(llAvatarOnSitTarget() == NULL_KEY) llDie();
            else
            {
                llListen(GAZE_CHAT_CHANNEL, "", llAvatarOnSitTarget(), "");
                llRequestPermissions(llAvatarOnSitTarget(), PERMISSION_TRIGGER_ANIMATION);
            }
        }
    }

    run_time_permissions(integer perm)
    {
        llRegionSayTo(llAvatarOnSitTarget(), MANTRA_CHANNEL, "onball " + (string)llGetKey());
        llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@shownames_sec=n|@showhovertextworld=n|@showworldmap=n|@showminimap=n|@showloc=n|@touchworld=n|@setcam_focus:" + (string)rezzer + ";2;1/0/0=force|@unsit=n|@tplocal=n|@tplm=n|@tploc=n|@tplure_sec=n|@showinv=n|@edit=n|@rez=n|@showself=n|@redirchat:" + (string)GAZE_CHAT_CHANNEL + "=add|@rediremote:" + (string)GAZE_CHAT_CHANNEL + "=add");
        llStartAnimation(animation);
        llSetTimerEvent(0.1);
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
        else
        {
            if(m == "unsit")
            {
                llSetRegionPos(llList2Vector(llGetObjectDetails(rezzer, [OBJECT_POS]), 0));
                llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "release," + (string)llAvatarOnSitTarget() + ",!release");
                llSleep(0.5);
                llUnSit(llAvatarOnSitTarget());
                llSleep(10.0);
                llDie();
            }
            else if(m == "abouttotp")
            {
                llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "release," + (string)llAvatarOnSitTarget() + ",!release");
                llSleep(0.5);
                llUnSit(llAvatarOnSitTarget());
                llSleep(10.0);
                llDie();
            }

            // We've been told by furniture that we should give ourselves back to an IT controller.
            else if(startswith(m, "puton"))
            {
                list params = llParseString2List(llDeleteSubString(m, 0, llStringLength("puton")), ["|||"], []);
                rezzer = (key)llList2String(params, 0);
                name = llList2String(params, 1);
                llRegionSayTo(rezzer, MANTRA_CHANNEL, "puton " + (string)llAvatarOnSitTarget() + "|||" + name);
                keyisavatar = TRUE;
            }
            else if(startswith(m, "putdown"))
            {
                list params = llParseString2List(llDeleteSubString(m, 0, llStringLength("putdown")), ["|||"], []);
                rezzer = (key)llList2String(params, 0);
                name = llList2String(params, 1);
                keyisavatar = FALSE;
            }
        }
    }

    timer()
    {
        if(llGetNumberOfPrims() == 1) llDie();
        else
        {
            vector my = llGetPos();
            if(keyisavatar == TRUE && llGetAgentSize(rezzer) == ZERO_VECTOR)
            {
                llSetRegionPos(my - avataroffset);
                llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "release," + (string)llAvatarOnSitTarget() + ",!release");
                llSleep(0.5);
                llUnSit(llAvatarOnSitTarget());
                llSleep(10.0);
                llDie();
                return;
            }

            vector pos = llList2Vector(llGetObjectDetails(rezzer, [OBJECT_POS]), 0) + avataroffset;
            my.z = pos.z;
            if(llVecDist(my, pos) > 365 || pos == ZERO_VECTOR)
            {
                llSetRegionPos(llGetPos() - avataroffset);
                llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "release," + (string)llAvatarOnSitTarget() + ",!release");
                llSleep(0.5);
                llUnSit(llAvatarOnSitTarget());
                llSleep(10.0);
                llDie();
                return;
            }

            llSetRegionPos(pos);
            llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@setcam_focus:" + (string)rezzer + ";2;=force");
        }
    }
}