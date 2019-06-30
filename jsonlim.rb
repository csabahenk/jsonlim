#!/usr/bin/env ruby

require 'json'

module JSONlim
extend self

  HEIGHT = :height

  def height obj
    case obj
    when [],{}
      0
    when Hash
      obj.values.map{|w| height w }.max + 1
    when Array
      obj.map{|v| height v }.max + 1
    else
      0
    end
  end

  private def format_rec(obj, max_depth=-1, out: STDOUT, indent: " "*4,
                         depth: 0, prefix: "", postfix: "")
    if max_depth != HEIGHT and max_depth < 0
      max_depth = [height(obj)+max_depth, 0].max
    end

    if (max_depth != HEIGHT and max_depth <= depth) or !(Hash === obj or Array === obj) or obj.empty?
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
        format_rec(v, max_depth, out: out, indent: indent, depth: depth+1,
                prefix: k.to_s.to_json + ": ", postfix: (i==obj.size-1) ? "" : ?,)
      }
    when Array
      obj.each_with_index { |v,i|
        format_rec(v, max_depth, out: out, indent: indent, depth: depth+1,
                postfix: (i==obj.size-1) ? "" : ?,)
      }
    end
    out << indent*depth + delim_close + postfix + "\n"
  end

  def format obj, max_depth=-1, out: STDOUT, indent: " "*4
    format_rec obj, max_depth, out: out, indent: indent
  end

end

if __FILE__ == $0
  require 'optparse'
  require 'yaml'

  depth = nil
  formats = {'json'=>JSON, 'yaml'=>YAML}
  format = 'json'
  height = false

  OptionParser.new do |op|
    op.on("-d", "--depth=N", "depth up to which unfold (integer or 'height' or '∞')") { |n| depth = n }
    op.on("-f", "--input-format=F", formats.keys.join(?,)) { |f| format = f }
    op.on("-H", "--show-height", "show height of object") { height = true }
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
  if height
    p JSONlim.height obj
  else
    JSONlim.format obj, *[depth].compact
  end
end
