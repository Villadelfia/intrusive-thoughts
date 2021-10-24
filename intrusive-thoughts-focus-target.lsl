vector angleVector = <0,0,1>;
integer lastpoint = -1;
integer point = -1;
float adjPos = 0.05;
float adjRot = 2.5;

update()
{
    vector curScale = llGetScale();
    if(curScale.x != curScale.y || curScale.y != curScale.z || curScale.x != curScale.z) llSetScale(<curScale.x, curScale.x, curScale.x>);
    vector x = llVecNorm(angleVector * llGetLocalRot());
    string desc = (string)x.x + "/" + (string)x.y + "/" +(string)x.z;
    llSetObjectDesc(desc);
}

updateVector()
{
    switch(point)
    {
        case 1:
        case 18:
        case 19:
        case 42:
        {
            angleVector = <-1,0,0>;
            break;
        }
        case 20:
        case 21:
        case 41:
        {
            angleVector = <1,0,0>;
            break;
        }
        case 6:
        case 9:
        {
            angleVector = <0,1,0>;
            break;
        }
        default:
        {
            angleVector = <0,0,1>;
            break;
        }
    }
}

preview()
{
    llOwnerSay("@setcam_focus:" + (string)llGetKey() + ";;" + llGetObjectDesc() + "=force");
}

adjustScale(float delta)
{
    vector curScale = llGetScale();
    if(curScale.x != curScale.y || curScale.y != curScale.z || curScale.x != curScale.z) llSetScale(<curScale.x, curScale.x, curScale.x>);
    float scale = curScale.x;
    if(scale == 0.01) scale = 0.0;
    scale += delta;
    if(scale < 0.01) scale = 0.01;
    if(scale > 64.0) scale = 64.0;
    llSetScale(<scale, scale, scale>);
}

adjustRotation(vector delta)
{
    rotation rot = llEuler2Rot(delta *= DEG_TO_RAD);
    llSetRot(rot * llGetLocalRot());
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
    if(!startswith(llGetObjectName(), "Intrusive Thoughts Focus Target")) llOwnerSay("Any worn object with the name \"" + llGetObjectName() +"\" or \"<prefix> " + llGetObjectName() + "\" will look at me if their camera is restricted. Click [secondlife:///app/chat/5/" + llEscapeURL((string)llGetKey() + "menu") + " here] to configure me.");
    else                                                                  llOwnerSay("Any IT Slave/Object will look at me if their camera is restricted. Take me off and rename me to something to make a specific object look at me. Click [secondlife:///app/chat/5/" + llEscapeURL((string)llGetKey() + "menu") + " here] to configure me.");

    // Make sure we're a cube.
    vector curScale = llGetScale();
    if(curScale.x != curScale.y || curScale.y != curScale.z || curScale.x != curScale.z) llSetScale(<curScale.x, curScale.x, curScale.x>);

    // If it has been worn to a new point, reset position for ease of use.
    point = llGetAttached();
    if(point != lastpoint && point != 0)
    {
        lastpoint = point;
        llSetPos(ZERO_VECTOR);
        llSetRot(ZERO_ROTATION);
        llSetScale(<0.25, 0.25, 0.25>);
    }

    // Set back to fine adjustments.
    adjPos = 0.01;
    adjRot = 2.5;

    // Set the angle vector, then update the description for slaves.
    updateVector();
    update();

    // Start update loop.
    llSetTimerEvent(0.5);
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
        else if(m == "preview")
        {
            preview();
        }
        else if(m == "bigger")
        {
            adjustScale(0.025);
            update();
            preview();
        }
        else if(m == "smaller")
        {
            adjustScale(-0.025);
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

    timer()
    {
        update();
    }
}