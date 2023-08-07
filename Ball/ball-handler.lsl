#include <IT/globals.lsl>
string animation = "";
key rezzer;
key urlt;
string url = "null";
key firstavatar = NULL_KEY;
integer keyisavatar;
integer saton;
integer editmode;
vector seatedoffset;
vector oldpos;
string name;
string objectprefix = "";
integer struggleEvents = 0;
integer struggleFailed = FALSE;
integer captured = FALSE;
integer firstattempt = TRUE;
integer notify = TRUE;
string prefix = "??";
integer timerctr = 0;

integer furnitureCameraMode = 0;
key furnitureCameraPos = NULL_KEY;
key furnitureCameraFocus = NULL_KEY;

// 0 = Nothing extra.
// 1 = Cannot open IM sessions.
// 2 = Cannot send IMs.
// 3 = Cannot send or receive IMs.
integer imRestrict = 0;

// 0 = Nothing extra.
// 1 = Dark fog at 10 meters.
// 2 = Light fog at 10 meters.
// 3 = Dark fog at 5 meters.
// 4 = Light fog at 5 meters.
// 5 = Dark fog at 2 meters.
// 6 = Light fog at 2 meters.
// 7 = Dark fog at 0.5 meters.
// 8 = Light fog at 0.5 meters.
// 9 = Blind.
integer visionRestrict = 0;

// 0 = Nothing extra.
// 1 = Incapable of hearing anyone but wearer and co-captured victims.
// 2 = Incapable of hearing anyone but wearer.
// 3 = Deaf.
integer hearingRestrict = 0;

// 0 = No restrictions.
// 1 = Not capable of speech except to owner and other captives. Can emote.
// 2 = No longer capable of emoting.
// 3 = Incapable of any kind of speech or emotes, even to owner.
integer speechRestrict = 1;

// 0 = No restrictions.
// 1 = Location and people hidden.
integer dazeRestrict = 1;

// 0 = No restrictions.
// 1 = Camera restricted to wearer.
integer cameraRestrict = 1;

// 0 = No restrictions.
// 1 = No inventory.
integer inventoryRestrict = 1;

// 0 = No restrictions.
// 1 = No world interaction.
integer worldRestrict = 1;

die()
{
    if(firstavatar) llRegionSayTo(rezzer, STRUGGLE_CHANNEL, "released|" + (string)firstavatar);
    llSetAlpha(0.0, ALL_SIDES);
    llSetPrimitiveParams([PRIM_TEMP_ON_REZ, TRUE]);
    llDie();
    while(TRUE) llSleep(60.0);
}

applyIm()
{
    if(imRestrict > 2)      llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@startim=n|@sendim=n|@recvim=n");
    else if(imRestrict > 1) llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@startim=n|@sendim=n|@recvim=y");
    else if(imRestrict > 0) llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@sendim=y|@startim=n|@recvim=y");
    else                    llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@sendim=y|@startim=y|@recvim=y");
}

applyVision()
{
    llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@setsphere=y");
    float dist = 10.0;
    if(visionRestrict > 2) dist = 5.0;
    if(visionRestrict > 4) dist = 2.0;
    if(visionRestrict > 6) dist = 0.5;
    if(visionRestrict > 8) dist = 0.0;
    string color = "0/0/0";
    if(visionRestrict % 2 == 0) color = "1/1/1";
    if(visionRestrict > 0) llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@setsphere=n|@setsphere_origin:1=force|@setsphere_distmin:" + (string)(dist/4) + "=force|@setsphere_valuemin:0=force|@setsphere_distmax:" + (string)dist + "=force|@setsphere_param:" + color + "/0=force");
}

applyHearing()
{
    llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@recvchat=y|@recvemote=y|@recvchat:" + (string)llGetOwnerKey(rezzer) + "=rem|@recvemote:" + (string)llGetOwnerKey(rezzer) + "=rem|@recvchat:" + llList2String(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0) + "=rem|@recvemote:" + llList2String(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0) + "=rem");
    if(hearingRestrict == 3)     llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@recvchat=n|@recvemote=n");
    else if(hearingRestrict > 0) llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@recvchat=n|@recvemote=n|@recvchat:" + (string)llGetOwnerKey(rezzer) + "=add|@recvemote:" + (string)llGetOwnerKey(rezzer) + "=add|@recvchat:" + llList2String(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0) + "=add|@recvemote:" + llList2String(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0) + "=add");
}

