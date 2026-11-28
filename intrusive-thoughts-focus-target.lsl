float dist = 0.5;
integer lastpoint = -1;
integer point = -1;
float adjPos = 0.05;
float adjRot = 2.5;
integer locked = FALSE;
integer previewing = FALSE;
integer singleMode = TRUE;
rotation mode0Rot = ZERO_ROTATION;
vector mode0Pos = ZERO_VECTOR;
float mode0Dist = 0.5;
rotation mode1Rot = ZERO_ROTATION;
vector mode1Pos = ZERO_VECTOR;
float mode1Dist = 0.5;
integer activeMode = 0;
string baseName = "";

integer sitting()
{
    return ((llGetAgentInfo(llGetOwner()) & AGENT_SITTING) != 0) || (llList2Key(llGetObjectDetails(llGetOwner(), [OBJECT_ROOT]), 0) != llGetOwner());
}

applystored()
{
    if(singleMode) return;
    integer sit = sitting();
    if(sit && activeMode == 0)
    {
        activeMode = 1;
        llSetRot(mode1Rot);
        llSetPos(mode1Pos);
        dist = mode1Dist;
        llSetObjectName(baseName + ";sit");
    }
    if(!sit && activeMode == 1)
    {
        activeMode = 0;
        llSetRot(mode0Rot);
        llSetPos(mode0Pos);
        dist = mode0Dist;
        llSetObjectName(baseName + ";stand");
    }
}

updatestored()
{
    if(singleMode)
    {
        mode0Pos = llGetLocalPos();
        mode0Rot = llGetLocalRot();
        mode0Dist = dist;
        mode1Pos = mode0Pos;
        mode1Rot = mode0Rot;
        mode1Dist = dist;
    }
    else
    {
        if(activeMode == 0)
        {
            mode0Pos = llGetLocalPos();
            mode0Rot = llGetLocalRot();
            mode0Dist = dist;
        }
        else
        {
            mode1Pos = llGetLocalPos();
            mode1Rot = llGetLocalRot();
            mode1Dist = dist;
        }
    }
}

update()
{
    vector curScale = llGetScale();
    if(curScale.x != curScale.y || curScale.y != curScale.z || curScale.x != curScale.z) llSetScale(<curScale.x, curScale.x, curScale.x>);
    vector x = llVecNorm(<0, 0, 1> * llGetLocalRot() * llGetRot());
    string desc = (string)x.x + "/" + (string)x.y + "/" +(string)x.z;
    llSetObjectDesc("setcam_focus:" + (string)llGetKey() + ";" + (string)dist + ";" + desc + "=force");
}

preview()
{
    llOwnerSay("@" + llGetObjectDesc());
}

adjustScale(float delta)
{
    dist += delta;
    if(dist < 0.01) dist = 0.01;
}

adjustRotation(vector delta)
{
    rotation rot = llEuler2Rot(delta * DEG_TO_RAD);
    llSetRot(llGetLocalRot() * rot);
}

adjustPosition(vector delta)
{
    llSetPos(llGetLocalPos() + delta);
}

integer startswith(string haystack, string needle)
{
    return llDeleteSubString(haystack, llStringLength(needle), 0x7FFFFFF0) == needle;
}

start()
{
    point = llGetAttached();
    if(point == 0)
    {
        llOwnerSay("Don't rez me. Wear me!");
        return;
    }

    // Greet the wearer.
    if(!startswith(llGetObjectName(), "Intrusive Thoughts Focus Target")) 
    {
        llOwnerSay("Any worn object with the name \"" + llGetObjectName() +"\" or \"<prefix> " + llGetObjectName() + "\" will look at me if their camera is restricted. Click [secondlife:///app/chat/5/" + llEscapeURL((string)llGetKey() + "menu") + " here] or click me to configure me.");
    }
    else
    {
        llOwnerSay("Any IT Slave/Object will look at me if their camera is restricted. Take me off and rename me to something to make a specific object look at me. Click [secondlife:///app/chat/5/" + llEscapeURL((string)llGetKey() + "menu") + " here] or click me to configure me.");
    }

    // If it has been worn to a new point, reset position for ease of use.
    if(point != lastpoint && point != 0)
    {
        lastpoint = point;
        llSetPos(ZERO_VECTOR);
        llSetRot(llEuler2Rot(<0,90,0>*DEG_TO_RAD));
        llSetScale(<0.1, 0.1, 0.1>);
        mode0Pos = llGetLocalPos();
        mode0Rot = llGetLocalRot();
        mode0Dist = 0.5;
        mode1Pos = mode0Pos;
        mode1Rot = mode0Rot;
        mode1Dist = 0.5;
        singleMode = TRUE;
        activeMode = 0;
    }

    // Set back to fine adjustments.
    adjPos = 0.01;
    adjRot = 2.5;

    // Store the basename.
    baseName = llStringTrim(llList2String(llParseString2List(llGetObjectName(), [";"], []), 0), STRING_TRIM);

    // Update the description for slaves.
    updatestored();
    applystored();
    update();

    locked = FALSE;
    previewing = FALSE;

    // Start update loop.
    llSetTimerEvent(0.03);
}

