#include <IT/globals.lsl>

list buttons =         [];
list buttonlinks =     [];
list buttonstates =    [];
list buttonfilters =   [];

list indicators =      [];
list indicatorlinks =  [];

list textfields = [];
list textfieldtexts = [];

integer islocked = FALSE;
integer ishidden = TRUE;
integer isstatus = FALSE;
integer started = FALSE;

integer hasobject = FALSE;
integer hasprey   = FALSE;
integer hasposs   = FALSE;
integer hasrelay  = FALSE;

string lockedavatarname = "";
key lockedavatarkey = NULL_KEY;
string seenavatarname = "";
key seenavatarkey = NULL_KEY;
string seenobjectname = "";
key seenobjectkey = NULL_KEY;

float hoverheight = 0.0;
key http;
key curowner;

setheight()
{
    llOwnerSay("Hover height set to " + (string)hoverheight + ".");
    llOwnerSay("@adjustheight:" + (string)hoverheight + "=force");
}

setbuttonfilter(string filter, integer active)
{
    if(filter == "") return;
    float alpha;
    integer i = llGetListLength(buttonfilters);
    while(~--i)
    {
        string f = llList2String(buttonfilters, i);
        if(f == filter)
        {
            buttonstates = llListReplaceList(buttonstates, [active], i, i);
            if(active) alpha = 0.0;
            else       alpha = 0.7;
            llSetLinkAlpha(llList2Integer(buttonlinks, i), alpha, 4);
        }
    }

    // Vore/unvore are mutually incompatible.
    i = llListFindList(buttons, ["unvore"]);
    if(llList2Integer(buttonstates, i) == TRUE)
    {
        i = llListFindList(buttons, ["vore"]);
        buttonstates = llListReplaceList(buttonstates, [FALSE], i, i);
        llSetLinkAlpha(llList2Integer(buttonlinks, i), 0.7, 4);
    }
    else
    {
        i = llListFindList(buttons, ["objectify"]);
        if(llList2Integer(buttonstates, i) == TRUE)
        {
            i = llListFindList(buttons, ["vore"]);
            buttonstates = llListReplaceList(buttonstates, [TRUE], i, i);
            llSetLinkAlpha(llList2Integer(buttonlinks, i), 0.0, 4);
        }
        else
        {
            i = llListFindList(buttons, ["vore"]);
            buttonstates = llListReplaceList(buttonstates, [FALSE], i, i);
            llSetLinkAlpha(llList2Integer(buttonlinks, i), 0.7, 4);
        }
    }

    // Similarly, possess and unpossess are not compatible.
    i = llListFindList(buttons, ["unpossess"]);
    if(llList2Integer(buttonstates, i) == TRUE)
    {
        i = llListFindList(buttons, ["possess"]);
        buttonstates = llListReplaceList(buttonstates, [FALSE], i, i);
        llSetLinkAlpha(llList2Integer(buttonlinks, i), 0.7, 4);
    }
    else
    {
        i = llListFindList(buttons, ["objectify"]);
        if(llList2Integer(buttonstates, i) == TRUE)
        {
            i = llListFindList(buttons, ["possess"]);
            buttonstates = llListReplaceList(buttonstates, [TRUE], i, i);
            llSetLinkAlpha(llList2Integer(buttonlinks, i), 0.0, 4);
        }
        else
        {
            i = llListFindList(buttons, ["possess"]);
            buttonstates = llListReplaceList(buttonstates, [FALSE], i, i);
            llSetLinkAlpha(llList2Integer(buttonlinks, i), 0.7, 4);
        }
    }

    i = llListFindList(indicators, [filter]);
    if(i == -1) return;
    if(active) alpha = 0.0;
    else       alpha = 1.0;

    llSetLinkAlpha(llList2Integer(indicatorlinks, i), alpha, ALL_SIDES);
}

string fontmap = " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~     ";
string fonttex = "bf38763e-9b99-e83b-f8d7-0f003d66103c";
vector indextooffset(integer index)
{
    if(index < 0 || index > 99) return <0, 0, 0>;
    integer x = index % 10;
    integer y = index / 10;
    return <-0.7+(x*0.1), 0.7-(y*0.1), 0>;
}

