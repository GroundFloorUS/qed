module QED
  module Step

    # A typical step.
    #
    class Eval < Base

      #
      def assertive?
        true
      end

      #
      def evaluate(demo)
        evaluate_matchers(demo)
        demo.evaluate(code, lineno) if code?
      end

      #
      def evaluate_matchers(demo)
        match = text

        demo.applique.each do |app|
          app.__matchers__.each do |(patterns, proc)|
            compare = match
            matched = true
            params  = []
            patterns.each do |pattern|
              case pattern
              when Regexp
                regex = pattern
              else
                regex = match_string_to_regexp(pattern)
              end
              if md = regex.match(compare)
                params.concat(md[1..-1])
                compare = md.post_match
              else
                matched = false
                break
              end
            end
            if matched
              args = [params, arguments].reject{|e| e == []}
              args = args + [sample_text] if data?
              args = proc.arity < 0 ? args : args[0,proc.arity]

              demo.scope.instance_exec(*args, &proc)  #proc.call(*args)
            end
          end
        end
      end

      SPLIT_PATTERNS = [ /(\(\(.*?\)\)(?!\)))/, /(\/\(.*?\)\/)/, /(\/\?.*?\/)/ ]

      SPLIT_PATTERN  = Regexp.new(SPLIT_PATTERNS.join('|'))

      # Convert matching string into a regular expression. If the string
      # contains double parenthesis, such as ((.*?)), then the text within
      # them is treated as in regular expression and kept verbatium.
      #
      def match_string_to_regexp(str)
        re = nil
        str = str.split(SPLIT_PATTERN).map do |x|
          case x
          when /\A\(\((.*?)\)\)(?!\))/
            $1
          when /\A\/(\(.*?\))\//
            $1
          when /\A\/(\?.*?)\//
            "(#{$1})"
          else
            Regexp.escape(x)
          end
        end.join

        str = str.gsub(/\\\s+/, '\s+')  # Replace space with variable space.

        Regexp.new(str, Regexp::IGNORECASE)
      end

=begin
    # The following code works as well, and can provide a MatchData
    # object instead of just matching params, but I call YAGNI on that
    # and it has two benefits. 1) the above code is faster, and 2)
    # using params allows |(name1, name2)| in rule blocks.

    #
    def evaluate_matchers(step)
      match = step.text
      args  = step.arguments
      @demo.applique.each do |a|
        matchers = a.__matchers__
        matchers.each do |(patterns, proc)|
          re = build_matcher_regexp(*patterns)
          if md = re.match(match)
            #params = [step.text.strip] + params
            #proc.call(*params)
            @demo.scope.instance_exec(md, *args, &proc)
          end
        end
      end
    end

    #
    def build_matcher_regexp(*patterns)
      parts = []
      patterns.each do |pattern|
        case pattern
        when Regexp
          parts << pattern
        else
          parts << match_string_to_regexp(pattern)
        end
      end
      Regexp.new(parts.join('.*?'), Regexp::MULTILINE)
    end
=end

    end

  end
end
