#include <IT/globals.lsl>
key primary = NULL_KEY;
list owners = [];
integer publicaccess = FALSE;
integer groupaccess = FALSE;

list statements = [];
integer timerMin = 0;
integer timerMax = 0;
string name = "";
integer tempDisable = FALSE;

integer intensity = 0;
string statement = "";

softReset()
{
    tempDisable = TRUE;
    if(statement != "")
    {
        statement = "";
        llOwnerSay("@clear");
        llOwnerSay("@detach=n");
        llMessageLinked(LINK_SET, S_API_MANTRA_DONE, "", NULL_KEY);
    }
    checkSetup();
}

hardReset()
{
    tempDisable = FALSE;
    name = "";
    statements = [];
    timerMin = 0;
    timerMax = 0;
    checkSetup();
}

checkSetup()
{
    if(tempDisable == TRUE || timerMax == 0)
    {
        llSetTimerEvent(0.0);
        sensortimer(0.0);
    }
    else
    {
        llSetTimerEvent(random(timerMin * 60, timerMax * 60));
        sensortimer(0.0);
    }
}

doMantra()
{
    llMessageLinked(LINK_SET, S_API_MANTRA_START, "", NULL_KEY);
    llSetTimerEvent(0.0);
    llOwnerSay("@clear");
    llOwnerSay("@detach=n,redirchat:" + (string)(VOICE_CHANNEL+1) + "=add,rediremote:" + (string)(VOICE_CHANNEL+1) + "=add,sendchannel=n,sendchannel:" + (string)(VOICE_CHANNEL+1) + "=add,sendchannel:" + (string)COMMAND_CHANNEL + "=add");
    llOwnerSay("@clear=setsphere,setsphere=n,setsphere_distmin:0=force,setsphere_valuemin:0=force,setsphere_distmax:128=force,setsphere_tween:5=force,setsphere_distmax:16=force,setsphere_tween=force");
    llOwnerSay("@fly=n,temprun=n,alwaysrun=n,sendgesture=n,tplocal=n,tplm=n,tploc=n,tplure=n,sittp=n,tprequest=n,tprequest:" + (string)primary + "=add,tplure:" + (string)primary + "=add,accepttp:" + (string)primary + "=add,accepttprequest:" + (string)primary + "=add");
    if(llGetAgentInfo(llGetOwner()) & AGENT_SITTING) llOwnerSay("@unsit=n");
    else                                             llOwnerSay("@sit=n");
    intensity = 0;
    statement = llStringTrim(llList2String(statements, llFloor(llFrand(llGetListLength(statements)))), STRING_TRIM);
    string old = llGetObjectName();
    llSetObjectName("");
    llOwnerSay("You feel a compulsion to say *exactly* '" + statement + "'...");
    llSetObjectName(old);
    sensortimer(30.0);
}

checkMantra(string m)
{
    m = llStringTrim(m, STRING_TRIM);
    if(m == statement)
    {
        statement = "";
        llSetTimerEvent(0.0);
        sensortimer(0.0);
        llOwnerSay("@clear");
        string old = llGetObjectName();
        llSetObjectName("");
        llOwnerSay("The compulsion to repeat the mantra fades... For now.");
        if(name == "") llSetObjectName(llGetDisplayName(llGetOwner()));
        else           llSetObjectName(name);
        llSay(0, m);
        llSetObjectName(old);
        llMessageLinked(LINK_SET, S_API_MANTRA_DONE, "", NULL_KEY);
        checkSetup();
    }
    else
    {
        string old = llGetObjectName();
        llSetObjectName("");
        llOwnerSay("A mantra is ringing through your mind and you feel compelled to repeat it before saying anything else. It's '" + statement + "'...");
        llSetObjectName(old);
    }
}

