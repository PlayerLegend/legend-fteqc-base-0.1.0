/*
  Copyright 2018 Joshua D. Sawyer

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

  3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
/*
    misc-subs.qc<server_qc>

    Miscelaneous functions, generally these get used anywhere and have
    no proper place
*/
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

//
//    Debug
//

void print_vec( string title, vector v )
{
  string p = strcat( title, ": ", vtos( v ), "\n" );

  if( self != world )
    {
      sprint( self, 9000, p );
    }
  else
    {
      print( p );
    }
}

void print_float( entity e, string title, float f )
{
  string p = strcat( title, ": ", ftos( f ), "\n" );
  
  if( e != world )
    {
      sprint( e, 9000, p );
    }
  else
    {
      print( p );
    }
}

void print_message( string message )
{
  string p = strcat( message, "\n" );
  
  if( self != world )
    {
      sprint( self, 9000, p );
    }
  else
    {
      print( p );
    }
}

//
//    safety functions
//

void safe_remove( entity tgt )
{
  array__free_members( &(tgt.held_weapons) );
  clear_entity_array_t( &(tgt.target_list) );
  remove( tgt );
}

#define remove safe_remove

//
//    network
//

void WriteVector( float to, vector vec )
//    write three coordinates
{
  WriteCoord( to, vec_x );
  WriteCoord( to, vec_y );
  WriteCoord( to, vec_z );
}

void SendEntity__send_header( float type, float changedflags )
//    send a generic header, always use this before sending data in SendEntity callbacks
{
  WriteByte( MSG_ENTITY, type );
  WriteByte( MSG_ENTITY, changedflags );
  WriteFloat( MSG_ENTITY, time );
}


//
//    weapons
//

weapon_cli_t * get_weapon_cli( entity holder, int slot )
{
  return (weapon_cli_t*)array__get_index_data( &(holder.held_weapons), slot );
}

bool is_weapon_ready( weapon_cli_t * cli )
{
  if( cli == __NULL__ )
    {
      return FALSE;
    }

  if( cli->holder.weapon_frame_active || cli->holder.weapon_frame_held )
    {
      return FALSE;
    }

  if( time < cli->time_when_ready )
    {
      return FALSE;
    }
  
  return TRUE;
}

bool holster_weapon( entity holder )
{
  if( holder.current_weapon_cli == __NULL__ )
    {
      return TRUE;
    }
  
  if( !is_weapon_ready( holder.current_weapon_cli ) )
    {
      return FALSE;
    }
  
  if( holder.current_weapon_def->holster( holder.current_weapon_cli ) )
    {
      holder.current_weapon_cli = __NULL__;
      holder.current_weapon_def = __NULL__;
      return TRUE;
    }
  
  return FALSE;
}

bool wield_weapon( weapon_cli_t * cli )
{
  if( cli == cli->holder.current_weapon_cli )
    {
      return TRUE;
    }
  
  if( !holster_weapon( cli->holder ) )
    {
      return FALSE;
    }

  weapon_def_t * def = cli->weapon;
  
  if( def->wield( cli ) )
    {
      cli->holder.current_weapon_cli = cli;
      cli->holder.current_weapon_def = def;
      return TRUE;
    }
  
  return FALSE;
}

bool give_weapon( entity holder, int slot, weapon_def_t * def )
{
  if( slot < 0 )
    {
      slot = def->target_slot;
    }
  
  if( slot == holder.current_weapon_slot )
    {
      if( !holster_weapon( holder ) )
	{
	  return FALSE;
	}
    }

  weapon_cli_t * set_weapon_cli = get_weapon_cli( holder, slot );

  if( set_weapon_cli == __NULL__ )
    {
      set_weapon_cli = memalloc( sizeof( *set_weapon_cli ) );
      array__set_index( &holder.held_weapons, slot, (void*)set_weapon_cli );
    }

  *set_weapon_cli = (weapon_cli_t){ holder, def, 0 };

  if( slot == holder.current_weapon_slot )
    {
      wield_weapon( set_weapon_cli );
    }

  return TRUE;
}


