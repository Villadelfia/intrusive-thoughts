#include <IT/globals.lsl>
key requester;
key primary = NULL_KEY;
list owners = [];
integer publicaccess = FALSE;
integer groupaccess = FALSE;

integer noim = FALSE;
integer onball = FALSE;
key ball;
string name = "";
string prefix = "xx";
string path = "";
string playing = "";
integer daze = FALSE;
integer locked = FALSE;
integer outfitlocked = FALSE;
float currentVision = 4.0;
float currentFocus = 2.0;

string outfitPrefix = "~outfit";
string stuffPrefix = "~stuff";
string formPrefix = "~form";

list lockedList = [];
list wearState = ["⮽", "⬜", "⬔", "⬛"];

clearLockList()
{
    integer i = llGetListLength(lockedList);
    while(~--i)
    {
        string entry = llList2String(lockedList, i);
        llOwnerSay("@detachallthis:" + entry + "=y,attachallthis:" + entry + "=y");
    }
    lockedList = [];
}

applyLockList()
{
    integer i = llGetListLength(lockedList);
    while(~--i)
    {
        string entry = llList2String(lockedList, i);
        llOwnerSay("@detachallthis:" + entry + "=n,attachallthis:" + entry + "=n");
    }
}

toggleLockEntry(string what, key who)
{
    integer pos = llListFindList(lockedList, [what]);
    if(pos == -1)
    {
        lockedList += [what];
        llOwnerSay("@detachallthis:" + what + "=n,attachallthis:" + what + "=n");
        llSetObjectName("");
        ownersay(who, "The folder \"#RLV/" + what + "\" is now locked in its current state.", 0);
        llSetObjectName(slave_base);
    }
    else
    {
        lockedList = llDeleteSubList(lockedList, pos, pos);
        llOwnerSay("@detachallthis:" + what + "=y,attachallthis:" + what + "=y");
        llSetObjectName("");
        ownersay(who, "The folder \"#RLV/" + what + "\" is no longer locked in its current state.", 0);
        llSetObjectName(slave_base);
    }
}

hardReset()
{
    name = llGetDisplayName(llGetOwner());
    noim = FALSE;
    daze = FALSE;
    outfitlocked = FALSE;
    currentVision = 4.0;
    currentFocus = 2.0;
    clearLockList();
    outfitPrefix = "~outfit";
    stuffPrefix = "~stuff";
    formPrefix = "~form";

    if(playing != "") llStopAnimation(playing);
    doSetup();
}

softReset()
{
    noim = FALSE;
    daze = FALSE;
    outfitlocked = FALSE;
    currentVision = 4.0;
    currentFocus = 2.0;
    clearLockList();

    if(playing != "") llStopAnimation(playing);
    doSetup();
}

doSetup()
{
#ifndef PUBLIC_SLAVE
    llOwnerSay("@accepttp:" + (string)primary + "=add,accepttprequest:" + (string)primary + "=add,acceptpermission=add");
    integer i = llGetListLength(owners);
    while(~--i)
    {
        key who = (string)llList2Key(owners, i);
        llOwnerSay("@accepttp:" + (string)who + "=add,accepttprequest:" + (string)who + "=add");
    }
#else
    llOwnerSay("@accepttp=add,accepttprequest=add,acceptpermission=add");
#endif

    if(daze) llOwnerSay("@shownames_sec=n,showhovertextworld=n,showworldmap=n,showminimap=n,showloc=n,fartouch=n,camunlock=n,alwaysrun=n,temprun=n");
    else     llOwnerSay("@shownames_sec=y,showhovertextworld=y,showworldmap=y,showminimap=y,showloc=y,fartouch=y,camunlock=y,alwaysrun=y,temprun=y");
    playing = "";
    if(noim)
    {
        llMessageLinked(LINK_SET, S_API_SAY, "/me can not IM with people within 20 meters of them.", (key)name);
#ifndef PUBLIC_SLAVE
        llOwnerSay("@recvim:20=n,sendim:20=n,sendim:" + (string)primary + "=add,recvim:" + (string)primary + "=add");
#else
        llOwnerSay("@recvim:20=n,sendim:20=n");
#endif
    }
    else
    {
#ifndef PUBLIC_SLAVE
        llOwnerSay("@recvim:20=y,sendim:20=y,sendim:" + (string)primary + "=rem,recvim:" + (string)primary + "=rem");
#else
        llOwnerSay("@recvim:20=y,sendim:20=y");
#endif
    }

    if(outfitlocked)
    {
        llOwnerSay("@addattach=n,remattach=n,addoutfit=n,remoutfit=n");
    }
    else
    {
        llOwnerSay("@addattach=y,remattach=y,addoutfit=y,remoutfit=y");
    }

    if(locked)
    {
        llOwnerSay("@detach=n");
        if(llGetInventoryType("NO_HIDE") == INVENTORY_NONE) llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES);
    }

    applyLockList();
}

