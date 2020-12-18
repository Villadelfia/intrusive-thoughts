#define MANTRA_CHANNEL -216684563
#define VOICE_CHANNEL   166845631
#define RLV_CHANNEL     166845630
#define MC_CHANNEL            999
#define API_RESET              -1
#define API_SELF_DESC          -2
#define API_SELF_SAY           -3
#define API_SAY                -4
key owner = NULL_KEY;
integer noim = FALSE;
string name = "";
string prefix = "xx";
list nearby = [];
string path = "";
string playing = "";

doScan()
{
    llSetTimerEvent(0.0);
    if(!noim)
    {
        llOwnerSay("@clear=recvimfrom,clear=sendimto");
        nearby = [];
        llMessageLinked(LINK_SET, API_SAY, "/me can IM with people within 20 meters of them again.", (key)name);
        return;
    }
    list check = llGetAgentList(AGENT_LIST_REGION, []);
    vector pos = llGetPos();

    // Filter by distance.
    integer l = llGetListLength(check);
    integer i;
    key k;
    for(l--; l >= 0; l--)
    {
        k = llList2Key(check, l);
        if(llVecDist(pos, llList2Vector(llGetObjectDetails(k, [OBJECT_POS]), 0)) > 19.5) check = llDeleteSubList(check, l, l);
    }
    
    // Check for every key in nearby, remove restriction if no longer present.
    l = llGetListLength(nearby);
    for(l--; l >= 0; l--)
    {
        k = llList2Key(nearby, l);
        i = llListFindList(check, [k]);
        if(i == -1) 
        {
            llOwnerSay("@recvimfrom:" + (string)k +"=y,sendimto:" + (string)k +"=y");
            nearby = llDeleteSubList(nearby, l, l);
        }
    }
    
    // Check for newly arrived people, add restriction.
    l = llGetListLength(check);
    for(l--; l >= 0; l--)
    {
        k = llList2Key(check, l);
        i = llListFindList(nearby, [k]);
        if(i == -1 && llGetAgentSize(k) != ZERO_VECTOR && k != (key)NULL_KEY && k != owner)
        {
            llOwnerSay("@recvimfrom:" + (string)k +"=n,sendimto:" + (string)k +"=n");
            nearby += [k];
        }
    }
    llSetTimerEvent(1.0);
}

integer getStringBytes(string msg)
{
    return (llStringLength((string)llParseString2List(llStringToBase64(msg), ["="], [])) * 3) >> 2;
}

integer contains(string haystack, string needle)
{
    return ~llSubStringIndex(haystack, needle);
}

integer endswith(string haystack, string needle)
{
    return llDeleteSubString(haystack, 0x8000000F, ~llStringLength(needle)) == needle;
}

integer startswith(string haystack, string needle)
{
    return llDeleteSubString(haystack, llStringLength(needle), 0x7FFFFFF0) == needle;
}

string slurl()
{
    vector pos = llGetPos();
    return "http://maps.secondlife.com/secondlife/" + llEscapeURL(llGetRegionName()) + "/" + (string)llRound(pos.x) + "/" + (string)llRound(pos.y) + "/" + (string)llRound(pos.z) + "/";
}

string strreplace(string source, string pattern, string replace) 
{
    while (llSubStringIndex(source, pattern) > -1) 
    {
        integer len = llStringLength(pattern);
        integer pos = llSubStringIndex(source, pattern);
        if (llStringLength(source) == len) { source = replace; }
        else if (pos == 0) { source = replace+llGetSubString(source, pos+len, -1); }
        else if (pos == llStringLength(source)-len) { source = llGetSubString(source, 0, pos-1)+replace; }
        else { source = llGetSubString(source, 0, pos-1)+replace+llGetSubString(source, pos+len, -1); }
    }
    return source;
}