bool switch_weapon_slot( entity holder, int slot )
{
  weapon_cli_t * desired_weapon_cli = get_weapon_cli( holder, slot );

  if( desired_weapon_cli == holder.current_weapon_cli )
    {
      return TRUE;
    }

  if( !holster_weapon( holder ) )
    {
      return FALSE;
    }

  holder.current_weapon_slot = slot;
  
  return wield_weapon( desired_weapon_cli );
}

void run_weapon_frame( entity holder )
{
  if( holder.current_weapon_def != __NULL__ &&
      (holder.weapon_frame_active || holder.weapon_frame_held) &&
      time > holder.current_weapon_cli->time_when_ready )
    {
      if( holder.held_buttons & BUTTONFL__ATTACK || holder.weapon_frame_held )
	{
	  //print("FRAME\n");
	  if( holder.current_weapon_def->frame( holder.current_weapon_cli ) )
	    {
	      return;
	    }
	  //print("frame fail\n");
	}
      //print("end\n");
      
      holder.current_weapon_def->end( holder.current_weapon_cli );
      holder.weapon_frame_active = FALSE;
      holder.weapon_frame_held = FALSE;
    }
}
  
bool weapon_attack( entity holder )
{
  if( !is_weapon_ready( holder.current_weapon_cli ) )
    {
      return FALSE;
    }

  if( holder.current_weapon_def->begin( holder.current_weapon_cli ) )
    {
      holder.weapon_frame_active = TRUE;
      return TRUE;
    }

  return FALSE;
}

void weapon_impulse_switch( entity holder )
{
  if( holder.impulse != 0 )
    {
      holder.next_weapon_impulse = holder.impulse;
    }

  if( holder.next_weapon_impulse <= 0 ||
      holder.next_weapon_impulse > holder.held_weapons.count ) // 1 will be subtracted, so it will be within range
    {
      holder.next_weapon_impulse = 0;
      return;
    }

  if( !switch_weapon_slot( holder, holder.next_weapon_impulse - 1 ) )
    {
      return;
    }
  
  holder.next_weapon_impulse = 0;
}

void client_weapon_frame()
{
  run_weapon_frame( self );
  weapon_impulse_switch( self );
  if( self.pressed_buttons & BUTTONFL__ATTACK )
    //    enforce semi-auto, to do automatic fire make def->frame = def->start
    {
      print_message( "try attack\n" );
      weapon_attack( self );
    }
}

//
//    Buttons
//

void client_setup_buttons_flags()
{
  float new_buttons = FL_Null;
  
  if( self.button0 )
    {
      new_buttons |= FL_1;
    }

  if( self.button1 )
    {
      new_buttons |= FL_2;
    }

  if( self.button2 )
    {
      new_buttons |= FL_3;
    }

  self.pressed_buttons = new_buttons & ~self.held_buttons;
  self.released_buttons = self.held_buttons & ~new_buttons;
  self.held_buttons = new_buttons;
}

//
//    Damage
//

float do_damage_sub( damage_info_t * damage )
{
  //  print_float( "DAMAGE DONE", damage->ammount );
  
  if( !damage->target.takedamage )
    {
      return 0;
    }

  if( damage->amount <= 0 )
    {
      return 0;
    }

  float take = damage->amount;

  damage->target.health -= take;

  if( damage->target.health <= 0 )
    {
      //print_float("die health", damage->target.health );
      if( damage->target.die )
	{
	  damage->target.die( damage );
	}
    }
  else if( damage->target.pain )
    {
      //print_float("pain health", damage->target.health );
      damage->target.pain( damage );
    }
  //print_float("pain2 health", damage->target.health );

  return take;
}

void clear_collect_damage()
{
  g_collect_damage_array.count = 0;
}