handlemenu(key k)
{
    if(isowner(k) == FALSE && llGetOwnerKey(k) != llGetOwner()) return;
    llSetObjectName("");

    // Greeting
    ownersay(k, "List of available commands for " + name + ":", 0);
    ownersay(k, " ", 0);

    // Animations
    integer numinv = llGetInventoryNumber(INVENTORY_ANIMATION);
    integer i;
    for(i = 0; i < numinv; ++i)
    {
        ownersay(k, "[secondlife:///app/chat/1/" + prefix + llEscapeURL(llGetInventoryName(INVENTORY_ANIMATION, i)) + " - Play " + llGetInventoryName(INVENTORY_ANIMATION, i) + " animation.]", 0);
    }

    // Stop animation
    ownersay(k, "[secondlife:///app/chat/1/" + prefix + "stop - Stop all animations.]", 0);
    ownersay(k, " ", 0);

    // Emergency release.
    ownersay(k, "[secondlife:///app/chat/1/" + prefix + "emergency - Remove all restrictions in case of emergency.]", 0);

    // Owner commands.
#ifndef PUBLIC_SLAVE
    if(isowner(k))
    {
#endif
        ownersay(k, " ", 0);
        ownersay(k, "[secondlife:///app/chat/1/" + prefix + "noim - Toggle local IMs.]", 0);
        ownersay(k, "[secondlife:///app/chat/1/" + prefix + "strip - Strip all clothes.]", 0);
        ownersay(k, "[secondlife:///app/chat/1/" + prefix + "listform - List all forms.]", 0);
        ownersay(k, "[secondlife:///app/chat/1/" + prefix + "listoutfit - List all outfits.]", 0);
        ownersay(k, "[secondlife:///app/chat/1/" + prefix + "liststuff - List all stuff.]", 0);
        ownersay(k, "[secondlife:///app/chat/1/" + prefix + "stand - Stand up.]", 0);
        ownersay(k, "[secondlife:///app/chat/1/" + prefix + "leash - Leash]/[secondlife:///app/chat/1/" + prefix + "unleash unleash.]", 0);
        if(llGetOwnerKey(k) == primary)
        {
            ownersay(k, "[secondlife:///app/chat/1/" + prefix + "ownerinfo - Add/remove secondary owners.]", 0);
            ownersay(k, "- Notification toggles: [secondlife:///app/chat/1/" + prefix + "tpnotify On teleport]/[secondlife:///app/chat/1/" + prefix + "lognotify On wear/detach].", 0);
        }
        ownersay(k, " ", 0);
        ownersay(k, "- Toggle [secondlife:///app/chat/1/" + prefix + "deaf deafness]/[secondlife:///app/chat/1/" + prefix + "blind blindness]/[secondlife:///app/chat/1/" + prefix + "mute muting].", 0);
        ownersay(k, "- Toggle [secondlife:///app/chat/1/" + prefix + "mind mindlessness]/[secondlife:///app/chat/1/" + prefix + "daze dazing]/[secondlife:///app/chat/1/" + prefix + "focus focussing].", 0);
        ownersay(k, "- Toggle [secondlife:///app/chat/1/" + prefix + "lock IT lock]/[secondlife:///app/chat/1/" + prefix + "lockoutfit outfit lock].", 0);
        ownersay(k, "- Sight radius: [secondlife:///app/chat/1/" + prefix + "b--- ---] [secondlife:///app/chat/1/" + prefix + "b-- --] [secondlife:///app/chat/1/" + prefix + "b- -] " + formatfloat(currentVision, 2) + " meters [secondlife:///app/chat/1/" + prefix + "b+ +] [secondlife:///app/chat/1/" + prefix + "b++ ++] [secondlife:///app/chat/1/" + prefix + "b+++ +++]", 0);
        ownersay(k, "- Focus distance: [secondlife:///app/chat/1/" + prefix + "f--- ---] [secondlife:///app/chat/1/" + prefix + "f-- --] [secondlife:///app/chat/1/" + prefix + "f- -] " + formatfloat(currentFocus, 2) + " meters [secondlife:///app/chat/1/" + prefix + "f+ +] [secondlife:///app/chat/1/" + prefix + "f++ ++] [secondlife:///app/chat/1/" + prefix + "f+++ +++]", 0);
        ownersay(k, " ", 0);
        ownersay(k, "- [secondlife:///app/chat/1/" + prefix + "afkcheck /1" + prefix + "afkcheck]: Have the slave do an AFK check.", 0);
        ownersay(k, "- /1" + prefix + "say <message>: Say a message.", 0);
        ownersay(k, "- /1" + prefix + "think <message>: Think a message.", 0);
        ownersay(k, "- /1" + prefix + "leashlength <meters>: Set the leash length.", 0);
        ownersay(k, "- /1" + prefix + "blindset <distance>: Directly set distance of sight radius in meters.", 0);
        ownersay(k, "- /1" + prefix + "focusset <distance>: Directly set focus distance in meters.", 0);
#ifndef PUBLIC_SLAVE
    }
#endif

    llSetObjectName(slave_base);
}

