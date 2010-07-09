class PeopleController < ApplicationController

  before_filter :logged_in, :only  => [ :show, :edit, :update ]
  
  before_filter :update_navi, :only => [ :home, :index] #needed for cached actions
  caches_action :home, :layout => false, 
                :if => Proc.new { |c| !c.params[:nocache]}, 
                :cache_path => Proc.new { |c| 
                  #This is kind of copmlicated cache key that tries to include every value that could have been changed if the contents of front page have been changed
                  # for ontifications are there will be delay of AppContr::NEW_ARRIVED_ITEMS_CACHE_TIME until changes are seen
                  "front_page/#{c.session[:locale]}/#{CacheHelper.frontpage_last_changed}/#{Rails.cache.read("new_arrived_items_for:#{c.session[:person_id]}")}/#{c.params[:nosplash]}/#{c.session[:person_id]}}"
                }
  caches_action :index, :layout => false, :cache_path => Proc.new { |c| "people_list/#{c.session[:locale]}/#{CacheHelper.people_last_changed}/p#{c.params[:page]}/pp#{c.params[:per_page]}/#{c.session[:person_id]}"}
  #cache_sweeper :person_sweeper, :only => [:create, :edit, :update, :index]
  
  def update_navi
    case params[:action]    
      when "home" then   save_navi_state(['home', '']) 
      when "index" then  save_navi_state(['people', 'browse_people'])
        
    end
  end

  def index
    @title = "kassi_users"
    #save_navi_state(['people', 'browse_people']) #moved to filter
    # @people = Person.find(:all).sort { 
    #   |a,b| a.name(session[:cookie]) <=> b.name(session[:cookie])
    # }.paginate :page => params[:page], :per_page => per_page
    @people = Person.paginate(:page => params[:page], :per_page => per_page, :order => "created_at DESC")
  end
  
  def home
    #save_navi_state(['home', ''])#moved to filter
    @events_per_page = 5
    @content_items_per_page = 15
    @kassi_events = KassiEvent.find(:all, :limit => @events_per_page, :conditions => "pending = 0", :order => "id DESC")
    @more_kassi_events_available = @events_per_page < KassiEvent.count(:all)
    get_newest_content_items(@content_items_per_page)
    @rss = RssHandler.get_kassi_feed
  end
  
  def more_kassi_events
    @events_per_page = params[:events_per_page].to_i + 5
    @kassi_events = KassiEvent.find(:all, :limit => @events_per_page, :order => "id DESC")
    @more_kassi_events_available = @events_per_page < KassiEvent.count(:all)
    render :update do |page|
      page["kassi_events"].replace_html :partial => "kassi_events/frontpage_event",
                                        :as => :kassi_event,
                                        :collection => @kassi_events, 
                                        :spacer_template => "layouts/dashed_line_white"
      page["more_kassi_events_link"].replace_html :partial => "more_kassi_events_link", 
                                                  :locals => { :events_per_page => @events_per_page }                                  
    end
  end
  
  def more_content_items
    @content_items_per_page = params[:content_items_per_page].to_i + 10
    @content_items = get_newest_content_items(@content_items_per_page)
    render :update do |page|
      page["content_items"].replace_html :partial => "content_item",
                                        :as => :content_item,
                                        :collection => @content_items, 
                                        :spacer_template => "layouts/dashed_line"
      page["more_content_items_link"].replace_html :partial => "more_content_items_link", 
                                                   :locals => { :content_items_per_page => @content_items_per_page }                                  
    end
  end
    
  # Shows profile page of a person.
  def show
    #@event_id = "show_profile_page_#{random_UUID}"
    @person = Person.find(params[:id])
    @items = @person.available_items(get_visibility_conditions("item"))
    @item = Item.new
    @favors = @person.available_favors(get_visibility_conditions("item"))
    @favor = Favor.new
    @groups = @person.groups(session[:cookie], @event_id)
    if @person.id == @current_user.id || session[:navi1] == nil || session[:navi1].eql?("")
      save_navi_state(['own', 'profile', '', '', 'information'])
    else
      save_navi_state(['people', 'browse_people'])
      session[:links_panel_navi] = 'information'
    end
  end
  
  def search
    save_navi_state(['people', 'search_people'])
    if params[:q]
      ids = Array.new
      Person.search(params[:q])["entry"].each do |person|
        ids << person["id"]
      end
      @people = Person.find_kassi_users_by_ids(ids).paginate :page => params[:page], :per_page => per_page
    end
  end
  
  # Search used for auto completion
  def search_by_name
    results = Person.search(params[:search])
    return if results.nil?
    #puts "RESLUTADO: #{results.inspect}"
    @suggestions = Array.new
    results["entry"].each do |person|
      @suggestions << ["#{person["name"]["unstructured"]} (#{person["username"]})", person["id"]]   
    end
    #puts "SUGGES: #{@suggestions.inspect}"  
    #@people = get_all_people_array
    #@matching = @people.reject {|p| p[0] !~ /#{params[:search]}/i}
    render :inline => "<%= content_tag(:ul, @suggestions.map { |person| content_tag(:li, h(person[0])) }) %>"
  end
  
  # Creates a new person
  def create
    # should expire cache for people listing
    
    # Open a Session first only for Kassi to be able to create a user
    @session = Session.create
    session[:cookie] = @session.headers["Cookie"]
    params[:person][:locale] = session[:locale] || 'fi'

    # Try to create a new person in COS. 
    @person = Person.new
    if params[:person][:password].eql?(params[:person][:password2]) &&
       params[:person][:consent]
      begin
        @person = Person.create(params[:person], session[:cookie])
      rescue RestClient::RequestFailed => e
        @person.add_errors_from(e)
        preserve_create_form_values(@person)
        render :action => "new" and return
      end
      session[:person_id] = @person.id
      self.smerf_user_id = @person.id   
      @person.settings = Settings.create
      flash[:notice] = :registration_succeeded
      if session[:return_to]
        redirect_to session[:return_to]
        session[:return_to] = nil
      else
        redirect_to root_path
      end
    else
      @person.errors.add(:password, "does not match") unless params[:person][:password].eql?(params[:person][:password2])
      @person.errors.add(:consent, @person.errors.generate_message(:consent, :not_accepted)) unless params[:person][:consent]
      preserve_create_form_values(@person)
      render :action => "new" and return
    end
    
        # Handle friend request hash
    # TODO: after testing, move behind the cos
    if params[:person][:hash] != nil
      invite = {
        :person => @person.id(),
        :direction => "IN",
        :hash => params[:person][:hash],
        :mail => ""
      }
      PersonInvite.new( invite )
    end
    
    
  end  
  
  # Displays register form
  def new
    clear_navi_state
    @person = Person.new
  end
  
  def edit
    @person = Person.find(params[:id])
    render :update do |page|
      page["profile_info_texts"].replace_html :partial => 'people/edit_profile_info'
      page["edit_profile_link"].replace_html :partial => 'cancel_edit_profile_link'
    end  
  end
  
  def update
    # should expire cache for people listing
    
    @person = Person.find(params[:id])
    @successful = update_person(@person)
    render :update do |page|
      if @successful
        page["profile_info_texts"].replace_html :partial => 'people/profile_info'
        page["edit_profile_link"].replace_html :partial => 'edit_profile_link'
        page["profile_header"].replace_html :partial => 'profile_header'
      end  
      refresh_announcements(page)
    end
  end
  
    def invite_new_user
      ## validate presence of email and name...
      hash = rand( 100000000000 )
      user = Person.find(params[:sender][:value])
      invite = {
        :person => user.id(),
        :direction => "OUT",
        :hash => hash,
        :mail => params[:to_email]
      }
      PersonInvite.new( invite )
      UserMailer.deliver_invite_new_person( user, session[:cookie], params[:to_name], params[:to_email], hash )
      ## check rendering
      render :action => "home" and return
    end
  
  def cancel_edit
    @person = Person.find(params[:id])
    render :update do |page|
      page["profile_info_texts"].replace_html :partial => 'people/profile_info'
      page["edit_profile_link"].replace_html :partial => 'edit_profile_link'
    end
  end
  
  def send_message
    @person = Person.find(params[:id])
    @message = Message.new
    return unless must_not_be_current_user(@person, :cant_send_message_to_self)
  end
  
  private
  
  def update_person(person)
    begin
      person.update_attributes(params[:person], session[:cookie])
      flash[:notice] = :person_updated_successfully
      flash[:error] = nil
    rescue RestClient::RequestFailed => e
      flash[:error] = translate_error_message(e.response.body.to_s)
      flash[:notice] = nil
      return false
    end
    return true
  end
  
  def translate_error_message(message)
    if message.include?("Given name is too long")
      return :given_name_is_too_long
    elsif message.include?("Family name is too long")
      return :family_name_is_too_long
    elsif message.include?("address is too long")
      return :street_address_is_too_long
    elsif message.include?("Postal code is too long") 
      return :postal_code_is_too_long  
    elsif message.include?("Locality is too long") 
      return :locality_is_too_long    
    elsif message.include?("Phone number is too long")
      return :phone_number_is_too_long 
    elsif message.include?("Description is too long")
      return :about_me_is_too_long
    else
      return message
    end  
  end
  
  def get_newest_content_items(limit)
    favors = Favor.find(:all, 
                        :conditions => "status <> 'disabled'" + get_visibility_conditions("favor"),
                        :limit => limit,
                        :order => "id DESC")
    items =  Item.find(:all, 
                       :conditions => "status <> 'disabled'" + get_visibility_conditions("item"),
                       :limit => limit, 
                       :order => "id DESC")    
    listings = Listing.find(:all, 
                            :conditions => "status = 'open' AND good_thru >= '" + Date.today.to_s + "'" + get_visibility_conditions("listing"),
                            :limit => limit, 
                            :order => "id DESC")
    @content_items = favors.concat(items).concat(listings).sort {
      |a, b| b.created_at <=> a.created_at
    }[0..(limit-1)]                              
  end
  
  def preserve_create_form_values(person)
    person.form_username = params[:person][:username]
    person.form_given_name = params[:person][:given_name]
    person.form_family_name = params[:person][:family_name]
    person.form_password = params[:person][:password]
    person.form_password2 = params[:person][:password2]
    person.form_email = params[:person][:email]
  end
  
end
