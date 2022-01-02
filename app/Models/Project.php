<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Project extends Model
{
  // Don't add create and update timestamps in database.
  public $timestamps  = false;

  /**
   * The user this card belongs to
   */
  public function members() {
    return $this->belongsToMany('App\Models\User','project_member','project_id','users_id');
  }

  public function tasks(){
    return $this->hasMany('App\Models\Task');
  }

  public function coordinators(){
    return $this->belongsToMany('App\Models\User','project_coordinator','project_id','users_id');
  }

    public function usersInvited(){
        return $this->belongsToMany('App\Models\User','invitation','project_id','users_id')->withPivot('coordinator_id','accepted');;
    }
    public function company()
    {
        return $this->belongsTo('App\Models\Company');
    }

}
