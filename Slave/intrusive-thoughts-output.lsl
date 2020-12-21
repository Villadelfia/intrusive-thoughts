#include <IT/globals.lsl>
key owner = NULL_KEY;
integer blindmute = FALSE;
integer focus = FALSE;
integer disabled = FALSE;
integer speakon = 0;
string name;

handleSelfDescribe(string message)
{
    integer firstSpace = llSubStringIndex(message, " ");
    while(firstSpace == 0)
    {
        message = llDeleteSubString(message, 0, 0);
        firstSpace = llSubStringIndex(message, " ");
    }
    string currentObjectName = llGetObjectName();
    if(firstSpace == -1)
    {
        llSetObjectName(".");
        llOwnerSay("/me " + message);
    }
    else
    {
        llSetObjectName(llGetSubString(message, 0, firstSpace-1));
        message = llDeleteSubString(message, 0, firstSpace);
        llOwnerSay("/me " + message);
    }
    llSetObjectName(currentObjectName);
}

handleSelfSay(string name, string message)
{
    string currentObjectName = llGetObjectName();
    llSetObjectName(name);
    integer bytes = getstringbytes(message);
    while(bytes > 0)
    {
        if(bytes <= 1024)
        {
            if(blindmute) llRegionSayTo(llGetOwner(), 0, message);
            else          llOwnerSay(message);
            bytes = 0;
        }
        else
        {
            integer offset = 0;
            while(bytes >= 1024) bytes = getstringbytes(llGetSubString(message, 0, --offset));
            if(blindmute) llRegionSayTo(llGetOwner(), 0, llGetSubString(message, 0, offset));
            else          llOwnerSay(message);
            message = llDeleteSubString(message, 0, offset);
            bytes = getstringbytes(message);
        }
    }
    llSetObjectName(currentObjectName);
}

handleSay(string name, string message, integer excludeSelf)
{
    list agents;
    integer l;
    vector pos;
    float range;

    if(blindmute == TRUE || excludeSelf == TRUE)
    {
        agents = llGetAgentList(AGENT_LIST_REGION, []);
        l = llGetListLength(agents)-1;
        pos = llGetPos();
        range = 20.0;

        if(startswith(message, "/whisper")) 
        {
            message = llDeleteSubString(message, 0, 7);
            range = 10.0;
        }
        else if(startswith(message, "/shout"))
        {
            message = llDeleteSubString(message, 0, 5);
            range = 100.0;
        }
 
        for(; l >= 0; --l)
        {
            vector target = llList2Vector(llGetObjectDetails(llList2Key(agents,l), [OBJECT_POS]), 0);
            if(llVecDist(target, pos) > range) agents = llDeleteSubList(agents, l, l);
        }
    }

    string currentObjectName = llGetObjectName();
    llSetObjectName(name);
    integer bytes = getstringbytes(message);
    while(bytes > 0)
    {
        if(bytes <= 1024)
        {
            if(blindmute == TRUE || excludeSelf == TRUE)
            {
                l = llGetListLength(agents)-1;
                for(; l >= 0; --l)
                {
                    key a = llList2Key(agents,l);
                    if(a == llGetOwner()) 
                    {
                        if(excludeSelf == FALSE) llRegionSayTo(a, 0, message);
                    }
                    else
                    {
                        llRegionSayTo(a, speakon, message);
                    }
                }
            }
            else
            {
                llSay(speakon, message);
                if(speakon != 0 && blindmute == TRUE) llRegionSayTo(llGetOwner(), 0, message);
                if(speakon != 0 && blindmute == FALSE) llOwnerSay(message);
            }
            bytes = 0;
        }
        else
        {
            integer offset = 0;
            while(bytes >= 1024) bytes = getstringbytes(llGetSubString(message, 0, --offset));
            if(blindmute == TRUE || excludeSelf == TRUE)
            {
                l = llGetListLength(agents)-1;
                for(; l >= 0; --l)
                {
                    key a = llList2Key(agents,l);
                    if(a == llGetOwner())
                    {
                        if(excludeSelf == FALSE) llRegionSayTo(a, 0, llGetSubString(message, 0, offset));
                    }
                    else
                    {
                        llRegionSayTo(a, speakon, llGetSubString(message, 0, offset));
                    }
                }
            }
            else
            {
                llSay(speakon, llGetSubString(message, 0, offset));
                if(speakon != 0 && blindmute == TRUE) llRegionSayTo(llGetOwner(), 0, llGetSubString(message, 0, offset));
                if(speakon != 0 && blindmute == FALSE) llOwnerSay(llGetSubString(message, 0, offset));
            }
            message = llDeleteSubString(message, 0, offset);
            bytes = getstringbytes(message);
        }
    }
    llSetObjectName(currentObjectName);
}

