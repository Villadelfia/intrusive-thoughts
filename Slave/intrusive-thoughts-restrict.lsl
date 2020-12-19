#include <IT/globals.lsl>
key owner = NULL_KEY;
integer noim = FALSE;
string name = "";
string prefix = "xx";
list nearby = [];
string path = "";
string playing = "";
integer daze = FALSE;

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

doSetup()
{
    llSetTimerEvent(0.0);
    llOwnerSay("@accepttp:" + (string)owner + "=add,accepttprequest:" + (string) owner + "=add,acceptpermission=add");
    if(daze) llOwnerSay("@shownames_sec=n,showhovertextworld=n,showworldmap=n,showminimap=n,showloc=n,fartouch=n,camunlock=n,alwaysrun=n,temprun=n");
    else     llOwnerSay("@shownames_sec=y,showhovertextworld=y,showworldmap=y,showminimap=y,showloc=y,fartouch=y,camunlock=y,alwaysrun=y,temprun=y");
    nearby = [];
    playing = "";
    if(noim) llSetTimerEvent(1.0);
}

handleClick(key k)
{
    if(k != owner && llGetOwnerKey(k) != owner && k != llGetOwner()) return;
    string oldn = llGetObjectName();
    llSetObjectName("");
    if(k == owner || llGetOwnerKey(k) == owner)
    {
        llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "List of available commands for " + name + ":");
        llRegionSayTo(owner, HUD_SPEAK_CHANNEL, " ");
    }
    else
    {
        llOwnerSay("List of available commands for " + name + ":");
        llOwnerSay(" ");
    }
    integer numinv = llGetInventoryNumber(INVENTORY_ANIMATION);
    integer i;
    for(i = 0; i < numinv; ++i)
    {
        if(k == owner || llGetOwnerKey(k) == owner)
        {
            llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "[secondlife:///app/chat/1/" + prefix + llEscapeURL(llGetInventoryName(INVENTORY_ANIMATION, i)) + " - Play " + llGetInventoryName(INVENTORY_ANIMATION, i) + " animation.]");
        }
        else
        {
            llOwnerSay("[secondlife:///app/chat/1/" + prefix + llEscapeURL(llGetInventoryName(INVENTORY_ANIMATION, i)) + " - Play " + llGetInventoryName(INVENTORY_ANIMATION, i) + " animation.]");
        }
    }
    if(k == owner || llGetOwnerKey(k) == owner)
    {
        llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "[secondlife:///app/chat/1/" + prefix + "stop - Stop all animations.]");
    }
    else
    {
        llOwnerSay("[secondlife:///app/chat/1/" + prefix + "stop - Stop all animations.]");
    }

    if(k == owner || llGetOwnerKey(k) == owner)
    {
        llRegionSayTo(owner, HUD_SPEAK_CHANNEL, " ");
        llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "[secondlife:///app/chat/1/" + prefix + "noim - Toggle local IMs.]");
        llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "[secondlife:///app/chat/1/" + prefix + "strip - Strip all clothes.]");
        llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "[secondlife:///app/chat/1/" + prefix + "listform - List all forms.]");
        llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "[secondlife:///app/chat/1/" + prefix + "listoutfit - List all outfits.]");
        llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "[secondlife:///app/chat/1/" + prefix + "liststuff - List all stuff.]");
        llRegionSayTo(owner, HUD_SPEAK_CHANNEL, " ");
        llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "- Toggle [secondlife:///app/chat/1/" + prefix + "deaf deafness]/[secondlife:///app/chat/1/" + prefix + "blind blindness]/[secondlife:///app/chat/1/" + prefix + "mute muting]/[secondlife:///app/chat/1/" + prefix + "daze dazing.]");
        llRegionSayTo(owner, HUD_SPEAK_CHANNEL, " ");
        llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "- /1" + prefix + "say <message>: Say a message.");
        llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "- /1" + prefix + "think <message>: Think a message.");
    }
    llSetObjectName(oldn);
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
        if(change & CHANGED_TELEPORT) 
        {
            string oldn = llGetObjectName();
            llSetObjectName("");
            if(llGetAgentSize(owner) != ZERO_VECTOR) llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "secondlife:///app/agent/" + (string)llGetOwner() + "/about has arrived at " + slurl() + ".");
            else                                     llInstantMessage(owner, "secondlife:///app/agent/" + (string)llGetOwner() + "/about has arrived at " + slurl() + ".");
            llSetObjectName(oldn);
        }
    }

    attach(key id)
    {
        if(id != NULL_KEY) 
        {
            doSetup();
            llRequestPermissions(llGetOwner(), PERMISSION_TAKE_CONTROLS | PERMISSION_TRIGGER_ANIMATION);
            string oldn = llGetObjectName();
            llSetObjectName("");
            if(llGetAgentSize(owner) != ZERO_VECTOR) llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "The intrusive thoughts slave has been worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about at " + slurl() + ".");
            else                                     llInstantMessage(owner, "The intrusive thoughts slave has been worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about at " + slurl() + ".");
            llSetObjectName(oldn);
        }
        else
        {
            llSetTimerEvent(0.0);
            string oldn = llGetObjectName();
            llSetObjectName("");
            if(llGetAgentSize(owner) != ZERO_VECTOR) llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "The intrusive thoughts slave has been taken off by secondlife:///app/agent/" + (string)llGetOwner() + "/about at " + slurl() + ".");
            else                                     llInstantMessage(owner, "The intrusive thoughts slave has been taken off by secondlife:///app/agent/" + (string)llGetOwner() + "/about at " + slurl() + ".");
            llSetObjectName(oldn);
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
        name = llGetDisplayName(llGetOwner());
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
        llListen(RLV_CHANNEL, "", llGetOwner(), "");
        llListen(1, "", owner, "");
        llListen(1, "", llGetOwner(), "");
        llRequestPermissions(llGetOwner(), PERMISSION_TAKE_CONTROLS | PERMISSION_TRIGGER_ANIMATION);
    }

    touch_start(integer num)
    {
        handleClick(llDetectedKey(0));
    }

    listen(integer c, string n, key k, string m)
    {
        if(c == RLV_CHANNEL)
        {
            if(path != "~") 
            {
                list stuff = llParseString2List(m, [","], []);
                stuff = llListSort(stuff, 1, TRUE);
                string message;
                string thing;
                integer l;
                integer i;
                if(path == "~form")
                {
                    llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "Available forms for " + name + ":");
                    llRegionSayTo(owner, HUD_SPEAK_CHANNEL, " ");
                    l = llGetListLength(stuff);
                    for(i = 0; i < l; ++i)
                    {
                        thing = llList2String(stuff, i);
                        llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "[secondlife:///app/chat/1/" + prefix + llEscapeURL("form " + thing) + " " + thing + "]");
                    }
                    llRegionSayTo(owner, HUD_SPEAK_CHANNEL, " ");
                    llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "[secondlife:///app/chat/1/" + prefix + "! Back to command list...]");
                }
                else if(path == "~outfit")
                {
                    llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "Available outfits for " + name + ":");
                    llRegionSayTo(owner, HUD_SPEAK_CHANNEL, " ");
                    l = llGetListLength(stuff);
                    for(i = 0; i < l; ++i)
                    {
                        thing = llList2String(stuff, i);
                        message  = "[secondlife:///app/chat/1/" + prefix + llEscapeURL("outfit " + thing) + " " + thing + "] ";
                        message += "[secondlife:///app/chat/1/" + prefix + llEscapeURL("outfitstrip " + thing) + " (strip first)]";
                        llRegionSayTo(owner, HUD_SPEAK_CHANNEL, message);
                    }
                    llRegionSayTo(owner, HUD_SPEAK_CHANNEL, " ");
                    llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "[secondlife:///app/chat/1/" + prefix + "! Back to command list...]");
                }
                else if(path == "~stuff")
                {
                    llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "Available stuff for " + name + ":");
                    llRegionSayTo(owner, HUD_SPEAK_CHANNEL, " ");
                    l = llGetListLength(stuff);
                    for(i = 0; i < l; ++i)
                    {
                        thing = llList2String(stuff, i);
                        message =  thing + " ";
                        message += "[secondlife:///app/chat/1/" + prefix + llEscapeURL("add " + thing) + " (+) ]";
                        message += "[secondlife:///app/chat/1/" + prefix + llEscapeURL("remove " + thing) + " (-)]";
                        llRegionSayTo(owner, HUD_SPEAK_CHANNEL, message);
                    }
                    llRegionSayTo(owner, HUD_SPEAK_CHANNEL, " ");
                    llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "[secondlife:///app/chat/1/" + prefix + "! Back to command list...]");
                }
                else
                {
                    if(path != "") path += "/";
                    llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "RLV folders in #RLV/" + path + " for " + name + ":");
                    llRegionSayTo(owner, HUD_SPEAK_CHANNEL, " ");
                    l = llGetListLength(stuff);
                    for(i = 0; i < l; ++i)
                    {
                        thing = llList2String(stuff, i);
                        message =  "[secondlife:///app/chat/1/" + prefix + llEscapeURL("list " + path + thing) + " " + thing + "] ";
                        message += "[secondlife:///app/chat/1/" + prefix + llEscapeURL("+ " + path + thing) + " (+)] ";
                        message += "[secondlife:///app/chat/1/" + prefix + llEscapeURL("- " + path + thing) + " (-)]";
                        llRegionSayTo(owner, HUD_SPEAK_CHANNEL, message);
                    }
                    llRegionSayTo(owner, HUD_SPEAK_CHANNEL, " ");
                }
            }
            else
            {
                llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "RLV command response for " + name + ":\n" + m);
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
        else if(c == 1 && llToLower(m) == "!")
        {
            handleClick(k);
        }

        // Starting here, only the Domme may give commands.
        if(k != owner && llGetOwnerKey(k) != owner) return;
        if(m == "RESET" && c == MANTRA_CHANNEL)
        {
            name = "";
            noim = FALSE;
            daze = FALSE;
        }
        else if(startswith(m, "NAME") && c == MANTRA_CHANNEL)
        {
            m = llDeleteSubString(m, 0, llStringLength("NAME"));
            name = m;
        }
        else if(m == "END" && c == MANTRA_CHANNEL)
        {
            llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "[" + llGetScriptName() + "]: " + (string)(llGetFreeMemory() / 1024.0) + "kb free.");
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
            llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "Stripping " + name + " of all clothes.");
            llOwnerSay("@detach=force,remoutfit=force");
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
            llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "Stripping " + name + " of her outfits, then wearing outfit '" + path + "'.");
            llOwnerSay("@detachall:~outfit=force,attachover:~outfit/" + path + "=force");
        }
        else if(startswith(llToLower(m), "outfitstrip"))
        {
            path = llDeleteSubString(m, 0, llStringLength("outfitstrip"));
            llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "Stripping " + name + " of everything, then wearing outfit '" + path + "'.");
            llOwnerSay("@detach=force,remoutfit=force,attachover:~outfit/" + path + "=force");
        }
        else if(startswith(llToLower(m), "form"))
        {
            path = llDeleteSubString(m, 0, llStringLength("form"));
            llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "Stripping " + name + " of all clothes, then wearing form '" + path + "'.");
            llOwnerSay("@detach=force,attachover:~form/" + path + "=force");
        }
        else if(startswith(llToLower(m), "add"))
        {
            path = llDeleteSubString(m, 0, llStringLength("add"));
            llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "Wearing '~stuff/" + path + "' on " + name + ".");
            llOwnerSay("@attachover:~stuff/" + path + "=force");
        }
        else if(startswith(llToLower(m), "remove"))
        {
            path = llDeleteSubString(m, 0, llStringLength("remove"));
            llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "Removing '~stuff/" + path + "' from " + name + ".");
            llOwnerSay("@detachall:~stuff/" + path + "=force");
        }
        else if(startswith(m, "think"))
        {
            m = llDeleteSubString(m, 0, llStringLength("think"));
            llMessageLinked(LINK_SET, API_SELF_DESC, m, NULL_KEY);
        }
        else if(startswith(m, "say"))
        {
            m = llDeleteSubString(m, 0, llStringLength("say"));
            llMessageLinked(LINK_SET, API_SAY, m, (key)name);
        }
        else if(llToLower(m) == "deafen" || llToLower(m) == "deaf")
        {
            llMessageLinked(LINK_SET, API_DEAF_TOGGLE, "", NULL_KEY);
        }
        else if(llToLower(m) == "blind")
        {
            llMessageLinked(LINK_SET, API_BLIND_TOGGLE, "", NULL_KEY);
        }
        else if(llToLower(m) == "mute")
        {
            llMessageLinked(LINK_SET, API_MUTE_TOGGLE, "", NULL_KEY);
        }
        else if(llToLower(m) == "daze")
        {
            if(daze)
            {
                daze = FALSE;
                llRegionSayTo(owner, HUD_SPEAK_CHANNEL, name + " is no longer dazed.");
                llOwnerSay("@shownames_sec=y,showhovertextworld=y,showworldmap=y,showminimap=y,showloc=y,fartouch=y,camunlock=y,alwaysrun=y,temprun=y");
            }
            else
            {
                daze = TRUE;
                llRegionSayTo(owner, HUD_SPEAK_CHANNEL, name + " is now dazed.");
                llOwnerSay("@shownames_sec=n,showhovertextworld=n,showworldmap=n,showminimap=n,showloc=n,fartouch=n,camunlock=n,alwaysrun=n,temprun=n");
            }
        }
        else if(startswith(m, "@"))
        {
            m = strreplace(m, "RLV_CHANNEL", (string)RLV_CHANNEL);
            path = "~";
            llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "Executing RLV command'" + m + "' on " + name + ".");
            llOwnerSay(m);
        }
    }

    timer()
    {
        doScan();
    }
}