default
{
    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == S_API_RLV_CHECK)
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
            llOwnerSay("@accepttp:" + (string)primary + "=add,accepttprequest:" + (string)primary + "=add");
            integer i = llGetListLength(owners);
            while(~--i)
            {
                key who = (string)llList2Key(owners, i);
                llOwnerSay("@accepttp:" + (string)who + "=add,accepttprequest:" + (string)who + "=add");
            }
        }
        else if(num == S_API_OTHER_ACCESS)
        {
            publicaccess = (integer)str;
            groupaccess = (integer)((string)id);
        }
        else if(num == S_API_MANTRA_DONE)
        {
            doSetup();
        }
        else if(num == S_API_SET_LOCK)
        {
            locked = (integer)str;
            llSetObjectName("");
            if(locked)
            {
                ownersay(id, "The " + VERSION_S + " worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about is locked.", 0);
                if(llGetInventoryType("NO_HIDE") == INVENTORY_NONE) llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES);
                if(llGetInventoryType("NO_RESIZE") == INVENTORY_NONE) llSetScale(<0.4, 0.4, 0.4>);
                llOwnerSay("@detach=n");
            }
            else
            {
                ownersay(id, "The " + VERSION_S + " worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about is unlocked.", 0);
                if(llGetInventoryType("NO_HIDE") == INVENTORY_NONE) llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES);
                if(llGetInventoryType("NO_RESIZE") == INVENTORY_NONE) llSetScale(<0.01, 0.01, 0.01>);
                llOwnerSay("@detach=y");
            }
            llSetObjectName(slave_base);
        }
        else if(num == S_API_SCHEDULE_DETACH)
        {
            llOwnerSay("@clear,detachme=force");
        }
    }

    attach(key id)
    {
        if(id == NULL_KEY) onball = FALSE;
    }

    run_time_permissions(integer perm)
    {
        if(perm & PERMISSION_TAKE_CONTROLS) llTakeControls(CONTROL_FWD, TRUE, TRUE);
    }

    touch_start(integer num)
    {
        handlemenu(llDetectedKey(0));
    }

    state_entry()
    {
        if(llGetInventoryType("NO_HIDE") == INVENTORY_NONE) llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES);
        prefix = llGetSubString(llGetUsername(llGetOwner()), 0, 1);
        name = llGetDisplayName(llGetOwner());
        if(llLinksetDataReadProtected("locked", "") != "") locked = (integer)llLinksetDataReadProtected("locked", "");
        if(locked) llMessageLinked(LINK_SET, S_API_SET_LOCK, (string)TRUE, NULL_KEY);
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
        llListen(RLV_CHANNEL, "", llGetOwner(), "");
        llListen(COMMAND_CHANNEL, "", NULL_KEY, "");
        llRequestPermissions(llGetOwner(), PERMISSION_TAKE_CONTROLS | PERMISSION_TRIGGER_ANIMATION);
    }

    listen(integer c, string n, key k, string m)
    {
        if(c == COMMAND_CHANNEL && startswith(llToLower(m), "*onball") && llList2Key(llGetObjectDetails(k, [OBJECT_CREATOR]), 0) == (key)IT_CREATOR)
        {
            llMessageLinked(LINK_SET, S_API_DISABLE, "", NULL_KEY);
            onball = TRUE;
            ball = (key)llDeleteSubString(m, 0, llStringLength("*onball"));
            llSetTimerEvent(5.0);
            return;
        }

        if(c == RLV_CHANNEL)
        {
            if(path != "~")
            {
                list stuff = llParseString2List(m, [","], []);
                stuff = llListSort(stuff, 1, TRUE);
                string message;
                list item;
                string thing;
                string worn;
                integer l;
                integer i;
                llSetObjectName("");
                if(path == formPrefix)
                {
                    ownersay(requester, "Available forms for " + name + ":", 0);
                    ownersay(requester, " ", 0);
                    l = llGetListLength(stuff);
                    for(i = 0; i < l; ++i)
                    {
                        item = llParseStringKeepNulls(llList2String(stuff, i), ["|"], []);
                        thing = llList2String(item, 0);
                        worn = llList2String(item, 1);
                        if(thing != "")
                        {
                            message  = llList2String(wearState, (integer)llGetSubString(worn, 0, 0)) + llList2String(wearState, (integer)llGetSubString(worn, 1, 1)) + " ";
                            message += "[secondlife:///app/chat/1/" + prefix + llEscapeURL("form " + thing) + " " + thing + "]";
                            if(llListFindList(lockedList, [path + "/" + thing]) == -1) message += " [secondlife:///app/chat/1/" + prefix + llEscapeURL("toggleitemlock " + path + "/" + thing) + " (lock)]";
                            else                                                       message += " [secondlife:///app/chat/1/" + prefix + llEscapeURL("toggleitemlock " + path + "/" + thing) + " (unlock)]";
                            ownersay(requester, message, 0);
                        }
                    }
                    ownersay(requester, " ", 0);
                    ownersay(requester, "[secondlife:///app/chat/1/" + prefix + "! Back to command list...]", 0);
                }
                else if(path == outfitPrefix)
                {
                    ownersay(requester, "Available outfits for " + name + ":", 0);
                    ownersay(requester, " ", 0);
                    l = llGetListLength(stuff);
                    for(i = 0; i < l; ++i)
                    {
                        item = llParseStringKeepNulls(llList2String(stuff, i), ["|"], []);
                        thing = llList2String(item, 0);
                        worn = llList2String(item, 1);
                        if(thing != "")
                        {
                            message  = llList2String(wearState, (integer)llGetSubString(worn, 0, 0)) + llList2String(wearState, (integer)llGetSubString(worn, 1, 1)) + " ";
                            message += "[secondlife:///app/chat/1/" + prefix + llEscapeURL("outfit " + thing) + " " + thing + "] ";
                            message += "[secondlife:///app/chat/1/" + prefix + llEscapeURL("outfitstrip " + thing) + " (strip first)]";
                            if(llListFindList(lockedList, [path + "/" + thing]) == -1) message += " [secondlife:///app/chat/1/" + prefix + llEscapeURL("toggleitemlock " + path + "/" + thing) + " (lock)]";
                            else                                                       message += " [secondlife:///app/chat/1/" + prefix + llEscapeURL("toggleitemlock " + path + "/" + thing) + " (unlock)]";
                            ownersay(requester, message, 0);
                        }
                    }
                    ownersay(requester, " ", 0);
                    ownersay(requester, "[secondlife:///app/chat/1/" + prefix + "! Back to command list...]", 0);
                }
                else if(path == stuffPrefix)
                {
                    ownersay(requester, "Available stuff for " + name + ":", 0);
                    ownersay(requester, " ", 0);
                    l = llGetListLength(stuff);
                    for(i = 0; i < l; ++i)
                    {
                        item = llParseStringKeepNulls(llList2String(stuff, i), ["|"], []);
                        thing = llList2String(item, 0);
                        worn = llList2String(item, 1);
                        if(thing != "")
                        {
                            message  = llList2String(wearState, (integer)llGetSubString(worn, 0, 0)) + llList2String(wearState, (integer)llGetSubString(worn, 1, 1)) + " ";
                            message += thing + " ";
                            message += "[secondlife:///app/chat/1/" + prefix + llEscapeURL("add " + thing) + " (+) ]";
                            message += "[secondlife:///app/chat/1/" + prefix + llEscapeURL("remove " + thing) + " (-)]";
                            if(llListFindList(lockedList, [path + "/" + thing]) == -1) message += " [secondlife:///app/chat/1/" + prefix + llEscapeURL("toggleitemlock " + path + "/" + thing) + " (lock)]";
                            else                                                       message += " [secondlife:///app/chat/1/" + prefix + llEscapeURL("toggleitemlock " + path + "/" + thing) + " (unlock)]";
                            ownersay(requester, message, 0);
                        }
                    }
                    ownersay(requester, " ", 0);
                    ownersay(requester, "[secondlife:///app/chat/1/" + prefix + "! Back to command list...]", 0);
                }
                else
                {
                    if(path != "") path += "/";
                    ownersay(requester, "RLV folders in #RLV/" + path + " for " + name + ":", 0);
                    ownersay(requester, " ", 0);
                    l = llGetListLength(stuff);
                    for(i = 0; i < l; ++i)
                    {
                        item = llParseStringKeepNulls(llList2String(stuff, i), ["|"], []);
                        thing = llList2String(item, 0);
                        worn = llList2String(item, 1);
                        if(thing != "")
                        {
                            message  = llList2String(wearState, (integer)llGetSubString(worn, 0, 0)) + llList2String(wearState, (integer)llGetSubString(worn, 1, 1)) + " ";
                            message += "[secondlife:///app/chat/1/" + prefix + llEscapeURL("list " + path + thing) + " " + thing + "] ";
                            message += "[secondlife:///app/chat/1/" + prefix + llEscapeURL("+ " + path + thing) + " (+)] ";
                            message += "[secondlife:///app/chat/1/" + prefix + llEscapeURL("- " + path + thing) + " (-)]";
                            if(llListFindList(lockedList, [path + thing]) == -1) message += " [secondlife:///app/chat/1/" + prefix + llEscapeURL("toggleitemlock " + path + thing) + " (lock)]";
                            else                                                 message += " [secondlife:///app/chat/1/" + prefix + llEscapeURL("toggleitemlock " + path + thing) + " (unlock)]";
                            ownersay(requester, message, 0);
                        }
                    }
                    ownersay(requester, " ", 0);
                }
                llSetObjectName(slave_base);
            }
            else
            {
                llSetObjectName("");
                ownersay(requester, "RLV command response for " + name + ":\n" + m, 0);
                llSetObjectName(slave_base);
            }
            llRegionSay(RLV_CHANNEL, m);
            return;
        }

#ifndef PUBLIC_SLAVE
        // We only accept commands from the owner or the wearer.
        if(llGetOwnerKey(k) != llGetOwner() && isowner(k) == FALSE) return;
#endif

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
            else if(llToLower(m) == "emergency")
            {
                llSetObjectName("");
#ifndef PUBLIC_SLAVE
                ownersay(k, "Removing all RLV restrictions, nullifying your filters until next relog, and notifying your primary owner...", 0);
                if(llGetAgentSize(primary) != ZERO_VECTOR) ownersay(primary, "The " + VERSION_S + " has been emergency reset by secondlife:///app/agent/" + (string)llGetOwner() + "/about at " + slurl() + ".", 0);
                else llInstantMessage(primary, "The " + VERSION_S + " has been emergency reset by secondlife:///app/agent/" + (string)llGetOwner() + "/about at " + slurl() + ".");
#else
                ownersay(k, "Removing all RLV restrictions, nullifying your filters until next relog...", 0);
#endif
                llSetObjectName(slave_base);
                softReset();
                llMessageLinked(LINK_SET, S_API_EMERGENCY, name, "");
            }
            else if(llToLower(m) == "!" || m == "" || llToLower(m) == "menu")
            {
                handlemenu(k);
            }
        }

        // Starting here, only the Domme may give commands.
