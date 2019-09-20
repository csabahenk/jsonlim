#!/usr/bin/env ruby

require 'json'

module JSONlim
extend self

  INFINITY = :∞

  def height obj, max_height: INFINITY
    case obj
    when Hash,Array
      return 0 if obj.empty?
    else
      return 0
    end

    return INFINITY if max_height == 0

    case obj
    when Hash
      obj.each_value
    when Array
      obj.each
    end.lazy.map {|v|
      h = height v, max_height: max_height == INFINITY ? INFINITY : max_height-1
      return INFINITY if h == INFINITY
      h
    }.max + 1
  end

  def format_rec(obj, max_depth: nil, min_height: nil, out: STDOUT, indent: " "*4,
                         depth: 0, prefix: "", postfix: "", &repr)
    if (!(Hash === obj or Array === obj) or obj.empty? or case true
      when !!max_depth
        max_depth != INFINITY and max_depth <= depth
      when !!min_height
        height(obj, max_height: min_height) != INFINITY
      else
        raise ArgumentError, "missing parameters"
      end
    )
      return out << indent*depth + prefix + repr[obj] + postfix + "\n"
    end

    delim_open, delim_close = case obj
    when Hash
      %w[{ }]
    when Array
      %w<[ ]>
    end

    out << indent*depth + prefix + delim_open + "\n"
    case obj
    when Hash
      obj.each_with_index { |w,i|
        k,v=w
        format_rec(v, max_depth: max_depth, min_height: min_height, out: out, indent: indent,
                   depth: depth + 1,
                   prefix: k.to_s.to_json + ": ", postfix: (i==obj.size-1) ? "" : ?,, &repr)
      }
    when Array
      obj.each_with_index { |v,i|
        format_rec(v, max_depth: max_depth, min_height: min_height, out: out, indent: indent,
                   depth: depth + 1,
                   postfix: (i==obj.size-1) ? "" : ?,, &repr)
      }
    end
    out << indent*depth + delim_close + postfix + "\n"
  end
  private :format_rec

  def format obj, max_depth: nil, min_height: nil, out: STDOUT, indent: " "*4, &repr
    unless max_depth or min_height
      max_depth = -1
    end
    max_depth,min_height = [max_depth,min_height].map { |v|
      if Integer === v and v < 0
        [height(obj)+v, 0].max
      else
        v
      end
    }

    repr ||= :to_json
    format_rec obj, max_depth: max_depth, min_height: min_height, out: out, indent: indent, &repr
  end

end

if __FILE__ == $0
  require 'optparse'
  require 'yaml'

  depth = nil
  height = nil
  formats = {'json'=>JSON, 'yaml'=>YAML}
  format = 'json'
  show_height = false

  parse_numarg = proc do |v|
    case v
    when nil
      nil
    when "infinity", "infty", ?∞
      JSONlim::INFINITY
    else
      Integer(v)
    end
  end

  OptionParser.new do |op|
    op.on("-d", "--depth=N", "depth up to which unfold (integer or 'inf(ini)ty' or '∞')") { |n| depth = parse_numarg[n] }
    op.on("-h", "--height=N", "height over which unfold (integer or 'inf(ini)ty' or '∞')") { |n| height = parse_numarg[n] }
    op.on("-f", "--input-format=F", formats.keys.join(?,)) { |f| format = f }
    op.on("-H", "--show-height", "show height of object") { show_height = true }
  end.parse!

  obj = formats[format].load($<)
  if show_height
    p JSONlim.height obj
  else
    JSONlim.format obj, max_depth: depth, min_height: height
  end
end
