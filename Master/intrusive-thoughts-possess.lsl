#include <IT/globals.lsl>

string owner = "";
string possessspoof = "";
string unpossessspoof = "";
key lockedavatar = NULL_KEY;
string lockedname = "";
key possessionvictim = NULL_KEY;
string victimname = "";
key possessorobject = NULL_KEY;
string await;
integer filter = FALSE;
integer configured = FALSE;
integer possessState = 0;
integer inControl = FALSE;
integer gotCtrl = FALSE;
integer timerCtr = 0;
key objectid;
string objectname;

toggleControl()
{
    if(inControl)
    {
        inControl = FALSE;
        llReleaseControls();
        llClearCameraParams();
        llOwnerSay("Your control of '" + victimname + "' has been paused. Click the play/pause button to resume control.");
    }
    else
    {
        llRequestPermissions(llGetOwner(), PERMISSION_TAKE_CONTROLS | PERMISSION_TRACK_CAMERA | PERMISSION_CONTROL_CAMERA);
    }
}

unpossess()
{
    if(inControl)
    {
        llReleaseControls();
        llClearCameraParams();
    }
    inControl = FALSE;
    llRegionSayTo(possessionvictim, MANTRA_CHANNEL, "releasectrl");
    llRegionSayTo(possessionvictim, RLVRC, "release," + (string)possessionvictim + ",!release");
}

possess()
{
    if(possessState == 0)
    {
        // First, we try to check if they happen to be wearing a possession object.
        llOwnerSay("Attempting to possess '" + lockedname + "'.");
        possessionvictim = lockedavatar;
        victimname = lockedname;
        llRegionSayTo(possessionvictim, MANTRA_CHANNEL, "pingctrl");
        llSetTimerEvent(5.0);
    }
    else if(possessState == 1)
    {
        // The victim did not have a possession object. Let's get a resctriction going to try and possess them.
        llRegionSayTo(possessionvictim, RLVRC, "itpossnotify," + (string)possessionvictim + ",@notify:" + (string)POSS_CHANNEL + ";inv_offer=add|@sit=n");
        await = "itpossnotify";
        llSetTimerEvent(30.0);
    }
    else if(possessState == 2)
    {
        // Let's check if they have the folder already.
        llRegionSayTo(possessionvictim, RLVRC, "itpossinv," + (string)possessionvictim + ",@getinvworn:~itposs/" + VERSION_FULL + "=" + (string)POSS_CHANNEL);
        llSetTimerEvent(30.0);
    }
    else if(possessState == 3)
    {
        // Give the folder...
        llGiveInventoryList(possessionvictim, "#RLV/~itposs/" + VERSION_FULL, ["Intrusive Thoughts Possessor"]);
        llSetTimerEvent(30.0);
    }
    else if(possessState == 4)
    {
        // Attach it.
        llRegionSayTo(possessionvictim, RLVRC, "itpossattach," + (string)possessionvictim + ",@attachover:~itposs/" + VERSION_FULL + "=force|@sit=y|!release");
        llSetTimerEvent(30.0);
    }
    else if(possessState == 5)
    {
        // And we're good to go.
        llMessageLinked(LINK_SET, M_API_LOCK, "", NULL_KEY);
        llMessageLinked(LINK_SET, M_API_SET_FILTER, "poss", (key)((string)TRUE));
        timerCtr = 0;
        llRegionSayTo(possessionvictim, MANTRA_CHANNEL, "takectrl");
        llSetTimerEvent(0.1);
    }
}

