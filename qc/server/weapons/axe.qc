/*
  Copyright 2018 Joshua D. Sawyer

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

  3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

string AXE__NAME = "Axe";
string AXE__VIEWMODEL = "progs/v_axe.mdl";
int AXE__MAX_AMMO = 0;
int AXE__TARGET_SLOT = 0;

bool axe__wield( weapon_cli_t * cli )
{
  print( "Wielded axe\n" );
  precache_model( AXE__VIEWMODEL );
  cli->holder.weaponmodel = AXE__VIEWMODEL;
  return TRUE;
}

bool axe__attack( weapon_cli_t * cli )
{
  makevectors( cli->holder.v_angle );

  damage_info_t damage =
    {
      world,
      10,
      cli->holder,
      cli->holder,
      FL_Null,
      0,
      FALSE
    };

  hitscan_attack( cli->holder.origin, v_forward, 1000, &damage );
  
  cli->time_when_ready = time + 0.5;
  print(ftos(time));
  print(" attack\n");
  return TRUE;
}

void axe__end( weapon_cli_t * cli )
{
}

bool axe__holster( weapon_cli_t * cli )
{
  return TRUE;
}

weapon_def_t weapon__axe =
  {
    AXE__NAME,
    AXE__VIEWMODEL,
    AXE__MAX_AMMO,
    AXE__TARGET_SLOT,
    axe__wield,
    axe__attack,
    axe__attack,
    axe__end,
    axe__holster
  };
