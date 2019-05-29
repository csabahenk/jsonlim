#!/usr/bin/env ruby

require 'json'

def jsonlim(obj, max_level=-1, out: STDOUT, indent: " "*4, level: 0, prefix: "", postfix: "")
  depth = proc { |o|
    case o
    when [],{}
      0
    when Hash
      o.values.map(&depth).max + 1
    when Array
      o.map(&depth).max + 1
    else
      0
    end
  }

  if max_level and max_level < 0
    max_level = [depth[obj]+max_level, 0].max
  end

  if (max_level||level+1) <= level or !(Hash === obj or Array === obj) or obj.empty?
    return out << indent*level + prefix + obj.to_json + postfix + "\n"
  end

  delim_open, delim_close = case obj
  when Hash
    %w[{ }]
  when Array
    %w<[ ]>
  end

  out << indent*level + prefix + delim_open + "\n"
  case obj
  when Hash
    obj.each_with_index { |w,i|
      k,v=w
      jsonlim(v, max_level, out: out, indent: indent, level: level+1,
              prefix: k.to_s.to_json + ": ", postfix: (i==obj.size-1) ? "" : ?,)
    }
  when Array
    obj.each_with_index { |v,i|
      jsonlim(v, max_level, out: out, indent: indent, level: level+1,
              postfix: (i==obj.size-1) ? "" : ?,)
    }
  end
  out << indent*level + delim_close + postfix + "\n"
end

if __FILE__ == $0
  lvl = Integer($*.shift)
  jsonlim JSON.load($<), lvl
end
