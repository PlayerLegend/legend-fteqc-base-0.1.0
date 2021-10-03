/*
  Copyright 2018 Joshua D. Sawyer

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

  3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

//
//    typedefs
//

struct void_array{
  //    an extendable array of void pointers
  int count;
  int buffer_size;
  void ** data;
};

typedef struct void_array void_array_t;

struct entity_array{
  //    an extendable array of entities
  int count;
  int buffer_size;
  entity * ent;
};

typedef struct entity_array entity_array_t;

.void_array_t * array_refs; // used to determine what entity arrays reference an entity, so they can be updated if the entity is removed

//
//    management functions
//

void array__append_data( void_array_t * array, void * data )
{  
  int new_count = array->count + 1;

  if( new_count >= array->buffer_size )
    {
      //    save old info
      int old_buffer_size = array->buffer_size;
      void ** old_array = array->data;

      //    expand and allocate
      array->buffer_size += new_count + 10;
      array->data = memalloc( array->buffer_size*sizeof( void* ) );

      //    copy and free old info
      memcpy( (void*)(array->data), (void*)(old_array), old_buffer_size*sizeof( void* ) );
      memfree( (void*)old_array );
    }

  array->data[array->count] = data;

  array->count = new_count;
}

void array__set_index( void_array_t * array, int index, void * data )
{
  int new_count = max( index + 1, array->count );
  
  if( new_count >= array->buffer_size )
    {
      //    save old info
      int old_buffer_size = array->buffer_size;
      void ** old_array = array->data;

      //    expand and allocate
      array->buffer_size += new_count + 10;
      array->data = memalloc( array->buffer_size*sizeof( void* ) );

      //    copy and free old info
      memcpy( (void*)(array->data), (void*)(old_array), old_buffer_size*sizeof( void* ) );
      memfree( (void*)old_array );
    }

  for( int i = array->count; i < new_count; i++ )
    {
      array->data[i] = __NULL__;
    }

  array->data[index] = data;
  array->count = new_count;
}

void array__delete_index_data( void_array_t * array, int index )
{
  memcpy( ((void*)(array->data)) + index, ((void*)(array->data)) + index + 1, (array->count - (index + 1))*sizeof( void* ) );
  array->count -= 1;
}

void * array__get_index_data( void_array_t * array, int index )
{
  if( index < array->count )
    {
      return array->data[index];
    }
  else
    {
      //print(ftos(array->count));
      //print(" - Out of range\n");
      return __NULL__;
    }
}

void array__delete_data( void_array_t * array, void * data )
{
  int iter_max = array->count - 1;
  for( int i = 0; i < array->count - 1; i++ )
    {
      if( array->data[i] == data )
	{
	  array__delete_index_data( array, i );
	  /*memcpy( ((void*)(array->data)) + i, ((void*)(array->data)) + i + 1, (iter_max - (array->count + i + 1))*sizeof( void* ) );
	  array->count -= 1;
	  iter_max = array->count - 1;*/
	}
    }
}

void array__free_members( void_array_t * array )
{
  for( int i = 0; i < array->count; i++ )
    {
      memfree( array->data[i] );
    }

  memfree( (__variant*)(array->data) );

  array->data = __NULL__;
  array->buffer_size = 0;
  array->count = 0;
}

void array__append_entity( entity_array_t * array, entity ent )
{
  int new_count = array->count + 1;

  if( new_count >= array->buffer_size )
    {
      //    save old info
      int old_buffer_size = array->buffer_size;
      entity * old_array = array->ent;

      //    expand and allocate
      array->buffer_size += new_count + 10;
      array->ent = memalloc( array->buffer_size*sizeof( entity ) );

      //    copy and free old info
      memcpy( array->ent, old_array, old_buffer_size*sizeof( entity ) );
      memfree( old_array );
    }

  array->ent[array->count] = ent;

  array->count = new_count;
}

void array__delete_entity( entity_array_t * array, entity ent )
{
  if( ent.array_refs != __NULL__ )
    {
      array__delete_data( ent.array_refs, (void*)array );
    }
  int iter_max = array->count - 1;
  for( int i = 0; i < iter_max; i++ )
    {
      if( array->ent[i] == ent )
	{
	  memcpy( array->ent + i, array->ent + i + 1, (iter_max - (array->count + i + 1))*sizeof( entity ) );
	  array->count -= 1;
	  iter_max = array->count - 1;
	}
    }
}

void clear_entity_array_t( entity_array_t * array )
{
  entity tgt;
  
  for( int i = 0; i < array->count; i++ )
    {
      tgt = array->ent[i];

      if( tgt.array_refs != __NULL__ )
	{
	  array__delete_data( tgt.array_refs, (void*)array );
	}
    }

  memfree( (__variant*)(array->ent) );

  array->ent = __NULL__;
  array->buffer_size = 0;
  array->count = 0;
}
void free_entity_array_t( void * array_p )
{
  clear_entity_array_t( (entity_array_t*)array_p );

  memfree( (__variant*)array_p );
}
