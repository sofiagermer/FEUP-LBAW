@extends('layouts.app')
@section('title', $project->name." Forum")
@section('content')
<script src={{ asset('js/forum.js') }} defer></script>

<div id="project-area">

  @include('partials.projects-bar')

  @include('partials.slide-right-menu')

    <div class="project-overview" data-id="{{$project->id}}">
        <div id="project-overview-top-bar">
            <div id="project-overview-top-bar-left">
                <h2 id="project-title">{{$project->name}}</h2>
            </div>
        </div>
        <div id = "forum">
            <div id="keep-scroll-at-bottom">
                <div id="forum-posts-container">
                    @foreach($project->forumPosts->sortBy('post_date') as $forumPost)
                    @if($forumPost->deleted)
                    <div class = "forumPost">
                        
                        <img class="forum-post-profile-image" src="{{$forumPost->postAuthor->profile_image}}" alt="user-profile-pic">
                        <div class="forum-post-name-date-options-content">
                            <div class="forum-post-name-date-options">
                                <div class="forum-post-name-plus-date">
                                    <h5>{{$forumPost->postAuthor->name}}</h5>
                                    <h6 class="forum-post-date-value">{{$forumPost->post_date}}</h6>
                                </div>
                            </div>
                            <div id="deleted-forum-post-icon-plus-text-content">   
                                <span>
                                    <i class="fas fa-ban"></i>
                                </span>
                                
                                <p class="delete-post-content">This post was deleted by the post's author.</p>
                            </div>
                            <!-- <textarea name="" id=""></textarea>
                            <div id="edit-forum-post-save-button">Save</div> -->
                        </div>
                        
                    </div>
                    @else
                    <div class = "forumPost">
                        
                        <img class="forum-post-profile-image" src="{{$forumPost->postAuthor->profile_image}}" alt="user-profile-pic">
                        <div class="forum-post-name-date-options-content">
                            <div class="forum-post-name-date-options">
                                <div class="forum-post-name-plus-date">
                                    <h5>{{$forumPost->postAuthor->name}}</h5>
                                    <h6 id="fpdv{{$forumPost->id}}" class="forum-post-date-value">{{$forumPost->post_date}}</h6>
                                    @if(count($forumPost->postEdition)>0)
                                    <h6>(edited)</h6>
                                    @endif
                                </div>
                                @if($forumPost->isAuthor(Auth::user()))
                                <div class="forum-post-options-container">
                                    <div class="forum-post-options-menu">
                                        <div data-id="{{$forumPost->id}}" class="forum-post-edit-post-button"><h4>Edit post</h4></div>
                                        <div data-id="{{$forumPost->id}}" class="forum-post-delete-post-button"><h4>Delete post</h4></div>
                                    </div>
                                    <img class="forum-post-options-button" src="/images/icons/3points.png" alt="options-icon">
                                </div>
                                @endif
                            </div>
                            <p id="fpc{{$forumPost->id}}" >{{$forumPost->content}}</p>
                            <!-- <textarea name="" id=""></textarea>
                            <div id="edit-forum-post-save-button">Save</div> -->
                        </div>
                        

                    </div>
                    @endif
                    @endforeach
                </div>
            </div>
            <div class="new-post-content-input"  data-project-id="{{$project->id}}">
                <textarea id="new-post-text-area-input" name="content" placeholder="Type a new message..." cols="120" rows="4"></textarea>
                <img id="createNewPostButton" src="/images/icons/send.png" alt="send-post-icon">
            </div>
        </div>
    </div>
</div>

@endsection