applySpeech()
{
    llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@redirchat=y|@redirchat:" + (string)GAZE_CHAT_CHANNEL + "=rem|@redirchat:" + (string)DUMMY_CHANNEL + "=rem|@redirchat:" + (string)GAZE_REN_CHANNEL + "=rem|@rediremote=y|@rediremote:" + (string)GAZE_CHAT_CHANNEL + "=rem|@rediremote:" + (string)DUMMY_CHANNEL + "=rem|@rediremote:" + (string)GAZE_REN_CHANNEL + "=rem");
    if(speechRestrict == 0) llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@redirchat=n|@redirchat:" + (string)GAZE_REN_CHANNEL + "=add|@rediremote=n|@rediremote:" + (string)GAZE_REN_CHANNEL + "=add");
    if(speechRestrict == 1) llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@redirchat=n|@redirchat:" + (string)GAZE_CHAT_CHANNEL + "=add|@rediremote=n|@rediremote:" + (string)GAZE_CHAT_CHANNEL + "=add");
    if(speechRestrict == 2) llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@redirchat=n|@redirchat:" + (string)GAZE_CHAT_CHANNEL + "=add|@rediremote=n|@rediremote:" + (string)DUMMY_CHANNEL + "=add");
    if(speechRestrict == 3) llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@redirchat=n|@redirchat:" + (string)DUMMY_CHANNEL + "=add|@rediremote=n|@rediremote:" + (string)DUMMY_CHANNEL + "=add");
}

applyDaze()
{
    if(dazeRestrict == 0) llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@shownames=y|@shownametags=y|@shownearby=y|@showhovertextall=y|@showworldmap=y|@showminimap=y|@showloc=y");
    if(dazeRestrict == 1) llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@shownames=n|@shownametags=n|@shownearby=n|@showhovertextall=n|@showworldmap=n|@showminimap=n|@showloc=n");
}

applyCamera()
{
    if(cameraRestrict == 0) llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@setcam_origindistmax:50=y");
    if(cameraRestrict == 1) llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@setcam_origindistmax:50=n");
}

applyInventory()
{
    if(inventoryRestrict == 0) llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@showinv=y");
    if(inventoryRestrict == 1) llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@showinv=n");
}

applyWorld()
{
    if(worldRestrict == 0) llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@touchall=y|@edit=y|@rez=y");
    if(worldRestrict == 1) llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@touchall=n|@edit=n|@rez=n");
}

doubleNotify(string s)
{
    llRegionSayTo(rezzer, 0, s);
    llRegionSayTo(firstavatar, 0, s);
}

string restrictionString()
{
    return (string)imRestrict + "," +
           (string)visionRestrict + "," +
           (string)hearingRestrict + "," +
           (string)speechRestrict + "," +
           (string)dazeRestrict + "," +
           (string)cameraRestrict + "," +
           (string)inventoryRestrict + "," +
           (string)worldRestrict + "," +
           (string)(animation == "hide_b");
}

