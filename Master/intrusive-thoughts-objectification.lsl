#include <IT/globals.lsl>

string owner = "";
string objectprefix = "";
integer hideopt = 1;

key lockedavatar = NULL_KEY;
string lockedname = "";

key target;
string targetname;
string targetdescription;

list objectifiedavatars = [];
list objectifiednames = [];
list objectifieddescriptions = [];
list objectifiedballs = [];
list objectifiedurls = [];
list objectificationqueue = [];
string await = "";

integer timermode = 0;
integer countdown = 0;
list arrived = [];
string lastregion;
list buffered = [];
integer store = -1;
string storingon;
key closestavatar = NULL_KEY;
key lastrezzed;
key lastseenobject;

integer dialog = 0;
integer filter = FALSE;
integer configured = FALSE;

detachobject(string o)
{
    if(o == "") return;
    if(contains(o, ";")) o = llList2String(llParseString2List(o, [";"], []), 1);
    llOwnerSay("@detach:~IT/" + llToLower(o) + "=force");
}

attachobject(string o)
{
    if(o == "") return;
    if(contains(o, ";")) o = llList2String(llParseString2List(o, [";"], []), 1);
    llOwnerSay("@attachover:~IT/" + llToLower(o) + "=force");
}

givereleasemenu()
{
    integer l = llGetListLength(objectifiednames);
    if(l == 1)
    {
        release(0);
        return;
    }

    string prompt = "Who will you release?\n";
    integer i;
    if(l > 11) l = 11;
    list buttons = [];
    for(i = 0; i < l; ++i)
    {
        buttons += [(string)i];
        prompt += "\n" + (string)i + ": " + llList2String(objectifiednames, i) + " (" + objectprefix + llList2String(objectifieddescriptions, i) + ")";
    }
    if(getstringbytes(prompt) > 512)
    {
        buttons = [];
        prompt = "Who will you release?\n";
        for(i = 0; i < l; ++i)
        {
            buttons += [(string)i];
            prompt += "\n" + (string)i + ": " + llList2String(objectifieddescriptions, i) + ")";
        }
    }
    while(llGetListLength(buttons) < 11) buttons += [" "];
    buttons += ["ALL"];
    dialog = 1;
    llDialog(llGetOwner(), prompt, orderbuttons(buttons), O_DIALOG_CHANNEL);
}

giveeditmenu()
{
    integer l = llGetListLength(objectifiednames);
    if(l == 1)
    {
        llRegionSayTo(llList2Key(objectifiedballs, 0), MANTRA_CHANNEL, "edit");
        llRegionSayTo(llList2Key(objectifiedballs, 0), 5, llGetSubString(llList2String(objectifiednames, 0), 0, 1) + "menu");
        return;
    }

    string prompt = "Whose position will you edit?\n";
    integer i;
    if(l > 12) l = 12;
    list buttons = [];
    for(i = 0; i < l; ++i)
    {
        buttons += [(string)i];
        prompt += "\n" + (string)i + ": " + llList2String(objectifiednames, i) + " (" + objectprefix + llList2String(objectifieddescriptions, i)+ ")";
    }
    if(getstringbytes(prompt) > 512)
    {
        buttons = [];
        prompt = "Whose position will you edit?\n";
        for(i = 0; i < l; ++i)
        {
            buttons += [(string)i];
            prompt += "\n" + (string)i + ": " + llList2String(objectifieddescriptions, i) + ")";
        }
    }
    while(llGetListLength(buttons) < 12) buttons += [" "];
    dialog = 2;
    llDialog(llGetOwner(), prompt, orderbuttons(buttons), O_DIALOG_CHANNEL);
}

