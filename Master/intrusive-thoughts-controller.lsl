#include <IT/globals.lsl>

integer retry = FALSE;
integer ready = FALSE;
key target;
list targets = [];
key getline;
key getlines;
integer line;
integer lines;
string name;
string todel;
string prefix;
integer storedCt = 0;
integer sending = 0;
integer menu = 0;
integer ncpage = 0;
key lockedavatar = NULL_KEY;
string lockedname = "";

integer continued = FALSE;
string setting;
string value;

list page = [
    "B.MUTE OFF", "BIMBO OFF",  "TIMER SET",
    "B.MUTE ON",  "BIMBO SET",  "NAME",
    "RESET",      "BIMBO ODDS", "CUSTOM",
    "AFKCHECK",   " ",          "BACK"
];

sendNext()
{
    if(sending <= storedCt)
    {
        list kv = llParseString2List(llLinksetDataReadProtected("it-" + (string)sending, ""), ["="], []);
        llMessageLinked(LINK_SET, M_API_CONFIG_DATA, llList2String(kv, 0), (key)llDumpList2String(llDeleteSubList(kv, 0, 0), "="));
        if(sending == storedCt)
        {
            llMessageLinked(LINK_SET, M_API_CONFIG_DONE, "", NULL_KEY);
            llMessageLinked(LINK_SET, M_API_STATUS_DONE, "", (string)"");
            ready = TRUE;
        }
        sending++;
    }
}

settext()
{
    if(line >= lines)
    {
        debug("[settext] Triggering M_API_STATUS_DONE");
        llRegionSayTo(target, MANTRA_CHANNEL, "END");
        llMessageLinked(LINK_SET, M_API_STATUS_DONE, "", (string)"");
    }
    else
    {
        debug("[settext] Updating M_API_STATUS_MESSAGE");
        llMessageLinked(LINK_SET, M_API_STATUS_MESSAGE, "Reading " + name + ":", (string)((string)line + "/" + (string)lines));
    }
}

giveMenu()
{
    string prompt = "Controlling secondlife:///app/agent/" + (string)target + "/about. Choose a notecard to send, or select another option.\n";
    integer i;
    integer l = llGetInventoryNumber(INVENTORY_NOTECARD);
    // If we have 9 or fewer notecards, we do not paginate:
    if(l <= 9)
    {
        list buttons = [];
        for(i = 0; i < l; ++i)
        {
            buttons += [(string)i];
            prompt += "\n" + (string)i + ": " + llGetInventoryName(INVENTORY_NOTECARD, i);
        }
        while(llGetListLength(buttons) < 9) buttons += [" "];
        buttons += ["MENU", "DELETE", "CANCEL"];
        menu = 0;
        debug("[giveMenu] Offering menu 0 unpaginated");
        llDialog(llGetOwner(), prompt, orderbuttons(buttons), S_DIALOG_CHANNEL);
    }
    // Otherwise we show them 6 at a time.
    else
    {
        list buttons = [];
        for(i = 6 * ncpage; i < l && i < (6 * (ncpage+1)); ++i)
        {
            buttons += [(string)i];
            prompt += "\n" + (string)i + ": " + llGetInventoryName(INVENTORY_NOTECARD, i);
        }
        while(llGetListLength(buttons) < 6) buttons += [" "];
        if(ncpage > 0) buttons += ["←"];
        else           buttons += [" "];
        buttons += [" "];
        if((6 * (ncpage+1)) >= l) buttons += [" "];
        else                      buttons += ["→"];
        buttons += ["MENU", "DELETE", "CANCEL"];
        menu = 0;
        debug("[giveMenu] Offering menu 0, page: " + (string)ncpage);
        llDialog(llGetOwner(), prompt, orderbuttons(buttons), S_DIALOG_CHANNEL);
    }
}