toggleedit()
{
    if(editmode == FALSE && (keyisavatar == FALSE || (llGetAgentInfo(rezzer) & AGENT_SITTING) == 0)) return;
    if(animation == "hide_b") return;
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
        llOwnerSay((string)llGetFreeMemory());
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
        llListen(BALL_CHANNEL, "", NULL_KEY, "");
        llListen(STRUGGLE_CHANNEL, "", NULL_KEY, "");
        llListen(GAZE_ECHO_CHANNEL, "", NULL_KEY, "");
        llListen(5, "", NULL_KEY, "");
        llSitTarget(<0.0, 0.0, 0.001>, ZERO_ROTATION);
        rezzer = llGetOwner();
        llVolumeDetect(TRUE);
        llSetStatus(STATUS_ROTATE_X | STATUS_ROTATE_Y | STATUS_ROTATE_Z, FALSE);
        llSetStatus(STATUS_PHYSICS, FALSE);
    }

    on_rez(integer start_param)
    {
        // Sanitize all default parameters.
        firstavatar = NULL_KEY;
        keyisavatar = TRUE;
        notify = TRUE;
        saton = FALSE;
        editmode = FALSE;
        seatedoffset = ZERO_VECTOR;
        urlt = llRequestURL();

        // Set the rezzer and default animation.
        rezzer = (key)llList2String(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0);
        animation = "hide_a";

        // Set certain settings based on the start parameter.
        if(start_param & 2) animation = "hide_b";
        if(start_param & 4) keyisavatar = FALSE;
        if(start_param & 8) notify = FALSE;

        // If the rezzer is an avatar, make sure we actually have the uuid of the avatar and not the hud.
        // Otherwise set the name this object will use to talk.
        if(keyisavatar) rezzer = llGetOwnerKey(rezzer);
        else            name = llList2String(llGetObjectDetails(rezzer, [OBJECT_NAME]), 0);

        // If we were rezzed without a start parameter or just normally, don't suicide in 60 seconds.
        if(start_param == 0) return;

        // Otherwise, start a suicide timer.
        llSetTimerEvent(60.0);
    }

    changed(integer change)
    {
        // If we have been sat on.
        if(change & CHANGED_LINK)
        {
            if(llAvatarOnSitTarget() != NULL_KEY)
            {
                // If it's the first time, remember who it was and start listening to certain channels.
                if(firstavatar == NULL_KEY)
                {
                    firstavatar = llAvatarOnSitTarget();
                    llListen(GAZE_CHAT_CHANNEL, "", firstavatar, "");
                    llListen(GAZE_REN_CHANNEL, "", firstavatar, "");
                    llListen(RLVRC, "", NULL_KEY, "");
                    if(keyisavatar) llRegionSayTo(llAvatarOnSitTarget(), MANTRA_CHANNEL, "ballnotify|||avatar|||" + name + "|||" + (string)rezzer);
                    else            llRegionSayTo(llAvatarOnSitTarget(), MANTRA_CHANNEL, "ballnotify|||furniture|||" + name + "|||" + (string)rezzer);
                }

                // Otherwise only allow the first sitter.
                if(firstavatar != llAvatarOnSitTarget()) llUnSit(llAvatarOnSitTarget());

                // Make sure to flag that we have been sat on.
                saton = TRUE;

                // Set the prefix
                prefix = llToLower(llGetSubString(llGetUsername(firstavatar), 0, 1));

                if(!captured)
                {
                    llRegionSayTo(rezzer, STRUGGLE_CHANNEL, "captured|" + (string)firstavatar + "|object|" + name);
                    captured = TRUE;
                }

                // Apply RLV restrictions.
                llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@tplocal=n|@tplm=n|@tploc=n|@tplure=n|@showself=n|@sendgesture=n|@startim:" + (string)llGetOwnerKey(rezzer) + "=add|@recvim:" + (string)llGetOwnerKey(rezzer) + "=add|@sendim:" + (string)llGetOwnerKey(rezzer) + "=add");
                applyIm();
                applyHearing();
                applySpeech();
                applyVision();
                applyDaze();
                applyCamera();
                applyInventory();
                applyWorld();

                // And animate the sat avatar.
                llRequestPermissions(llAvatarOnSitTarget(), PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS | PERMISSION_CONTROL_CAMERA | PERMISSION_TRACK_CAMERA);
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
        // Let the IT slave know to turn off its garbler.
        llRegionSayTo(llAvatarOnSitTarget(), COMMAND_CHANNEL, "*onball " + (string)llGetKey());

        // Start the animation.
        llStartAnimation(animation);

        // Take controls.
        llTakeControls(CONTROL_FWD | CONTROL_BACK | CONTROL_LEFT | CONTROL_RIGHT | CONTROL_ROT_LEFT | CONTROL_ROT_RIGHT | CONTROL_UP | CONTROL_DOWN, TRUE, TRUE);

        // Notify of menu.
        if(notify)
        {
            llSetObjectName("");
            llRegionSayTo(llAvatarOnSitTarget(), 0, "You can restrict yourself further by clicking [secondlife:///app/chat/5/" + prefix + "menu here] or by typing /5" + prefix + "menu. Settings made will be saved and remembered for when you are captured by the same person.");
            llRegionSayTo(llGetOwnerKey(rezzer), 0, "You can edit the restrictions on your victim by clicking [secondlife:///app/chat/5/" + prefix + "menu here] or by typing /5" + prefix + "menu. Settings made will be saved and remembered for when you capture the same person.");
            llSetObjectName("ball");
        }

        // And start a timer loop.
        llSetTimerEvent(0.5);
    }

    control(key id, integer level, integer edge)
    {
        integer start = level & edge;
        if(start) struggleEvents++;
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
            llSetObjectName(objectprefix + llList2String(llParseString2List(name, [";"], []), 0));
            if(llToLower(llStringTrim(m, STRING_TRIM)) == "/me" || startswith(m, "/me") == FALSE || contains(m, "\"") == TRUE)
            {
                llRegionSayTo(llAvatarOnSitTarget(), 0, m);
            }
            else
            {
                llSay(0, m);
            }
            llSetObjectName("ball");
        }
        else if(c == GAZE_REN_CHANNEL)
        {
            llSetObjectName(objectprefix + llList2String(llParseString2List(name, [";"], []), 0));
            llSay(0, m);
            llSetObjectName("ball");
        }
        else if(c == GAZE_ECHO_CHANNEL)
        {
            if(hearingRestrict > 1) return;
            llSetObjectName(n);
            llRegionSayTo(llAvatarOnSitTarget(), 0, m);
            llSetObjectName("ball");
        }
        else if(c == BALL_CHANNEL)
        {
            if(keyisavatar == FALSE || llGetOwnerKey(id) != rezzer) return;
            if(hearingRestrict == 3) return;
            llSetObjectName("Wearer's Thoughts");
            llRegionSayTo(llAvatarOnSitTarget(), 0, m);
            llSetObjectName("ball");
        }
        else if(c == 5)
        {
            if(id != firstavatar && llGetOwner() != llGetOwnerKey(id)) return;
            if(m == prefix + "menu") llMessageLinked(LINK_THIS, X_API_GIVE_MENU, "", llGetOwnerKey(id));
            else if(m == prefix + "invis")
            {
                if(animation == "hide_b")
                {
                    if(id == firstavatar) return;
                    llStopAnimation(animation);
                    animation = "hide_a";
                    llStartAnimation(animation);
                    llSetObjectName("");
                    doubleNotify("secondlife:///app/agent/" + (string)firstavatar + "/about will now be rendered visible again, but it will require a relog.");
                    llSetObjectName("ball");
                    llMessageLinked(LINK_THIS, X_API_SETTINGS_SAVE, restrictionString(), NULL_KEY);
                }
                else
                {
                    llStopAnimation(animation);
                    animation = "hide_b";
                    llStartAnimation(animation);
                    llSetObjectName("");
                    doubleNotify("secondlife:///app/agent/" + (string)firstavatar + "/about is now rendered truly invisible, nameplate and all.");
                    llSetObjectName("ball");
                    llMessageLinked(LINK_THIS, X_API_SETTINGS_SAVE, restrictionString(), NULL_KEY);
                }
            }
            else if(startswith(m, prefix + "name"))
            {
                if(id == firstavatar) return;
                m = llDeleteSubString(m, 0, llStringLength(prefix + "name"));
                name = m;
                llSetObjectName("");
                doubleNotify("secondlife:///app/agent/" + (string)firstavatar + "/about is now " + objectprefix + m + ".");
                llSetObjectName("ball");
                llRegionSayTo(rezzer, MANTRA_CHANNEL, "objrename " + m);
            }
            else if(startswith(m, prefix + "im"))
            {
                if(id == firstavatar && imRestrict > (integer)llGetSubString(m, -1, -1)) return;
                imRestrict = (integer)llGetSubString(m, -1, -1);
                if(imRestrict < 0) imRestrict = 0;
                if(imRestrict > 3) imRestrict = 3;
                llSetObjectName("");
                doubleNotify("secondlife:///app/agent/" + (string)firstavatar + "/about's IM restrictions set to level " + (string)imRestrict + ".");
                llSetObjectName("ball");
                applyIm();
                llMessageLinked(LINK_THIS, X_API_SETTINGS_SAVE, restrictionString(), NULL_KEY);
            }
            else if(startswith(m, prefix + "vi"))
            {
                if(id == firstavatar && visionRestrict > (integer)llGetSubString(m, -1, -1)) return;
                visionRestrict = (integer)llGetSubString(m, -1, -1);
                if(visionRestrict < 0) visionRestrict = 0;
                if(visionRestrict > 9) visionRestrict = 9;
                llSetObjectName("");
                doubleNotify("secondlife:///app/agent/" + (string)firstavatar + "/about's Vision restrictions set to level " + (string)visionRestrict + ".");
                llSetObjectName("ball");
                applyVision();
                llMessageLinked(LINK_THIS, X_API_SETTINGS_SAVE, restrictionString(), NULL_KEY);
            }
            else if(startswith(m, prefix + "he"))
            {
                if(id == firstavatar && hearingRestrict > (integer)llGetSubString(m, -1, -1)) return;
                hearingRestrict = (integer)llGetSubString(m, -1, -1);
                if(hearingRestrict < 0) hearingRestrict = 0;
                if(hearingRestrict > 3) hearingRestrict = 3;
                llSetObjectName("");
                doubleNotify("secondlife:///app/agent/" + (string)firstavatar + "/about's Hearing restrictions set to level " + (string)hearingRestrict + ".");
                llSetObjectName("ball");
                applyHearing();
                llMessageLinked(LINK_THIS, X_API_SETTINGS_SAVE, restrictionString(), NULL_KEY);
            }
            else if(startswith(m, prefix + "sp"))
            {
                if(id == firstavatar && speechRestrict > (integer)llGetSubString(m, -1, -1)) return;
                speechRestrict = (integer)llGetSubString(m, -1, -1);
                if(speechRestrict < 0) speechRestrict = 0;
                if(speechRestrict > 3) speechRestrict = 3;
                llSetObjectName("");
                doubleNotify("secondlife:///app/agent/" + (string)firstavatar + "/about's Speech restrictions set to level " + (string)speechRestrict + ".");
                llSetObjectName("ball");
                applySpeech();
                llMessageLinked(LINK_THIS, X_API_SETTINGS_SAVE, restrictionString(), NULL_KEY);
            }
            else if(startswith(m, prefix + "da"))
            {
                if(id == firstavatar && dazeRestrict > (integer)llGetSubString(m, -1, -1)) return;
                dazeRestrict = (integer)llGetSubString(m, -1, -1);
                if(dazeRestrict < 0) dazeRestrict = 0;
                if(dazeRestrict > 1) dazeRestrict = 1;
                llSetObjectName("");
                doubleNotify("secondlife:///app/agent/" + (string)firstavatar + "/about's Daze restrictions set to level " + (string)dazeRestrict + ".");
                llSetObjectName("ball");
                applyDaze();
                llMessageLinked(LINK_THIS, X_API_SETTINGS_SAVE, restrictionString(), NULL_KEY);
            }
            else if(startswith(m, prefix + "ca"))
            {
                if(id == firstavatar && cameraRestrict > (integer)llGetSubString(m, -1, -1)) return;
                cameraRestrict = (integer)llGetSubString(m, -1, -1);
                if(cameraRestrict < 0) cameraRestrict = 0;
                if(cameraRestrict > 1) cameraRestrict = 1;
                llSetObjectName("");
                doubleNotify("secondlife:///app/agent/" + (string)firstavatar + "/about's Camera restrictions set to level " + (string)cameraRestrict + ".");
                llSetObjectName("ball");
                applyCamera();
                llMessageLinked(LINK_THIS, X_API_SETTINGS_SAVE, restrictionString(), NULL_KEY);
            }
            else if(startswith(m, prefix + "in"))
            {
                if(id == firstavatar && inventoryRestrict > (integer)llGetSubString(m, -1, -1)) return;
                inventoryRestrict = (integer)llGetSubString(m, -1, -1);
                if(inventoryRestrict < 0) inventoryRestrict = 0;
                if(inventoryRestrict > 1) inventoryRestrict = 1;
                llSetObjectName("");
                doubleNotify("secondlife:///app/agent/" + (string)firstavatar + "/about's Inventory restrictions set to level " + (string)inventoryRestrict + ".");
                llSetObjectName("ball");
                applyInventory();
                llMessageLinked(LINK_THIS, X_API_SETTINGS_SAVE, restrictionString(), NULL_KEY);
            }
            else if(startswith(m, prefix + "wo"))
            {
                if(id == firstavatar && worldRestrict > (integer)llGetSubString(m, -1, -1)) return;
                worldRestrict = (integer)llGetSubString(m, -1, -1);
                if(worldRestrict < 0) worldRestrict = 0;
                if(worldRestrict > 1) worldRestrict = 1;
                llSetObjectName("");
                doubleNotify("secondlife:///app/agent/" + (string)firstavatar + "/about's World restrictions set to level " + (string)worldRestrict + ".");
                llSetObjectName("ball");
                applyWorld();
                llMessageLinked(LINK_THIS, X_API_SETTINGS_SAVE, restrictionString(), NULL_KEY);
            }
        }
        else if(c == MANTRA_CHANNEL)
        {
            if(m == "unsit")
            {
                if(llAvatarOnSitTarget() == NULL_KEY) die();
                llSetRegionPos(llList2Vector(llGetObjectDetails(rezzer, [OBJECT_POS]), 0));
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
            else if(startswith(m, "sit"))
            {
                list params = llParseString2List(llDeleteSubString(m, 0, llStringLength("sit")), ["|||"], []);
                firstavatar = (key)llList2String(params, 0);
                name = llList2String(params, 1);
                objectprefix = llList2String(params, 2);
                if(objectprefix == "NULL") objectprefix = "";
                llListen(GAZE_CHAT_CHANNEL, "", firstavatar, "");
                llListen(GAZE_REN_CHANNEL, "", firstavatar, "");
                vector pos = llList2Vector(llGetObjectDetails(firstavatar, [OBJECT_POS]), 0);
                llSetRegionPos(pos);
                llListen(RLVRC, "", NULL_KEY, "");
                llRegionSayTo(firstavatar, RLVRC, "c," + (string)firstavatar + ",@sit:" + (string)llGetKey() + "=force|@unsit=n");
                llSetTimerEvent(20.0);
            }
            else if(m == "edit" && llGetOwnerKey(id) == llGetOwnerKey(rezzer) && keyisavatar == TRUE)
            {
                toggleedit();
            }
            else if(startswith(m, "puton"))
            {
                if(llAvatarOnSitTarget() == NULL_KEY) die();
                list params = llParseString2List(llDeleteSubString(m, 0, llStringLength("puton")), ["|||"], []);
                llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@startim:" + (string)llGetOwnerKey(rezzer) + "=rem|@recvim:" + (string)llGetOwnerKey(rezzer) + "=rem|@sendim:" + (string)llGetOwnerKey(rezzer) + "=rem");
                rezzer = (key)llList2String(params, 0);
                name = llList2String(params, 1);
                objectprefix = "";
                llRegionSayTo(rezzer, MANTRA_CHANNEL, "puton " + (string)llAvatarOnSitTarget() + "|||" + name + "|||" + url);
                llRegionSayTo(llAvatarOnSitTarget(), MANTRA_CHANNEL, "ballnotify|||avatar|||" + name + "|||" + (string)rezzer);
                keyisavatar = TRUE;
                llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@startim:" + (string)llGetOwnerKey(rezzer) + "=add|@recvim:" + (string)llGetOwnerKey(rezzer) + "=add|@sendim:" + (string)llGetOwnerKey(rezzer) + "=add");
            }
            else if(startswith(m, "putdown"))
            {
                if(llAvatarOnSitTarget() == NULL_KEY) die();
                list params = llParseString2List(llDeleteSubString(m, 0, llStringLength("putdown")), ["|||"], []);
                llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@startim:" + (string)llGetOwnerKey(rezzer) + "=rem|@recvim:" + (string)llGetOwnerKey(rezzer) + "=rem|@sendim:" + (string)llGetOwnerKey(rezzer) + "=rem");
                rezzer = (key)llList2String(params, 0);
                name = llList2String(params, 1);
                objectprefix = "";
                llRegionSayTo(rezzer, MANTRA_CHANNEL, "objurl " + url);
                keyisavatar = FALSE;
                llRegionSayTo(llAvatarOnSitTarget(), MANTRA_CHANNEL, "ballnotify|||furniture|||" + name + "|||" + (string)rezzer);
            }
            else if(startswith(m, "prefix"))
            {
                if(llAvatarOnSitTarget() == NULL_KEY) die();
                m = llDeleteSubString(m, 0, llStringLength("prefix"));
                objectprefix = m;
            }
            else if(startswith(m, "furniturecamera"))
            {
                list settings = llParseString2List(m, [";"], []);
                furnitureCameraMode = (integer)llList2String(settings, 1);
                furnitureCameraPos = (key)llList2String(settings, 2);
                furnitureCameraFocus = (key)llList2String(settings, 3);
            }
        }
        else if(c == RLVRC)
        {
            if(endswith(m, (string)llGetKey()+",!release,ok"))
            {
                llSetObjectName(objectprefix + name);
                llSetRegionPos(llList2Vector(llGetObjectDetails(rezzer, [OBJECT_POS]), 0));
                llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "release," + (string)llAvatarOnSitTarget() + ",!release");
                llSleep(0.5);
                llUnSit(llAvatarOnSitTarget());
                llSleep(10.0);
                die();
            }
            else if(startswith(m, "c,"))
            {
                llSleep(1.0);
                if(llList2Key(llGetObjectDetails(firstavatar, [OBJECT_ROOT]), 0) == llGetKey()) llRegionSayTo(rezzer, RLVRC, "c," + llList2String(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0) + ",@sit=n,ok");
                else llRegionSayTo(rezzer, RLVRC, "c," + llList2String(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0) + ",@sit=n,ko");
            }
        }
        else if(c == STRUGGLE_CHANNEL)
        {
            if((keyisavatar == TRUE && llGetOwnerKey(id) != rezzer) || (keyisavatar == FALSE && id != rezzer)) return;
            if(llAvatarOnSitTarget() == NULL_KEY) die();
            if(startswith(m, "struggle_fail"))
            {
                list params = llParseString2List(m, ["|"], []);
                m = llList2String(llParseString2List(m, ["|"], []), -1);
                if(llGetListLength(params) == 2 || (llGetListLength(params) == 3 && (key)llList2String(params, 1) == firstavatar))
                {
                    llSetObjectName("");
                    llRegionSayTo(firstavatar, 0, m);
                    llSetObjectName("ball");
                    llReleaseControls();
                    struggleFailed = TRUE;
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
                    llSetObjectName("ball");
                    llSetRegionPos(llList2Vector(llGetObjectDetails(rezzer, [OBJECT_POS]), 0));
                    llRegionSayTo(firstavatar, RLVRC, "release," + (string)firstavatar + ",!release");
                    llSleep(0.5);
                    llUnSit(firstavatar);
                    llSleep(10.0);
                    die();
                }
            }
        }
    }

    timer()
    {
        if(struggleEvents > 0 && struggleFailed == FALSE)
        {
            llRegionSayTo(rezzer, STRUGGLE_CHANNEL, "struggle_count|" + (string)firstavatar + "|" + (string)struggleEvents);
            struggleEvents = 0;
        }

        if(editmode)
        {
            return;
        }

        if(llGetNumberOfPrims() == 1)
        {
            die();
        }
        else
        {
            vector my = llGetPos();
            vector offset = ZERO_VECTOR;
            if(keyisavatar) offset = seatedoffset;
            if(animation == "hide_b") offset = <0.0, 0.0, -5.0>;

            if((keyisavatar == TRUE && llGetAgentSize(rezzer) == ZERO_VECTOR) || (keyisavatar == FALSE && llList2Vector(llGetObjectDetails(rezzer, [OBJECT_POS]), 0) == ZERO_VECTOR))
            {
                if(firstattempt)
                {
                    firstattempt = FALSE;
                    llSetTimerEvent(30.0);
                    return;
                }
                else
                {
                    llSetRegionPos(my - offset);
                    llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "release," + (string)llAvatarOnSitTarget() + ",!release");
                    llSleep(0.5);
                    llUnSit(llAvatarOnSitTarget());
                    llSleep(10.0);
                    die();
                    return;
                }

            }
            else
            {
                firstattempt = TRUE;
            }

            vector pos = llList2Vector(llGetObjectDetails(rezzer, [OBJECT_POS]), 0) + offset;
            float dist = llVecDist(my, pos);
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

            timerctr++;
            if(timerctr % 5 == 0)
            {
                llRegionSayTo(rezzer, MANTRA_CHANNEL, "objurl " + url);
                if(furnitureCameraMode != 0 && furnitureCameraPos != NULL_KEY && furnitureCameraFocus != NULL_KEY)
                {
                    llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@setcam_unlock=n");
                    vector posPos = llList2Vector(llGetObjectDetails(furnitureCameraPos, [OBJECT_POS]), 0);
                    vector focusPos = llList2Vector(llGetObjectDetails(furnitureCameraFocus, [OBJECT_POS]), 0);
                    float closestDist = 65535.0;
                    key closestPerson = NULL_KEY;
                    vector closestPos = ZERO_VECTOR;

                    list onsim = llGetAgentList(AGENT_LIST_REGION, []);
                    integer n = llGetListLength(onsim);
                    key id;
                    float dist;
                    vector pos;
                    while(~--n)
                    {
                        id = llList2Key(onsim, n);
                        pos = llList2Vector(llGetObjectDetails(id, [OBJECT_POS]), 0);
                        dist = llVecDist(focusPos, pos);
                        if(dist < closestDist) {
                            closestDist = dist;
                            closestPerson = id;
                            closestPos = pos;
                        }
                    }

                    if(furnitureCameraMode == 1 || closestPos > 10.0)
                    {
                        llSetCameraParams([
                            CAMERA_ACTIVE, 1,
                            CAMERA_POSITION_LAG, 0.0,
                            CAMERA_POSITION, posPos,
                            CAMERA_POSITION_LOCKED, TRUE,
                            CAMERA_POSITION_THRESHOLD, 0.0,
                            CAMERA_FOCUS_LAG, 0.0,
                            CAMERA_FOCUS, focusPos,
                            CAMERA_FOCUS_LOCKED, TRUE,
                            CAMERA_FOCUS_THRESHOLD, 0.0
                        ]);
                    }
                    else
                    {
                        llSetCameraParams([
                            CAMERA_ACTIVE, 1,
                            CAMERA_POSITION_LAG, 0.0,
                            CAMERA_POSITION, focusPos,
                            CAMERA_POSITION_LOCKED, TRUE,
                            CAMERA_POSITION_THRESHOLD, 0.0,
                            CAMERA_FOCUS_LAG, 0.5,
                            CAMERA_FOCUS, closestPos,
                            CAMERA_FOCUS_LOCKED, TRUE,
                            CAMERA_FOCUS_THRESHOLD, 0.0
                        ]);
                    }
                }
                else if(cameraRestrict != 0)
                {
                    list uuids = llGetAttachedList(rezzer);
                    integer n = llGetListLength(uuids);
                    list data = [];
                    while(~--n)
                    {
                        data = llGetObjectDetails(llList2Key(uuids, n), [OBJECT_NAME, OBJECT_DESC]);
                        if(llToLower((string)data[0]) == llToLower(name) || llToLower((string)data[0]) == llToLower(objectprefix + name))
                        {
                            llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@setcam_unlock=y|@" + (string)data[1]);
                            return;
                        }
                    }
                    n = llGetListLength(uuids);
                    while(~--n)
                    {
                        data = llGetObjectDetails(llList2Key(uuids, n), [OBJECT_NAME, OBJECT_DESC]);
                        if(startswith((string)data[0], "Intrusive Thoughts Focus Target"))
                        {
                            llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@setcam_unlock=y|@" + (string)data[1]);
                            return;
                        }
                    }
                    llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@setcam_unlock=y|@setcam_focus:" + (string)rezzer + ";;=force");
                }
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
            llSetTimerEvent(0.0);
            llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "cantp," + (string)llAvatarOnSitTarget() + ",@unsit=y|@tplocal=y|@tplm=y|@tploc=y|@tpto:" + body + "=force|!release");
            llHTTPResponse(id, 200, "OK");
            llSleep(10.0);
            die();
        }
    }

    link_message(integer sender_num, integer num, string str, key id )
    {
        if(num == X_API_SETTINGS_LOAD)
        {
            list settings = llParseString2List(str, [","], []);
            imRestrict = (integer)llList2String(settings, 0);
            visionRestrict = (integer)llList2String(settings, 1);
            hearingRestrict = (integer)llList2String(settings, 2);
            speechRestrict = (integer)llList2String(settings, 3);
            dazeRestrict = (integer)llList2String(settings, 4);
            cameraRestrict = (integer)llList2String(settings, 5);
            inventoryRestrict = (integer)llList2String(settings, 6);
            worldRestrict = (integer)llList2String(settings, 7);
            integer isHidden = (integer)llList2String(settings, 8);
            llSetObjectName("");
            if(imRestrict > 0) doubleNotify("secondlife:///app/agent/" + (string)firstavatar + "/about's IM restrictions set to level " + (string)imRestrict + ".");
            if(visionRestrict > 0) doubleNotify("secondlife:///app/agent/" + (string)firstavatar + "/about's Vision restrictions set to level " + (string)visionRestrict + ".");
            if(hearingRestrict > 0) doubleNotify("secondlife:///app/agent/" + (string)firstavatar + "/about's Hearing restrictions set to level " + (string)hearingRestrict + ".");
            if(speechRestrict != 1) doubleNotify("secondlife:///app/agent/" + (string)firstavatar + "/about's Speech restrictions set to level " + (string)speechRestrict + ".");
            if(dazeRestrict != 1) doubleNotify("secondlife:///app/agent/" + (string)firstavatar + "/about's Daze restrictions set to level " + (string)dazeRestrict + ".");
            if(cameraRestrict != 1) doubleNotify("secondlife:///app/agent/" + (string)firstavatar + "/about's Camera restrictions set to level " + (string)cameraRestrict + ".");
            if(inventoryRestrict != 1) doubleNotify("secondlife:///app/agent/" + (string)firstavatar + "/about's Inventory restrictions set to level " + (string)inventoryRestrict + ".");
            if(worldRestrict != 1) doubleNotify("secondlife:///app/agent/" + (string)firstavatar + "/about's World restrictions set to level " + (string)worldRestrict + ".");
            if(isHidden && animation != "hide_b")
            {
                if(llGetPermissions() & PERMISSION_TRIGGER_ANIMATION) llStopAnimation(animation);
                animation = "hide_b";
                if(llGetPermissions() & PERMISSION_TRIGGER_ANIMATION) llStartAnimation(animation);
                doubleNotify("secondlife:///app/agent/" + (string)firstavatar + "/about is now rendered truly invisible, nameplate and all.");
            }
            llSetObjectName("ball");
            applyIm();
            applyVision();
            applyHearing();
            applySpeech();
            applyDaze();
            applyCamera();
            applyInventory();
            applyWorld();
        }
    }
}
