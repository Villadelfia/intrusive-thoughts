#include <IT/globals.lsl>
string animation = "";
key rezzer;
key firstavatar = NULL_KEY;
integer keyisavatar;
integer saton;
integer editmode;
vector seatedoffset;
vector oldpos;
string name;
integer waitingstate;
integer struggleEvents = 0;
integer struggleFailed = FALSE;
integer captured = FALSE;
string prefix = "";

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
// 7 = Blind.
integer visionRestrict = 0;

// 0 = Nothing extra.
// 1 = Incapable of hearing anyone but wearer and co-captured victims.
// 2 = Incapable of hearing anyone but wearer.
// 3 = Deaf.
integer hearingRestrict = 0;

// 0 = Nothing extra.
// 1 = No longer capable of emoting.
// 2 = Incapable of any kind of speech, even to owner.
integer speechRestrict = 0;

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
    llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@sendim=y|@startim=y|@recvim=y");
    if(imRestrict > 0) llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@startim=n");
    if(imRestrict > 1) llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@sendim=n");
    if(imRestrict > 2) llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@recvim=n");
}

applyVision()
{
    llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@setsphere=y");
    float dist = 10.0;
    if(visionRestrict > 2) dist = 5.0;
    if(visionRestrict > 4) dist = 2.0;
    if(visionRestrict > 6) dist = 0.0;
    string color = "0/0/0";
    if(visionRestrict % 2 == 0) color = "1/1/1";
    if(visionRestrict > 0) llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@setsphere=n|@setsphere_distmin:" + (string)(dist/4) + "=force|@setsphere_valuemin:0=force|@setsphere_distmax:" + (string)dist + "=force|@setsphere_param:" + color + "/0=force");
}

applyHearing()
{
    llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@recvchat=y|@recvemote=y|@recvchat:" + (string)llGetOwnerKey(rezzer) + "=rem|@recvemote:" + (string)llGetOwnerKey(rezzer) + "=rem|@recvchat:" + llList2String(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0) + "=rem|@recvemote:" + llList2String(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0) + "=rem");
    if(hearingRestrict == 3)     llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@recvchat=n|@recvemote=n");
    else if(hearingRestrict > 0) llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@recvchat=n|@recvemote=n|@recvchat:" + (string)llGetOwnerKey(rezzer) + "=add|@recvemote:" + (string)llGetOwnerKey(rezzer) + "=add|@recvchat:" + llList2String(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0) + "=add|@recvemote:" + llList2String(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0) + "=add");
}

applySpeech()
{
    llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@redirchat=y|@redirchat:" + (string)GAZE_CHAT_CHANNEL + "=rem|@redirchat:" + (string)DUMMY_CHANNEL + "=rem|@rediremote=y|@rediremote:" + (string)GAZE_CHAT_CHANNEL + "=rem|@rediremote:" + (string)DUMMY_CHANNEL + "=rem|@sendchannel_sec=y|@sendchannel_sec:" + (string)GAZE_CHAT_CHANNEL + "=rem|@sendchannel_sec:" + (string)DUMMY_CHANNEL + "=rem");
    if(speechRestrict == 0) llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@redirchat=n|@redirchat:" + (string)GAZE_CHAT_CHANNEL + "=add|@rediremote=n|@rediremote:" + (string)GAZE_CHAT_CHANNEL + "=add|@sendchannel_sec=n|@sendchannel_sec:" + (string)GAZE_CHAT_CHANNEL + "=add");
    if(speechRestrict == 1) llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@redirchat=n|@redirchat:" + (string)GAZE_CHAT_CHANNEL + "=add|@rediremote=n|@rediremote:" + (string)DUMMY_CHANNEL + "=add|@sendchannel_sec=n|@sendchannel_sec:" + (string)GAZE_CHAT_CHANNEL + "=add");
    if(speechRestrict == 2) llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@redirchat=n|@redirchat:" + (string)DUMMY_CHANNEL + "=add|@rediremote=n|@rediremote:" + (string)DUMMY_CHANNEL + "=add|@sendchannel_sec=n");
}

