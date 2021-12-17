#include <IT/globals.lsl>
key rezzer;
key urlt;
string url = "null";
string prefix = "??";
string anim = "";
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
integer timerctr = 0;

list whitelist = ["boot",    "top",      "bangle", "armband", "bracer", "thigh",  "ring", 
                  "suit",    "lingerie", "bra",    "shoe",    "glove",  "sock",   "stocking", 
                  "leotard", "tight",    "skirt",  "warmers", "robe",   "kimono", "pant",
                  "sandal",  "jean",     "string", "bikini",  "heel",   "dress",  "sarong",
                  "glasses", "corset",   "tube",   "dress",   "legging"];

// 0 = Nothing extra.
// 1 = Cannot open IM sessions.
// 2 = Cannot send IMs.
// 3 = Cannot send or receive IMs.
integer imRestrict = 0;

// 0 = No restrictions.
// 1 = No longer capable of speech.
// 2 = No longer capable of speech or emoting.
integer speechRestrict = 0;

// 0 = No restrictions.
// 1 = Location and people hidden.
integer dazeRestrict = 1;

// 0 = No restrictions.
// 1 = Camera restricted to inside stomach.
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
    llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES);
    llSetAlpha(0.0, ALL_SIDES);
    llSetPrimitiveParams([PRIM_TEMP_ON_REZ, TRUE]);
    llDie();
    while(TRUE) llSleep(60.0);
}

applyIm()
{
    llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), RLVRC, "restrict," + (string)llAvatarOnLinkSitTarget(volumelink) + ",@sendim=y|@startim=y|@recvim=y");
    if(imRestrict > 0) llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), RLVRC, "restrict," + (string)llAvatarOnLinkSitTarget(volumelink) + ",@startim=n");
    if(imRestrict > 1) llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), RLVRC, "restrict," + (string)llAvatarOnLinkSitTarget(volumelink) + ",@sendim=n");
    if(imRestrict > 2) llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), RLVRC, "restrict," + (string)llAvatarOnLinkSitTarget(volumelink) + ",@recvim=n");
}

applySpeech()
{
    llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), RLVRC, "restrict," + (string)llAvatarOnLinkSitTarget(volumelink) + ",@redirchat=y|@redirchat:" + (string)GAZE_CHAT_CHANNEL + "=rem|@redirchat:" + (string)DUMMY_CHANNEL + "=rem|@rediremote=y|@rediremote:" + (string)GAZE_CHAT_CHANNEL + "=rem|@rediremote:" + (string)DUMMY_CHANNEL + "=rem");
    if(speechRestrict == 0) llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), RLVRC, "restrict," + (string)llAvatarOnLinkSitTarget(volumelink) + ",@redirchat=n|@redirchat:" + (string)GAZE_CHAT_CHANNEL + "=add|@rediremote=n|@rediremote:" + (string)GAZE_CHAT_CHANNEL + "=add");
    if(speechRestrict == 1) llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), RLVRC, "restrict," + (string)llAvatarOnLinkSitTarget(volumelink) + ",@redirchat=n|@redirchat:" + (string)DUMMY_CHANNEL + "=add|@rediremote=n|@rediremote:" + (string)GAZE_CHAT_CHANNEL + "=add");
    if(speechRestrict == 2) llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), RLVRC, "restrict," + (string)llAvatarOnLinkSitTarget(volumelink) + ",@redirchat=n|@redirchat:" + (string)DUMMY_CHANNEL + "=add|@rediremote=n|@rediremote:" + (string)DUMMY_CHANNEL + "=add");
}

applyDaze()
{
    if(dazeRestrict == 0) llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), RLVRC, "restrict," + (string)llAvatarOnLinkSitTarget(volumelink) + ",@shownames_sec=y|@shownametags=y|@shownearby=y|@showhovertextall=y|@showworldmap=y|@showminimap=y|@showloc=y");
    if(dazeRestrict == 1) llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), RLVRC, "restrict," + (string)llAvatarOnLinkSitTarget(volumelink) + ",@shownames_sec=n|@shownametags=n|@shownearby=n|@showhovertextall=n|@showworldmap=n|@showminimap=n|@showloc=n");
}

