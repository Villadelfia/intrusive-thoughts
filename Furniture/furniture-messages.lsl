#include <IT/globals.lsl>
integer FURNITURE_CHANNEL;

scanLinkSet(integer canAdd)
{
    list data = llParseString2List(llLinksetDataRead("link_texture_data"), [";"], []);
    integer n = llGetObjectPrimCount(llGetKey());
    integer i;
    list details;
    string linkkey;
    if(!canAdd) jump noadd;
    for(i = 1; i <= n; i++)
    {
        // We never alter our prim.
        linkkey = llGetObjectLinkKey(llGetKey(), i);
        if(linkkey == llGetObjectLinkKey(llGetKey(), LINK_THIS)) jump skip;

        // We need lots of details...
        details = llGetLinkPrimitiveParams(i, [
            PRIM_NAME, 
            PRIM_DESC
        ]);

        // We skip links labeled nohide in description or name.
        string name = llList2String(details, 0);
        string desc = llList2String(details, 1);
        if(llToLower(name) == "nohide" || llToLower(desc) == "nohide") jump skip;

        // Check if a description matched a stored link.
        integer idx = llListFindList(data, [desc]);
        if(idx != -1 && llStringLength(desc) == 36)
        {
            data = llListReplaceList(data, [(string)linkkey, (string)i], idx, idx+1);
            jump skip;
        }

        // Otherwise, we have stuff to add to the data!
        llSetLinkPrimitiveParamsFast(i, [PRIM_DESC, (string)linkkey]);
        list add = [(string)linkkey, (string)i];
        integer j;
        for(j = 0; j < 8; j++)
        {
            details = llGetLinkPrimitiveParams(i, [
                PRIM_ALPHA_MODE, j,
                PRIM_COLOR, j,
                PRIM_GLTF_BASE_COLOR, j
            ]);

            // Alpha mode + mask value + alpha blend.
            add += [(string)llList2Integer(details, 0)];
            add += [(string)llList2Integer(details, 1)];
            add += [(string)llList2Float(details, 3)];

            // GLTF alpha mode + mask value + alpha blend + tint color.
            add += [(string)llList2Integer(details, 10)];
            add += [(string)llList2Float(details, 11)];
            add += [(string)llList2Float(details, 9)];
            add += [(string)llList2Vector(details, 8)];
        }
        data += add;
        @skip;
    }

    // Now we check for missing links and remove them.
    @noadd;
    n = llGetListLength(data);
    for(i = n - 58; i >= 0; i -= 58)
    {
        key root = llList2Key(llGetObjectDetails((key)llList2String(data, i), [OBJECT_ROOT]), 0);
        if(root != llGetLinkKey(LINK_ROOT)) data = llDeleteSubList(data, i, i+57);
    }

    // And save.
    llLinksetDataWrite("link_texture_data", llDumpList2String(data, ";"));
}


doShow() 
{
    scanLinkSet(FALSE);
    list data = llParseString2List(llLinksetDataRead("link_texture_data"), [";"], []);
    integer n = llGetListLength(data);
    integer i;
    integer j;
    integer target;
    for(i = 0; i < n; i += 58)
    {
        target = (integer)llList2String(data, i+1);
        for(j = 0; j < 8; j++)
        {
            llSetLinkPrimitiveParamsFast(target,[PRIM_ALPHA_MODE, j, (integer)llList2String(data, (i+2)+(j*6)+0), (integer)llList2String(data, (i+2)+(j*7)+1)]);
            llSetLinkAlpha(target, (float)llList2String(data, (i+2)+(j*7)+2), j);
            llSetLinkGLTFOverrides(target, j, [
                OVERRIDE_GLTF_BASE_ALPHA_MODE, (integer)llList2String(data, (i+2)+(j*7)+3), 
                OVERRIDE_GLTF_BASE_ALPHA_MASK, (float)llList2String(data, (i+2)+(j*7)+4),
                OVERRIDE_GLTF_BASE_ALPHA, (float)llList2String(data, (i+2)+(j*7)+5),
                OVERRIDE_GLTF_BASE_COLOR_FACTOR, (vector)llList2String(data, (i+2)+(j*7)+6)
            ]);
        }
    }
}

doHide()
{
    scanLinkSet(TRUE);
    list data = llParseString2List(llLinksetDataRead("link_texture_data"), [";"], []);
    integer n = llGetListLength(data);
    integer i;
    for(i = 0; i < n; i += 58)
    {
        llSetLinkAlpha((integer)llList2String(data, i+1), 0.0, ALL_SIDES);
        llSetLinkGLTFOverrides((integer)llList2String(data, i+1), ALL_SIDES, [OVERRIDE_GLTF_BASE_ALPHA_MODE, PRIM_GLTF_ALPHA_MODE_BLEND, OVERRIDE_GLTF_BASE_ALPHA, 0.0]);
    }
}