sitterMenu()
{
    string oldn = llGetObjectName();
    llSetObjectName("");
    llRegionSayTo(firstavatar, 0, "Object Options Menu:");
    llRegionSayTo(firstavatar, 0, " ");
    llRegionSayTo(firstavatar, 0, "IM Options:");
    if(imRestrict == 0)       llRegionSayTo(firstavatar, 0, " * No restrictions.");
    else                      llRegionSayTo(firstavatar, 0, " - No restrictions.");
    if(imRestrict < 1)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "im1 Cannot open IM sessions.]");
    else if(imRestrict == 1)  llRegionSayTo(firstavatar, 0, " * Cannot open IM sessions.");
    else                      llRegionSayTo(firstavatar, 0, " - Cannot open IM sessions.");
    if(imRestrict < 2)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "im2 Cannot send IMs.]");
    else if(imRestrict == 2)  llRegionSayTo(firstavatar, 0, " * Cannot send IMs.");
    else                      llRegionSayTo(firstavatar, 0, " - Cannot send IMs.");
    if(imRestrict < 3)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "im3 Cannot send or receive IMs.]");
    else if(imRestrict == 3)  llRegionSayTo(firstavatar, 0, " * Cannot send or receive IMs.");
    llRegionSayTo(firstavatar, 0, " ");
    llRegionSayTo(firstavatar, 0, "Vision Options:");
    if(visionRestrict == 0)       llRegionSayTo(firstavatar, 0, " * No restrictions.");
    else                          llRegionSayTo(firstavatar, 0, " - No restrictions.");
    if(visionRestrict < 1)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "vi1 Dark fog at 10 meters.]");
    else if(visionRestrict == 1)  llRegionSayTo(firstavatar, 0, " * Dark fog at 10 meters.");
    else                          llRegionSayTo(firstavatar, 0, " - Dark fog at 10 meters.");
    if(visionRestrict < 2)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "vi2 Light fog at 10 meters.]");
    else if(visionRestrict == 2)  llRegionSayTo(firstavatar, 0, " * Light fog at 10 meters.");
    else                          llRegionSayTo(firstavatar, 0, " - Light fog at 10 meters.");
    if(visionRestrict < 3)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "vi3 Dark fog at 5 meters.]");
    else if(visionRestrict == 3)  llRegionSayTo(firstavatar, 0, " * Dark fog at 5 meters.");
    else                          llRegionSayTo(firstavatar, 0, " - Dark fog at 5 meters.");
    if(visionRestrict < 4)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "vi4 Light fog at 5 meters.]");
    else if(visionRestrict == 4)  llRegionSayTo(firstavatar, 0, " * Light fog at 5 meters.");
    else                          llRegionSayTo(firstavatar, 0, " - Light fog at 5 meters.");
    if(visionRestrict < 5)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "vi5 Dark fog at 2 meters.]");
    else if(visionRestrict == 5)  llRegionSayTo(firstavatar, 0, " * Dark fog at 2 meters.");
    else                          llRegionSayTo(firstavatar, 0, " - Dark fog at 2 meters.");
    if(visionRestrict < 6)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "vi6 Light fog at 2 meters.]");
    else if(visionRestrict == 6)  llRegionSayTo(firstavatar, 0, " * Light fog at 2 meters.");
    else                          llRegionSayTo(firstavatar, 0, " - Light fog at 2 meters.");
    if(visionRestrict < 7)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "vi7 Blind.]");
    else if(visionRestrict == 7)  llRegionSayTo(firstavatar, 0, " * Blind.");
    llRegionSayTo(firstavatar, 0, " ");
    llRegionSayTo(firstavatar, 0, "Hearing Options:");
    if(hearingRestrict == 0)       llRegionSayTo(firstavatar, 0, " * No restrictions.");
    else                           llRegionSayTo(firstavatar, 0, " - No restrictions.");
    if(hearingRestrict < 1)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "he1 Incapable of hearing anyone but wearer and co-captured victims.]");
    else if(hearingRestrict == 1)  llRegionSayTo(firstavatar, 0, " * Incapable of hearing anyone but wearer and co-captured victims.");
    else                           llRegionSayTo(firstavatar, 0, " - Incapable of hearing anyone but wearer and co-captured victims.");
    if(hearingRestrict < 2)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "he2 Incapable of hearing anyone but wearer.]");
    else if(hearingRestrict == 2)  llRegionSayTo(firstavatar, 0, " * Incapable of hearing anyone but wearer.");
    else                           llRegionSayTo(firstavatar, 0, " - Incapable of hearing anyone but wearer.");
    if(hearingRestrict < 3)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "he3 Deaf.]");
    else if(hearingRestrict == 3)  llRegionSayTo(firstavatar, 0, " * Deaf.");
    llRegionSayTo(firstavatar, 0, " ");
    llRegionSayTo(firstavatar, 0, "Speech Options:");
    if(speechRestrict == 0)       llRegionSayTo(firstavatar, 0, " * No extra restrictions.");
    else                          llRegionSayTo(firstavatar, 0, " - No extra restrictions.");
    if(speechRestrict < 1)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "sp1 No longer capable of emoting.]");
    else if(speechRestrict == 1)  llRegionSayTo(firstavatar, 0, " * No longer capable of emoting.");
    else                          llRegionSayTo(firstavatar, 0, " - No longer capable of emoting.");
    if(speechRestrict < 2)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "sp2 Incapable of any kind of speech, even to owner.]");
    else if(speechRestrict == 2)  llRegionSayTo(firstavatar, 0, " * Incapable of any kind of speech, even to owner.");
    llRegionSayTo(firstavatar, 0, " ");
    llRegionSayTo(firstavatar, 0, "Visibility Options:");
    if(animation != "hide_a")  llRegionSayTo(firstavatar, 0, " - Under the ground, but avatar and nameplate visible.");
    else                       llRegionSayTo(firstavatar, 0, " * Under the ground, but avatar and nameplate visible.");
    if(animation != "hide_b")  llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "invis Completely invisible, even the nameplate. Slightly fiddly to become visible again after relog.]");
    else                       llRegionSayTo(firstavatar, 0, " * Completely invisible, even the nameplate. Slightly fiddly to become visible again after relog.");
    llSetObjectName(oldn);
}