giveMenu()
{
    string oldn = llGetObjectName();
    llSetObjectName("");
    llOwnerSay("Focus Target Menu:");
    llOwnerSay("You are seeing what the object or slave will see. Click [secondlife:///app/chat/5/" + llEscapeURL((string)llGetKey() + "preview") + " here] or wait a minute without touching the menu to stop. Click [secondlife:///app/chat/5/" + llEscapeURL((string)llGetKey() + "lock") + " here] to lock/unlock the focus target onto your avatar.");
    llOwnerSay(" ");
    llOwnerSay("Adjustment amount:");
    llOwnerSay("[secondlife:///app/chat/5/" + llEscapeURL((string)llGetKey() + "a0") + " Fine (1cm / 2.5°)]/[secondlife:///app/chat/5/" + llEscapeURL((string)llGetKey() + "a1") + " medium (5cm / 10°)]/[secondlife:///app/chat/5/" + llEscapeURL((string)llGetKey() + "a2") + " coarse (10cm / 25°)]");
    llOwnerSay(" ");
    llOwnerSay("Camera movement:");
    llOwnerSay("[secondlife:///app/chat/5/" + llEscapeURL((string)llGetKey() + "x-") + " X-]  [secondlife:///app/chat/5/" + llEscapeURL((string)llGetKey() + "y-") + " Y-]   [secondlife:///app/chat/5/" + llEscapeURL((string)llGetKey() + "z-") + " Z-]");
    llOwnerSay("[secondlife:///app/chat/5/" + llEscapeURL((string)llGetKey() + "x+") + " X+] [secondlife:///app/chat/5/" + llEscapeURL((string)llGetKey() + "y+") + " Y+] [secondlife:///app/chat/5/" + llEscapeURL((string)llGetKey() + "z+") + " Z+]");
    llOwnerSay(" ");
    llOwnerSay("Camera rotation:");
    llOwnerSay("[secondlife:///app/chat/5/" + llEscapeURL((string)llGetKey() + "rx-") + " X-]  [secondlife:///app/chat/5/" + llEscapeURL((string)llGetKey() + "ry-") + " Y-]   [secondlife:///app/chat/5/" + llEscapeURL((string)llGetKey() + "rz-") + " Z-]");
    llOwnerSay("[secondlife:///app/chat/5/" + llEscapeURL((string)llGetKey() + "rx+") + " X+] [secondlife:///app/chat/5/" + llEscapeURL((string)llGetKey() + "ry+") + " Y+] [secondlife:///app/chat/5/" + llEscapeURL((string)llGetKey() + "rz+") + " Z+]");
    llOwnerSay(" ");
    llOwnerSay("Camera zoom:");
    llOwnerSay("[secondlife:///app/chat/5/" + llEscapeURL((string)llGetKey() + "bigger") + " See more.]");
    llOwnerSay("[secondlife:///app/chat/5/" + llEscapeURL((string)llGetKey() + "smaller") + " See less.]");
    llOwnerSay(" ");
    llOwnerSay("Clicking any of the control links will snap your camera to the new view. Press escape when you're satisfied to reset your camera. Movement is local to the attachment point, so the controls may take some experimentation.");
    llOwnerSay(" ");
    if(singleMode)
    {
        llOwnerSay("You're in single mode. The object will have the same view whether you're sitting or standing. Click [secondlife:///app/chat/5/" + llEscapeURL((string)llGetKey() + "swap") + " here] to swap to multi mode.");
    }
    else
    {
        if(sitting()) llOwnerSay("You're in multi mode. You are currently editing the sitting view, stand up to edit the standing view. Click [secondlife:///app/chat/5/" + llEscapeURL((string)llGetKey() + "swap") + " here] to swap to single mode.");
        else          llOwnerSay("You're in multi mode. You are currently editing the standing view, sit down to edit the sitting view. Click [secondlife:///app/chat/5/" + llEscapeURL((string)llGetKey() + "swap") + " here] to swap to single mode.");
    }
    llSetObjectName(oldn);
}