applyCamera()
{
    if(cameraRestrict == 0) llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), RLVRC, "restrict," + (string)llAvatarOnLinkSitTarget(volumelink) + ",@setcam_focus:" + (string)rezzer + ";0;0/1/0=force|@setoverlay=y");
    if(cameraRestrict == 1) llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), RLVRC, "restrict," + (string)llAvatarOnLinkSitTarget(volumelink) + ",@setcam_focus:" + (string)focuskey + ";0;0/1/0=force|@setoverlay=n|@setoverlay_texture:5ace8e33-db4a-3596-3dd2-98b82516b5d1=force");
    if(cameraRestrict == 2) llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), RLVRC, "restrict," + (string)llAvatarOnLinkSitTarget(volumelink) + ",@setcam_focus:" + (string)llGetOwner() + ";;=force|@setoverlay=y");
}

applyInventory()
{
    if(inventoryRestrict == 0) llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), RLVRC, "restrict," + (string)llAvatarOnLinkSitTarget(volumelink) + ",@showinv=y");
    if(inventoryRestrict == 1) llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), RLVRC, "restrict," + (string)llAvatarOnLinkSitTarget(volumelink) + ",@showinv=n");
}

applyWorld()
{
    if(worldRestrict == 0) llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), RLVRC, "restrict," + (string)llAvatarOnLinkSitTarget(volumelink) + ",@interact=y");
    if(worldRestrict == 1) llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), RLVRC, "restrict," + (string)llAvatarOnLinkSitTarget(volumelink) + ",@interact=n");
}

