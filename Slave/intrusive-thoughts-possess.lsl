#include <IT/globals.lsl>
#define IMPULSE 1.6
integer muted = FALSE;
key controller = NULL_KEY;
key primary = NULL_KEY;
string name = "";
list owners = [];
integer publicaccess = FALSE;
integer groupaccess = FALSE;

release()
{
    llReleaseControls();
    llOwnerSay("@interact=y,tplocal=y,tplm=y,tploc=y,unsit=y,sendchat=y,sendchannel=y");
    controller = NULL_KEY;
    llSetTimerEvent(0.0);
}

default
{
    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == S_API_RLV_CHECK)
        {
            if(llGetPermissions() & PERMISSION_TAKE_CONTROLS) release();
        }
        else if(num == S_API_OWNERS)
        {
            owners = [];
            list new = llParseString2List(str, [","], []);
            integer n = llGetListLength(new);
            while(~--n)
            {
                owners += [(key)llList2String(new, n)];
            }
            primary = id;
        }
        else if(num == S_API_OTHER_ACCESS)
        {
            publicaccess = (integer)str;
            groupaccess = (integer)((string)id);
        }
    }

    state_entry()
    {
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
        llListen(0, "", NULL_KEY, "");
    }

    listen(integer c, string n, key id, string m)
    {
        if(c == 0)
        {
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
            llSetObjectName(slave_base);
            return;
        }

        id = llGetOwnerKey(id);
#ifndef PUBLIC_SLAVE
        if(isowner(id) == FALSE) return;
#endif
        if(m == "RESET")
        {
            name = "";
        }
        else if(startswith(m, "NAME"))
        {
            m = llDeleteSubString(m, 0, llStringLength("NAME"));
            name = m;
        }

        if(m == "takectrl" && controller == NULL_KEY)
        {
            muted = FALSE;
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
            llReleaseControls();
            llSetObjectName("");
            llOwnerSay("You're free from secondlife:///app/agent/" + (string)controller + "/about's control.");
            llRegionSayTo(controller, MANTRA_CHANNEL, "ctrlended " + (string)llGetOwner());
            llSetObjectName(slave_base);
            release();
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
                ownersay(id, "secondlife:///app/agent/" + (string)llGetOwner() + "/about can speak again.", 0);
            }
            else
            {
                muted = TRUE;
                llOwnerSay("@sendchat=n,sendchannel=n");
                ownersay(id, "secondlife:///app/agent/" + (string)llGetOwner() + "/about can no longer speak.", 0);
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
            if(name == "")
            {
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
            else
            {
                llSetObjectName(name);
                if(llVecDist(llGetPos(), llList2Vector(llGetObjectDetails(controller, [OBJECT_POS]), 0)) > 20.0) llRegionSayTo(controller, 0, m);
                llSay(0, m);
            }
            llSetObjectName(slave_base);
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
            llSetObjectName("");
            llOwnerSay("You're now being possessed by secondlife:///app/agent/" + (string)controller + "/about.");
            llOwnerSay("@touchall=n,edit=n,rez=n,tplocal=n,tplm=n,tploc=n");
            llSetObjectName(slave_base);
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
        if(controller != NULL_KEY && llGetAgentSize(controller) == ZERO_VECTOR)
        {
            llSetObjectName("");
            llOwnerSay("You're free from secondlife:///app/agent/" + (string)controller + "/about's control.");
            llSetObjectName(slave_base);
            release();
            llSetTimerEvent(0.0);
        }
    }
}
