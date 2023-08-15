#include <IT/globals.lsl>
integer handle1;
integer handle2;
string animation = "";
key objectifier = NULL_KEY;
key urlt;
string url = "null";
string name;
string objectprefix = "";
integer waitingstate;
integer struggleEvents = 0;
integer struggleFailed = FALSE;
integer keyisavatar = FALSE;
string prefix = "??";
integer firstattempt = TRUE;
integer firstoutrange = TRUE;
integer leashinghandle;
vector leashtarget;
integer leasherinrange;

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
    llRegionSayTo(objectifier, STRUGGLE_CHANNEL, "released|" + (string)llGetOwner());
    llOwnerSay("@clear,detachme=force");
}

capture()
{
    llSetObjectName("");

    // If I'm objectifying for an avatar, let them know.
    if(keyisavatar) llRegionSayTo(objectifier, 0, "secondlife:///app/agent/" + (string)llGetOwner() + "/about is being objectified in a no-rez zone.");

    // Basic RLV restrictions:
    //  - No detaching.
    //  - No flying.
    //  - Forced stand up and no sitting.
    //  - No teleporting or getting teleported.
    //  - Hide self.
    //  - No gestures.
    llOwnerSay("@detach=n,fly=n,unsit=force,sit=n,tplocal=n,tplm=n,tploc=n,tplure_sec=n,showself=n,sendgesture=n");

    // If I'm objectifying for an avatar, also add teleport exceptions and IM exceptions for them ahead of time.
    if(keyisavatar)
    {
        llOwnerSay("@tplure:" + (string)objectifier + "=add,accepttp:" + (string)objectifier + "=add");
        llOwnerSay("@startim:" + (string)objectifier + "=add,recvim:" + (string)objectifier + "=add,sendim:" + (string)objectifier + "=add");
    }

    // Apply the saved settings loaded from the server.
    applyIm();
    applyHearing();
    applySpeech();
    applyVision();
    applyDaze();
    applyCamera();
    applyInventory();
    applyWorld();

    // "leash" to the capturer.
    leash();

    // Get a URL to handle TP following in case of avatar.
    urlt = llRequestURL();

    // And finally, block movement and hide avatar.
    llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS);
}

applyIm()
{
    llOwnerSay("@sendim=y,startim=y,recvim=y");
    if(imRestrict > 0) llOwnerSay("@startim=n");
    if(imRestrict > 1) llOwnerSay("@sendim=n");
    if(imRestrict > 2) llOwnerSay("@recvim=n");
}

applyVision()
{
    llOwnerSay("@setsphere=y");
    float dist = 10.0;
    if(visionRestrict > 2) dist = 5.0;
    if(visionRestrict > 4) dist = 2.0;
    if(visionRestrict > 6) dist = 0.5;
    if(visionRestrict > 8) dist = 0.0;
    string color = "0/0/0";
    if(visionRestrict % 2 == 0) color = "1/1/1";
    if(visionRestrict > 0) llOwnerSay("@setsphere=n,setsphere_origin:1=force,setsphere_distmin:" + (string)(dist/4) + "=force,setsphere_valuemin:0=force,setsphere_distmax:" + (string)dist + "=force,setsphere_param:" + color + "/0=force");
}

applyHearing()
{
    llOwnerSay("@recvchat=y,recvemote=y,recvchat:" + (string)llGetOwnerKey(objectifier) + "=rem,recvemote:" + (string)llGetOwnerKey(objectifier) + "=rem");
    if(hearingRestrict == 3)     llOwnerSay("@recvchat=n,recvemote=n");
    else if(hearingRestrict > 0) llOwnerSay("@recvchat=n,recvemote=n,recvchat:" + (string)llGetOwnerKey(objectifier) + "=add,recvemote:" + (string)llGetOwnerKey(objectifier) + "=add");
}

