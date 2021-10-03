/*
  Copyright 2018 Joshua D. Sawyer

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

  3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

string SPAWNER__NAME = "Spawner Tool";
string SPAWNER__VIEWMODEL = "models/wand.mdl";
int SPAWNER__MAX_AMMO = 0;
int SPAWNER__TARGET_SLOT = 2;

void spawner__place_entity( entity holder, vector wishpos, entity target )
{
  tracebox( wishpos, target.mins, target.maxs, holder.origin, FALSE, target );
  tracebox( trace_endpos, target.mins, target.maxs, wishpos, FALSE, target );

  setorigin( target, trace_endpos );
}

enum
  {
    SPAWNER__NO_ENT,
    SPAWNER__TARGET_PLAYER,
    SPAWNER__ENUM_MAX,
  };

void pain_dummy_player( damage_info_t * damage )
{
  sprint( damage.attacker, 9000, "Ouchie, ", ftos( damage->amount ), " damage!\n" );
}

void die_dummy_player( damage_info_t * damage )
{
  sprint( damage.attacker, 9000, "Dead, from ", ftos( damage->amount ), " damage!\n" );
}

void setup_newspawn_player( entity tgt );
entity spawner__spawn_entity( entity holder, vector wishpos, int target_entity_enum )
{
  if( target_entity_enum == SPAWNER__NO_ENT )
    {
      return world;
    }

  entity new = spawn();
  
  switch( target_entity_enum )
    {
    default:
      print_float( world, "spawn error", target_entity_enum );
    case SPAWNER__TARGET_PLAYER:
      //setup_newspawn_player( new );
      //new.SendEntity = 0;
      new.movetype = MOVETYPE_WALK;
      new.solid = SOLID_SLIDEBOX;
      new.takedamage = DAMAGE_AIM;
      new.health = 200;
      new.pain = pain_dummy_player;
      new.die = die_dummy_player;
      setmodel( new, "progs/player.mdl" );
      setsize( new, VEC_HULL_MIN, VEC_HULL_MAX );
      print("spawn player\n");
      break;
    }

  spawner__place_entity( holder, wishpos, new );

  print("spawn\n");
  return new;
}

void spawner__print_menu( entity tgt )
{
  const float menu_entry_count;
  

  string print_str = "Spawn:\n";
  
  print_str = strcat( print_str, ftos( SPAWNER__TARGET_PLAYER ), ") \n" );

  centerprint( tgt, print_str );
}

bool spawner__wield( weapon_cli_t * cli )
{
  print( "Wielded spawner\n" );
  cli->holder.weaponmodel = SPAWNER__VIEWMODEL;
  return TRUE;
}

bool spawner__begin( weapon_cli_t * cli )
{
  cli->holder.weapon_frame_held = TRUE;

  cli->holder.time_when_ready = time;

  cli->holder.weapon_frame_held = TRUE;

  return TRUE;
}

bool spawner__frame( weapon_cli_t * cli )
{
  print("sframe\n");
  
  cli->holder.time_when_ready = time + 0.2;

  spawner__print_menu( cli->holder );

  if( self.next_weapon_impulse == 0 && self.next_weapon_impulse < SPAWNER__ENUM_MAX )
    {
      print("true\n");
      return TRUE;
    }

  print_float( world, "impulse", cli->holder.next_weapon_impulse );
  
  makevectors( cli->holder.v_angle );

  traceline( cli->holder.origin, cli->holder.origin + 8000*v_forward, FALSE, self );
  
  spawner__spawn_entity( cli->holder, trace_endpos, self.next_weapon_impulse );

  cli->holder.weapon_frame_held = FALSE;

  cli->holder.next_weapon_impulse = 0;
  
  return FALSE;
}

void spawner__end( weapon_cli_t * cli )
{
}

bool spawner__holster( weapon_cli_t * cli )
{
  return TRUE;
}

weapon_def_t weapon__spawner =
  {
    SPAWNER__NAME,
    SPAWNER__VIEWMODEL,
    SPAWNER__MAX_AMMO,
    SPAWNER__TARGET_SLOT,
    spawner__wield,
    spawner__begin,
    spawner__frame,
    spawner__end,
    spawner__holster
  };