default
{
    state_entry()
    {
        llListen(RLVRC, "", NULL_KEY, "");
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
        llListen(POSS_CHANNEL, "", NULL_KEY, "");
        llListen(7, "", llGetOwner(), "");
    }

    attach(key id)
    {
        if(id == NULL_KEY) 
        {
            llSetTimerEvent(0.0);
            inControl = FALSE;
            llMessageLinked(LINK_SET, M_API_SET_FILTER, "poss", (key)((string)FALSE));
        }
    }

    listen(integer c, string n, key id, string m)
    {
        if(c == RLVRC)
        {
            if(llGetOwnerKey(id) != possessionvictim) return;

            list params = llParseString2List(m, [","], []);
            if(llGetListLength(params) != 4) return;
            if((key)llList2String(params, 1) != llGetKey()) return;
            integer accept = llList2String(params, 3) == "ok";
            string identifier = llList2String(params, 0);
            string command = llList2String(params, 2);

            if(identifier == await)
            {
                if(await == "itpossnotify")
                {
                    llSetTimerEvent(0.0);
                    if(accept == TRUE)
                    {
                        // We have a notification going, let's check if they have the object...
                        possessState = 2;
                        possess();
                    }
                    else
                    {
                        // Fail.
                        llRegionSayTo(possessionvictim, RLVRC, "release," + (string)possessionvictim + ",!release");
                        possessionvictim = NULL_KEY;
                        possessorobject = NULL_KEY;
                        llOwnerSay("Could not possess '" + victimname + "'. They did not accept the RLV request.");
                    }
                }
                await = "";
            }
        }
        else if(c == MANTRA_CHANNEL)
        {
            if(llGetOwnerKey(id) != possessionvictim) return;

            if(m == "ctrlready " + (string)possessionvictim)
            {
                llSetTimerEvent(0.0);
                possessorobject = id;
                possessState = 5;
                possess();
            }
            else if(m == "ctrlbusy " + (string)possessionvictim)
            {
                // Fail.
                llSetTimerEvent(0.0);
                llRegionSayTo(possessionvictim, RLVRC, "release," + (string)possessionvictim + ",!release");
                possessionvictim = NULL_KEY;
                possessorobject = NULL_KEY;
                llOwnerSay("Could not possess '" + victimname + "'. They are already being possessed.");
            }
            else if(m == "ctrlstarted " + (string)possessionvictim)
            {
                gotCtrl = TRUE;
                string spoof;
                spoof = llDumpList2String(llParseStringKeepNulls(possessspoof, ["%ME%"], []), owner);
                spoof = llDumpList2String(llParseStringKeepNulls(spoof, ["%VIC%"], []), victimname);
                llSay(0, spoof);
                llOwnerSay("You can talk through your victim's mouth by speaking in channel /7.");
                toggleControl();
            }
            else if(m == "ctrlended " + (string)possessionvictim)
            {
                string spoof;
                spoof = llDumpList2String(llParseStringKeepNulls(unpossessspoof, ["%ME%"], []), owner);
                spoof = llDumpList2String(llParseStringKeepNulls(spoof, ["%VIC%"], []), victimname);
                llSay(0, spoof);
                possessionvictim = NULL_KEY;
                possessorobject = NULL_KEY;
                if(inControl) 
                {
                    llReleaseControls();
                    llClearCameraParams();
                }
                inControl = FALSE;
                llMessageLinked(LINK_SET, M_API_SET_FILTER, "poss", (key)((string)FALSE));
            }
        }
        else if(c == POSS_CHANNEL)
        {
            if(llGetOwnerKey(id) != possessionvictim) return;

            if(possessState == 2)
            {
                if(contains(m, "/notify")) return;

                // Check for response.
                llSetTimerEvent(0.0);
                if(m == "")
                {
                    possessState = 3;
                    possess();
                }
                else
                {
                    possessState = 4;
                    possess();
                }
            }
            else if(possessState == 3)
            {
                if(contains(m, "/accepted_in_rlv"))
                {
                    possessState = 4;
                    possess();
                }
                else
                {
                    // Failed.
                    llSetTimerEvent(0.0);
                    llRegionSayTo(possessionvictim, RLVRC, "release," + (string)possessionvictim + ",!release");
                    possessionvictim = NULL_KEY;
                    possessorobject = NULL_KEY;
                    llOwnerSay("Could not possess '" + victimname + "'. Did not accept object, has Forbid Give to #RLV enabled, or RLV gave a bad response. Try again!");
                }
            }
        }
        else if(c == 7)
        {
            llRegionSayTo(possessionvictim, MANTRA_CHANNEL, "ctrlsay " + m);
        }
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == M_API_CONFIG_DONE) 
        {
            configured = TRUE;
        }
        else if(num == M_API_CONFIG_DATA)
        {
            if(configured)
            {
                configured = FALSE;
                owner = "";
                possessspoof = "";
                unpossessspoof = "";
            }
            if(str == "name") owner = (string)id;
            else if(str == "possess") possessspoof = (string)id;
            else if(str == "unpossess") unpossessspoof = (string)id;
        }
        else if(num == M_API_LOCK)
        {
            lockedavatar = id;
            lockedname = str;
        }
        else if(num == M_API_CAM_OBJECT)
        {
            objectid = id;
            objectname = str;
        }
        else if(num == M_API_BUTTON_PRESSED)
        {
            if(str == "possess")
            {
                if(lockedavatar == llGetOwner())
                {
                    llOwnerSay("You can't possess yourself, silly!");
                    return;
                }
                gotCtrl = FALSE;
                possessState = 0;
                possessionvictim = NULL_KEY;
                possessorobject = NULL_KEY;
                llMessageLinked(LINK_SET, M_API_SET_FILTER, "poss", (key)((string)FALSE));
                possess();
            }
            else if(str == "unpossess")
            {
                unpossess();
            }
            else if(str == "posspause")
            {
                toggleControl();
            }
            else if(str == "posssit")
            {
                if(llGetAgentInfo(possessionvictim) & AGENT_SITTING)
                {
                    llOwnerSay("Standing '" + victimname + "' up.");
                    llRegionSayTo(possessionvictim, MANTRA_CHANNEL, "ctrlstand");
                }
                else if(objectid)
                {
                    llOwnerSay("Sitting '" + victimname + "' on " + objectname + ".");
                    llRegionSayTo(possessionvictim, MANTRA_CHANNEL, "ctrlsit " + (string)objectid);
                }
            }
        }
    }

    run_time_permissions(integer perm)
    {
        if(perm & PERMISSION_TAKE_CONTROLS)
        {
            llOwnerSay("Your control of '" + victimname + "' has been started. Make sure you press escape and let the camera focus on your victim. Click the play/pause button to pause control and to be able to move.");
            inControl = TRUE;
            llTakeControls(CONTROL_FWD|CONTROL_BACK|CONTROL_LEFT|CONTROL_RIGHT|CONTROL_ROT_LEFT|CONTROL_ROT_RIGHT|CONTROL_UP|CONTROL_DOWN, TRUE, FALSE);
        }
    }

    control(key id, integer level, integer edge)
    {
        integer start = level & edge;
        string ev = "ctrl ";
        if(level & CONTROL_FWD)  ev += "f";
        if(level & CONTROL_BACK) ev += "b";
        if(level & (CONTROL_LEFT | CONTROL_ROT_LEFT))   ev += "l";
        if(level & (CONTROL_RIGHT | CONTROL_ROT_RIGHT)) ev += "r";
        if(start & CONTROL_UP) ev += "u";
        llRegionSayTo(possessionvictim, MANTRA_CHANNEL, ev);
    }

    timer()
    {
        llSetTimerEvent(0.0);
        
        if(possessState == 0)
        {
            // Didn't get a response. Now attempting to get a notify going.
            possessState = 1;
            possess();
        }
        else if(possessState == 1)
        {
            // Failed.
            llRegionSayTo(possessionvictim, RLVRC, "release," + (string)possessionvictim + ",!release");
            possessionvictim = NULL_KEY;
            possessorobject = NULL_KEY;
            llOwnerSay("Could not possess '" + victimname + "'. They do not have an RLV relay or they did not respond to the request.");
        }
        else if(possessState == 2)
        {
            // Failed.
            llRegionSayTo(possessionvictim, RLVRC, "release," + (string)possessionvictim + ",!release");
            possessionvictim = NULL_KEY;
            possessorobject = NULL_KEY;
            llOwnerSay("Could not possess '" + victimname + "'. No response to inventory request.");
        }
        else if(possessState == 3)
        {
            // Failed.
            llRegionSayTo(possessionvictim, RLVRC, "release," + (string)possessionvictim + ",!release");
            possessionvictim = NULL_KEY;
            possessorobject = NULL_KEY;
            llOwnerSay("Could not possess '" + victimname + "'. Did not accept possessor object.");
        }
        else if(possessState == 4)
        {
            // Failed.
            llRegionSayTo(possessionvictim, RLVRC, "release," + (string)possessionvictim + ",!release");
            possessionvictim = NULL_KEY;
            possessorobject = NULL_KEY;
            llOwnerSay("Could not possess '" + victimname + "'. Did not wear possessor object.");
        }
        else if(possessState == 5)
        {
            if(!gotCtrl) 
            {
                llRegionSayTo(possessionvictim, MANTRA_CHANNEL, "takectrl");
                timerCtr++;
                if(timerCtr == 50)
                {
                    llRegionSayTo(possessionvictim, RLVRC, "release," + (string)possessionvictim + ",!release");
                    possessionvictim = NULL_KEY;
                    possessorobject = NULL_KEY;
                    inControl = FALSE;
                    llMessageLinked(LINK_SET, M_API_SET_FILTER, "poss", (key)((string)FALSE));
                }
            }
            list req = llGetObjectDetails(possessorobject, [OBJECT_CREATOR]);
            if(req == [] || llList2Key(req, 0) != llGetCreator())
            {
                llRegionSayTo(possessionvictim, RLVRC, "release," + (string)possessionvictim + ",!release");
                possessionvictim = NULL_KEY;
                possessorobject = NULL_KEY;
                if(inControl) 
                {
                    llReleaseControls();
                    llClearCameraParams();
                }
                inControl = FALSE;
                llMessageLinked(LINK_SET, M_API_SET_FILTER, "poss", (key)((string)FALSE));
            }
            else
            {
                if(inControl)
                {
                    list dets = llGetObjectDetails(possessionvictim, [OBJECT_POS, OBJECT_ROT]);
                    vector camfocus = llList2Vector(dets, 0);
                    camfocus.z = camfocus.z + 0.5;
                    rotation targetrot = llList2Rot(dets, 1);
                    vector campos = camfocus + (<-1.0, 0.0, 0.0> * targetrot) * 2.5;
                    llSetCameraParams([
                        CAMERA_ACTIVE, 1,
                        CAMERA_FOCUS, camfocus,
                        CAMERA_FOCUS_LOCKED, TRUE,
                        CAMERA_POSITION, campos,
                        CAMERA_POSITION_LOCKED, TRUE
                    ]); 
                }                
                llSetTimerEvent(0.1);
            }
        }
    }
}