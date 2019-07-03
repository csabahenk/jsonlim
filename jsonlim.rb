#!/usr/bin/env ruby

require 'json'

module JSONlim
extend self

  HEIGHT = :height

  def height obj, max_height: HEIGHT
    case obj
    when Hash,Array
      return 0 if obj.empty?
    else
      return 0
    end

    return HEIGHT if max_height == 0

    case obj
    when Hash
      obj.each_value
    when Array
      obj.each
    end.lazy.map {|v|
      h = height v, max_height: max_height == HEIGHT ? HEIGHT : max_height-1
      return HEIGHT if h == HEIGHT
      h
    }.max + 1
  end

  private def format_rec(obj, max_depth: nil, min_height: nil, out: STDOUT, indent: " "*4,
                         depth: 0, prefix: "", postfix: "")
    if Integer === max_depth and max_depth < 0
      max_depth = [height(obj)+max_depth, 0].max
    end

    if (!(Hash === obj or Array === obj) or obj.empty? or case true
      when !!max_depth
        max_depth != HEIGHT and max_depth <= depth
      when !!min_height
        height(obj, max_height: min_height) != HEIGHT
      else
        raise ArgumentError, "missing parameters"
      end
    )
      return out << indent*depth + prefix + obj.to_json + postfix + "\n"
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
                   prefix: k.to_s.to_json + ": ", postfix: (i==obj.size-1) ? "" : ?,)
      }
    when Array
      obj.each_with_index { |v,i|
        format_rec(v, max_depth: max_depth, min_height: min_height, out: out, indent: indent,
                   depth: depth + 1,
                   postfix: (i==obj.size-1) ? "" : ?,)
      }
    end
    out << indent*depth + delim_close + postfix + "\n"
  end

  def format obj, max_depth: nil, min_height: nil, out: STDOUT, indent: " "*4
    unless max_depth or min_height
      max_depth = -1
    end

    format_rec obj, max_depth: max_depth, min_height: min_height, out: out, indent: indent
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

  OptionParser.new do |op|
    op.on("-d", "--depth=N", "depth up to which unfold (integer or 'height' or '∞')") { |n| depth = n }
    op.on("-h", "--height=N", "height over which unfold", Integer) { |n| height = n }
    op.on("-f", "--input-format=F", formats.keys.join(?,)) { |f| format = f }
    op.on("-H", "--show-height", "show height of object") { show_height = true }
  end.parse!

  depth = case depth
  when nil
    nil
  when "height", "infinity", "infty", ?∞
    JSONlim::HEIGHT
  else
    Integer(depth)
  end

  obj = formats[format].load($<)
  if show_height
    p JSONlim.height obj
  else
    JSONlim.format obj, max_depth: depth, min_height: height
  end
end