applySpeech()
{
    llOwnerSay("@redirchat=y,redirchat:" + (string)GAZE_CHAT_CHANNEL + "=rem,redirchat:" + (string)DUMMY_CHANNEL + "=rem,redirchat:" + (string)GAZE_REN_CHANNEL + "=rem,rediremote=y,rediremote:" + (string)GAZE_CHAT_CHANNEL + "=rem,rediremote:" + (string)DUMMY_CHANNEL + "=rem,rediremote:" + (string)GAZE_REN_CHANNEL + "=rem");
    if(speechRestrict == 0) llOwnerSay("@redirchat=n,redirchat:" + (string)GAZE_REN_CHANNEL + "=add,rediremote=n,rediremote:" + (string)GAZE_REN_CHANNEL + "=add");
    if(speechRestrict == 1) llOwnerSay("@redirchat=n,redirchat:" + (string)GAZE_CHAT_CHANNEL + "=add,rediremote=n,rediremote:" + (string)GAZE_CHAT_CHANNEL + "=add");
    if(speechRestrict == 2) llOwnerSay("@redirchat=n,redirchat:" + (string)GAZE_CHAT_CHANNEL + "=add,rediremote=n,rediremote:" + (string)DUMMY_CHANNEL + "=add");
    if(speechRestrict == 3) llOwnerSay("@redirchat=n,redirchat:" + (string)DUMMY_CHANNEL + "=add,rediremote=n,rediremote:" + (string)DUMMY_CHANNEL + "=add");
}

applyDaze()
{
    if(dazeRestrict == 0) llOwnerSay("@shownames=y,shownametags=y,shownearby=y,showhovertextall=y,showworldmap=y,showminimap=y,showloc=y");
    if(dazeRestrict == 1) llOwnerSay("@shownames=n,shownametags=n,shownearby=n,showhovertextall=n,showworldmap=n,showminimap=n,showloc=n");
}

applyCamera()
{
    if(cameraRestrict == 0) llOwnerSay("@setcam_origindistmax:10=y");
    if(cameraRestrict == 1) llOwnerSay("@setcam_origindistmax:10=n");
}

applyInventory()
{
    if(inventoryRestrict == 0) llOwnerSay("@showinv=y");
    if(inventoryRestrict == 1) llOwnerSay("@showinv=n");
}

