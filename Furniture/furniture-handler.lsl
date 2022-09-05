#include <IT/globals.lsl>
key storedobject = NULL_KEY;
key storedavatar = NULL_KEY;
key capturing = NULL_KEY;
string storedname = "";
key linkTarget = NULL_KEY;
integer handle = -1;
vector startPos = ZERO_VECTOR;
vector endPos   = ZERO_VECTOR;
rotation startRot = ZERO_ROTATION;
rotation endRot   = ZERO_ROTATION;
vector startScale = <1.0, 1.0, 1.0>;
vector endScale   = ZERO_VECTOR;
float startAlpha = 1.0;
float endAlpha   = 0.0;
float tVar = 0.0;
string myName = "";
integer waitingForRez = FALSE;
integer wasPhysical = FALSE;

// Furniture 2.0 settings.
integer FURNITURE_CHANNEL;
integer furnitureIsAlwaysVisible = TRUE;
integer objectIsMute = TRUE;
integer objectNameTagIsVisible = TRUE;
string objectGroup = "";
key lockedAvatar = NULL_KEY;
integer menuState = 0;
list targets = [];

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

handleMenu()
{
    if(menuState == 0)
    {
        string msg = "Welcome to your IT furniture!\n";
        list buttons = [];
        if(storedobject)
        {
            if(lockedAvatar)
            {
                msg += "This furniture is currently locked to secondlife:///app/agent/" + (string)lockedAvatar + "/about.\n \n";
                buttons += [" ", "UNLOCK", " "];
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
                msg += "This furniture is currently locked to secondlife:///app/agent/" + (string)lockedAvatar + "/about.\n \n";
                buttons += [" ", "UNLOCK", " "];
            }
            else
            {
                msg += "This furniture is currently ready to capture anyone.\n \n";
                buttons += ["CAPTURE", " ",  " "];
            }
        }

        msg += " ▶ This furniture is named " + llGetObjectName() + ".\n";
        if(objectGroup == "") msg += " ▶ This furniture is not in a group. Set a group to allow objects stored on grouped furniture to communicate.\n";
        else                  msg += " ▶ This furniture is in the \"" + objectGroup+ "\" group. Objects stored on this furniture can communicate with objects stored on other furniture in the same group.\n";
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

        buttons += [" ", " ", " "];

        if(objectIsMute)
        {
            msg += " ▶ Stored objects cannot speak in local chat.\n";
            buttons += ["CAN SPEAK"];
        }
        else
        {
            msg += " ▶ Stored objects can speak in local chat.\n";
            buttons += ["MUTE"];
        }

        if(objectNameTagIsVisible)
        {
            msg += " ▶ Stored objects have a visible nametag.";
            buttons += ["HIDE NAME"];
        }
        else
        {
            msg += " ▶ Stored objects are completely invisible.";
            buttons += ["SHOW NAME"];
        }

        if(storedobject) buttons += ["OBJ MENU"];
        else             buttons += [" "];

        llDialog(llGetOwner(), msg, orderbuttons(buttons), FURNITURE_CHANNEL);
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
        llDialog(llGetOwner(), msg, orderbuttons(buttons), FURNITURE_CHANNEL);
    }
    else if(menuState == 2)
    {
        llTextBox(llGetOwner(), "Enter a new name for this furniture.", FURNITURE_CHANNEL);
    }
    else if(menuState == 3)
    {
        llTextBox(llGetOwner(), "Enter a new group for this furniture. Objects stored on this furniture will be able to talk to objects stored on other furniture with the same group. Enter none to remove the group.", FURNITURE_CHANNEL);
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
        objectGroup = llGetObjectDesc();
        objectGroup = llStringTrim(objectGroup, STRING_TRIM);
        llSetObjectDesc(objectGroup);
        FURNITURE_CHANNEL = ((integer)("0x"+llGetSubString((string)llGetKey(),-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFFF;
        llListen(FURNITURE_CHANNEL, "", llGetOwner(), "");
        llSetRemoteScriptAccessPin(FURNITURE_CHANNEL);
        llSetLinkAlpha(LINK_THIS, 0.0, ALL_SIDES);
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
                    llRegionSayTo(llGetOwnerKey(id), 0, "This furniture is reserved for a specific object. The owner can release this reservation by clicking the furniture.");
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
                    llRegionSayTo(llGetOwnerKey(id), 0, "This furniture is reserved for a specific object. The owner can release this reservation by clicking the furniture.");
                    return;
                }

                // Set the uuid of who to capture.
                capturing = (key)llDeleteSubString(m, 0, llStringLength("putdown"));

                // Then do it.
                integer option = 4 | 1;
                if(!objectNameTagIsVisible) option = 4 | 2;
                llRezAtRoot("ball", llGetPos(), ZERO_VECTOR, ZERO_ROTATION, option);
                waitingForRez = TRUE;
                llSetTimerEvent(15.0);
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
                if(m == "CAPTURE")
                {
                    menuState = 1;
                    handleMenu();
                }
                else if(m == "RELEASE")
                {
                    llRegionSayTo(storedobject, MANTRA_CHANNEL, "unsit");
                    storedobject = NULL_KEY;
                    storedavatar = NULL_KEY;
                    handleMenu();
                }
                else if(m == "LOCK")
                {
                    lockedAvatar = storedavatar;
                    handleMenu();
                }
                else if(m == "UNLOCK")
                {
                    lockedAvatar = NULL_KEY;
                    llSensorRemove();
                    handleMenu();
                }
                else if(m == "RENAME")
                {
                    menuState = 2;
                    handleMenu();
                }
                else if(m == "GROUP")
                {
                    menuState = 3;
                    handleMenu();
                }
                else if(m == "INVISIBLE" || m == "VISIBLE")
                {
                    furnitureIsAlwaysVisible = !furnitureIsAlwaysVisible;
                    if(storedobject == NULL_KEY) llSetLinkAlpha(LINK_ALL_OTHERS, (float)furnitureIsAlwaysVisible, ALL_SIDES);
                    handleMenu();
                }
                else if(m == "CAN SPEAK" || m == "MUTE")
                {
                    objectIsMute = !objectIsMute;
                    handleMenu();
                }
                else if(m == "SHOW NAME" || m == "HIDE NAME")
                {
                    objectNameTagIsVisible = !objectNameTagIsVisible;
                    handleMenu();
                }
                else if(m == "OBJ MENU")
                {
                    string prefix = llGetSubString(llGetUsername(storedavatar), 0, 1);
                    llRegionSayTo(storedobject, 5, prefix + "menu");
                }
                else if(m == " ")
                {
                    handleMenu();
                }
            }
            else if(menuState == 1)
            {
                if(m == " ")
                {
                    handleMenu();
                }
                else
                {
                    capturing = llList2Key(targets, ((((integer)m)-1)*2)+1);
                    llOwnerSay("Capturing secondlife:///app/agent/" + (string)capturing + "/about...");
                    integer option = 4 | 1;
                    if(!objectNameTagIsVisible) option = 4 | 2;
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
                handleMenu();
            }
            else if(menuState == 3)
            {
                m = llStringTrim(m, STRING_TRIM);
                if(llToLower(m) == "none") m = "";
                llSetObjectDesc(m);
                objectGroup = m;
                menuState = 0;
                handleMenu();
            }
        }
    }

    touch_start(integer num_detected)
    {
        if(llDetectedKey(0) == llGetOwner())
        {
            menuState = 0;
            handleMenu();
        }
        else
        {
            llMessageLinked(LINK_ALL_OTHERS, 90005, "", llDetectedKey(0));
        }
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
        llRegionSayTo(id, MANTRA_CHANNEL, "sit " + (string)capturing + "|||" + llGetObjectName() + "|||NULL");
        if(!furnitureIsAlwaysVisible) llSetLinkAlpha(LINK_ALL_OTHERS, 1.0, ALL_SIDES);
        llSetTimerEvent(15.0);
    }

    // The sensor timer is used to look for the locked avatar.
    no_sensor()
    {
        // Quit if we already have the object stored.
        if(storedobject) return;

        // Quit if the object isn't here.
        if(llGetAgentSize(lockedAvatar) == ZERO_VECTOR) return;

        // Otherwise, go for it!
        capturing = lockedAvatar;
        integer option = 4 | 1;
        if(!objectNameTagIsVisible) option = 4 | 2;
        llRezAtRoot("ball", llGetPos(), ZERO_VECTOR, ZERO_ROTATION, option);
        waitingForRez = TRUE;
        llSetTimerEvent(15.0);
        llSensorRemove();
    }

    // The basic timer is used to track the presence of the object. Once it's gone, we clear up our state.
    timer()
    {
        llSetTimerEvent(0.0);
        // It is also used to track stalled rezzes, because SL is an amazing piece of technology that always works perfectly.
        if(waitingForRez)
        {
            // If the avatar we were rezzing for is still around, just try again.
            if(llGetAgentSize(capturing) != ZERO_VECTOR)
            {
                integer option = 4 | 1;
                if(!objectNameTagIsVisible) option = 4 | 2;
                llRezAtRoot("ball", llGetPos(), ZERO_VECTOR, ZERO_ROTATION, option);
                waitingForRez = TRUE;
                llSetTimerEvent(15.0);
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
        llSetTimerEvent(5.0);
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == X_API_DUMP_SETTINGS)
        {
            string packed = "" +
                (string)furnitureIsAlwaysVisible + "\n" +
                (string)objectIsMute + "\n" +
                (string)objectNameTagIsVisible + "\n" +
                (string)lockedAvatar + "\n" +
                llStringToBase64(objectGroup);
            llMessageLinked(LINK_THIS, X_API_DUMP_SETTINGS_R, packed, NULL_KEY);
        }
        else if(num == X_API_RESTORE_SETTINGS)
        {
            list data = llParseString2List(str, ["\n"], []);
            furnitureIsAlwaysVisible = (integer)llList2String(data, 0);
            objectIsMute = (integer)llList2String(data, 1);
            objectNameTagIsVisible = (integer)llList2String(data, 2);
            lockedAvatar = (key)llList2String(data, 3);
            objectGroup = llBase64ToString(llList2String(data, 4));
            if(lockedAvatar) sensortimer(5.0);
            llMessageLinked(LINK_THIS, X_API_RESTORE_SETTINGS_R, "OK", NULL_KEY);
        }
    }
}
