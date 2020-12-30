default
{
    state_entry()
    {
        llSetTextureAnim(ANIM_ON | PING_PONG | SCALE | SMOOTH | LOOP, ALL_SIDES, 0, 0, 0.975, .05, 0.05);
        llLoopSound("5f6b61f1-d55e-236f-8173-a4a25695f26d", 0.5);
    }
}