integer settext(integer line, string text)
{
    string lineprefix = (string)line + ".";
    integer suffix = 0;
    integer i = llListFindList(textfields, [lineprefix + (string)suffix]);
    if(i == -1) return FALSE;

    if(llList2String(textfieldtexts, line) == text) return TRUE;
    textfieldtexts = llListReplaceList(textfieldtexts, [text], line, line);

    list links = [];
    while(i != -1)
    {
        links += llList2Integer(textfields, i + 1);
        suffix++;
        i = llListFindList(textfields, [lineprefix + (string)suffix]);
    }

    integer maxlength = llGetListLength(links);
    while(llStringLength(text) < (maxlength * 8)) text = text + " ";
    if(llStringLength(text) > (maxlength * 8)) text = llDeleteSubString(text, -1, -1);

    integer j = 0;
    integer link = 0;
    list options = [];
    while(j < maxlength)
    {
        i = 0;
        link = llList2Integer(links, j);
        options += [PRIM_LINK_TARGET, link];
        while(i < 8)
        {
            options += [PRIM_TEXTURE, i, fonttex, <1.6,1.6,0>, indextooffset(llSubStringIndex(fontmap, llGetSubString(text, i+(j*8), i+(j*8)))), 0.0];
            i++;
        }
        j++;
    }
    llSetLinkPrimitiveParamsFast(0, options);
    return TRUE;
}

integer validatedisplayname(string name)
{
    integer l = llStringLength(name);
    while(~--l)
    {
        if(!contains(fontmap, llGetSubString(name, l, l))) return FALSE;
    }
    return TRUE;
}

sethide()
{
    if(ishidden) llSetLocalRot(<0.0, 0.0, -0.70711, 0.70711>);
    else         llSetLocalRot(ZERO_ROTATION);
}

dosetup()
{
    integer i = llGetNumberOfPrims();
    while(~i)
    {
        key link = llGetLinkKey(i);
        list details = llGetObjectDetails(link, [OBJECT_NAME, OBJECT_DESC]);
        string name = llList2String(details, 0);
        string desc = llList2String(details, 1);
        if(desc == "indicator")
        {
            indicators += [name];
            indicatorlinks += [i];
        }
        else if(desc == "text")
        {
            textfields += [name, i];
            textfieldtexts += ["x"];
        }
        else if(startswith(desc, "button"))
        {
            buttons += [name];
            buttonlinks += [i];
            string filter = llList2String(llParseString2List(desc, [".have"], []), 1);
            buttonfilters += [filter];
            if(filter == "")
            {
                buttonstates += [TRUE];
                llSetLinkAlpha(i, 0.0, ALL_SIDES);
            }
            else if(filter == "hidden")
            {
                buttonstates += [TRUE];
                llSetLinkAlpha(i, 1.0, ALL_SIDES);
            }
            else
            {
                buttonstates += [FALSE];
                llSetLinkAlpha(i, 0.0, ALL_SIDES);
                llSetLinkAlpha(i, 0.7, 4);
            }
        }
        --i;
    }
    i = 0;
    while(settext(i++, ""));
    llListen(BALL_CHANNEL, "", llGetOwner(), "");
    llListen(COMMAND_CHANNEL, "", llGetOwner(), "");
    sethide();
    llMessageLinked(LINK_SET, M_API_HUD_STARTED, "", (key)"");
    http = llHTTPRequest(UPDATE_URL, [], "");
}

doquicksetup()
{
    integer i = 0;
    while(settext(i++, ""));
    started = FALSE;
    islocked = FALSE;
    isstatus = FALSE;
    hoverheight = 0.0;
    llMessageLinked(LINK_SET, M_API_HUD_STARTED, "", (key)"");
    llMessageLinked(LINK_SET, M_API_LOCK, "", NULL_KEY);
    http = llHTTPRequest(UPDATE_URL, [], "");
}

