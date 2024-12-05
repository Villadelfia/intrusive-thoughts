#include <IT/globals.lsl>
key primary = NULL_KEY;
list owners = [];
string name = "";
string prefix = "";
integer publicaccess = FALSE;
integer groupaccess = FALSE;
float currentVision = 4.0;
float currentFocus = 2.0;

handlemenu(key k)
{
    if(isowner(k) == FALSE && llGetOwnerKey(k) != llGetOwner()) return;
    llSetObjectName("");

    // Greeting
    ownersay(k, "List of available commands for " + name + ":", 0);
    ownersay(k, " ", 0);

    // Animations
    integer numinv = llGetInventoryNumber(INVENTORY_ANIMATION);
    integer i;
    for(i = 0; i < numinv; ++i)
    {
        ownersay(k, "[secondlife:///app/chat/1/" + prefix + llEscapeURL(llGetInventoryName(INVENTORY_ANIMATION, i)) + " - Play " + llGetInventoryName(INVENTORY_ANIMATION, i) + " animation.]", 0);
    }

    // Stop animation
    ownersay(k, "[secondlife:///app/chat/1/" + prefix + "stop - Stop all animations.]", 0);
    ownersay(k, " ", 0);

    // Emergency release.
    ownersay(k, "[secondlife:///app/chat/1/" + prefix + "emergency - Remove all restrictions in case of emergency.]", 0);

    // Owner commands.
#ifndef PUBLIC_SLAVE
    if(isowner(k))
    {
#endif
        ownersay(k, " ", 0);
        ownersay(k, "[secondlife:///app/chat/1/" + prefix + "noim - Toggle local IMs.]", 0);
        ownersay(k, "[secondlife:///app/chat/1/" + prefix + "strip - Strip all clothes.]", 0);
        ownersay(k, "[secondlife:///app/chat/1/" + prefix + "listform - List all forms.]", 0);
        ownersay(k, "[secondlife:///app/chat/1/" + prefix + "listoutfit - List all outfits.]", 0);
        ownersay(k, "[secondlife:///app/chat/1/" + prefix + "liststuff - List all stuff.]", 0);
        ownersay(k, "[secondlife:///app/chat/1/" + prefix + "stand - Stand up.]", 0);
        ownersay(k, "[secondlife:///app/chat/1/" + prefix + "locksit - Lock sit/stand state.]", 0);
        ownersay(k, "[secondlife:///app/chat/1/" + prefix + "leash - Leash]/[secondlife:///app/chat/1/" + prefix + "unleash unleash.]", 0);
        if(llGetOwnerKey(k) == primary)
        {
            ownersay(k, "[secondlife:///app/chat/1/" + prefix + "ownerinfo - Add/remove secondary owners.]", 0);
            ownersay(k, "- Notification toggles: [secondlife:///app/chat/1/" + prefix + "tpnotify On teleport]/[secondlife:///app/chat/1/" + prefix + "lognotify On wear/detach].", 0);
        }
        ownersay(k, " ", 0);
        ownersay(k, "- Toggle [secondlife:///app/chat/1/" + prefix + "deaf deafness]/[secondlife:///app/chat/1/" + prefix + "blind blindness]/[secondlife:///app/chat/1/" + prefix + "mute muting].", 0);
        ownersay(k, "- Toggle [secondlife:///app/chat/1/" + prefix + "mind mindlessness]/[secondlife:///app/chat/1/" + prefix + "daze dazing]/[secondlife:///app/chat/1/" + prefix + "focus focussing].", 0);
        ownersay(k, "- Toggle [secondlife:///app/chat/1/" + prefix + "lock IT lock]/[secondlife:///app/chat/1/" + prefix + "lockoutfit outfit lock].", 0);
        ownersay(k, "- Sight radius: [secondlife:///app/chat/1/" + prefix + "b--- ---] [secondlife:///app/chat/1/" + prefix + "b-- --] [secondlife:///app/chat/1/" + prefix + "b- -] " + formatfloat(currentVision, 2) + " meters [secondlife:///app/chat/1/" + prefix + "b+ +] [secondlife:///app/chat/1/" + prefix + "b++ ++] [secondlife:///app/chat/1/" + prefix + "b+++ +++]", 0);
        ownersay(k, "- Focus distance: [secondlife:///app/chat/1/" + prefix + "f--- ---] [secondlife:///app/chat/1/" + prefix + "f-- --] [secondlife:///app/chat/1/" + prefix + "f- -] " + formatfloat(currentFocus, 2) + " meters [secondlife:///app/chat/1/" + prefix + "f+ +] [secondlife:///app/chat/1/" + prefix + "f++ ++] [secondlife:///app/chat/1/" + prefix + "f+++ +++]", 0);
        ownersay(k, " ", 0);
        ownersay(k, "- [secondlife:///app/chat/1/" + prefix + "afkcheck /1" + prefix + "afkcheck]: Have the slave do an AFK check.", 0);
        ownersay(k, "- /1" + prefix + "say <message>: Say a message.", 0);
        ownersay(k, "- /1" + prefix + "think <message>: Think a message.", 0);
        ownersay(k, "- /1" + prefix + "leashlength <meters>: Set the leash length.", 0);
        ownersay(k, "- /1" + prefix + "blindset <distance>: Directly set distance of sight radius in meters.", 0);
        ownersay(k, "- /1" + prefix + "focusset <distance>: Directly set focus distance in meters.", 0);
#ifndef PUBLIC_SLAVE
    }
#endif

    llSetObjectName(slave_base);
}

default
{
    state_entry()
    {
        name = llGetDisplayName(llGetOwner());
        prefix = llGetSubString(llGetUsername(llGetOwner()), 0, 1);
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == S_API_OWNERS)
        {
            owners = [];
            list new = llParseString2List(str, [","], []);
            integer n = llGetListLength(new);
            while(~--n)
            {
                owners += [(key)llList2String(new, n)];
            }
            primary = id;
            llOwnerSay("@accepttp:" + (string)primary + "=add,accepttprequest:" + (string)primary + "=add");
            integer i = llGetListLength(owners);
            while(~--i)
            {
                key who = (string)llList2Key(owners, i);
                llOwnerSay("@accepttp:" + (string)who + "=add,accepttprequest:" + (string)who + "=add");
            }
        }
        else if(num == S_API_OTHER_ACCESS)
        {
            publicaccess = (integer)str;
            groupaccess = (integer)((string)id);
        }
        else if(num == S_API_MENU)
        {
            handlemenu(id);
        }
        else if(num == S_API_NAME)
        {
            name = str;
        }
        else if(num == S_API_BLIND_LEVEL)
        {
            currentVision = (float)str;
        }
        else if(num == S_API_FOCUS_LEVEL)
        {
            currentFocus = (float)str;
        }
    }

    touch_start(integer num)
    {
        handlemenu(llDetectedKey(0));
    }
}
