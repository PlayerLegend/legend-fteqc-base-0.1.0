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
    player.qc<server_qc>

    Player related functions

    Includes:
      Player spawning
      Player networking
*/
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


void setup_player( entity tgt )
//    set up an entity as a player
{
  give_weapon( tgt, -1, &weapon__axe );
  give_weapon( tgt, -1, &weapon__shotgun );
  tgt.classname = "player";
  tgt.solid = SOLID_SLIDEBOX;
  tgt.modelindex = MODEL__PLAYER;
  tgt.movetype = MOVETYPE_WALK;
  setsize( tgt, VEC_HULL_MIN, VEC_HULL_MAX );
  tgt.view_ofs = '0 0 22';
  self.SendFlags |= PLAYER_SENDFL__SPAWN_INFO;
}

entity find_spawn()
//    find a spawn for a player
{
  entity_array_t * spawn_array;
  
  if( deathmatch )
    {
      spawn_array = &(g_spawns.deathmatch);
    }
  else if( coop )
    {
      spawn_array = &(g_spawns.coop);
    }
  else
    {
      spawn_array = &(g_spawns.single);
    }

  if( spawn_array->count == 0 )
    {
      if( g_spawns.all.count > 0 )
	{
	  spawn_array = &(g_spawns.all);
	}
      else
	{
	  return world;
	}
    }

  int randomindex = rint( spawn_array->count * random() );

  return spawn_array->ent[randomindex];
}

float spawn_player( entity tgt )
//    spawn the 'tgt' entity as a player and place it in the world
{
  entity tgt_spawn = find_spawn();

  if( tgt_spawn != world )
    {
      setup_player( tgt );

      setorigin( tgt, tgt_spawn.origin + '0 0 1' );
      self.angles = tgt_spawn.angles;
      self.fixangle = 1;
      
      self.SendFlags |= PLAYER_SENDFL__SPAWN_INFO;

      return TRUE;
    }
  else
    {
      return FALSE;
    }
}

void th_player_spawn()
//    a .think callback which will spawn the entity as a player
{
  centerprint( self, "spawn" );
  if( !spawn_player( self ) )
    {
      self.nextthink = time + 0.1 + random();
    }
}

float sendentity__player( entity playerent, float changedflags )
//    the .SendEntity callback for player entities
{
  if( changedflags & PLAYER_SENDFL__NEW_ENT )
    {
      changedflags |= PLAYER_SENDFL__SPAWN_INFO | PLAYER_SENDFL__FRAME_INFO;
    }

  //  *  begin sending info
  
  //  **  send a generic header

  SendEntity__send_header( SENDENT__PLAYER, changedflags );

  //  **  send player-specific info 

  if( changedflags & PLAYER_SENDFL__FRAME_INFO )
    {
      WriteVector( MSG_ENTITY, self.origin );
      WriteVector( MSG_ENTITY, self.velocity );
      WriteByte( MSG_ENTITY, self.frame );
      WriteFloat( MSG_ENTITY, self.flags );
    }

  if( changedflags & PLAYER_SENDFL__SPAWN_INFO )
    {
      WriteVector( MSG_ENTITY, self.mins );
      WriteVector( MSG_ENTITY, self.maxs );
      WriteByte( MSG_ENTITY, self.modelindex );
      WriteByte( MSG_ENTITY, self.solid );
      WriteByte( MSG_ENTITY, self.movetype );
    }
    
  return TRUE;
}