gethelp(string b)
{
    llSetObjectName("");
    if(b == "-" || b == "--" || b == "reset" || b == "+" || b == "++")
    {
        llOwnerSay("This group of five buttons controls your hover height. Clicking the + button moves you up a little, while pressing the ++ button will move you up a lot. The opposite is true for the - and -- buttons. Clicking the RESET button will reset you back to 0 hover height. RLV is required for this function to work, and when you re-attach the HUD, you will be reset to 0 hover height.");
    }
    else if(b == "lock")
    {
        llOwnerSay("Click this button to lock the last seen avatar as a target for many functions of the HUD. Clicking the button with someone locked, will instead unlock the HUD target. The indicator in the upper right of the HUD will show whether or not you have a lock. You can also type /1lock <uuid/name> to lock onto someone if they are hard to cam, just the first few letters of the legacy name or display name are needed.");
    }
    else if(b == "sit")
    {
        llOwnerSay("This button will sit the locked avatar onto the object you are looking at, or make them stand up if they are sitting.");
    }
    else if(b == "leash")
    {
        llOwnerSay("This button will leash the locked avatar to the object you are looking at if they are wearing an IT Slave with you as an owner.");
    }
    else if(b == "relay")
    {
        llOwnerSay("This button will turn the embedded RLV relay on and off. If it is turned off, any and all RLV restrictions will also be removed.");
    }
    else if(b == "tp")
    {
        llOwnerSay("This button will give you a list of teleportation options.");
    }
    else if(b == "menu")
    {
        llOwnerSay("This button will give you the menu for programming IT Slaves with you set as an owner. Note that if you have a lock on an avatar, it will try to give you the menu belonging to their IT Slave first, if they are not wearing an IT Slave, it will continue to do a scan for slaves as normal.");
    }
    else if(b == "rclear" || b == "rdetach" || b == "rreset")
    {
        llOwnerSay("These three buttons will control the RLV relay in the locked avatar's IT Slave. The CLEAR button will remove all restrictions, the DETACH button will remove all restrictions and detach the IT Slave device, and the RESET button will remove all restrictions and do a hard reset on the entire IT slave system, except for the owner list. The RESET can be needed when dealing with badly programmed RLV toys.");
    }
    else if(b == "objectify")
    {
        llOwnerSay("This button will turn the locked avatar into an object you wear. It will give you a dialog to select a name for the object. It will also attempt to wear the RLV folder '#RLV/~IT/name', where name is the name you entered. There is no real limit to the amount of objects you can hold.");
    }
    else if(b == "release")
    {
        llOwnerSay("This button will release a held object. If you have only one object held, it will release that one. Otherwise you will get a menu.");
    }
    else if(b == "edit")
    {
        llOwnerSay("This button will edit a held object's name tag position if you are seated. If you have only one object held, it will edit that one. Otherwise you will get a menu.");
    }
    else if(b == "store")
    {
        llOwnerSay("This button will store a held object as the IT Furniture you are looking at. If you have only one object held, it will store that one. Otherwise you will get a menu.");
    }
    else if(b == "furniture")
    {
        llOwnerSay("This button will attempt to take an object from the IT Furniture you are looking at. If you have an avatar locked and the IT Furniture is not already occupied, it will instead try to store that avatar directly.");
    }
    else if(b == "vore" || b == "unvore")
    {
        llOwnerSay("These two buttons will eat, and release, the locked avatar. You can only have one avatar inside of you. When eating someone, the RLV folder #RLV/~IT/vore/on will be worn, and the folder #RLV/~IT/vore/off will be taken off. The opposite will be done when you release someone.");
    }
    else if(b == "acid+" || b == "acid-")
    {
        llOwnerSay("These buttons affect the acid level inside of your stomach. Random clothes will start dissolving if the acide level is at or above 40%. If you raise the percentage above 100%, your food will be fully digested and made invisible.");
    }
    else if(b == "hide")
    {
        llOwnerSay("Clicking this button will minimize/maximize the HUD.");
    }
    else if(b == "possess" || b == "unpossess")
    {
        llOwnerSay("Possess will attempt to take control over the locked avatar. Release will let them go.");
    }
    else if(b == "posspause")
    {
        llOwnerSay("While you are possessing someone, you can not move. This button will pause the possession so you can move. You can then click it again to take control over your victim again.");
    }
    else if(b == "posssit")
    {
        llOwnerSay("This button will have your victim sit on the object you are looking at, or stand them up if they were already seated.");
    }
    llSetObjectName(master_base);
}

integer validlock(key k)
{
    if(k)
    {
        if(llGetAgentSize(k) == ZERO_VECTOR) return FALSE;
        if(llGetAgentInfo(k) & AGENT_SITTING)
        {
            key saton = llList2Key(llGetObjectDetails(k, [OBJECT_ROOT]), 0);
            list dets = llGetObjectDetails(saton, [OBJECT_CREATOR]);
            string screa = (string)llList2Key(dets, 0);
            if(IT_CREATOR == screa) return FALSE;
        }
        return TRUE;
    }
    else
    {
        return FALSE;
    }
}

