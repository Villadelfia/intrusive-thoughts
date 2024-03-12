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
integer retries = 50;

integer furnitureCameraMode = 0;
key furnitureCameraPos = NULL_KEY;
key furnitureCameraFocus = NULL_KEY;

// Creators of stuff that is likely near furniture that should NOT be focused on.
// We want this to focus on people that can move only.
list furnitureCameraBlacklist = [
    "ebb81fdb-8c5b-4afe-94bd-2e790d823491", // Watsoon Steampunk
    "9870257c-0c11-4329-bde9-e7f5e414a992", // MzBitch2u
    "dc6a91c8-540e-4434-b996-895455915685", // Tammy Badger
    "c93fd4fd-e26e-4807-94cb-998877925d8a", // Siennajessicamoon
    "0520e63a-236e-4902-9eb6-590a0eae48ad", // Snot Gothly
    "ef227582-1e78-4fed-986a-76bdcad5dfb3", // Valtum
    "6d9cbaea-b83e-4a5d-8043-9bf1faee651a", // LitaRubeus
    "bc50a813-5b31-4cbe-9ae6-0031d1b7d53e", // Jenni Silverpath
    "23e29f4a-caad-47dc-b6ce-7d6d59f5ca4d", // Carina Asbrink
    "b8dad95f-3875-48ae-a830-ae1972619ccb", // Nic Feila
    "d7c82582-33de-42db-9982-e9bd8ba9c026", // Rayeanners
    "63d32336-7cdf-4888-8ad1-89e521345ee6", // Puetano
    "145b5e86-fcb2-4351-877a-0dfe65e80518", // Honey Puddles
    "bfb5d38f-ce9e-4701-ac71-79663a25d435", // Tammy Dismantled
    "d0dcc51e-d359-4103-bba5-d265984ace21", // Issmir
    "0788796c-b64a-4ad5-8528-a605a2fdc4ba", // Vanessa Foote
    "1aaf1cad-8d64-4966-b1ee-4d17dee81ca9"  // Myself
];

// Z-base of the furniture. To avoid focusing on people that are much above or below us.
float furnitureCameraZBase = 0.0;

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

vector positionOffset = ZERO_VECTOR;
rotation rotationOffset = ZERO_ROTATION;

