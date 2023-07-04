#include <IT/globals.lsl>
#define IMPULSE 1.6
string animation = "hide_a";
key urlt = NULL_KEY;
key controller = NULL_KEY;
key objectifier = NULL_KEY;
key primary = NULL_KEY;
string url = "null";
string name = "";
string objectprefix = "";
integer waitingstate = 0;
integer keyisavatar = FALSE;
string prefix = "??";
integer firstattempt = TRUE;
integer firstoutrange = TRUE;
integer leashinghandle = 0;
vector leashtarget = ZERO_VECTOR;
integer leasherinrange = FALSE;
integer imRestrict = 0;
integer visionRestrict = 0;
integer hearingRestrict = 0;
integer speechRestrict = 1;
integer dazeRestrict = 1;
integer cameraRestrict = 1;
integer inventoryRestrict = 1;
integer worldRestrict = 1;
integer relayInUse = FALSE;

release(integer propagate)
{
    llSetTimerEvent(0.0);
    controller = NULL_KEY;
    objectifier = NULL_KEY;
    relayInUse = FALSE;
    llTargetRemove(leashinghandle);
    llStopMoveToTarget();
    if(propagate) llMessageLinked(LINK_SET, X_API_RELEASE, "", NULL_KEY);
}

capture(key id)
{
    llSetObjectName("");
    llRegionSayTo(id, 0, "secondlife:///app/agent/" + (string)llGetOwner() + "/about is being objectified in a no-rez zone.");
    llOwnerSay("@detach=n,fly=n,unsit=force,sit=n,tplocal=n,tplm=n,tploc=n,tplure=n,tplure:" + (string)llGetOwnerKey(objectifier) + "=add,accepttp:" + (string)llGetOwnerKey(objectifier) + "=add,showself=n,sendgesture=n,startim:" + (string)llGetOwnerKey(objectifier) + "=add,recvim:" + (string)llGetOwnerKey(objectifier) + "=add");
    applyIm();
    applyHearing();
    applySpeech();
    applyVision();
    applyDaze();
    applyCamera();
    applyInventory();
    applyWorld();
    leash();
    urlt = llRequestURL();
    llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
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
    if(visionRestrict > 6) dist = 0.0;
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
    leashinghandle = llTarget(leashtarget, 2.0);
    if(leashtarget != ZERO_VECTOR) llMoveToTarget(leashtarget, 1.5);
}

default
{
    state_entry()
    {
        release(FALSE);
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == X_API_ACTIVATE)
        {
            primary = id;
            state active;
        }
    }
}

