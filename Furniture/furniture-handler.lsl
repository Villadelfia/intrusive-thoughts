#include <IT/globals.lsl>

// Linking assistance variables.
integer handle = -1;
key linkTarget = NULL_KEY;
vector startPos = ZERO_VECTOR;
vector endPos   = ZERO_VECTOR;
rotation startRot = ZERO_ROTATION;
rotation endRot   = ZERO_ROTATION;
vector startScale = <1.0, 1.0, 1.0>;
vector endScale   = ZERO_VECTOR;
float startAlpha = 1.0;
float endAlpha   = 0.0;
float tVar = 0.0;
integer wasPhysical = FALSE;
string myName = "";

// General operational variables.
integer FURNITURE_CHANNEL;
key storedobject = NULL_KEY;
key storedavatar = NULL_KEY;
key capturing = NULL_KEY;
string storedname = "";
integer waitingForRez = FALSE;
integer menuState = 0;
integer gaveUnlockNotification = FALSE;
list targets = [];

// Whether the furniture is always visible or only when occupied.
integer furnitureIsAlwaysVisible = TRUE;

// Whether the object can speak in local.
integer objectIsMute = TRUE;

// If not, what object group it belongs to.
string objectGroup = "";

// Timer settings.
// Both zero means indefinite.
// If they are equal, it's a set time in minutes.
// If they are not equal, it's a random time between min and max in minutes.
integer timerMin = 0;
integer timerMax = 0;

// How locked time is measured. Zero is real time, one is active time.
integer timerMode = 0;

// The actual time limit, is either -1 for indefinite, or a number in minutes.
integer lockTimeLimit = -1;

// The amount of time spent locked, both in real time and in actively locked time.
float lockTimeElapsedReal = 0.0;
float lockTimeElapsedActive = 0.0;

// How the timer is shown.
//  0 = full visible
//  1 = potential range
//  2 = not shown
integer timerShowMode = 0;

// The animation played when a victim is captured:
//  0 = hide_a, aka simply underground
//  1 = hide_b, aka true invis
//  2 = custom, it sends over whatever animation is in this furniture and plays that instead. If there's more than one, it'll send over all of them and send play them all.
integer animationMode = 0;

// Offsets for custom animations.
vector positionOffset = ZERO_VECTOR;
rotation rotationOffset = ZERO_ROTATION;

// To use these features, two prims must be linked to the linkset:
//  - cam_pos
//  - cam_focus
//
// If 'cameraMode' is set to 0, then the regular focusing will be used.
// If it's set to 1, then the camera will be locked at cam_pos and aimed at cam_focus.
// If it's set to 2, it will act the same, except when an avatar comes within
integer cameraMode = 0;
key camPosKey = NULL_KEY;
key camFocusKey = NULL_KEY;

// Whether the furniture has someone locked. And if it is a deadlock.
key lockedAvatar = NULL_KEY;
integer lockedDeadlock = FALSE;

// How the capturing works;
// If no timer is set:
//   1. Capture -> The person will now be locked until released or until relog.
//   2. Lock    -> The person will now only be released if and when the owner unlocks and releases them. Will recapture on relog.
// If a timer is set:
//   1. Capture  -> The person will be locked until released or until relog. If the timer expires before this, they will get offered to release themselves. Can be clicked at any point from then on.
//   2. Lock     -> The person will now only be released if and when the owner unlocks and releases them, or the timer expires. Will recapture on relog.
//   3. Deadlock -> Like lock, but now ONLY a timer expiration can cause a release.
//
// Animation when captured;
// There are three options:
//    1. Hidden -> Victim is just put underground. Unsuitable for multi story buildings or exceptionally big furniture.
//    2. Invisible -> Victim is completely invisible. Even the nameplate. Needs a relog to become visible again.
//    3. Custom    -> Will copy any and all animations inside of the furniture to the orb, then play all of them. Meant for custom poses or "pedestals". Can use "edit mode" to adjust position and rotation, will remember the last location.

integer canUnlock()
{
    if(lockTimeLimit == -1) return FALSE;
    if(timerMode == 0)
    {
        return lockTimeElapsedReal >= (lockTimeLimit * 60);
    }
    else
    {
        return lockTimeElapsedActive >= (lockTimeLimit * 60);
    }
}

giveUnlockNotification()
{
    if(gaveUnlockNotification == TRUE) return;
    gaveUnlockNotification = TRUE;
    llRegionSayTo(storedavatar, 0, "Your capture timer is up. You may now, and at any later time, type /5release or click [secondlife:///app/chat/5/release here] to release yourself.");
}

makeNewTimer()
{
    gaveUnlockNotification = FALSE;
    lockTimeElapsedActive = 0.0;
    lockTimeElapsedReal = 0.0;
    if(timerMin == 0 && timerMax == 0)
    {
        lockTimeLimit = -1;
    }
    else if(timerMin == timerMax)
    {
        lockTimeLimit = timerMin;
    }
    else
    {
        lockTimeLimit = timerMin + (integer)(llFrand(timerMax - timerMin + 1));
    }
}

