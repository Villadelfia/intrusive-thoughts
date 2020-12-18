#define MANTRA_CHANNEL -216684563
#define DIALOG_CHANNEL -219755312
#define MC_CHANNEL            999
integer retry = FALSE;
key target;
list targets = [];
key getline;
key getlines;
integer line;
integer lines;
string name;
string prefix;
integer menu = 0;

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

list orderButtons(list buttons)
{
    return llList2List(buttons, -3, -1) + llList2List(buttons, -6, -4)
         + llList2List(buttons, -9, -7) + llList2List(buttons, -12, -10);
}

integer startswith(string haystack, string needle)
{
    return llDeleteSubString(haystack, llStringLength(needle), 0x7FFFFFF0) == needle;
}

setText()
{
    if(line >= lines) 
    {
        llSetText("" , <1.0, 1.0, 1.0>, 0.0);
        llRegionSayTo(target, MANTRA_CHANNEL, "END");
    }
    else 
    {
        llSetText("Reading " + name + ":\n" + (string)line + "/" + (string)lines, <1.0, 1.0, 1.0>, 1.0);
    }
}

giveMenu()
{
    string prompt = "Controlling secondlife:///app/agent/" + (string)target + "/about. Choose a notecard to send, or select another option.\n";
    integer i;
    integer l = llGetInventoryNumber(INVENTORY_NOTECARD);
    if(l > 10) l = 10;
    list buttons = [];
    for(i = 0; i < l; ++i)
    {
        buttons += [(string)i];
        prompt += "\n" + (string)i + ": " + llGetInventoryName(INVENTORY_NOTECARD, i);
    }
    while(llGetListLength(buttons) < 10) buttons += [" "];
    buttons += ["MENU", "CANCEL"];
    menu = 0;
    llDialog(llGetOwner(), prompt, orderButtons(buttons), DIALOG_CHANNEL);
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
    llDialog(llGetOwner(), prompt, orderButtons(buttons), DIALOG_CHANNEL);
}

