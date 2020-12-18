#define MANTRA_CHANNEL -216684563

list locations = [
    "tflab",    "Bedos",       "97",  "99",  "291",
    "tf",       "Bedos",       "97",  "99",  "291",
    "home",     "Bedos",       "96",  "99",  "198",
    "house",    "Bedos",       "96",  "99",  "198",
    "dungeon",  "Bedos",       "95", "104",  "235",
    "mystwood", "Quiet Riot", "141",  "95",   "55",
    "mw",       "Quiet Riot", "141",  "95",   "55",
    "silenced", "San Fierro", "218",  "15", "2422",
    "hbc",      "Myanimo",     "96",  "20",  "903"
];

integer startswith(string haystack, string needle)
{
    return llDeleteSubString(haystack, llStringLength(needle), 0x7FFFFFF0) == needle;
}

dotp(string region, string x, string y, string z)
{
    llRegionSay(MANTRA_CHANNEL, "@tploc=y,unsit=y,tpto:" + region + "/" + x + "/" + y  + "/" + z + "=force");
    llSleep(1.0);
    llOwnerSay("@tploc=y,unsit=y,tpto:" + region + "/" + x + "/" + y  + "/" + z + "=force");
}

tpme(string region, string x, string y, string z)
{
    llOwnerSay("@tploc=y,unsit=y,tpto:" + region + "/" + x + "/" + y  + "/" + z + "=force");
}

default
{
    state_entry()
    {
        llListen(1, "", llGetOwner(), "");
    }

    changed(integer change)
    {
        if(change & CHANGED_OWNER)
        {
            llResetScript();
        }
    }

    listen(integer c, string n, key id, string m)
    {
        if(startswith(llToLower(m), "tpto") == FALSE && startswith(llToLower(m), "tpme") == FALSE) return;
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