scanCamera()
{
    camPosKey = NULL_KEY;
    camFocusKey = NULL_KEY;
    integer i = llGetLinkNumber() != 0;
    integer x = llGetNumberOfPrims() + i;
    for(; i < x; ++i)
    {
        if(llGetLinkName(i) == "cam_pos") camPosKey = llGetLinkKey(i);
        if(llGetLinkName(i) == "cam_focus") camFocusKey = llGetLinkKey(i);
    }
    broadcastCamera();
}

broadcastCamera()
{
    if(storedobject == NULL_KEY) return;
    llRegionSayTo(storedobject, MANTRA_CHANNEL, "furniturecamera;" + (string)cameraMode + ";" + (string)camPosKey + ";" + (string)camFocusKey);
}

float fCos(float x, float y, float t)
{
    float F = (1-llCos(t*PI))/2;
    return (x*(1-F))+(y*F);
}

vector vCos(vector x, vector y, float t)
{
    float F = (1-llCos(t*PI))/2;
    return (x*(1-F))+(y*F);
}

rotation rCos(rotation x, rotation y, float t)
{
    float f = (1-llCos(t*PI))/2;
    float ang = llAngleBetween(x, y);
    if(ang > PI) ang -= TWO_PI;
    return x * llAxisAngle2Rot(llRot2Axis(y/x)*x, ang*f);
}

whichperson()
{
    storedavatar = NULL_KEY;
    if(storedobject == NULL_KEY) return;

    list agents = llGetAgentList(AGENT_LIST_REGION, []);
    integer n = llGetListLength(agents);
    while(~--n)
    {
        key agent = llList2Key(agents, n);
        if(llList2Key(llGetObjectDetails(agent, [OBJECT_ROOT]), 0) == storedobject)
        {
            storedavatar = agent;
            return;
        }
    }

    // If we get here, something has gone horribly wrong.
    llRegionSayTo(storedobject, MANTRA_CHANNEL, "unsit");
    storedobject = NULL_KEY;
    llSetTimerEvent(0.0);
}

saytoobject(string n, string m)
{
    string old = llGetObjectName();
    llSetObjectName(n);
    llRegionSayTo(storedavatar, 0, m);
    llSetObjectName(old);
}

string prettyDuration(integer m)
{
    integer d = 0;
    integer h = 0;
    while(m > 1440)
    {
        m -= 1440;
        d++;
    }

    while(m > 60)
    {
        m -= 60;
        h++;
    }

    return (string)d +"d " + (string)h + "h " + (string)m + "m";
}

