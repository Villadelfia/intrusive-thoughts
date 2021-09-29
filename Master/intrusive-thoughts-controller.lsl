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
integer menu = 0;
integer ncpage = 0;
key lockedavatar = NULL_KEY;
string lockedname = "";

list page = [
    "B.MUTE OFF", "BIMBO OFF",  "TIMER SET",
    "B.MUTE ON",  "BIMBO SET",  "NAME",
    "RESET",      "BIMBO ODDS", "BACK"
];

settext()
{
    if(line >= lines) 
    {
        llRegionSayTo(target, MANTRA_CHANNEL, "END");
        llMessageLinked(LINK_SET, M_API_STATUS_DONE, "", (string)"");
    }
    else 
    {
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
    llDialog(llGetOwner(), prompt, orderbuttons(buttons), S_DIALOG_CHANNEL);
}

default
{
    state_entry()
    {
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
                llMessageLinked(LINK_SET, M_API_CONFIG_DONE, "", NULL_KEY);
            }
            else
            {
                llOwnerSay(VERSION_M + ": Drop your 'Intrusive Thoughts Configuration' notecard onto the HUD to set it up.");
            }
        }
        else if(num == M_API_CONFIG_DONE)
        {
            llOwnerSay(VERSION_M + ": Startup complete. Welcome to your Intrusive Thoughts system. Click and hold any button for more than a second to get basic usage information. For more documentation read the included Instruction Manual notecard.");
            if(llGetPermissions() & PERMISSION_TAKE_CONTROLS == 0) llRequestPermissions(llGetOwner(), PERMISSION_TAKE_CONTROLS);
        }
        else if(num == M_API_LOCK)
        {
            lockedavatar = id;
            lockedname = str;
        }

        if(!ready) return;

        if(num == M_API_BUTTON_PRESSED)
        {
            if(str == "menu")
            {
                if(name != "")
                {
                    llOwnerSay("Hold on. We're busy sending settings...");
                    return;
                }

                if(lockedavatar)
                {
                    llOwnerSay("Displaying the menu for the Intrusive Thoughts slave worn by '" + lockedname + "'.");
                    llRegionSayTo(lockedavatar, MANTRA_CHANNEL, "PING");
                    llRegionSayTo(lockedavatar, COMMAND_CHANNEL, "*");
                }
                else
                {
                    llOwnerSay("Pinging the region for Intrusive Thoughts slaves under your control...");
                    targets = [];
                    retry = FALSE;
                    llRegionSay(MANTRA_CHANNEL, "PING");
                    llSetTimerEvent(1.0);
                }
            }
        }
    }

    run_time_permissions(integer perm)
    {
        if(perm & PERMISSION_TAKE_CONTROLS) llTakeControls(CONTROL_FWD, FALSE, TRUE);
    }

    changed(integer change)
    {
        if(change & CHANGED_INVENTORY)
        {
            if(llGetInventoryType("Intrusive Thoughts Configuration") == INVENTORY_NOTECARD)
            {
                if(!ready) llMessageLinked(LINK_SET, M_API_BUTTON_PRESSED, "hide", "");
                llMessageLinked(LINK_SET, M_API_STATUS_MESSAGE, "Loading config...", "");
                ready = FALSE;
                name = "Intrusive Thoughts Configuration";
                line = 0;
                getline = llGetNotecardLine(name, line);
            }
        }
    }

    listen(integer c, string n, key k, string m)
    {
        if(c == HUD_SPEAK_CHANNEL) llOwnerSay(m);
        else if(c == PING_CHANNEL)
        {
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
            if(m == "CANCEL") return;
            else if(m == "BACK" || m == " ") giveMenu();
            else if(m == "MENU") llDialog(llGetOwner(), "Select a command...", orderbuttons(page), S_DIALOG_CHANNEL);
            else if(m == "DELETE") giveDelete();
            else if(m == "→")
            {
                ncpage++;
                giveMenu();
            }
            else if(m == "←")
            {
                ncpage--;
                giveMenu();
            }
            else if(m == "B.MUTE OFF")
            {
                llRegionSayTo(target, MANTRA_CHANNEL, "BLIND_MUTE 0");
                llDialog(llGetOwner(), "Select a command...", orderbuttons(page), S_DIALOG_CHANNEL);
            }
            else if(m == "B.MUTE ON")
            {
                llRegionSayTo(target, MANTRA_CHANNEL, "BLIND_MUTE 1");
                llDialog(llGetOwner(), "Select a command...", orderbuttons(page), S_DIALOG_CHANNEL);
            }
            else if(m == "BIMBO OFF")
            {
                llRegionSayTo(target, MANTRA_CHANNEL, "AUDITORY_BIMBO_LIMIT 0");
                llDialog(llGetOwner(), "Select a command...", orderbuttons(page), S_DIALOG_CHANNEL);
            }
            else if(m == "BIMBO SET")
            {
                menu = 1;
                llTextBox(llGetOwner(), "Enter the maximum word length.", S_DIALOG_CHANNEL);
            }
            else if(m == "BIMBO ODDS")
            {
                menu = 2;
                llTextBox(llGetOwner(), "Enter the letter drop chance.", S_DIALOG_CHANNEL);
            }
            else if(m == "RESET")
            {
                llRegionSayTo(target, MANTRA_CHANNEL, "RESET");
                llDialog(llGetOwner(), "Select a command...", orderbuttons(page), S_DIALOG_CHANNEL);
            }
            else if(m == "TIMER SET")
            {
                menu = 3;
                llTextBox(llGetOwner(), "Enter the timer min and max.", S_DIALOG_CHANNEL);
            }
            else if(m == "NAME")
            {
                menu = 4;
                llTextBox(llGetOwner(), "Enter a new name.", S_DIALOG_CHANNEL);
            }
            else
            {
                llRegionSayTo(target, MANTRA_CHANNEL, "RESET");
                name = llGetInventoryName(INVENTORY_NOTECARD, (integer)m);
                getlines = llGetNumberOfNotecardLines(name);
            }
        }
        else if(menu == 1)
        {
            llRegionSayTo(target, MANTRA_CHANNEL, "AUDITORY_BIMBO_LIMIT " + m);
            menu = 0;
            llDialog(llGetOwner(), "Select a command...", orderbuttons(page), S_DIALOG_CHANNEL);
        }
        else if(menu == 2)
        {
            llRegionSayTo(target, MANTRA_CHANNEL, "AUDITORY_BIMBO_ODDS " + m);
            menu = 0;
            llDialog(llGetOwner(), "Select a command...", orderbuttons(page), S_DIALOG_CHANNEL);
        }
        else if(menu == 3)
        {
            llRegionSayTo(target, MANTRA_CHANNEL, "TIMER " + m);
            menu = 0;
            llDialog(llGetOwner(), "Select a command...", orderbuttons(page), S_DIALOG_CHANNEL);
        }
        else if(menu == 4)
        {
            llRegionSayTo(target, MANTRA_CHANNEL, "NAME " + m);
            menu = 0;
            llDialog(llGetOwner(), "Select a command...", orderbuttons(page), S_DIALOG_CHANNEL);
        }
        else if(menu == 5)
        {
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
                llRemoveInventory(todel);
                llDialog(llGetOwner(), "The notecard " + todel + " has been deleted.", ["OK"], S_DIALOG_CHANNEL);
            }
            else if(m == "NO")
            {
                giveDelete();
            }
            else
            {
                todel = llGetInventoryName(INVENTORY_NOTECARD, (integer)m);
                llDialog(llGetOwner(), "Are you certain you wish to delete " + todel + "?", ["YES", "NO"], S_DIALOG_CHANNEL);
            }
        }
        else if(menu == -1)
        {
            target = llList2Key(targets, (integer)m);
            ncpage = 0;
            giveMenu();
        }
    }

    dataserver(key q, string d)
    {
        if(q == getline && ready == FALSE)
        {
            if(d == EOF)
            {
                llRemoveInventory("Intrusive Thoughts Configuration");
                llMessageLinked(LINK_SET, M_API_CONFIG_DONE, "", NULL_KEY);
                llMessageLinked(LINK_SET, M_API_STATUS_DONE, "", (string)"");
                ready = TRUE;
                name = "";
                return;
            }
            else if(llStringTrim(d, STRING_TRIM) == "");
            else if(startswith(d, "#"));
            else
            {
                list tokens = llParseStringKeepNulls(d, ["="], []);
                llMessageLinked(LINK_SET, M_API_CONFIG_DATA, llStringTrim(llList2String(tokens, 0), STRING_TRIM), (key)llStringTrim(llList2String(tokens, 1), STRING_TRIM));
            }
            ++line;
            getline = llGetNotecardLine(name, line);
        }
        else if(q == getlines)
        {
            lines = (integer)d;
            line = 0;
            prefix = "";
            getline = llGetNotecardLine(name, line);
        }
        else if(q == getline)
        {
            settext();
            if(d == EOF) 
            {
                name = "";
                return;
            }
            else if(llStringTrim(d, STRING_TRIM) == "");
            else if(startswith(d, "█"))
            {
                prefix = llGetSubString(d, 1, -1);
                if(prefix == "END")
                {
                    line = lines-1;
                }
            }
            else if(startswith(d, "#"));
            else llRegionSayTo(target, MANTRA_CHANNEL, prefix + " " + d);
            ++line;
            getline = llGetNotecardLine(name, line);
        }
    }

    timer()
    {
        llSetTimerEvent(0.0);
        if(targets == [])
        {
            llOwnerSay("No slaves found.");
            return;
        }
        else if(llGetListLength(targets) == 1)
        {
            target = llList2Key(targets, 0);
            ncpage = 0;
            giveMenu();
            return;
        }
        else if(llGetListLength(targets) > 12 && retry == FALSE)
        {
            llOwnerSay("Too many responses. Trying again with a 10 meter range.");
            targets = [];
            retry = TRUE;
            llWhisper(MANTRA_CHANNEL, "PING");
            llSetTimerEvent(1.0);
            return;
        }
        else if(llGetListLength(targets) > 12 && retry == TRUE)
        {
            llOwnerSay("Too many responses. Giving a menu with the first 12 responses.");
        }
        giveTargets();
    }
}