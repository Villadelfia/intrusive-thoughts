#include <IT/globals.lsl>
integer leashinghandle;
integer justmoved;
vector leashtarget;
integer leasherinrange;
key leashedto;
key owner = NULL_KEY;
key leashpoint = NULL_KEY;
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
        if(num == S_API_RESET && id == llGetOwner()) llResetScript();
    }

    changed(integer change)
    {
        if(change & CHANGED_OWNER) llResetScript();
    }

    attach(key id)
    {
        unleash();
    }

    state_entry()
    {
        owner = llList2Key(llGetObjectDetails(llGetKey(), [OBJECT_LAST_OWNER_ID]), 0);
        prefix = llGetSubString(llGetUsername(llGetOwner()), 0, 1);
        name = llGetDisplayName(llGetOwner());
        llListen(1, "", owner, "");
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
        unleash();
    }

    listen(integer c, string n, key k, string m)
    {
        if(k != owner && llGetOwnerKey(k) != owner) return;
        if(c == MANTRA_CHANNEL)
        {
            if(m == "END")
            {
                llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "[" + llGetScriptName() + "]: " + (string)(llGetFreeMemory() / 1024.0) + "kb free.");
            }
            else if(startswith(m, "leashto"))
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
                if(k != leashpoint) 
                {
                    leashpoint = k;
                    if(leashedto) 
                    {
                        unleash();
                        leash(leashpoint);
                    }
                }
            }
        }
        else if(c == 1)
        {
            if(startswith(m, "#") && k == llGetOwner())       return;
            if(startswith(m, prefix))                         m = llDeleteSubString(m, 0, 1);
            else if(startswith(m, "*") || startswith(m, "#")) m = llDeleteSubString(m, 0, 0);
            else                                              return;
            if(llToLower(m) == "leash")
            {   
                if(leashpoint != NULL_KEY)
                {
                    if(llList2Vector(llGetObjectDetails(leashpoint, [OBJECT_POS]), 0) == ZERO_VECTOR)
                    {
                        leashpoint = NULL_KEY;
                        leash(owner);
                    }
                    else
                    {
                        leash(leashpoint);
                    }
                }
                else
                {
                    leash(owner);
                }
            }
            else if(llToLower(m) == "unleash")
            {
                unleash();
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