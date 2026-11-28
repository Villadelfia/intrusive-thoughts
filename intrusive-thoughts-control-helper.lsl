#include <IT/globals.lsl>
#define MENU_ROOT 0
#define MENU_WORN_ROOT 1
#define MENU_FOCUS_ROOT 2
#define MENU_SLAVES_ROOT 3
#define MENU_WORN_TOP 4

integer menustate = MENU_ROOT;
list balls = [];
key targetball;
key targetavatar;
string targetdesc;
string targetprefix;
string targetrestrictions;

givemenu()
{
    list buttons = [];
    string msg = "";
    if(menustate == MENU_ROOT)
    {
        msg = "Which of these do you want easier menus for?\n\n1. Worn objects.\n2. Focus targets.\n3. Slaves in the region.";
        buttons = ["1", "2", "3", " ", " ", " ", " ", " ", " ", " ", " ", "CLOSE"];
        llDialog(llGetOwner(), msg, orderbuttons(buttons), HELPER_CHANNEL);
    }
    else if(menustate == MENU_WORN_ROOT)
    {
        purgeballs();
        if(balls == [])
        {
            msg = "You're not wearing anyone, or they're sitting on outdated IT 'balls', for example from older furniture.";
            buttons = ["OK"];
            llDialog(llGetOwner(), msg, orderbuttons(buttons), HELPER_CHANNEL);
        }
        else
        {
            integer i = 0;
            integer n = llGetListLength(balls);
            string desc;
            msg = "Which object do you want to change settings for:\n";
            while(i < 12 && i < n)
            {
                desc = llList2String(llParseString2List(llList2String(llGetObjectDetails(llList2Key(balls, i), [OBJECT_DESC]), 0), [";"], []), 2);
                msg += "\n" + (string)(i+1) + ". " + desc + ".";
                buttons += [(string)(i+1)];
                i++;
            }
            while(llGetListLength(buttons) < 11) buttons += [" "];
            if(llGetListLength(buttons) == 11) buttons += ["BACK"];
            llDialog(llGetOwner(), msg, orderbuttons(buttons), HELPER_CHANNEL);
        }
    }
    else if(menustate == MENU_WORN_TOP)
    {
        llDialog(llGetOwner(), "Victim: secondlife:///app/agent/"+(string)targetavatar+"/inspect.", ["OK"], HELPER_CHANNEL);
    }
    else
    {
        msg = "Sorry, this part of the control helper hud hasn't been implemented yet.";
        buttons = ["OK"];
        llDialog(llGetOwner(), msg, orderbuttons(buttons), HELPER_CHANNEL);
    }
}

getballdetails(key ball)
{
    targetball = ball;
    list desc = llParseString2List(llList2String(llGetObjectDetails(targetball, [OBJECT_DESC]), 0), [";"], []);
    targetprefix = llList2String(desc, 1);
    targetdesc = llList2String(desc, 2);
    targetrestrictions = llList2String(desc, 3);
    targetavatar = NULL_KEY;
    list agents = llGetAgentList(AGENT_LIST_REGION, []);
    integer n = llGetListLength(agents);
    while(~--n)
    {
        if(targetball == llList2Key(llGetObjectDetails(llList2Key(agents, n), [OBJECT_ROOT]), 0))
        {
            targetavatar = llList2Key(agents, n);
            return;
        }
    }
}

purgeballs()
{
    if(balls != [])
    {
        integer l = llGetListLength(balls);
        while(~--l)
        {
            if(!startswith(llList2String(llGetObjectDetails(llList2Key(balls, l), [OBJECT_DESC]), 0), (string)llGetOwner()))
            {
                balls = llDeleteSubList(balls, l, l);
            }
        }
    }
}

default
{
    attach(key id)
    {
        if(id) llResetScript();
    }

    state_entry()
    {
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
        llListen(HELPER_CHANNEL, "", llGetOwner(), "");
        llOwnerSay("Click me to get a menu that'll help you with some of the fiddlier parts of IT.");
        llSetTimerEvent(5.0);
    }

    touch_end(integer num_detected)
    {
        menustate = MENU_ROOT;
        givemenu();
    }

    listen(integer c, string n, key id, string m)
    {
        if(c == MANTRA_CHANNEL)
        {
            if(m == "ball_owned")
            {
                integer i = llListFindList(balls, [id]);
                if(i == -1) balls += [id];
            }
            else if(m == "ball_disowned")
            {
                integer i = llListFindList(balls, [id]);
                if(i != -1) balls = llDeleteSubList(balls, i, i);
            }
        }
        else if(c == HELPER_CHANNEL)
        {
            m = llStringTrim(m, STRING_TRIM);
            if(m == "")
            {
                givemenu();
                return;
            }

            if(menustate == MENU_ROOT)
            {
                if(m == "CLOSE") return;
                if(m == "1") menustate = MENU_WORN_ROOT;
                if(m == "2") menustate = MENU_FOCUS_ROOT;
                if(m == "3") menustate = MENU_SLAVES_ROOT;
                givemenu();
            }
            else if(menustate == MENU_WORN_ROOT)
            {
                if(m == "OK" || m == "BACK")
                {
                    menustate = MENU_ROOT;
                    givemenu();
                    return;
                }

                integer i = ((integer)m)-1;
                getballdetails(llList2Key(balls, i));
                menustate = MENU_WORN_TOP;
                givemenu();
            }
            else
            {
                menustate = MENU_ROOT;
                givemenu();
            }
        }
    }

    timer()
    {
        purgeballs();
    }
}