handleMenu(key t)
{
    if(menuState == 0)
    {
        string msg = "";
        list buttons = [];


        // Top row: Capturing, releasing, locking, unlocking, deadlocking.
        if(storedobject)
        {
            if(lockedAvatar)
            {
                if(lockedDeadlock)
                {
                    msg += "This furniture is currently deadlocked to secondlife:///app/agent/" + (string)lockedAvatar + "/about.\n \n";
                    if(canUnlock()) buttons += [" ", "UNLOCK", " "];
                }
                else
                {
                    msg += "This furniture is currently locked to secondlife:///app/agent/" + (string)lockedAvatar + "/about.\n \n";
                    if(timerMin != 0 && timerMax != 0) buttons += [" ", "UNLOCK", "DEADLOCK"];
                    else                               buttons += [" ", "UNLOCK", " "];
                }
            }
            else
            {
                msg += "This furniture is currently occupied by secondlife:///app/agent/" + (string)storedavatar + "/about.\n \n";
                buttons += ["RELEASE", "LOCK", " "];
            }
        }
        else
        {
            if(lockedAvatar)
            {
                if(lockedDeadlock)
                {
                    msg += "This furniture is currently deadlocked to secondlife:///app/agent/" + (string)lockedAvatar + "/about.\n \n";
                    if(canUnlock()) buttons += [" ", "UNLOCK", " "];
                }
                else
                {
                    msg += "This furniture is currently locked to secondlife:///app/agent/" + (string)lockedAvatar + "/about.\n \n";
                    if(timerMin != 0 && timerMax != 0) buttons += [" ", "UNLOCK", "DEADLOCK"];
                    else                               buttons += [" ", "UNLOCK", " "];
                }
            }
            else
            {
                msg += "This furniture is currently ready to capture anyone.\n \n";
                buttons += ["CAPTURE", " ",  " "];
            }
        }


        // Second row: Object group and uncaptured visibility.
        msg += " ▶ This furniture is named " + llGetObjectName() + ".\n";
        if(objectGroup == "") msg += " ▶ This furniture is not in a group.\n";
        else                  msg += " ▶ This furniture is in the \"" + objectGroup+ "\" group.\n";
        buttons += ["RENAME", "GROUP"];

        if(furnitureIsAlwaysVisible)
        {
            msg += " ▶ The furniture is always visible, even when not occupied.\n \n";
            buttons += ["INVISIBLE"];
        }
        else
        {
            msg += " ▶ The furniture is invisible when not occupied.\n \n";
            buttons += ["VISIBLE"];
        }


        // Third row: Speech, anim, camera.
        if(objectIsMute)
        {
            msg += " ▶ Stored objects cannot speak.\n";
            buttons += ["CAN SPEAK"];
        }
        else
        {
            msg += " ▶ Stored objects can speak.\n";
            buttons += ["MUTE"];
        }

        if(animationMode == 0)
        {
            msg += " ▶ Animation: Hide.\n";
            buttons += ["HIDE NAME"];
        }
        else if(animationMode == 1)
        {
            msg += " ▶ Animation: Invisible.\n";
            if(llGetInventoryNumber(INVENTORY_ANIMATION) > 0) buttons += ["CUSTOM"];
            else                                              buttons += ["SHOW NAME"];
        }
        else if(animationMode == 2)
        {
            msg += " ▶ Animation: Custom.\n";
            buttons += ["SHOW NAME"];
        }

        if(camPosKey != NULL_KEY && camFocusKey != NULL_KEY)
        {
            if(cameraMode == 0)
            {
                msg += " ▶ Camera follows normal rules.";
                buttons += ["OBJ CAM"];
            }
            else if(cameraMode == 1)
            {
                msg += " ▶ Camera focuses on object.";
                buttons += ["FPV CAM"];
            }
            else if(cameraMode == 2)
            {
                msg += " ▶ Camera focuses on avatars.";
                buttons += ["NORM CAM"];
            }
        }
        else
        {
            buttons += [" "];
        }

        // Fourth row: Obj menu and timer.
        if(storedobject)
        {
            if(animationMode == 2) buttons += ["TIMER", "EDIT TOGGLE", "OBJ MENU"];
            else                   buttons += ["TIMER", " ", "OBJ MENU"];
        }
        else
        {
            buttons += ["TIMER", " ", " "];
        }

        // Order and send it.
        llDialog(t, msg, orderbuttons(buttons), FURNITURE_CHANNEL);
    }
    else if(menuState == 1)
    {
        targets = [];
        list onsim = llGetAgentList(AGENT_LIST_REGION, []);
        vector pos = llGetPos();
        integer n = llGetListLength(onsim);
        key id;
        while(~--n)
        {
            id = llList2Key(onsim, n);
            targets += [llVecDist(pos, llList2Vector(llGetObjectDetails(id, [OBJECT_POS]), 0)), id];
            onsim = llDeleteSubList(onsim, -1, -1);
        }
        targets = llList2List(llListSort(targets, 2, TRUE), 0, 23);

        string msg = "Who do you wish to capture?\n \n";
        list buttons = [];
        integer i;
        n = llGetListLength(targets);
        for(i = 0; i < n; i += 2)
        {
            if(n > 5)
            {
                string uname = llGetUsername(llList2Key(targets, i+1));
                if(contains(uname, ".")) uname = llList2String(llParseString2List(uname, ["."], []), 0);
                msg += (string)(i/2+1) + ". " + uname + "\n";
            }
            else
            {
                msg += (string)(i/2+1) + ". secondlife:///app/agent/" + (string)llList2Key(targets, i+1) + "/about\n";
            }
            buttons += [(string)(i/2+1)];
        }

        while(llGetListLength(buttons) < 12) buttons += [" "];
        llDialog(t, msg, orderbuttons(buttons), FURNITURE_CHANNEL);
    }
    else if(menuState == 2)
    {
        llTextBox(t, "Enter a new name for this furniture.", FURNITURE_CHANNEL);
    }
    else if(menuState == 3)
    {
        llTextBox(t, "Enter a new group for this furniture. Objects stored on this furniture will be able to talk to objects stored on other furniture with the same group. Enter none to remove the group.", FURNITURE_CHANNEL);
    }
    else if(menuState == 4)
    {
        string msg = "Current timer settings:\n\n";
        list buttons = [];

        // Timer settings.
        if(timerMin == 0 && timerMax == 0)
        {
            msg += "▶ Indefinite duration.\n";
        }
        else if(timerMin == timerMax)
        {
            msg += "▶ Duration: " + prettyDuration(timerMin) + ".\n";
        }
        else
        {
            msg += "▶ Minimum Duration: " + prettyDuration(timerMin) + ".\n";
            msg += "▶ Maximum Duration: " + prettyDuration(timerMax) + ".\n";
        }
        buttons = ["SET TIMER"];

        // When the timer counts.
        if(timerMode == 0)
        {
            msg += "▶ Time counted in real time.\n";
            buttons += ["ACTIVE TIME"];
        }
        else
        {
            msg += "▶ Time counted in active time.\n";
            buttons += ["REAL TIME"];
        }

        // How the timer is shown.
        if(timerShowMode == 0)
        {
            msg += "▶ Timer is displayed here.\n";
            buttons += ["HIDE TIMER"];
        }
        else if(timerShowMode == 1)
        {
            msg += "▶ Timer maximum is displayed here.\n";
            buttons += ["SHOW TIMER"];
        }
        else
        {
            msg += "▶ Timer is hidden.\n";
            buttons += ["SHOW RANGE"];
        }

        if((storedavatar != NULL_KEY || lockedAvatar != NULL_KEY) && lockTimeLimit != -1)
        {
            float spent = 0.0;
            if(timerMode == 0) spent = lockTimeElapsedReal / 60.0;
            else               spent = lockTimeElapsedActive / 60.0;
            integer remaining = lockTimeLimit - llRound(spent);
            if(remaining >= 0)
            {
                if(timerShowMode == 0)
                {
                    msg += "\n▶ Time remaining: " + prettyDuration(remaining) + ".\n";
                }
                else if(timerShowMode == 1)
                {
                    if(timerMin == timerMax)
                    {
                        msg += "\n▶ Time remaining: Up to " + prettyDuration(timerMax) + ".\n";
                    }
                    else if(spent < timerMin)
                    {
                        msg += "\n▶ Minimum time remaining: " + prettyDuration(timerMin - llRound(spent)) + ".\n";
                        msg += "▶ Maximum time remaining: " + prettyDuration(timerMax - llRound(spent)) + ".\n";
                    }
                    else
                    {
                        msg += "\n▶ Time remaining: Up to " + prettyDuration(timerMax - llRound(spent)) + ".\n";
                    }
                }
                msg += "\nNote that changing the timer now will not have any effect until you recapture the victim.";
            }
        }

        buttons += [" ", " ", "BACK"];
        llDialog(t, msg, orderbuttons(buttons), FURNITURE_CHANNEL);
    }
    else if(menuState == 5)
    {
        llTextBox(t, "Enter a time limit for the capture.\n\nIf you want a set time, enter one number in minutes.\nIf you want a minimum and a maximum, enter two numbers separated by a space, both in minutes.\nIf you want to have the capture indefinite, enter NONE.", FURNITURE_CHANNEL);
    }
}

