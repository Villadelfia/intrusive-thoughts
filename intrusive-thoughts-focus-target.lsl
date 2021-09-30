float currentAlpha = 0.0;
vector angleVector = <0,0,1>;
integer point = -1;

update()
{
    vector x = llVecNorm(angleVector * llGetLocalRot());
    string desc = (string)x.x + "/" + (string)x.y + "/" +(string)x.z;
    llSetObjectDesc(desc);
}

updateVector()
{
    switch(point)
    {
        case 1:
        case 18:
        case 19:
        case 42:
        {
            angleVector = <-1,0,0>;
            break;
        }
        case 20:
        case 21:
        case 41:
        {
            angleVector = <1,0,0>;
            break;
        }
        case 6:
        case 9:
        {
            angleVector = <0,1,0>;
            break;
        }
        default:
        {
            angleVector = <0,0,1>;
            break;
        }
    }
}

start()
{
    llOwnerSay("Click me to toggle visibility. Any IT Slave that focuses on you will look at me. They will be made to look approximately at the white face.");
    point = llGetAttached();
    llSetTimerEvent(0.5);
    updateVector();
    update();
    currentAlpha = llGetAlpha(ALL_SIDES);
}

default
{
    state_entry()
    {
        start();
    }

    on_rez(integer start_param)
    {
        start();
    }

    touch_start(integer num_detected)
    {
        if(llDetectedKey(0) != llGetOwner()) return;
        if(currentAlpha == 0.0) currentAlpha = 1.0;
        else                    currentAlpha = 0.0;
        llSetAlpha(currentAlpha, ALL_SIDES);
    }

    timer()
    {
        update();
    }
}