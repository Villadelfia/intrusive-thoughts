#include <IT/globals.lsl>
#define IMPULSE 1.6
key controller = NULL_KEY;
key objectifier = NULL_KEY;
integer muted = FALSE;
integer struggleEvents = 0;
integer struggleFailed = FALSE;

default
{
    state_entry()
    {
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
        llListen(STRUGGLE_CHANNEL, "", NULL_KEY, "");
        llListen(0, "", NULL_KEY, "");
    }

    attach(key id)
    {
        llSetTimerEvent(0.0);
        muted = FALSE;
        struggleEvents = 0;
        struggleFailed = FALSE;
        controller = NULL_KEY;
        objectifier = NULL_KEY;
        if(id)
        {
            llRegionSay(MANTRA_CHANNEL, "ctrlready " + (string)llGetOwner());
            llRegionSay(MANTRA_CHANNEL, "objready " + (string)llGetOwner());
        }
    }

    listen(integer c, string n, key id, string m)
    {
        if(c == 0)
        {
            if(id == llGetOwner())
            {
                if(llToLower(llStringTrim(m, STRING_TRIM)) == "((red))")
                {
                    llOwnerSay("Safeworded... Releasing you!");
                    llOwnerSay("@clear,detachme=force");
                }
            }

            if(controller == NULL_KEY) return;
            if(llVecDist(llList2Vector(llGetObjectDetails(id, [OBJECT_POS]), 0), llList2Vector(llGetObjectDetails(controller, [OBJECT_POS]), 0)) <= 20.0) return;
            string prefix = "";
            if(id != llGetOwnerKey(id))
            {
                string group = "";
                if((string)llGetObjectDetails(id, [OBJECT_OWNER]) == NULL_KEY) group = "&groupowned=true";
                vector pos = llList2Vector(llGetObjectDetails(id, [OBJECT_POS]), 0);
                string slurl = llEscapeURL(llGetRegionName()) + "/"+ (string)((integer)pos.x) + "/"+ (string)((integer)pos.y) + "/"+ (string)(llCeil(pos.z));
                prefix = "[secondlife:///app/objectim/" + (string)id +
                        "?name=" + llEscapeURL(n) +
                        "&owner=" + (string)llGetOwnerKey(id) +
                        group +
                        "&slurl=" + llEscapeURL(slurl) + " " + n + "]";
            }
            else
            {
                prefix = "secondlife:///app/agent/" + (string)id + "/about";
            }

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
            llRegionSayTo(controller, 0, prefix + m);
        }
        else if(c == MANTRA_CHANNEL)
        {
            if(m == "takectrl" && controller == NULL_KEY && objectifier == NULL_KEY)
            {
                controller = llGetOwnerKey(id);
                muted = FALSE;
                llRequestPermissions(llGetOwner(), PERMISSION_TAKE_CONTROLS);
            }
            else if(startswith(m, "sit") && controller == NULL_KEY && objectifier == NULL_KEY)
            {
                objectifier = id;
            }
            else if(m == "pingctrl")
            {
                if(controller == NULL_KEY && objectifier == NULL_KEY) llRegionSayTo(llGetOwnerKey(id), MANTRA_CHANNEL, "ctrlready " + (string)llGetOwner());
                else                                                  llRegionSayTo(llGetOwnerKey(id), MANTRA_CHANNEL, "ctrlbusy " + (string)llGetOwner());
            }
            else if(m == "objping")
            {
                if(controller == NULL_KEY && objectifier == NULL_KEY) llRegionSayTo(id, MANTRA_CHANNEL, "objready " + (string)llGetOwner());
                else                                                  llRegionSayTo(id, MANTRA_CHANNEL, "objbusy " + (string)llGetOwner());
            }

            id = llGetOwnerKey(id);
            if(id != controller) return;

            if(m == "releasectrl")
            {
                llSetTimerEvent(0.0);
                llReleaseControls();
                llOwnerSay("You're free from secondlife:///app/agent/" + (string)controller + "/about's control.");
                llRegionSayTo(controller, STRUGGLE_CHANNEL, "released|" + (string)llGetOwner());
                llRegionSayTo(controller, MANTRA_CHANNEL, "ctrlended " + (string)llGetOwner());
                llSleep(2.5);
                llOwnerSay("@clear,detachme=force");
            }
            else if(m == "ctrlstand")
            {
                llOwnerSay("@unsit=force,unsit=y");
            }
            else if(m == "ctrlmute")
            {
                if(muted)
                {
                    muted = FALSE;
                    llOwnerSay("@sendchat=y,sendchannel=y");
                    ownersay(id, "secondlife:///app/agent/" + (string)llGetOwner() + "/about can speak again.");
                }
                else
                {
                    muted = TRUE;
                    llOwnerSay("@sendchat=n,sendchannel=n");
                    ownersay(id, "secondlife:///app/agent/" + (string)llGetOwner() + "/about can no longer speak.");
                }
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
                if(llVecDist(llGetPos(), llList2Vector(llGetObjectDetails(controller, [OBJECT_POS]), 0)) > 20.0) llRegionSayTo(controller, 0, prefix + m);
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
        else if(c == STRUGGLE_CHANNEL)
        {
            id = llGetOwnerKey(id);
            if(id != controller) return;
            if(startswith(m, "struggle_fail"))
            {
                list params = llParseString2List(m, ["|"], []);
                m = llList2String(llParseString2List(m, ["|"], []), -1);
                if(llGetListLength(params) == 2 || (llGetListLength(params) == 3 && (key)llList2String(params, 1) == llGetOwner()))
                {
                    llSetObjectName("");
                    llOwnerSay(m);
                    llReleaseControls();
                    struggleFailed = TRUE;
                }
            }
            else if(startswith(m, "struggle_success"))
            {
                list params = llParseString2List(m, ["|"], []);
                m = llList2String(llParseString2List(m, ["|"], []), -1);
                if(llGetListLength(params) == 2 || (llGetListLength(params) == 3 && (key)llList2String(params, 1) == llGetOwner()))
                {
                    llSetTimerEvent(0.0);
                    llReleaseControls();
                    llOwnerSay("You're free from secondlife:///app/agent/" + (string)controller + "/about's control.");
                    llSetObjectName("");
                    llOwnerSay(m);
                    llRegionSayTo(controller, STRUGGLE_CHANNEL, "released|" + (string)llGetOwner());
                    llRegionSayTo(controller, MANTRA_CHANNEL, "ctrlended " + (string)llGetOwner());
                    llSleep(2.5);
                    llOwnerSay("@clear,detachme=force");
                }
            }
        }
    }

    control(key id, integer level, integer edge)
    {
        integer start = level & edge;
        if(start) struggleEvents++;
    }

    run_time_permissions(integer perm)
    {
        if(perm & PERMISSION_TAKE_CONTROLS)
        {
            llOwnerSay("You're now being possessed by secondlife:///app/agent/" + (string)controller + "/about.");
            llOwnerSay("@detach=n,interact=n,tplocal=n,tplm=n,tploc=n,setcam_mouselook=n");
            llRegionSayTo(controller, MANTRA_CHANNEL, "ctrlstarted " + (string)llGetOwner());
            llRegionSayTo(controller, STRUGGLE_CHANNEL, "captured|" + (string)llGetOwner() + "|possess");
            llTakeControls(CONTROL_FWD | CONTROL_BACK | CONTROL_LEFT | CONTROL_RIGHT | CONTROL_ROT_LEFT | CONTROL_ROT_RIGHT | CONTROL_UP | CONTROL_DOWN | CONTROL_LBUTTON | CONTROL_ML_LBUTTON, TRUE, FALSE);
            llSetTimerEvent(0.5);
        }
        else
        {
            llRegionSayTo(controller, MANTRA_CHANNEL, "ctrlended " + (string)llGetOwner());
            llSleep(2.5);
            llOwnerSay("@clear,detachme=force");
        }
    }

    timer()
    {
        if(struggleEvents > 0 && struggleFailed == FALSE)
        {
            llRegionSayTo(objectifier, STRUGGLE_CHANNEL, "struggle_count|" + (string)llGetOwner() + "|" + (string)struggleEvents);
            struggleEvents = 0;
        }

        if(llGetAgentSize(controller) == ZERO_VECTOR)
        {
            llOwnerSay("You're free from secondlife:///app/agent/" + (string)controller + "/about's control.");
            llReleaseControls();
            llOwnerSay("@clear,detachme=force");
        }
    }
}