default
{
    on_rez(integer start_param)
    {
        llResetScript();
    }

    state_entry()
    {
        if(llGetAttached() != 0)
        {
            llOwnerSay("Please rez me instead of wearing me.");
            return;
        }
        if(llGetLinkNumber() != 0)
        {
            state running;
            return;
        }
        llSetRemoteScriptAccessPin(0);
        llOwnerSay("Welcome to your " + llGetObjectName() + ".\n\nFirst, I need to link up with another object. Drop the script I am giving you right now into that object and follow the instructions.");
        llGiveInventory(llGetOwner(), "IT Furniture Linking Script");
        handle = llListen(-1443216791, "", NULL_KEY, "");
        llPreloadSound("dec9fb53-0fef-29ae-a21d-b3047525d312");
        llSetStatus(STATUS_PHANTOM, TRUE);
    }

    listen(integer channel, string name, key id, string message)
    {
        if(llGetOwner() != llGetOwnerKey(id)) return;
        llListenRemove(handle);
        handle = -1;
        linkTarget = (key)message;
        list dets = llGetObjectDetails(linkTarget, [OBJECT_PHYSICS, OBJECT_TEMP_ON_REZ]);
        wasPhysical = llList2Integer(dets, 0);
        if(llList2Integer(dets, 1))
        {
            llOwnerSay("Can't link to temp rezzed objects!");
            llResetScript();
        }
        llOwnerSay("I am linking to " + llList2String(llGetObjectDetails(linkTarget, [OBJECT_NAME]), 0) + ". Please grant me the linking permission to complete setup.");
        llRequestPermissions(llGetOwner(), PERMISSION_CHANGE_LINKS);
    }

    run_time_permissions(integer perm)
    {
        if(perm & PERMISSION_CHANGE_LINKS)
        {
            list     info = llGetObjectDetails(linkTarget, [OBJECT_POS, OBJECT_ROT, OBJECT_NAME, OBJECT_DESC]) + llGetBoundingBox(linkTarget);
            vector   pos  = llList2Vector(info, 0);
            rotation rot  = llList2Rot(info, 1);
            myName = llList2String(info, 2);
            vector   c1   = llList2Vector(info, 4) * rot + pos;
            vector   c2   = llList2Vector(info, 5) * rot + pos;
            vector   size = llList2Vector(info, 5) - llList2Vector(info, 4);

            startPos = llGetPos();
            endPos   = (c1 + c2) * 0.5;

            startRot = llGetRot();
            endRot   = rot;

            startScale = llGetScale();
            endScale   = size;

            startAlpha = 1.0;
            endAlpha   = 0.1;

            tVar = 0.0;

            llSetObjectDesc(llList2String(info, 3));
            llSetTimerEvent(0.05);
        }
        else
        {
            llOwnerSay("You must grant the linking permission to continue.");
            llResetScript();
        }
    }

    timer()
    {
        if(tVar <= 1.0)
        {
            tVar += 0.025;
            llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_ROTATION, rCos(startRot, endRot, tVar),
                                                     PRIM_SIZE,     vCos(startScale, endScale, tVar),
                                                     PRIM_COLOR,    ALL_SIDES, <0.784, 0.094, 0.094>, fCos(startAlpha, endAlpha, tVar)]);
            llSetRegionPos(vCos(startPos, endPos, tVar));
        }
        else if(tVar <= 2.0)
        {
            tVar += 0.2;
            llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_GLOW, ALL_SIDES, fCos(0.0, 0.2, tVar-1.0)]);
        }
        else if(tVar <= 2.5)
        {
            tVar += 0.5;
            llPlaySound("dec9fb53-0fef-29ae-a21d-b3047525d312", 1.0);
        }
        else if(tVar <= 3.5)
        {
            tVar += 0.2;
            llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_GLOW, ALL_SIDES, fCos(0.2, 0.0, tVar-2.5)]);
        }
        else
        {
            llSetTimerEvent(0.0);
            llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_TEXTURE,    ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0,
                                                     PRIM_COLOR,      ALL_SIDES, <1.0, 1.0, 1.0>, 1.0,
                                                     PRIM_ALPHA_MODE, ALL_SIDES, PRIM_ALPHA_MODE_MASK, 255,
                                                     PRIM_GLOW,       ALL_SIDES, 0.0]);
            llCreateLink(linkTarget, TRUE);
            llSetObjectName(myName);
            if(wasPhysical) llSetLinkPrimitiveParamsFast(LINK_ROOT, [PRIM_TYPE, PRIM_TYPE_SPHERE, PRIM_HOLE_DEFAULT, <0.0, 1.0, 0.0>, 0.0, <0.0, 0.0, 0.0>, <0.0, 1.0, 0.0>]);
            llSetStatus(STATUS_PHANTOM, !wasPhysical);
            llSetStatus(STATUS_PHYSICS, wasPhysical);
            llOwnerSay("Alright, I'm good to go. You can now store objects in me via the IT Master HUD. Click me for more options.");
            llRemoveInventory("IT Furniture Linking Script");
            state running;
        }
    }
}

