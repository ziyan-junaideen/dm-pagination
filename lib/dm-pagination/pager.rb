
module DataMapper
  class Pager
    
    ##
    # Total number of un-limited records.
    
    attr_reader :total 
    
    ##
    # Records per page.
    
    attr_reader :per_page 
    
    ##
    # Current page number.
    
    attr_reader :current_page
    
    ##
    # Previous page or nil when no previous page is available.
    
    attr_reader :previous_page
    
    ##
    # Next page or nil when no more pages are available.
    
    attr_reader :next_page
    
    ##
    # Total number of pages.
    
    attr_reader :total_pages
    
    ##
    # Initialize with _options_.
    
    def initialize options = {}
      @total = options.delete :total
      @per_page = options.delete :limit
      @current_page = options.delete :page
      @total_pages = total.quo(per_page).ceil
      @next_page = current_page + 1 unless current_page >= total_pages
      @previous_page = current_page - 1 unless current_page <= 1
    end
    
    ##
    # Render the pager with the given _uri_ and _options_.
    # 
    # === Examples
    #
    #   User.page(2).pager.to_html('/users')
    #   User.page(2).pager.to_html('/users', :size => 3)
    #
    # === Options
    #
    #   :size   Number of intermediate page number links to be shown; Defaults to 7
    #
    
    def to_html uri, options = {}
      return unless total_pages > 1
      @uri = uri
      @size = options.fetch :size, Pagination.defaults[:size]
      raise ArgumentError, 'invalid :size; must be an odd number' if @size % 2 == 0
      @size /= 2
      %(<ul class="#{Pagination.defaults[:pager_class]}">) + first_link + previous_link + 
      more(:before) + intermediate_links.join("\n") + more(:after) +
      next_link + last_link + '</ul>'
    end
    
    private
    
    ##
    # Link to _page_ with optional anchor tag _contents_. 
    
    def link_to page, contents = nil
      %(<a href="#{uri_for(page)}">#{contents || page}</a>)
    end
    
    ##
    # More pages indicator for _position_.
    
    def more position
      return '' if position == :before && (current_page <= 1 || first <= 1)
      return '' if position == :after && (current_page >= total_pages || last >= total_pages)
      li('more') { Pagination.defaults[:more_text] }
    end
    
    ##
    # Intermediate page links array.
    
    def intermediate_links
      (first..last).map do |page|
        classes = current_page == page ? ['active'] : []
        classes << "page-#{page}"
        li(classes.join(' ')) { link_to(page) }
      end
    end
    
    ##
    # Previous link.
    
    def previous_link
      previous_page ? li('previous jump') { link_to(previous_page, Pagination.defaults[:previous_text]) } : ''
    end
    
    ##
    # Next link.
    
    def next_link
      next_page ? li('next jump') { link_to(next_page, Pagination.defaults[:next_text]) } : ''
    end
    
    ##
    # Last link.
    
    def last_link
      next_page ? li('last jump') { link_to(total_pages, Pagination.defaults[:last_text]) } : ''
    end
    
    ##
    # First link.
    
    def first_link
      previous_page ? li('first jump') { link_to(1, Pagination.defaults[:first_text]) } : ''
    end
    
    ##
    # Determine first intermediate page.

    def first
      @first ||= begin
        first = [current_page - @size, 1].max
        if (current_page - total_pages).abs < @size
          first = [first - (@size - (current_page - total_pages).abs), 1].max
        end
        first
      end
    end
    
    ##
    # Determine last intermediate page.

    def last
      @last ||= begin
        last = [current_page + @size, total_pages].min
        if @size >= current_page
          last = [last + (@size - current_page) + 1, total_pages].min
        end
        last
      end
    end
    
    ##
    # Renders a <li> with the given class
    # and content from the given block.
    
    def li css_class = nil, &block
      "<li#{%( class="#{css_class}") if css_class}>#{yield}</li>\n"
    end
    
    ##
    # Uri for _page_. The following conversions are made
    # to the _uri_ previously passed to #to_html:
    #
    #   /items          # Appends query string => /items?page=2
    #   /items?page=1   # Adjusts current page => /items?page=2
    #   /items?foo=bar  # Appends page pair    => /items?foo=bar&page=1
    #

    def uri_for page
      case @uri
      when /page=/ ; @uri.gsub /page=\d+/, "page=#{page}"
      when /\?/    ; @uri += "&page=#{page}"
      else         ; @uri += "?page=#{page}"
      end
    end
    
  end
end