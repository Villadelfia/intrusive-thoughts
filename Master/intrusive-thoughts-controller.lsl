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
string prefix;
integer menu = 0;
key confignc;

// TODO: Remove some cruft from the menus.
list page1 = [
    "B.MUTE OFF", "BIMBO OFF",  "TIMER SET",
    "B.MUTE ON",  "BIMBO SET",  "NAME",
    "(UN)LOCK",   "BIMBO ODDS", "MC SAY",
    " ",          "BACK",       "-->"
];

list page2 = [
    "MAN. CMD.", "RESET",    "THINK",
    "LOCAL IM",  "RLV CMD.", "LIST ROOT",
    "LIST PATH", "OUTFIT",   "STRIP",
    "<--",       "BACK",     " "
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
    if(l > 11) l = 11;
    list buttons = [];
    for(i = 0; i < l; ++i)
    {
        if(llGetInventoryName(INVENTORY_NOTECARD, i) != "!config")
        {
            buttons += [(string)i];
            prompt += "\n" + (string)i + ": " + llGetInventoryName(INVENTORY_NOTECARD, i);
        }
    }
    while(llGetListLength(buttons) < 10) buttons += [" "];
    buttons += ["MENU", "CANCEL"];
    menu = 0;
    llDialog(llGetOwner(), prompt, orderbuttons(buttons), S_DIALOG_CHANNEL);
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
                llOwnerSay(VERSION_C + ": Startup complete. Welcome to your Intrusive Thoughts system.");
                llRequestPermissions(llGetOwner(), PERMISSION_TAKE_CONTROLS);
            }
            else
            {
                confignc = llGetInventoryKey("!config");
                llMessageLinked(LINK_SET, M_API_STATUS_MESSAGE, "Loading config...", (string)"");
                name = "!config";
                line = 0;
                getline = llGetNotecardLine(name, line);
            }
        }
        else if(num == M_API_CONFIG_DONE)
        {
            llOwnerSay(VERSION_C + ": Startup complete. Welcome to your Intrusive Thoughts system.");
            if(llGetPermissions() & PERMISSION_TAKE_CONTROLS == 0) llRequestPermissions(llGetOwner(), PERMISSION_TAKE_CONTROLS);
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
                llOwnerSay("Pinging the region for Intrusive Thoughts slaves under your control...");
                targets = [];
                retry = FALSE;
                llRegionSay(MANTRA_CHANNEL, "PING");
                llSetTimerEvent(1.0);
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
            if(llGetInventoryKey("!config") != confignc)
            {
                ready = FALSE;
                confignc = llGetInventoryKey("!config");
                llMessageLinked(LINK_SET, M_API_STATUS_MESSAGE, "Loading config...", (string)"");
                name = "!config";
                line = 0;
                getline = llGetNotecardLine(name, line);
            }
        }
    }

    listen(integer c, string n, key k, string m)
    {
        if(c == HUD_SPEAK_CHANNEL) llOwnerSay(m);
        else if(c == PING_CHANNEL) targets += [llGetOwnerKey(k)];
        else if(menu == 0)
        {
            if(m == "CANCEL") return;
            else if(m == "BACK" || m == " ") giveMenu();
            else if(m == "MENU" || m == "<--") llDialog(llGetOwner(), "Select a command...", orderbuttons(page1), S_DIALOG_CHANNEL);
            else if(m == "-->") llDialog(llGetOwner(), "Select a command...", orderbuttons(page2), S_DIALOG_CHANNEL);
            else if(m == "B.MUTE OFF")
            {
                llRegionSayTo(target, MANTRA_CHANNEL, "BLIND_MUTE 0");
                llDialog(llGetOwner(), "Select a command...", orderbuttons(page1), S_DIALOG_CHANNEL);
            }
            else if(m == "B.MUTE ON")
            {
                llRegionSayTo(target, MANTRA_CHANNEL, "BLIND_MUTE 1");
                llDialog(llGetOwner(), "Select a command...", orderbuttons(page1), S_DIALOG_CHANNEL);
            }
            else if(m == "(UN)LOCK")
            {
                llRegionSayTo(target, MANTRA_CHANNEL, "LOCK");
                llDialog(llGetOwner(), "Select a command...", orderbuttons(page1), S_DIALOG_CHANNEL);
            }
            else if(m == "MAN. CMD.")
            {
                menu = 7;
                llTextBox(llGetOwner(), "Enter a manual command.", S_DIALOG_CHANNEL);
            }
            else if(m == "BIMBO OFF")
            {
                llRegionSayTo(target, MANTRA_CHANNEL, "AUDITORY_BIMBO_LIMIT 0");
                llDialog(llGetOwner(), "Select a command...", orderbuttons(page1), S_DIALOG_CHANNEL);
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
                llDialog(llGetOwner(), "Select a command...", orderbuttons(page2), S_DIALOG_CHANNEL);
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
            else if(m == "MC SAY")
            {
                menu = 5;
                llTextBox(llGetOwner(), "Enter a message for your submissive to say.", S_DIALOG_CHANNEL);
            }
            else if(m == "THINK")
            {
                menu = 6;
                llTextBox(llGetOwner(), "Enter a thought to trigger.", S_DIALOG_CHANNEL);
            }
            else if(m == "LOCAL IM")
            {
                llRegionSayTo(target, MANTRA_CHANNEL, "NOIM");
                llDialog(llGetOwner(), "Select a command...", orderbuttons(page2), S_DIALOG_CHANNEL);
            }
            else if(m == "RLV CMD.")
            {
                menu = 7;
                llTextBox(llGetOwner(), "Enter a manual RLV command. Do not forget the @!", S_DIALOG_CHANNEL);
            }
            else if(m == "LIST ROOT")
            {
                llRegionSayTo(target, MANTRA_CHANNEL, "LIST");
                llDialog(llGetOwner(), "Select a command...", orderbuttons(page2), S_DIALOG_CHANNEL);
            }
            else if(m == "LIST PATH")
            {
                menu = 8;
                llTextBox(llGetOwner(), "Enter a subpath to list.", S_DIALOG_CHANNEL);
            }
            else if(m == "STRIP")
            {
                llRegionSayTo(target, MANTRA_CHANNEL, "STRIP");
                llDialog(llGetOwner(), "Select a command...", orderbuttons(page2), S_DIALOG_CHANNEL);
            }
            else if(m == "OUTFIT")
            {
                menu = 9;
                llTextBox(llGetOwner(), "Enter an outfit name.", S_DIALOG_CHANNEL);
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
            llDialog(llGetOwner(), "Select a command...", orderbuttons(page1), S_DIALOG_CHANNEL);
        }
        else if(menu == 2)
        {
            llRegionSayTo(target, MANTRA_CHANNEL, "AUDITORY_BIMBO_ODDS " + m);
            menu = 0;
            llDialog(llGetOwner(), "Select a command...", orderbuttons(page1), S_DIALOG_CHANNEL);
        }
        else if(menu == 3)
        {
            llRegionSayTo(target, MANTRA_CHANNEL, "TIMER " + m);
            menu = 0;
            llDialog(llGetOwner(), "Select a command...", orderbuttons(page1), S_DIALOG_CHANNEL);
        }
        else if(menu == 4)
        {
            llRegionSayTo(target, MANTRA_CHANNEL, "NAME " + m);
            menu = 0;
            llDialog(llGetOwner(), "Select a command...", orderbuttons(page1), S_DIALOG_CHANNEL);
        }
        else if(menu == 5)
        {
            llRegionSayTo(target, MANTRA_CHANNEL, "say " + m);
            menu = 0;
            llDialog(llGetOwner(), "Select a command...", orderbuttons(page1), S_DIALOG_CHANNEL);
        }
        else if(menu == 6)
        {
            llRegionSayTo(target, MANTRA_CHANNEL, "think " + m);
            menu = 0;
            llDialog(llGetOwner(), "Select a command...", orderbuttons(page2), S_DIALOG_CHANNEL);
        }
        else if(menu == 7)
        {
            llRegionSayTo(target, MANTRA_CHANNEL, m);
            menu = 0;
            llDialog(llGetOwner(), "Select a command...", orderbuttons(page2), S_DIALOG_CHANNEL);
        }
        else if(menu == 8)
        {
            llRegionSayTo(target, MANTRA_CHANNEL, "LIST " + m);
            menu = 0;
            llDialog(llGetOwner(), "Select a command...", orderbuttons(page2), S_DIALOG_CHANNEL);
        }
        else if(menu == 8)
        {
            llRegionSayTo(target, MANTRA_CHANNEL, "OUTFIT " + m);
            menu = 0;
            llDialog(llGetOwner(), "Select a command...", orderbuttons(page2), S_DIALOG_CHANNEL);
        }
        else if(menu == -1)
        {
            target = llList2Key(targets, (integer)m);
            giveMenu();
        }
    }

    dataserver(key q, string d)
    {
        if(q == getline && ready == FALSE)
        {
            if(d == EOF)
            {
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
                list tokens = llParseString2List(d, ["|"], []);
                llMessageLinked(LINK_SET, M_API_CONFIG_DATA, llList2String(tokens, 0), (key)llList2String(tokens, 1));
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