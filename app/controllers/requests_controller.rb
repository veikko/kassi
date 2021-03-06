class RequestsController < ApplicationController
  
  before_filter :logged_in
  after_filter :clear_caches, :excpet => [:index, :reject]
  
  def index
    @person = Person.find(params[:person_id])
    return unless must_be_current_user(@person)
    save_navi_state(['own', 'requests'])
    ids = Array.new
    @person.get_friend_requests(session[:cookie])["entry"].each do |person|
      ids << person["id"]
    end
    @requesters = Person.find_kassi_users_by_ids(ids).paginate :page => params[:page], :per_page => per_page
  end

  def accept
    @friend = Person.find(params[:id])
    @successful = accept_friend_request(@friend)
    render :update do |page|
      if @successful
        page["#{@friend.id}_friendstatus"].replace_html :partial => 'people/friend_status_link', 
                                                          :locals => { :person => @friend }                                                  
      end       
      refresh_announcements(page)
    end
  end
  
  def accept_redirect
    @friend = Person.find(params[:id])
    @success = accept_friend_request(@friend)
    redirect_to :back
  end  

  def reject
    begin
      @current_user.remove_pending_friend_request(params[:id], session[:cookie])
      flash[:notice] = :friend_request_rejected
    rescue RestClient::ResourceNotFound => e
      flash[:error] = :rejecting_friend_request_failed
    end
    redirect_to :back
  end
  
  def cancel
    @friend = Person.find(params[:id])
    @successful = cancel_friend_request(@friend)
    render :update do |page|
      if @successful
        page["#{@friend.id}_friendstatus"].replace_html :partial => 'people/friend_status_link', 
                                                        :locals => { :person => @friend }
      end       
      refresh_announcements(page)
    end
  end

  private
  
  def clear_caches
     update_caches_dependent_on_friendship(@current_user, @friend)
  end
  
  def accept_friend_request(friend)
    begin
      @current_user.add_as_friend(friend.id, session[:cookie])
      flash[:notice] = [ :friend_request_accepted, friend.name, person_path(friend) ]
      return true
    rescue RestClient::ResourceNotFound => e
      flash[:error] = :accepting_friend_request_failed
      return false
    end
  end
  
  def cancel_friend_request(friend)
    begin
      @current_user.remove_pending_friend_request(friend.id, session[:cookie])
      flash[:notice] = :friend_request_canceled
    rescue RestClient::ResourceNotFound => e
      flash[:error] = :canceling_friend_request_failed
    end
  end
  
  # Updates friend status link
  def update_friend_status(friend, successful)
    render :update do |page|
      if successful
        page["#{friend.id}_friendstatus"].replace_html :partial => 'people/friend_status_link', 
                                                        :locals => { :person => friend }
      end       
      refresh_announcements(page)
    end
  end

end
