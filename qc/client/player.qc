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
    player.qc<client_qc>

    Functions relating to the player entity

    Includes:
      Rendering
      Animating
      Networking
*/
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

float total_timelen;

int next_commandframe;

float predraw__player()
{
  if( self.entnum == player_localentnum )
    {
      const int first_commandframe = servercommandframe + 1;
      if( next_commandframe < first_commandframe )
	{
	  next_commandframe = first_commandframe;
	}
      
      while( next_commandframe <= clientcommandframe )
	{
	  //print("Frame\n");
	  getinputstate( next_commandframe );
	  total_timelen += input_timelength;

	  run_player_physics( self );
	  
	  next_commandframe++;
	}
    }
  else
    {
      input_timelength = frametime;
      run_player_physics( self );
      addentity( self );
    }
  
  return PREDRAW_NEXT;
}

void interpolate_set_origin( entity tgt, vector new_origin )
{
  tgt.org_interp_ofs += tgt.origin - new_origin;
  tgt.org_interp_time = (time - tgt.org_last_update) * 3;
  tgt.org_last_update = time;

  const float max_interp_time = 0.1;
  if( tgt.org_interp_time > max_interp_time )
    {
      tgt.org_interp_time = max_interp_time;
    }

  setorigin( tgt, new_origin );
}

void recvent__player( float isnew, float sendtime, float changedflags )
{
  if( changedflags & PLAYER_SENDFL__FRAME_INFO )
    {
      if( self.entnum == player_localentnum )
	{
	  interpolate_set_origin( self, readvector() );
	}
      else
	{
	  setorigin( self, readvector() );
	}
      
      self.velocity = readvector();
      self.frame = readbyte();
      self.flags = readfloat();
    }

  if( changedflags & PLAYER_SENDFL__SPAWN_INFO )
    {
      self.mins = readvector();
      self.maxs = readvector();
      self.modelindex = readbyte();
      self.solid = readbyte();
      self.movetype = readbyte();

      setsize( self, self.mins, self.maxs );

      print( strcat( "Set size ", vtos(self.maxs - self.mins), "\n" ) );
    }
  
  if( changedflags & PLAYER_SENDFL__NEW_ENT )
    {
      self.drawmask |= MASK_ENGINE;

      if( self.entnum == player_localentnum )
	{
	  self.renderflags |= RF_EXTERNALMODEL;
	}
      self.customphysics = NULL_customphysics;
      self.predraw = predraw__player;
    }    
}