intensify()
{
    string old = llGetObjectName();
    llSetObjectName("");
    llOwnerSay("You feel a compulsion to say *exactly* '" + statement + "'... The compulsion grows...");
    llSetObjectName(old);
    intensity++;
    if(intensity == 1) llOwnerSay("@clear=setsphere,setsphere=n,setsphere_distmin:0=force,setsphere_valuemin:0=force,setsphere_distmax:16=force,setsphere_tween:5=force,setsphere_distmax:8=force,setsphere_tween=force");
    if(intensity == 2) llOwnerSay("@clear=setsphere,setsphere=n,setsphere_distmin:0=force,setsphere_valuemin:0=force,setsphere_distmax:8=force,setsphere_tween:5=force,setsphere_distmax:4=force,setsphere_tween=force,interact=n");
    if(intensity == 3) llOwnerSay("@clear=setsphere,setsphere=n,setsphere_distmin:0=force,setsphere_valuemin:0=force,setsphere_distmax:4=force,setsphere_tween:5=force,setsphere_distmax:2=force,setsphere_tween=force,showinv=n,share=n,shownametags=n");
    if(intensity == 4) llOwnerSay("@clear=setsphere,setsphere=n,setsphere_distmin:0=force,setsphere_valuemin:0=force,setsphere_distmax:2=force,setsphere_tween:5=force,setsphere_distmax:1=force,setsphere_tween=force,defaultwear=n,addoutfit=n,remoutfit=n,addattach=n,remattach=n,shownames=n");
    if(intensity == 5) llOwnerSay("@clear=setsphere,setsphere=n,setsphere_distmin:0=force,setsphere_valuemin:0=force,setsphere_distmax:1=force,setsphere_tween:5=force,setsphere_distmax:0=force,setsphere_tween=force,sendim:20=n,recvim:20=n,sendim:" + (string)primary + "=add,recvim:" + (string)primary + "=add,shownearby=n,showhovertextall=n");
    if(intensity == 6) llOwnerSay("@clear=setsphere,setsphere=n,setsphere_distmin:0=force,setsphere_valuemin:0=force,setsphere_distmax:1=force,setsphere_tween:5=force,setsphere_distmax:0=force,setsphere_tween=force,recvchat=n,recvemote=n");
}

default
{
    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == S_API_RLV_CHECK)
        {
            tempDisable = FALSE;
            checkSetup();
        }
        else if(num == S_API_OWNERS)
        {
            owners = [];
            list new = llParseString2List(str, [","], []);
            integer n = llGetListLength(new);
            while(~--n)
            {
                owners += [(key)llList2String(new, n)];
            }
            primary = id;
        }
        else if(num == S_API_OTHER_ACCESS)
        {
            publicaccess = (integer)str;
            groupaccess = (integer)((string)id);
        }
        else if(num == S_API_EMERGENCY)
        {
            softReset();
        }
    }

    state_entry()
    {
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
        setupVoiceChannel();
        llListen(VOICE_CHANNEL+1, "", llGetOwner(), "");
    }

    attach(key id)
    {
        if(id == NULL_KEY)
        {
            llSetTimerEvent(0.0);
            sensortimer(0.0);
        }
    }

    listen(integer c, string n, key k, string m)
    {
        if(c == MANTRA_CHANNEL)
        {
            if(!isowner(k)) return;
            if(m == "RESET")
            {
                hardReset();
            }
            else if(m == "END")
            {
                ownersay(k, "[mantra]: " + (string)(llGetFreeMemory() / 1024.0) + "kb free.", HUD_SPEAK_CHANNEL);
            }
            else if(startswith(m, "MANTRA_TIMER"))
            {
                list t = llParseString2List(m, [" "], []);
                timerMin = (integer)llList2String(t, 1);
                timerMax = (integer)llList2String(t, 2);
                checkSetup();
            }
            else if(startswith(m, "MANTRA_PHRASES"))
            {
                statements += [llDeleteSubString(m, 0, llStringLength("MANTRA_PHRASES"))];
                checkSetup();
            }
        }
        else
        {
            checkMantra(m);
        }
    }

    no_sensor()
    {
        intensify();
    }

    timer()
    {
        doMantra();
    }
}