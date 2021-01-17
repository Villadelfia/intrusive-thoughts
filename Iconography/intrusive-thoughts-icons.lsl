#include <IT/globals.lsl>
list namedParticles = [
    "yes",   "f736cd9a-578c-c898-c64d-ec6eae9022f8", <0.0, 1.0, 0.0>,
    "no",    "f441dea9-c32c-bc67-e1ae-43061b772529", <1.0, 0.0, 0.0>,
    "plus",  "61dd57f7-4250-1c61-4a0d-ba5e4ab03cae", ZERO_VECTOR,
    "minus", "5f474007-45a9-48ae-5e01-8f4cf6b37bad", ZERO_VECTOR
];

vector configuredSize    = <0.25, 0.25, 0.0>;
vector configuredColor   = <1.0, 1.0, 1.0>;
float configuredDuration = 10.0;

emitParticle(string texture, vector partcolor, vector partsize, float partduration)
{
    list partParams = [
        PSYS_PART_FLAGS, PSYS_PART_EMISSIVE_MASK | PSYS_PART_INTERP_COLOR_MASK | PSYS_PART_FOLLOW_SRC_MASK,
        PSYS_PART_START_COLOR, partcolor, PSYS_PART_END_COLOR, partcolor,
        PSYS_PART_START_ALPHA, 1.0, PSYS_PART_END_ALPHA, 0.0,
        PSYS_PART_START_SCALE, partsize, PSYS_PART_END_SCALE, partsize,
        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_DROP,
        PSYS_SRC_BURST_PART_COUNT, 1,
        PSYS_PART_BLEND_FUNC_DEST, PSYS_PART_BF_ONE,
        PSYS_SRC_BURST_RATE, partduration,
        PSYS_PART_MAX_AGE, partduration,
        PSYS_SRC_MAX_AGE, partduration,
        PSYS_SRC_TEXTURE, texture
    ];
    llParticleSystem(partParams);
    llSetTimerEvent(partduration);
}

preload()
{
    integer max = llGetNumberOfPrims();
    integer curr = 2;
    integer face = 0;
    integer textureidx = 1;
    integer textureamt = llGetListLength(namedParticles);
    while(textureidx < textureamt && curr <= max)
    {
        string tex = llList2String(namedParticles, textureidx);
        textureidx += 3;
        llSetLinkPrimitiveParamsFast(curr, [PRIM_TEXTURE, face, tex, <0.0, 0.0, 0.0>, <1.0, 1.0, 0.0>, 0.0, PRIM_ALPHA_MODE, face, PRIM_ALPHA_MODE_MASK, 255]);
        face++;
        if(face == 8)
        {
            face = 0;
            curr++;
        }
    }
}

default
{
    changed(integer change)
    {
        if(change & CHANGED_OWNER) llResetScript();
    }

    on_rez(integer start)
    {
        llOwnerSay("Say '/1help' or just click [secondlife:///app/chat/1/help here] to get a list of commands the iconography system supports.");
        preload();
    }

    state_entry()
    {
        llListen(VOICE_CHANNEL,   "", llGetOwner(), "");
        llListen(COMMAND_CHANNEL, "", llGetOwner(), "");
        llOwnerSay("Say '/1help' or just click [secondlife:///app/chat/1/help here] to get a list of commands the iconography system supports.");
        preload();
    }

    listen(integer c, string n, key id, string m)
    {
        integer i;
        integer l;
        m = llToLower(m);
        if(m == "help")
        {
            string old = llGetObjectName();
            llSetObjectName("");
            llOwnerSay("You have the following commands at your disposal:");
            llOwnerSay(" - [secondlife:///app/chat/1/help /1help]: This list of commands.");
            llOwnerSay(" - /1color r g b: Set the color of your icon to an RGB color. R, g, and b are values between 0 and 255. Note that some icons (like the yes and no icons) override this color.");
            llOwnerSay(" - /1size s: Set the size of your icon. S is a number from 0.01 to 1.0");
            llOwnerSay(" - /1duration t: Set the duration of your icon. T is a number in seconds from 1.0 to 60.0");
            llOwnerSay(" - /1icon: This will display the icon with the matching name. For example /1yes would show the 'yes' icon.");
            llOwnerSay(" ");
            llOwnerSay("Available icons are:");
            l = llGetListLength(namedParticles);
            for(i = 0; i < l; i += 3) llOwnerSay(" - [secondlife:///app/chat/1/" + llList2String(namedParticles, i) + " " + llList2String(namedParticles, i) + "]");
            llSetObjectName(old);
        }
        else if(startswith(m, "duration"))
        {
            m = llDeleteSubString(m, 0, 8);
            float f = (float)m;
            if(f < 1.00) f = 1.00;
            if(f > 60.0) f = 60.0;
            configuredDuration = f;
            llOwnerSay("Particle duration set to " + m + " seconds.");
        }
        else if(startswith(m, "size"))
        {
            m = llDeleteSubString(m, 0, 4);
            float f = (float)m;
            if(f < 0.01) f = 0.01;
            if(f > 1.00) f = 1.00;
            configuredSize = <1.0, 1.0, 0.0> * f;
            llOwnerSay("Particle size set to " + m + " meters.");
        }
        else if(startswith(m, "color"))
        {
            m = llDeleteSubString(m, 0, 5);
            list elems = llParseString2List(m, [" "], []);
            if(llGetListLength(elems) == 3)
            {
                configuredColor.x = llList2Integer(elems, 0) / 255.0;
                configuredColor.y = llList2Integer(elems, 1) / 255.0;
                configuredColor.z = llList2Integer(elems, 2) / 255.0;
                llOwnerSay("Particle color set to <" + llList2String(elems, 0) + ", " + llList2String(elems, 1) + ", " + llList2String(elems, 2) + ">.");
            }
        }

        l = llGetListLength(namedParticles);
        for(i = 0; i < l; i += 3)
        {
            if(m == llList2String(namedParticles, i))
            {
                string texture = llList2String(namedParticles, i+1);
                vector color   = llList2Vector(namedParticles, i+2);
                if(color == ZERO_VECTOR) color = configuredColor;
                emitParticle(texture, color, configuredSize, configuredDuration);
            }
        }
    }

    timer()
    {
        llSetTimerEvent(0.0);
        llParticleSystem([]);
    }
}