applyWorld()
{
    if(worldRestrict == 0) llOwnerSay("@touchall=y,edit=y,rez=y");
    if(worldRestrict == 1) llOwnerSay("@touchall=n,edit=n,rez=n");
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

leash()
{
    leashtarget = llList2Vector(llGetObjectDetails(objectifier, [OBJECT_POS]), 0);
    llTargetRemove(leashinghandle);
    llStopMoveToTarget();
    leashinghandle = llTarget(leashtarget, 5.0);
    if(leashtarget != ZERO_VECTOR) llMoveToTarget(leashtarget, 1.5);
}

default
{
    state_entry()
    {
        prefix = llToLower(llGetSubString(llGetUsername(llGetOwner()), 0, 1));
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
        llListen(BALL_CHANNEL, "", NULL_KEY, "");
        llListen(STRUGGLE_CHANNEL, "", NULL_KEY, "");
        llListen(GAZE_ECHO_CHANNEL, "", NULL_KEY, "");
        handle1 = llListen(GAZE_CHAT_CHANNEL, "", llGetOwner(), "");
        handle2 = llListen(GAZE_REN_CHANNEL, "", llGetOwner(), "");
        llListen(5, "", NULL_KEY, "");
        animation = "hide_a";
    }

    attach(key id)
    {
        llSetTimerEvent(0.0);
        struggleEvents = 0;
        struggleFailed = FALSE;
        llTargetRemove(leashinghandle);
        llStopMoveToTarget();
        objectifier = NULL_KEY;
    }

    changed(integer change)
    {
        if(change & (CHANGED_REGION | CHANGED_TELEPORT))
        {
            llSleep(0.5);
            die();
            llSleep(0.5);
            die();
            llSleep(0.5);
            die();
        }
        if(change & CHANGED_OWNER)
        {
            prefix = llToLower(llGetSubString(llGetUsername(llGetOwner()), 0, 1));
            llListenRemove(handle1);
            llListenRemove(handle2);
            handle1 = llListen(GAZE_CHAT_CHANNEL, "", llGetOwner(), "");
            handle2 = llListen(GAZE_REN_CHANNEL, "", llGetOwner(), "");
        }
    }

    run_time_permissions(integer perm)
    {
        // Let the IT slave know to turn off its garbler.
        llRegionSayTo(llGetOwner(), COMMAND_CHANNEL, "*onball " + (string)llGetKey());

        // Start the animation.
        llStartAnimation(animation);

        // Take controls.
        llTakeControls(CONTROL_FWD | CONTROL_BACK | CONTROL_LEFT | CONTROL_RIGHT | CONTROL_ROT_LEFT | CONTROL_ROT_RIGHT | CONTROL_UP | CONTROL_DOWN, TRUE, TRUE);

        // Struggle
        llRegionSayTo(objectifier, STRUGGLE_CHANNEL, "captured|" + (string)llGetOwner() + "|object");

        // Notify of menu.
        llSetObjectName("");
        llOwnerSay("You can restrict yourself further by clicking [secondlife:///app/chat/5/" + prefix + "menu here] or by typing /5" + prefix + "menu. Settings made will be saved and remembered for when you are captured by the same person.");
        llRegionSayTo(objectifier, 0, "You can edit the restrictions on your victim by clicking [secondlife:///app/chat/5/" + prefix + "menu here] or by typing /5" + prefix + "menu. Settings made will be saved and remembered for when you capture the same person.");

        // And start a timer loop.
        llSetTimerEvent(0.5);
    }

    control(key id, integer level, integer edge)
    {
        integer start = level & edge;
        if(start) struggleEvents++;
    }

    listen(integer c, string n, key id, string m)
    {
        if(c == GAZE_CHAT_CHANNEL)
        {
            if(keyisavatar == TRUE) return;
            llSetObjectName(objectprefix + name);
            if(llToLower(llStringTrim(m, STRING_TRIM)) == "/me" || startswith(m, "/me") == FALSE || contains(m, "\"") == TRUE) llOwnerSay(m);
            else llSay(0, m);
        }
        else if(c == GAZE_REN_CHANNEL)
        {
            llSetObjectName(objectprefix + name);
            llSay(0, m);
        }
        else if(c == GAZE_ECHO_CHANNEL)
        {
            if(llGetOwnerKey(id) != objectifier) return;
            if(hearingRestrict > 1) return;
            llSetObjectName(n);
            llOwnerSay(m);
        }
        else if(c == BALL_CHANNEL)
        {
            if(keyisavatar == FALSE || llGetOwnerKey(id) != objectifier) return;
            if(hearingRestrict == 3) return;
            llSetObjectName("Wearer's Thoughts");
            llOwnerSay(m);
        }
        else if(c == 5)
        {
            if(llGetOwnerKey(id) != objectifier && llGetOwner() != id) return;
            if(m == prefix + "menu") llMessageLinked(LINK_THIS, X_API_GIVE_MENU, "", llGetOwnerKey(id));
            else if(m == prefix + "invis")
            {
                if(animation == "hide_b")
                {
                    if(id == llGetOwner()) return;
                    llStopAnimation(animation);
                    animation = "hide_a";
                    llStartAnimation(animation);
                    llSetObjectName("");
                    llOwnerSay("secondlife:///app/agent/" + (string)llGetOwner() + "/about will now be rendered visible again, but it will require a relog.");
                    llRegionSayTo(objectifier, 0, "secondlife:///app/agent/" + (string)llGetOwner() + "/about will now be rendered visible again, but it will require a relog.");
                    llMessageLinked(LINK_THIS, X_API_SETTINGS_SAVE, restrictionString(), NULL_KEY);
                }
                else
                {
                    llStopAnimation(animation);
                    animation = "hide_b";
                    llStartAnimation(animation);
                    llSetObjectName("");
                    llOwnerSay("secondlife:///app/agent/" + (string)llGetOwner() + "/about is now rendered truly invisible, nameplate and all.");
                    llRegionSayTo(objectifier, 0, "secondlife:///app/agent/" + (string)llGetOwner() + "/about is now rendered truly invisible, nameplate and all.");
                    llMessageLinked(LINK_THIS, X_API_SETTINGS_SAVE, restrictionString(), NULL_KEY);
                }
            }
            else if(startswith(m, prefix + "name"))
            {
                if(id == llGetOwner()) return;
                m = llDeleteSubString(m, 0, llStringLength(prefix + "name"));
                name = m;
                llSetObjectName("");
                llOwnerSay("secondlife:///app/agent/" + (string)llGetOwner() + "/about is now " + objectprefix + m + ".");
                llRegionSayTo(objectifier, 0, "secondlife:///app/agent/" + (string)llGetOwner() + "/about is now " + objectprefix + m + ".");
                llRegionSayTo(objectifier, MANTRA_CHANNEL, "objrename " + m);
            }
            else if(startswith(m, prefix + "im"))
            {
                if(id == llGetOwner() && imRestrict > (integer)llGetSubString(m, -1, -1)) return;
                imRestrict = (integer)llGetSubString(m, -1, -1);
                if(imRestrict < 0) imRestrict = 0;
                if(imRestrict > 3) imRestrict = 3;
                llSetObjectName("");
                llOwnerSay("secondlife:///app/agent/" + (string)llGetOwner() + "/about's IM restrictions set to level " + (string)imRestrict + ".");
                llRegionSayTo(objectifier, 0, "secondlife:///app/agent/" + (string)llGetOwner() + "/about's IM restrictions set to level " + (string)imRestrict + ".");
                applyIm();
                llMessageLinked(LINK_THIS, X_API_SETTINGS_SAVE, restrictionString(), NULL_KEY);
            }
            else if(startswith(m, prefix + "vi"))
            {
                if(id == llGetOwner() && visionRestrict > (integer)llGetSubString(m, -1, -1)) return;
                visionRestrict = (integer)llGetSubString(m, -1, -1);
                if(visionRestrict < 0) visionRestrict = 0;
                if(visionRestrict > 9) visionRestrict = 9;
                llSetObjectName("");
                llOwnerSay("secondlife:///app/agent/" + (string)llGetOwner() + "/about's Vision restrictions set to level " + (string)visionRestrict + ".");
                llRegionSayTo(objectifier, 0, "secondlife:///app/agent/" + (string)llGetOwner() + "/about's Vision restrictions set to level " + (string)visionRestrict + ".");
                applyVision();
                llMessageLinked(LINK_THIS, X_API_SETTINGS_SAVE, restrictionString(), NULL_KEY);
            }
            else if(startswith(m, prefix + "he"))
            {
                if(id == llGetOwner() && hearingRestrict > (integer)llGetSubString(m, -1, -1)) return;
                hearingRestrict = (integer)llGetSubString(m, -1, -1);
                if(hearingRestrict < 0) hearingRestrict = 0;
                if(hearingRestrict > 3) hearingRestrict = 3;
                llSetObjectName("");
                llOwnerSay("secondlife:///app/agent/" + (string)llGetOwner() + "/about's Hearing restrictions set to level " + (string)hearingRestrict + ".");
                llRegionSayTo(objectifier, 0, "secondlife:///app/agent/" + (string)llGetOwner() + "/about's Hearing restrictions set to level " + (string)hearingRestrict + ".");
                applyHearing();
                llMessageLinked(LINK_THIS, X_API_SETTINGS_SAVE, restrictionString(), NULL_KEY);
            }
            else if(startswith(m, prefix + "sp"))
            {
                if(id == llGetOwner() && speechRestrict > (integer)llGetSubString(m, -1, -1)) return;
                speechRestrict = (integer)llGetSubString(m, -1, -1);
                if(speechRestrict < 0) speechRestrict = 0;
                if(speechRestrict > 2) speechRestrict = 2;
                llSetObjectName("");
                llOwnerSay("secondlife:///app/agent/" + (string)llGetOwner() + "/about's Speech restrictions set to level " + (string)speechRestrict + ".");
                llRegionSayTo(objectifier, 0, "secondlife:///app/agent/" + (string)llGetOwner() + "/about's Speech restrictions set to level " + (string)speechRestrict + ".");
                applySpeech();
                llMessageLinked(LINK_THIS, X_API_SETTINGS_SAVE, restrictionString(), NULL_KEY);
            }
            else if(startswith(m, prefix + "da"))
            {
                if(id == llGetOwner() && dazeRestrict > (integer)llGetSubString(m, -1, -1)) return;
                dazeRestrict = (integer)llGetSubString(m, -1, -1);
                if(dazeRestrict < 0) dazeRestrict = 0;
                if(dazeRestrict > 1) dazeRestrict = 1;
                llSetObjectName("");
                llOwnerSay("secondlife:///app/agent/" + (string)llGetOwner() + "/about's Daze restrictions set to level " + (string)dazeRestrict + ".");
                llRegionSayTo(objectifier, 0, "secondlife:///app/agent/" + (string)llGetOwner() + "/about's Daze restrictions set to level " + (string)dazeRestrict + ".");
                applyDaze();
                llMessageLinked(LINK_THIS, X_API_SETTINGS_SAVE, restrictionString(), NULL_KEY);
            }
            else if(startswith(m, prefix + "ca"))
            {
                if(id == llGetOwner() && cameraRestrict > (integer)llGetSubString(m, -1, -1)) return;
                cameraRestrict = (integer)llGetSubString(m, -1, -1);
                if(cameraRestrict < 0) cameraRestrict = 0;
                if(cameraRestrict > 1) cameraRestrict = 1;
                llSetObjectName("");
                llOwnerSay("secondlife:///app/agent/" + (string)llGetOwner() + "/about's Camera restrictions set to level " + (string)cameraRestrict + ".");
                llRegionSayTo(objectifier, 0, "secondlife:///app/agent/" + (string)llGetOwner() + "/about's Camera restrictions set to level " + (string)cameraRestrict + ".");
                applyCamera();
                llMessageLinked(LINK_THIS, X_API_SETTINGS_SAVE, restrictionString(), NULL_KEY);
            }
            else if(startswith(m, prefix + "in"))
            {
                if(id == llGetOwner() && inventoryRestrict > (integer)llGetSubString(m, -1, -1)) return;
                inventoryRestrict = (integer)llGetSubString(m, -1, -1);
                if(inventoryRestrict < 0) inventoryRestrict = 0;
                if(inventoryRestrict > 1) inventoryRestrict = 1;
                llSetObjectName("");
                llOwnerSay("secondlife:///app/agent/" + (string)llGetOwner() + "/about's Inventory restrictions set to level " + (string)inventoryRestrict + ".");
                llRegionSayTo(objectifier, 0, "secondlife:///app/agent/" + (string)llGetOwner() + "/about's Inventory restrictions set to level " + (string)inventoryRestrict + ".");
                applyInventory();
                llMessageLinked(LINK_THIS, X_API_SETTINGS_SAVE, restrictionString(), NULL_KEY);
            }
            else if(startswith(m, prefix + "wo"))
            {
                if(id == llGetOwner() && worldRestrict > (integer)llGetSubString(m, -1, -1)) return;
                worldRestrict = (integer)llGetSubString(m, -1, -1);
                if(worldRestrict < 0) worldRestrict = 0;
                if(worldRestrict > 1) worldRestrict = 1;
                llSetObjectName("");
                llOwnerSay("secondlife:///app/agent/" + (string)llGetOwner() + "/about's World restrictions set to level " + (string)worldRestrict + ".");
                llRegionSayTo(objectifier, 0, "secondlife:///app/agent/" + (string)llGetOwner() + "/about's World restrictions set to level " + (string)worldRestrict + ".");
                applyWorld();
                llMessageLinked(LINK_THIS, X_API_SETTINGS_SAVE, restrictionString(), NULL_KEY);
            }
        }
        else if(c == MANTRA_CHANNEL)
        {
            if(m == "unsit")
            {
                die();
            }
            else if(startswith(m, "sit"))
            {
                list params = llParseString2List(llDeleteSubString(m, 0, llStringLength("sit")), ["|||"], []);

                // The objectifier is an avatar if the object sending the message has an attachment point.
                // Otherwise it's IT furniture.
                keyisavatar = llList2Integer(llGetObjectDetails(id, [OBJECT_ATTACHED_POINT]), 0) != 0;

                // If the objectifier is an avatar, we want the avatar, not the hud. Otherwise the object is fine.
                if(keyisavatar) objectifier = llGetOwnerKey(id);
                else            objectifier = id;

                // Name and prefix of what we're becoming.
                name = llList2String(params, 1);
                objectprefix = llList2String(params, 2);
                if(objectprefix == "NULL") objectprefix = "";

                // Let the other scripts know that we're busy.
                llMessageLinked(LINK_SET, X_API_SET_OBJECTIFIER, "", llGetOwnerKey(id));

                // And do the capture.
                capture();
            }
            else if(startswith(m, "puton"))
            {
                list params = llParseString2List(llDeleteSubString(m, 0, llStringLength("puton")), ["|||"], []);
                llOwnerSay("@tplure:" + (string)llGetOwnerKey(objectifier) + "=rem,accepttp:" + (string)llGetOwnerKey(objectifier) + "=rem");
                llOwnerSay("@startim:" + (string)objectifier + "=rem,recvim:" + (string)objectifier + "=rem,sendim:" + (string)objectifier + "=rem");
                objectifier = (key)llList2String(params, 0);
                llOwnerSay("@tplure:" + (string)llGetOwnerKey(objectifier) + "=add,accepttp:" + (string)llGetOwnerKey(objectifier) + "=add");
                llOwnerSay("@startim:" + (string)objectifier + "=add,recvim:" + (string)objectifier + "=add,sendim:" + (string)objectifier + "=add");
                name = llList2String(params, 1);
                objectprefix = "";
                llRegionSayTo(objectifier, MANTRA_CHANNEL, "puton " + (string)llAvatarOnSitTarget() + "|||" + name + "|||" + url);
                keyisavatar = TRUE;
                leash();
                llMessageLinked(LINK_SET, X_API_SET_OBJECTIFIER, "", objectifier);
            }
            else if(startswith(m, "putdown"))
            {
                list params = llParseString2List(llDeleteSubString(m, 0, llStringLength("putdown")), ["|||"], []);
                llOwnerSay("@tplure:" + (string)llGetOwnerKey(objectifier) + "=rem,accepttp:" + (string)llGetOwnerKey(objectifier) + "=rem");
                llOwnerSay("@startim:" + (string)objectifier + "=rem,recvim:" + (string)objectifier + "=rem,sendim:" + (string)objectifier + "=rem");
                objectifier = (key)llList2String(params, 0);
                llOwnerSay("@tplure:" + (string)llGetOwnerKey(objectifier) + "=add,accepttp:" + (string)llGetOwnerKey(objectifier) + "=add");
                llOwnerSay("@startim:" + (string)objectifier + "=add,recvim:" + (string)objectifier + "=add,sendim:" + (string)objectifier + "=add");
                name = llList2String(params, 1);
                objectprefix = "";
                llRegionSayTo(objectifier, MANTRA_CHANNEL, "objurl " + url);
                keyisavatar = FALSE;
                leash();
                llMessageLinked(LINK_SET, X_API_SET_OBJECTIFIER, "", objectifier);
            }
            else if(startswith(m, "prefix"))
            {
                m = llDeleteSubString(m, 0, llStringLength("prefix"));
                objectprefix = m;
            }
        }
        else if(c == STRUGGLE_CHANNEL)
        {
            if((keyisavatar == TRUE && llGetOwnerKey(id) != objectifier) || (keyisavatar == FALSE && id != objectifier)) return;
            if(startswith(m, "struggle_fail"))
            {
                list params = llParseString2List(m, ["|"], []);
                m = llList2String(llParseString2List(m, ["|"], []), -1);
                if(llGetListLength(params) == 2 || (llGetListLength(params) == 3 && (key)llList2String(params, 1) == llGetOwner()))
                {
                    llSetObjectName("");
                    llOwnerSay(m);
                    llReleaseControls();
                    struggleFailed = TRUE;
                }
            }
            else if(startswith(m, "struggle_success"))
            {
                list params = llParseString2List(m, ["|"], []);
                m = llList2String(llParseString2List(m, ["|"], []), -1);
                if(llGetListLength(params) == 2 || (llGetListLength(params) == 3 && (key)llList2String(params, 1) == llGetOwner()))
                {
                    llSetObjectName("");
                    llOwnerSay(m);
                    llSetRegionPos(llList2Vector(llGetObjectDetails(objectifier, [OBJECT_POS]), 0));
                    if(animation == "hide_b") llOwnerSay("Note: The animation currently making you invisible can be a little tricky to get rid of. If you remain invisible after you are freed, put on something and then take it off again. If this doesn't help, relog.");
                    die();
                }
            }
        }
    }

    at_target(integer num, vector tar, vector me)
    {
        llStopMoveToTarget();
        llTargetRemove(leashinghandle);
        leashtarget = llList2Vector(llGetObjectDetails(objectifier, [OBJECT_POS]), 0);
        leashinghandle = llTarget(leashtarget, 5.0);
    }

    not_at_target()
    {
        if(objectifier)
        {
            vector newpos = llList2Vector(llGetObjectDetails(objectifier, [OBJECT_POS]), 0);
            if(leashtarget != newpos)
            {
                llTargetRemove(leashinghandle);
                leashtarget = newpos;
                leashinghandle = llTarget(leashtarget, 5.0);
            }
            if(leashtarget != ZERO_VECTOR)
            {
                llMoveToTarget(leashtarget, 1.5);
            }
            else
            {
                llStopMoveToTarget();
                llTargetRemove(leashinghandle);
            }
        }
        else
        {
            llStopMoveToTarget();
            llTargetRemove(leashinghandle);
        }
    }

    timer()
    {
        llRegionSayTo(objectifier, MANTRA_CHANNEL, "objurl " + url);

        if(struggleEvents > 0 && struggleFailed == FALSE)
        {
            llRegionSayTo(objectifier, STRUGGLE_CHANNEL, "struggle_count|" + (string)llGetOwner() + "|" + (string)struggleEvents);
            struggleEvents = 0;
        }

        if((keyisavatar == TRUE && llGetAgentSize(objectifier) == ZERO_VECTOR) || (keyisavatar == FALSE && llList2Vector(llGetObjectDetails(objectifier, [OBJECT_POS]), 0) == ZERO_VECTOR))
        {
            if(firstattempt)
            {
                firstattempt = FALSE;
                llSetTimerEvent(30.0);
                return;
            }
            else
            {
                die();
                return;
            }
        }
        else
        {
            firstattempt = TRUE;
        }

        leashtarget = llList2Vector(llGetObjectDetails(objectifier, [OBJECT_POS]), 0);
        if(leashtarget == ZERO_VECTOR) leashtarget = llList2Vector(llGetObjectDetails(llGetOwnerKey(objectifier), [OBJECT_POS]), 0);
        if(llVecDist(llGetPos(), leashtarget) > 60.0)
        {
            if(firstoutrange)
            {
                firstoutrange = FALSE;
                llStopMoveToTarget();
                llTargetRemove(leashinghandle);
                llSetTimerEvent(10.0);
                return;
            }
            else
            {
                die();
                return;
            }
        }
        else
        {
            firstoutrange = TRUE;
        }
        llTargetRemove(leashinghandle);
        leashtarget = llList2Vector(llGetObjectDetails(objectifier, [OBJECT_POS]), 0);
        if(leashtarget == ZERO_VECTOR) leashtarget = llList2Vector(llGetObjectDetails(llGetOwnerKey(objectifier), [OBJECT_POS]), 0);
        leashinghandle = llTarget(leashtarget, 5.0);
        if(leashtarget != ZERO_VECTOR) llMoveToTarget(leashtarget, 1.5);
        if(cameraRestrict != 0)
        {
            list uuids = llGetAttachedList(objectifier);
            integer n = llGetListLength(uuids);
            list data = [];
            while(~--n)
            {
                data = llGetObjectDetails(llList2Key(uuids, n), [OBJECT_NAME, OBJECT_DESC]);
                if(llToLower((string)data[0]) == llToLower(name) || llToLower((string)data[0]) == llToLower(objectprefix + name))
                {
                    llOwnerSay("@" + (string)data[1]);
                    return;
                }
            }
            n = llGetListLength(uuids);
            while(~--n)
            {
                data = llGetObjectDetails(llList2Key(uuids, n), [OBJECT_NAME, OBJECT_DESC]);
                if(startswith((string)data[0], "Intrusive Thoughts Focus Target"))
                {
                    llOwnerSay("@" + (string)data[1]);
                    return;
                }
            }
            llOwnerSay("@setcam_focus:" + (string)objectifier + ";;=force");
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
                llRegionSayTo(objectifier, MANTRA_CHANNEL, "objurl " + url);
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
                llOwnerSay("@clear,tpto:" + body + "=force");
            }
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
            if(imRestrict > 0) llOwnerSay("secondlife:///app/agent/" + (string)llGetOwner() + "/about's IM restrictions set to level " + (string)imRestrict + ".");
            if(imRestrict > 0) llRegionSayTo(objectifier, 0, "secondlife:///app/agent/" + (string)llGetOwner() + "/about's IM restrictions set to level " + (string)imRestrict + ".");
            if(visionRestrict > 0) llOwnerSay("secondlife:///app/agent/" + (string)llGetOwner() + "/about's Vision restrictions set to level " + (string)visionRestrict + ".");
            if(visionRestrict > 0) llRegionSayTo(objectifier, 0, "secondlife:///app/agent/" + (string)llGetOwner() + "/about's Vision restrictions set to level " + (string)visionRestrict + ".");
            if(hearingRestrict > 0) llOwnerSay("secondlife:///app/agent/" + (string)llGetOwner() + "/about's Hearing restrictions set to level " + (string)hearingRestrict + ".");
            if(hearingRestrict > 0) llRegionSayTo(objectifier, 0, "secondlife:///app/agent/" + (string)llGetOwner() + "/about's Hearing restrictions set to level " + (string)hearingRestrict + ".");
            if(speechRestrict != 1) llOwnerSay("secondlife:///app/agent/" + (string)llGetOwner() + "/about's Speech restrictions set to level " + (string)speechRestrict + ".");
            if(speechRestrict != 1) llRegionSayTo(objectifier, 0, "secondlife:///app/agent/" + (string)llGetOwner() + "/about's Speech restrictions set to level " + (string)speechRestrict + ".");
            if(dazeRestrict != 1) llOwnerSay("secondlife:///app/agent/" + (string)llGetOwner() + "/about's Daze restrictions set to level " + (string)dazeRestrict + ".");
            if(dazeRestrict != 1) llRegionSayTo(objectifier, 0, "secondlife:///app/agent/" + (string)llGetOwner() + "/about's Daze restrictions set to level " + (string)dazeRestrict + ".");
            if(cameraRestrict != 1) llOwnerSay("secondlife:///app/agent/" + (string)llGetOwner() + "/about's Camera restrictions set to level " + (string)cameraRestrict + ".");
            if(cameraRestrict != 1) llRegionSayTo(objectifier, 0, "secondlife:///app/agent/" + (string)llGetOwner() + "/about's Camera restrictions set to level " + (string)cameraRestrict + ".");
            if(inventoryRestrict != 1) llOwnerSay("secondlife:///app/agent/" + (string)llGetOwner() + "/about's Inventory restrictions set to level " + (string)inventoryRestrict + ".");
            if(inventoryRestrict != 1) llRegionSayTo(objectifier, 0, "secondlife:///app/agent/" + (string)llGetOwner() + "/about's Inventory restrictions set to level " + (string)inventoryRestrict + ".");
            if(worldRestrict != 1) llOwnerSay("secondlife:///app/agent/" + (string)llGetOwner() + "/about's World restrictions set to level " + (string)worldRestrict + ".");
            if(worldRestrict != 1) llRegionSayTo(objectifier, 0, "secondlife:///app/agent/" + (string)llGetOwner() + "/about's World restrictions set to level " + (string)worldRestrict + ".");
            if(isHidden && animation != "hide_b")
            {
                llStopAnimation(animation);
                animation = "hide_b";
                llStartAnimation(animation);
                llOwnerSay("secondlife:///app/agent/" + (string)llGetOwner() + "/about is now rendered truly invisible, nameplate and all.");
                llRegionSayTo(objectifier, 0, "secondlife:///app/agent/" + (string)llGetOwner() + "/about is now rendered truly invisible, nameplate and all.");
            }
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
