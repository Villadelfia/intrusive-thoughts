#include <IT/globals.lsl>
integer linkct = 0;

default
{
    state_entry()
    {
        if(llGetAttached() != 0)
        {
            llOwnerSay("Please rez me, don't wear me.");
            llRequestPermissions(llGetOwner(), PERMISSION_ATTACH);
            return;
        }
        llOwnerSay("Welcome to the Intrusive Thoughts Furniture Kit. Installing this kit will enable the option for objectified avatars on IT Furniture to be forced to look in a specific direction from a specific position.");
        llOwnerSay("Once added, two new camera modes will become available: OBJECT mode and FPV mode. In OBJECT mode, the camera will look from the camera to the looking glass. In FPV it will act the same if nobody is nearby. But if someone gets within 10m it will look from the looking glass to the nearest person.");
        llOwnerSay("If you are skilled with modding, you can manually link an object called 'cam_pos' to your furniture to represent the camera, and an object called 'cam_focus' to represent the looking glass. If not, make sure you are near the already set up IT Furniture that you wish to add these camera options to and then click me to continue to the next step.");
    }

    run_time_permissions(integer perm)
    {
        llDetachFromAvatar();
    }

    touch_end(integer n)
    {
        if(llDetectedKey(0) != llGetOwner()) return;
        state state_one;
    }

    on_rez(integer s)
    {
        llResetScript();
    }
}

state state_one
{
    state_entry()
    {
        llRezAtRoot("cam_pos", llGetPos() + <0,0,0.4>, ZERO_VECTOR, ZERO_ROTATION, 0);
    }

    object_rez(key id)
    {
        state state_two;
    }

    on_rez(integer s)
    {
        llResetScript();
    }
}

state state_two
{
    state_entry()
    {
        llOwnerSay("Please edit and position the camera that is now rezzed above me to the position you want the object's camera to be looking from. You do not need to rotate it, deciding where it will be pointed at is done in the next step. Once you have done so, click me again.");
    }

    touch_end(integer n)
    {
        if(llDetectedKey(0) != llGetOwner()) return;
        state state_three;
    }

    on_rez(integer s)
    {
        llResetScript();
    }
}

state state_three
{
    state_entry()
    {
        llRezAtRoot("cam_focus", llGetPos() + <0,0,0.4>, ZERO_VECTOR, <0.66233, -0.24763, 0.24763, 0.66233>, 0);
    }

    object_rez(key id)
    {
        state state_four;
    }

    on_rez(integer s)
    {
        llResetScript();
    }
}

state state_four
{
    state_entry()
    {
        llOwnerSay("Please edit and position the looking glass that is now rezzed above me to the position you want the object's camera to be looking towards when in OBJECT mode, and where the camera will be looking *from* in the FPV mode when an avatar is nearby. Once you have done so, click me again.");
    }

    touch_end(integer n)
    {
        if(llDetectedKey(0) != llGetOwner()) return;
        state state_five;
    }

    on_rez(integer s)
    {
        llResetScript();
    }
}

state state_five
{
    state_entry()
    {
        llOwnerSay("I am now going to give you a script. Drag this script onto the furniture you want to apply these camera settings to.");
        llListen(-1443216791, "", NULL_KEY, "");
        llGiveInventory(llGetOwner(), "IT Linking Script");
    }

    listen(integer c, string n, key id, string m)
    {
        if(llGetOwnerKey(id) != llGetOwner()) return;
        state state_six;
    }

    on_rez(integer s)
    {
        llResetScript();
    }
}

state state_six
{
    state_entry()
    {
        llOwnerSay("You will now get two link permission requests. Please grant these to link the camera and looking glass to the furniture.");
        llListen(-1443216792, "", NULL_KEY, "");
    }

    listen(integer c, string n, key id, string m)
    {
        if(llGetOwnerKey(id) != llGetOwner()) return;
        linkct++;
        if(linkct == 2) state state_seven;
    }

    on_rez(integer s)
    {
        llResetScript();
    }
}

state state_seven
{
    state_entry()
    {
        llOwnerSay("You're good to go! You can now click the furniture and access the new camera modes from there. You can also manually edit the prim positions if you want to change the camera and looking glass positions later. I'm deleting myself now.");
        if(llGetOwner() != (key)IT_CREATOR) llDie();
    }

    on_rez(integer s)
    {
        llResetScript();
    }
}
