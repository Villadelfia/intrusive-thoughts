#include <IT/globals.lsl>
integer started = FALSE;
key wearer;
key primary;
list owners;
integer publicaccess = FALSE;
integer groupaccess = FALSE;
string prefix;
key http;

default
{
    changed(integer change)
    {
        if(change & CHANGED_OWNER) resetscripts();
    }

    // This script bootstraps the entire IT Slave system.
    attach(key id)
    {
        if(id != NULL_KEY)
        {
            if(wearer != llGetOwner()) return;
            llMessageLinked(LINK_SET, S_API_STARTED, llDumpList2String(owners, ","), primary);
            if(llGetAgentSize(primary) != ZERO_VECTOR) ownersay(primary, "The " + VERSION_S + " has been worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about at " + slurl() + ".");
            else llInstantMessage(primary, "The " + VERSION_S + " has been worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about at " + slurl() + ".");
            http = llHTTPRequest(UPDATE_URL, [], "");
        }
        else
        {
            if(llGetAgentSize(primary) != ZERO_VECTOR) ownersay(primary, "The " + VERSION_S + " has been taken off by secondlife:///app/agent/" + (string)llGetOwner() + "/about at " + slurl() + ".");
            else llInstantMessage(primary, "The " + VERSION_S + " has been taken off by secondlife:///app/agent/" + (string)llGetOwner() + "/about at " + slurl() + ".");
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
        llListen(COMMAND_CHANNEL, "", NULL_KEY, "");
        if(llGetAgentSize(primary) != ZERO_VECTOR) ownersay(primary, "The " + VERSION_S + " has been worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about at " + slurl() + ".");
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
            ownersay(k, "Owner information for " + llGetDisplayName(wearer) + ".");
            ownersay(k, "Primary owner: secondlife:///app/agent/" + (string)primary + "/about");
            integer n = llGetListLength(owners);
            integer i;
            for(i = 0; i < n; ++i)
            {
                ownersay(k, "Secondary owner " + (string)i + ": secondlife:///app/agent/" + (string)llList2Key(owners, i) + "/about");
            }
            ownersay(k, " ");
            ownersay(k, "To add a secondary owner, type /1" + prefix + "owneradd username. The user MUST be present on the same region.");
            if(n != 0) ownersay(k, "To remove a secondary owner, type /1" + prefix + "ownerdel number.");
            string groupstatus = "DISABLED";
            string publicstatus = "DISABLED";
            if(groupaccess) groupstatus = "ENABLED";
            if(publicaccess) publicstatus = "ENABLED";
            ownersay(k, "Group access " + groupstatus + ". Click [secondlife:///app/chat/1/" + prefix + "groupaccess here] to toggle.");
            ownersay(k, "Public access " + publicstatus + ". Click [secondlife:///app/chat/1/" + prefix + "publicaccess here] to toggle.");
        }
        else if(startswith(m, "owneradd"))
        {
            m = llDeleteSubString(m, 0, llStringLength("owneradd"));
            key new = llName2Key(m);
            if(new)
            {
                ownersay(k, "Added secondary owner secondlife:///app/agent/" + (string)new + "/about.");
                llRegionSayTo(new, 0, "You've been added as a secondary owner to the Intrusive Thoughts Slave worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about.");
                if(new != llGetOwner())
                {
                    llRegionSayTo(new, 0, "I am sending you a device that you must wear to be able to see the messages sent to owners by the Intrusive Thoughts Slave. If you have multiple slaves, you only need one of these.");
                    llGiveInventory(new, "Intrusive Thoughts Listener");
                }
                owners += [new];
                llMessageLinked(LINK_SET, S_API_OWNERS, llDumpList2String(owners, ","), primary);
            }
            else
            {
                ownersay(k, "There is no user in the same region with the username " + m + ".");
            }
        }
        else if(startswith(m, "ownerdel"))
        {
            integer n = (integer)llDeleteSubString(m, 0, llStringLength("ownerdel"));
            if(n < 0 || n >= llGetListLength(owners))
            {
                ownersay(k, "Invalid number given for secondary owner deletion: " + (string)n + ".");
                return;
            }
            else
            {
                ownersay(k, "Deleting secondary owner secondlife:///app/agent/" + (string)llList2Key(owners, n) + "/about.");
                owners = llDeleteSubList(owners, n, n);
                llMessageLinked(LINK_SET, S_API_OWNERS, llDumpList2String(owners, ","), primary);
            }
        }
        else if(m == "groupaccess")
        {
            groupaccess = !groupaccess;
            string groupstatus = "DISABLED";
            if(groupaccess) groupstatus = "ENABLED";
            ownersay(k, "Group access " + groupstatus + ". Click [secondlife:///app/chat/1/" + prefix + "groupaccess here] to toggle.");
            llMessageLinked(LINK_SET, S_API_OTHER_ACCESS, (string)publicaccess, (key)((string)groupaccess));
        }
        else if(m == "publicaccess")
        {
            publicaccess = !publicaccess;
            string publicstatus = "DISABLED";
            if(publicaccess) publicstatus = "ENABLED";
            ownersay(k, "Public access " + publicstatus + ". Click [secondlife:///app/chat/1/" + prefix + "publicaccess here] to toggle.");
            llMessageLinked(LINK_SET, S_API_OTHER_ACCESS, (string)publicaccess, (key)((string)groupaccess));
        }

        llSetObjectName(oldn);
    }

    http_response(key id, integer status, list metadata, string body)
    {
        if(id == http && status == 200) versioncheck(body, FALSE);
    }
}