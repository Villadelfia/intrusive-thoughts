#define MANTRA_CHANNEL   -216684563
#define PING_CHANNEL     -216684564
#define DIALOG_CHANNEL   -219755312
#define HUD_SPEAK_CHANNEL 166845632
#define RLV_CHECK_CHANNEL 166845633
#define VOICE_CHANNEL     166845631
#define SPEAK_CHANNEL     166845632
#define RLV_CHANNEL       166845630
#define RLVRC           -1812221819
#define API_RESET                -1
#define API_SELF_DESC            -2
#define API_SELF_SAY             -3
#define API_SAY                  -4
#define API_ONLY_OTHERS_SAY      -5
#define API_BLIND_TOGGLE         -6
#define API_DEAF_TOGGLE          -7
#define API_MUTE_TOGGLE          -8
#define API_FOCUS_TOGGLE         -9
string VERSION_S = "Intrusive Thoughts Slave v4.8";
string VERSION_C = "Intrusive Thoughts Controller v4.8";

integer startswith(string haystack, string needle)
{
    return llDeleteSubString(haystack, llStringLength(needle), 0x7FFFFFF0) == needle;
}

integer contains(string haystack, string needle)
{
    return 0 <= llSubStringIndex(haystack, needle);
}

integer endswith(string haystack, string needle)
{
    return llDeleteSubString(haystack, 0x8000000F, ~llStringLength(needle)) == needle;
}

integer getstringbytes(string msg)
{
    return (llStringLength((string)llParseString2List(llStringToBase64(msg), ["="], [])) * 3) >> 2;
}

string slurl()
{
    vector pos = llGetPos();
    return "http://maps.secondlife.com/secondlife/" + llEscapeURL(llGetRegionName()) + "/" + (string)llRound(pos.x) + "/" + (string)llRound(pos.y) + "/" + (string)llRound(pos.z) + "/";
}

string strreplace(string source, string pattern, string replace) 
{
    while (llSubStringIndex(source, pattern) > -1) 
    {
        integer len = llStringLength(pattern);
        integer pos = llSubStringIndex(source, pattern);
        if (llStringLength(source) == len) { source = replace; }
        else if (pos == 0) { source = replace+llGetSubString(source, pos+len, -1); }
        else if (pos == llStringLength(source)-len) { source = llGetSubString(source, 0, pos-1)+replace; }
        else { source = llGetSubString(source, 0, pos-1)+replace+llGetSubString(source, pos+len, -1); }
    }
    return source;
}

list orderbuttons(list buttons)
{
    return llList2List(buttons, -3, -1) + llList2List(buttons, -6, -4)
         + llList2List(buttons, -9, -7) + llList2List(buttons, -12, -10);
}

integer random(integer min, integer max)
{
    return min + (integer)(llFrand(max - min + 1));
}