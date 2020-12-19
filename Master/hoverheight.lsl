float hoverheight = 0.0;

setheight()
{
    llOwnerSay("@adjustheight:" + (string)hoverheight + "=force");
}

default
{
    attach(key id)
    {
        if(id)
        {
            setheight();
        }
    }

    touch_start(integer total_number)
    {
        string name = llGetLinkName(llDetectedLinkNumber(0));
        if(name == "reset")
        {
            hoverheight = 0.0;
        }
        else if(name == "++")
        {
            hoverheight += 3.0;
        }
        else if(name == "+")
        {
            hoverheight += 0.5;
        }
        else if(name == "--")
        {
            hoverheight -= 3.0;
        }
        else if(name == "-")
        {
            hoverheight -= 0.5;
        }
        setheight();
    }
}