default
{
    state_entry()
    {
        llListen(5, "", NULL_KEY, "");
        point = -1;
        start();
    }

    on_rez(integer start_param)
    {
        llSetTimerEvent(0.0);
        start();
    }

    listen(integer c, string n, key id, string m)
    {
        if(llGetOwnerKey(id) != llGetOwner()) return;
        if(!startswith(m, (string)llGetKey())) return;
        m = llDeleteSubString(m, 0, 35);
        llResetTime();
        previewing = TRUE;
        if(m == "menu")
        {
            giveMenu();
        }
        else if(m == "lock")
        {
            locked = !locked;
            string oldn = llGetObjectName();
            llSetObjectName("");
            if(locked) {
                llOwnerSay("Locking this focus target onto your avatar...");
                llOwnerSay("@detach=n");
            } else {
                llOwnerSay("Unlocking this focus target from your avatar...");
                llOwnerSay("@detach=y");
            }
            llSetObjectName(oldn);
        }
        else if(m == "preview")
        {
            previewing = FALSE;
        }
        else if(m == "bigger")
        {
            adjustScale(adjPos);
            updatestored();
            update();
        }
        else if(m == "smaller")
        {
            adjustScale(-adjPos);
            updatestored();
            update();
        }
        else if(m == "x+")
        {
            adjustPosition(<adjPos, 0, 0>);
            updatestored();
            update();
        }
        else if(m == "x-")
        {
            adjustPosition(<-adjPos, 0, 0>);
            updatestored();
            update();
        }
        else if(m == "y+")
        {
            adjustPosition(<0, adjPos, 0>);
            updatestored();
            update();
        }
        else if(m == "y-")
        {
            adjustPosition(<0, -adjPos, 0>);
            updatestored();
            update();
        }
        else if(m == "z+")
        {
            adjustPosition(<0, 0, adjPos>);
            updatestored();
            update();
        }
        else if(m == "z-")
        {
            adjustPosition(<0, 0, -adjPos>);
            updatestored();
            update();
        }
        else if(m == "rx+")
        {
            adjustRotation(<adjRot, 0, 0>);
            updatestored();
            update();
        }
        else if(m == "rx-")
        {
            adjustRotation(<-adjRot, 0, 0>);
            updatestored();
            update();
        }
        else if(m == "ry+")
        {
            adjustRotation(<0, adjRot, 0>);
            updatestored();
            update();
        }
        else if(m == "ry-")
        {
            adjustRotation(<0, -adjRot, 0>);
            updatestored();
            update();
        }
        else if(m == "rz+")
        {
            adjustRotation(<0, 0, adjRot>);
            updatestored();
            update();
        }
        else if(m == "rz-")
        {
            adjustRotation(<0, 0, -adjRot>);
            updatestored();
            update();
        }
        else if(m == "a0")
        {
            adjPos = 0.01;
            adjRot = 2.50;
        }
        else if(m == "a1")
        {
            adjPos = 0.05;
            adjRot = 10.0;
        }
        else if(m == "a2")
        {
            adjPos = 0.10;
            adjRot = 25.0;
        }
        else if(m == "swap")
        {
            singleMode = !singleMode;
            updatestored();
            if(singleMode) llSetObjectName(baseName);
            giveMenu();
        }
    }

    touch_start(integer num_detected)
    {
        if(llDetectedKey(0) != llGetOwner()) return;
        giveMenu();
    }

    timer()
    {
        if(previewing) preview();
        if(llGetTime() > 60.0) previewing = FALSE;
        updatestored();
        applystored();
        update();
    }
}