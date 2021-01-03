#include <IT/globals.lsl>
integer started = FALSE;
key wearer;
key primary;
list owners;
string prefix;

default
{
    // This script bootstraps the entire IT Slave system.
    attach(key id)
    {
        if(id != NULL_KEY)
        {
            if(DEMO_MODE == 1)
            {
                list date = llParseString2List(llGetDate(), ["-"], []);
                integer year  = (integer)llList2String(date, 0);
                integer month = (integer)llList2String(date, 1);
                if(year > 2021 || month > 1)
                {
                    llOwnerSay("Demo period is over. Detaching.");
                    llOwnerSay("@clear,detachme=force");
                    llRequestPermissions(llGetOwner(), PERMISSION_ATTACH);
                    return;
                }
            }
            if(wearer != llGetOwner()) resetscripts();
            else
            {
                llMessageLinked(LINK_SET, S_API_STARTED, llDumpList2String(owners, ","), primary);
                if(llGetAgentSize(primary) != ZERO_VECTOR) llRegionSayTo(primary, 0, "The " + VERSION_S + " has been worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about at " + slurl() + ".");
                else llInstantMessage(primary, "The " + VERSION_S + " has been worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about at " + slurl() + ".");
            }
        }
        else
        {
            if(llGetAgentSize(primary) != ZERO_VECTOR) llRegionSayTo(primary, 0, "The " + VERSION_S + " has been taken off by secondlife:///app/agent/" + (string)llGetOwner() + "/about at " + slurl() + ".");
            else llInstantMessage(primary, "The " + VERSION_S + " has been taken off by secondlife:///app/agent/" + (string)llGetOwner() + "/about at " + slurl() + ".");
        }
    }

    run_time_permissions(integer perm)
    {
        if(perm & PERMISSION_ATTACH) llDetachFromAvatar();
    }

    // Set up the owner and prefix on first wear.
    state_entry()
    {
        primary = llList2Key(llGetObjectDetails(llGetKey(), [OBJECT_LAST_OWNER_ID]), 0);
        owners = [];
        wearer = llGetOwner();
        prefix = llGetSubString(llGetUsername(llGetOwner()), 0, 1);
        llListen(COMMAND_CHANNEL, "", NULL_KEY, "");
        if(llGetAgentSize(primary) != ZERO_VECTOR) llRegionSayTo(primary, 0, "The " + VERSION_S + " has been worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about at " + slurl() + ".");
        else llInstantMessage(primary, "The " + VERSION_S + " has been worn by secondlife:///app/agent/" + (string)llGetOwner() + "/about at " + slurl() + ".");
        llOwnerSay("Your primary owner has been detected as secondlife:///app/agent/" + (string)primary + "/about. If this is incorrect, detach me immediately because this person can configure me and add additional owners.");
        llMessageLinked(LINK_SET, S_API_OWNERS, llDumpList2String(owners, ","), primary);
    }

    link_message(integer sender_num, integer num, string str, key id )
    {
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
        k = llGetOwnerKey(k);

        // Owner info
        if(m == "ownerinfo")
        {
            llRegionSayTo(k, HUD_SPEAK_CHANNEL, "Owner information for " + llGetDisplayName(wearer) + ".");
            llRegionSayTo(k, HUD_SPEAK_CHANNEL, "Primary owner: secondlife:///app/agent/" + (string)primary + "/about");
            integer n = llGetListLength(owners);
            integer i;
            for(i = 0; i < n; ++i)
            {
                llRegionSayTo(k, HUD_SPEAK_CHANNEL, "Secondary owner " + (string)i + ": secondlife:///app/agent/" + (string)llList2Key(owners, i) + "/about");
            }
            llRegionSayTo(k, HUD_SPEAK_CHANNEL, "");
            llRegionSayTo(k, HUD_SPEAK_CHANNEL, "To add a secondary owner, type /1" + prefix + "owneradd username. The user MUST be present on the same region.");
            if(n != 0) llRegionSayTo(k, HUD_SPEAK_CHANNEL, "To remove a secondary owner, type /1" + prefix + "ownerdel number.");
        }
        else if(startswith(m, "owneradd"))
        {
            m = llDeleteSubString(m, 0, llStringLength("owneradd"));
            key new = llName2Key(m);
            if(new)
            {
                llRegionSayTo(k, HUD_SPEAK_CHANNEL, "Added secondary owner secondlife:///app/agent/" + (string)new + "/about.");
                llRegionSayTo(new, 0, "I am sending you a device that you must wear to be able to see the messages sent to owners by the Intrusive Thoughts Slave. If you have multiple slaves, you only need one of these.");
                llGiveInventory(new, "Intrusive Thoughts Listener");
                owners += [new];
                llMessageLinked(LINK_SET, S_API_OWNERS, llDumpList2String(owners, ","), primary);
            }
            else
            {
                llRegionSayTo(k, HUD_SPEAK_CHANNEL, "There is no user in the same region with the username " + m + ".");
            }
        }
        else if(startswith(m, "ownerdel"))
        {
            integer n = (integer)llDeleteSubString(m, 0, llStringLength("ownerdel"));
            if(n < 0 || n >= llGetListLength(owners))
            {
                llRegionSayTo(k, HUD_SPEAK_CHANNEL, "Invalid number given for secondary owner deletion: " + (string)n + ".");
                return;
            }
            else
            {
                llRegionSayTo(k, HUD_SPEAK_CHANNEL, "Deleting secondary owner secondlife:///app/agent/" + (string)llList2Key(owners, n) + "/about.");
                owners = llDeleteSubList(owners, n, n);
                llMessageLinked(LINK_SET, S_API_OWNERS, llDumpList2String(owners, ","), primary);
            }
        }
    }
}