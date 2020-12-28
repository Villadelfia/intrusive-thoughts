#include <IT/globals.lsl>
key owner;
list rlvclients = [];
list blacklist = [];
list whitelist = [];
key handlingk = NULL_KEY;
string handlingm;
integer handlingi;
integer templisten = -1;
integer tempchannel;

makelisten(key who)
{
    if(templisten != -1) llListenRemove(templisten);
    tempchannel = ((integer)("0x"+llGetSubString((string)llGenerateKey(),-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFF;
    templisten = llListen(tempchannel, "", who, "");
}

clearlisten()
{
    if(templisten != -1) llListenRemove(templisten);
    templisten = -1;
}

buildclients()
{
    integer ct = llGetInventoryNumber(INVENTORY_SCRIPT);
    integer i;
    integer handlers = 0;
    for(i = 0; i < ct; ++i)
    {
        if(contains(llToLower(llGetInventoryName(INVENTORY_SCRIPT, i)), "client")) handlers++;
    }

    integer change = FALSE;
    while(llGetListLength(rlvclients) < handlers) 
    {
        rlvclients += [(key)NULL_KEY];
        change = TRUE;
    }

    while(llGetListLength(rlvclients) > handlers)
    {
        rlvclients = llDeleteSubList(rlvclients, -1, -1);
        change = TRUE;
    }

    if(change && rlvclients != []) llOwnerSay("RLV relay online with up to " + (string)handlers + " devices supported.");
    if(rlvclients == [])           llOwnerSay("RLV relay offline. Add client scripts to my inventory.");
}

default
{
    changed(integer change)
    {
        if(change & CHANGED_OWNER) llResetScript();
        if(change & CHANGED_INVENTORY) buildclients();
    }

    state_entry()
    {
        owner = llList2Key(llGetObjectDetails(llGetKey(), [OBJECT_LAST_OWNER_ID]), 0);
        llListen(RLVRC, "", NULL_KEY, "");
        llListen(0, "", llGetOwner(), "");
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
        buildclients();
    }

    listen(integer c, string n, key id, string m)
    {
        if(c == RLVRC)
        {
            if(rlvclients == []) return;
            list args = llParseStringKeepNulls(m, [","], []);

            // We discard if the message is too short.
            if(llGetListLength(args)!=3) return;
            string ident = llList2String(args, 0);
            string target = llList2String(args, 1);
            string command = llList2String(args, 2);
            string firstcommand = llList2String(llParseString2List(command, ["|"], []), 0);
            string behavior = llList2String(llParseString2List(firstcommand, ["="], []), 0);
            string value = llList2String(llParseString2List(firstcommand, ["="], []), 1);

            // Or if the target is not us.
            if(target != (string)llGetOwner() && target != "ffffffff-ffff-ffff-ffff-ffffffffffff") return;

            integer inlist = llListFindList(rlvclients, [id]);
            if(inlist != -1)
            {
                // If we know the device, we just pass the message through.
                llMessageLinked(LINK_SET, API_RLV_HANDLE_CMD, m, (key)((string)inlist));
            }
            else
            {
                // If we do not know the device, first see if we have a pending request
                // and cancel if we do. Then we check if we have an available client.
                if(handlingk != NULL_KEY) return;
                if(llListFindList(blacklist, [id]) != -1) return;
                integer available = llListFindList(rlvclients, [(key)NULL_KEY]);
                if(available == -1) return;

                // If the device is owned by the owner, by us, or it is in the whitelist, allow it.
                if(llGetOwnerKey(id) == owner || llGetOwnerKey(id) == llGetOwner() || llListFindList(whitelist, [id]) != -1)
                {
                    rlvclients = llListReplaceList(rlvclients, [id], available, available);
                    llMessageLinked(LINK_SET, API_RLV_SET_SRC, (string)available, id);
                    llMessageLinked(LINK_SET, API_RLV_HANDLE_CMD, m, (key)((string)available));
                }
                else
                {
                    // If it's not owned by the owner or us, we check if it's one of the allowed commands.
                    if(command == "!version") llRegionSayTo(id, RLVRC, ident+","+(string)id+",!version,1100");
                    else if(command == "!implversion") llRegionSayTo(id, RLVRC, ident+","+(string)id+",!implversion,ORG=0004/Hana's Relay");
                    else if(command == "!x-orgversions") llRegionSayTo(id, RLVRC, ident+","+(string)id+",!x-orgversions,ORG=0004");
                    else if((behavior == "@version" || behavior == "@versionnew" || behavior == "@versionnum" || behavior == "@versionnumbl") && command == behavior + "=" + value) llOwnerSay(command);

                    // If not, we ask the owner for permission if they're available, or the
                    // wearer if they're not.
                    else
                    {
                        key target = llGetOwner();
                        if(llGetAgentSize(owner) != ZERO_VECTOR) target = owner;
                        handlingk = id;
                        handlingm = m;
                        handlingi = available;
                        makelisten(target);
                        llDialog(target, "The device '" + n + "' owned by secondlife:///app/agent/" + (string)llGetOwnerKey(id) + "/about wants to access the relay of secondlife:///app/agent/" + (string)llGetOwner() + "/about, will you allow this?\n \n(Timeout in 15 seconds.)", ["ALLOW", "DENY", "BLOCK"], tempchannel);
                        llSetTimerEvent(15.0);
                    }
                }
            }
        }
        else if(c == tempchannel)
        {
            if(handlingk == NULL_KEY) return;
            if(llGetOwnerKey(id) != owner && llGetOwnerKey(id) != llGetOwner()) return;
            if(m == "ALLOW")
            {
                llSetTimerEvent(0.0);
                if(llListFindList(whitelist, [handlingk]) == -1) whitelist += [handlingk];
                if(llGetListLength(whitelist) > 10) whitelist = llDeleteSubList(whitelist, 1, -1);
                rlvclients = llListReplaceList(rlvclients, [handlingk], handlingi, handlingi);
                llMessageLinked(LINK_SET, API_RLV_SET_SRC, (string)handlingi, handlingk);
                llMessageLinked(LINK_SET, API_RLV_HANDLE_CMD, handlingm, (key)((string)handlingi));
                handlingk = NULL_KEY;
            }
            else if(m == "DENY")
            {
                llOwnerSay("RLV relay request denied.");
                llSetTimerEvent(0.0);
                handlingk = NULL_KEY;
            }
            else if(m == "BLOCK")
            {
                llOwnerSay("RLV relay request blocked. You can type ((blocklist)) to clear the block list.");
                llSetTimerEvent(0.0);
                if(llListFindList(blacklist, [handlingk]) == -1) blacklist += [handlingk];
                handlingk = NULL_KEY;
            }
        }
        else if(c == MANTRA_CHANNEL)
        {
            if(llGetOwnerKey(id) != owner) return;
            if(m == "CLEAR")
            {
                if(llGetAgentSize(owner) != ZERO_VECTOR) llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "The " + VERSION_S + " relay worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about has been cleared.");
                llMessageLinked(LINK_SET, API_RLV_SAFEWORD, "", NULL_KEY);
            }
            else if(m == "FORCECLEAR")    
            {
                if(llGetAgentSize(owner) != ZERO_VECTOR) llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "The " + VERSION_S + " relay worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about has been cleared and detached.");
                llMessageLinked(LINK_SET, API_RLV_SAFEWORD, "", NULL_KEY);
                llOwnerSay("@clear,detachme=force");
            }
            else if(m == "RESETRELAY")    
            {
                if(llGetAgentSize(owner) != ZERO_VECTOR) llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "The " + VERSION_S + " relay worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about has been reset and has been rebuilt.");
                llResetScript();
            }
        }
        else if(c == 0)
        {
            if(contains(llToLower(m), "((red))"))
            {
                llOwnerSay("You've safeworded. You're free from all RLV devices that grabbed you.");
                llMessageLinked(LINK_SET, API_RLV_SAFEWORD, "", NULL_KEY);
                string oldn = llGetObjectName();
                llSetObjectName("");
                if(llGetAgentSize(owner) != ZERO_VECTOR) llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "The " + VERSION_S + " relay has been safeworded by secondlife:///app/agent/" + (string)llGetOwner() + "/about at " + slurl() + ".");
                else
                {
                    llSetObjectName(oldn);
                    llInstantMessage(owner, "The " + VERSION_S + " relay has been safeworded by secondlife:///app/agent/" + (string)llGetOwner() + "/about at " + slurl() + ".");
                }
                llSetObjectName(oldn);
            }
            else if(contains(llToLower(m), "((forcered))"))
            {
                llOwnerSay("You've used the hard safeword. Freeing you and detaching.");
                llMessageLinked(LINK_SET, API_RLV_SAFEWORD, "", NULL_KEY);
                string oldn = llGetObjectName();
                llSetObjectName("");
                if(llGetAgentSize(owner) != ZERO_VECTOR) llRegionSayTo(owner, HUD_SPEAK_CHANNEL, "The " + VERSION_S + " been detached by secondlife:///app/agent/" + (string)llGetOwner() + "/about at " + slurl() + " because of safeword.");
                else
                {
                    llSetObjectName(oldn);
                    llInstantMessage(owner, "The " + VERSION_S + " been detached by secondlife:///app/agent/" + (string)llGetOwner() + "/about at " + slurl() + " because of safeword.");
                }
                llSetObjectName(oldn);
                llOwnerSay("@clear,detachme=force");
            }
            else if(contains(llToLower(m), "((blocklist))"))
            {
                llOwnerSay("Clearing the block list.");
                blacklist = [];
            }
        }
    }

    link_message(integer sender_num, integer num, string str, key k)
    {
        if(num == API_RLV_CLR_SRC) rlvclients = llListReplaceList(rlvclients, [(key)NULL_KEY], (integer)str, (integer)str);
    }

    timer()
    {
        llSetTimerEvent(0.0);
        handlingk = NULL_KEY;
        clearlisten();
    }
}