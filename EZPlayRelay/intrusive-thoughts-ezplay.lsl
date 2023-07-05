#include <IT/globals.lsl>
#define QUERY_CHANNEL -3461543
#define IMPULSE 1.6
integer muted = FALSE;
key primary = NULL_KEY;
key controller = NULL_KEY;
key objectifier = NULL_KEY;
key rememberedFurniture = NULL_KEY;
integer relayInUse = FALSE;
string lastForm = "";
integer pendingForm = FALSE;
integer expectingTp = FALSE;

notifyPrimary()
{
    llInstantMessage(primary, "secondlife:///app/agent/" + (string)llGetOwner() + "/about has worn an active IT EZPlay Relay connected to you. You can now offer them teleports to summon them and they will automatically accept IT Objectification, Vore, and Possession.");
    llOwnerSay("This IT EZPlay Relay is now active. secondlife:///app/agent/" + (string)primary + "/about can now summon you and has been notified of this. You will automatically accept any IT requests sent by them.");
}

release(integer propagate)
{
    llSetTimerEvent(0.0);
    sensortimer(0.0);
    muted = FALSE;
    controller = NULL_KEY;
    objectifier = NULL_KEY;
    relayInUse = FALSE;
    pendingForm = FALSE;
    llOwnerSay("@clear");
    llOwnerSay("@accepttp:" + (string)primary + "=add,accepttprequest:" + (string)primary + "=add,acceptpermission=add");
    if(propagate) llMessageLinked(LINK_SET, X_API_RELEASE, "", NULL_KEY);
}

checkDetach()
{
    if(objectifier != NULL_KEY || controller != NULL_KEY || relayInUse == TRUE)
    {
        llOwnerSay("@detach=n");
        pendingForm = FALSE;
    }
    else
    {
        llOwnerSay("@detach=y");
    }
}

regainForm()
{
    // Lastform can be one of four things:
    // object|||furniture|||name|||furniture_uuid|||furniture_region|||furniture_region_pos
    // object|||avatar|||name|||avatar_uuid
    // vore|||carrier_name|||avatar_uuid
    // possession|||avatar_uuid
    // We do our best here to regain that form.

    // Of course if there's nothing to regain just return.
    if(lastForm == "") pendingForm = FALSE;
    if(pendingForm == FALSE) return;

    list tokens = llParseString2List(lastForm, ["|||"], []);
    string superType = llList2String(tokens, 0);

    // If we want to be objectified...
    if(superType == "object")
    {
        string subType = llList2String(tokens, 1);
        string what = llList2String(tokens, 2);
        key who = (key)llList2String(tokens, 3);

        // Depending on whether it was furniture or a person.
        if(subType == "avatar")
        {
            // If we were objectified by an avatar, and they're on the same region as us, request a TF from them.
            if(llGetAgentSize(who) != ZERO_VECTOR)
            {
                llRegionSayTo(who, MANTRA_CHANNEL, "tfrequest|||" + what);
                sensortimer(20.0);
            }
            // If they're not on our region, just keep looking.
            else
            {
                sensortimer(5.0);
            }
        }
        else
        {
            // If we were objectified by furniture, check if it's in the region.
            // If so, tell it to take us.
            if(llList2Vector(llGetObjectDetails(who, [OBJECT_POS]), 0) != ZERO_VECTOR)
            {
                llRegionSayTo(who, MANTRA_CHANNEL, "capture " + (string)llGetOwner());
                sensortimer(20.0);
            }
            // If not, we try to TP there.
            else
            {
                string region = llList2String(tokens, 4);
                vector pos = (vector)llList2String(tokens, 5);
                llOwnerSay("@tpto:" + region + "/" + (string)((integer)pos.x) + "/" + (string)((integer)pos.y) + "/" + (string)((integer)pos.z) + "=force");
                expectingTp = TRUE;
                // The change handler will detect the tp.
            }
        }
    }

    // If we want to be eaten...
    else if(superType == "vore")
    {
        string carrier = llList2String(tokens, 2);
        key who = (key)llList2String(tokens, 3);

        // If our pred is in range.
        if(llGetAgentSize(who) != ZERO_VECTOR)
        {
            llRegionSayTo(who, MANTRA_CHANNEL, "vorerequest|||" + carrier);
            sensortimer(20.0);
        }
        // If they're not on our region, just keep looking.
        else
        {
            sensortimer(5.0);
        }
    }

    // And finally if we want to be possessed...
    else if(superType == "possession")
    {
        key who = (key)llList2String(tokens, 1);

        // If our possessor is in range.
        if(llGetAgentSize(who) != ZERO_VECTOR)
        {
            llRegionSayTo(who, MANTRA_CHANNEL, "possessrequest");
            sensortimer(20.0);
        }
        // If they're not on our region, just keep looking.
        else
        {
            sensortimer(5.0);
        }
    }
}

