#include <IT/globals.lsl>
key owner;
list rlvclients = [];
list blacklist = [];
list whitelist = [];
key handlingk = NULL_KEY;
string handlingm;
integer handlingi;

buildclients()
{
    integer i = 0;
    do
    {
        rlvclients += [(key)NULL_KEY];
        i++;
    }
    while(llGetInventoryType(RLVSCRIPT + " " + (string)i) == INVENTORY_SCRIPT);
    llOwnerSay("RLV relay online with up to " + (string)i + " devices supported.");
}

default
{
    changed(integer change)
    {
        if(change & CHANGED_OWNER) llResetScript();
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
            list args = llParseStringKeepNulls(m, [","], []);
            if(llGetListLength(args)!=3) return;            
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

                // If the device is owned by the owner or it is in the whitelist, allow it.
                if(llGetOwnerKey(id) == owner || llListFindList(whitelist, [id]) != -1)
                {
                    rlvclients = llListReplaceList(rlvclients, [id], available, available);
                    llMessageLinked(LINK_SET, API_RLV_SET_SRC, (string)available, id);
                    llMessageLinked(LINK_SET, API_RLV_HANDLE_CMD, m, (key)((string)available));
                }
                else
                {
                    // If not, we ask the owner for permission if they're available, or the
                    // wearer if they're not.
                    key target = llGetOwner();
                    if(llGetAgentSize(owner) != ZERO_VECTOR) target = owner;
                    handlingk = id;
                    handlingm = m;
                    handlingi = available;
                    llDialog(target, "The device '" + n + "' owned by secondlife:///app/agent/" + (string)llGetOwnerKey(id) + "/about wants to access the relay of secondlife:///app/agent/" + (string)llGetOwner() + "/about, will you allow this?\n \n(Timeout in 15 seconds.)", ["ALLOW", "DENY", "BLOCK"], MANTRA_CHANNEL);
                    llSetTimerEvent(15.0);
                }
            }
        }
        else if(c == MANTRA_CHANNEL)
        {
            if(llGetOwnerKey(id) != owner) return;
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
            else if(m == "CLEAR")
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
    }
}