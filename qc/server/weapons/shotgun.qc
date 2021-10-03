/*
  Copyright 2018 Joshua D. Sawyer

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

  3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

string SHOTGUN__NAME = "Shotgun";
//string SHOTGUN__VIEWMODEL = "progs/v_shot.mdl";
string SHOTGUN__VIEWMODEL = "models/mg42.mdl";
int SHOTGUN__MAX_AMMO = 25;
int SHOTGUN__TARGET_SLOT = 1;

bool shotgun__wield( weapon_cli_t * cli )
{
  print( "Wielded shotgun\n" );
  cli->holder.weaponmodel = SHOTGUN__VIEWMODEL;
  return TRUE;
}

bool shotgun__begin( weapon_cli_t * cli )
{
  //print("SHOT\n");
  damage_info_t damage =
    {
      world,
      8,
      cli->holder,
      cli->holder,
      FL_Null,
      0,
      TRUE
    };
  
  hitscan_blast_square( cli->holder.origin, cli->holder.v_angle, 8192, '0.08 0.08 0', 1, &damage );
  
  cli->time_when_ready = time + (60.0 / 1200.0);
  
  sound (cli->holder, CHAN_WEAPON, "sounds/guns/mg-shot2.wav", 1, ATTN_NORM);
  
  return TRUE;
}

bool shotgun__frame( weapon_cli_t * cli )
{
  //print("SHOTFRAME\n");
  //return FALSE;

  return shotgun__begin( cli );
}

void shotgun__end( weapon_cli_t * cli )
{
  //print("SHOTEND\n");
  return;
}

bool shotgun__holster( weapon_cli_t * cli )
{
  return TRUE;
}

weapon_def_t weapon__shotgun =
  {
    SHOTGUN__NAME,
    SHOTGUN__VIEWMODEL,
    SHOTGUN__MAX_AMMO,
    SHOTGUN__TARGET_SLOT,
    shotgun__wield,
    shotgun__begin,
    shotgun__frame,
    shotgun__end,
    shotgun__holster
  };