focusToggle()
{
    if(focus)
    {
        focus = FALSE;
        llRegionSayTo(owner, HUD_SPEAK_CHANNEL, name + " is no longer forced to look at you.");
    }
    else
    {
        focus = TRUE;
        llRegionSayTo(owner, HUD_SPEAK_CHANNEL, name + " is now forced to look at you.");
    }
    llRequestPermissions(llGetOwner(), PERMISSION_TRACK_CAMERA | PERMISSION_CONTROL_CAMERA);
}

default
{
    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == API_RESET && id == llGetOwner())                    llResetScript();
        else if(num == API_SELF_DESC && str != "")                    handleSelfDescribe(str);
        else if(num == API_FOCUS_TOGGLE)                              focusToggle();
        else if(num == API_ENABLE)                                    disabled = FALSE;
        else if(num == API_DISABLE)                                   disabled = TRUE;
        else if(num == API_SELF_SAY && str != "")                     handleSelfSay((string)id, str);
        
        if(disabled) return;

        if(num == API_SAY && str != "")                               handleSay((string)id, str, FALSE);
        else if(num == API_ONLY_OTHERS_SAY && str != "")              handleSay((string)id, str, TRUE);
    }

    changed(integer change)
    {
        if(change & CHANGED_OWNER) llResetScript();
    }

    state_entry()
    {
        owner = llList2Key(llGetObjectDetails(llGetKey(), [OBJECT_LAST_OWNER_ID]), 0);
        name = llGetDisplayName(llGetOwner());
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
        llRequestPermissions(llGetOwner(), PERMISSION_TRACK_CAMERA | PERMISSION_CONTROL_CAMERA);
    }

    run_time_permissions(integer mask)
    {
        if(llGetPermissions() & PERMISSION_CONTROL_CAMERA == 0)
        {
            llRequestPermissions(llGetOwner(), PERMISSION_TRACK_CAMERA | PERMISSION_CONTROL_CAMERA);
            return;
        }

        if(focus)
        {
            llOwnerSay("@camunlock=n,camdistmax:0=n");
            llSetTimerEvent(0.1);
        }
    }

    timer()
    {
        llSetTimerEvent(0.0);
        if(llGetPermissions() & PERMISSION_CONTROL_CAMERA == 0)
        {
            llRequestPermissions(llGetOwner(), PERMISSION_TRACK_CAMERA | PERMISSION_CONTROL_CAMERA);
            return;
        }

        if(!focus)
        {
            if(llGetPermissions() & PERMISSION_CONTROL_CAMERA) llClearCameraParams();
            llOwnerSay("@camunlock=y,camdistmax:0=y");
            return;
        }
        vector pos = llList2Vector(llGetObjectDetails(owner, [OBJECT_POS]), 0);
        if(pos != ZERO_VECTOR)
        {
            vector to = pos - llGetPos();
            llOwnerSay("@setrot:" + (string)llAtan2(to.x, to.y) + "=force");
            llClearCameraParams();
            llSetCameraParams([
                CAMERA_ACTIVE, TRUE,
                CAMERA_FOCUS, pos,
                CAMERA_FOCUS_LAG, 0.0,
                CAMERA_FOCUS_LOCKED, TRUE,
                CAMERA_POSITION, llGetPos() + <0.25, 0.0, 1.0> * llGetRot(),
                CAMERA_POSITION_LAG, 0.0,
                CAMERA_POSITION_LOCKED, TRUE
            ]);
            llSetTimerEvent(0.1);
        }
        else
        {
            llClearCameraParams();
            focus = FALSE;
            llRequestPermissions(llGetOwner(), PERMISSION_TRACK_CAMERA | PERMISSION_CONTROL_CAMERA);
        }
    }

    attach(key id)
    {
        if(id != NULL_KEY) 
        {
            llRequestPermissions(llGetOwner(), PERMISSION_TRACK_CAMERA | PERMISSION_CONTROL_CAMERA);
        }
        else
        {
            llSetTimerEvent(0.0);
        }
    }

    listen(integer c, string n, key k, string m)
    {
        if(k != owner && llGetOwnerKey(k) != owner) return;
        if(m == "RESET")
        {
            blindmute = FALSE;
            focus = FALSE;
            name = llGetDisplayName(llGetOwner());
        }
        else if(startswith(m, "NAME") && c == MANTRA_CHANNEL)
        {
            m = llDeleteSubString(m, 0, llStringLength("NAME"));
            name = m;
        }
        else if(startswith(m, "BLIND_MUTE"))
        {
            m = llDeleteSubString(m, 0, llStringLength("BLIND_MUTE"));
            if(m != "0") blindmute = TRUE;
            else         blindmute = FALSE;
        }
        else if(startswith(m, "DIALECT"))
        {
            m = llDeleteSubString(m, 0, llStringLength("DIALECT"));
            if(m != "0") speakon = SPEAK_CHANNEL;
            else         speakon = 0;
        }
        else if(m == "END")
        {
            llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "[" + llGetScriptName() + "]: " + (string)(llGetFreeMemory() / 1024.0) + "kb free.");
        }
    }
}