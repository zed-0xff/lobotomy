def prepare_nested_layouts layouts

  layouts_by_name = Hash[*layouts.map{|l| [l.identifier.tr('/',''),l] }.flatten]

  layouts.each do |layout|
    if parent_name = layout.attributes[:layout]
#      puts "[.] layout #{layout.identifier} needs a parent #{parent_name.inspect}"
      unless parent_layout = layouts_by_name[parent_name]
        raise "unknown parent layout #{parent_name.inspect}"
      end

      # HACK #1
      new_raw_content = parent_layout.raw_content.gsub(/<%=\s*yield\s*%>/, layout.raw_content)
      raise "cannot find '<%= yield %>' in parent layout" if new_raw_content == parent_layout.raw_content

      # HACK #2
      layout.instance_variable_set('@raw_content',new_raw_content)
    end
  end
end
