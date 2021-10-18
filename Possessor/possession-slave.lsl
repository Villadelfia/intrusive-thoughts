#include <IT/globals.lsl>
#define IMPULSE 1.6
key controller = NULL_KEY;

default
{
    state_entry()
    {
        llRegionSay(MANTRA_CHANNEL, "ctrlready " + (string)llGetOwner());
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
    }

    on_rez(integer start_param)
    {
        llResetScript();
    }

    listen(integer c, string n, key id, string m)
    {
        id = llGetOwnerKey(id);
        if(m == "takectrl" && controller == NULL_KEY)
        {
            controller = id;
            llRequestPermissions(llGetOwner(), PERMISSION_TAKE_CONTROLS);
        }
        else if(m == "pingctrl")
        {
            if(controller == NULL_KEY) llRegionSayTo(id, MANTRA_CHANNEL, "ctrlready " + (string)llGetOwner());
            else                       llRegionSayTo(id, MANTRA_CHANNEL, "ctrlbusy " + (string)llGetOwner());
        }

        if(id != controller) return;

        if(m == "releasectrl")
        {
            llSetTimerEvent(0.0);
            llReleaseControls();
            llOwnerSay("You're free from secondlife:///app/agent/" + (string)controller + "/about's control.");
            llRegionSayTo(controller, MANTRA_CHANNEL, "ctrlended " + (string)llGetOwner());
            llSleep(2.5);
            llOwnerSay("@clear,detachme=force");
        }
        else if(m == "ctrlstand")
        {
            llOwnerSay("@unsit=force,unsit=y");
        }
        else if(startswith(m, "ctrlsit"))
        {
            m = llList2String(llParseString2List(m, [" "], []), 1);
            if(llGetAgentInfo(llGetOwner()) & AGENT_SITTING)
            {
                llOwnerSay("@unsit=force,unsit=y");
                llSleep(1.0);
            }
            llOwnerSay("@sit:" + m + "=force,unsit=n");
        }
        else if(startswith(m, "ctrlsay"))
        {
            m = llDeleteSubString(m, 0, llStringLength("ctrlsay"));
            string prefix = "secondlife:///app/agent/" + (string)llGetOwner() + "/about";
            if(startswith(m, "/me"))
            {
                prefix = "/me " + prefix;
                m = llDeleteSubString(m, 0, 2);
            }
            else
            {
                prefix += ": ";
            }
            llSetObjectName("");
            llSay(0, prefix + m);
        }
        else if(startswith(m, "ctrl"))
        {
            m = llList2String(llParseString2List(m, [" "], []), 1);
            vector v;
            if(contains(m, "f")) v.x += IMPULSE;
            if(contains(m, "b")) v.x -= IMPULSE;
            if(contains(m, "l")) v.y += IMPULSE;
            if(contains(m, "r")) v.y -= IMPULSE;
            if(contains(m, "u")) v.z  = IMPULSE*10;
            else                 v.z  = 0.1;
            if(contains(m, "r") || contains(m, "l"))
            {
                vector startpos = llGetPos();
                rotation rot = llGetRootRotation();
                vector endpos;
                if(contains(m, "l")) endpos = startpos + (<1.0,  1.0, 0.0> * rot) * 3;
                if(contains(m, "r")) endpos = startpos + (<1.0, -1.0, 0.0> * rot) * 3;
                vector point = endpos - llGetPos();
                llOwnerSay("@setrot:" + (string)llAtan2(point.x, point.y) + "=force");
            }
            llApplyImpulse(v, TRUE);
        }
    }

    run_time_permissions(integer perm)
    {
        if(perm & PERMISSION_TAKE_CONTROLS)
        {
            llOwnerSay("You're now being possessed by secondlife:///app/agent/" + (string)controller + "/about.");
            llOwnerSay("@detach=n,interact=n,tplocal=n,tplm=n,tploc=n");
            llRegionSayTo(controller, MANTRA_CHANNEL, "ctrlstarted " + (string)llGetOwner());
            llTakeControls(0, FALSE, FALSE);
            llSetTimerEvent(0.5);
        }
        else
        {
            llRegionSayTo(controller, MANTRA_CHANNEL, "ctrlended " + (string)llGetOwner());
        }
    }

    timer()
    {
        if(llGetAgentSize(controller) == ZERO_VECTOR)
        {
            llOwnerSay("You're free from secondlife:///app/agent/" + (string)controller + "/about's control.");
            llReleaseControls();
            llOwnerSay("@clear,detachme=force");
        }
    }
}