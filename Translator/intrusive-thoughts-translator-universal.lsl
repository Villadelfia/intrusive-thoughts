#define SPEAK_CHANNEL   166845632
key owner = NULL_KEY;

integer getStringBytes(string msg)
{
    return (llStringLength((string)llParseString2List(llStringToBase64(msg), ["="], [])) * 3) >> 2;
}

handleSelfSay(string name, string message)
{
    string currentObjectName = llGetObjectName();
    llSetObjectName(name);
    integer bytes = getStringBytes(message);
    while(bytes > 0)
    {
        if(bytes <= 1024)
        {
            llOwnerSay(message);
            bytes = 0;
        }
        else
        {
            integer offset = 0;
            while(bytes >= 1024) bytes = getStringBytes(llGetSubString(message, 0, --offset));
            llOwnerSay(message);
            message = llDeleteSubString(message, 0, offset);
            bytes = getStringBytes(message);
        }
    }
    llSetObjectName(currentObjectName);
}

default
{
    state_entry()
    {
        llListen(SPEAK_CHANNEL, "", NULL_KEY, "");
    }

    listen(integer c, string n, key k, string m)
    {
        handleSelfSay(n, m);
    }
}