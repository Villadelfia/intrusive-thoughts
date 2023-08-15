#include <IT/globals.lsl>
key primary = NULL_KEY;
list owners = [];
integer publicaccess = FALSE;
integer groupaccess = FALSE;

key primaryleashpoint = NULL_KEY;
list secondaryleashpoints = [];

integer leashinghandle;
integer justmoved;
vector leashtarget;
integer leasherinrange;
key leashedto;
integer awaycounter = -1;
integer llength = 2;
string prefix;
string name;
vector pcolor = <0.474, 0.057, 0.057>;
vector pcolordefault = <0.474, 0.057, 0.057>;
vector pscale = <0.04, 0.04, 1.0>;
float prate = 0.0;
vector paccel = <0.0, 0.0, -1.0>;
string ptex = "cdb7025a-9283-17d9-8d20-cee010f36e90";

scanLeashSettings()
{
    list uuids = llGetAttachedList(llGetOwner());
    integer n = llGetListLength(uuids);
    list data;
    while(~--n)
    {
        data = llGetObjectDetails(llList2Key(uuids, n), [OBJECT_DESC]);
        if(startswith((string)data[0], "itleash"))
        {
            pcolor = (vector)llDeleteSubString((string)data[0], 0, llStringLength("itleash"));
            jump d;
        }
    }
    pcolor = pcolordefault;
    @d;

    pscale = <0.04, 0.04, 1.0>;
    prate = 0.0;
    paccel = <0.0, 0.0, -1.0>;
    ptex = "cdb7025a-9283-17d9-8d20-cee010f36e90";
    n = llGetInventoryNumber(INVENTORY_NOTECARD);
    while(~--n)
    {
        string nm = llGetInventoryName(INVENTORY_NOTECARD, n);
        if(startswith(nm, "~PSYS_PART_START_COLOR")) pcolor = (vector)llList2String(llParseString2List(nm, ["="], []), 1);
        if(startswith(nm, "~PSYS_PART_START_SCALE")) pscale = (vector)llList2String(llParseString2List(nm, ["="], []), 1);
        if(startswith(nm, "~PSYS_SRC_BURST_RATE")) prate = (float)llList2String(llParseString2List(nm, ["="], []), 1);
        if(startswith(nm, "~PSYS_SRC_ACCEL")) paccel = (vector)llList2String(llParseString2List(nm, ["="], []), 1);
        if(startswith(nm, "~PSYS_SRC_TEXTURE")) ptex = llList2String(llParseString2List(nm, ["="], []), 1);
    }
}

particles(key k)
{
    if(k == NULL_KEY)
    {
        llParticleSystem([]);
    }
    else
    {
        scanLeashSettings();
        llParticleSystem([
            PSYS_PART_FLAGS, PSYS_PART_FOLLOW_VELOCITY_MASK | PSYS_PART_TARGET_POS_MASK | PSYS_PART_FOLLOW_SRC_MASK | PSYS_PART_RIBBON_MASK,
            PSYS_PART_MAX_AGE, 3.5,
            PSYS_PART_START_COLOR, pcolor,
            PSYS_PART_START_SCALE, pscale,
            PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_DROP,
            PSYS_SRC_BURST_RATE, prate,
            PSYS_SRC_ACCEL, paccel,
            PSYS_SRC_BURST_PART_COUNT, 1,
            PSYS_SRC_TARGET_KEY, k,
            PSYS_SRC_MAX_AGE, 0,
            PSYS_SRC_TEXTURE, ptex
        ]);
    }
}

checkSetup()
{
    if(leasherinrange == TRUE && leashedto != NULL_KEY) llOwnerSay("@fly=n,tplm=n,tplure=n,tploc=n,tplure:" + (string)llGetOwnerKey(leashedto) + "=add");
    else                                                llOwnerSay("@fly=y,tplm=y,tplure=y,tploc=y");
}

leash(key target)
{
    // Announce leashing.
    llRegionSayTo(target, LEASH_CHANNEL, "leashed");
    leashedto = target;

    // Do particles and instantiate timer.
    particles(target);
    llSetTimerEvent(3.0);

    // Get position of target. Fallback to wearer if first check fails.
    leashtarget = llList2Vector(llGetObjectDetails(leashedto, [OBJECT_POS]), 0);
    if(leashtarget == ZERO_VECTOR) leashtarget = llList2Vector(llGetObjectDetails(llGetOwnerKey(leashedto), [OBJECT_POS]), 0);

    // Move to the new leashing target.
    llTargetRemove(leashinghandle);
    llStopMoveToTarget();
    leashinghandle = llTarget(leashtarget, (float)llength);
    if(leashtarget != ZERO_VECTOR) llMoveToTarget(leashtarget, 0.7);
    leasherinrange = TRUE;

    // Update setup.
    checkSetup();
}

