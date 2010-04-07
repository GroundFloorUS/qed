module QED
  require 'yaml'
  require 'tilt'
  require 'nokogiri'

  require 'facets/dir/ascend'

  require 'qed/evaluator'

  #Assertion   = AE::Assertion
  #Expectation = Assertor

  # = Script
  #
  # When run current working directory is changed to that of
  # the demonstration script's. So any relative file references
  # within a demo must take that into account.
  #
  class Script

    # Demonstration file.
    attr :file

    # Expanded dirname of +file+.
    attr :dir

    #
    attr :scope

    # New Script
    def initialize(file, scope=nil)
      @file     = file
      @scope    = scope || Scope.new
      apply_environment
    end

    # One binding per script.
    def binding
      @binding ||= @scope.__binding__
    end

    #
    def advice
      @scope.__advice__
    end

    #
    def dir
      @dir ||= File.expand_path(File.dirname(file))
    end

    # File basename less extension.
    def name
      @name ||= File.basename(file).chomp(File.extname(file))
    end

    # Nokogiri HTML document.
    def document
      @document ||= Nokogiri::HTML(to_html)
    end

    # Root node of the html document.
    def root
      document.root
    end

    # Open file and translate template into HTML text.
    def to_html
      #case file
      #when /^http/
      #  ext  = File.extname(file).sub('.','')
      #  Tilt[ext].new{ source }
      #else
      #end
      if File.extname(file) == '.html'
        File.read(file)
      else
        Tilt.new(file).render
      end
    end

    # Open, convert to HTML and cache.
    def html
      @html ||= to_html
    end

    #
    #def source
    #  @source ||= (
    #    #case file
    #    #when /^http/
    #    #  ext  = File.extname(file).sub('.','')
    #    #  open(file)
    #    #else
    #      File.read(file)
    #    #end
    #  )
    #end

    #
    def run(*observers)
      evaluator = Evaluator.new(self, *observers)
      evaluator.run
    end

    #
    def environment
      glob = File.join(dir, '{environment,common,shared}', '*')
      Dir[glob]
    end

    #
    def apply_environment
      environment.each do |file|
        case File.extname(file)
        when '.rb'
          eval(File.read(file), scope.__binding__, file)
        else
          Script.new(file, scope).run
        end
      end
    end

  end

end