giveDelete()
{
    string prompt = "Choose a notecard to delete, or click back to return.\n";
    integer i;
    integer l = llGetInventoryNumber(INVENTORY_NOTECARD);
    // If we have 9 or fewer notecards, we do not paginate:
    if(l <= 9)
    {
        list buttons = [];
        for(i = 0; i < l; ++i)
        {
            buttons += [(string)i];
            prompt += "\n" + (string)i + ": " + llGetInventoryName(INVENTORY_NOTECARD, i);
        }
        while(llGetListLength(buttons) < 9) buttons += [" "];
        buttons += [" ", "BACK", "CANCEL"];
        menu = 5;
        debug("[giveDelete] Offering menu 5 unpaginated");
        llDialog(llGetOwner(), prompt, orderbuttons(buttons), S_DIALOG_CHANNEL);
    }
    // Otherwise we show them 6 at a time.
    else
    {
        list buttons = [];
        for(i = 6 * ncpage; i < l && i < (6 * (ncpage+1)); ++i)
        {
            buttons += [(string)i];
            prompt += "\n" + (string)i + ": " + llGetInventoryName(INVENTORY_NOTECARD, i);
        }
        while(llGetListLength(buttons) < 6) buttons += [" "];
        if(ncpage > 0) buttons += ["←"];
        else           buttons += [" "];
        buttons += [" "];
        if((6 * (ncpage+1)) >= l) buttons += [" "];
        else                      buttons += ["→"];
        buttons += [" ", "BACK", "CANCEL"];
        menu = 5;
        debug("[giveDelete] Offering menu 5, page: " + (string)ncpage);
        llDialog(llGetOwner(), prompt, orderbuttons(buttons), S_DIALOG_CHANNEL);
    }
}

giveTargets()
{
    string prompt = "Who will you control?\n";
    integer i;
    integer l = llGetListLength(targets);
    if(l > 12) l = 12;
    list buttons = [];
    for(i = 0; i < l; ++i)
    {
        buttons += [(string)i];
        prompt += "\n" + (string)i + ": " + llGetUsername(llList2Key(targets, i));
    }
    while(llGetListLength(buttons) < 12) buttons += [" "];
    menu = -1;
    debug("[giveTargets] Offering menu -1");
    llDialog(llGetOwner(), prompt, orderbuttons(buttons), S_DIALOG_CHANNEL);
}

