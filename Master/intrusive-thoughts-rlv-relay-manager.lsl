#include <IT/globals.lsl>

key owner;
list rlvclients = [];
list blacklist = [];
list whitelist = [];
list filters = [];
integer responses = 0;
list restrictions = [];
key handlingk = NULL_KEY;
string handlingm;
integer handlingi;
integer templisten = -1;
integer tempchannel = DEBUG_CHANNEL;
integer enabled = FALSE;
integer configured = FALSE;
integer relaymode = 0;
list allowed = [];

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
    while(llGetListLength(rlvclients) < handlers) rlvclients += [(key)NULL_KEY];
    while(llGetListLength(rlvclients) > handlers) rlvclients = llDeleteSubList(rlvclients, -1, -1);
    llMessageLinked(LINK_SET, RLV_API_SET_FILTERS, llDumpList2String(filters, "\n"), (key)"");
}

integer hasrestrictions()
{
    integer n = llGetListLength(rlvclients);
    while(~--n) if(llList2Key(rlvclients, n) != NULL_KEY) return TRUE;
    return FALSE;
}

givemenu()
{
    llSetObjectName("");
    llOwnerSay("RLV relay options:");

    // General options.
    llOwnerSay(" ");
    if(enabled)
    {
        llOwnerSay("Your RLV relay is currently enabled. Click [secondlife:///app/chat/1/rlvoff here] to turn off your RLV relay, clearing any and all restrictions.");
    }
    else
    {
        llOwnerSay("Your RLV relay is currently disabled. Click [secondlife:///app/chat/1/rlvon here] to turn on your RLV relay.");
    }

    // Commands.
    llOwnerSay(" ");
    llOwnerSay("/1rlvrun <command> — Run an RLV command on yourself. This will bypass any filters you have set up.");
    llOwnerSay("[secondlife:///app/chat/1/rlvmenu /1rlvmenu] — Show this menu.");

    // Restrictions.
    integer dev = -1;
    integer i;
    integer l = llGetListLength(restrictions);

    llOwnerSay(" ");
    llOwnerSay("Active restrictions:");
    if(restrictions != [])
    {

        for(i = 0; i < l; i += 3)
        {
            integer newdev = (integer)llList2String(restrictions, i);
            string oname = llList2String(restrictions, i+1);
            string res = llList2String(restrictions, i+2);
            if(newdev != dev)
            {
                dev = newdev;
                llOwnerSay("Device " + (string)(dev) + ": " + oname);
            }
            llOwnerSay(" - [secondlife:///app/chat/1/relaycmd%20" + (string)dev + "%20" + llEscapeURL(res + "=y") + " " + res + "]");
        }

        llOwnerSay(" ");
        llOwnerSay("Click any of the above links to remove that restriction.");
    }
    else
    {
        llOwnerSay(" - None");
    }

    // Filters.
    llOwnerSay(" ");
    llOwnerSay("RLV filters:");
    if(filters != [])
    {
        l = llGetListLength(filters);
        for(i = 0; i < l; ++i) llOwnerSay(" - [secondlife:///app/chat/1/filterdel%20" + (string)i + " " + llList2String(filters, i) + "]");

        llOwnerSay(" ");
        llOwnerSay("Click any of the above links to remove that filter.");
    }
    else
    {
        llOwnerSay(" - None");
        llOwnerSay(" ");
    }

    llOwnerSay("Type \"/1filteradd <filter>\" to add an RLV command filter.");
    llSetObjectName(master_base);
}