die()
{
    if(firstavatar) llRegionSayTo(rezzer, STRUGGLE_CHANNEL, "released|" + (string)firstavatar);
    llSetAlpha(0.0, ALL_SIDES);
    llSetPrimitiveParams([PRIM_TEMP_ON_REZ, TRUE]);
    llDie();
    while(TRUE) llSleep(60.0);
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

getZBase()
{
    furnitureCameraZBase = 0.0;
    list     info = llGetObjectDetails(rezzer, [OBJECT_POS, OBJECT_ROT]) + llGetBoundingBox(rezzer);
    vector   pos  = llList2Vector(info, 0);
    rotation rot  = llList2Rot(info, 1);
    vector   c1   = llList2Vector(info, 2) * rot + pos;
    vector   c2   = llList2Vector(info, 3) * rot + pos;
    if(c1.z < c2.z) furnitureCameraZBase = c1.z;
    else            furnitureCameraZBase = c2.z;
}

toggleedit()
{
    if(editmode == FALSE && (keyisavatar == TRUE && (llGetAgentInfo(rezzer) & AGENT_SITTING) == 0)) return;
    if(animation == "hide_b") return;
    editmode = !editmode;
    if(keyisavatar == TRUE)
    {
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
    else
    {
        if(editmode)
        {
            llSetAlpha(1.0, ALL_SIDES);
            llSetScale(<0.1, 0.1, 5.0>);
        }
        else
        {
            rotationOffset = llGetRot();
            positionOffset = llGetPos() - llList2Vector(llGetObjectDetails(rezzer, [OBJECT_POS]), 0);
            llRegionSayTo(rezzer, MANTRA_CHANNEL, "offsets;" + (string)positionOffset + ";" + (string)rotationOffset);
            llSetAlpha(0.0, ALL_SIDES);
            llSetScale(<0.1, 0.1, 0.1>);
        }
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
        llSitTarget(<0.0, 0.0, 0.1>, ZERO_ROTATION);
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
        if(keyisavatar)
        {
            rezzer = llGetOwnerKey(rezzer);
        }
        else
        {
            getZBase();
            name = llList2String(llGetObjectDetails(rezzer, [OBJECT_NAME]), 0);
        }

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
                // Go invis.
                llSetAlpha(0.0, ALL_SIDES);

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
                llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@unsit=n|tplocal=n|@tplm=n|@tploc=n|@tplure=n|@sendgesture=n|@startim:" + (string)llGetOwnerKey(rezzer) + "=add|@recvim:" + (string)llGetOwnerKey(rezzer) + "=add|@sendim:" + (string)llGetOwnerKey(rezzer) + "=add");
                if(llGetInventoryNumber(INVENTORY_ANIMATION) == 2) llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@showself=n");
                llMessageLinked(LINK_THIS, X_API_APPLY_IM, (string)imRestrict, NULL_KEY);
                llMessageLinked(LINK_THIS, X_API_APPLY_HEARING, (string)hearingRestrict, NULL_KEY);
                llMessageLinked(LINK_THIS, X_API_APPLY_SPEECH, (string)speechRestrict, NULL_KEY);
                llMessageLinked(LINK_THIS, X_API_APPLY_VISION, (string)visionRestrict, NULL_KEY);
                llMessageLinked(LINK_THIS, X_API_APPLY_DAZE, (string)dazeRestrict, NULL_KEY);
                llMessageLinked(LINK_THIS, X_API_APPLY_CAMERA, (string)cameraRestrict, NULL_KEY);
                llMessageLinked(LINK_THIS, X_API_APPLY_INVENTORY, (string)inventoryRestrict, NULL_KEY);
                llMessageLinked(LINK_THIS, X_API_APPLY_WORLD, (string)worldRestrict, NULL_KEY);
                llMessageLinked(LINK_THIS, X_API_APPLY_INVENTORY, (string)inventoryRestrict, NULL_KEY);

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
        if(llGetInventoryNumber(INVENTORY_ANIMATION) == 2)
        {
            llStartAnimation(animation);
        }
        else
        {
            integer i = 0;
            integer l = llGetInventoryNumber(INVENTORY_ANIMATION);
            for(i = 0; i < l; ++i)
            {
                string n = llGetInventoryName(INVENTORY_ANIMATION, i);
                if(n != "hide_a" && n != "hide_b") llStartAnimation(n);
            }
            animation = "hide_a";
        }


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
        if(keyisavatar == FALSE && editmode == TRUE) toggleedit();
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
                if(llGetInventoryNumber(INVENTORY_ANIMATION) == 2)
                {
                    if(animation == "hide_b")
                    {
                        if(id == firstavatar) return;
                        llStopAnimation(animation);
                        animation = "hide_a";
                        llStartAnimation(animation);
                        llMessageLinked(LINK_THIS, X_API_NOTIFY_HIDEA, "", firstavatar);
                        llMessageLinked(LINK_THIS, X_API_SETTINGS_SAVE, restrictionString(), NULL_KEY);
                    }
                    else
                    {
                        llStopAnimation(animation);
                        animation = "hide_b";
                        llStartAnimation(animation);
                        llMessageLinked(LINK_THIS, X_API_NOTIFY_HIDEB, "", firstavatar);
                        llMessageLinked(LINK_THIS, X_API_SETTINGS_SAVE, restrictionString(), NULL_KEY);
                    }
                }
            }
            else if(startswith(m, prefix + "name"))
            {
                if(id == firstavatar) return;
                m = llDeleteSubString(m, 0, llStringLength(prefix + "name"));
                name = m;
                llMessageLinked(LINK_THIS, X_API_NOTIFY_NAME, objectprefix + m, firstavatar);
                llRegionSayTo(rezzer, MANTRA_CHANNEL, "objrename " + m);
            }
            else if(startswith(m, prefix + "im"))
            {
                imRestrict = (integer)llGetSubString(m, -1, -1);
                if(imRestrict < 0) imRestrict = 0;
                if(imRestrict > 3) imRestrict = 3;
                llMessageLinked(LINK_THIS, X_API_APPLY_IM, (string)imRestrict, NULL_KEY);
                llMessageLinked(LINK_THIS, X_API_NOTIFY_IM, (string)imRestrict, firstavatar);
                llMessageLinked(LINK_THIS, X_API_SETTINGS_SAVE, restrictionString(), NULL_KEY);
            }
            else if(startswith(m, prefix + "vi"))
            {
                visionRestrict = (integer)llGetSubString(m, -1, -1);
                if(visionRestrict < 0) visionRestrict = 0;
                if(visionRestrict > 9) visionRestrict = 9;
                llMessageLinked(LINK_THIS, X_API_APPLY_VISION, (string)visionRestrict, NULL_KEY);
                llMessageLinked(LINK_THIS, X_API_NOTIFY_VISION, (string)visionRestrict, firstavatar);
                llMessageLinked(LINK_THIS, X_API_SETTINGS_SAVE, restrictionString(), NULL_KEY);
            }
            else if(startswith(m, prefix + "he"))
            {
                hearingRestrict = (integer)llGetSubString(m, -1, -1);
                if(hearingRestrict < 0) hearingRestrict = 0;
                if(hearingRestrict > 3) hearingRestrict = 3;
                llMessageLinked(LINK_THIS, X_API_APPLY_HEARING, (string)hearingRestrict, NULL_KEY);
                llMessageLinked(LINK_THIS, X_API_NOTIFY_HEARING, (string)hearingRestrict, firstavatar);
                llMessageLinked(LINK_THIS, X_API_SETTINGS_SAVE, restrictionString(), NULL_KEY);
            }
            else if(startswith(m, prefix + "sp"))
            {
                speechRestrict = (integer)llGetSubString(m, -1, -1);
                if(speechRestrict < 0) speechRestrict = 0;
                if(speechRestrict > 3) speechRestrict = 3;
                llMessageLinked(LINK_THIS, X_API_APPLY_SPEECH, (string)speechRestrict, NULL_KEY);
                llMessageLinked(LINK_THIS, X_API_NOTIFY_SPEECH, (string)speechRestrict, firstavatar);
                llMessageLinked(LINK_THIS, X_API_SETTINGS_SAVE, restrictionString(), NULL_KEY);
            }
            else if(startswith(m, prefix + "da"))
            {
                dazeRestrict = (integer)llGetSubString(m, -1, -1);
                if(dazeRestrict < 0) dazeRestrict = 0;
                if(dazeRestrict > 1) dazeRestrict = 1;
                llMessageLinked(LINK_THIS, X_API_APPLY_DAZE, (string)dazeRestrict, NULL_KEY);
                llMessageLinked(LINK_THIS, X_API_NOTIFY_DAZE, (string)dazeRestrict, firstavatar);
                llMessageLinked(LINK_THIS, X_API_SETTINGS_SAVE, restrictionString(), NULL_KEY);
            }
            else if(startswith(m, prefix + "ca"))
            {
                cameraRestrict = (integer)llGetSubString(m, -1, -1);
                if(cameraRestrict < 0) cameraRestrict = 0;
                if(cameraRestrict > 1) cameraRestrict = 1;
                llMessageLinked(LINK_THIS, X_API_APPLY_CAMERA, (string)cameraRestrict, NULL_KEY);
                llMessageLinked(LINK_THIS, X_API_NOTIFY_CAMERA, (string)cameraRestrict, firstavatar);
                llMessageLinked(LINK_THIS, X_API_SETTINGS_SAVE, restrictionString(), NULL_KEY);
            }
            else if(startswith(m, prefix + "in"))
            {
                inventoryRestrict = (integer)llGetSubString(m, -1, -1);
                if(inventoryRestrict < 0) inventoryRestrict = 0;
                if(inventoryRestrict > 1) inventoryRestrict = 1;
                llMessageLinked(LINK_THIS, X_API_APPLY_INVENTORY, (string)inventoryRestrict, NULL_KEY);
                llMessageLinked(LINK_THIS, X_API_NOTIFY_INVENTORY, (string)inventoryRestrict, firstavatar);
                llMessageLinked(LINK_THIS, X_API_SETTINGS_SAVE, restrictionString(), NULL_KEY);
            }
            else if(startswith(m, prefix + "wo"))
            {
                worldRestrict = (integer)llGetSubString(m, -1, -1);
                if(worldRestrict < 0) worldRestrict = 0;
                if(worldRestrict > 1) worldRestrict = 1;
                llMessageLinked(LINK_THIS, X_API_APPLY_INVENTORY, (string)inventoryRestrict, NULL_KEY);
                llMessageLinked(LINK_THIS, X_API_NOTIFY_WORLD, (string)worldRestrict, firstavatar);
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
            else if(startswith(m, "offsets"))
            {
                list params = llParseString2List(m, [";"], []);
                positionOffset = (vector)llList2String(params, 1);
                rotationOffset = (rotation)llList2String(params, 2);
                llSetRot(rotationOffset);
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
                llSetRegionPos(pos + <0.25, 0.0, 0.0>);
                llListen(RLVRC, "", NULL_KEY, "");
                llRegionSayTo(firstavatar, RLVRC, "c," + (string)firstavatar + ",@sit:" + (string)llGetKey() + "=force|@tplocal=n");
                llSetTimerEvent(60.0);
            }
            else if(m == "edit" && (llGetOwnerKey(id) == llGetOwnerKey(rezzer) || id == rezzer))
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
                getZBase();
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
                if(llList2Key(llGetObjectDetails(firstavatar, [OBJECT_ROOT]), 0) == llGetKey())
                {
                    llRegionSayTo(rezzer, RLVRC, "c," + llList2String(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0) + ",@sit=n,ok");
                }
                else
                {
                    sensortimer(0.5);
                }
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

    no_sensor()
    {
        if(llList2Key(llGetObjectDetails(firstavatar, [OBJECT_ROOT]), 0) == llGetKey())
        {
            llRegionSayTo(rezzer, RLVRC, "c," + llList2String(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0) + ",@sit=n,ok");
            sensortimer(0.0);
        }
        else
        {
            retries--;
            if(retries > 0)
            {
                llRegionSayTo(firstavatar, RLVRC, "c," + (string)firstavatar + ",@sit:" + (string)llGetKey() + "=force");
            }
            else
            {
                llRegionSayTo(rezzer, RLVRC, "c," + llList2String(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0) + ",@sit=n,ko");
                sensortimer(0.0);
                die();
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

            if(llList2Vector(llGetObjectDetails(llGetOwnerKey(rezzer), [OBJECT_POS]), 0) == ZERO_VECTOR && llList2Vector(llGetObjectDetails(rezzer, [OBJECT_POS]), 0) == ZERO_VECTOR)
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

            vector pos = llList2Vector(llGetObjectDetails(rezzer, [OBJECT_POS]), 0);
            if(pos == ZERO_VECTOR) pos = llList2Vector(llGetObjectDetails(rezzer, [OBJECT_POS]), 0);
            if(llGetInventoryNumber(INVENTORY_ANIMATION) == 2)
            {
                pos += offset;
            }
            else
            {
                pos += positionOffset;
            }
            float dist = llVecDist(my, pos);
            if(dist > 60.0 && pos.x <= 256 && pos.x >= 0 && pos.y <= 256 && pos.y >= 0)
            {
                llSetTimerEvent(0.5);
                llSetStatus(STATUS_PHYSICS, FALSE);
                llStopMoveToTarget();
                llSetRegionPos(pos);
            }
            else if(dist > 0.05)
            {
                if(pos.x > 256.0 || pos.x < 0 || pos.y > 256.0 || pos.y < 0) llSetTimerEvent(2.5);
                else llSetTimerEvent(0.5);
                llMoveToTarget(pos, 0.1);
                llSetStatus(STATUS_PHYSICS, TRUE);
            }
            else if(llGetStatus(STATUS_PHYSICS))
            {
                llSetTimerEvent(0.5);
                llSetStatus(STATUS_PHYSICS, FALSE);
                llStopMoveToTarget();
            }

            timerctr++;
            if(timerctr % 10 == 0) llRegionSayTo(rezzer, MANTRA_CHANNEL, "objurl " + url);

            if(keyisavatar == FALSE && furnitureCameraMode != 0 && furnitureCameraPos != NULL_KEY && furnitureCameraFocus != NULL_KEY)
            {
                if(timerctr % 10 == 0) llRegionSayTo(llAvatarOnSitTarget(), RLVRC, "restrict," + (string)llAvatarOnSitTarget() + ",@setcam_unlock=n");
                getZBase();
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
                    if(dist < closestDist && id != llAvatarOnSitTarget())
                    {
                        // Are they sitting?
                        key what = llList2Key(llGetObjectDetails(id, [OBJECT_ROOT]), 0);

                        if(what != id)
                        {
                            // Who made it?
                            string creator = (string)llList2Key(llGetObjectDetails(what, [OBJECT_CREATOR]), 0);

                            // If it's in the blacklist, don't use  this person.
                            if(llListFindList(furnitureCameraBlacklist, [creator]) != -1) jump endOfCheck;
                        }

                        // Are they too far above or below us?
                        if(llFabs(pos.z - furnitureCameraZBase) > 1.5) jump endOfCheck;

                        // In any other case, save them.
                        closestDist = dist;
                        closestPerson = id;
                        closestPos = pos;
                    }
                    @endOfCheck;
                }

                if(furnitureCameraMode == 1 || closestDist > 10.0)
                {
                    // Focus to self.
                    // Wiggle the camera position softly.
                    llSetCameraParams([
                        CAMERA_ACTIVE, 1,
                        CAMERA_POSITION_LAG, 0.49,
                        CAMERA_POSITION, posPos + <0.0, 0.0, 0.025 * llSin(llGetTime() / 10)>,
                        CAMERA_POSITION_LOCKED, TRUE,
                        CAMERA_POSITION_THRESHOLD, 0.0,
                        CAMERA_FOCUS_LAG, 0.49,
                        CAMERA_FOCUS, focusPos,
                        CAMERA_FOCUS_LOCKED, TRUE,
                        CAMERA_FOCUS_THRESHOLD, 0.0
                    ]);
                }
                else
                {
                    // Focus on person nearby.
                    // Wiggle up and down a little.
                    llSetCameraParams([
                        CAMERA_ACTIVE, 1,
                        CAMERA_POSITION_LAG, 0.49,
                        CAMERA_POSITION, focusPos,
                        CAMERA_POSITION_LOCKED, TRUE,
                        CAMERA_POSITION_THRESHOLD, 0.0,
                        CAMERA_FOCUS_LAG, 0.49,
                        CAMERA_FOCUS, closestPos + <0.0, 0.0, 0.025 * llSin(llGetTime() / 10)>,
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
            if(imRestrict > 0) llMessageLinked(LINK_THIS, X_API_NOTIFY_IM, (string)imRestrict, firstavatar);
            if(visionRestrict > 0) llMessageLinked(LINK_THIS, X_API_NOTIFY_VISION, (string)visionRestrict, firstavatar);
            if(hearingRestrict > 0) llMessageLinked(LINK_THIS, X_API_NOTIFY_HEARING, (string)hearingRestrict, firstavatar);
            if(speechRestrict != 1) llMessageLinked(LINK_THIS, X_API_NOTIFY_SPEECH, (string)speechRestrict, firstavatar);
            if(dazeRestrict != 1) llMessageLinked(LINK_THIS, X_API_NOTIFY_DAZE, (string)dazeRestrict, firstavatar);
            if(cameraRestrict != 1) llMessageLinked(LINK_THIS, X_API_NOTIFY_CAMERA, (string)cameraRestrict, firstavatar);
            if(inventoryRestrict != 1) llMessageLinked(LINK_THIS, X_API_NOTIFY_INVENTORY, (string)inventoryRestrict, firstavatar);
            if(worldRestrict != 1) llMessageLinked(LINK_THIS, X_API_NOTIFY_WORLD, (string)worldRestrict, firstavatar);
            if(isHidden && animation != "hide_b" && llGetInventoryNumber(INVENTORY_ANIMATION) == 2)
            {
                if(llGetPermissions() & PERMISSION_TRIGGER_ANIMATION) llStopAnimation(animation);
                animation = "hide_b";
                if(llGetPermissions() & PERMISSION_TRIGGER_ANIMATION) llStartAnimation(animation);
                llMessageLinked(LINK_THIS, X_API_NOTIFY_HIDEB, "", firstavatar);
            }
            llMessageLinked(LINK_THIS, X_API_APPLY_IM, (string)imRestrict, NULL_KEY);
            llMessageLinked(LINK_THIS, X_API_APPLY_VISION, (string)visionRestrict, NULL_KEY);
            llMessageLinked(LINK_THIS, X_API_APPLY_HEARING, (string)hearingRestrict, NULL_KEY);
            llMessageLinked(LINK_THIS, X_API_APPLY_SPEECH, (string)speechRestrict, NULL_KEY);
            llMessageLinked(LINK_THIS, X_API_APPLY_DAZE, (string)dazeRestrict, NULL_KEY);
            llMessageLinked(LINK_THIS, X_API_APPLY_CAMERA, (string)cameraRestrict, NULL_KEY);
            llMessageLinked(LINK_THIS, X_API_APPLY_INVENTORY, (string)inventoryRestrict, NULL_KEY);
            llMessageLinked(LINK_THIS, X_API_APPLY_INVENTORY, (string)inventoryRestrict, NULL_KEY);
        }
    }
}
