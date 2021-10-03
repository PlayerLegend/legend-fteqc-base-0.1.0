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
    entry.qc<server_qc>

    Entry functions (that aren't spawning functions) go here
*/
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


//
//    world
//

void main()
{
}

void worldspawn()
{
  set_model_indexes();
}

void StartFrame()
{
  apply_collect_damage();  
}

//
//    client
//

void SpectatorConnect()
{
  
}

void ClientConnect()
{
}

void PutClientInServer()
{
  self.think = th_player_spawn;
  self.nextthink = time + 0.1*( 1 + random() );
  self.SendEntity = sendentity__player;
  self.SendFlags |= PLAYER_SENDFL__NEW_ENT;
}

float debug_last_update;

void PlayerPreThink()
{
  makevectors( self.v_angle );
  client_setup_buttons_flags();
  client_weapon_frame();
  //if( !self.deadflag )
    {
      alive_player_frame_setup();
    }
  //self.velocity = '100 100 100';
}

void PlayerPostThink()
{
  self.impulse = 0;
}

void ClientDisconnect()
{
  
}

//    FTEQW

void SV_RunClientCommand()
{
  run_player_physics( self );
  //if( time - debug_last_update > 1 )
    {
      //print("update\n");
      self.SendFlags |= PLAYER_SENDFL__FRAME_INFO;
      debug_last_update = time;
    }
}

