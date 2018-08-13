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

weapon_cli_t * get_weapon_cli( entity holder, int slot )
{
  return (weapon_cli_t*)array__get_index_data( &(holder.held_weapons), slot );
}

bool is_weapon_ready( struct weapon_cli * cli )
{
  if( cli == __NULL__ )
    {
      return FALSE;
    }

  if( cli->holder.weapon_frame_active )
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

bool give_weapon( entity holder, int slot, struct weapon_def * def )
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

  *set_weapon_cli = (struct weapon_cli){ holder, def, 0 };

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
  if( time < holder.current_weapon_cli->time_when_ready )
    {
      return;
    }

  if( !holder.weapon_frame_active )
    {
      return;
    }
  
  if( holder.held_buttons & BUTTONFL__ATTACK )
    {
      if( holder.current_weapon_def->frame( holder.current_weapon_cli ) )
	{
	  return;
	}
    }

  holder.current_weapon_def->end( holder.current_weapon_cli );
  holder.weapon_frame_active = FALSE;
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
