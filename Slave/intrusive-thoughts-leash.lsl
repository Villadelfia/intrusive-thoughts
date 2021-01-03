#include <IT/globals.lsl>
key primary = NULL_KEY;
list owners = [];

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

particles(key k)
{
    if(k == NULL_KEY)
    {
        llParticleSystem([]);
    }
    else
    {
        llParticleSystem([
            PSYS_PART_FLAGS, PSYS_PART_FOLLOW_VELOCITY_MASK | PSYS_PART_TARGET_POS_MASK | PSYS_PART_FOLLOW_SRC_MASK | PSYS_PART_RIBBON_MASK,
            PSYS_PART_MAX_AGE, 3.5,
            PSYS_PART_START_COLOR, <0.474, 0.057, 0.057>,
            PSYS_PART_START_SCALE, <0.04,0.04,1.0>,
            PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_DROP,
            PSYS_SRC_BURST_RATE, 0.0,
            PSYS_SRC_ACCEL, <0.0,0.0,-1.0>,
            PSYS_SRC_BURST_PART_COUNT, 1,
            PSYS_SRC_TARGET_KEY, k,
            PSYS_SRC_MAX_AGE, 0,
            PSYS_SRC_TEXTURE, "cdb7025a-9283-17d9-8d20-cee010f36e90"
        ]);
    }
}

checkSetup() 
{
    if(leasherinrange != FALSE && leashedto != NULL_KEY)
    {
        llOwnerSay("@fly=n,tplm=n,tplure=n,tploc=n,tplure:" + (string)leashedto + "=add");
    }
    else
    {
        llOwnerSay("@fly=y,tplm=y,tplure=y,tploc=y");
    }
}

leash(key target) 
{
    llRegionSayTo(target, LEASH_CHANNEL, "leashed");

    leashedto = target;

    particles(target);

    llSetTimerEvent(3.0);
    
    leashtarget = llList2Vector(llGetObjectDetails(leashedto, [OBJECT_POS]), 0);
    llTargetRemove(leashinghandle);
    llStopMoveToTarget();
    leashinghandle = llTarget(leashtarget, (float)llength);
    if(leashtarget != ZERO_VECTOR)
    {
        llMoveToTarget(leashtarget, 0.7);
    }    
    leasherinrange=TRUE;
    checkSetup();
}

unleash()
{
    llRegionSayTo(leashedto, LEASH_CHANNEL, "unleashed");

    llTargetRemove(leashinghandle);
    llStopMoveToTarget();
    particles(NULL_KEY);
    leashedto = NULL_KEY;
    llSetTimerEvent(0.0);
    leasherinrange = FALSE;
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
        if(!isowner(k)) return;
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
                leash(llGetOwnerKey(k));
                llOwnerSay("Your leash has been grabbed by secondlife:///app/agent/" + (string)llGetOwnerKey(k) + "/about.");
                ownersay(k, "You've grabbed the leash of secondlife:///app/agent/" + (string)llGetOwner() + "/about.");
            }
            else if(llToLower(m) == "unleash")
            {
                unleash();
                llOwnerSay("Your leash has been released by secondlife:///app/agent/" + (string)llGetOwnerKey(k) + "/about.");
                ownersay(k, "You've released the leash of secondlife:///app/agent/" + (string)llGetOwner() + "/about.");
            }
            else if(llToLower(m) == "yank")
            {
                if(leashedto) yankTo(leashedto);
            }
            else if(startswith(llToLower(m), "leashlength"))
            {
                integer leashlength = (integer)llDeleteSubString(m, 0, llStringLength("leashlength"));
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
        vector leashedtopos = llList2Vector(llGetObjectDetails(leashedto, [OBJECT_POS]), 0);
        integer isinsim = TRUE;
        if(leashedtopos == ZERO_VECTOR || llVecDist(llGetPos(), leashedtopos) > 255) isinsim = FALSE;
        
        if(isinsim && llVecDist(llGetPos(), leashedtopos) < (60 + llength)) 
        {
            if(!leasherinrange) 
            {
                leasherinrange = TRUE;
                llTargetRemove(leashinghandle);
                leashtarget = leashedtopos;
                leashinghandle = llTarget(leashtarget, (float)llength);
                if(leashtarget != ZERO_VECTOR) llMoveToTarget(leashtarget, 0.8);
                checkSetup();
            }
        } 
        else 
        {
            if(leasherinrange) 
            {
                llTargetRemove(leashinghandle);
                llStopMoveToTarget();
                particles(NULL_KEY);
                leasherinrange = FALSE;
                checkSetup();
            }
            else
            {
                unleash();
            }
        }
    }
}