unleash()
{
    // Announce unleash.
    llRegionSayTo(leashedto, LEASH_CHANNEL, "unleashed");

    // Stop events.
    llTargetRemove(leashinghandle);
    llStopMoveToTarget();
    particles(NULL_KEY);
    leashedto = NULL_KEY;
    llSetTimerEvent(0.0);
    leasherinrange = FALSE;

    // Update setup.
    checkSetup();
}

yankTo(key k)
{
    llMoveToTarget(llList2Vector(llGetObjectDetails(k, [OBJECT_POS]), 0), 0.5);
    if(llGetAgentInfo(llGetOwner()) & AGENT_SITTING) llOwnerSay("@unsit=force");
    llSleep(2.0);
    llStopMoveToTarget();
}

default
{
    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == S_API_STARTED)
        {
            unleash();
        }
        else if(num == S_API_OWNERS)
        {
            owners = [];
            secondaryleashpoints = [];
            list new = llParseString2List(str, [","], []);
            integer n = llGetListLength(new);
            while(~--n)
            {
                owners += [(key)llList2String(new, n)];
                secondaryleashpoints += [NULL_KEY];
            }
            primary = id;
        }
        else if(num == S_API_OTHER_ACCESS)
        {
            publicaccess = (integer)str;
            groupaccess = (integer)((string)id);
        }
    }

    state_entry()
    {
        prefix = llGetSubString(llGetUsername(llGetOwner()), 0, 1);
        name = llGetDisplayName(llGetOwner());
        llListen(COMMAND_CHANNEL, "", NULL_KEY, "");
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
        unleash();
    }

    listen(integer c, string n, key k, string m)
    {
#ifndef PUBLIC_SLAVE
        if(!isowner(k)) return;
#endif
        if(c == MANTRA_CHANNEL)
        {
            if(startswith(m, "leashto"))
            {
                m = llDeleteSubString(m, 0, llStringLength("leashto"));
                leash((key)m);
            }
            else if(m == "unleash")
            {
                unleash();
            }
            else if(m == "yank")
            {
                if(leashedto) yankTo(leashedto);
            }
            else if(m == "leashpoint")
            {
#ifndef PUBLIC_SLAVE
                integer c = FALSE;
                if(llGetOwnerKey(k) == primary)
                {
                    if(k != primaryleashpoint)
                    {
                        primaryleashpoint = k;
                        c = TRUE;
                    }
                }
                else
                {
                    integer i = llListFindList(owners, [llGetOwnerKey(k)]);
                    if(llList2Key(secondaryleashpoints, i) != k)
                    {
                        secondaryleashpoints = llListReplaceList(secondaryleashpoints, [k], i, i);
                        c = TRUE;
                    }
                }

                if(llGetOwnerKey(leashedto) == llGetOwnerKey(k) && c == TRUE)
                {
                    unleash();
                    leash(k);
                }
#else
                if(llGetOwnerKey(leashedto) == llGetOwnerKey(k) && primaryleashpoint != k)
                {
                    primaryleashpoint = k;
                    unleash();
                    leash(k);
                }
#endif
            }
        }
        else if(c == COMMAND_CHANNEL)
        {
            if(startswith(m, "#") && k == llGetOwner())       return;
            if(startswith(m, prefix))                         m = llDeleteSubString(m, 0, 1);
            else if(startswith(m, "*") || startswith(m, "#")) m = llDeleteSubString(m, 0, 0);
            else                                              return;
            if(llToLower(m) == "leash")
            {
                llSetObjectName("");
                llOwnerSay("Your leash has been grabbed by secondlife:///app/agent/" + (string)llGetOwnerKey(k) + "/about.");
                ownersay(k, "You've grabbed the leash of secondlife:///app/agent/" + (string)llGetOwner() + "/about.", 0);
                llSetObjectName(slave_base);
#ifndef PUBLIC_SLAVE
                if(llGetOwnerKey(k) == primary)
                {
                    if(primaryleashpoint)
                    {
                        vector handlepos = llList2Vector(llGetObjectDetails(primaryleashpoint, [OBJECT_POS]), 0);
                        if(handlepos == ZERO_VECTOR)
                        {
                            primaryleashpoint = NULL_KEY;
                        }
                        else
                        {
                            leash(primaryleashpoint);
                            return;
                        }
                    }
                }
                else
                {
                    integer i = llListFindList(owners, [llGetOwnerKey(k)]);
                    if(llList2Key(secondaryleashpoints, i))
                    {
                        vector handlepos = llList2Vector(llGetObjectDetails(llList2Key(secondaryleashpoints, i), [OBJECT_POS]), 0);
                        if(handlepos == ZERO_VECTOR)
                        {
                            secondaryleashpoints = llListReplaceList(secondaryleashpoints, [NULL_KEY], i, i);
                        }
                        else
                        {
                            leash(llList2Key(secondaryleashpoints, i));
                            return;
                        }
                    }
                }
#else
                primaryleashpoint = NULL_KEY;
#endif
                leash(llGetOwnerKey(k));
            }
            else if(llToLower(m) == "unleash")
            {
                unleash();
                llSetObjectName("");
                llOwnerSay("Your leash has been released by secondlife:///app/agent/" + (string)llGetOwnerKey(k) + "/about.");
                ownersay(k, "You've released the leash of secondlife:///app/agent/" + (string)llGetOwner() + "/about.", 0);
                llSetObjectName(slave_base);
            }
            else if(llToLower(m) == "yank")
            {
                if(leashedto) yankTo(leashedto);
            }
            else if(startswith(llToLower(m), "leashlength"))
            {
                integer leashlength = (integer)llDeleteSubString(m, 0, llStringLength("leashlength"));
                if(leashlength < 1) leashlength = 1;
                if(llength != leashlength)
                {
                    llength = leashlength;
                    if(leashedto)
                    {
                        key k = leashedto;
                        unleash();
                        leash(k);
                    }
                }
            }
        }
    }

    at_target(integer num, vector tar, vector me)
    {
        llStopMoveToTarget();
        llTargetRemove(leashinghandle);
        leashtarget = llList2Vector(llGetObjectDetails(leashedto, [OBJECT_POS]), 0);
        if(leashtarget == ZERO_VECTOR) leashtarget = llList2Vector(llGetObjectDetails(llGetOwnerKey(leashedto), [OBJECT_POS]), 0);
        leashinghandle = llTarget(leashtarget, (float)llength);
        if(justmoved)
        {
            vector p = leashtarget - llGetPos();
            float angle = llAtan2(p.x, p.y);
            llOwnerSay("@setrot:" + (string)(angle) + "=force");
            justmoved = 0;
        }
    }

    not_at_target()
    {
        justmoved = 1;
        if(leashedto)
        {
            vector newpos = llList2Vector(llGetObjectDetails(leashedto, [OBJECT_POS]), 0);
            if(newpos == ZERO_VECTOR) newpos = llList2Vector(llGetObjectDetails(llGetOwnerKey(leashedto), [OBJECT_POS]), 0);
            if(leashtarget != newpos)
            {
                llTargetRemove(leashinghandle);
                leashtarget = newpos;
                leashinghandle = llTarget(leashtarget, (float)llength);
            }
            if(leashtarget != ZERO_VECTOR)
            {
                llMoveToTarget(leashtarget, 1.0);
            }
            else
            {
                llStopMoveToTarget();
                llTargetRemove(leashinghandle);
            }
        }
        else
        {
            llStopMoveToTarget();
            llTargetRemove(leashinghandle);
            unleash();
        }
    }

    timer()
    {
        // Get position of our leash target.
        vector leashedtopos = llList2Vector(llGetObjectDetails(leashedto, [OBJECT_POS]), 0);
        if(leashedtopos == ZERO_VECTOR) leashedtopos = llList2Vector(llGetObjectDetails(llGetOwnerKey(leashedto), [OBJECT_POS]), 0);

        // Is that position within our range?
        integer isinsim = (leashedtopos != ZERO_VECTOR && llVecDist(llGetPos(), leashedtopos) <= 255);

        // If it's within our range...
        if(isinsim && llVecDist(llGetPos(), leashedtopos) < (60 + llength))
        {
            // And we lost our leash earlier...
            if(!leasherinrange)
            {
                // Re-establish the leash.
                leasherinrange = TRUE;
                particles(leashedto);
                llTargetRemove(leashinghandle);
                llStopMoveToTarget();
                leashinghandle = llTarget(leashtarget, (float)llength);
                if(leashtarget != ZERO_VECTOR) llMoveToTarget(leashtarget, 0.7);
                checkSetup();
            }
        }
        else
        {
            // If it's not and this is our first iteration...
            if(leasherinrange)
            {
                // Disable the leash.
                leasherinrange = FALSE;
                llTargetRemove(leashinghandle);
                llStopMoveToTarget();
                particles(NULL_KEY);
                checkSetup();
            }
            else
            {
                // On the second iteration remove the leash entirely.
                unleash();
                llSetObjectName("");
                llOwnerSay("Your leash has been released.");
                llSetObjectName(slave_base);
            }
        }
    }
}