void apply_collect_damage()
{
  for( int i = 0; i < g_collect_damage_array.count; i++ )
    {
      /*print("d\nd\nd\nd\nd\n");
      print_float( "dcount",  g_collect_damage_array.count);
      print("b\nb\nb\nb\nb\n");*/
      do_damage_sub( g_collect_damage_array.data + i );
    }

  clear_collect_damage();
}


int get_new_collect_damage()
{
  const int alloc_expand_increment = 5;

  int old_count = g_collect_damage_array.count;
  
  g_collect_damage_array.count += 1;
  
  if( g_collect_damage_array.count > g_collect_damage_array.alloc )
    //    reallocate
    {
      g_collect_damage_array.alloc = g_collect_damage_array.count + 5;

      damage_info_t * new_array = memalloc( g_collect_damage_array.alloc * sizeof( *new_array ) );

      memcpy( new_array, g_collect_damage_array.data, old_count * sizeof( *new_array ) );

      memfree( g_collect_damage_array.data );
      
      g_collect_damage_array.data = new_array;
    }

  g_collect_damage_array.data[old_count] = (damage_info_t){};

  return old_count;
}

bool is_damage_similar( damage_info_t * a, damage_info_t * b )
{
  return a->target == b->target &&
    a->attacker == b->attacker &&
    a->src == b->src &&
    a->flags == b->flags;
}

void add_collect_damage( damage_info_t * damage )
{
  static int check_index;

  if( check_index >= g_collect_damage_array.count )
    {
      check_index = g_collect_damage_array.count - 1;
    }
  
  if( check_index < 0 )
    {
      check_index = get_new_collect_damage();
      g_collect_damage_array.data[check_index] = *damage;
      //print_float( "init damage", damage.amount );
      return;
    }

  if( is_damage_similar( damage, g_collect_damage_array.data + check_index ) )
    {
      g_collect_damage_array.data[check_index].amount += damage->amount;
      //print_float( "reuse damage", g_collect_damage_array.data[check_index].amount );
      return;
    }
  else
    {
      //print("precheck\n");
      for( check_index = g_collect_damage_array.count - 1; check_index >= 0; check_index-- )
	{
	  //  print("check\n");
	  if( is_damage_similar( damage, g_collect_damage_array.data + check_index ) )
	    {
	      g_collect_damage_array.data[check_index].amount += damage->amount;
	      //  print_float( "found damage", g_collect_damage_array.data[check_index].amount );
	      return;
	    }
	}
    }

  //print_float( "new damage", damage.amount );
  check_index = get_new_collect_damage();
  g_collect_damage_array.data[check_index].amount += damage->amount;
}

float do_damage( damage_info_t * damage )
{
  if( damage->collect )
    {
      //print_message("Collect");
      add_collect_damage( damage );
      return 0;
    }
  else
    {
      //print_message("Do");
      apply_collect_damage();
      return do_damage_sub( damage );
    }
}

void spawn_cursor( vector org )
{
  static entity cursor;
  if( cursor == world )
    {
      cursor = spawn();
      setmodel( cursor, "progs/player.mdl" );
    }

  setorigin( cursor, org );
}

void spawn_blood( entity ent, vector org, damage_info_t * damage )
{
  te_blood( org, '0 0 0', damage->amount );
}

void hitscan_attack( vector org, vector dir, float range, damage_info_t * damage )
{
  traceline( org, org + range * dir, FALSE, damage->inflictor );

  if( trace_fraction >= 1.0 )
    {
      return;
    }

  if( !trace_ent.takedamage )
    {
      te_spike( trace_endpos );
      return;
    }

  spawn_blood( trace_ent, trace_endpos, damage );
  
  //spawn_cursor( trace_endpos );

  //print_message("trace something");
  
  damage->target = trace_ent;

  do_damage( damage );
}

void hitscan_blast_square( vector org, vector angles, float range, vector spread, int count, damage_info_t * damage )
{
  makevectors( angles );
  
  for( int i = 0; i < count; i++ )
    {
      vector dir = v_forward + spread_x * crandom() * v_right + spread_y * crandom() * v_up;

      hitscan_attack( org, dir, range, damage );
    }
}
