@extends('layouts.app')
@section('content')

<div class = "userpageSetUp">
    <div class = "photoSpace">
        <div id = "userPhoto">
            <img src="/images/profile-pic.png">
        </div>
    </div>
    <div class = "textSpace">
        <div class="userpageInfo">
            <p class="userName">{{ $user->name }}</p>
            <hr id = "userPageHR">
        </div>
        <div class="userpageInfo">
            <div id = "emailSpace">
                <i class="fas fa-envelope icon" id = "emailIcon" ></i>
                <p class="userEmail">{{ $user->email }}</p>
            </div>
        </div>
        <div id= "buttonEditProfile"> 
            <a href="{{ url('/edituserpage') }}" id = "editprofileButton">Edit Profile </a>
        </div>
    </div>
</div>

@endsection