#ifndef PUBLIC_SLAVE
        if(!isowner(k)) return;
#endif
        requester = k;

        if(c == MANTRA_CHANNEL)
        {
            if(m == "RESET")
            {
                hardReset();
            }
            else if(startswith(m, "NAME"))
            {
                m = llDeleteSubString(m, 0, llStringLength("NAME"));
                name = m;
            }
            else if(startswith(m, "PREFIX_STUFF"))
            {
                stuffPrefix = llDeleteSubString(m, 0, llStringLength("PREFIX_STUFF"));
            }
            else if(startswith(m, "PREFIX_OUTFIT"))
            {
                outfitPrefix = llDeleteSubString(m, 0, llStringLength("PREFIX_OUTFIT"));
            }
            else if(startswith(m, "PREFIX_FORM"))
            {
                formPrefix = llDeleteSubString(m, 0, llStringLength("PREFIX_FORM"));
            }
            else if(m == "END")
            {
                llSetObjectName("");
                ownersay(k, "[restrict]: " + (string)(llGetFreeMemory() / 1024.0) + "kb free.", HUD_SPEAK_CHANNEL);
            }
        }

        if(llToLower(m) == "noim")
        {
            if(noim)
            {
                llMessageLinked(LINK_SET, S_API_SAY, "/me can IM with people within 20 meters of them again.", (key)name);
#ifndef PUBLIC_SLAVE
                llOwnerSay("@recvim:20=y,sendim:20=y,sendim:" + (string)primary + "=rem,recvim:" + (string)primary + "=rem");
#else
                llOwnerSay("@recvim:20=y,sendim:20=y");
#endif
                noim = FALSE;
            }
            else
            {
                llMessageLinked(LINK_SET, S_API_SAY, "/me can no longer IM with people within 20 meters of them.", (key)name);
#ifndef PUBLIC_SLAVE
                llOwnerSay("@recvim:20=n,sendim:20=n,sendim:" + (string)primary + "=add,recvim:" + (string)primary + "=add");
#else
                llOwnerSay("@recvim:20=n,sendim:20=n");
#endif
                noim = TRUE;
            }
        }
        else if(llToLower(m) == "strip")
        {
            llSetObjectName("");
            ownersay(k, "Stripping " + name + " of all clothes.", 0);
            llSetObjectName(slave_base);
            llOwnerSay("@detach=force,remoutfit=force");
        }
        else if(llToLower(m) == "afkcheck")
        {
            llMessageLinked(LINK_SET, S_API_AFK_CHECK, "", k);
        }
        else if(llToLower(m) == "list")
        {
            path = "";
            llOwnerSay("@getinvworn=" + (string)RLV_CHANNEL);
        }
        else if(llToLower(m) == "listoutfit")
        {
            path = outfitPrefix;
            llOwnerSay("@getinvworn:" + outfitPrefix + "=" + (string)RLV_CHANNEL);
        }
        else if(llToLower(m) == "liststuff")
        {
            path = stuffPrefix;
            llOwnerSay("@getinvworn:" + stuffPrefix + "=" + (string)RLV_CHANNEL);
        }
        else if(llToLower(m) == "listform")
        {
            path = formPrefix;
            llOwnerSay("@getinvworn:" + formPrefix + "=" + (string)RLV_CHANNEL);
        }
        else if(startswith(llToLower(m), "list"))
        {
            path = llDeleteSubString(m, 0, llStringLength("list"));
            llOwnerSay("@getinvworn:" + path + "=" + (string)RLV_CHANNEL);
        }
        else if(startswith(m, "toggleitemlock"))
        {
            m = llDeleteSubString(m, 0, llStringLength("toggleitemlock"));
            toggleLockEntry(m, k);
        }
        else if(startswith(llToLower(m), "outfitstrip"))
        {
            path = llDeleteSubString(m, 0, llStringLength("outfitstrip"));
            llSetObjectName("");
            ownersay(k, "Stripping " + name + " of everything, then wearing outfit '" + path + "'.", 0);
            llSetObjectName(slave_base);
            llOwnerSay("@detach=force,remoutfit=force,attachover:" + outfitPrefix + "/" + path + "=force");
        }
        else if(startswith(llToLower(m), "outfit"))
        {
            path = llDeleteSubString(m, 0, llStringLength("outfit"));
            llSetObjectName("");
            ownersay(k, "Stripping " + name + " of her outfits, then wearing outfit '" + path + "'.", 0);
            llSetObjectName(slave_base);
            llOwnerSay("@detachall:" + outfitPrefix + "=force,attachover:" + outfitPrefix + "/" + path + "=force");
        }
        else if(startswith(llToLower(m), "form"))
        {
            path = llDeleteSubString(m, 0, llStringLength("form"));
            llSetObjectName("");
            ownersay(k, "Stripping " + name + " of all clothes, then wearing form '" + path + "'.", 0);
            llSetObjectName(slave_base);
            llOwnerSay("@detach=force,remoutfit=force,attachover:" + formPrefix + "/" + path + "=force");
        }
        else if(startswith(llToLower(m), "add"))
        {
            path = llDeleteSubString(m, 0, llStringLength("add"));
            llSetObjectName("");
            ownersay(k, "Wearing '" + stuffPrefix + "/" + path + "' on " + name + ".", 0);
            llSetObjectName(slave_base);
            llOwnerSay("@attachover:" + stuffPrefix + "/" + path + "=force");
        }
        else if(startswith(llToLower(m), "remove"))
        {
            path = llDeleteSubString(m, 0, llStringLength("remove"));
            llSetObjectName("");
            ownersay(k, "Removing '" + stuffPrefix + "/" + path + "' from " + name + ".", 0);
            llSetObjectName(slave_base);
            llOwnerSay("@detachall:" + stuffPrefix + "/" + path + "=force");
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
        else if(llToLower(m) == "b-")
        {
            currentVision -= 0.05;
            if(currentVision < 0) currentVision = 0.0;
            llMessageLinked(LINK_SET, S_API_BLIND_LEVEL, (string)currentVision, k);
        }
        else if(llToLower(m) == "b--")
        {
            currentVision -= 0.25;
            if(currentVision < 0) currentVision = 0.0;
            llMessageLinked(LINK_SET, S_API_BLIND_LEVEL, (string)currentVision, k);
        }
        else if(llToLower(m) == "b---")
        {
            currentVision -= 1.0;
            if(currentVision < 0) currentVision = 0.0;
            llMessageLinked(LINK_SET, S_API_BLIND_LEVEL, (string)currentVision, k);
        }
        else if(llToLower(m) == "b+")
        {
            currentVision += 0.05;
            llMessageLinked(LINK_SET, S_API_BLIND_LEVEL, (string)currentVision, k);
        }
        else if(llToLower(m) == "b++")
        {
            currentVision += 0.25;
            llMessageLinked(LINK_SET, S_API_BLIND_LEVEL, (string)currentVision, k);
        }
        else if(llToLower(m) == "b+++")
        {
            currentVision += 1.0;
            llMessageLinked(LINK_SET, S_API_BLIND_LEVEL, (string)currentVision, k);
        }
        else if(startswith(m, "blindset"))
        {
            currentVision = (float)llDeleteSubString(m, 0, llStringLength("blindset"));
            if(currentVision < 0) currentVision = 0.0;
            llMessageLinked(LINK_SET, S_API_BLIND_LEVEL, (string)currentVision, k);
        }
        else if(llToLower(m) == "mute")
        {
            llMessageLinked(LINK_SET, S_API_MUTE_TOGGLE, "", k);
        }
        else if(llToLower(m) == "mind")
        {
            llMessageLinked(LINK_SET, S_API_MIND_TOGGLE, "", k);
        }
        else if(llToLower(m) == "daze")
        {
            llSetObjectName("");
            if(daze)
            {
                daze = FALSE;
                ownersay(k, name + " is no longer dazed.", 0);
                llOwnerSay("@shownames_sec=y,showhovertextworld=y,showworldmap=y,showminimap=y,showloc=y,fartouch=y,camunlock=y,alwaysrun=y,temprun=y");
            }
            else
            {
                daze = TRUE;
                ownersay(k, name + " is now dazed.", 0);
                llOwnerSay("@shownames_sec=n,showhovertextworld=n,showworldmap=n,showminimap=n,showloc=n,fartouch=n,camunlock=n,alwaysrun=n,temprun=n");
            }
            llSetObjectName(slave_base);
        }
        else if(llToLower(m) == "lockoutfit")
        {
            llSetObjectName("");
            if(outfitlocked)
            {
                outfitlocked = FALSE;
                ownersay(k, name + " is no longer prevented from changing their outfit.", 0);
                llOwnerSay("@addattach=y,remattach=y,addoutfit=y,remoutfit=y");
            }
            else
            {
                outfitlocked = TRUE;
                ownersay(k, name + " can no longer change their outfit.", 0);
                llOwnerSay("@addattach=n,remattach=n,addoutfit=n,remoutfit=n");
            }
            llSetObjectName(slave_base);
        }
        else if(llToLower(m) == "focus")
        {
            llMessageLinked(LINK_SET, S_API_FOCUS_TOGGLE, "", k);
        }
        else if(llToLower(m) == "f-")
        {
            currentFocus -= 0.05;
            if(currentFocus < 0) currentFocus = 0.0;
            llMessageLinked(LINK_SET, S_API_FOCUS_LEVEL, (string)currentFocus, k);
        }
        else if(llToLower(m) == "f--")
        {
            currentFocus -= 0.25;
            if(currentFocus < 0) currentFocus = 0.0;
            llMessageLinked(LINK_SET, S_API_FOCUS_LEVEL, (string)currentFocus, k);
        }
        else if(llToLower(m) == "f---")
        {
            currentFocus -= 1.0;
            if(currentFocus < 0) currentFocus = 0.0;
            llMessageLinked(LINK_SET, S_API_FOCUS_LEVEL, (string)currentFocus, k);
        }
        else if(llToLower(m) == "f+")
        {
            currentFocus += 0.05;
            llMessageLinked(LINK_SET, S_API_FOCUS_LEVEL, (string)currentFocus, k);
        }
        else if(llToLower(m) == "f++")
        {
            currentFocus += 0.25;
            llMessageLinked(LINK_SET, S_API_FOCUS_LEVEL, (string)currentFocus, k);
        }
        else if(llToLower(m) == "f+++")
        {
            currentFocus += 1.0;
            llMessageLinked(LINK_SET, S_API_FOCUS_LEVEL, (string)currentFocus, k);
        }
        else if(startswith(m, "focusset"))
        {
            currentFocus = (float)llDeleteSubString(m, 0, llStringLength("focusset"));
            if(currentFocus < 0) currentFocus = 0.0;
            llMessageLinked(LINK_SET, S_API_FOCUS_LEVEL, (string)currentFocus, k);
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
                llMessageLinked(LINK_SET, S_API_SET_LOCK, (string)FALSE, k);
                llLinksetDataWriteProtected("locked", (string)FALSE, "");
            }
            else
            {
                llMessageLinked(LINK_SET, S_API_SET_LOCK, (string)TRUE, k);
                llLinksetDataWriteProtected("locked", (string)TRUE, "");
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
            llSetObjectName("");
            ownersay(k, "Executing RLV command '" + m + "' on " + name + ".", 0);
            llSetObjectName(slave_base);
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
