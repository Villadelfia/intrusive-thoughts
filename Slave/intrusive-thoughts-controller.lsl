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
        if(change & CHANGED_OWNER) resetscripts();
        if(!notifyTeleport) return;
        if(change & CHANGED_TELEPORT) 
        {
            string oldn = llGetObjectName();
            llSetObjectName("");
            if(llGetAgentSize(primary) != ZERO_VECTOR) ownersay(primary, "secondlife:///app/agent/" + (string)llGetOwner() + "/about has arrived at " + slurl() + ".", 0);
            else
            {
                llSetObjectName(oldn);
                llInstantMessage(primary, "secondlife:///app/agent/" + (string)llGetOwner() + "/about has arrived at " + slurl() + ".");
            }
            llSetObjectName(oldn);
        }
    }

    // This script bootstraps the entire IT Slave system.
    attach(key id)
    {
        if(id != NULL_KEY)
        {
            if(wearer != llGetOwner()) return;
            llMessageLinked(LINK_SET, S_API_STARTED, llDumpList2String(owners, ","), primary);
            if(notifyLogon)
            {
                if(llGetAgentSize(primary) != ZERO_VECTOR) ownersay(primary, "The " + VERSION_S + " has been worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about at " + slurl() + ".", 0);
                else llInstantMessage(primary, "The " + VERSION_S + " has been worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about at " + slurl() + ".");
            }
            http = llHTTPRequest(UPDATE_URL, [], "");
        }
        else
        {
            if(notifyLogon)
            {
                if(llGetAgentSize(primary) != ZERO_VECTOR) ownersay(primary, "The " + VERSION_S + " has been taken off by secondlife:///app/agent/" + (string)llGetOwner() + "/about at " + slurl() + ".", 0);
                else llInstantMessage(primary, "The " + VERSION_S + " has been taken off by secondlife:///app/agent/" + (string)llGetOwner() + "/about at " + slurl() + ".");
            }
        }
    }

    // Set up the owner and prefix on first wear.
    state_entry()
    {
        primary = llList2Key(llGetObjectDetails(llGetKey(), [OBJECT_LAST_OWNER_ID]), 0);
#ifdef RETAIL_MODE
        if(primary == llGetCreator()) primary = llGetOwner();
#endif
        owners = [];
        wearer = llGetOwner();
        prefix = llGetSubString(llGetUsername(llGetOwner()), 0, 1);
        llSetObjectDesc((string)primary);
        llListen(COMMAND_CHANNEL, "", NULL_KEY, "");
        if(llGetAgentSize(primary) != ZERO_VECTOR) ownersay(primary, "The " + VERSION_S + " has been worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about at " + slurl() + ".", 0);
        else llInstantMessage(primary, "The " + VERSION_S + " has been worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about at " + slurl() + ".");
        llOwnerSay("Your primary owner has been detected as secondlife:///app/agent/" + (string)primary + "/about. If this is incorrect, detach me immediately because this person can configure me and add additional owners.");
        llMessageLinked(LINK_SET, S_API_OWNERS, llDumpList2String(owners, ","), primary);
        http = llHTTPRequest(UPDATE_URL, [], ""); 
    }

    link_message(integer sender_num, integer num, string str, key id )
    {
        if(num == S_API_HARD_RESET)
        {
            llOwnerSay("@clear");
            resetother();
            llSleep(5.0);
            llMessageLinked(LINK_SET, S_API_OWNERS, llDumpList2String(owners, ","), primary);
            llMessageLinked(LINK_SET, S_API_STARTED, llDumpList2String(owners, ","), primary);
        }
        if(started) return;
        if(num == S_API_OWNERS)
        {
            started = TRUE;
            llMessageLinked(LINK_SET, S_API_STARTED, llDumpList2String(owners, ","), primary);
        }
    }

    listen(integer c, string n, key k, string m)
    {
        // Only allow privileged access.
        if(k != primary) return;

        // Only allow prefixed access.
        if(startswith(m, prefix)) m = llDeleteSubString(m, 0, 1);
        else                      return;
        
        string oldn = llGetObjectName();
        llSetObjectName("");

        k = llGetOwnerKey(k);

        // Owner info
        if(m == "ownerinfo")
        {
            ownersay(k, "Owner information for " + llGetDisplayName(wearer) + ".", 0);
            ownersay(k, "Primary owner: secondlife:///app/agent/" + (string)primary + "/about", 0);
            integer n = llGetListLength(owners);
            integer i;
            for(i = 0; i < n; ++i)
            {
                ownersay(k, "Secondary owner " + (string)i + ": secondlife:///app/agent/" + (string)llList2Key(owners, i) + "/about", 0);
            }
            ownersay(k, " ", 0);
            ownersay(k, "To add a secondary owner, type /1" + prefix + "owneradd username. The user MUST be present on the same region.", 0);
            if(n != 0) ownersay(k, "To remove a secondary owner, type /1" + prefix + "ownerdel number.", 0);
            string groupstatus = "DISABLED";
            string publicstatus = "DISABLED";
            if(groupaccess) groupstatus = "ENABLED";
            if(publicaccess) publicstatus = "ENABLED";
            ownersay(k, "Group access " + groupstatus + ". Click [secondlife:///app/chat/1/" + prefix + "groupaccess here] to toggle.", 0);
            ownersay(k, "Public access " + publicstatus + ". Click [secondlife:///app/chat/1/" + prefix + "publicaccess here] to toggle.", 0);
        }
        else if(startswith(m, "owneradd"))
        {
            m = llDeleteSubString(m, 0, llStringLength("owneradd"));
            key new = llName2Key(m);
            if(new)
            {
                ownersay(k, "Added secondary owner secondlife:///app/agent/" + (string)new + "/about.", 0);
                llRegionSayTo(new, 0, "You've been added as a secondary owner to the Intrusive Thoughts Slave worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about.");
                owners += [new];
                llMessageLinked(LINK_SET, S_API_OWNERS, llDumpList2String(owners, ","), primary);
            }
            else
            {
                ownersay(k, "There is no user in the same region with the username " + m + ".", 0);
            }
        }
        else if(startswith(m, "ownerdel"))
        {
            integer n = (integer)llDeleteSubString(m, 0, llStringLength("ownerdel"));
            if(n < 0 || n >= llGetListLength(owners))
            {
                ownersay(k, "Invalid number given for secondary owner deletion: " + (string)n + ".", 0);
                return;
            }
            else
            {
                ownersay(k, "Deleting secondary owner secondlife:///app/agent/" + (string)llList2Key(owners, n) + "/about.", 0);
                owners = llDeleteSubList(owners, n, n);
                llMessageLinked(LINK_SET, S_API_OWNERS, llDumpList2String(owners, ","), primary);
            }
        }
        else if(m == "groupaccess")
        {
            groupaccess = !groupaccess;
            string groupstatus = "DISABLED";
            if(groupaccess) groupstatus = "ENABLED";
            ownersay(k, "Group access " + groupstatus + ". Click [secondlife:///app/chat/1/" + prefix + "groupaccess here] to toggle.", 0);
            llMessageLinked(LINK_SET, S_API_OTHER_ACCESS, (string)publicaccess, (key)((string)groupaccess));
        }
        else if(m == "publicaccess")
        {
            publicaccess = !publicaccess;
            string publicstatus = "DISABLED";
            if(publicaccess) publicstatus = "ENABLED";
            ownersay(k, "Public access " + publicstatus + ". Click [secondlife:///app/chat/1/" + prefix + "publicaccess here] to toggle.", 0);
            llMessageLinked(LINK_SET, S_API_OTHER_ACCESS, (string)publicaccess, (key)((string)groupaccess));
        }
        else if(m == "lognotify")
        {
            notifyLogon = !notifyLogon;
            string status = "DISABLED";
            if(notifyLogon) status = "ENABLED";
            ownersay(k, "Wear/take off notifications " + status + ". Click [secondlife:///app/chat/1/" + prefix + "lognotify here] to toggle.", 0);
        }
        else if(m == "tpnotify")
        {
            notifyTeleport = !notifyTeleport;
            string status = "DISABLED";
            if(notifyTeleport) status = "ENABLED";
            ownersay(k, "Teleport notifications " + status + ". Click [secondlife:///app/chat/1/" + prefix + "tpnotify here] to toggle.", 0);
        }

        llSetObjectName(oldn);
    }

    http_response(key id, integer status, list metadata, string body)
    {
        if(id == http && status == 200) versioncheck(body, FALSE);
    }
}