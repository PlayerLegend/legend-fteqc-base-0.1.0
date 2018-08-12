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
    entry.qc<client_qc>

    Entry functions go here
*/
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

entity vmodel_ent;
float last_vmodel_frame;
float next_vmodel_frame;

void CSQC_Init( float apiver, string enginename, float enginever )
{
  //set_model_indexes();
}

float velocity_roll_slosh;

vector get_velocity_weapon_sway()
{
  const float weapon_sway_max = 4;
  static vector velocity_weapon_sway;
  
  vector swayvel = bound_vector_max( self.velocity / 50, weapon_sway_max );
  vector ofs_add = weapon_sway_max * frametime * (swayvel - velocity_weapon_sway);
  
  velocity_weapon_sway += ofs_add;

  return velocity_weapon_sway;
}

vector get_rotation_weapon_sway()
{
  const float weapon_sway_max = 4;
  
  static float last_angle, sway;

  float wish_sway = bound_float( last_angle - view_angles_y, -weapon_sway_max, weapon_sway_max );

  sway += weapon_sway_max * frametime * (wish_sway - sway);

  last_angle = view_angles_y;
  
  return v_right * sway;
}

void update_interp_offset()
{
  if( self.org_interp_time > 0 && vlen_is_greater( self.org_interp_ofs, 1 ) )
    {
      float origin_time_diff = bound( 0, self.org_interp_time, frametime );
      self.org_interp_ofs -= self.org_interp_ofs * origin_time_diff / self.org_interp_time;
      self.org_interp_time -= origin_time_diff;
    }
}

void update_viewmodel()
{
  //    spawn
  if( vmodel_ent == world )
    {
      vmodel_ent = spawn();
      vmodel_ent.drawmask = MASK_ENGINE;
    }
    
  //    origin
  setorigin( vmodel_ent, getviewprop( VF_ORIGIN ) - get_velocity_weapon_sway() - get_rotation_weapon_sway() );
    
  //    angles
  vmodel_ent.angles = [ -view_angles_x, view_angles_y, view_angles_z ];

  //    model
  vmodel_ent.modelindex = getstatf( STAT_WEAPONMODELI );

  //    frame
  next_vmodel_frame = getstatf( STAT_WEAPONFRAME );
  if( fabs( next_vmodel_frame - last_vmodel_frame ) > 1 )
    {
      last_vmodel_frame = next_vmodel_frame;
    }
}

void set_view_origin()
{
  update_interp_offset();
    
  vector tgt_origin = self.origin;

  tgt_origin += '0 0 1' * getstatf( STAT_VIEWHEIGHT );

  tgt_origin += self.org_interp_ofs;
    
  setviewprop( VF_ORIGIN, tgt_origin );
}

void set_view_angles()
{
  float velocity_roll_new = self.velocity != '0 0 0' ? v_right * self.velocity / 1000 : 0;
  velocity_roll_slosh = velocity_roll_slosh + 10 * frametime * ( velocity_roll_new - velocity_roll_slosh );
  setviewprop( VF_ANGLES, view_angles + '0 0 20' * velocity_roll_slosh );
}

bool get_player_self()
{
  self = findfloat( world, entnum, player_localentnum );
  
  if( self == world )
    {
      cprint( "self is world\n" );
      return FALSE;
    }
  else
    {
      return TRUE;
    }
}

void CSQC_UpdateView( float width, float height, float menushown )
{
  clearscene();

  if( !get_player_self() )
    {
      return;
    }
  
  drawfill( '0 0 0', [width, height, 0], '1 1 0', 1, 0 );

  makevectors( view_angles );

  set_view_angles();

  set_view_origin();
  
  update_viewmodel();
  
  setviewprop( VF_DRAWENGINESBAR, 0 );	
  setviewprop( VF_DRAWCROSSHAIR, 0 );
  
  addentities( MASK_ENGINE );

  renderscene();
}

void CSQC_Input_Frame()
{
  /*self = findfloat( world, entnum, player_localentnum );
  
  if( self == world )
    {
      print("Self is world\n");
      return;
      }*/
}

/*void CSQC_WorldLoaded()
{
  
}*/

void CSQC_Ent_Update( float isnew )
{
  if( isnew )
    {
      print(strcat("ent update ", etos(self),"\n"));
    }

  float type = readbyte(); // entity type
  float flags = readbyte(); // sendflags
  float sendtime = readfloat(); // server time when sent
  
  switch( type )
    {
    case SENDENT__PLAYER:
      recvent__player( isnew, sendtime, flags );
      break;
    default:
      error( "Unknown entity type! oh noes! panic!" );
    }

  self.last_sendtime = sendtime;
  self.last_recvtime = time;
}

void CSQC_Ent_Remove()
{
  print("Removed\n");
  remove( self );
}

/*void CSQC_Parse_Event()
{
  
}*/