default
{
    state_entry()
    {
        FURNITURE_CHANNEL = ((integer)("0x"+llGetSubString((string)llGetKey(),-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFFF;
    }
    
    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == FM_CHANNEL) 
        {
            FURNITURE_CHANNEL = (integer)str;
        }
        else if(num == FM_RELEASE) 
        {
            llRegionSayTo(id, 0, "Your capture timer is up. You may now, and at any later time, type /5release or click [secondlife:///app/chat/5/release here] to release yourself.");
        }
        else if(num == FD_OWNER) 
        {
            llDialog(id, "Sorry, this furniture is set to owner only.", ["OK"], -3001920);
        }
        else if(num == FD_CAPTURER) 
        {
            llDialog(id, "Sorry, only the person who captured this object can access the menu.", ["OK"], -3001920);
        }
        else if(num == FD_NAME)
        {
            llTextBox(id, "Enter a new name for this furniture.", FURNITURE_CHANNEL);
        }
        else if(num == FD_GROUP)
        {
            llTextBox(id, "Enter a new group for this furniture. Objects stored on this furniture will be able to talk to objects stored on other furniture with the same group. Enter none to remove the group.", FURNITURE_CHANNEL);
        }
        else if(num == FD_TIME)
        {
            llTextBox(id, "Enter a time limit for the capture.\n\nIf you want a set time, enter one number in minutes.\nIf you want a minimum and a maximum, enter two numbers separated by a space, both in minutes.\nIf you want to have the capture indefinite, enter NONE.", FURNITURE_CHANNEL);
        }
        else if(num == FM_WELCOME)
        {
            llOwnerSay("Welcome to your " + llGetObjectName() + ".\n\nFirst, I need to link up with another object. Drop the script I am giving you right now into that object and follow the instructions.");
            llGiveInventory(llGetOwner(), "IT Furniture Linking Script");
            llPreloadSound("dec9fb53-0fef-29ae-a21d-b3047525d312");
            llSetStatus(STATUS_PHANTOM, TRUE);
        }
        else if(num == FM_LINK)
        {
            llOwnerSay("I am linking to " + llList2String(llGetObjectDetails(id, [OBJECT_NAME]), 0) + ". Please grant me the linking permission to complete setup.");
        }
        else if(num == FM_PLEASE_REZ)
        {
            llOwnerSay("Please rez me instead of wearing me.");
        }
        else if(num == FM_NO_TEMP)
        {
            llOwnerSay("Can't link to temp rezzed objects!");
        }
        else if(num == FM_NO_PERM)
        {
            llOwnerSay("You must grant the linking permission to continue.");
        }
        else if(num == FM_G2G)
        {
            llOwnerSay("Alright, I'm good to go. You can now store objects in me via the IT Master HUD. Click me for more options.");
        }
        else if(num == FM_REINIT)
        {
            llOwnerSay("Fresh rez detected... Reinitializing.");
        }
        else if(num == FM_LOCK1)
        {
            if((key)str != NULL_KEY) llRegionSayTo(llGetOwnerKey(id), 0, "The stored object is locked to this furniture. The owner can unlock it by clicking the furniture.");
            else                     llRegionSayTo(llGetOwnerKey(id), 0, "This furniture is reserved for a specific object. The owner can release this reservation by clicking the furniture.");
        }
        else if(num == FM_LOCK2)
        {
            llRegionSayTo(llGetOwnerKey(id), 0, "This furniture is reserved for a specific object. You can release this reservation by clicking the furniture.");
        }
        else if(num == FM_CAPTURING)
        {
            llRegionSayTo(llGetOwnerKey(id), 0,"Capturing secondlife:///app/agent/" + str + "/about...");
        }
        else if(num == FM_MAINMENU)
        {
            string msg = "";
            list buttons = [];
            list tokens = llParseStringKeepNulls(str, ["|||"], []);
            key storedobject = (key)llList2String(tokens, 0);
            key lockedAvatar = (key)llList2String(tokens, 1);
            integer lockedDeadlock = (integer)llList2String(tokens, 2);
            integer canUnlock = (integer)llList2String(tokens, 3);
            integer timerMin = (integer)llList2String(tokens, 4);
            integer timerMax = (integer)llList2String(tokens, 5);
            key storedavatar = (key)llList2String(tokens, 6);
            integer ownerOnly = (integer)llList2String(tokens, 7);
            string objectGroup = llList2String(tokens, 8);
            integer furnitureIsAlwaysVisible = (integer)llList2String(tokens, 9);
            integer objectIsMute = (integer)llList2String(tokens, 10);
            integer animationMode = (integer)llList2String(tokens, 11);
            key camPosKey = (key)llList2String(tokens, 12);
            key camFocusKey = (key)llList2String(tokens, 13);
            integer cameraMode = (integer)llList2String(tokens, 14);

            // Top row: Capturing, releasing, locking, unlocking, deadlocking.
            if(storedobject)
            {
                if(lockedAvatar)
                {
                    if(lockedDeadlock)
                    {
                        msg += "This furniture is currently deadlocked to secondlife:///app/agent/" + (string)lockedAvatar + "/about.\n \n";
                        if(canUnlock) buttons += [" ", "UNLOCK", " "];
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
                        if(canUnlock) buttons += [" ", "UNLOCK", " "];
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
                    msg += "This furniture is currently ready to capture anyone.";
                    buttons += ["CAPTURE", " "];
                    if(id == llGetOwner()) 
                    {
                        if(ownerOnly)
                        {
                            buttons += ["PUBLIC"];
                            msg += "\n ▶ Only you can use this menu.";
                        }
                        else
                        {
                            buttons += ["OWNER"];
                            msg += "\n ▶ Everyone can use this menu.";
                        }
                    } 
                    else
                    {
                        buttons += [" "];
                    }
                    msg += "\n \n";
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
                else                                                    buttons += ["SHOW NAME"];
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
            llDialog(id, msg, orderbuttons(buttons), FURNITURE_CHANNEL);
        }
        else if(num == FM_API_SET_VISIBLE)
        {
            integer show = (integer)str;
            if(show) doShow();
            else     doHide();
        }
    }
}