default
{
    state_entry()
    {
        debug("[state_entry] Script start");
        llListen(S_DIALOG_CHANNEL, "", llGetOwner(), "");
        llListen(PING_CHANNEL, "", NULL_KEY, "");
        llListen(HUD_SPEAK_CHANNEL, "", NULL_KEY, "");
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == M_API_HUD_STARTED)
        {
            if(ready)
            {
                debug("[link_message] M_API_HUD_STARTED triggering M_API_CONFIG_DONE");
                llMessageLinked(LINK_SET, M_API_CONFIG_DONE, "", NULL_KEY);
            }
            else
            {
                if(llLinksetDataReadProtected("it-ct", "") != "")
                {
                    debug("[link_message] M_API_HUD_STARTED found stored configuration");
                    llMessageLinked(LINK_SET, M_API_BUTTON_PRESSED, "hide", "");
                    llMessageLinked(LINK_SET, M_API_STATUS_MESSAGE, "Loading config...", "");
                    storedCt = (integer)llLinksetDataReadProtected("it-ct", "");
                    sending = 0;
                    sendNext();
                    sendNext();
                    sendNext();
                    sendNext();
                    sendNext();
                    sensortimer(0.1);
                }
                else
                {
                    debug("[link_message] M_API_HUD_STARTED requesting configuration");
                    llSetObjectName("");
                    llOwnerSay(VERSION_M + ": Drop your 'Intrusive Thoughts Configuration' notecard onto the HUD to set it up.");
                    llSetObjectName(master_base);
                }
            }
        }
        else if(num == M_API_CONFIG_DONE)
        {
            debug("[link_message] M_API_CONFIG_DONE");
            llSetObjectName("");
            llOwnerSay(VERSION_M + ": Startup complete. Welcome to your Intrusive Thoughts system. Click and hold any button for more than a second to get basic usage information. For more documentation read the included Instruction Manual notecard.");
            if(llGetPermissions() & PERMISSION_TAKE_CONTROLS == 0) llRequestPermissions(llGetOwner(), PERMISSION_TAKE_CONTROLS);
            llSetObjectName(master_base);
            llMessageLinked(LINK_SET, M_API_CONFIG_DONE_2, "", NULL_KEY);

            // Set update pin.
            integer pin = ((integer)("0x"+llGetSubString((string)llGetOwner(),-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFFF;
            llSetRemoteScriptAccessPin(pin);
        }
        else if(num == M_API_LOCK)
        {
            debug("[link_message] M_API_LOCK, uuid: " + (string)id + ", name: " + str);
            lockedavatar = id;
            lockedname = str;
        }

        if(!ready) return;

        if(num == M_API_BUTTON_PRESSED)
        {
            debug("[link_message] M_API_BUTTON_PRESSED, button_name: " + str);
            if(str == "menu")
            {
                if(name != "")
                {
                    debug("[link_message] M_API_BUTTON_PRESSED menu busy reject");
                    llSetObjectName("");
                    llOwnerSay("Hold on. We're busy sending settings...");
                    llSetObjectName(master_base);
                    return;
                }

                if(lockedavatar)
                {
                    debug("[link_message] M_API_BUTTON_PRESSED menu trigger, for: " + lockedname + ", uuid: " + (string)lockedavatar);
                    llSetObjectName("");
                    llOwnerSay("Displaying the menu for the Intrusive Thoughts slave worn by '" + lockedname + "'.");
                    llSetObjectName(master_base);
                    llRegionSayTo(lockedavatar, MANTRA_CHANNEL, "PING");
                    llRegionSayTo(lockedavatar, COMMAND_CHANNEL, "*");
                }
                else
                {
                    debug("[link_message] M_API_BUTTON_PRESSED menu broadcast ping");
                    llSetObjectName("");
                    llOwnerSay("Pinging the region for Intrusive Thoughts slaves under your control...");
                    llSetObjectName(master_base);
                    targets = [];
                    retry = FALSE;
                    llRegionSay(MANTRA_CHANNEL, "PING");
                    llSetTimerEvent(1.0);
                }
            }
        }
    }

    no_sensor()
    {
        sensortimer(0.0);
        if(llGetInventoryType("Intrusive Thoughts Configuration") == INVENTORY_NOTECARD)
        {
            getline = llGetNotecardLine(name, line);
        }
        else
        {
            if(sending > storedCt) return;
            sendNext();
            sendNext();
            sendNext();
            sendNext();
            sendNext();
            sensortimer(0.1);
        }
    }

    run_time_permissions(integer perm)
    {
        debug("[run_time_permissions] Entry, perm: " + (string)perm);
        if(perm & PERMISSION_TAKE_CONTROLS) llTakeControls(CONTROL_FWD, TRUE, TRUE);
    }

    changed(integer change)
    {
        if(change & CHANGED_INVENTORY)
        {
            if(llGetInventoryType("Intrusive Thoughts Configuration") == INVENTORY_NOTECARD)
            {
                debug("[changed] Trigger reconfiguration due to NC");
                if(!ready) llMessageLinked(LINK_SET, M_API_BUTTON_PRESSED, "hide", "");
                llMessageLinked(LINK_SET, M_API_STATUS_MESSAGE, "Loading config...", "");
                ready = FALSE;
                continued = FALSE;
                name = "Intrusive Thoughts Configuration";
                line = 0;
                storedCt = 0;
                llLinksetDataReset();
                getline = llGetNotecardLine(name, line);
            }
        }
    }

    listen(integer c, string n, key k, string m)
    {
        if(c == HUD_SPEAK_CHANNEL)
        {
            llSetObjectName("");
            llOwnerSay(m);
            llSetObjectName(master_base);
        }
        else if(c == PING_CHANNEL)
        {
            debug("[listen] PING_CHANNEL from: " + (string)k);
            if(lockedavatar)
            {
                target = llGetOwnerKey(k);
                ncpage = 0;
                giveMenu();
            }
            else
            {
                targets += [llGetOwnerKey(k)];
            }
        }
        else if(menu == 0)
        {
            debug("[listen] S_DIALOG_CHANNEL, menu: 0, cmd: " + m);
            if(m == "CANCEL") return;
            else if(m == "BACK" || m == " ") giveMenu();
            else if(m == "MENU") llDialog(llGetOwner(), "Select a command...", orderbuttons(page), S_DIALOG_CHANNEL);
            else if(m == "DELETE") giveDelete();
            else if(m == "→")
            {
                debug("[listen] S_DIALOG_CHANNEL, menu: 0, increment page");
                ncpage++;
                giveMenu();
            }
            else if(m == "←")
            {
                debug("[listen] S_DIALOG_CHANNEL, menu: 0, decrement page");
                ncpage--;
                giveMenu();
            }
            else if(m == "B.MUTE OFF")
            {
                debug("[listen] S_DIALOG_CHANNEL, menu: 0, b.mute off for: " + (string)target);
                llRegionSayTo(target, MANTRA_CHANNEL, "BLIND_MUTE 0");
                llDialog(llGetOwner(), "Select a command...", orderbuttons(page), S_DIALOG_CHANNEL);
            }
            else if(m == "B.MUTE ON")
            {
                debug("[listen] S_DIALOG_CHANNEL, menu: 0, b.mute on for: " + (string)target);
                llRegionSayTo(target, MANTRA_CHANNEL, "BLIND_MUTE 1");
                llDialog(llGetOwner(), "Select a command...", orderbuttons(page), S_DIALOG_CHANNEL);
            }
            else if(m == "BIMBO OFF")
            {
                debug("[listen] S_DIALOG_CHANNEL, menu: 0, bimbo off for: " + (string)target);
                llRegionSayTo(target, MANTRA_CHANNEL, "AUDITORY_BIMBO_LIMIT 0");
                llDialog(llGetOwner(), "Select a command...", orderbuttons(page), S_DIALOG_CHANNEL);
            }
            else if(m == "BIMBO SET")
            {
                debug("[listen] S_DIALOG_CHANNEL, menu: 0, bimbo set for: " + (string)target + ", menu transition: 1");
                menu = 1;
                llTextBox(llGetOwner(), "Enter the maximum word length.", S_DIALOG_CHANNEL);
            }
            else if(m == "BIMBO ODDS")
            {
                debug("[listen] S_DIALOG_CHANNEL, menu: 0, bimbo odds for: " + (string)target + ", menu transition: 2");
                menu = 2;
                llTextBox(llGetOwner(), "Enter the letter drop chance.", S_DIALOG_CHANNEL);
            }
            else if(m == "RESET")
            {
                debug("[listen] S_DIALOG_CHANNEL, menu: 0, reset for: " + (string)target);
                llRegionSayTo(target, MANTRA_CHANNEL, "RESET");
                llDialog(llGetOwner(), "Select a command...", orderbuttons(page), S_DIALOG_CHANNEL);
            }
            else if(m == "TIMER SET")
            {
                debug("[listen] S_DIALOG_CHANNEL, menu: 0, timer set for: " + (string)target + ", menu transition: 3");
                menu = 3;
                llTextBox(llGetOwner(), "Enter the timer min and max.", S_DIALOG_CHANNEL);
            }
            else if(m == "NAME")
            {
                debug("[listen] S_DIALOG_CHANNEL, menu: 0, name for: " + (string)target + ", menu transition: 4");
                menu = 4;
                llTextBox(llGetOwner(), "Enter a new name.", S_DIALOG_CHANNEL);
            }
            else if(m == "CUSTOM")
            {
                debug("[listen] S_DIALOG_CHANNEL, menu: 0, custom for: " + (string)target + ", menu transition: 6");
                menu = 6;
                llTextBox(llGetOwner(), "Enter a custom command.", S_DIALOG_CHANNEL);
            }
            else if(m == "AFKCHECK")
            {
                debug("[listen] S_DIALOG_CHANNEL, menu: 0, afkcheck for: " + (string)target);
                llRegionSayTo(target, MANTRA_CHANNEL, "AFKCHECK");
                llDialog(llGetOwner(), "Select a command...", orderbuttons(page), S_DIALOG_CHANNEL);
            }
            else
            {
                llRegionSayTo(target, MANTRA_CHANNEL, "RESET");
                name = llGetInventoryName(INVENTORY_NOTECARD, (integer)m);
                debug("[listen] S_DIALOG_CHANNEL, menu: 0, programming notecard for: " + (string)target + ", nc: " + name);
                getlines = llGetNumberOfNotecardLines(name);
            }
        }
        else if(menu == 1)
        {
            debug("[listen] S_DIALOG_CHANNEL, menu: 1, menu transition: 0, cmd: " + m);
            llRegionSayTo(target, MANTRA_CHANNEL, "AUDITORY_BIMBO_LIMIT " + m);
            menu = 0;
            llDialog(llGetOwner(), "Select a command...", orderbuttons(page), S_DIALOG_CHANNEL);
        }
        else if(menu == 2)
        {
            debug("[listen] S_DIALOG_CHANNEL, menu: 2, menu transition: 0, cmd: " + m);
            llRegionSayTo(target, MANTRA_CHANNEL, "AUDITORY_BIMBO_ODDS " + m);
            menu = 0;
            llDialog(llGetOwner(), "Select a command...", orderbuttons(page), S_DIALOG_CHANNEL);
        }
        else if(menu == 3)
        {
            debug("[listen] S_DIALOG_CHANNEL, menu: 3, menu transition: 0, cmd: " + m);
            llRegionSayTo(target, MANTRA_CHANNEL, "TIMER " + m);
            menu = 0;
            llDialog(llGetOwner(), "Select a command...", orderbuttons(page), S_DIALOG_CHANNEL);
        }
        else if(menu == 4)
        {
            debug("[listen] S_DIALOG_CHANNEL, menu: 4, menu transition: 0, cmd: " + m);
            llRegionSayTo(target, MANTRA_CHANNEL, "NAME " + m);
            menu = 0;
            llDialog(llGetOwner(), "Select a command...", orderbuttons(page), S_DIALOG_CHANNEL);
        }
        else if(menu == 5)
        {
            debug("[listen] S_DIALOG_CHANNEL, menu: 5, cmd: " + m);
            if(m == "CANCEL") return;
            else if(m == "OK")
            {
                ncpage = 0;
                giveDelete();
            }
            else if(m == "BACK" || m == " ")
            {
                giveMenu();
            }
            else if(m == "→")
            {
                ncpage++;
                giveDelete();
            }
            else if(m == "←")
            {
                ncpage--;
                giveDelete();
            }
            else if(m == "YES")
            {
                debug("[listen] S_DIALOG_CHANNEL, menu: 5, deletion confirmed for: " + todel);
                llRemoveInventory(todel);
                llDialog(llGetOwner(), "The notecard " + todel + " has been deleted.", ["OK"], S_DIALOG_CHANNEL);
            }
            else if(m == "NO")
            {
                debug("[listen] S_DIALOG_CHANNEL, menu: 5, deletion rejected for: " + todel);
                todel = "";
                giveDelete();
            }
            else
            {
                todel = llGetInventoryName(INVENTORY_NOTECARD, (integer)m);
                debug("[listen] S_DIALOG_CHANNEL, menu: 5, deletion confirmation for: " + todel);
                llDialog(llGetOwner(), "Are you certain you wish to delete " + todel + "?", ["YES", "NO"], S_DIALOG_CHANNEL);
            }
        }
        else if(menu == 6)
        {
            debug("[listen] S_DIALOG_CHANNEL, menu: 6, menu transition: 0, cmd: " + m);
            llRegionSayTo(target, MANTRA_CHANNEL, m);
            menu = 0;
            llDialog(llGetOwner(), "Select a command...", orderbuttons(page), S_DIALOG_CHANNEL);
        }
        else if(menu == -1)
        {
            target = llList2Key(targets, (integer)m);
            debug("[listen] S_DIALOG_CHANNEL, menu: -1, target: " + (string)target);
            ncpage = 0;
            giveMenu();
        }
    }

    dataserver(key q, string d)
    {
        if(q == getline && ready == FALSE)
        {
            integer sent = 0;
            while(d != NAK)
            {
                if(d == EOF)
                {
                    debug("[dataserver] End of config notecard");
                    llRemoveInventory("Intrusive Thoughts Configuration");
                    llMessageLinked(LINK_SET, M_API_CONFIG_DONE, "", NULL_KEY);
                    llMessageLinked(LINK_SET, M_API_STATUS_DONE, "", (string)"");
                    ready = TRUE;
                    name = "";
                    return;
                }
                else if(llStringTrim(d, STRING_TRIM) == "")
                {
                    debug("[dataserver] Config notecard, ignored line: " + (string)line);
                }
                else if(startswith(d, "#"))
                {
                    debug("[dataserver] Config notecard, ignored line: " + (string)line);
                }
                else
                {
                    if(continued)
                    {
                        debug("[dataserver] Config notecard, line: " + (string)line + ", data continuation: " + d);
                        value += d;
                    }
                    else
                    {
                        list tokens = llParseStringKeepNulls(d, ["="], []);
                        setting = llStringTrim(llList2String(tokens, 0), STRING_TRIM);
                        value   = llStringTrim(llDumpList2String(llDeleteSubList(tokens, 0, 0), "="), STRING_TRIM);
                        debug("[dataserver] Config notecard, line: " + (string)line + ", start of data for setting: " + setting + ", data: " + value);
                    }

                    if(llGetSubString(d, -1, -1) == "\\")
                    {
                        continued = TRUE;
                        value = llDeleteSubString(value, -1, -1);
                        debug("[dataserver] Config notecard, line: " + (string)line + ", current data continues in next line");
                    }
                    else
                    {
                        continued = FALSE;
                    }

                    if(!continued)
                    {
                        debug("[dataserver] Config notecard, line: " + (string)line + ", sending built M_API_CONFIG_DATA");
                        llMessageLinked(LINK_SET, M_API_CONFIG_DATA, setting, (key)value);
                        llLinksetDataWriteProtected("it-" + (string)storedCt, setting + "=" + value, "");
                        storedCt++;
                        llLinksetDataWriteProtected("it-ct", (string)storedCt, "");
                        sent++;
                        if(sent > 15)
                        {
                            ++line;
                            sensortimer(0.1);
                            return;
                        }
                    }
                }
                ++line;
                d = llGetNotecardLineSync(name, line);
            }

            if(d == NAK)
            {
                --line;
                getline = llGetNotecardLine(name, line);
            }
        }
        else if(q == getlines)
        {
            lines = (integer)d;
            debug("[dataserver] Notecard line count query for: " + name + ", lines: " + (string)lines);
            line = 0;
            prefix = "";
            getline = llGetNotecardLine(name, line);
        }
        else if(q == getline)
        {
            while(d != NAK)
            {
                integer sent = 0;
                settext();
                if(d == EOF)
                {
                    debug("[dataserver] End of applier notecard, notecard: " + name);
                    name = "";
                    return;
                }
                else if(llStringTrim(d, STRING_TRIM) == "")
                {
                    debug("[dataserver] Applier notecard, ignored line: " + (string)line + ", notecard: " + name);
                }
                else if(startswith(d, "█"))
                {
                    prefix = llGetSubString(d, 1, -1);
                    if(prefix == "END")
                    {
                        debug("[dataserver] Applier notecard, line: " + (string)line + ", notecard: " + name + ", explicit early end");
                        line = lines-1;
                    }
                    else
                    {
                        debug("[dataserver] Applier notecard, line: " + (string)line + ", notecard: " + name + ", prefix change: " + prefix);
                    }
                }
                else if(startswith(d, "#"))
                {
                    debug("[dataserver] Applier notecard, ignored line: " + (string)line + ", notecard: " + name);
                }
                else
                {
                    debug("[dataserver] Applier notecard, line: " + (string)line + ", notecard: " + name + ", data for prefix: " + prefix + ", data: " + d);
                    llRegionSayTo(target, MANTRA_CHANNEL, prefix + " " + d);
                    sent++;
                    if(sent > 30)
                    {
                        llSleep(0.5);
                        sent = 0;
                    }
                }
                ++line;
                d = llGetNotecardLineSync(name, line);
            }

            if(d == NAK)
            {
                --line;
                getline = llGetNotecardLine(name, line);
            }
        }
    }

    timer()
    {
        llSetTimerEvent(0.0);
        llSetObjectName("");
        if(targets == [])
        {
            debug("[timer] No slave responses");
            llOwnerSay("No slaves found.");
            llSetObjectName(master_base);
            return;
        }
        else if(llGetListLength(targets) == 1)
        {
            target = llList2Key(targets, 0);
            debug("[timer] Exactly one slave response, uuid: " + (string)target);
            ncpage = 0;
            giveMenu();
            return;
        }
        else if(llGetListLength(targets) > 12 && retry == FALSE)
        {
            debug("[timer] Too many slave responses, rebroadcast in smaller range");
            llOwnerSay("Too many responses. Trying again with a 10 meter range.");
            llSetObjectName(master_base);
            targets = [];
            retry = TRUE;
            llWhisper(MANTRA_CHANNEL, "PING");
            llSetTimerEvent(1.0);
            return;
        }
        else if(llGetListLength(targets) > 12 && retry == TRUE)
        {
            debug("[timer] Too many slave responses with smaller range, trimming to first 12 respondents");
            llOwnerSay("Too many responses. Giving a menu with the first 12 responses.");
            llSetObjectName(master_base);
        }
        giveTargets();
    }
}
