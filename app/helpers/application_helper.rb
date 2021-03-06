# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  # Short form for translate method. Integers are not translated.
  def t(*args)
    if (args[0] && args[0].to_i.to_s.eql?(args[0]))
      args
    else  
      translate(*args)
    end  
  end
  
  def ta(array)
    translated_array = Array.new
    index = 0;
    array.each do |array_item|
      translated_array[index] = t(array_item)
      index += 1;
    end
    return translated_array  
  end
  
  def self.escape_for_url(str)
     URI.escape(str, Regexp.new("[^-_!~*()a-zA-Z\\d]"))
  end
  
  def remove_html_unfriendly_chars(str)
    str.gsub(/["']/, "")
  end
  
  # Returns a hash containing link names and urls for top navigation.
  def get_top_navi_items
    navi_items = ActiveSupport::OrderedHash.new
    navi_items[:home] = root_path
    navi_items[:listings] = listing_category_path("all_categories")
    navi_items[:items_tab] = items_path
    navi_items[:favors_top] = favors_path
    navi_items[:people] = people_path
    navi_items[:groups_title] = groups_path
    if @current_user
      navi_items[:own] = person_path(@current_user)
    end
    return navi_items
  end
  
  # Returns a hash containing link names and urls for left navigation.
  def get_left_navi_items(navi_type)
    navi_items = ActiveSupport::OrderedHash.new
    session[:left_navi] = true
    case navi_type
    when 'own'
      navi_items[:profile] = person_path(@current_user)
      navi_items[:inbox] = person_inbox_index_path(@current_user)
      navi_items[:requests] = person_requests_path(@current_user)
      navi_items[:comments_to_own_listings] = comments_person_listings_path(@current_user)
      navi_items[:settings] = person_settings_path(@current_user)
    when 'listings'
      navi_items[:browse_listings] = listing_category_path("all_categories")
      navi_items[:search_listings] = search_listings_path
      navi_items[:add_listing] = new_listing_path
      navi_items[:own_listings] = person_listings_path(@current_user) if @current_user
    when 'items_tab'
      navi_items[:browse_items] = items_path
      navi_items[:search_items] = search_items_path
      navi_items[:add_item] = person_path(@current_user) + "#items" if @current_user
      navi_items[:request_item] = new_listing_path(:category => "borrow_items")
    when 'favors_top'
      navi_items[:browse_favors] = favors_path
      navi_items[:search_favors] = search_favors_path
      navi_items[:add_favor] = person_path(@current_user) + "#favors" if @current_user
      navi_items[:request_favor] = new_listing_path(:category => "favors")
    when 'people'
      navi_items[:browse_people] = people_path
      navi_items[:search_people] = search_people_path
      if @current_user
        navi_items[:friends] = person_friends_path(@current_user)
        navi_items[:contacts] = person_contacts_path(@current_user)
      end  
    when 'groups_title'
      navi_items[:browse_groups] = groups_path
      navi_items[:search_groups] = search_groups_path
      navi_items[:new_group] = new_group_path
      navi_items[:own_groups] = person_path(@current_user) + "#groups" if @current_user
    when 'info'
      navi_items[:about] = about_info_path
      navi_items[:help] = help_info_path
      navi_items[:terms] = terms_info_path      
    else
      session[:left_navi] = false  
    end  
    return navi_items
  end
  
  # Returns a hash containing link names and urls for left sub navigation.
  def get_sub_navi_items(navi_type)
    navi_items = ActiveSupport::OrderedHash.new
    case navi_type
    when 'browse_listings'
      navi_items[:all_categories] = listing_category_path("all_categories")
      Listing::MAIN_CATEGORIES.each do |category|
        navi_items[category] = listing_category_path(category)
      end    
    else
      navi_items = nil
    end 
    return navi_items 
  end
  
  # Returns a hash containing link names and urls for left "sub sub" navigation.
  def get_sub_sub_navi_items(navi_type)
    navi_items = ActiveSupport::OrderedHash.new
    if (Listing.get_sub_categories(navi_type))
      Listing.get_sub_categories(navi_type).each do |category|
        navi_items[category] = listing_category_path(category)
      end   
    else
      navi_items = nil
    end 
    return navi_items 
  end
  
  def is_current_user?(person)
    if @current_user
      return person.id == @current_user.id ? true : false 
    else
      return false
    end    
  end
  
  # Create "show [link_value] listings on page" links for 
  # each link value. Type defines the link target path.
  def create_footer_pagination_links(link_values, type)
    links = []
    per_page_value = params[:per_page] || "10"
    params[:page] = 1 if params[:page]
    link_values.each do |value|
      if per_page_value.eql?(value)
        links << link_to(t(value), "#", :class => "links_panel links_panel_selected")
      else
        case type
        when "category"
          if params[:id]
            path = listing_category_path(params.merge({:per_page => value}))
          else
            path = listing_category_path("all_categories", :per_page => value)
          end 
        when "interesting_listings"
          path = interesting_person_listings_path(params.merge({:per_page => value}))
        when "person_listings"
          path = person_listings_path(params.merge({:per_page => value}))       
        when "search_listings"
          path = search_listings_path(params.merge({:per_page => value}))
        when "search_items"
          path = search_items_path(params.merge({:per_page => value}))  
        when "search_all"
          path = search_path(params.merge({:per_page => value})) 
        when "kassi_events"
          path = person_kassi_events_path(params.merge({:per_page => value}))
        when "received"
          path = person_inbox_index_path(params.merge({:per_page => value}))
        when "sent"
          path = sent_person_inbox_path(params.merge({:per_page => value}))   
        when "kassi_users"
          path = people_path(params.merge({:per_page => value}))
        when "contacts"
          path = person_contacts_path(params.merge({:per_page => value}))
        when "friends"
          path = person_friends_path(params.merge({:per_page => value}))    
        when "comments"
          path = comments_person_listings_path(params.merge({:per_page => value}))
        when "requests"
          path = person_requests_path(params.merge({:per_page => value}))
        when "search_people"
          path = search_people_path(params.merge({:per_page => value}))
        when "feedback"
          path = admin_feedbacks_path(params.merge({:per_page => value}))
        when "groups_title"
          path = groups_path(params.merge({:per_page => value}))
        when "group_members"
          path = group_path(params.merge({:per_page => value}))
        when "search_groups"
          path = search_groups_path(params.merge({:per_page => value}))                     
        end
        links << link_to(t(value), path, :class => "links_panel")  
      end    
    end
    links.join("") 
  end
  
  # Changes line breaks to <br>-tags and transforms URLs to links
  def text_with_line_breaks(text)
    #pattern for ending characters that are not part of the url
    pattern = /[\.)]*$/
    h(text).gsub(/https?:\/\/\S+/) { |link_url| link_to(link_url.gsub(pattern,""), link_url.gsub(pattern,"")) +  link_url.match(pattern)[0]}.gsub(/\n/, "<br />")
  end
  
  def small_avatar_thumb(person)    
    link_to (image_tag APP_CONFIG.asi_url + "/people/" + person.id + "/@avatar/small_thumbnail", :width => 50, :height => 50), person
              #, :alt => person.name(session[:cookie]), :width => 50, :height => 50), person  
              # The alt text is removed 'cos it's prosessing caused some timeouts..
  end
  
  def large_avatar_thumb(person)
    image_tag APP_CONFIG.asi_url + "/people/" + person.id + "/@avatar/large_thumbnail", 
              :alt => person.name(session[:cookie])
  end
  
  def translate_announcement_error_message(message)
    case message
    when "Title is required"
      :title_is_required
    when "Title on liian lyhyt (minimi on 2 merkkiä)"
      :title_is_too_short
    when "Title is too short (minimum is 2 characters)"
      :title_is_too_short  
    when "Title on liian pitkä (maksimi on 70 merkkiä)"
      :title_is_too_long
    when "Title item_with_proposed_title_already_exists"
      :item_title_with_same_name_already_exists
    when "Title favor_with_proposed_title_already_exists"
      :favor_title_with_same_name_already_exists  
    when "Description is too long"    
      :description_is_too_long 
    when "Amount ei ole numero"
      :item_amount_is_not_numeric
    when "Amount täytyy olla suurempi tai yhtä suuri kuin1"
      :item_amount_is_too_small  
    else
      message
    end  
  end
  
  def refresh_announcements(page)
    page["announcement_div"].replace_html :partial => 'layouts/announcements'
  end
  
  def has_address?(person)
    if person.street_address && person.street_address != ""
      return true
    end
    return false  
  end
  
  # Displays translated error messages for an object.
  def display_errors(object, error_message)
    output = ""
    errors = translate_error_messages(object.errors.full_messages) 
    unless errors.empty? 
      output += "
        <div id='form_error_messages'>
          <h2>#{t(error_message)}:</h2>
          <ul>"  
      errors.each do |error| 
        output += "<li>#{error}</li>"
      end 
      output += "</ul></div>"
    end
    return output 
  end
  
  def translate_error_messages(error_message_groups)
    translated_errors = []
    error_message_groups.each do |error_messages|
      error_messages.each do |message|
        translated_errors << translate_error_message(message)
      end
    end
    return translated_errors  
  end
  
  def translate_error_message(message)
    
    # This could be transfered to translation files in format :"Username can't be blank" => 
    
    case message
    when "Title on pakollinen tieto."
      t(:title_is_required)
    when "Title on liian lyhyt (minimi on 2 merkkiä)."
      t(:title_is_too_short)
    when "Title on liian pitkä (maksimi on 50 merkkiä)."
      t(:title_is_too_long)  
    when "Content on pakollinen tieto."
      t(:content_is_required)
    when "Good thru on pakollinen tieto."
      t(:good_thru_is_required)
    when "Language on pakollinen tieto."
      t(:listing_must_have_language)
    when "Image file is not a recognized format"
      t(:image_file_is_not_a_recognized_format)
    when "Image file can't be bigger than 10 megabytes"
      t(:image_file_is_too_big)           
    when "Good thru must not be more than one year"
      t(:good_thru_must_not_be_more_than_year)
    when "Password does not match"
      t(:passwords_dont_match)
    when "Username can't be blank"
      t(:username_is_required)  
    when "Username is too short"
      t(:username_is_too_short)
    when "Username is too long"
      t(:username_is_too_long)
    when "Email is invalid"
      t(:email_is_invalid)
    when "Email can't be blank"
      t(:email_can_not_be_blank)  
    when "Username has already been taken"
      t(:username_has_already_been_taken)  
    when "Email has already been taken"
      t(:email_has_already_been_taken)  
    when "Password is invalid"
      t(:password_is_invalid)
    when "Password is too short"
      t(:password_is_too_short)
    when "Password is too long"
      t(:password_is_too_long)
    when "Ryhmän nimi is too short (minimum is 2 characters)"
      t(:group_title_is_too_short)
    when "Ryhmän nimi is too long (maximum is 70 characters)"
      t(:group_title_is_too_long)    
    when "Description is too long"
      t(:group_description_is_too_long)        
    else
      message
    end  
  end
  
  def message_from_error(error)
    return "" if error.nil?
    begin
      if error.class.parent == RestClient
        error_json = JSON.parse(error.response.body.to_s)
        # select the first from the errors
        error_string = error_json["messages"][0]
      else
        error_string = error.message
      end
    rescue Exception => e
      return "Error in error message translation"
    end
    return error_string
  end
  
  # def get_all_people_array
  #   Rails.cache.fetch("people_name_and_username_list/#{CacheHelper.people_last_changed}") {get_all_people_array_without_cache}
  #   #get_all_people_array_without_cache
  # end
  # 
  # def get_all_people_array_without_cache
  #   people = Person.find(:all).collect { 
  #     |p| [ p.name(session[:cookie]) + " (" + p.username(session[:cookie]) + ")", p.id ] 
  #   }
  #   
  #   people.sort! {|a,b| a[0].downcase <=> b[0].downcase}
  #   
  #   return people
  # end
  
  # Takes a collection of any objects and creates an array for javascript from them
  def to_js_array(collection)
    "'#{collection.collect { |object| object.id.to_s }.sort { |a,b| a <=> b }.join("','")}'"
  end
  
  # put this in the body after a form to set the input focus to a specific control id
  def set_focus_to_id(id)
    <<-END
    <script language="javascript">
        <!--
                document.getElementById("#{id}").focus()
        //-->
    </script>
    END
  end
  
end


# Overrides 'page_entries_info' method of will paginate plugin so that the messages
# it provides can be translated.
module WillPaginate
  module ViewHelpers
    def page_entries_info(collection, options = {})
      entry_name = options[:entry_name] ||
        (collection.empty?? 'entry' : collection.first.class.name.underscore.sub('_', ' '))
      
      if collection.total_pages < 2
        case collection.size
        when 0; "0"
        when 1; "1"
        else;   "#{collection.size}/#{collection.size}"
        end
      else
        %{%d-%d/%d} % [
          collection.offset + 1,
          collection.offset + collection.length,
          collection.total_entries
        ]
      end
    end
  end
end
