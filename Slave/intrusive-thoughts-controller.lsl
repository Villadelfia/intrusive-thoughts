#include <IT/globals.lsl>
integer started = FALSE;
key wearer;
key primary;
list owners;
integer publicaccess = FALSE;
integer groupaccess = FALSE;
string prefix;
key http;
integer notifyLogon = TRUE;
integer notifyTeleport = TRUE;

default
{
    changed(integer change)
    {
        if(change & CHANGED_OWNER)
        {
            llLinksetDataReset();
            resetscripts();
        }
#ifndef PUBLIC_SLAVE
        if(!notifyTeleport) return;
        if(change & CHANGED_TELEPORT)
        {
            llSetObjectName("");
            if(llGetAgentSize(primary) != ZERO_VECTOR) ownersay(primary, "secondlife:///app/agent/" + (string)llGetOwner() + "/about has arrived at " + slurl() + ".", 0);
            else
            {
                llSetObjectName(slave_base);
                llInstantMessage(primary, "secondlife:///app/agent/" + (string)llGetOwner() + "/about has arrived at " + slurl() + ".");
            }
            llSetObjectName(slave_base);
        }
#endif
    }

    // This script bootstraps the entire IT Slave system.
    attach(key id)
    {
        if(id != NULL_KEY)
        {
            if(wearer != llGetOwner()) return;
            llMessageLinked(LINK_SET, S_API_STARTED, llDumpList2String(owners, ","), primary);
#ifndef PUBLIC_SLAVE
            if(notifyLogon)
            {
                if(llGetAgentSize(primary) != ZERO_VECTOR)
                {
                    llSetObjectName("");
                    ownersay(primary, "The " + VERSION_S + " has been worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about at " + slurl() + ".", 0);
                    llSetObjectName(slave_base);
                }
                else llInstantMessage(primary, "The " + VERSION_S + " has been worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about at " + slurl() + ".");
            }
            http = llHTTPRequest(UPDATE_URL, [], "");
#endif
        }
#ifndef PUBLIC_SLAVE
        else
        {
            if(notifyLogon)
            {
                llSetObjectName("");
                if(llGetAgentSize(primary) != ZERO_VECTOR) ownersay(primary, "The " + VERSION_S + " has been taken off by secondlife:///app/agent/" + (string)llGetOwner() + "/about at " + slurl() + ".", 0);
                else llInstantMessage(primary, "The " + VERSION_S + " has been taken off by secondlife:///app/agent/" + (string)llGetOwner() + "/about at " + slurl() + ".");
                llSetObjectName(slave_base);
            }
        }
#endif
    }

    // Set up the owner and prefix on first wear.
    state_entry()
    {
        primary = llList2Key(llGetObjectDetails(llGetKey(), [OBJECT_LAST_OWNER_ID]), 0);
#ifdef RETAIL_MODE
        if(primary == llGetCreator()) primary = llGetOwner();
#endif
        // Reload from LSD.
        owners = llParseString2List(llLinksetDataReadProtected("secondary", ""), [","], []);
        if(llLinksetDataReadProtected("primary", "") != "") primary = (key)llLinksetDataReadProtected("primary", "");
        if(llLinksetDataReadProtected("publicaccess", "") != "") publicaccess = (integer)llLinksetDataReadProtected("publicaccess", "");
        if(llLinksetDataReadProtected("groupaccess", "") != "") groupaccess = (integer)llLinksetDataReadProtected("groupaccess", "");
        if(llLinksetDataReadProtected("lognotify", "") != "") notifyLogon = (integer)llLinksetDataReadProtected("lognotify", "");
        if(llLinksetDataReadProtected("tpnotify", "") != "") notifyTeleport = (integer)llLinksetDataReadProtected("tpnotify", "");

        wearer = llGetOwner();
        prefix = llGetSubString(llGetUsername(llGetOwner()), 0, 1);
        llSetObjectDesc((string)primary);
        llListen(COMMAND_CHANNEL, "", NULL_KEY, "");
        llListen(UPDATE_CHANNEL, "", NULL_KEY, "");

        // Set update pin.
        integer pin = ((integer)("0x"+llGetSubString((string)llGetOwner(),-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFFF;
        llSetRemoteScriptAccessPin(pin);

        llSetObjectName("");
#ifndef PUBLIC_SLAVE
        if(llGetAgentSize(primary) != ZERO_VECTOR)
        {
            ownersay(primary, "The " + VERSION_S + " has been worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about at " + slurl() + ".", 0);
        }
        else
        {
            llSetObjectName(slave_base);
            llInstantMessage(primary, "The " + VERSION_S + " has been worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about at " + slurl() + ".");
            llSetObjectName("");
        }
        llOwnerSay("Your primary owner has been detected as secondlife:///app/agent/" + (string)primary + "/about. If this is incorrect, detach me immediately because this person can configure me and add additional owners.");
        llSetObjectName(slave_base);
        llMessageLinked(LINK_SET, S_API_OWNERS, llDumpList2String(owners, ","), primary);
        llMessageLinked(LINK_SET, S_API_OTHER_ACCESS, (string)publicaccess, (key)((string)groupaccess));
        http = llHTTPRequest(UPDATE_URL, [], "");
#else
        llOwnerSay("This version of the IT Slave can be configured by *anyone* (including yourself). If this is incorrect, detach me immediately.");
        llSetObjectName(slave_base);
        started = TRUE;
        llMessageLinked(LINK_SET, S_API_STARTED, "", NULL_KEY);
#endif
    }

    link_message(integer sender_num, integer num, string str, key id )
    {
        if(num == S_API_HARD_RESET)
        {
            llOwnerSay("@clear");
            resetother();
            llSleep(5.0);
            llMessageLinked(LINK_SET, S_API_OWNERS, llDumpList2String(owners, ","), primary);
            llMessageLinked(LINK_SET, S_API_OTHER_ACCESS, (string)publicaccess, (key)((string)groupaccess));
            llMessageLinked(LINK_SET, S_API_STARTED, llDumpList2String(owners, ","), primary);
        }
        if(started) return;
        if(num == S_API_OWNERS)
        {
            started = TRUE;
            llMessageLinked(LINK_SET, S_API_STARTED, llDumpList2String(owners, ","), primary);
        }
    }

#ifndef PUBLIC_SLAVE
    listen(integer c, string n, key k, string m)
    {
        if(c == UPDATE_CHANNEL)
        {
            if(llGetOwnerKey(k) != llGetOwner()) return;
            if(m == "VERSION_CHECK") llRegionSayTo(k, UPDATE_CHANNEL, "SLAVE_VERSION " + VERSION_CMP);
            return;
        }

        // Only allow privileged access.
        if(k != primary) return;

        // Only allow prefixed access.
        if(startswith(m, prefix)) m = llDeleteSubString(m, 0, 1);
        else                      return;

        k = llGetOwnerKey(k);

        // Owner info
        if(m == "ownerinfo")
        {
            llSetObjectName("");
            ownersay(k, "Owner information for " + llGetDisplayName(wearer) + ".", 0);
            ownersay(k, "Primary owner: secondlife:///app/agent/" + (string)primary + "/about", 0);
            integer n = llGetListLength(owners);
            integer i;
            for(i = 0; i < n; ++i)
            {
                ownersay(k, "Secondary owner " + (string)i + ": secondlife:///app/agent/" + (string)llList2Key(owners, i) + "/about", 0);
            }
            ownersay(k, " ", 0);
            ownersay(k, "To add a secondary owner, type /1" + prefix + "owneradd username/uuid. The user MUST be present on the same region in case of username.", 0);
            if(n != 0) ownersay(k, "To remove a secondary owner, type /1" + prefix + "ownerdel number.", 0);
            string groupstatus = "DISABLED";
            string publicstatus = "DISABLED";
            if(groupaccess) groupstatus = "ENABLED";
            if(publicaccess) publicstatus = "ENABLED";
            ownersay(k, "Group access " + groupstatus + ". Click [secondlife:///app/chat/1/" + prefix + "groupaccess here] to toggle.", 0);
            ownersay(k, "Public access " + publicstatus + ". Click [secondlife:///app/chat/1/" + prefix + "publicaccess here] to toggle.", 0);
            llSetObjectName(slave_base);
        }
        else if(startswith(m, "owneradd"))
        {
            m = llStringTrim(llDeleteSubString(m, 0, llStringLength("owneradd")), STRING_TRIM);
            key new = NULL_KEY;
            if(llStringLength(m) == 36) new = (key)m;
            else                        new = llName2Key(m);
            llSetObjectName("");
            if(new)
            {
                ownersay(k, "Added secondary owner secondlife:///app/agent/" + (string)new + "/about.", 0);
                llRegionSayTo(new, 0, "You've been added as a secondary owner to the Intrusive Thoughts Slave worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about.");
                owners += [new];
                llLinksetDataWriteProtected("secondary", llDumpList2String(owners, ","), "");
                llLinksetDataWriteProtected("primary", (string)primary, "");
                llMessageLinked(LINK_SET, S_API_OWNERS, llDumpList2String(owners, ","), primary);
            }
            else
            {
                ownersay(k, "There is no user in the same region with the username " + m + ".", 0);
            }
            llSetObjectName(slave_base);
        }
        else if(startswith(m, "ownerdel"))
        {
            integer n = (integer)llDeleteSubString(m, 0, llStringLength("ownerdel"));
            llSetObjectName("");
            if(n < 0 || n >= llGetListLength(owners))
            {
                ownersay(k, "Invalid number given for secondary owner deletion: " + (string)n + ".", 0);
                llSetObjectName(slave_base);
                return;
            }
            else
            {
                ownersay(k, "Deleting secondary owner secondlife:///app/agent/" + (string)llList2Key(owners, n) + "/about.", 0);
                owners = llDeleteSubList(owners, n, n);
                llLinksetDataWriteProtected("secondary", llDumpList2String(owners, ","), "");
                llLinksetDataWriteProtected("primary", (string)primary, "");
                llMessageLinked(LINK_SET, S_API_OWNERS, llDumpList2String(owners, ","), primary);
            }
            llSetObjectName(slave_base);
        }
        else if(m == "ownerexport")
        {
            string out = "pri:" + (string)primary + ";pub:" + (string)publicaccess + ";grp:" + (string)groupaccess;
            if(owners != [])
            {
                out += ";sec:";
                out += llDumpList2String(owners, ",");
            }
            llSetObjectName("Owner Data Export");
            ownersay(k, out, 0);
            llSetObjectName(slave_base);
        }
        else if(startswith(m, "ownerimport"))
        {
            m = llStringTrim(llDeleteSubString(m, 0, llStringLength("ownerimport")-1), STRING_TRIM);
            list tokens = llParseString2List(m, [";"], []);
            integer l = llGetListLength(tokens);
            llSetObjectName("");
            while(~--l)
            {
                string token = llList2String(tokens, l);
                if(startswith(token, "pri:"))
                {
                    primary = (key)llList2String(llParseString2List(token, [":"], []), 1);
                    ownersay(k, "Primary owner: secondlife:///app/agent/" + (string)primary + "/about", 0);
                }
                else if(startswith(token, "sec:"))
                {
                    list new = llParseString2List(llList2String(llParseString2List(token, [":"], []), 1), [","], []);
                    integer m = llGetListLength(new);
                    owners = [];
                    while(~--m)
                    {
                        ownersay(k, "Added secondary owner secondlife:///app/agent/" + llList2String(new, m) + "/about.", 0);
                        owners += [(key)llList2String(new, m)];
                    }
                }
                else if(startswith(token, "grp:"))
                {
                    groupaccess = (integer)llList2String(llParseString2List(token, [":"], []), 1);
                    string groupstatus = "DISABLED";
                    if(groupaccess) groupstatus = "ENABLED";
                    ownersay(k, "Group access " + groupstatus + ".", 0);
                }
                else if(startswith(token, "pub:"))
                {
                    publicaccess = (integer)llList2String(llParseString2List(token, [":"], []), 1);
                    string publicstatus = "DISABLED";
                    if(publicaccess) publicstatus = "ENABLED";
                    ownersay(k, "Public access " + publicstatus + ".", 0);
                }
            }
            llSetObjectName(slave_base);
            llLinksetDataWriteProtected("secondary", llDumpList2String(owners, ","), "");
            llLinksetDataWriteProtected("primary", (string)primary, "");
            llLinksetDataWriteProtected("publicaccess", (string)publicaccess, "");
            llLinksetDataWriteProtected("groupaccess", (string)groupaccess, "");
            llMessageLinked(LINK_SET, S_API_OWNERS, llDumpList2String(owners, ","), primary);
            llMessageLinked(LINK_SET, S_API_OTHER_ACCESS, (string)publicaccess, (key)((string)groupaccess));
        }
        else if(m == "groupaccess")
        {
            groupaccess = !groupaccess;
            string groupstatus = "DISABLED";
            if(groupaccess) groupstatus = "ENABLED";
            llSetObjectName("");
            ownersay(k, "Group access " + groupstatus + ". Click [secondlife:///app/chat/1/" + prefix + "groupaccess here] to toggle.", 0);
            llSetObjectName(slave_base);
            llLinksetDataWriteProtected("publicaccess", (string)publicaccess, "");
            llLinksetDataWriteProtected("groupaccess", (string)groupaccess, "");
            llMessageLinked(LINK_SET, S_API_OTHER_ACCESS, (string)publicaccess, (key)((string)groupaccess));
        }
        else if(m == "publicaccess")
        {
            publicaccess = !publicaccess;
            string publicstatus = "DISABLED";
            if(publicaccess) publicstatus = "ENABLED";
            llSetObjectName("");
            ownersay(k, "Public access " + publicstatus + ". Click [secondlife:///app/chat/1/" + prefix + "publicaccess here] to toggle.", 0);
            llSetObjectName(slave_base);
            llLinksetDataWriteProtected("publicaccess", (string)publicaccess, "");
            llLinksetDataWriteProtected("groupaccess", (string)groupaccess, "");
            llMessageLinked(LINK_SET, S_API_OTHER_ACCESS, (string)publicaccess, (key)((string)groupaccess));
        }
        else if(m == "lognotify")
        {
            notifyLogon = !notifyLogon;
            string status = "DISABLED";
            if(notifyLogon) status = "ENABLED";
            llSetObjectName("");
            ownersay(k, "Wear/take off notifications " + status + ". Click [secondlife:///app/chat/1/" + prefix + "lognotify here] to toggle.", 0);
            llSetObjectName(slave_base);
            llLinksetDataWriteProtected("lognotify", (string)notifyLogon, "");
        }
        else if(m == "tpnotify")
        {
            notifyTeleport = !notifyTeleport;
            string status = "DISABLED";
            if(notifyTeleport) status = "ENABLED";
            llSetObjectName("");
            ownersay(k, "Teleport notifications " + status + ". Click [secondlife:///app/chat/1/" + prefix + "tpnotify here] to toggle.", 0);
            llSetObjectName(slave_base);
            llLinksetDataWriteProtected("tpnotify", (string)notifyTeleport, "");
        }

    }

    http_response(key id, integer status, list metadata, string body)
    {
        if(id == http && status == 200) versioncheck(body, FALSE);
    }
#endif
}
