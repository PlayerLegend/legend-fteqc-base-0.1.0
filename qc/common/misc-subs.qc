/*
  Copyright 2018 Joshua D. Sawyer

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

  3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

//
//    model precache
//

float getmodelindex_check( string name )
{
  float ret = getmodelindex( name );

  if( ret == -1 )
    {
      print( strcat("Failed to load ", name, "\n") );
    }

  return ret;
}

void set_model_indexes()
//    precache models and set their indexes in the global MODEL__ variables
{
  MODEL__PLAYER         = getmodelindex_check( "progs/player.mdl" );
  MODEL__SOLDIER 	= getmodelindex_check( "progs/soldier.mdl" );
  MODEL__GRENADE 	= getmodelindex_check( "progs/grenade.mdl" );
  MODEL__VIEWMODEL_AXE  = getmodelindex_check( "progs/v_axe.mdl" );
}

//
//    triggers
//

void find_targets( entity ent )
{
  entity cursor;

  cursor = world;
  while( (cursor = find( cursor, targetname, ent.target)) != world )
    {
      array__append_entity( &(ent.target_list), cursor );
    }
}

void run_event( trigger_event_t event )
{
  int i;
  int count;
  entity * list;

  trigger_event_t branch_event;
  
  while( event.current_trigger.trigger_flags & TRIGGERFL__READY )
    {
      count = event.current_trigger.target_list.count;
      list = event.current_trigger.target_list.ent;

      if( count > 1 )
	{
	  for( i = 0; i < count; i++ )
	    {
	      event.current_target = list[i];
	      if( (event.current_trigger.trigger_action( event )) && (event.current_target.trigger_flags & TRIGGERFL__IS_TRIGGER) )
		{
		  branch_event = (trigger_event_t)
		    {
		      event.activator,
		      event.first_trigger,
		      event.current_trigger,
		      list[i],
		      world // set in run_event
		    };
	
		  run_event( branch_event );
		}
	    }
	  
	  break;
	}
      else
	{
	  event.current_target = list[0];
	  if( !(event.current_trigger.trigger_action( event )) || !(event.current_target.trigger_flags & TRIGGERFL__IS_TRIGGER) )
	    {
	      break;
	    }
	}

      if( count == 0 )
	{
	  break;
	}
      
      event.last_trigger = event.current_trigger;
      event.current_trigger = event.current_target;
    }
}

void activate_trigger( entity trigger, entity activator )
{
  trigger_event_t event =
    {
      activator, // activator
      trigger,   // first trigger
      world,     // last activator
      trigger    // current trigger
    };

  run_event( event );
}

//
//    Math
//

float crandom()
{
  return random() - 0.5;
}

bool vlen_is_greater( vector v, float len )
{
  return vlen( v ) > len;
  
  /*if( len <= 0 )
    {
      return v == '0 0 0';
    }
  
    return v*v > len*len;*/
}

float vlen_is_less( vector v, float len )
{
  return vlen( v ) < len;
  /*  if( len <= 0 )
    {
      return v == '0 0 0';
    }
  
    return v*v < len*len;*/
}

vector bound_vector_max( vector v, float rad )
{
  if( vlen_is_greater( v, rad ) )
    {
      return rad * normalize( v );
    }
  else
    {
      return v;
    }
}

float bound_float( float f, float min, float max )
{
  if( f < min )
    {
      return min;
    }
  else if( f > max )
    {
      return max;
    }
  else
    {
      return f;
    }
}

float anglediff( float a, float b )
{
  float ab = anglemod( a - b );

  if( ab < 0 )
    {
      print("GAY\n");
    }
  
  if( ab > 180 )
    {
      return ab - 360;
    }
  else
    {
      return ab;
    }
  
  /*float ab = a - b;
  float ba = b - a;
  if( fabs( ab ) < fabs( ba ) )
    {
      
      return ab;
    }
  else
    {
      return ba;
      }*/

  /*float diff = a - b;

  while( diff < -180 )
    {
      diff += 360;
    }

  while( diff > 180 )
    {
      diff -= 360;
    }

    return diff;*/
}

vector anglediff3( vector a, vector b )
{
  return [ anglediff( a_x, b_x ), anglediff( a_y, b_y ), anglediff( a_z, b_z ) ];
}

vector vector_pow3( vector a )
{
  return [ a_x * a_x * a_x, a_y * a_y * a_y, a_z * a_z * a_z ];
}

vector rotate_about_axis( vector v, vector axis, float radians )
{
  axis = normalize( axis );
  
  vector axis_project = (v * axis) * axis;
  vector axis_reject = v - axis_project;
  vector cross = crossproduct( axis_reject, axis );
  vector mod_reject = axis_reject * cos( radians ) + cross * sin( radians );

  return axis_project + mod_reject;
}