ownerMenu()
{
    string oldn = llGetObjectName();
    llSetObjectName("");
    llOwnerSay("Object Options Menu:");
    llOwnerSay(" ");
    llOwnerSay("IM Options:");
    if(imRestrict != 0)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "im0 No restrictions.]");
    else                 llOwnerSay(" * No restrictions.");
    if(imRestrict != 1)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "im1 Cannot open IM sessions.]");
    else                 llOwnerSay(" * Cannot open IM sessions.");
    if(imRestrict != 2)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "im2 Cannot send IMs.]");
    else                 llOwnerSay(" * Cannot send IMs.");
    if(imRestrict != 3)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "im3 Cannot send or receive IMs.]");
    else                 llOwnerSay(" * Cannot send or receive IMs.");
    llOwnerSay(" ");
    llOwnerSay("Vision Options:");
    if(visionRestrict != 0)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "vi0 No restrictions.]");
    else                     llOwnerSay(" * No restrictions.");
    if(visionRestrict != 1)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "vi1 Dark fog at 10 meters.]");
    else                     llOwnerSay(" * Dark fog at 10 meters.");
    if(visionRestrict != 2)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "vi2 Light fog at 10 meters.]");
    else                     llOwnerSay(" * Light fog at 10 meters.");
    if(visionRestrict != 3)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "vi3 Dark fog at 5 meters.]");
    else                     llOwnerSay(" * Dark fog at 5 meters.");
    if(visionRestrict != 4)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "vi4 Light fog at 5 meters.]");
    else                     llOwnerSay(" * Light fog at 5 meters.");
    if(visionRestrict != 5)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "vi5 Dark fog at 2 meters.]");
    else                     llOwnerSay(" * Dark fog at 2 meters.");
    if(visionRestrict != 6)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "vi6 Light fog at 2 meters.]");
    else                     llOwnerSay(" * Light fog at 2 meters.");
    if(visionRestrict != 7)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "vi7 Blind.]");
    else                     llOwnerSay(" * Blind.");
    llOwnerSay(" ");
    llOwnerSay("Hearing Options:");
    if(hearingRestrict != 0)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "he0 No restrictions.]");
    else                      llOwnerSay(" * No restrictions.");
    if(hearingRestrict != 1)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "he1 Incapable of hearing anyone but wearer and co-captured victims.]");
    else                      llOwnerSay(" * Incapable of hearing anyone but wearer and co-captured victims.");
    if(hearingRestrict != 2)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "he2 Incapable of hearing anyone but wearer.]");
    else                      llOwnerSay(" * Incapable of hearing anyone but wearer.");
    if(hearingRestrict != 3)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "he3 Deaf.]");
    else                      llOwnerSay(" * Deaf.");
    llOwnerSay(" ");
    llOwnerSay("Speech Options:");
    if(speechRestrict != 0)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "sp0 No extra restrictions.]");
    else                     llOwnerSay(" * No extra restrictions.");
    if(speechRestrict != 1)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "sp1 No longer capable of emoting.]");
    else                     llOwnerSay(" * No longer capable of emoting.");
    if(speechRestrict != 2)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "sp2 Incapable of any kind of speech, even to owner.]");
    else                     llOwnerSay(" * Incapable of any kind of speech, even to owner.");
    llOwnerSay(" ");
    llOwnerSay("Visibility Options:");
    if(animation != "hide_a")  llOwnerSay(" - Under the ground, but avatar and nameplate visible.");
    else                       llOwnerSay(" * Under the ground, but avatar and nameplate visible.");
    if(animation != "hide_b")  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "invis Completely invisible, even the nameplate. Slightly fiddly to become visible again after relog.]");
    else                       llOwnerSay(" * Completely invisible, even the nameplate. Slightly fiddly to become visible again after relog.");
    llOwnerSay(" ");
    llOwnerSay("Other Options:");
    llOwnerSay(" - Type /5 " + prefix + "name <new name> to rename this object.");
    llOwnerSay(" - If there is a purple cylinder present, you can move it to change the object's nameplate, then click it to hide it.");
    llSetObjectName(oldn);
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
        saton = FALSE;
        editmode = FALSE;
        seatedoffset = ZERO_VECTOR;
        waitingstate = 0;
        prefix = llGetSubString((string)llGetKey(), -10, -1);
        
        // Set the rezzer and default animation.
        rezzer = (key)llList2String(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0);
        animation = "hide_a";

        // Set certain settings based on the start parameter.
        if(start_param & 2) animation = "hide_b";
        if(start_param & 4) keyisavatar = FALSE;

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
                    llListen(GAZE_CHAT_CHANNEL, "", llAvatarOnSitTarget(), "");
                    llListen(RLVRC, "", NULL_KEY, "");
                }

                // Otherwise only allow the first sitter.
                if(firstavatar != llAvatarOnSitTarget()) llUnSit(llAvatarOnSitTarget());

                // Make sure to flag that we have been sat on.
                saton = TRUE;
                
                if(!captured) 
                {
                    llRegionSayTo(rezzer, STRUGGLE_CHANNEL, "captured|" + (string)firstavatar + "|object");
                    captured = TRUE;
                }

                // And animate the sat avatar.
                llRequestPermissions(llAvatarOnSitTarget(), PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS);
            }
        }
    }

    run_time_permissions(integer perm)
    {
        // Let the IT slave know to turn off its garbler.
        llRegionSayTo(llAvatarOnSitTarget(), COMMAND_CHANNEL, "*onball " + (string)llGetKey());

        // Apply RLV restrictions.
        llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@shownames_sec:" + (string)llGetOwnerKey(rezzer) + "=n|@shownametags=n|@shownearby=n|@showhovertextall=n|@showworldmap=n|@showminimap=n|@showloc=n|@setcam_focus:" + (string)rezzer + ";;1/0/0=force|@setcam_origindistmax:10=n|@buy=n|@pay=n|@unsit=n|@tplocal=n|@tplm=n|@tploc=n|@tplure_sec=n|@showinv=n|@interact=n|@showself=n|@sendgesture=n|@sendim:" + (string)llGetOwnerKey(rezzer) + "=add|@startim:" + (string)llGetOwnerKey(rezzer) + "=add|@recvim:" + (string)llGetOwnerKey(rezzer) + "=add|@sendchannel_sec:5=add");
        applyIm();
        applyHearing();
        applySpeech();
        applyVision();

        // Start the animation.
        llStartAnimation(animation);

        // Take controls.
        llTakeControls(CONTROL_FWD | CONTROL_BACK | CONTROL_LEFT | CONTROL_RIGHT | CONTROL_ROT_LEFT | CONTROL_ROT_RIGHT | CONTROL_UP | CONTROL_DOWN, TRUE, TRUE);

        // Notify of menu.
        llRegionSayTo(llAvatarOnSitTarget(), 0, "You can access a menu to restrict yourself further by clicking [secondlife:///app/chat/5/menu here] or by typing /5menu.");

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
        else if(c == GAZE_ECHO_CHANNEL)
        {
            if(hearingRestrict > 1) return;
            string oldn = llGetObjectName();
            llSetObjectName(n);
            llRegionSayTo(llAvatarOnSitTarget(), 0, m);
            llSetObjectName(oldn);
        }
        else if(c == BALL_CHANNEL)
        {
            if(keyisavatar == FALSE || llGetOwnerKey(id) != rezzer) return;
            if(hearingRestrict == 3) return;
            string oldn = llGetObjectName();
            llSetObjectName("Wearer's Thoughts");
            llRegionSayTo(llAvatarOnSitTarget(), 0, m);
            llSetObjectName(oldn);
        }
        else if(c == 5)
        {
            if(id != firstavatar && rezzer != llGetOwnerKey(id)) return;
            if(m == "menu" && id == firstavatar) sitterMenu();
            else if(m == "menu" && rezzer == llGetOwnerKey(id)) ownerMenu();
            else if(startswith(m, prefix + "im"))
            {
                if(id == firstavatar && imRestrict > (integer)llGetSubString(m, -1, -1)) return;
                imRestrict = (integer)llGetSubString(m, -1, -1);
                if(imRestrict < 0) imRestrict = 0;
                if(imRestrict > 3) imRestrict = 3;
                string oldn = llGetObjectName();
                llSetObjectName("");
                llOwnerSay("secondlife:///app/agent/" + (string)firstavatar + "/about's IM restrictions set to level " + (string)imRestrict + ".");
                llRegionSayTo(firstavatar, 0, "secondlife:///app/agent/" + (string)firstavatar + "/about's IM restrictions set to level " + (string)imRestrict + ".");
                applyIm();
                llSetObjectName(oldn);
            }
            else if(startswith(m, prefix + "vi"))
            {
                if(id == firstavatar && visionRestrict > (integer)llGetSubString(m, -1, -1)) return;
                visionRestrict = (integer)llGetSubString(m, -1, -1);
                if(visionRestrict < 0) visionRestrict = 0;
                if(visionRestrict > 7) visionRestrict = 7;
                string oldn = llGetObjectName();
                llSetObjectName("");
                llOwnerSay("secondlife:///app/agent/" + (string)firstavatar + "/about's Vision restrictions set to level " + (string)visionRestrict + ".");
                llRegionSayTo(firstavatar, 0, "secondlife:///app/agent/" + (string)firstavatar + "/about's Vision restrictions set to level " + (string)visionRestrict + ".");
                applyVision();
                llSetObjectName(oldn);
            }
            else if(startswith(m, prefix + "he"))
            {
                if(id == firstavatar && hearingRestrict > (integer)llGetSubString(m, -1, -1)) return;
                hearingRestrict = (integer)llGetSubString(m, -1, -1);
                if(hearingRestrict < 0) hearingRestrict = 0;
                if(hearingRestrict > 3) hearingRestrict = 3;
                string oldn = llGetObjectName();
                llSetObjectName("");
                llOwnerSay("secondlife:///app/agent/" + (string)firstavatar + "/about's Hearing restrictions set to level " + (string)hearingRestrict + ".");
                llRegionSayTo(firstavatar, 0, "secondlife:///app/agent/" + (string)firstavatar + "/about's Hearing restrictions set to level " + (string)hearingRestrict + ".");
                applyHearing();
                llSetObjectName(oldn);
            }
            else if(startswith(m, prefix + "sp"))
            {
                if(id == firstavatar && speechRestrict > (integer)llGetSubString(m, -1, -1)) return;
                speechRestrict = (integer)llGetSubString(m, -1, -1);
                if(speechRestrict < 0) speechRestrict = 0;
                if(speechRestrict > 2) speechRestrict = 2;
                string oldn = llGetObjectName();
                llSetObjectName("");
                llOwnerSay("secondlife:///app/agent/" + (string)firstavatar + "/about's Speech restrictions set to level " + (string)speechRestrict + ".");
                llRegionSayTo(firstavatar, 0, "secondlife:///app/agent/" + (string)firstavatar + "/about's Speech restrictions set to level " + (string)speechRestrict + ".");
                applySpeech();
                llSetObjectName(oldn);
            }
            else if(m == prefix + "invis")
            {
                if(animation == "hide_b") return;
                llStopAnimation(animation);
                animation = "hide_b";
                llStartAnimation(animation);
                string oldn = llGetObjectName();
                llSetObjectName("");
                llOwnerSay("secondlife:///app/agent/" + (string)firstavatar + "/about is now rendered truly invisible, nameplate and all.");
                llRegionSayTo(firstavatar, 0, "secondlife:///app/agent/" + (string)firstavatar + "/about is now rendered truly invisible, nameplate and all.");
                llSetObjectName(oldn);
            }
            else if(startswith(m, prefix + "name"))
            {
                if(id == firstavatar) return;
                m = llDeleteSubString(m, 0, llStringLength(prefix + "name"));
                string oldn = llGetObjectName();
                llSetObjectName("");
                llOwnerSay("secondlife:///app/agent/" + (string)firstavatar + "/about is now " + m + ".");
                llRegionSayTo(firstavatar, 0, "secondlife:///app/agent/" + (string)firstavatar + "/about is now " + m + ".");
                llRegionSayTo(rezzer, MANTRA_CHANNEL, "objrename " + m);
                llSetObjectName(oldn);
            }
        }
        else if(c == MANTRA_CHANNEL)
        {
            if(m == "unsit")
            {
                if(llAvatarOnSitTarget() == NULL_KEY) die();
                llSetRegionPos(llList2Vector(llGetObjectDetails(rezzer, [OBJECT_POS]), 0));
                if(animation == "hide_b")
                {
                    string oldn = llGetObjectName();
                    llSetObjectName("");
                    llRegionSayTo(llAvatarOnSitTarget(), 0, "Note: The animation currently making you invisible can be a little tricky to get rid of. If you remain invisible after you are freed, put on something and then take it off again. If this doesn't help, relog.");
                    llSetObjectName(oldn);
                }
                llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "release," + (string)llAvatarOnSitTarget() + ",!release");
                llSleep(0.5);
                llUnSit(llAvatarOnSitTarget());
                llSleep(10.0);
                die();
            }
            else if(startswith(m, "rlvforward"))
            {
                if(llAvatarOnSitTarget() == NULL_KEY) die();
                m = llDeleteSubString(m, 0, llStringLength("rlvforward"));
                llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "cmd," + (string)llAvatarOnSitTarget() + "," + m);
                llRegionSayTo(rezzer, MANTRA_CHANNEL, "rlvresponse ok");
            }
            else if(m == "check")
            {
                if(llAvatarOnSitTarget() == NULL_KEY) die();
            }
            else if(startswith(m, "sit"))
            {
                m = llDeleteSubString(m, 0, llStringLength("sit"));
                firstavatar = (key)m;
                llListen(GAZE_CHAT_CHANNEL, "", firstavatar, "");
                llListen(RLVRC, "", NULL_KEY, "");
                llRegionSayTo((key)m, RLVRC, "c," + m + ",@sit:" + (string)llGetKey() + "=force|@shownearby=n");
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
                    llSetRegionPos(llList2Vector(llGetObjectDetails(rezzer, [OBJECT_POS]), 0));
                    if(animation == "hide_b") llRegionSayTo(firstavatar, 0, "Note: The animation currently making you invisible can be a little tricky to get rid of. If you remain invisible after you are freed, put on something and then take it off again. If this doesn't help, relog.");
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
            if(keyisavatar) offset = seatedoffset;

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
            float dist = llVecDist(my, pos);
            my.z = pos.z;
            float xydist = llVecDist(my, pos);
            if(xydist > 365.0 || pos == ZERO_VECTOR)
            {
                // More than a region away on a flat plane. This should never happen. Die.
                llSetRegionPos(llGetPos() - offset);
                llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "release," + (string)llAvatarOnSitTarget() + ",@shownames_sec=y|@shownametags=y|@shownearby=y|@showhovertextall=y|@showworldmap=y|@showminimap=y|@showloc=y|@setcam_origindistmax:10=y|@buy=y|@pay=y|@unsit=y|@tplocal=y|@tplm=y|@tploc=y|@tplure_sec=y|@showinv=y|@interact=y|@showself=y|@sendgesture=y|@redirchat:" + (string)GAZE_CHAT_CHANNEL + "=rem|@rediremote:" + (string)GAZE_CHAT_CHANNEL + "=rem|@sendchannel_sec=y|@sendchannel_sec:" + (string)GAZE_CHAT_CHANNEL + "=rem");
                llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "release," + (string)llAvatarOnSitTarget() + ",!release");
                llSleep(0.5);
                llUnSit(llAvatarOnSitTarget());
                llSleep(10.0);
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

            llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@setcam_focus:" + (string)rezzer + ";;=force");
        }
    }
}