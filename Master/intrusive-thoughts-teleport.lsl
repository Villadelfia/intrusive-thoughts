#include <IT/globals.lsl>
string target = "";
string tptarget = "";
list locations = [];

dotp(string region, string x, string y, string z)
{
    llRegionSay(MANTRA_CHANNEL, "tpto " + region + "/" + x + "/" + y  + "/" + z);
    llMessageLinked(LINK_SET, API_DOTP, "@tploc=y|@unsit=y|@tpto:" + region + "/" + x + "/" + y  + "/" + z + "=force", (key)region);
    tptarget = "@tploc=y,unsit=y,tpto:" + region + "/" + x + "/" + y  + "/" + z + "=force";
}

tpme(string region, string x, string y, string z)
{
    llMessageLinked(LINK_SET, API_DOTP, "@tploc=y|@unsit=y|@tpto:" + region + "/" + x + "/" + y  + "/" + z + "=force", (key)region);
    tptarget = "@tploc=y,unsit=y,tpto:" + region + "/" + x + "/" + y  + "/" + z + "=force";
}

givemenu()
{
    llOwnerSay("Teleportation options:");
    integer i;
    integer l = llGetListLength(locations);
    for(i = 0; i < l; i += 5)
    {
        string dest = llList2String(locations, i);
        llOwnerSay(dest + " — [secondlife:///app/chat/1/tpto%20" + dest + " (together)] [secondlife:///app/chat/1/tpme%20" + dest + " (alone)].");
    }
    if(l > 0)
    {
        llOwnerSay(" ");
        llOwnerSay("You may also use the following commands:");
    }
    llOwnerSay("/1tpto <slurl> — Teleport with your slaves to the SLURL.");
    llOwnerSay("/1tpme <slurl> — Teleport alone to the SLURL.");
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
            llResetScript();
        }
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == API_TPOK) llOwnerSay(tptarget);
        if(num == API_STARTUP_DONE) llListen(1, "", llGetOwner(), "");
        if(num == API_CONFIG_DATA && str == "tp")
        {
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
}