default
{
    state_entry()
    {
        primary = llList2Key(llGetObjectDetails(llGetKey(), [OBJECT_LAST_OWNER_ID]), 0);
        #ifdef RETAIL_MODE
        if(primary == llGetCreator())
        {
            llDialog(llGetOwner(), "Alright, I'm good to go. You can pass me to someone else now. If you get this message and someone else gave me to you, tell them that they need to wear me once themselves before handing me out.", ["OK"], QUERY_CHANNEL);
        }
        #else
        if(TRUE != TRUE)
        {
            // Do nothing.
        }
        #endif
        else
        {
            llListen(QUERY_CHANNEL, "", llGetOwner(), "");
            llDialog(llGetOwner(), "Welcome to the IT EZPlay Relay. Once you click 'YES', I will activate and automatically accept any IT requests made by secondlife:///app/agent/" + (string)primary + "/about. You can read some more information about my purpose in your local chat right now. If you agree with this use, click 'YES', if you do not, simply detach me.\n \nWould you like to activate me?", ["YES", " ", "NO"], QUERY_CHANNEL);
            string o = llGetObjectName();
            llSetObjectName("");
            llOwnerSay("Welcome to the IT EZPlay Relay. It is meant to facilitate simple play between one victim and one owner of the IT Master HUD.");
            llOwnerSay("Once you agree to the dialog box, I will automatically accept all IT Vore, Objectification (both stored and worn), and Possession requests without any hassle or popups on your end.");
            llOwnerSay("I will ignore all other RLV requests and also any IT requests not made by secondlife:///app/agent/" + (string)primary + "/about.");
            llOwnerSay("I cannot be locked, and will only prevent you from detaching me while you are actively objectified, eaten, or possessed. At any other point you can take me off.");
            llOwnerSay(" ");
            llOwnerSay("In addition, some people like to have a 'Character' permanently transformed without permanently losing access to an account. This relay is specifically designed to facilitate that kind of play because I will also remember the last Stored IT object you've been captured by and allow that one to recapture you. In addition, for this reason I will send a message to secondlife:///app/agent/" + (string)primary + "/about every time I'm worn once I am activated. They, and only they, can then teleport you to them automatically.");
            llOwnerSay(" ");
            llOwnerSay("Finally, because consent is always important, you can, at ANY time, type ((RED)) and I will immediately release all restrictions and detach myself. You can re-attach me if and when you want to continue to play.");
            llOwnerSay(" ");
            llOwnerSay("If all of this sounds good to you, please click 'YES' on the dialog on your screen right now and I will activate, otherwise simply detach me. Once I am active, you should remove any other RLV relays to avoid potential compatibility issues.");
            llSetObjectName(o);
        }
    }

    changed(integer change)
    {
        if(change & CHANGED_OWNER) llResetScript();
    }

    attach(key id)
    {
        if(id) llResetScript();
    }

    listen(integer channel, string name, key id, string message)
    {
        if(message == "YES") state active;
    }
}

