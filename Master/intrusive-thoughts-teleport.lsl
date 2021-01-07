#include <IT/globals.lsl>
string target = "";
string tptarget = "";
list locations = [];
integer configured = FALSE;
vector targetsimcorner;
vector targetsimlocal;
key ds;
integer vok = FALSE;
integer ook = FALSE;
key lockedavatar;
string lockedname;

dotp(string region, string x, string y, string z)
{
    llOwnerSay("Teleporting you and your slaves to: " + slurlp(region, x, y, z));
    llRegionSay(COMMAND_CHANNEL, "*tpto " + region + "/" + x + "/" + y  + "/" + z);
    ook = FALSE;
    vok = FALSE;
    llMessageLinked(LINK_SET, M_API_DOTP, "@tploc=y|@unsit=y|@tpto:" + region + "/" + x + "/" + y  + "/" + z + "=force|!release", (key)region);
    tptarget = "@tploc=y,unsit=y,tpto:" + region + "/" + x + "/" + y  + "/" + z + "=force";
}

tpme(string region, string x, string y, string z)
{
    llOwnerSay("Teleporting you to: " + slurlp(region, x, y, z));
    ook = FALSE;
    vok = FALSE;
    llMessageLinked(LINK_SET, M_API_DOTP, "@tploc=y|@unsit=y|@tpto:" + region + "/" + x + "/" + y  + "/" + z + "=force|!release", (key)region);
    tptarget = "@tploc=y,unsit=y,tpto:" + region + "/" + x + "/" + y  + "/" + z + "=force";
}

send(string region, string x, string y, string z)
{
    if(lockedavatar == llGetOwner())
    {
        llOwnerSay("Teleporting you to: " + slurlp(region, x, y, z));
        ook = FALSE;
        vok = FALSE;
        llMessageLinked(LINK_SET, M_API_DOTP, "@tploc=y|@unsit=y|@tpto:" + region + "/" + x + "/" + y  + "/" + z + "=force", (key)region);
        tptarget = "@tploc=y,unsit=y,tpto:" + region + "/" + x + "/" + y  + "/" + z + "=force";
    }
    else
    {
        llOwnerSay("Teleporting '" + lockedname + "' to: " + slurlp(region, x, y, z));
        llRegionSayTo(lockedavatar, RLVRC, "tpt," + (string)lockedavatar + ",@tploc=y|@unsit=y|@tpto:" + region + "/" + x + "/" + y  + "/" + z + "=force");
    }
}

givemenu()
{
    llOwnerSay("Teleportation options:");
    integer i;
    integer l = llGetListLength(locations);
    for(i = 0; i < l; i += 5)
    {
        string dest = llList2String(locations, i);
        string say = dest + " — [secondlife:///app/chat/1/tpto%20" + dest + " (together)] [secondlife:///app/chat/1/tpme%20" + dest + " (alone)]";
        if(lockedavatar) say = say + " [secondlife:///app/chat/1/send%20" + dest + " (send locked avatar)]";
        llOwnerSay(say);
    }
    llOwnerSay(" ");
    llOwnerSay("You may also use the following commands:");
    llOwnerSay("/1tpto <slurl> — Teleport with your slaves to the SLURL");
    llOwnerSay("/1tpme <slurl> — Teleport alone to the SLURL");
    if(lockedavatar) llOwnerSay("/1send <slurl> — Teleport the locked avatar to the SLURL");
    llOwnerSay("—or— drop a landmark onto the HUD to teleport there with your slaves");
}

default
{
    state_entry()
    {
        llListen(COMMAND_CHANNEL, "", llGetOwner(), "");
    }

    changed(integer change)
    {
        if(change & CHANGED_INVENTORY)
        {
            if(llGetInventoryNumber(INVENTORY_LANDMARK) == 0) return;
            ds = llRequestInventoryData(llGetInventoryName(INVENTORY_LANDMARK, 0));
        }
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == M_API_CONFIG_DONE) 
        {
            configured = TRUE;
        }
        else if(num == M_API_CONFIG_DATA && str == "tp")
        {
            if(configured)
            {
                locations = [];
                configured = FALSE;
            }
            locations += llParseString2List((string)id, [","], []);
            llOwnerSay(VERSION_M + ": Loaded teleport location " + llList2String(locations, -5));
        }
        if(num == M_API_TPOK_O) 
        {
            ook = TRUE;
            if(ook == TRUE && vok == TRUE) llOwnerSay(tptarget);
        }
        else if(num == M_API_TPOK_V) 
        {
            vok = TRUE;
            if(ook == TRUE && vok == TRUE) llOwnerSay(tptarget);
        }
        if(num == M_API_BUTTON_PRESSED)
        {
            if(str == "tp") givemenu();
        }
        else if(num == M_API_LOCK)
        {
            lockedavatar = id;
            lockedname = str;
        }
    }

    listen(integer c, string n, key id, string m)
    {
        if(startswith(llToLower(m), "dotp") == FALSE && 
           startswith(llToLower(m), "tpto") == FALSE && 
           startswith(llToLower(m), "tpme") == FALSE &&
           startswith(llToLower(m), "send") == FALSE) return;
        string type = llToLower(llList2String(llParseString2List(m, [" "], []), 0));
        integer justme = type == "tpme";
        integer sendl  = type == "send";
        if(sendl)
        {
            if(lockedavatar);
            else return;
        }

        m = llDeleteSubString(m, 0, llStringLength("tpto"));
        if(llListFindList(locations, [llToLower(m)]) != -1)
        {
            integer i = llListFindList(locations, [llToLower(m)]);
            string region = (string)locations[i+1];
            string x = (string)locations[i+2];
            string y = (string)locations[i+3];
            string z = (string)locations[i+4];
            if(justme)     tpme(region, x, y, z);
            else if(sendl) send(region, x, y, z);
            else           dotp(region, x, y, z);
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
            if(justme)     tpme(region, x, y, z);
            else if(sendl) send(region, x, y, z);
            else           dotp(region, x, y, z);
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