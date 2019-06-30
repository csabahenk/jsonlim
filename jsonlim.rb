#!/usr/bin/env ruby

require 'json'

module JSONlim
extend self

  private def format_rec(obj, max_depth=-1, out: STDOUT, indent: " "*4,
                         depth: 0, prefix: "", postfix: "")
    height = proc { |o|
      case o
      when [],{}
        0
      when Hash
        o.values.map(&height).max + 1
      when Array
        o.map(&height).max + 1
      else
        0
      end
    }

    if max_depth and max_depth < 0
      max_depth = [height[obj]+max_depth, 0].max
    end

    if (max_depth||depth+1) <= depth or !(Hash === obj or Array === obj) or obj.empty?
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

  lvl = nil
  formats = {'json'=>JSON, 'yaml'=>YAML}
  format = 'json'

  OptionParser.new do |op|
    op.on("-d", "--depth=N", Integer, "depth up to which unfold") { |n| lvl = n }
    op.on("-f", "--input-format=F", formats.keys.join(?,)) { |f| format = f }
  end.parse!

  JSONlim.format formats[format].load($<), *[lvl].compact
end
