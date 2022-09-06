#include <IT/globals.lsl>

string settings;
integer await = -1;
list updatable = [];

sendPayload()
{
    if(updatable == [])
    {
        llOwnerSay("Done updating all pieces of furniture! Deleting myself...");
        if(llGetOwner() != (key)IT_CREATOR)
        {
            llSleep(5.0);
            llDie();
            while(TRUE) llSleep(1.0);
        }
        else
        {
            llResetScript();
            while(TRUE) llSleep(1.0);
        }
    }
    key k = llList2Key(updatable, 0);
    integer pin = ((integer)("0x"+llGetSubString((string)k,-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFFF;
    string n = llList2String(llGetObjectDetails(k, [OBJECT_NAME]), 0);
    llOwnerSay("Updating: " + n);
    llRemoteLoadScriptPin(k, "intrusive-thoughts-updater", pin, TRUE, 1);
}

sendBall()
{
    key k = llList2Key(updatable, 0);
    llGiveInventory(k, "ball");
}

sendScript()
{
    key k = llList2Key(updatable, 0);
    integer pin = ((integer)("0x"+llGetSubString((string)k,-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFFF;
    llRemoteLoadScriptPin(k, "intrusive-thoughts-furniture", pin, TRUE, 1);
}

default
{
    state_entry()
    {
        if(llGetStartParameter() == 1) state slave;
        if(llGetAttached() != 0)
        {
            llOwnerSay("Please rez me instead of wearing me.");
        }
        else
        {
            llOwnerSay("This object will scan for, and apply, updates to any rezzed IT Furniture in this region. Scanning for updatable furniture right now...");
            llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
            llRegionSay(MANTRA_CHANNEL, "furnver");
            llSetTimerEvent(5.0);
        }
    }

    listen(integer channel, string name, key id, string message)
    {
        if(startswith(message, "furnver="))
        {
            if(FURNITURE_VERSION > (integer)llList2String(llParseString2List(message, ["="], []), 1))
            {
                updatable += [id];
                llSetTimerEvent(0.0);
                llSetTimerEvent(5.0);
            }
        }
    }

    timer()
    {
        llSetTimerEvent(0.0);
        if(updatable == [])
        {
            llOwnerSay(
                "No updatable furniture found. This can mean one of three things:\n\n" +
                " - There is no IT Furniture rezzed on this region that is owned by you.\n" +
                " - There is IT Furniture rezzed on this region that is owned by you, but its version is older than version 3.0.4. You need to update it manually. Please consult the instruction manual for information on this process.\n" +
                " - There is updatable IT Furniture rezzed on this region, but it is currently occupied. It is not possible to update IT Furniture that currently has someone captured.\n\n" +
                "Please verify and rectify the above issues, then rez me again. I am now deleting myself."
            );
            if(llGetOwner() != (key)IT_CREATOR)
            {
                llSleep(5.0);
                llDie();
                while(TRUE) llSleep(1.0);
            }
        }
        else
        {
            llOwnerSay("Found -->" + (string)llGetListLength(updatable) + "<-- updatable pieces of furniture. Starting update process.");
            state update;
        }
    }

    on_rez(integer start_param)
    {
        if(llGetStartParameter() == 1) state slave;
        else                           llResetScript();
    }
}

state update
{
    state_entry()
    {
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
        sendPayload();
    }

    listen(integer c, string n, key id, string m)
    {
        if(id != llList2Key(updatable, 0)) return;
        if(m == "furnupdball") sendBall();
        if(m == "furnupdscript") sendScript();
        if(m == "furnupdok" || m == "furnupdnok")
        {
            updatable = llDeleteSubList(updatable, 0, 0);
            sendPayload();
        }
    }

    on_rez(integer start_param)
    {
        llResetScript();
    }
}

state slave
{
    state_entry()
    {
        llOwnerSay("Starting update...");
        llMessageLinked(LINK_THIS, X_API_DUMP_SETTINGS, "", NULL_KEY);
        llSetTimerEvent(10.0);
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == X_API_DUMP_SETTINGS_R)
        {
            llSetTimerEvent(0.0);
            settings = str;
            await = 0;
            llRemoveInventory("ball");
            llRegionSay(MANTRA_CHANNEL, "furnupdball");
            llOwnerSay("Requesting new ball...");
        }
        else if(num == X_API_RESTORE_SETTINGS_R)
        {
            llRegionSay(MANTRA_CHANNEL, "furnupdok");
            llOwnerSay("Update complete!");
            llRemoveInventory(llGetScriptName());
        }
    }

    changed(integer change)
    {
        if(change & CHANGED_INVENTORY)
        {
            if(await == 0)
            {
                if(llGetInventoryType("ball") == INVENTORY_OBJECT)
                {
                    await = 1;
                    llRemoveInventory("intrusive-thoughts-furniture");
                    llRegionSay(MANTRA_CHANNEL, "furnupdscript");
                    llOwnerSay("Requesting new script...");
                }
            }
            else if(await == 1)
            {
                if(llGetInventoryType("intrusive-thoughts-furniture") == INVENTORY_SCRIPT)
                {
                    await = -1;
                    llOwnerSay("Finishing update...");
                    llSleep(3.0);
                    llMessageLinked(LINK_THIS, X_API_RESTORE_SETTINGS, settings, NULL_KEY);
                }
            }
        }
    }

    timer()
    {
        llOwnerSay("Could not update...");
        llSetTimerEvent(0.0);
        llRegionSay(MANTRA_CHANNEL, "furnupdnok");
        llRemoveInventory(llGetScriptName());
    }
}
