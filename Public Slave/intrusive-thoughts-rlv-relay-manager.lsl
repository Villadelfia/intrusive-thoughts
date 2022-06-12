#include <IT/globals.lsl>
list rlvclients = [];
list blacklist = [];
list whitelist = [];
key handlingk = NULL_KEY;
string handlingm;
integer handlingi;
string region = "";

buildclients()
{
    integer ct = llGetInventoryNumber(INVENTORY_SCRIPT);
    integer i;
    integer handlers = 0;
    for(i = 0; i < ct; ++i)
    {
        if(contains(llToLower(llGetInventoryName(INVENTORY_SCRIPT, i)), "client")) handlers++;
    }
    while(llGetListLength(rlvclients) < handlers) rlvclients += [(key)NULL_KEY];
    while(llGetListLength(rlvclients) > handlers) rlvclients = llDeleteSubList(rlvclients, -1, -1);
}

default
{
    changed(integer change)
    {
        if(change & CHANGED_INVENTORY) buildclients();
        if(change & CHANGED_REGION)    region = "";
    }

    on_rez(integer start_param)
    {
        region = "";
    }

    link_message(integer sender_num, integer num, string str, key k)
    {
        if(num == RLV_API_CLR_SRC)       rlvclients = llListReplaceList(rlvclients, [(key)NULL_KEY], (integer)str, (integer)str);
        else if(num == RLV_API_HANDOVER) rlvclients = llListReplaceList(rlvclients, [k], (integer)str, (integer)str);
    }

    state_entry()
    {
        llListen(RLVRC, "", NULL_KEY, "");
        llListen(0, "", llGetOwner(), "");
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
        buildclients();
    }

    listen(integer c, string n, key id, string m)
    {
        if(c == RLVRC)
        {
            if(region == "NRI") return;
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
                llMessageLinked(LINK_SET, RLV_API_HANDLE_CMD, m, (key)((string)inlist));
            }
            else
            {
                // If we do not know the device, first see if we have a pending request
                // and cancel if we do. Then we check if we have an available client.
                if(handlingk != NULL_KEY) return;
                if(llListFindList(blacklist, [id]) != -1) return;
                integer available = llListFindList(rlvclients, [(key)NULL_KEY]);
                if(available == -1) return;

                rlvclients = llListReplaceList(rlvclients, [id], available, available);
                llMessageLinked(LINK_SET, RLV_API_SET_SRC, (string)available, id);
                llMessageLinked(LINK_SET, RLV_API_HANDLE_CMD, m, (key)((string)available));
            }
        }
        else if(c == MANTRA_CHANNEL)
        {
            if(m == "NRIREGION")
            {
                if(llGetCreator() != llList2Key(llGetObjectDetails(id, [OBJECT_CREATOR]), 0)) return;
                region = "NRI";
            }
            else if(m == "NRINORLV")
            {
                if(llGetCreator() != llList2Key(llGetObjectDetails(id, [OBJECT_CREATOR]), 0)) return;
                region = "";
            }
            else if(m == "CLEAR")
            {
                llSetObjectName("");
                if(llGetAgentSize(llGetOwnerKey(id)) != ZERO_VECTOR) ownersay(id, "The " + VERSION_S + " relay worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about has been cleared.", 0);
                llSetObjectName(slave_base);
                llMessageLinked(LINK_SET, RLV_API_SAFEWORD, "", NULL_KEY);
            }
            else if(m == "FORCECLEAR")
            {
                llSetObjectName("");
                if(llGetAgentSize(llGetOwnerKey(id)) != ZERO_VECTOR) ownersay(id, "The " + VERSION_S + " relay worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about has been cleared and detached.", 0);
                llSetObjectName(slave_base);
                llMessageLinked(LINK_SET, RLV_API_SAFEWORD, "", NULL_KEY);
                llOwnerSay("@clear,detachme=force");
            }
            else if(m == "RESETRELAY")
            {
                llSetObjectName("");
                if(llGetAgentSize(llGetOwnerKey(id)) != ZERO_VECTOR) ownersay(id, "The " + VERSION_S + " relay worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about has been reset and has been rebuilt.", 0);
                llSetObjectName(slave_base);
                llMessageLinked(LINK_SET, S_API_HARD_RESET, "", "");
            }
        }
        else if(c == 0)
        {
            if(region == "NRI") return;
            if(contains(llToLower(m), "((red))"))
            {
                llSetObjectName("");
                llOwnerSay("You've safeworded. You're free from all RLV devices that grabbed you.");
                llSetObjectName(slave_base);
                llMessageLinked(LINK_SET, RLV_API_SAFEWORD, "", NULL_KEY);
            }
            else if(contains(llToLower(m), "((forcered))"))
            {
                llSetObjectName("");
                llOwnerSay("You've used the hard safeword. Freeing you and detaching.");
                llSetObjectName(slave_base);
                llMessageLinked(LINK_SET, RLV_API_SAFEWORD, "", NULL_KEY);
                llOwnerSay("@clear,detachme=force");
            }
            else if(contains(llToLower(m), "((blocklist))"))
            {
                llSetObjectName("");
                llOwnerSay("Clearing the block list.");
                llSetObjectName(slave_base);
                blacklist = [];
            }
        }
    }
}