default
{
    changed(integer change)
    {
        if(change & CHANGED_INVENTORY) buildclients();
    }

    state_entry()
    {
        owner = llGetOwner();
        llListen(RLVRC, "", NULL_KEY, "");
        llListen(0, "", llGetOwner(), "");
        llListen(1, "", llGetOwner(), "");
        buildclients();
    }

    listen(integer c, string n, key id, string m)
    {
        if(c == 1)
        {
            if(startswith(llToLower(m), "filteradd"))
            {
                m = llDeleteSubString(m, 0, llStringLength("filteradd"));
                if(llGetSubString(m, 0, 0) == "@") m = llDeleteSubString(m, 0, 0);
                m = llToLower(m);
                m = llDumpList2String(llParseStringKeepNulls(m, [" "], []), "");
                llSetObjectName("");
                llOwnerSay("Adding RLV command filter \"" + m + "\".");
                llSetObjectName(master_base);
                filters += [m];
                llMessageLinked(LINK_SET, RLV_API_SET_FILTERS, llDumpList2String(filters, "\n"), (key)"");
            }
            else if(startswith(llToLower(m), "filterdel"))
            {
                integer which = (integer)llDeleteSubString(m, 0, llStringLength("filterdel"));
                llSetObjectName("");
                llOwnerSay("Removing RLV command filter \"" + llList2String(filters, which) + "\".");
                llSetObjectName(master_base);
                filters = llDeleteSubList(filters, which, which);
                llMessageLinked(LINK_SET, RLV_API_SET_FILTERS, llDumpList2String(filters, "\n"), (key)"");
            }
            else if(startswith(llToLower(m), "rlvrun"))
            {
                m = llDeleteSubString(m, 0, llStringLength("rlvrun"));
                if(!startswith(m, "@")) m = "@" + m;
                llOwnerSay(m);
            }
            else if(llToLower(m) == "rlvmenu")
            {
                responses = 0;
                restrictions = [];
                llMessageLinked(LINK_SET, RLV_API_GET_RESTRICTIONS, "", (key)"");
            }
            else if(llToLower(m) == "rlvoff")
            {
                if(enabled)
                {
                    enabled = FALSE;
                    llMessageLinked(LINK_SET, M_API_SET_FILTER, "relay", (key)((string)enabled));
                    llSetObjectName("");
                    llOwnerSay("Your RLV relay has been turned off. In addition, you have been freed from all RLV devices that may have had ongoing restrictions on you.");
                    llSetObjectName(master_base);
                    llMessageLinked(LINK_SET, RLV_API_SAFEWORD, "", NULL_KEY);
                }
            }
            else if(llToLower(m) == "rlvon")
            {
                if(!enabled)
                {
                    enabled = TRUE;
                    llMessageLinked(LINK_SET, M_API_SET_FILTER, "relay", (key)((string)enabled));
                    llSetObjectName("");
                    llOwnerSay("Your RLV relay has been turned on.");
                    llSetObjectName(master_base);
                    llOwnerSay("@touchme=add");
                }
            }

            if(hasrestrictions() == FALSE || restrictions == []) return;
            //if(nridisable) return;
            if(!enabled) return;

            if(startswith(llToLower(m), "relaycmd"))
            {
                list args = llParseString2List(llDeleteSubString(m, 0, llStringLength("relaycmd")), [" "], []);
                integer relayid = (integer)llList2String(args, 0);
                string cmd = llList2String(args, 1);
                llSetObjectName("");
                llOwnerSay("Disabling restriction \"" + llDeleteSubString(cmd, -2, -1) + "\" on device " + (string)relayid + ".");
                llSetObjectName(master_base);
                llMessageLinked(LINK_SET, RLV_API_HANDLE_CMD_QUIET, "override," + (string)llGetOwner() + ",@" + cmd, (key)((string)relayid));
            }

            return;
        }

        if(!enabled) return;
        if(c == RLVRC)
        {
            if(rlvclients == []) return;
            list args = llParseStringKeepNulls(m, [","], []);

            // Re-assert the exceptions.
            llOwnerSay("@touchme=add");

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

                // Check if allowed.
                if(relaymode == 2 ||                                     // Auto mode?
                   llGetOwnerKey(id) == owner ||                         // Owned by the owner?
                   llListFindList(whitelist, [id]) != -1 ||              // On the whitelist?
                   llListFindList(allowed, [llGetOwnerKey(id)]) != -1 || // On the allowed list?
                   (relaymode == 1 && llSameGroup(id)))                  // Or in group mode and in the same group?
                {
                    rlvclients = llListReplaceList(rlvclients, [id], available, available);
                    llMessageLinked(LINK_SET, RLV_API_SET_SRC, (string)available, id);
                    llMessageLinked(LINK_SET, RLV_API_HANDLE_CMD, m, (key)((string)available));
                }
                else
                {
                    // If it's not owned by the us, we check if it's one of the allowed commands.
                    if(command == "!version") llRegionSayTo(id, RLVRC, ident+","+(string)id+",!version,1100");
                    else if(command == "!implversion") llRegionSayTo(id, RLVRC, ident+","+(string)id+",!implversion,ORG=0004/Hana's Relay");
                    else if(command == "!x-orgversions") llRegionSayTo(id, RLVRC, ident+","+(string)id+",!x-orgversions,ORG=0004/handover=001");
                    else if((behavior == "@version" || behavior == "@versionnew" || behavior == "@versionnum" || behavior == "@versionnumbl") && command == behavior + "=" + value) llOwnerSay(command);

                    // If not, we ask the wearer for permission.
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
        else if(c == tempchannel && templisten != -1)
        {
            if(handlingk == NULL_KEY) return;
            if(llGetOwnerKey(id) != llGetOwner()) return;
            if(m == "ALLOW")
            {
                llSetTimerEvent(0.0);
                if(llListFindList(whitelist, [handlingk]) == -1) whitelist += [handlingk];
                if(llGetListLength(whitelist) > 10) whitelist = llDeleteSubList(whitelist, 1, -1);
                rlvclients = llListReplaceList(rlvclients, [handlingk], handlingi, handlingi);
                llMessageLinked(LINK_SET, RLV_API_SET_SRC, (string)handlingi, handlingk);
                llMessageLinked(LINK_SET, RLV_API_HANDLE_CMD, handlingm, (key)((string)handlingi));
                handlingk = NULL_KEY;
            }
            else if(m == "DENY")
            {
                llSetObjectName("");
                llOwnerSay("RLV relay request denied.");
                llSetObjectName(master_base);
                llSetTimerEvent(0.0);
                handlingk = NULL_KEY;
            }
            else if(m == "BLOCK")
            {
                llSetObjectName("");
                llOwnerSay("RLV relay request blocked. You can type ((blocklist)) to clear the block list.");
                llSetObjectName(master_base);
                llSetTimerEvent(0.0);
                if(llListFindList(blacklist, [handlingk]) == -1) blacklist += [handlingk];
                handlingk = NULL_KEY;
            }
        }
        else if(c == 0)
        {
            if(enabled)
            {
                // Re-assert the exceptions.
                llOwnerSay("@touchme=add");
            }

            integer hr = hasrestrictions();
            if(contains(llToLower(m), "((red))") && hr && enabled)
            {
                llSetObjectName("");
                llOwnerSay("You've safeworded. You're free from all RLV devices that grabbed you.");
                llSetObjectName(master_base);
                llMessageLinked(LINK_SET, RLV_API_SAFEWORD, "", NULL_KEY);
            }
            else if(contains(llToLower(m), "((forcered))") && hr && enabled)
            {
                llSetObjectName("");
                llOwnerSay("You've used the hard safeword. Freeing you and detaching.");
                llSetObjectName(master_base);
                llMessageLinked(LINK_SET, RLV_API_SAFEWORD, "", NULL_KEY);
                llOwnerSay("@clear,detachme=force");
            }
            else if(contains(llToLower(m), "((blocklist))"))
            {
                llSetObjectName("");
                llOwnerSay("Clearing the block list.");
                llSetObjectName(master_base);
                blacklist = [];
            }
        }
    }

    link_message(integer sender_num, integer num, string str, key k)
    {
        if(num == RLV_API_CLR_SRC) rlvclients = llListReplaceList(rlvclients, [(key)NULL_KEY], (integer)str, (integer)str);
        else if(num == RLV_API_HANDOVER) rlvclients = llListReplaceList(rlvclients, [k], (integer)str, (integer)str);
        else if(num == M_API_BUTTON_PRESSED)
        {
            if(rlvclients == []) return;
            if(str == "relay")
            {
                if(enabled == FALSE)
                {
                    enabled = TRUE;
                    llMessageLinked(LINK_SET, M_API_SET_FILTER, "relay", (key)((string)enabled));
                    llSetObjectName("");
                    llOwnerSay("Your RLV relay has been turned on.");
                    llSetObjectName(master_base);
                    llOwnerSay("@touchme=add");
                }
                else
                {
                    if(hasrestrictions())
                    {
                        responses = 0;
                        restrictions = [];
                        llMessageLinked(LINK_SET, RLV_API_GET_RESTRICTIONS, "", (key)"");
                    }
                    else
                    {
                        enabled = FALSE;
                        llMessageLinked(LINK_SET, M_API_SET_FILTER, "relay", (key)((string)enabled));
                        llSetObjectName("");
                        llOwnerSay("Your RLV relay has been turned off. In addition, you have been freed from all RLV devices that may have had ongoing restrictions on you.");
                        llSetObjectName(master_base);
                        llMessageLinked(LINK_SET, RLV_API_SAFEWORD, "", NULL_KEY);
                    }
                }
            }
        }
        else if(num == RLV_API_RESP_RESTRICTIONS)
        {
            responses++;
            if((string)k != "")
            {
                integer hid = (integer)str;
                string oname = llList2String(llGetObjectDetails(llList2Key(rlvclients, hid), [OBJECT_NAME]), 0);
                list rests = llParseString2List((string)k, ["\n"], []);
                integer i;
                integer l = llGetListLength(rests);
                for(i = 0; i < l; ++i)
                {
                    restrictions += [str, oname, llList2String(rests, i)];
                }
            }
            if(responses == llGetListLength(rlvclients))
            {
                restrictions = llListSort(restrictions, 3, TRUE);
                givemenu();
            }
        }
        else if(num == M_API_CONFIG_DONE_2)
        {
            if(rlvclients == []) enabled = FALSE;
            llMessageLinked(LINK_SET, RLV_API_SET_FILTERS, llDumpList2String(filters, "\n"), (key)"");
            llMessageLinked(LINK_SET, M_API_SET_FILTER, "relay", (key)((string)enabled));
            if(enabled == TRUE)
            {
                llSetObjectName("");
                llOwnerSay(VERSION_M + ": Your RLV relay is turned on, supporting up to " + (string)llGetListLength(rlvclients) + " devices.");
                llSetObjectName(master_base);
                llOwnerSay("@touchme=add");
            }
            else if(rlvclients == [])
            {
                llSetObjectName("");
                llOwnerSay(VERSION_M + ": Your RLV relay is disabled until you add some RLV Client scripts to the HUD.");
                llSetObjectName(master_base);
            }
            else
            {
                llSetObjectName("");
                llOwnerSay(VERSION_M + ": Your RLV relay is turned off. It supports up to " + (string)llGetListLength(rlvclients) + " devices.");
                llSetObjectName(master_base);
            }
            configured = TRUE;
        }
        else if(num == M_API_CONFIG_DATA)
        {
            if(configured)
            {
                allowed = [];
                filters = [];
                configured = FALSE;
            }

            if(str == "relaymode")
            {
                string mode = llToLower((string)k);
                if(mode == "ask")
                {
                    llSetObjectName("");
                    llOwnerSay(VERSION_M + ": RLV Relay will ask permission for devices not owned by yourself or other avatars on the exception list.");
                    llSetObjectName(master_base);
                    relaymode = 0;
                }
                else if(mode == "group")
                {
                    llSetObjectName("");
                    llOwnerSay(VERSION_M + ": RLV Relay will ask permission for devices not in the same group as you. Devices owned by yourself and those owned by other avatars on the exception list will be granted permission automatically.");
                    llSetObjectName(master_base);
                    relaymode = 1;
                }
                else if(mode == "auto")
                {
                    llSetObjectName("");
                    llOwnerSay(VERSION_M + ": RLV Relay will grant permission automatically to everything.");
                    llSetObjectName(master_base);
                    relaymode = 2;
                }
            }
            else if(str == "relayallowed")
            {
                allowed += [k];
                llSetObjectName("");
                llOwnerSay(VERSION_M + ": RLV Relay will automatically allow devices owned by secondlife:///app/agent/" + (string)k + "/about.");
                llSetObjectName(master_base);
            }
            else if(str == "relayfilter")
            {
                string filter = llToLower((string)k);
                if(filter == "block_im")
                {
                    filters += ["sendim", "recvim", "startim"];
                    llSetObjectName("");
                    llOwnerSay(VERSION_M + ": RLV Relay will filter out IM blocking commands.");
                    llSetObjectName(master_base);
                }
                else if(filter == "block_blur")
                {
                    filters += ["*renderresolutiondivisor"];
                    llSetObjectName("");
                    llOwnerSay(VERSION_M + ": RLV Relay will filter out screen blur commands.");
                    llSetObjectName(master_base);
                }
                else if(filter == "block_overlay")
                {
                    filters += ["setoverlay", "setenv_"];
                    llSetObjectName("");
                    llOwnerSay(VERSION_M + ": RLV Relay will filter out overlay and vision commands.");
                    llSetObjectName(master_base);
                }
                else if(filter == "block_sphere")
                {
                    filters += ["setsphere", "camdraw"];
                    llSetObjectName("");
                    llOwnerSay(VERSION_M + ": RLV Relay will filter out vision sphere commands.");
                    llSetObjectName(master_base);
                }
                else if(filter == "block_inventory")
                {
                    filters += ["showinv", "view"];
                    llSetObjectName("");
                    llOwnerSay(VERSION_M + ": RLV Relay will filter out inventory commands.");
                    llSetObjectName(master_base);
                }
                else if(filter == "block_autotp")
                {
                    filters += ["accepttp"];
                    llSetObjectName("");
                    llOwnerSay(VERSION_M + ": RLV Relay will filter out auto-teleport commands.");
                    llSetObjectName(master_base);
                }
                else if(filter == "block_tp")
                {
                    filters += ["tp", "sittp", "standtp"];
                    llSetObjectName("");
                    llOwnerSay(VERSION_M + ": RLV Relay will filter out teleport commands.");
                    llSetObjectName(master_base);
                }
                else
                {
                    filters += [filter];
                    llSetObjectName("");
                    llOwnerSay(VERSION_M + ": RLV Relay filter \"" + filter + "\" added.");
                    llSetObjectName(master_base);
                }
            }
        }
    }

    timer()
    {
        llSetTimerEvent(0.0);
        handlingk = NULL_KEY;
        clearlisten();
    }
}