givestoremenu()
{
    integer l = llGetListLength(objectifiednames);
    if(l == 1)
    {
        store = 0;
        llRegionSayTo(lastseenobject, MANTRA_CHANNEL, "furniture");
        return;
    }

    string prompt = "Who will you store as '" + llList2String(llGetObjectDetails(lastseenobject, [OBJECT_NAME]), 0) + "'?\n";
    integer i;
    if(l > 12) l = 12;
    list buttons = [];
    for(i = 0; i < l; ++i)
    {
        buttons += [(string)i];
        prompt += "\n" + (string)i + ": " + llList2String(objectifiednames, i) + " (" + objectprefix + llList2String(objectifieddescriptions, i)+ ")";
    }
    if(getstringbytes(prompt) > 512)
    {
        buttons = [];
        prompt = "Who will you store as '" + llList2String(llGetObjectDetails(lastseenobject, [OBJECT_NAME]), 0) + "'?\n";
        for(i = 0; i < l; ++i)
        {
            buttons += [(string)i];
            prompt += "\n" + (string)i + ": " + llList2String(objectifieddescriptions, i) + ")";
        }
    }
    while(llGetListLength(buttons) < 12) buttons += [" "];
    dialog = 3;
    llDialog(llGetOwner(), prompt, orderbuttons(buttons), O_DIALOG_CHANNEL);
}

release(integer i)
{
    detachobject(llList2String(objectifieddescriptions, i));
    llMessageLinked(LINK_SET, M_API_SPOOF, "objrelease", (key)(owner + "|||" + llList2String(objectifieddescriptions, i) + "|||" + llList2String(objectifiednames, i)));
    llRegionSayTo(llList2Key(objectifiedballs, i), MANTRA_CHANNEL, "unsit");
    objectifiednames = llDeleteSubList(objectifiednames, i, i);
    objectifiedavatars = llDeleteSubList(objectifiedavatars, i, i);
    objectifiedballs = llDeleteSubList(objectifiedballs, i, i);
    objectifieddescriptions = llDeleteSubList(objectifieddescriptions, i, i);
    objectifiedurls = llDeleteSubList(objectifiedurls, i, i);
}

releaseall()
{
    integer l = llGetListLength(objectifiedballs);
    while(~--l) release(l);
}

addobject(string desc)
{
    if(lockedavatar == llGetOwner()) return;
    if(lockedavatar == NULL_KEY || lockedname == "") return;
    if(desc == "") desc = "object";
    if(startswith(llToLower(desc), llToLower(objectprefix))) desc = llGetSubString(desc, llStringLength(objectprefix), -1);
    targetdescription = desc;
    llSetObjectName("");
    llOwnerSay("Capturing '" + lockedname + "'.");
    llSetObjectName(master_base);
    target = lockedavatar;
    targetname = lockedname;
    llMessageLinked(LINK_SET, M_API_PROVISION_REQUEST, targetname + "|||" + desc + "|||" + (string)hideopt + "|||0", target);
}

addobjectdirect(string desc, key who)
{
    if(desc == "") desc = "object";
    if(startswith(llToLower(desc), llToLower(objectprefix))) desc = llGetSubString(desc, llStringLength(objectprefix), -1);
    target = who;
    targetname = llGetDisplayName(who);
    llSetObjectName("");
    llOwnerSay("Automatically capturing '" + targetname + "' because of an EZPlay Relay request.");
    llSetObjectName(master_base);
    llMessageLinked(LINK_SET, M_API_PROVISION_REQUEST, targetname + "|||" + desc + "|||" + (string)hideopt + "|||0", target);
}

handlequeue()
{
    llSetObjectName("");
    if(objectificationqueue == [])
    {
        llOwnerSay("Done recapturing!");
        timermode = 0;
        llSetTimerEvent(2.5);
    }
    else
    {
        target = llList2Key(objectificationqueue, 0);
        targetname = llList2String(objectificationqueue, 1);
        targetdescription = llList2String(objectificationqueue, 2);
        objectificationqueue = llDeleteSubList(objectificationqueue, 0, 2);
        if(llGetAgentSize(target) == ZERO_VECTOR)
        {
            llOwnerSay("Skipping " + targetname + ". Not present.");
            handlequeue();
        }
        else
        {
            llOwnerSay("Recapturing " + targetname + ".");
            llSetTimerEvent(60.0);
            llMessageLinked(LINK_SET, M_API_PROVISION_REQUEST, targetname + "|||" + targetdescription + "|||" + (string)hideopt + "|||8", target);
        }
    }
    llSetObjectName(master_base);
}