string restrictionString()
{
    return (string)imRestrict + "," + 
           (string)speechRestrict + "," + 
           (string)dazeRestrict + "," + 
           (string)cameraRestrict + "," + 
           (string)inventoryRestrict + "," + 
           (string)worldRestrict;
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
                llSetObjectName("The Acid");
                llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), 0, "/me in your predator's stomach has dissolved your '" + name + "'.");
                return;
            }
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
        llListen(5, "", NULL_KEY, "");
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
                prefix = llToLower(llGetSubString(llGetUsername(firstavatar), 0, 1));
                llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), RLVRC, "restrict," + (string)llAvatarOnLinkSitTarget(volumelink) + ",@tplocal=n|@tplm=n|@tploc=n|@tplure_sec=n|@sendgesture=n|@startim:" + (string)llGetOwnerKey(rezzer) + "=add|@recvim:" + (string)llGetOwnerKey(rezzer) + "=add");
                applyIm();
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
        llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), COMMAND_CHANNEL, "*onball " + (string)llGetKey());
        llStartAnimation("sit");
        anim = "sit";
        llSetObjectName("");
        llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), 0, "You can restrict yourself further by clicking [secondlife:///app/chat/5/" + prefix + "menu here] or by typing /5" + prefix + "menu. Settings made will be saved and remembered for when you are captured by the same person.");
        llRegionSayTo(rezzer, 0, "You can edit the restrictions on your victim by clicking [secondlife:///app/chat/5/" + prefix + "menu here] or by typing /5" + prefix + "menu. Settings made will be saved and remembered for when you capture the same person.");
        llTakeControls(CONTROL_FWD | CONTROL_BACK | CONTROL_LEFT | CONTROL_RIGHT | CONTROL_ROT_LEFT | CONTROL_ROT_RIGHT | CONTROL_UP | CONTROL_DOWN, TRUE, TRUE);
        llResetTime();
        llSetTimerEvent(0.5);
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
            llSetObjectName("Predator's Thoughts");
            llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), 0, m);
        }
        else if(c == 5)
        {
            if(id != firstavatar && llGetOwner() != llGetOwnerKey(id)) return;
            if(m == prefix + "menu") llMessageLinked(LINK_THIS, X_API_GIVE_MENU, "", llGetOwnerKey(id));
            else if(startswith(m, prefix + "im"))
            {
                if(id == firstavatar && imRestrict > (integer)llGetSubString(m, -1, -1)) return;
                imRestrict = (integer)llGetSubString(m, -1, -1);
                if(imRestrict < 0) imRestrict = 0;
                if(imRestrict > 3) imRestrict = 3;
                llSetObjectName("");
                llOwnerSay("secondlife:///app/agent/" + (string)firstavatar + "/about's IM restrictions set to level " + (string)imRestrict + ".");
                llRegionSayTo(firstavatar, 0, "secondlife:///app/agent/" + (string)firstavatar + "/about's IM restrictions set to level " + (string)imRestrict + ".");
                applyIm();
                llMessageLinked(LINK_THIS, X_API_SETTINGS_SAVE, restrictionString(), NULL_KEY);
            }
            else if(startswith(m, prefix + "sp"))
            {
                if(id == firstavatar && speechRestrict > (integer)llGetSubString(m, -1, -1)) return;
                speechRestrict = (integer)llGetSubString(m, -1, -1);
                if(speechRestrict < 0) speechRestrict = 0;
                if(speechRestrict > 2) speechRestrict = 2;
                llSetObjectName("");
                llOwnerSay("secondlife:///app/agent/" + (string)firstavatar + "/about's Speech restrictions set to level " + (string)speechRestrict + ".");
                llRegionSayTo(firstavatar, 0, "secondlife:///app/agent/" + (string)firstavatar + "/about's Speech restrictions set to level " + (string)speechRestrict + ".");
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
                llOwnerSay("secondlife:///app/agent/" + (string)firstavatar + "/about's Daze restrictions set to level " + (string)dazeRestrict + ".");
                llRegionSayTo(firstavatar, 0, "secondlife:///app/agent/" + (string)firstavatar + "/about's Daze restrictions set to level " + (string)dazeRestrict + ".");
                applyDaze();
                llMessageLinked(LINK_THIS, X_API_SETTINGS_SAVE, restrictionString(), NULL_KEY);
            }
            else if(startswith(m, prefix + "ca"))
            {
                cameraRestrict = (integer)llGetSubString(m, -1, -1);
                if(cameraRestrict < 0) cameraRestrict = 0;
                if(cameraRestrict > 2) cameraRestrict = 2;
                llSetObjectName("");
                llOwnerSay("secondlife:///app/agent/" + (string)firstavatar + "/about's Camera restrictions set to level " + (string)cameraRestrict + ".");
                llRegionSayTo(firstavatar, 0, "secondlife:///app/agent/" + (string)firstavatar + "/about's Camera restrictions set to level " + (string)cameraRestrict + ".");
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
                llOwnerSay("secondlife:///app/agent/" + (string)firstavatar + "/about's Inventory restrictions set to level " + (string)inventoryRestrict + ".");
                llRegionSayTo(firstavatar, 0, "secondlife:///app/agent/" + (string)firstavatar + "/about's Inventory restrictions set to level " + (string)inventoryRestrict + ".");
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
                llOwnerSay("secondlife:///app/agent/" + (string)firstavatar + "/about's World restrictions set to level " + (string)worldRestrict + ".");
                llRegionSayTo(firstavatar, 0, "secondlife:///app/agent/" + (string)firstavatar + "/about's World restrictions set to level " + (string)worldRestrict + ".");
                applyWorld();
                llMessageLinked(LINK_THIS, X_API_SETTINGS_SAVE, restrictionString(), NULL_KEY);
            }
            else if(startswith(m, prefix + "play"))
            {
                m = llDeleteSubString(m, 0, llStringLength(prefix + "play"));
                if(llGetInventoryType(m) == INVENTORY_ANIMATION && anim != m)
                {
                    llOwnerSay("secondlife:///app/agent/" + (string)firstavatar + "/about's animation set to " + m + ".");
                    llStopAnimation(anim);
                    llStartAnimation(m);
                }
            }
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
                llRegionSayTo(firstavatar, RLVRC, "cv," + (string)firstavatar + ",@sit:" + (string)llGetKey() + "=force|@unsit=n");
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
                if(dissolved) return;
                llRegionSayTo(rezzer, STRUGGLE_CHANNEL, "acid_dissolve|" + (string)firstavatar);
                llStopAnimation("sit");
                llStartAnimation("digest");
                anim = "digest";
                dissolved = TRUE;
                llSetObjectName("The Acid");
                llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), 0, "/me in your predator's stomach has completely dissolved you.");
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

            if(timerctr % 10 == 0)
            {
                llRegionSayTo(rezzer, MANTRA_CHANNEL, "objurl " + url);
                if(cameraRestrict == 1) llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), RLVRC, "focus," + (string)llAvatarOnLinkSitTarget(volumelink) + ",@setcam_focus:" + (string)focuskey + ";0;0/1/0=force");
                if(cameraRestrict == 2) llRegionSayTo(llAvatarOnLinkSitTarget(volumelink), RLVRC, "focus," + (string)llAvatarOnLinkSitTarget(volumelink) + ",@setcam_focus:" + (string)llGetOwner() + ";;=force");
            }
            timerctr++;
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

    link_message(integer sender_num, integer num, string str, key id )
    {
        if(num == X_API_SETTINGS_LOAD)
        {
            list settings = llParseString2List(str, [","], []);
            imRestrict = (integer)llList2String(settings, 0);
            speechRestrict = (integer)llList2String(settings, 1);
            dazeRestrict = (integer)llList2String(settings, 2);
            cameraRestrict = (integer)llList2String(settings, 3);
            inventoryRestrict = (integer)llList2String(settings, 4);
            worldRestrict = (integer)llList2String(settings, 5);
            llSetObjectName("");
            if(imRestrict > 0) llOwnerSay("secondlife:///app/agent/" + (string)firstavatar + "/about's IM restrictions set to level " + (string)imRestrict + ".");
            if(imRestrict > 0) llRegionSayTo(firstavatar, 0, "secondlife:///app/agent/" + (string)firstavatar + "/about's IM restrictions set to level " + (string)imRestrict + ".");
            if(speechRestrict > 0) llOwnerSay("secondlife:///app/agent/" + (string)firstavatar + "/about's Speech restrictions set to level " + (string)speechRestrict + ".");
            if(speechRestrict > 0) llRegionSayTo(firstavatar, 0, "secondlife:///app/agent/" + (string)firstavatar + "/about's Speech restrictions set to level " + (string)speechRestrict + ".");
            if(dazeRestrict != 1) llOwnerSay("secondlife:///app/agent/" + (string)firstavatar + "/about's Daze restrictions set to level " + (string)dazeRestrict + ".");
            if(dazeRestrict != 1) llRegionSayTo(firstavatar, 0, "secondlife:///app/agent/" + (string)firstavatar + "/about's Daze restrictions set to level " + (string)dazeRestrict + ".");
            if(cameraRestrict != 1) llOwnerSay("secondlife:///app/agent/" + (string)firstavatar + "/about's Camera restrictions set to level " + (string)cameraRestrict + ".");
            if(cameraRestrict != 1) llRegionSayTo(firstavatar, 0, "secondlife:///app/agent/" + (string)firstavatar + "/about's Camera restrictions set to level " + (string)cameraRestrict + ".");
            if(inventoryRestrict != 1) llOwnerSay("secondlife:///app/agent/" + (string)firstavatar + "/about's Inventory restrictions set to level " + (string)inventoryRestrict + ".");
            if(inventoryRestrict != 1) llRegionSayTo(firstavatar, 0, "secondlife:///app/agent/" + (string)firstavatar + "/about's Inventory restrictions set to level " + (string)inventoryRestrict + ".");
            if(worldRestrict != 1) llOwnerSay("secondlife:///app/agent/" + (string)firstavatar + "/about's World restrictions set to level " + (string)worldRestrict + ".");
            if(worldRestrict != 1) llRegionSayTo(firstavatar, 0, "secondlife:///app/agent/" + (string)firstavatar + "/about's World restrictions set to level " + (string)worldRestrict + ".");
            applyIm();
            applySpeech();
            applyDaze();
            applyCamera();
            applyInventory();
            applyWorld();
        }
    }
}