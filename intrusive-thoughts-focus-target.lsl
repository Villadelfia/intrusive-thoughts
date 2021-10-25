float dist = 0.5;
integer lastpoint = -1;
integer point = -1;
float adjPos = 0.05;
float adjRot = 2.5;

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
    // Greet the wearer.
    if(!startswith(llGetObjectName(), "Intrusive Thoughts Focus Target")) llOwnerSay("Any worn object with the name \"" + llGetObjectName() +"\" or \"<prefix> " + llGetObjectName() + "\" will look at me if their camera is restricted. Click [secondlife:///app/chat/5/" + llEscapeURL((string)llGetKey() + "menu") + " here] or click me to configure me.");
    else                                                                  llOwnerSay("Any IT Slave/Object will look at me if their camera is restricted. Take me off and rename me to something to make a specific object look at me. Click [secondlife:///app/chat/5/" + llEscapeURL((string)llGetKey() + "menu") + " here] or click me to configure me.");

    // If it has been worn to a new point, reset position for ease of use.
    point = llGetAttached();
    if(point != lastpoint && point != 0)
    {
        lastpoint = point;
        llSetPos(ZERO_VECTOR);
        llSetRot(llEuler2Rot(<0,90,0>*DEG_TO_RAD));
        llSetScale(<0.1, 0.1, 0.1>);
    }

    // Set back to fine adjustments.
    adjPos = 0.01;
    adjRot = 2.5;

    // Update the description for slaves.
    update();

    // Start update loop.
    llSetTimerEvent(0.5);
}

giveMenu()
{
    string oldn = llGetObjectName();
    llSetObjectName("");
    llOwnerSay("Focus Target Menu:");
    llOwnerSay("Click [secondlife:///app/chat/5/" + llEscapeURL((string)llGetKey() + "preview") + " here] to preview what the object or slave will see.");
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
    llSetObjectName(oldn);
}

default
{
    state_entry()
    {
        llListen(5, "", NULL_KEY, "");
        start();
    }

    on_rez(integer start_param)
    {
        llSetTimerEvent(0.0);
        start();
    }

    listen(integer c, string n, key id, string m)
    {
        if(id != llGetOwner()) return;
        if(!startswith(m, (string)llGetKey())) return;
        m = llDeleteSubString(m, 0, 35);
        if(m == "menu")
        {
            giveMenu();
        }
        else if(m == "preview")
        {
            preview();
        }
        else if(m == "bigger")
        {
            adjustScale(adjPos);
            update();
            preview();
        }
        else if(m == "smaller")
        {
            adjustScale(-adjPos);
            update();
            preview();
        }
        else if(m == "x+")
        {
            adjustPosition(<adjPos, 0, 0>);
            update();
            preview();
        }
        else if(m == "x-")
        {
            adjustPosition(<-adjPos, 0, 0>);
            update();
            preview();
        }
        else if(m == "y+")
        {
            adjustPosition(<0, adjPos, 0>);
            update();
            preview();
        }
        else if(m == "y-")
        {
            adjustPosition(<0, -adjPos, 0>);
            update();
            preview();
        }
        else if(m == "z+")
        {
            adjustPosition(<0, 0, adjPos>);
            update();
            preview();
        }
        else if(m == "z-")
        {
            adjustPosition(<0, 0, -adjPos>);
            update();
            preview();
        }
        else if(m == "rx+")
        {
            adjustRotation(<adjRot, 0, 0>);
            update();
            preview();
        }
        else if(m == "rx-")
        {
            adjustRotation(<-adjRot, 0, 0>);
            update();
            preview();
        }
        else if(m == "ry+")
        {
            adjustRotation(<0, adjRot, 0>);
            update();
            preview();
        }
        else if(m == "ry-")
        {
            adjustRotation(<0, -adjRot, 0>);
            update();
            preview();
        }
        else if(m == "rz+")
        {
            adjustRotation(<0, 0, adjRot>);
            update();
            preview();
        }
        else if(m == "rz-")
        {
            adjustRotation(<0, 0, -adjRot>);
            update();
            preview();
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
    }

    touch_start(integer num_detected)
    {
        if(llDetectedKey(0) != llGetOwner()) return;
        giveMenu();
    }

    timer()
    {
        update();
    }
}