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

void add_weapon( weapon_object_t * weapon )
{
  array__set_index( &g_weapon_objects_array, weapon->id, (void*)weapon );
}

weapon_info_t * get_weapon_info( entity holder, int slot )
{
  return (weapon_info_t*)array__get_index_data( &(holder.held_weapons), slot );
}

bool is_weapon_ready( entity holder )
{
  if( holder.current_weapon_info == __NULL__ )
    {
      return FALSE;
    }

  if( holder.weapon_frame_active )
    {
      return FALSE;
    }
  
  if( time < holder.current_weapon_info->time_when_ready )
    {
      return FALSE;
    }
  else
    {
      return TRUE;
    }
}

bool holster_weapon( entity holder )
{
  if( holder.current_weapon_info == __NULL__ )
    {
      return TRUE;
    }
  
  if( !is_weapon_ready( holder ) )
    {
      return FALSE;
    }
  
  weapon_object_t * wo = holder.current_weapon_info->weapon;
  
  if( wo->holster( holder ) )
    {
      holder.current_weapon_info = __NULL__;
      return TRUE;
    }
  else
    {
      return FALSE;
    }
}

bool wield_weapon( entity holder, weapon_info_t * weapon_info )
{
  if( weapon_info == __NULL__ )
    {
      return FALSE;
    }

  weapon_object_t * wo = weapon_info->weapon;
  
  if( wo->wield( holder ) )
    {
      holder.current_weapon_info = weapon_info;
      return TRUE;
    }
  else
    {
      return FALSE;
    }
}

bool set_weapon_info( entity holder, int slot, weapon_info_t weapon_info )
{
  if( slot == holder.current_weapon_slot )
    {
      if( !holster_weapon( holder ) )
	{
	  return FALSE;
	}
    }

  weapon_info_t * weapon_info_p = get_weapon_info( holder, slot );

  if( weapon_info_p == __NULL__ )
    {
      weapon_info_p = memalloc( sizeof( *weapon_info_p ) );
      array__set_index( &holder.held_weapons, slot, (void*)weapon_info_p );
    }

  *weapon_info_p = weapon_info;

  if( slot == holder.current_weapon_slot )
    {
      wield_weapon( holder, weapon_info_p );
    }

  return TRUE;
}


bool switch_weapon_slot( entity holder, int slot )
{
  weapon_info_t * desired_weapon_info = get_weapon_info( holder, slot );

  if( desired_weapon_info == holder.current_weapon_info )
    {
      return TRUE;
    }

  if( !holster_weapon( holder ) )
    {
      return FALSE;
    }

  holder.current_weapon_slot = slot;
  
  return wield_weapon( holder, desired_weapon_info );
}

bool give_weapon_object( entity holder, weapon_object_t * weapon )
{
  return set_weapon_info( holder, weapon->target_slot, (weapon_info_t){ holder, weapon, 0 } );
}

bool give_weapon_id( entity holder, int weapon_id )
{
  weapon_object_t * desired_wo = (weapon_object_t*)array__get_index_data( &g_weapon_objects_array, weapon_id );

  if( desired_wo == __NULL__ )
    {
      print( strcat( "Cannot give weapon, no weapon exists by id ", ftos( weapon_id ), "\n" ) );
      return FALSE;
    }

  return give_weapon_object( holder, desired_wo );
}

void init_weapon( weapon_object_t * weapon )
{
  array__set_index( &g_weapon_objects_array, weapon->id, (void*)weapon );
}

void run_weapon_frame( entity holder )
{
  if( !holder.weapon_frame_active )
    {
      return;
    }

  weapon_object_t * wo = holder.current_weapon_info->weapon;

  if( !(holder.held_buttons & BUTTONFL__ATTACK) || !wo->frame( holder ) )
    {
      wo->end( holder );
      holder.weapon_frame_active = FALSE;
    }
}
  
bool weapon_attack( entity holder )
{
  if( !is_weapon_ready( holder ) )
    {
      return FALSE;
    }

  weapon_object_t * wo = holder.current_weapon_info->weapon;

  if( wo->begin( holder ) )
    {
      if( holder.current_weapon_info->time_when_ready > time )
	{
	  holder.weapon_frame_active = TRUE;
	}
      else
	{
	  wo->end( holder );
	}
      
      return TRUE;
    }
  else
    {
      return FALSE;
    }
}

bool weapon_impulse_switch( entity holder )
{
  if( holder.impulse != 0 )
    {
      holder.next_weapon_impulse = holder.impulse;
    }

  if( holder.next_weapon_impulse == 0 ||
      holder.next_weapon_impulse > holder.held_weapons.count ) // 1 will be subtracted, so it will be within range
    {
      return FALSE;
    }

  if( !switch_weapon_slot( holder, holder.next_weapon_impulse - 1 ) )
    {
      return FALSE;
    }
  else
    {
      holder.next_weapon_impulse = 0;
      return TRUE;
    }
}

void client_weapon_frame()
{
  run_weapon_frame( self );
  weapon_impulse_switch( self );
  if( self.held_buttons & BUTTONFL__ATTACK )
    {
      print("tryattack\n");
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
