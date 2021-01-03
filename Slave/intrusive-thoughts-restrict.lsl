#include <IT/globals.lsl>
key requester;
key primary = NULL_KEY;
list owners = [];

integer noim = FALSE;
integer onball = FALSE;
key ball;
string name = "";
string prefix = "xx";
string path = "";
string playing = "";
integer daze = FALSE;
integer locked = FALSE;

doSetup()
{
    llOwnerSay("@accepttp:" + (string)primary + "=add,accepttprequest:" + (string)primary + "=add,acceptpermission=add");

    if(daze) llOwnerSay("@shownames_sec=n,showhovertextworld=n,showworldmap=n,showminimap=n,showloc=n,fartouch=n,camunlock=n,alwaysrun=n,temprun=n");
    else     llOwnerSay("@shownames_sec=y,showhovertextworld=y,showworldmap=y,showminimap=y,showloc=y,fartouch=y,camunlock=y,alwaysrun=y,temprun=y");
    playing = "";
    if(noim)
    {
        llMessageLinked(LINK_SET, S_API_SAY, "/me can not IM with people within 20 meters of them.", (key)name);
        llOwnerSay("@recvim:20=n,sendim:20=n,sendim:" + (string)primary + "=add,recvim:" + (string)primary + "=add");
    }
    else
    {
        llOwnerSay("@recvim:20=y,sendim:20=y,sendim:" + (string)primary + "=rem,recvim:" + (string)primary + "=rem");
    }

    if(locked)
    {
        llOwnerSay("@detach=n");
        llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES);
    }
}

handlemenu(key k)
{
    if(isowner(k) == FALSE && llGetOwnerKey(k) != llGetOwner()) return;
    string oldn = llGetObjectName();
    llSetObjectName("");

    // Greeting
    ownersay(k, "List of available commands for " + name + ":");
    ownersay(k, " ");

    // Animations
    integer numinv = llGetInventoryNumber(INVENTORY_ANIMATION);
    integer i;
    for(i = 0; i < numinv; ++i)
    {
        ownersay(k, "[secondlife:///app/chat/1/" + prefix + llEscapeURL(llGetInventoryName(INVENTORY_ANIMATION, i)) + " - Play " + llGetInventoryName(INVENTORY_ANIMATION, i) + " animation.]");
    }

    // Stop animation
    ownersay(k, "[secondlife:///app/chat/1/" + prefix + "stop - Stop all animations.]");

    // Owner commands.
    if(isowner(k))
    {
        ownersay(k, " ");
        ownersay(k, "[secondlife:///app/chat/1/" + prefix + "noim - Toggle local IMs.]");
        ownersay(k, "[secondlife:///app/chat/1/" + prefix + "strip - Strip all clothes.]");
        ownersay(k, "[secondlife:///app/chat/1/" + prefix + "listform - List all forms.]");
        ownersay(k, "[secondlife:///app/chat/1/" + prefix + "listoutfit - List all outfits.]");
        ownersay(k, "[secondlife:///app/chat/1/" + prefix + "liststuff - List all stuff.]");
        ownersay(k, "[secondlife:///app/chat/1/" + prefix + "stand - Stand up.]");
        ownersay(k, "[secondlife:///app/chat/1/" + prefix + "leash - Leash]/[secondlife:///app/chat/1/" + prefix + "unleash unleash.]");
        if(llGetOwnerKey(k) == primary) ownersay(k, "[secondlife:///app/chat/1/" + prefix + "ownerinfo - Add/remove secondary owners.]");
        ownersay(k, " ");
        ownersay(k, "- Toggle [secondlife:///app/chat/1/" + prefix + "deaf deafness]/[secondlife:///app/chat/1/" + prefix + "blind blindness]/[secondlife:///app/chat/1/" + prefix + "mute muting]/[secondlife:///app/chat/1/" + prefix + "daze dazing]/[secondlife:///app/chat/1/" + prefix + "focus focussing]/[secondlife:///app/chat/1/" + prefix + "lock lock].");
        ownersay(k, " ");
        ownersay(k, "- /1" + prefix + "say <message>: Say a message.");
        ownersay(k, "- /1" + prefix + "think <message>: Think a message.");
        ownersay(k, "- /1" + prefix + "leashlength <meters>: Set the leash length.");
    }

    llSetObjectName(oldn);
}