default
{
    changed(integer change)
    {
        if(change & CHANGED_OWNER) resetscripts();
    }

    attach(key id)
    {
        if(curowner != llGetOwner()) return;
        if(id) doquicksetup();
    }

    run_time_permissions(integer perm)
    {
        if(perm & PERMISSION_ATTACH) llDetachFromAvatar();
    }

    state_entry()
    {
        curowner = llGetOwner();
        resetother();
        dosetup();
    }

    listen(integer channel, string name, key id, string message)
    {
        if(channel == BALL_CHANNEL)
        {
            llSetObjectName("Your Thoughts");
            llOwnerSay(message);
            llSetObjectName(master_base);
        }
        else if(channel == COMMAND_CHANNEL)
        {
            if(message == "hardreset")
            {
                llSetObjectName("");
                llOwnerSay("Doing a hard reset of your Master HUD.");
                llSetObjectName(master_base);
                resetscripts();
            }
            else if(startswith(message, "lock"))
            {
                message = llDeleteSubString(message, 0, llStringLength("lock"));
                key uuid = (key)message;
                if(uuid)
                {
                    if(llGetAgentSize(uuid) != ZERO_VECTOR)
                    {
                        llMessageLinked(LINK_SET, M_API_LOCK, llGetDisplayName(uuid), uuid);
                    }
                }
                else
                {
                    uuid = llName2Key(message);
                    if(uuid)
                    {
                        if(llGetAgentSize(uuid) != ZERO_VECTOR)
                        {
                            llMessageLinked(LINK_SET, M_API_LOCK, llGetDisplayName(uuid), uuid);
                        }
                    }
                    else
                    {
                        list agents = llGetAgentList(AGENT_LIST_REGION, []);
                        integer n = llGetListLength(agents);
                        while(~--n)
                        {
                            uuid = llList2Key(agents, n);
                            if(startswith(llToLower(llGetDisplayName(uuid)), llToLower(message)) || startswith(llToLower(llGetUsername(uuid)), llToLower(message)))
                            {
                                llMessageLinked(LINK_SET, M_API_LOCK, llGetDisplayName(uuid), uuid);
                                return;
                            }
                        }
                    }
                }
            }
        }
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == M_API_CONFIG_DONE)
        {
            started = TRUE;
        }
        else if(num == M_API_CAM_AVATAR)
        {
            if(validatedisplayname(str))
            {
                seenavatarname = str;
            }
            else
            {
                seenavatarname = llGetUsername(id);
                string outname = "";
                list names = llParseString2List(seenavatarname, ["."], []);
                integer i = 0;
                integer l = llGetListLength(names);
                while(i < l)
                {
                    string word = llList2String(names, i);
                    word = llToUpper(llGetSubString(word, 0, 0)) + llGetSubString(word, 1, -1);
                    if(llToLower(word) != "resident") outname += word;
                    if(i != l-1) outname += " ";
                    ++i;
                }
                seenavatarname = outname;
            }
            seenavatarkey = id;
            if(isstatus || islocked) return;
            settext(0, seenavatarname);
        }
        else if(num == M_API_CAM_OBJECT)
        {
            seenobjectname = str;
            seenobjectkey = id;
            if(isstatus) return;
            settext(1, str);
        }
        else if(num == M_API_STATUS_MESSAGE)
        {
            isstatus = TRUE;
            settext(0, str);
            settext(1, (string)id);
        }
        else if(num == M_API_STATUS_DONE)
        {
            isstatus = FALSE;
            if(!islocked) settext(0, seenavatarname);
            else          settext(0, lockedavatarname);
            settext(1, seenobjectname);
        }
        else if(num == M_API_LOCK)
        {
            lockedavatarkey = id;
            if(validatedisplayname(str))
            {
                lockedavatarname = ">" + str + "<";
            }
            else
            {
                lockedavatarname = llGetUsername(id);
                string outname = "";
                list names = llParseString2List(lockedavatarname, ["."], []);
                integer i = 0;
                integer l = llGetListLength(names);
                while(i < l)
                {
                    string word = llList2String(names, i);
                    word = llToUpper(llGetSubString(word, 0, 0)) + llGetSubString(word, 1, -1);
                    if(llToLower(word) != "resident") outname += word;
                    if(i != l-1) outname += " ";
                    ++i;
                }
                lockedavatarname = ">" + outname + "<";
            }
            if(str == "")
            {
                islocked = FALSE;
                setbuttonfilter("lock", FALSE);
                settext(0, seenavatarname);
            }
            else
            {
                islocked = TRUE;
                setbuttonfilter("lock", TRUE);
                settext(0, lockedavatarname);
                if(!validlock(lockedavatarkey)) llMessageLinked(LINK_SET, M_API_LOCK, "", NULL_KEY);
                else                            llSetTimerEvent(0.5);
            }
        }
        else if(num == M_API_SET_FILTER)
        {
            setbuttonfilter(str, (integer)((string)id));

            // Prevent accidental detach while having prey, objects, or the relay.
            if(str == "vore") hasprey = (integer)((string)id);
            if(str == "object") hasobject = (integer)((string)id);
            if(str == "relay") hasrelay = (integer)((string)id);
            if(str == "poss") hasposs = (integer)((string)id);
            if(hasprey || hasobject || hasrelay || hasposs) llOwnerSay("@detach=n");
            else                                            llOwnerSay("@detach=y");
        }
        else if(num == M_API_BUTTON_PRESSED)
        {
            if(str == "hide")
            {
                ishidden = !ishidden;
                sethide();
            }
            else if(str == "lock")
            {
                if(islocked) llMessageLinked(LINK_SET, M_API_LOCK, "", NULL_KEY);
                else         llMessageLinked(LINK_SET, M_API_LOCK, seenavatarname, seenavatarkey);
            }
            else if(str == "sit")
            {
                llSetObjectName("RLV Sit");
                if(llGetAgentInfo(lockedavatarkey) & AGENT_SITTING)
                {
                    llOwnerSay("Standing up '" + llGetSubString(lockedavatarname, 1, -2) + "'.");
                    if(lockedavatarkey == llGetOwner()) llOwnerSay("@unsit=force");
                    else                                llRegionSayTo(lockedavatarkey, RLVRC, "st," + (string)lockedavatarkey + ",@unsit=force");
                }
                else
                {
                    llOwnerSay("Sitting '" + llGetSubString(lockedavatarname, 1, -2) + "' on '" + seenobjectname + "'.");
                    if(lockedavatarkey == llGetOwner()) llOwnerSay("@sit:" + (string)seenobjectkey + "=force");
                    else                                llRegionSayTo(lockedavatarkey, RLVRC, "si," + (string)lockedavatarkey + ",@sit:" + (string)seenobjectkey + "=force");
                }
                llSetObjectName(master_base);
            }
            else if(str == "leash")
            {
                llRegionSayTo(lockedavatarkey, MANTRA_CHANNEL, "leashto " + (string)seenobjectkey);
            }
            else if(str == "rclear")
            {
                llRegionSayTo(lockedavatarkey, MANTRA_CHANNEL, "CLEAR");
            }
            else if(str == "rdetach")
            {
                llRegionSayTo(lockedavatarkey, MANTRA_CHANNEL, "FORCECLEAR");
            }
            else if(str == "rreset")
            {
                llRegionSayTo(lockedavatarkey, MANTRA_CHANNEL, "RESETRELAY");
            }
            else if(str == "reset")
            {
                hoverheight = 0.0;
                setheight();
            }
            else if(str == "++")
            {
                hoverheight += 3.0;
                setheight();
            }
            else if(str == "+")
            {
                hoverheight += 0.5;
                setheight();
            }
            else if(str == "--")
            {
                hoverheight -= 3.0;
                setheight();
            }
            else if(str == "-")
            {
                hoverheight -= 0.5;
                setheight();
            }
        }
    }

    touch_start(integer num)
    {
        if(!started) return;
        llResetTime();
    }

    touch_end(integer num)
    {
        if(!started) return;
        string name = llGetLinkName(llDetectedLinkNumber(0));
        integer i = llListFindList(buttons, [name]);
        if(i == -1) return;
        if(ishidden == TRUE && name != "hide") return;

        if(llGetTime() > 1.0)
        {
            gethelp(name);
        }
        else
        {
            string filter = llList2String(buttonfilters, i);
            if(filter != "" && llList2Integer(buttonstates, i) == FALSE) return;
            llMessageLinked(LINK_SET, M_API_BUTTON_PRESSED, name, seenobjectkey);
        }
    }

    timer()
    {
        llSetTimerEvent(0.0);
        if(!validlock(lockedavatarkey))
        {
            llMessageLinked(LINK_SET, M_API_LOCK, "", NULL_KEY);
            return;
        }
        llSetTimerEvent(0.5);
    }

    http_response(key id, integer status, list metadata, string body)
    {
        if(id == http)
        {
            if(status == 200) versioncheck(body, TRUE);
            else              llOwnerSay("Cannot check for updates: Connectivity issue between SL and the external server. You can click [secondlife:///app/chat/1/update here] or type /1update ");
        }
    }
}