state active
{
    attach(key id)
    {
        if(id == NULL_KEY) llResetScript();
    }

    state_entry()
    {
        prefix = llToLower(llGetSubString(llGetUsername(llGetOwner()), 0, 1));
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
        llListen(BALL_CHANNEL, "", NULL_KEY, "");
        llListen(GAZE_ECHO_CHANNEL, "", NULL_KEY, "");
        llListen(GAZE_CHAT_CHANNEL, "", llGetOwner(), "");
        llListen(GAZE_REN_CHANNEL, "", llGetOwner(), "");
        llListen(5, "", NULL_KEY, "");
    }

    listen(integer c, string n, key id, string m)
    {
        if(controller != NULL_KEY) return;
        if(relayInUse) return;

        if(c == GAZE_CHAT_CHANNEL)
        {
            if(objectifier == NULL_KEY) return;
            if(keyisavatar == TRUE) return;
            string o = llGetObjectName();
            llSetObjectName(objectprefix + name);
            if(llToLower(llStringTrim(m, STRING_TRIM)) == "/me" || startswith(m, "/me") == FALSE || contains(m, "\"") == TRUE) llOwnerSay(m);
            else llSay(0, m);
            llSetObjectName(o);
        }
        else if(c == GAZE_REN_CHANNEL)
        {
            if(objectifier == NULL_KEY) return;
            string o = llGetObjectName();
            llSetObjectName(objectprefix + name);
            llSay(0, m);
            llSetObjectName(o);
        }
        else if(c == GAZE_ECHO_CHANNEL)
        {
            if(llGetOwnerKey(id) != objectifier) return;
            if(hearingRestrict > 1) return;
            string o = llGetObjectName();
            llSetObjectName(n);
            llOwnerSay(m);
            llSetObjectName(o);
        }
        else if(c == BALL_CHANNEL)
        {
            if(keyisavatar == FALSE || llGetOwnerKey(id) != objectifier) return;
            if(hearingRestrict == 3) return;
            string o = llGetObjectName();
            llSetObjectName("Wearer's Thoughts");
            llOwnerSay(m);
            llSetObjectName(o);
        }
        else if(c == 5)
        {
            if(llGetOwnerKey(id) != objectifier && llGetOwner() != id) return;
            string o = llGetObjectName();
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
                if(visionRestrict > 7) visionRestrict = 7;
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
            llSetObjectName(o);
        }
        else if(c == MANTRA_CHANNEL)
        {
            if(objectifier != NULL_KEY)
            {
                if(m == "unsit")
                {
                    release(TRUE);
                }
                else if(startswith(m, "puton"))
                {
                    list params = llParseString2List(llDeleteSubString(m, 0, llStringLength("puton")), ["|||"], []);
                    llOwnerSay("@tplure:" + (string)llGetOwnerKey(objectifier) + "=rem,accepttp:" + (string)llGetOwnerKey(objectifier) + "=rem");
                    objectifier = (key)llList2String(params, 0);
                    llMessageLinked(LINK_SET, X_API_SET_OBJECTIFIER, "", objectifier);
                    llOwnerSay("@tplure:" + (string)llGetOwnerKey(objectifier) + "=add,accepttp:" + (string)llGetOwnerKey(objectifier) + "=add");
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
                    objectifier = (key)llList2String(params, 0);
                    llMessageLinked(LINK_SET, X_API_SET_OBJECTIFIER, "", objectifier);
                    llMessageLinked(LINK_SET, X_API_REMEMBER_FURNITURE, "", objectifier);
                    llOwnerSay("@tplure:" + (string)llGetOwnerKey(objectifier) + "=add,accepttp:" + (string)llGetOwnerKey(objectifier) + "=add");
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

            if(llGetOwnerKey(id) != primary && id != primary) return;
            if(startswith(m, "sit") && controller == NULL_KEY && objectifier == NULL_KEY)
            {
                list params = llParseString2List(llDeleteSubString(m, 0, llStringLength("sit")), ["|||"], []);
                objectifier = llGetOwnerKey(id);
                name = llList2String(params, 1);
                objectprefix = llList2String(params, 2);
                if(objectprefix == "NULL") objectprefix = "";
                keyisavatar = llList2Integer(llGetObjectDetails(id, [OBJECT_ATTACHED_POINT]), 0) != 0;
                if(keyisavatar) objectifier = llGetOwnerKey(id);
                else            objectifier = id;
                llMessageLinked(LINK_SET, X_API_SET_OBJECTIFIER, "", llGetOwnerKey(id));
                capture(id);
            }
        }
    }

    at_target(integer num, vector tar, vector me)
    {
        llStopMoveToTarget();
        llTargetRemove(leashinghandle);
        leashtarget = llList2Vector(llGetObjectDetails(objectifier, [OBJECT_POS]), 0);
        leashinghandle = llTarget(leashtarget, 2.0);
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
                leashinghandle = llTarget(leashtarget, 2.0);
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

    run_time_permissions(integer perm)
    {
        if(perm & PERMISSION_TRIGGER_ANIMATION)
        {
            llRegionSayTo(llGetOwner(), COMMAND_CHANNEL, "*onball " + (string)llGetKey());
            llStartAnimation(animation);
            string o = llGetObjectName();
            llSetObjectName("");
            llOwnerSay("You can restrict yourself further by clicking [secondlife:///app/chat/5/" + prefix + "menu here] or by typing /5" + prefix + "menu. Settings made will be saved and remembered for when you are captured by the same person.");
            llRegionSayTo(objectifier, 0, "You can edit the restrictions on your victim by clicking [secondlife:///app/chat/5/" + prefix + "menu here] or by typing /5" + prefix + "menu. Settings made will be saved and remembered for when you capture the same person.");
            llSetObjectName(o);
            llSetTimerEvent(0.5);
        }
    }

    timer()
    {
        if(objectifier != NULL_KEY)
        {
            llRegionSayTo(objectifier, MANTRA_CHANNEL, "objurl " + url);

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
                    release(TRUE);
                }
            }
            else
            {
                firstattempt = TRUE;
            }

            leashtarget = llList2Vector(llGetObjectDetails(objectifier, [OBJECT_POS]), 0);
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
                    release(TRUE);
                }
            }
            else
            {
                firstoutrange = TRUE;
            }
            llTargetRemove(leashinghandle);
            leashtarget = llList2Vector(llGetObjectDetails(objectifier, [OBJECT_POS]), 0);
            leashinghandle = llTarget(leashtarget, 2.0);
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
                release(TRUE);
                llOwnerSay("@tpto:" + body + "=force");
            }
        }
    }

    link_message(integer sender_num, integer num, string str, key id )
    {
        if(num == X_API_RELEASE)
        {
            release(FALSE);
        }
        else if(num == X_API_SET_CONTROLLER)
        {
            controller = id;
        }
        else if(num == X_API_SET_RELAY)
        {
            relayInUse = id != NULL_KEY;
        }
        else if(num == X_API_SETTINGS_LOAD)
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
