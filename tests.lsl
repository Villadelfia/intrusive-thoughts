key link;
vector p0;
vector p1;

default
{
    state_entry()
    {
        llSitTarget(<0,0,0.001>,ZERO_ROTATION);
        integer i = llGetNumberOfPrims();
        while(~--i) {
            if(llGetLinkName(i) == "focus") link = llGetLinkKey(i);
        }

        p0 = llGetPos();
        p1 = llList2Vector(llGetObjectDetails(link, [OBJECT_POS]), 0);

        llOwnerSay("@setcam_unlock=n");
        llRequestPermissions(llAvatarOnSitTarget(), PERMISSION_CONTROL_CAMERA | PERMISSION_TRACK_CAMERA);
    }

    timer()
    {
        llSetCameraParams([
            CAMERA_ACTIVE, 1,
            CAMERA_POSITION, llGetPos(),
            CAMERA_POSITION_LOCKED, TRUE,
            CAMERA_POSITION_THRESHOLD, 0.0,
            CAMERA_FOCUS, llList2Vector(llGetObjectDetails((key)"24e115c3-6c17-4d28-af88-62120e8ebf9e", [OBJECT_POS]), 0),
            CAMERA_FOCUS_LOCKED, TRUE,
            CAMERA_FOCUS_THRESHOLD, 0.0
        ]);
    }

    run_time_permissions(integer perms)
    {
        llSetTimerEvent(0.1);
    }
}
