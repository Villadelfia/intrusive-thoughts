#include <IT/globals.lsl>
string target = "";
string tptarget = "";
list locations = [];
integer configured = FALSE;
vector targetsimcorner;
vector targetsimlocal;
key ds;

dotp(string region, string x, string y, string z)
{
    llOwnerSay("Teleporting you and your slaves to: " + slurlp(region, x, y, z));
    llRegionSay(MANTRA_CHANNEL, "tpto " + region + "/" + x + "/" + y  + "/" + z);
    llMessageLinked(LINK_SET, API_DOTP, "@tploc=y|@unsit=y|@tpto:" + region + "/" + x + "/" + y  + "/" + z + "=force", (key)region);
    tptarget = "@tploc=y,unsit=y,tpto:" + region + "/" + x + "/" + y  + "/" + z + "=force";
}

tpme(string region, string x, string y, string z)
{
    llOwnerSay("Teleporting you to: " + slurlp(region, x, y, z));
    llMessageLinked(LINK_SET, API_DOTP, "@tploc=y|@unsit=y|@tpto:" + region + "/" + x + "/" + y  + "/" + z + "=force", (key)region);
    tptarget = "@tploc=y,unsit=y,tpto:" + region + "/" + x + "/" + y  + "/" + z + "=force";
}

givemenu()
{
    llOwnerSay("Leash options:");
    llOwnerSay("[secondlife:///app/chat/" + (string)GAZE_CHANNEL + "/leashme Leash locked avatar to self]");
    llOwnerSay("[secondlife:///app/chat/" + (string)GAZE_CHANNEL + "/leashto Leash locked avatar to last seen object]");
    llOwnerSay("[secondlife:///app/chat/" + (string)GAZE_CHANNEL + "/yank Yank locked avatar]");
    llOwnerSay("[secondlife:///app/chat/" + (string)GAZE_CHANNEL + "/unleash Unleash locked avatar]");
    llOwnerSay(" ");
    llOwnerSay("RLV options:");
    llOwnerSay("[secondlife:///app/chat/" + (string)GAZE_CHANNEL + "/clear Clear RLV relay for locked avatar]");
    llOwnerSay("[secondlife:///app/chat/" + (string)GAZE_CHANNEL + "/forceclear Clear and detach RLV relay for locked avatar]");
    llOwnerSay("You can type ((RED)) to clear your own relay, or ((FORCERED)) to clear and detach it.");
    llOwnerSay(" ");
    llOwnerSay("Teleportation options:");
    integer i;
    integer l = llGetListLength(locations);
    for(i = 0; i < l; i += 5)
    {
        string dest = llList2String(locations, i);
        llOwnerSay(dest + " — [secondlife:///app/chat/1/tpto%20" + dest + " (together)] [secondlife:///app/chat/1/tpme%20" + dest + " (alone)]");
    }
    llOwnerSay(" ");
    llOwnerSay("You may also use the following commands:");
    llOwnerSay("/1tpto <slurl> — Teleport with your slaves to the SLURL");
    llOwnerSay("/1tpme <slurl> — Teleport alone to the SLURL");
    llOwnerSay("—or— drop a landmark onto the HUD to teleport there with your slaves");
}

default
{
    changed(integer change)
    {
        if(change & CHANGED_OWNER)
        {
            llResetScript();
        }

        if(change & CHANGED_INVENTORY)
        {
            if(llGetInventoryNumber(INVENTORY_LANDMARK) == 0) return;
            ds = llRequestInventoryData(llGetInventoryName(INVENTORY_LANDMARK, 0));
        }
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == API_TPOK) llOwnerSay(tptarget);
        if(num == API_STARTUP_DONE) 
        {
            llListen(1, "", llGetOwner(), "");
            configured = TRUE;
            llOwnerSay("[" + llGetScriptName() + "]: " + (string)(llGetFreeMemory() / 1024.0) + "kb free.");
        }
        if(num == API_CONFIG_DATA && str == "tp")
        {
            if(configured)
            {
                locations = [];
                configured = FALSE;
            }
            locations += llParseString2List((string)id, [","], []);
            llSetObjectName("");
            llOwnerSay(VERSION_C + ": Loaded teleport location " + llList2String(locations, -5));
        }
        if(num == API_GIVE_TP_MENU) givemenu();
    }

    listen(integer c, string n, key id, string m)
    {
        if(startswith(llToLower(m), "dotp") == FALSE && startswith(llToLower(m), "tpto") == FALSE && startswith(llToLower(m), "tpme") == FALSE) return;
        integer justme = startswith(llToLower(m), "tpme");
        m = llDeleteSubString(m, 0, llStringLength("tpto"));
        if(llListFindList(locations, [llToLower(m)]) != -1)
        {
            integer i = llListFindList(locations, [llToLower(m)]);
            string region = (string)locations[i+1];
            string x = (string)locations[i+2];
            string y = (string)locations[i+3];
            string z = (string)locations[i+4];
            if(justme) tpme(region, x, y, z);
            else       dotp(region, x, y, z);
        }
        else if(startswith(m, "http://") || startswith(m, "https://"))
        {
            list parts = llParseString2List(m, ["/"], []);
            string url = (string)parts[1];
            if(url != "maps.secondlife.com" && url != "slurl.com") return;
            string region = llUnescapeURL((string)parts[3]);
            string x = (string)parts[4];
            string y = (string)parts[5];
            string z = (string)parts[6];
            if(justme) tpme(region, x, y, z);
            else       dotp(region, x, y, z);
        }
    }

    http_response(key q, integer status, list metadata, string body)
    {
        if(q != ds) return;
        string region = llList2String(llParseString2List(body, ["'"], []), 1);
        if(status != 200 || region == "error")
        {
            llOwnerSay("Error getting landmark data...");
            return;
        }
        string x = (string)llRound(targetsimlocal.x);
        string y = (string)llRound(targetsimlocal.y);
        string z = (string)llRound(targetsimlocal.z);
        dotp(region, x, y, z);
    }

    dataserver(key q, string d)
    {
        if(q != ds) return;
        vector relative = (vector)d;
        vector global = llGetRegionCorner() + relative;
        targetsimcorner = <256.0 * (float) ((integer)(global.x / 256.0)), 256.0 * (float) ((integer)(global.y / 256.0)), 0.0>;
        targetsimlocal = global - targetsimcorner;
        targetsimcorner /= 256;
        string url = "https://cap.secondlife.com/cap/0/b713fe80-283b-4585-af4d-a3b7d9a32492?var=region&grid_x=" + (string)llRound(targetsimcorner.x) + "&grid_y=" + (string)llRound(targetsimcorner.y);
        ds = llHTTPRequest(url, [], "");
        while(llGetInventoryNumber(INVENTORY_LANDMARK) > 0) llRemoveInventory(llGetInventoryName(INVENTORY_LANDMARK, 0));
    }
}