default
{
    attach(key id)
    {
        if(id) llRequestPermissions(llGetOwner(), PERMISSION_TAKE_CONTROLS);
    }

    run_time_permissions(integer perm)
    {
        if(perm & PERMISSION_TAKE_CONTROLS) llTakeControls(CONTROL_FWD, FALSE, TRUE);
    }

    state_entry()
    {
        llListen(DIALOG_CHANNEL, "", llGetOwner(), "");
        llListen(MANTRA_CHANNEL-1, "", NULL_KEY, "");
        llRequestPermissions(llGetOwner(), PERMISSION_TAKE_CONTROLS);
    }

    changed(integer change)
    {
        if(change & CHANGED_OWNER)
        {
            llResetScript();
        }
    }

    touch_start(integer num)
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
        llSetTimerEvent(2.5);
    }

    listen(integer c, string n, key k, string m)
    {
        if(c == MANTRA_CHANNEL-1)
        {
            targets += [llGetOwnerKey(k)];
        }
        else if(menu == 0)
        {
            if(m == "CANCEL")
            {
                return;
            }
            else if(m == "BACK" || m == " ")
            {
                giveMenu();
            }
            else if(m == "MENU" || m == "<--")
            {
                llDialog(llGetOwner(), "Select a command...", orderButtons(page1), DIALOG_CHANNEL);
            }
            else if(m == "-->")
            {
                llDialog(llGetOwner(), "Select a command...", orderButtons(page2), DIALOG_CHANNEL);
            }
            else if(m == "B.MUTE OFF")
            {
                llRegionSayTo(target, MANTRA_CHANNEL, "BLIND_MUTE 0");
                llDialog(llGetOwner(), "Select a command...", orderButtons(page1), DIALOG_CHANNEL);
            }
            else if(m == "B.MUTE ON")
            {
                llRegionSayTo(target, MANTRA_CHANNEL, "BLIND_MUTE 1");
                llDialog(llGetOwner(), "Select a command...", orderButtons(page1), DIALOG_CHANNEL);
            }
            else if(m == "(UN)LOCK")
            {
                llRegionSayTo(target, MANTRA_CHANNEL, "LOCK");
                llDialog(llGetOwner(), "Select a command...", orderButtons(page1), DIALOG_CHANNEL);
            }
            else if(m == "MAN. CMD.")
            {
                menu = 7;
                llTextBox(llGetOwner(), "Enter a manual command.", DIALOG_CHANNEL);
            }
            else if(m == "BIMBO OFF")
            {
                llRegionSayTo(target, MANTRA_CHANNEL, "AUDITORY_BIMBO_LIMIT 0");
                llDialog(llGetOwner(), "Select a command...", orderButtons(page1), DIALOG_CHANNEL);
            }
            else if(m == "BIMBO SET")
            {
                menu = 1;
                llTextBox(llGetOwner(), "Enter the maximum word length.", DIALOG_CHANNEL);
            }
            else if(m == "BIMBO ODDS")
            {
                menu = 2;
                llTextBox(llGetOwner(), "Enter the letter drop chance.", DIALOG_CHANNEL);
            }
            else if(m == "RESET")
            {
                llRegionSayTo(target, MANTRA_CHANNEL, "RESET");
                llDialog(llGetOwner(), "Select a command...", orderButtons(page2), DIALOG_CHANNEL);
            }
            else if(m == "TIMER SET")
            {
                menu = 3;
                llTextBox(llGetOwner(), "Enter the timer min and max.", DIALOG_CHANNEL);
            }
            else if(m == "NAME")
            {
                menu = 4;
                llTextBox(llGetOwner(), "Enter a new name.", DIALOG_CHANNEL);
            }
            else if(m == "MC SAY")
            {
                menu = 5;
                llTextBox(llGetOwner(), "Enter a message for your submissive to say.", DIALOG_CHANNEL);
            }
            else if(m == "THINK")
            {
                menu = 6;
                llTextBox(llGetOwner(), "Enter a thought to trigger.", DIALOG_CHANNEL);
            }
            else if(m == "LOCAL IM")
            {
                llRegionSayTo(target, MANTRA_CHANNEL, "NOIM");
                llDialog(llGetOwner(), "Select a command...", orderButtons(page2), DIALOG_CHANNEL);
            }
            else if(m == "RLV CMD.")
            {
                menu = 7;
                llTextBox(llGetOwner(), "Enter a manual RLV command. Do not forget the @!", DIALOG_CHANNEL);
            }
            else if(m == "LIST ROOT")
            {
                llRegionSayTo(target, MANTRA_CHANNEL, "LIST");
                llDialog(llGetOwner(), "Select a command...", orderButtons(page2), DIALOG_CHANNEL);
            }
            else if(m == "LIST PATH")
            {
                menu = 8;
                llTextBox(llGetOwner(), "Enter a subpath to list.", DIALOG_CHANNEL);
            }
            else if(m == "STRIP")
            {
                llRegionSayTo(target, MANTRA_CHANNEL, "STRIP");
                llDialog(llGetOwner(), "Select a command...", orderButtons(page2), DIALOG_CHANNEL);
            }
            else if(m == "OUTFIT")
            {
                menu = 9;
                llTextBox(llGetOwner(), "Enter an outfit name.", DIALOG_CHANNEL);
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
            llDialog(llGetOwner(), "Select a command...", orderButtons(page1), DIALOG_CHANNEL);
        }
        else if(menu == 2)
        {
            llRegionSayTo(target, MANTRA_CHANNEL, "AUDITORY_BIMBO_ODDS " + m);
            menu = 0;
            llDialog(llGetOwner(), "Select a command...", orderButtons(page1), DIALOG_CHANNEL);
        }
        else if(menu == 3)
        {
            llRegionSayTo(target, MANTRA_CHANNEL, "TIMER " + m);
            menu = 0;
            llDialog(llGetOwner(), "Select a command...", orderButtons(page1), DIALOG_CHANNEL);
        }
        else if(menu == 4)
        {
            llRegionSayTo(target, MANTRA_CHANNEL, "NAME " + m);
            menu = 0;
            llDialog(llGetOwner(), "Select a command...", orderButtons(page1), DIALOG_CHANNEL);
        }
        else if(menu == 5)
        {
            llRegionSayTo(target, MC_CHANNEL, m);
            menu = 0;
            llDialog(llGetOwner(), "Select a command...", orderButtons(page1), DIALOG_CHANNEL);
        }
        else if(menu == 6)
        {
            llRegionSayTo(target, MANTRA_CHANNEL, "TRIGGER_THOUGHT " + m);
            menu = 0;
            llDialog(llGetOwner(), "Select a command...", orderButtons(page2), DIALOG_CHANNEL);
        }
        else if(menu == 7)
        {
            llRegionSayTo(target, MANTRA_CHANNEL, m);
            menu = 0;
            llDialog(llGetOwner(), "Select a command...", orderButtons(page2), DIALOG_CHANNEL);
        }
        else if(menu == 8)
        {
            llRegionSayTo(target, MANTRA_CHANNEL, "LIST " + m);
            menu = 0;
            llDialog(llGetOwner(), "Select a command...", orderButtons(page2), DIALOG_CHANNEL);
        }
        else if(menu == 8)
        {
            llRegionSayTo(target, MANTRA_CHANNEL, "OUTFIT " + m);
            menu = 0;
            llDialog(llGetOwner(), "Select a command...", orderButtons(page2), DIALOG_CHANNEL);
        }
        else if(menu == -1)
        {
            target = llList2Key(targets, (integer)m);
            giveMenu();
        }
    }

    dataserver(key q, string d)
    {
        if(q == getlines)
        {
            lines = (integer)d;
            line = 0;
            prefix = "";
            getline = llGetNotecardLine(name, line);
        }
        else if(q == getline)
        {
            setText();
            if(d == EOF) 
            {
                name = "";
                return;
            }
            else if(llStringTrim(d, STRING_TRIM) == "") 
            {
            }
            else if(startswith(d, "█"))
            {
                prefix = llGetSubString(d, 1, -1);
                if(prefix == "END")
                {
                    line = lines-1;
                }
            }
            else if(startswith(d, "#"))
            {
            }
            else
            {
                llRegionSayTo(target, MANTRA_CHANNEL, prefix + " " + d);
            }
            
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
            llSetTimerEvent(2.5);
            return;
        }
        else if(llGetListLength(targets) > 12 && retry == TRUE)
        {
            llOwnerSay("Too many responses. Giving a menu with the first 12 responses.");
        }
        giveTargets();
    }
}