state running
{
    state_entry()
    {
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
        llListen(GAZE_CHAT_CHANNEL, "", NULL_KEY, "");
        llListen(5, "", NULL_KEY, "");
        objectGroup = llGetObjectDesc();
        objectGroup = llStringTrim(objectGroup, STRING_TRIM);
        llSetObjectDesc(objectGroup);
        FURNITURE_CHANNEL = ((integer)("0x"+llGetSubString((string)llGetKey(),-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFFF;
        llListen(FURNITURE_CHANNEL, "", NULL_KEY, "");
        llSetRemoteScriptAccessPin(FURNITURE_CHANNEL);
        llSetLinkAlpha(LINK_THIS, 0.0, ALL_SIDES);
        scanCamera();
    }

    changed(integer change)
    {
        if(change & CHANGED_LINK)
        {
            scanCamera();
        }
    }

    on_rez(integer start)
    {
        llOwnerSay("Fresh rez detected... Reinitializing.");
        lockedAvatar = NULL_KEY;
        storedobject = NULL_KEY;
        storedavatar = NULL_KEY;
        capturing = NULL_KEY;
        storedname = "";
        waitingForRez = FALSE;
        state default;
    }

    listen(integer c, string n, key id, string m)
    {
        if(c == MANTRA_CHANNEL)
        {
            // Request for version. Only respond when not in use.
            if(m == "furnver" && storedobject == NULL_KEY && llGetOwnerKey(id) == llGetOwner())
            {
                llRegionSayTo(id, MANTRA_CHANNEL, "furnver=" + (string)FURNITURE_VERSION);
            }

            // The IT controller is asking if we have anything stored.
            else if(m == "furniture")
            {
                // We respond if there is not a locked avatar. If there is, however, the request is denied.
                if(lockedAvatar == NULL_KEY)
                {
                    if(storedobject == NULL_KEY) llRegionSayTo(id, MANTRA_CHANNEL, "furniture 0");
                    else                         llRegionSayTo(id, MANTRA_CHANNEL, "furniture 1");
                }
                else
                {
                    if(storedobject) llRegionSayTo(llGetOwnerKey(id), 0, "The stored object is locked to this furniture. The owner can unlock it by clicking the furniture.");
                    else             llRegionSayTo(llGetOwnerKey(id), 0, "This furniture is reserved for a specific object. The owner can release this reservation by clicking the furniture.");
                }
            }

            // We've been by the IT controller that we have to give up whatever we are storing.
            else if(startswith(m, "puton"))
            {
                // Early return in case of nothing stored.
                if(storedobject == NULL_KEY) return;

                // If the avatar is locked, deny the request.
                if(lockedAvatar) return;

                // Otherwise, give it up.
                llRegionSayTo(storedobject, MANTRA_CHANNEL, "puton " + (string)llGetOwnerKey(id) + "|||" + storedname);
                storedobject = NULL_KEY;
                if(!furnitureIsAlwaysVisible) llSetLinkAlpha(LINK_ALL_OTHERS, 0.0, ALL_SIDES);
                llSetTimerEvent(0.0);
            }

            // We've been told by the IT controller that whatever it is storing is now ours.
            else if(startswith(m, "putdown"))
            {
                // If we have a locked avatar, deny the request.
                if(lockedAvatar)
                {
                    llRegionSayTo(llGetOwnerKey(id), 0, "This furniture is reserved for a specific object. You can release this reservation by clicking the furniture.");
                    return;
                }

                // If we already had an object, we do an exchange.
                if(storedobject != NULL_KEY) llRegionSayTo(storedobject, MANTRA_CHANNEL, "puton " + (string)llGetOwnerKey(id) + "|||" + storedname);

                // We store the object.
                list params = llParseString2List(llDeleteSubString(m, 0, llStringLength("putdown")), ["|||"], []);
                storedobject = (key)llList2String(params, 0);
                storedname = llList2String(params, 1);
                whichperson();

                // Let the object know to follow us now.
                llRegionSayTo(storedobject, MANTRA_CHANNEL, "putdown " + (string)llGetKey() + "|||" + llGetObjectName());
                llRegionSayTo(id, MANTRA_CHANNEL, "putdown");
                if(!furnitureIsAlwaysVisible) llSetLinkAlpha(LINK_ALL_OTHERS, 1.0, ALL_SIDES);
                llSetTimerEvent(5.0);
            }

            // We've been told by the IT controller to capture someone.
            else if(startswith(m, "capture"))
            {
                // If we have an object, refuse.
                if(storedobject != NULL_KEY) return;

                // If we're locked to someone, refuse.
                if(lockedAvatar)
                {
                    llRegionSayTo(llGetOwnerKey(id), 0, "This furniture is reserved for a specific object. You can release this reservation by clicking the furniture.");
                    return;
                }

                // Set the uuid of who to capture.
                capturing = (key)llDeleteSubString(m, 0, llStringLength("capture"));

                // Then do it.
                integer option = 4 | 1;
                if(animationMode == 1) option = 4 | 2;
                makeNewTimer();
                llRezAtRoot("ball", llGetPos(), ZERO_VECTOR, ZERO_ROTATION, option);
                waitingForRez = TRUE;
                llSetTimerEvent(15.0);
            }

            // Offsets after edit mode.
            else if(startswith(m, "offsets"))
            {
                list params = llParseString2List(m, [";"], []);
                positionOffset = (vector)llList2String(params, 1);
                rotationOffset = (rotation)llList2String(params, 2);
            }
        }
        else if(c == GAZE_CHAT_CHANNEL)
        {
            // Don't bother if we have no object.
            if(storedobject == NULL_KEY) return;

            // Don't bother if we have no object group.
            if(objectIsMute && objectGroup == "") return;

            // First we check if the message would already be allowed...
            if(llToLower(llStringTrim(m, STRING_TRIM)) != "/me" && startswith(m, "/me") == TRUE && contains(m, "\"") == FALSE) return;

            if(objectIsMute)
            {
                // If the source was the object we're storing, forward to the region.
                if(storedavatar == id)
                {
                    llRegionSay(GAZE_CHAT_CHANNEL, m);
                }

                // If the source was an object with a matching description to ours, forward the message to the object we're storing.
                else if(objectGroup == llList2String(llGetObjectDetails(id, [OBJECT_DESC]), 0))
                {
                    saytoobject(n, m);
                }
            }
            else
            {
                // If it's the right avatar, we say it.
                if(storedavatar == id) llSay(0, m);
            }
        }
        else if(c == FURNITURE_CHANNEL)
        {
            if(menuState == 0)
            {
                // Top row: Capturing, releasing, locking, deadlocking.
                if(m == "CAPTURE")
                {
                    menuState = 1;
                    handleMenu(id);
                }
                else if(m == "RELEASE")
                {
                    llRegionSayTo(storedobject, MANTRA_CHANNEL, "unsit");
                    storedobject = NULL_KEY;
                    storedavatar = NULL_KEY;
                    handleMenu(id);
                }
                else if(m == "LOCK")
                {
                    lockedAvatar = storedavatar;
                    handleMenu(id);
                }
                else if(m == "DEADLOCK")
                {
                    lockedDeadlock = TRUE;
                    handleMenu(id);
                }
                else if(m == "UNLOCK")
                {
                    lockedAvatar = NULL_KEY;
                    llSensorRemove();
                    handleMenu(id);
                }

                // Second row
                else if(m == "RENAME")
                {
                    menuState = 2;
                    handleMenu(id);
                }
                else if(m == "GROUP")
                {
                    menuState = 3;
                    handleMenu(id);
                }
                else if(m == "INVISIBLE" || m == "VISIBLE")
                {
                    furnitureIsAlwaysVisible = !furnitureIsAlwaysVisible;
                    if(storedobject == NULL_KEY) llSetLinkAlpha(LINK_ALL_OTHERS, (float)furnitureIsAlwaysVisible, ALL_SIDES);
                    handleMenu(id);
                }

                // Third row.
                else if(m == "CAN SPEAK" || m == "MUTE")
                {
                    objectIsMute = !objectIsMute;
                    handleMenu(id);
                }
                else if(m == "SHOW NAME")
                {
                    animationMode = 0;
                    handleMenu(id);
                }
                else if(m == "HIDE NAME")
                {
                    animationMode = 1;
                    handleMenu(id);
                }
                else if(m == "CUSTOM")
                {
                    animationMode = 2;
                    handleMenu(id);
                }
                else if(m == "NORM CAM")
                {
                    cameraMode = 0;
                    broadcastCamera();
                    handleMenu(id);
                }
                else if(m == "OBJ CAM")
                {
                    cameraMode = 1;
                    broadcastCamera();
                    handleMenu(id);
                }
                else if(m == "FPV CAM")
                {
                    cameraMode = 2;
                    broadcastCamera();
                    handleMenu(id);
                }

                // Fourth row.
                else if(m == "TIMER")
                {
                    menuState = 4;
                    handleMenu(id);
                }
                else if(m == "OBJ MENU")
                {
                    string prefix = llGetSubString(llGetUsername(storedavatar), 0, 1);
                    llRegionSayTo(storedobject, 5, prefix + "menu");
                }
                else if(m == "EDIT TOGGLE")
                {
                    llRegionSayTo(storedobject, MANTRA_CHANNEL, "edit");
                }
                else if(m == " ")
                {
                    handleMenu(id);
                }
            }
            else if(menuState == 1)
            {
                if(m == " ")
                {
                    handleMenu(id);
                }
                else
                {
                    capturing = llList2Key(targets, ((((integer)m)-1)*2)+1);
                    llOwnerSay("Capturing secondlife:///app/agent/" + (string)capturing + "/about...");
                    integer option = 4 | 1;
                    if(animationMode == 1) option = 4 | 2;
                    makeNewTimer();
                    llRezAtRoot("ball", llGetPos(), ZERO_VECTOR, ZERO_ROTATION, option);
                    waitingForRez = TRUE;
                    llSetTimerEvent(15.0);
                }
            }
            else if(menuState == 2)
            {
                m = llStringTrim(m, STRING_TRIM);
                if(m == "") m = "Unnamed Furniture";
                llSetObjectName(m);
                if(storedobject)
                {
                    string prefix = llGetSubString(llGetUsername(storedavatar), 0, 1);
                    llRegionSayTo(storedobject, 5, prefix + "name " + llGetObjectName());
                }
                menuState = 0;
                handleMenu(id);
            }
            else if(menuState == 3)
            {
                m = llStringTrim(m, STRING_TRIM);
                if(llToLower(m) == "none") m = "";
                llSetObjectDesc(m);
                objectGroup = m;
                menuState = 0;
                handleMenu(id);
            }
            else if(menuState == 4)
            {
                if(m == "BACK" || m == " ")
                {
                    menuState = 0;
                    handleMenu(id);
                }
                else if(m == "SET TIMER")
                {
                    menuState = 5;
                    handleMenu(id);
                }
                else if(m == "ACTIVE TIME")
                {
                    timerMode = 1;
                    handleMenu(id);
                }
                else if(m == "REAL TIME")
                {
                    timerMode = 0;
                    handleMenu(id);
                }
                else if(m == "HIDE TIMER")
                {
                    timerShowMode = 2;
                    handleMenu(id);
                }
                else if(m == "SHOW RANGE")
                {
                    timerShowMode = 1;
                    handleMenu(id);
                }
                else if(m == "SHOW TIMER")
                {
                    timerShowMode = 0;
                    handleMenu(id);
                }
            }
            else if(menuState == 5)
            {
                if(llToUpper(llStringTrim(m, STRING_TRIM)) == "NONE")
                {
                    timerMin = 0;
                    timerMax = 0;
                }
                else
                {
                    list args = llParseString2List(llStringTrim(m, STRING_TRIM), [" "], []);
                    if(llGetListLength(args) > 1)
                    {
                        timerMin = (integer)llList2String(args, 0);
                        timerMax = (integer)llList2String(args, 1);
                        if(timerMin > timerMax) timerMin = timerMax;
                    }
                    else
                    {
                        timerMin = (integer)llStringTrim(m, STRING_TRIM);
                        timerMax = timerMin;
                    }
                }
                menuState = 4;
                handleMenu(id);
            }
        }
        else if(c == 5)
        {
            if(canUnlock() == FALSE) return;
            if(id != storedavatar) return;
            if(m != "release") return;
            llRegionSayTo(storedobject, MANTRA_CHANNEL, "unsit");
            storedobject = NULL_KEY;
            storedavatar = NULL_KEY;
        }
    }

    touch_start(integer num_detected)
    {
        if(llDetectedKey(0) == storedavatar) return;
        menuState = 0;
        handleMenu(llDetectedKey(0));
        llMessageLinked(LINK_ALL_OTHERS, 90005, "", llDetectedKey(0));
    }

    // Object_rez event is only used for objectification.
    object_rez(key id)
    {
        if(!waitingForRez) return;
        if(llList2String(llGetObjectDetails(id, [OBJECT_NAME]), 0) != "ball") return;
        llSetTimerEvent(0.0);
        waitingForRez = FALSE;
        storedobject = id;
        storedavatar = capturing;
        storedname = llGetObjectName();

        if(animationMode == 2)
        {
            list anims = [];
            integer l = llGetInventoryNumber(INVENTORY_ANIMATION);
            while(~--l) anims += [llGetInventoryName(INVENTORY_ANIMATION, l)];
            llGiveInventoryList(id, ".", anims);
            llRegionSayTo(id, MANTRA_CHANNEL, "offsets;" + (string)positionOffset + ";" + (string)rotationOffset);
        }

        llRegionSayTo(id, MANTRA_CHANNEL, "sit " + (string)capturing + "|||" + llGetObjectName() + "|||NULL");
        if(!furnitureIsAlwaysVisible) llSetLinkAlpha(LINK_ALL_OTHERS, 1.0, ALL_SIDES);
        broadcastCamera();
        llSetTimerEvent(15.0);
    }

    // The sensor timer is used to look for the locked avatar.
    no_sensor()
    {
        // Quit if we already have the object stored.
        if(storedobject) return;

        // Increment real time.
        lockTimeElapsedReal += llGetAndResetTime();

        // Quit if the object isn't here.
        if(llGetAgentSize(lockedAvatar) == ZERO_VECTOR) return;

        // Otherwise, go for it!
        capturing = lockedAvatar;
        integer option = 4 | 1;
        if(animationMode == 1) option = 4 | 2;
        gaveUnlockNotification = FALSE;
        llRezAtRoot("ball", llGetPos(), ZERO_VECTOR, ZERO_ROTATION, option);
        waitingForRez = TRUE;
        llSetTimerEvent(15.0);
        llSensorRemove();
    }

    // The basic timer is used to track the presence of the object. Once it's gone, we clear up our state.
    timer()
    {
        llSetTimerEvent(0.0);

        // The lock keeps ticking.
        float inc = llGetAndResetTime();
        lockTimeElapsedReal += inc;
        if(storedobject) lockTimeElapsedActive += inc;

        // It is also used to track stalled rezzes, because SL is an amazing piece of technology that always works perfectly.
        if(waitingForRez)
        {
            // If the avatar we were rezzing for is still around, just try again.
            if(llGetAgentSize(capturing) != ZERO_VECTOR)
            {
                integer option = 4 | 1;
                if(animationMode == 1) option = 4 | 2;
                llRezAtRoot("ball", llGetPos(), ZERO_VECTOR, ZERO_ROTATION, option);
                waitingForRez = TRUE;
                llSetTimerEvent(15.0);
                return;
            }

            // Otherwise, give up.
            else
            {
                waitingForRez = FALSE;
                if(lockedAvatar) sensortimer(5.0);
                return;
            }
        }

        if(llGetObjectDetails(storedobject, [OBJECT_POS]) == [])
        {
            storedavatar = NULL_KEY;
            storedobject = NULL_KEY;
            if(!furnitureIsAlwaysVisible) llSetLinkAlpha(LINK_ALL_OTHERS, 0.0, ALL_SIDES);
            if(lockedAvatar) sensortimer(5.0);
            return;
        }
        else if(canUnlock())
        {
            giveUnlockNotification();
        }

        broadcastCamera();
        llSetTimerEvent(5.0);
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == X_API_DUMP_SETTINGS)
        {
            string packed = "" +
                (string)furnitureIsAlwaysVisible + "\n" +
                (string)objectIsMute + "\n" +
                (string)animationMode + "\n" +
                (string)lockedAvatar + "\n" +
                llStringToBase64(objectGroup) + "\n" +
                (string)cameraMode + "\n" +
                (string)timerMin + "\n" +
                (string)timerMax + "\n" +
                (string)timerMode + "\n" +
                (string)lockTimeLimit + "\n" +
                (string)lockTimeElapsedReal + "\n" +
                (string)lockTimeElapsedActive + "\n" +
                (string)timerShowMode + "\n" +
                (string)positionOffset + "\n" +
                (string)rotationOffset;
            llMessageLinked(LINK_THIS, X_API_DUMP_SETTINGS_R, packed, NULL_KEY);
        }
        else if(num == X_API_RESTORE_SETTINGS)
        {
            list data = llParseString2List(str, ["\n"], []);
            furnitureIsAlwaysVisible = (integer)llList2String(data, 0);
            objectIsMute = (integer)llList2String(data, 1);
            animationMode = (integer)llList2String(data, 2);
            lockedAvatar = (key)llList2String(data, 3);
            objectGroup = llBase64ToString(llList2String(data, 4));
            cameraMode = (integer)llList2String(data, 5);
            timerMin = (integer)llList2String(data, 6);
            timerMax = (integer)llList2String(data, 7);
            timerMode = (integer)llList2String(data, 8);
            lockTimeLimit = (integer)llList2String(data, 9);
            lockTimeElapsedReal = (float)llList2String(data, 10);
            lockTimeElapsedActive = (float)llList2String(data, 11);
            timerShowMode = (integer)llList2String(data, 12);
            positionOffset = (vector)llList2String(data, 13);
            rotationOffset = (rotation)llList2String(data, 14);
            llResetTime();
            if(lockedAvatar) sensortimer(5.0);
            scanCamera();
            llMessageLinked(LINK_THIS, X_API_RESTORE_SETTINGS_R, "OK", NULL_KEY);
        }
    }
}