default
{
    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == S_API_STARTED)
        {
            doSetup();
            llRequestPermissions(llGetOwner(), PERMISSION_TAKE_CONTROLS | PERMISSION_TRIGGER_ANIMATION);
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
        
    }

    changed(integer change)
    {
        if(change & CHANGED_TELEPORT) 
        {
            string oldn = llGetObjectName();
            llSetObjectName("");
            if(llGetAgentSize(primary) != ZERO_VECTOR) ownersay(primary, "secondlife:///app/agent/" + (string)llGetOwner() + "/about has arrived at " + slurl() + ".");
            else
            {
                llSetObjectName(oldn);
                llInstantMessage(primary, "secondlife:///app/agent/" + (string)llGetOwner() + "/about has arrived at " + slurl() + ".");
            }
            llSetObjectName(oldn);
        }
    }

    attach(key id)
    {
        if(id == NULL_KEY) onball = FALSE;
    }

    run_time_permissions(integer perm)
    {
        if(perm & PERMISSION_TAKE_CONTROLS) llTakeControls(CONTROL_FWD, FALSE, TRUE);
    }

    touch_start(integer num)
    {
        handlemenu(llDetectedKey(0));
    }

    state_entry()
    {
        llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES);
        prefix = llGetSubString(llGetUsername(llGetOwner()), 0, 1);
        name = llGetDisplayName(llGetOwner());
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
        llListen(RLV_CHANNEL, "", llGetOwner(), "");
        llListen(COMMAND_CHANNEL, "", NULL_KEY, "");
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
                string message;
                string thing;
                integer l;
                integer i;
                if(path == "~form")
                {
                    ownersay(requester, "Available forms for " + name + ":");
                    ownersay(requester, " ");
                    l = llGetListLength(stuff);
                    for(i = 0; i < l; ++i)
                    {
                        thing = llList2String(stuff, i);
                        ownersay(requester, "[secondlife:///app/chat/1/" + prefix + llEscapeURL("form " + thing) + " " + thing + "]");
                    }
                    ownersay(requester, " ");
                    ownersay(requester, "[secondlife:///app/chat/1/" + prefix + "! Back to command list...]");
                }
                else if(path == "~outfit")
                {
                    ownersay(requester, "Available outfits for " + name + ":");
                    ownersay(requester, " ");
                    l = llGetListLength(stuff);
                    for(i = 0; i < l; ++i)
                    {
                        thing = llList2String(stuff, i);
                        message  = "[secondlife:///app/chat/1/" + prefix + llEscapeURL("outfit " + thing) + " " + thing + "] ";
                        message += "[secondlife:///app/chat/1/" + prefix + llEscapeURL("outfitstrip " + thing) + " (strip first)]";
                        ownersay(requester, message);
                    }
                    ownersay(requester, " ");
                    ownersay(requester, "[secondlife:///app/chat/1/" + prefix + "! Back to command list...]");
                }
                else if(path == "~stuff")
                {
                    ownersay(requester, "Available stuff for " + name + ":");
                    ownersay(requester, " ");
                    l = llGetListLength(stuff);
                    for(i = 0; i < l; ++i)
                    {
                        thing = llList2String(stuff, i);
                        message =  thing + " ";
                        message += "[secondlife:///app/chat/1/" + prefix + llEscapeURL("add " + thing) + " (+) ]";
                        message += "[secondlife:///app/chat/1/" + prefix + llEscapeURL("remove " + thing) + " (-)]";
                        ownersay(requester, message);
                    }
                    ownersay(requester, " ");
                    ownersay(requester, "[secondlife:///app/chat/1/" + prefix + "! Back to command list...]");
                }
                else
                {
                    if(path != "") path += "/";
                    ownersay(requester, "RLV folders in #RLV/" + path + " for " + name + ":");
                    ownersay(requester, " ");
                    l = llGetListLength(stuff);
                    for(i = 0; i < l; ++i)
                    {
                        thing = llList2String(stuff, i);
                        message =  "[secondlife:///app/chat/1/" + prefix + llEscapeURL("list " + path + thing) + " " + thing + "] ";
                        message += "[secondlife:///app/chat/1/" + prefix + llEscapeURL("+ " + path + thing) + " (+)] ";
                        message += "[secondlife:///app/chat/1/" + prefix + llEscapeURL("- " + path + thing) + " (-)]";
                        ownersay(requester, message);
                    }
                    ownersay(requester, " ");
                }
            }
            else
            {
                ownersay(requester, "RLV command response for " + name + ":\n" + m);
            }
            llRegionSay(RLV_CHANNEL, m);
            return;
        }

        // We only accept commands from the owner or the wearer.
        if(llGetOwnerKey(k) != llGetOwner() && isowner(k) == FALSE) return;

        // Detect prefix.
        if(c == COMMAND_CHANNEL)
        {
            if(startswith(m, "#") && k == llGetOwner()) return;
            if(startswith(m, prefix))                         m = llDeleteSubString(m, 0, 1);
            else if(startswith(m, "*") || startswith(m, "#")) m = llDeleteSubString(m, 0, 0);
            else                                              return;
        }
        
        // Handle animation and menu commands.
        if(c == COMMAND_CHANNEL)
        {
            if(llGetInventoryType(m) == INVENTORY_ANIMATION)
            {
                if(playing != "") llStopAnimation(playing);
                playing = m;
                llStartAnimation(playing);
                return;
            }
            else if(llToLower(m) == "stop")
            {
                if(playing != "") llStopAnimation(playing);
                playing = "";
                return;
            }
            else if(llToLower(m) == "!" || m == "" || llToLower(m) == "menu")
            {
                handlemenu(k);
            }
        }

        // Starting here, only the Domme may give commands.
        if(!isowner(k)) return;
        requester = k;

        if(c == MANTRA_CHANNEL)
        {
            if(m == "RESET")
            {
                name = llGetDisplayName(llGetOwner());
                noim = FALSE;
                daze = FALSE;
            }
            else if(startswith(m, "NAME"))
            {
                m = llDeleteSubString(m, 0, llStringLength("NAME"));
                name = m;
            }
            else if(m == "END")
            {
                ownersay(k, "[restrict]: " + (string)(llGetFreeMemory() / 1024.0) + "kb free.");
            }
        }
        
        if(llToLower(m) == "noim")
        {
            if(noim)
            {
                llMessageLinked(LINK_SET, S_API_SAY, "/me can IM with people within 20 meters of them again.", (key)name);
                llOwnerSay("@recvim:20=y,sendim:20=y,sendim:" + (string)primary + "=rem,recvim:" + (string)primary + "=rem");
                noim = FALSE;
            }
            else
            {
                llMessageLinked(LINK_SET, S_API_SAY, "/me can no longer IM with people within 20 meters of them.", (key)name);
                llOwnerSay("@recvim:20=n,sendim:20=n,sendim:" + (string)primary + "=add,recvim:" + (string)primary + "=add");
                noim = TRUE;
            }
        }
        else if(llToLower(m) == "strip")
        {
            ownersay(k, "Stripping " + name + " of all clothes.");
            llOwnerSay("@detach=force,remoutfit=force");
        }
        else if(llToLower(m) == "list")
        {
            path = "";
            llOwnerSay("@getinv=" + (string)RLV_CHANNEL);
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
        else if(startswith(llToLower(m), "outfitstrip"))
        {
            path = llDeleteSubString(m, 0, llStringLength("outfitstrip"));
            ownersay(k, "Stripping " + name + " of everything, then wearing outfit '" + path + "'.");
            llOwnerSay("@detach=force,remoutfit=force,attachover:~outfit/" + path + "=force");
        }
        else if(startswith(llToLower(m), "outfit"))
        {
            path = llDeleteSubString(m, 0, llStringLength("outfit"));
            ownersay(k, "Stripping " + name + " of her outfits, then wearing outfit '" + path + "'.");
            llOwnerSay("@detachall:~outfit=force,attachover:~outfit/" + path + "=force");
        }
        else if(startswith(llToLower(m), "form"))
        {
            path = llDeleteSubString(m, 0, llStringLength("form"));
            ownersay(k, "Stripping " + name + " of all clothes, then wearing form '" + path + "'.");
            llOwnerSay("@detach=force,attachover:~form/" + path + "=force");
        }
        else if(startswith(llToLower(m), "add"))
        {
            path = llDeleteSubString(m, 0, llStringLength("add"));
            ownersay(k, "Wearing '~stuff/" + path + "' on " + name + ".");
            llOwnerSay("@attachover:~stuff/" + path + "=force");
        }
        else if(startswith(llToLower(m), "remove"))
        {
            path = llDeleteSubString(m, 0, llStringLength("remove"));
            ownersay(k, "Removing '~stuff/" + path + "' from " + name + ".");
            llOwnerSay("@detachall:~stuff/" + path + "=force");
        }
        else if(startswith(m, "think"))
        {
            m = llDeleteSubString(m, 0, llStringLength("think"));
            llMessageLinked(LINK_SET, S_API_SELF_DESC, m, NULL_KEY);
        }
        else if(startswith(m, "say"))
        {
            m = llDeleteSubString(m, 0, llStringLength("say"));
            llMessageLinked(LINK_SET, S_API_SAY, m, (key)name);
        }
        else if(llToLower(m) == "deafen" || llToLower(m) == "deaf")
        {
            llMessageLinked(LINK_SET, S_API_DEAF_TOGGLE, "", k);
        }
        else if(llToLower(m) == "blind")
        {
            llMessageLinked(LINK_SET, S_API_BLIND_TOGGLE, "", k);
        }
        else if(llToLower(m) == "mute")
        {
            llMessageLinked(LINK_SET, S_API_MUTE_TOGGLE, "", k);
        }
        else if(llToLower(m) == "daze")
        {
            if(daze)
            {
                daze = FALSE;
                ownersay(k, name + " is no longer dazed.");
                llOwnerSay("@shownames_sec=y,showhovertextworld=y,showworldmap=y,showminimap=y,showloc=y,fartouch=y,camunlock=y,alwaysrun=y,temprun=y");
            }
            else
            {
                daze = TRUE;
                ownersay(k, name + " is now dazed.");
                llOwnerSay("@shownames_sec=n,showhovertextworld=n,showworldmap=n,showminimap=n,showloc=n,fartouch=n,camunlock=n,alwaysrun=n,temprun=n");
            }
        }
        else if(llToLower(m) == "focus")
        {
            llMessageLinked(LINK_SET, S_API_FOCUS_TOGGLE, "", k);
        }
        else if(startswith(llToLower(m), "onball"))
        {
            llMessageLinked(LINK_SET, S_API_DISABLE, "", NULL_KEY);
            onball = TRUE;
            ball = (key)llDeleteSubString(m, 0, llStringLength("onball"));
            llSetTimerEvent(5.0);
        }
        else if(startswith(llToLower(m), "tpto"))
        {
            if(onball == TRUE && llList2Key(llGetObjectDetails(llGetOwner(), [OBJECT_ROOT]), 0) == ball) return;
            llMessageLinked(LINK_SET, S_API_ENABLE, "", NULL_KEY);
            onball = FALSE;
            ball = NULL_KEY;
            llSetTimerEvent(0.0);
            m = llDeleteSubString(m, 0, llStringLength("tpto"));
            llOwnerSay("@tploc=y,unsit=y,tpto:" + m + "=force");
        }
        else if(llToLower(m) == "lock")
        {
            if(locked)
            {
                ownersay(k, "The " + VERSION_S + " worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about is unlocked.");
                locked = FALSE;
                llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES);
                llSetScale(<0.01, 0.01, 0.01>);
                llOwnerSay("@detach=y");
            }
            else
            {
                ownersay(k, "The " + VERSION_S + " worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about is locked.");
                locked = TRUE;
                llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES);
                llSetScale(<0.4, 0.4, 0.4>);
                llOwnerSay("@detach=n");
            }
        }
        else if(llToLower(m) == "stand" || llToLower(m) == "unsit")
        {
            llOwnerSay("@unsit=force");
        }
        else if(startswith(m, "@"))
        {
            m = strreplace(m, "RLV_CHANNEL", (string)RLV_CHANNEL);
            path = "~";
            ownersay(k, "Executing RLV command '" + m + "' on " + name + ".");
            llOwnerSay(m);
        }
    }

    timer()
    {
        key obj = llList2Key(llGetObjectDetails(llGetOwner(), [OBJECT_ROOT]), 0);
        if(obj != ball)
        {
            llMessageLinked(LINK_SET, S_API_ENABLE, "", NULL_KEY);
            onball = FALSE;
            ball = NULL_KEY;
            llSetTimerEvent(0.0);
        }
    }
}