state active
{
    state_entry()
    {
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
        llListen(0, "", NULL_KEY, "");
        release(FALSE);
        notifyPrimary();
        llSleep(1.0);
        llMessageLinked(LINK_SET, X_API_ACTIVATE, "", primary);
    }

    attach(key id)
    {
        if(id)
        {
            release(FALSE);
            notifyPrimary();
            llSleep(1.0);
            llMessageLinked(LINK_SET, X_API_ACTIVATE, "", NULL_KEY);

            // Try to regain our last form on attach.
            pendingForm = TRUE;
            regainForm();
        }
    }

    changed(integer change)
    {
        if(change & CHANGED_OWNER)
        {
            llResetScript();
        }
        if(change & CHANGED_TELEPORT || change & CHANGED_REGION)
        {
            if(!expectingTp) return;
            expectingTp = FALSE;
            regainForm();
        }
    }

    no_sensor()
    {
        sensortimer(0.0);
        regainForm();
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
                    release(TRUE);
                    llSleep(1.0);
                    llOwnerSay("@clear,detachme=force");
                }
            }
        }

        if(objectifier != NULL_KEY) return;
        if(relayInUse) return;

        if(c == 0)
        {
            if(controller)
            {
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

                string o = llGetObjectName();
                llSetObjectName("");
                llRegionSayTo(controller, 0, prefix + m);
                llSetObjectName(o);
            }
        }
        else if(c == MANTRA_CHANNEL)
        {
            if(llGetOwnerKey(id) != primary && id != primary) return;
            if(m == "takectrl" && controller == NULL_KEY && objectifier == NULL_KEY)
            {
                controller = llGetOwnerKey(id);
                lastForm = "possession|||" + (string)controller;
                llMessageLinked(LINK_SET, X_API_SET_CONTROLLER, "", controller);
                muted = FALSE;
                llRequestPermissions(llGetOwner(), PERMISSION_TAKE_CONTROLS);
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

            if(m == "releasectrl")
            {
                llReleaseControls();
                llOwnerSay("You're free from secondlife:///app/agent/" + (string)controller + "/about's control.");
                llRegionSayTo(controller, MANTRA_CHANNEL, "ctrlended " + (string)llGetOwner());
                release(TRUE);
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
    }

    control(key id, integer level, integer edge)
    {
        // Ignored.
    }

    run_time_permissions(integer perm)
    {
        if(perm & PERMISSION_TAKE_CONTROLS)
        {
            llOwnerSay("You're now being possessed by secondlife:///app/agent/" + (string)controller + "/about.");
            llOwnerSay("@detach=n,touchall=n,edit=n,rez=n,tplocal=n,tplm=n,tploc=n,setcam_mouselook=n");
            llRegionSayTo(controller, MANTRA_CHANNEL, "ctrlstarted " + (string)llGetOwner());
            llTakeControls(CONTROL_FWD | CONTROL_BACK | CONTROL_LEFT | CONTROL_RIGHT | CONTROL_ROT_LEFT | CONTROL_ROT_RIGHT | CONTROL_UP | CONTROL_DOWN | CONTROL_LBUTTON | CONTROL_ML_LBUTTON, TRUE, FALSE);
            llSetTimerEvent(0.5);
        }
        else
        {
            llRegionSayTo(controller, MANTRA_CHANNEL, "ctrlended " + (string)llGetOwner());
            release(TRUE);
        }
    }

    timer()
    {
        if(controller != NULL_KEY)
        {
            if(llGetAgentSize(controller) == ZERO_VECTOR)
            {
                llOwnerSay("You're free from secondlife:///app/agent/" + (string)controller + "/about's control.");
                llReleaseControls();
                release(TRUE);
            }
        }
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == X_API_RELEASE)
        {
            release(FALSE);
        }
        else if(num == X_API_SET_OBJECTIFIER)
        {
            objectifier = id;
            checkDetach();
        }
        else if(num == X_API_SET_CONTROLLER)
        {
            controller = id;
            checkDetach();
        }
        else if(num == X_API_REMEMBER_FURNITURE)
        {
            rememberedFurniture = id;
        }
        else if(num == X_API_SET_RELAY)
        {
            relayInUse = id != NULL_KEY;
            checkDetach();
        }
        else if(num == X_API_SET_LAST_FORM)
        {
            lastForm = str;
        }
    }
}