doSetup()
{
    llSetTimerEvent(0.0);
    llOwnerSay("@accepttp:" + (string)owner + "=add,accepttprequest:" + (string) owner + "=add,acceptpermission=add");
    nearby = [];
    playing = "";
    if(noim) llSetTimerEvent(1.0);
}

default
{
    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == API_RESET && id == llGetOwner()) llResetScript();
    }

    changed(integer change)
    {
        if(change & CHANGED_OWNER) llResetScript();
        if(change & CHANGED_TELEPORT) llInstantMessage(owner, "secondlife:///app/agent/" + (string)llGetOwner() + "/about has arrived at " + slurl() + ".");
    }

    attach(key id)
    {
        if(id != NULL_KEY) 
        {
            doSetup();
            llRequestPermissions(llGetOwner(), PERMISSION_TAKE_CONTROLS | PERMISSION_TRIGGER_ANIMATION);
            llInstantMessage(owner, "The intrusive thoughts slave has been worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about at " + slurl() + ".");
        }
        else
        {
            llSetTimerEvent(0.0);
            llInstantMessage(owner, "The intrusive thoughts slave has been taken off by secondlife:///app/agent/" + (string)llGetOwner() + "/about at " + slurl() + ".");
        }
    }

    run_time_permissions(integer perm)
    {
        if(perm & PERMISSION_TAKE_CONTROLS) llTakeControls(CONTROL_FWD, FALSE, TRUE);
    }

    state_entry()
    {
        owner = llList2Key(llGetObjectDetails(llGetKey(), [OBJECT_LAST_OWNER_ID]), 0);
        prefix = llGetSubString(llGetUsername(llGetOwner()), 0, 1);
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
        llListen(RLV_CHANNEL, "", llGetOwner(), "");
        llListen(1, "", owner, "");
        llListen(1, "", llGetOwner(), "");
        llRequestPermissions(llGetOwner(), PERMISSION_TAKE_CONTROLS | PERMISSION_TRIGGER_ANIMATION);
    }

    listen(integer c, string n, key k, string m)
    {
        if(c == RLV_CHANNEL)
        {
            if(path != "~") 
            {
                list stuff = llParseString2List(m, [","], []);
                stuff = llListSort(stuff, 1, TRUE);
                llRegionSayTo(owner, 0, "RLV folders in #RLV/" + path + ":\n" + llDumpList2String(stuff, "\n"));
            }
            else
            {
                llRegionSayTo(owner, 0, "RLV command response: " + m);
            }
            llRegionSay(RLV_CHANNEL, m);
            return;
        }
        if(c == 1)
        {
            if(startswith(m, "#") && k == llGetOwner()) return;
            if(startswith(m, prefix))                         m = llDeleteSubString(m, 0, 1);
            else if(startswith(m, "*") || startswith(m, "#")) m = llDeleteSubString(m, 0, 0);
            else                                              return;
        }
        if(c == 1 && llGetInventoryType(m) == INVENTORY_ANIMATION)
        {
            if(playing != "") llStopAnimation(playing);
            playing = m;
            llStartAnimation(playing);
            return;
        }
        else if(c == 1 && llToLower(m) == "stop")
        {
            if(playing != "") llStopAnimation(playing);
            playing = "";
            return;
        }

        // Starting here, only the sub's Domme may give commands.
        if(k != owner && llGetOwnerKey(k) != owner) return;
        if(m == "RESET" && c == MANTRA_CHANNEL)
        {
            name = "";
            noim = FALSE;
        }
        else if(startswith(m, "NAME") && c == MANTRA_CHANNEL)
        {
            m = llDeleteSubString(m, 0, llStringLength("NAME"));
            name = m;
        }
        else if(m == "END")
        {
            llRegionSayTo(owner, 0, "[" + llGetScriptName() + "]: " + (string)(llGetFreeMemory() / 1024.0) + "kb free.");
        }
        else if(llToLower(m) == "noim")
        {
            if(noim)
            {
                noim = FALSE;
            }
            else
            {
                llMessageLinked(LINK_SET, API_SAY, "/me can no longer IM with people within 20 meters of them.", (key)name);
                noim = TRUE;
                llSetTimerEvent(1.0);
            }
        }
        else if(llToLower(m) == "list")
        {
            path = "";
            llOwnerSay("@getinv=" + (string)RLV_CHANNEL);
        }
        else if(llToLower(m) == "strip")
        {
            llRegionSayTo(owner, 0, "Stripping " + name + " of all clothes.");
            llOwnerSay("@detach=force");
        }
        else if(llToLower(m) == "listoutfit")
        {
            path = "~outfit";
            llOwnerSay("@getinv:~outfit=" + (string)RLV_CHANNEL);
        }
        else if(llToLower(m) == "liststuff")
        {
            path = "~stuff";
            llOwnerSay("@getinv:~stuff=" + (string)RLV_CHANNEL);
        }
        else if(llToLower(m) == "listform")
        {
            path = "~form";
            llOwnerSay("@getinv:~stuff=" + (string)RLV_CHANNEL);
        }
        else if(startswith(llToLower(m), "list"))
        {
            path = llDeleteSubString(m, 0, llStringLength("list"));
            llOwnerSay("@getinv:" + path + "=" + (string)RLV_CHANNEL);
        }
        else if(startswith(llToLower(m), "outfit"))
        {
            path = llDeleteSubString(m, 0, llStringLength("outfit"));
            llRegionSayTo(owner, 0, "Stripping " + name + " of her outfit, then wearing outfit '" + path + "'.");
            llOwnerSay("@detachall:~outfit=force,attachover:~outfit/" + path + "=force");
        }
        else if(startswith(llToLower(m), "outfitstrip"))
        {
            path = llDeleteSubString(m, 0, llStringLength("outfitstrip"));
            llRegionSayTo(owner, 0, "Stripping " + name + " of all clothes, then wearing outfit '" + path + "'.");
            llOwnerSay("@detach=force,attachover:~outfit/" + path + "=force");
        }
        else if(startswith(llToLower(m), "form"))
        {
            path = llDeleteSubString(m, 0, llStringLength("form"));
            llRegionSayTo(owner, 0, "Stripping " + name + " of all clothes, then wearing form '" + path + "'.");
            llOwnerSay("@detach=force,attachover:~form/" + path + "=force");
        }
        else if(startswith(llToLower(m), "add"))
        {
            path = llDeleteSubString(m, 0, llStringLength("add"));
            llRegionSayTo(owner, 0, "Wearing '~stuff/" + path + "' on " + name + ".");
            llOwnerSay("@attachover:~stuff/" + path + "=force");
        }
        else if(startswith(llToLower(m), "remove"))
        {
            path = llDeleteSubString(m, 0, llStringLength("remove"));
            llRegionSayTo(owner, 0, "Removing '~stuff/" + path + "' from " + name + ".");
            llOwnerSay("@detachall:~stuff/" + path + "=force");
        }
        else if(startswith(llToLower(m), "+"))
        {
            path = llDeleteSubString(m, 0, 0);
            llRegionSayTo(owner, 0, "Wearing '~stuff/" + path + "' on " + name + ".");
            llOwnerSay("@attachover:~stuff/" + path + "=force");
        }
        else if(startswith(llToLower(m), "-"))
        {
            path = llDeleteSubString(m, 0, 0);
            llRegionSayTo(owner, 0, "Removing '~stuff/" + path + "' from " + name + ".");
            llOwnerSay("@detachall:~stuff/" + path + "=force");
        }
        else if(startswith(m, "@"))
        {
            m = strreplace(m, "RLV_CHANNEL", (string)RLV_CHANNEL);
            path = "~";
            llRegionSayTo(owner, 0, "Executing RLV command'" + m + "' on " + name + ".");
            llOwnerSay(m);
        }
    }

    timer()
    {
        doScan();
    }
}