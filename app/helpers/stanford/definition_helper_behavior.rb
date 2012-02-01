module Stanford::DefinitionHelperBehavior
  # Generate a dt/dd pair given a Solr field
  # If you provide a :default value in the opts hash, 
  # then when the solr field is empty, the default value will be used.
  # If you don't provide a default value, this method will not generate html when the field is empty.
  def get_data_with_label(doc, label, field_string, opts={})
    if opts[:default] && !doc[field_string]
      doc[field_string] = opts[:default]
    end
    
    if doc[field_string]
      field = doc[field_string]
      text = "<dt>#{label}</dt><dd>"
      if field.is_a?(Array)
          field.each do |l|
            text += "#{h(l)}"
            if l != h(field.last)
              text += "<br/>"
            end
          end
      else
        text += h(field)
      end
      #Does the field have a vernacular equivalent? 
      if doc["vern_#{field_string}"]
        vern_field = doc["vern_#{field_string}"]
        text += "<br/>"
        if vern_field.is_a?(Array)
          vern_field.each do |l|
            text += "#{h(l)}"
            if l != h(vern_field.last)
              text += "<br/>"
            end
          end
        else
          text += h(vern_field)
        end
      end
      text += "</dd>"
      text
    end
  end
end