default
{
    state_entry()
    {
        llListen(O_DIALOG_CHANNEL, "", llGetOwner(), "");
        llListen(RLVRC, "", NULL_KEY, "");
        llListen(GAZE_CHAT_CHANNEL, "", NULL_KEY, "");
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
    }

    attach(key id)
    {
        if(id == NULL_KEY) llSetTimerEvent(0.0);
    }

    listen(integer c, string n, key id, string m)
    {
        if(c == O_DIALOG_CHANNEL)
        {
            if(dialog == 0)
            {
                addobject(llStringTrim(m, STRING_TRIM));
            }
            else if(dialog == 1)
            {
                if(m == " ")        return;
                else if(m == "ALL") releaseall();
                else                release((integer)m);
            }
            else if(dialog == 2)
            {
                if(m == " ") return;
                llRegionSayTo(llList2Key(objectifiedballs, (integer)m), MANTRA_CHANNEL, "edit");
                llRegionSayTo(llList2Key(objectifiedballs, (integer)m), 5, llGetSubString(llList2String(objectifiednames, (integer)m), 0, 1) + "menu");
            }
            else if(dialog == 3)
            {
                if(m == " ") return;
                store = (integer)m;
                llRegionSayTo(lastseenobject, MANTRA_CHANNEL, "furniture");
            }

            // Avoid triggering multiple times falsely.
            dialog = -1;
        }
        else if(c == MANTRA_CHANNEL)
        {
            if(startswith(m, "furniture"))
            {
                llSetObjectName("");
                storingon = n;
                if(store == -1)
                {
                    if(m == "furniture 0")
                    {
                        if(lockedavatar == NULL_KEY) llOwnerSay("No object is stored in " + n + ".");
                        else
                        {
                            llRegionSayTo(id, MANTRA_CHANNEL, "capture " + (string)lockedavatar);
                        }
                    }
                    else
                    {
                        llOwnerSay("Taking object from '" + n + "'.");
                        llRegionSayTo(id, MANTRA_CHANNEL, "puton");
                    }
                }
                else
                {
                    detachobject(llList2String(objectifieddescriptions, store));
                    llMessageLinked(LINK_SET, M_API_SPOOF, "objputdown", (key)(owner + "|||" + llList2String(objectifieddescriptions, store) + "|||" + llList2String(objectifiednames, store) + "|||" + n));
                    llRegionSayTo(id, MANTRA_CHANNEL, "putdown " + (string)llList2Key(objectifiedballs, store) + "|||" + llList2String(objectifieddescriptions, store));
                    objectifiednames = llDeleteSubList(objectifiednames, store, store);
                    objectifiedavatars = llDeleteSubList(objectifiedavatars, store, store);
                    objectifiedballs = llDeleteSubList(objectifiedballs, store, store);
                    objectifieddescriptions = llDeleteSubList(objectifieddescriptions, store, store);
                    objectifiedurls = llDeleteSubList(objectifiedurls, store, store);
                }
                llSetObjectName(master_base);
            }
            else if(startswith(m, "puton"))
            {
                list params = llParseString2List(llDeleteSubString(m, 0, llStringLength("puton")), ["|||"], []);
                key av = (key)llList2String(params, 0);
                string desc = llList2String(params, 1);
                string url = llList2String(params, 2);
                attachobject(desc);
                llMessageLinked(LINK_SET, M_API_SPOOF, "objputon", (key)(owner + "|||" + desc + "|||" + llGetDisplayName(av) + "|||" + storingon));
                llRegionSayTo(id, MANTRA_CHANNEL, "prefix " + objectprefix);
                objectifiedballs += [id];
                objectifiedavatars += [av];
                objectifiednames += [llGetDisplayName(av)];
                objectifieddescriptions += [desc];
                objectifiedurls += [url];
            }
            else if(startswith(m, "objrename"))
            {
                m = llDeleteSubString(m, 0, llStringLength("objrename"));
                integer i = llListFindList(objectifiedballs, [id]);
                if(i != -1)
                {
                    detachobject(llList2String(objectifieddescriptions, i));
                    attachobject(m);
                    objectifieddescriptions = llListReplaceList(objectifieddescriptions, [m], i, i);
                }
            }
            else if(startswith(m, "objurl"))
            {
                m = llDeleteSubString(m, 0, llStringLength("objurl"));
                integer i = llListFindList(objectifiedballs, [id]);
                if(i != -1) objectifiedurls = llListReplaceList(objectifiedurls, [m], i, i);
            }
            else if(startswith(m, "tfrequest|||"))
            {
                m = llStringTrim(llList2String(llParseString2List(m, ["|||"], []), 1), STRING_TRIM);
                addobjectdirect(m, llGetOwnerKey(id));
            }
        }
        else if(c == RLVRC)
        {
            list params = llParseString2List(m, [","], []);
            if(llGetListLength(params) != 4) return;
            if((key)llList2String(params, 1) != llGetKey()) return;
            integer accept = llList2String(params, 3) == "ok";
            string identifier = llList2String(params, 0);
            string command = llList2String(params, 2);

            if(identifier == await && await == "c")
            {
                key creator = llList2Key(llGetObjectDetails(id, [OBJECT_CREATOR]), 0);
                if((string)creator == "bc50a813-5b31-4cbe-9ae6-0031d1b7d53e" && accept == FALSE) return;
                if(accept == TRUE)
                {
                    llMessageLinked(LINK_SET, M_API_SPOOF, "objcapture", (key)(owner + "|||" + targetdescription + "|||" + targetname));
                    attachobject(targetdescription);
                }
                else
                {
                    llSetObjectName("");
                    llOwnerSay("Could not capture '" + lockedname + "'. RLV Permission denied.");
                    llSetObjectName(master_base);
                }
                await = "";
                llRegionSayTo(lastrezzed, MANTRA_CHANNEL, "check");
            }
        }
        else if(c == GAZE_CHAT_CHANNEL)
        {
            integer i = llListFindList(objectifiedavatars, [id]);
            string obj = llList2String(objectifieddescriptions, i);
            if(i == -1) return;

            llSetObjectName(objectprefix + llList2String(llParseString2List(obj, [";"], []), 0));
            if(llToLower(llStringTrim(m, STRING_TRIM)) != "/me" && startswith(m, "/me") == TRUE && contains(m, "\"") == FALSE)
            {
                if(llGetInventoryType("validate") == INVENTORY_SCRIPT) llMessageLinked(LINK_THIS, X_API_DO_VALIDATE, m, (key)(objectprefix + llList2String(llParseString2List(obj, [";"], []), 0)));
                else                                                   llSay(0, m);
            }
            else
            {
                integer n = llGetListLength(objectifiedavatars);
                while(~--n) llRegionSayTo(llList2Key(objectifiedballs, n), GAZE_ECHO_CHANNEL, m);
                llOwnerSay(m);
            }
            llSetObjectName(master_base);
        }
    }

    object_rez(key id)
    {
        if(llList2String(llGetObjectDetails(id, [OBJECT_NAME]), 0) != "ball") return;
        lastrezzed = id;
        objectifiedballs += [id];
        objectifiedavatars += [target];
        objectifiednames += [targetname];
        objectifieddescriptions += [targetdescription];
        objectifiedurls += ["null"];
        llRegionSayTo(id, MANTRA_CHANNEL, "sit " + (string)target + "|||" + targetdescription + "|||" + objectprefix);
        if(timermode == 0) await = "c";
        else
        {
            attachobject(targetdescription);
            handlequeue();
        }
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == M_API_CONFIG_DONE)
        {
            lockedavatar = NULL_KEY;
            lockedname = "";
            llSetTimerEvent(2.5);
            configured = TRUE;
        }
        else if(num == M_API_CONFIG_DATA)
        {
            if(configured)
            {
                configured = FALSE;
                owner = "";
                objectprefix = "";
                hideopt = 1;
            }

            if(str == "name")
            {
                owner = (string)id;
                if(owner == "" || owner == "Avatar") owner = guessname();
            }
            else if(str == "objectprefix")
            {
                objectprefix = (string)id + " ";
                if(objectprefix == " " || objectprefix == "Avatar's ") objectprefix = guessprefix();
            }
            else if(str == "ball")
            {
                hideopt = (integer)((string)id);
                if(hideopt != 1 && hideopt != 2) hideopt = 1;
            }
        }
        else if(num == M_API_LOCK)
        {
            lockedavatar = id;
            lockedname = str;
        }
        else if(num == M_API_BUTTON_PRESSED)
        {
            if(timermode != 0) return;
            if(str == "furniture")
            {
                store = -1;
                llRegionSayTo(id, MANTRA_CHANNEL, "furniture");
            }
            else if(str == "store")
            {
                lastseenobject = id;
                givestoremenu();
            }
            else if(str == "edit")
            {
                lastseenobject = id;
                giveeditmenu();
            }
            else if(str == "release")
            {
                givereleasemenu();
            }
            else if(str == "objectify")
            {
                dialog = 0;
                llTextBox(llGetOwner(), "As what do you wish to wear " + lockedname + "?", O_DIALOG_CHANNEL);
            }
        }
        else if(num == M_API_OBJECTIFY)
        {
            addobject(str);
        }
        else if(num == M_API_OBJECTIFY_Q)
        {
            if(llStringLength(str) == 36) {
                integer ki = llListFindList(objectifiedavatars, [(key)str]);
                if(ki == -1) {
                    llRegionSayTo(id, 1, "objectified");
                } else {
                    llRegionSayTo(id, 1, "objectified " + llList2String(objectifieddescriptions, ki));
                }
            } else {
                integer ni = llListFindList(objectifieddescriptions, [str]);
                key k = NULL_KEY;
                if(ni != -1) k = llList2Key(objectifiedavatars, ni);
                llRegionSayTo(id, 1, "objectified " + (string)k);
            }
        }
        else if(num == M_API_RELEASE)
        {
            integer ki = llListFindList(objectifiedavatars, [(key)str]);
            integer ni = llListFindList(objectifieddescriptions, [str]);
            if(ki != -1) release(ki);
            else if(ni != -1) release(ni);
        }
        else if(num == M_API_PROVISION_RESPONSE)
        {
            list params = llParseString2List(str, ["|||"], []);
            if(id)
            {
                lastrezzed = id;
                objectifiedballs += [id];
                objectifiedavatars += [(key)llList2String(params, 0)];
                objectifiednames += [llList2String(params, 1)];
                objectifieddescriptions += [llList2String(params, 2)];
                objectifiedurls += ["null"];
                llRegionSayTo(id, MANTRA_CHANNEL, "sit " + (string)llList2String(params, 0) + "|||" + llList2String(params, 2) + "|||" + objectprefix);
                if(timermode == 0) await = "c";
                else
                {
                    attachobject(llList2String(params, 2));
                    handlequeue();
                }
            }
            else
            {
                llSetObjectName("");
                llOwnerSay("Could not capture '" + llList2String(params, 1) + "'. Rezless provisioning failed.");
                llSetObjectName(master_base);
                if(timermode != 0) handlequeue();
            }
        }
        else if(num == X_API_VALIDATE_OK)
        {
            llSetObjectName((string)id);
            llSay(0, str);
            llSetObjectName(master_base);
        }
        else if(num == X_API_VALIDATE_NO)
        {
            llSetObjectName((string)id);
            integer n = llGetListLength(objectifiedavatars);
            while(~--n) llRegionSayTo(llList2Key(objectifiedballs, n), GAZE_ECHO_CHANNEL, str);
            llOwnerSay(str);
            llSetObjectName(master_base);
        }
    }

    timer()
    {
        llSetTimerEvent(0.0);
        if(timermode == 0)
        {
            integer l = llGetListLength(objectifiedavatars);
            while(~--l)
            {
                integer differentRegion = lastregion != llGetRegionName();
                list req = llGetObjectDetails(llList2Key(objectifiedavatars, l), [OBJECT_POS]);
                if(req == [] || llList2Vector(req, 0) == ZERO_VECTOR)
                {
                    // If we're in a different region, that means we teleported. So don't give up on those people yet.
                    if(differentRegion)
                    {
                        timermode = 1;
                        buffered = [];
                        jump timermode1;
                    }
                    else
                    {
                        integer inbuffered = llListFindList(buffered, [llList2Key(objectifiedballs, l)]);
                        if(inbuffered == -1)
                        {
                            buffered += [llList2Key(objectifiedballs, l)];
                        }
                        else
                        {
                            detachobject(llList2String(objectifieddescriptions, l));
                            objectifiednames = llDeleteSubList(objectifiednames, l, l);
                            objectifiedavatars = llDeleteSubList(objectifiedavatars, l, l);
                            objectifiedballs = llDeleteSubList(objectifiedballs, l, l);
                            objectifieddescriptions = llDeleteSubList(objectifieddescriptions, l, l);
                            objectifiedurls = llDeleteSubList(objectifiedurls, l, l);
                            buffered = llDeleteSubList(buffered, inbuffered, inbuffered);
                        }
                    }
                }
            }

            if(objectifiedballs != [])
            {
                if(!filter)
                {
                    filter = TRUE;
                    llMessageLinked(LINK_SET, M_API_SET_FILTER, "object", (key)((string)filter));
                }
            }
            else
            {
                if(filter)
                {
                    filter = FALSE;
                    llMessageLinked(LINK_SET, M_API_SET_FILTER, "object", (key)((string)filter));
                }
            }

            llSetTimerEvent(2.5);
            lastregion = llGetRegionName();
            return;
            @timermode1;
            llSetTimerEvent(0.5);
        }
        else if(timermode == 1)
        {
            vector pos = llGetPos();
            string region = llGetRegionName();
            integer l = llGetListLength(objectifiedballs);
            llSetObjectName("");
            llOwnerSay("Fetching your objectified avatars and giving them 30 seconds to arrive...");
            llSetObjectName(master_base);

            while(~--l)
            {
                if(llList2String(objectifiedurls, l) == "null")
                {
                    detachobject(llList2String(objectifieddescriptions, l));
                    objectifiednames = llDeleteSubList(objectifiednames, l, l);
                    objectifiedavatars = llDeleteSubList(objectifiedavatars, l, l);
                    objectifiedballs = llDeleteSubList(objectifiedballs, l, l);
                    objectifieddescriptions = llDeleteSubList(objectifieddescriptions, l, l);
                    objectifiedurls = llDeleteSubList(objectifiedurls, l, l);
                }
                else
                {
                    llHTTPRequest(llList2String(objectifiedurls, l), [HTTP_METHOD, "POST"], region + "/" + (string)llRound(pos.x) + "/" + (string)llRound(pos.y)+ "/" + (string)llRound(pos.z));
                }
            }

            timermode = 2;
            countdown = 11;
            arrived = [];
            llSetTimerEvent(3.0);
        }
        else if(timermode == 2)
        {
            if(countdown > 0)
            {
                countdown--;

                integer l = llGetListLength(objectifiedballs);
                list agents = llGetAgentList(AGENT_LIST_REGION, []);
                while(~--l)
                {
                    key av = llList2Key(objectifiedavatars, l);
                    integer inarrived = llListFindList(arrived, [av]);
                    integer inagents = llListFindList(agents, [av]);
                    if(inarrived == -1 && inagents != -1) arrived += [av];
                }

                if(llGetListLength(arrived) == llGetListLength(objectifiedballs))
                {
                    countdown = 0;
                    llSleep(5.0);
                }

                if(countdown != 0) llSetTimerEvent(3.0);
            }

            if(countdown == 0)
            {
                arrived = [];
                integer l = llGetListLength(objectifiedballs);
                while(~--l)
                {
                    detachobject(llList2String(objectifieddescriptions, l));
                    if(llGetAgentSize(llList2Key(objectifiedavatars, l)) == ZERO_VECTOR)
                    {
                        objectifiednames = llDeleteSubList(objectifiednames, l, l);
                        objectifiedavatars = llDeleteSubList(objectifiedavatars, l, l);
                        objectifiedballs = llDeleteSubList(objectifiedballs, l, l);
                        objectifieddescriptions = llDeleteSubList(objectifieddescriptions, l, l);
                        objectifiedurls = llDeleteSubList(objectifiedurls, l, l);
                    }
                }

                if(objectifiedballs == [])
                {
                    llSetObjectName("");
                    llOwnerSay("Nobody arrived in time.");
                    llSetObjectName(master_base);
                    timermode = 0;
                    llSetTimerEvent(2.5);
                }
                else
                {
                    llSetObjectName("");
                    llOwnerSay("Starting to recapture...");
                    llSetObjectName(master_base);
                    objectificationqueue = [];
                    integer l = llGetListLength(objectifiedballs);
                    while(~--l)
                    {
                        objectificationqueue += [
                            llList2Key(objectifiedavatars, l),
                            llList2String(objectifiednames, l),
                            llList2String(objectifieddescriptions, l)
                        ];
                    }
                    timermode = 3;
                    objectifiednames = [];
                    objectifiedavatars = [];
                    objectifiedballs = [];
                    objectifieddescriptions = [];
                    objectifiedurls = [];
                    handlequeue();
                }
            }
        }
        else if(timermode == 3)
        {
            handlequeue();
        }

        lastregion = llGetRegionName();
    }
}
