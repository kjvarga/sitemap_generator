module XmlMacros
  def gzipped_xml_file_should_validate_against_schema(xml_gz_filename, schema_name)
    Zlib::GzipReader.open(xml_gz_filename) do |xml_file|
      xml_data_should_validate_against_schema(xml_file.read, schema_name)
    end
  end

  # Validate XML against a local schema file.
  #
  # `schema_name` gives the name of the schema file to validate against.  The schema
  # file is looked for in `spec/support/schemas/<schema_name>.xsd`.
  def xml_data_should_validate_against_schema(xml, schema_name)
    xml = xml.is_a?(String) ? xml : xml.to_s
    doc = Nokogiri::XML(xml)
    schema_file = File.join(File.dirname(__FILE__), 'schemas', "#{schema_name}.xsd")
    schema = Nokogiri::XML::Schema File.read(schema_file)
    expect(schema.validate(doc)).to eq([])
  end

  # Validate a fragment of XML against a schema.  Builds a document with a root
  # node for you so the fragment can be validated.
  #
  # Unfortunately Nokogiri doesn't support validating
  # documents with multiple namespaces.  So we have to extract the element
  # and create a new document from it.  If the xmlns isn't set on the element
  # we get an error like:
  #
  #    Element 'video': No matching global declaration available for the validation root.
  #
  # <tt>xml</tt> The XML fragment
  # <tt>schema_name</tt> the name of the schema file to validate against.  The schema
  # file is looked for in `spec/support/schemas/<schema_name>.xsd`.
  # <tt>xmlns</tt> A hash with only one key which gives the XML namespace and associated
  # URI.  Sometimes one needs to specify a prefix to the namespace, in which case this would
  # look like: 'xmlns:video' => 'http://www.google.com/schemas/sitemap-video/1.1'
  #
  # Example:
  #   xml_fragment_should_validate_against_schema('<video/>', 'sitemap-video', 'xmlns:video' => 'http://www.google.com/schemas/sitemap-video/1.1')
  #
  #   This validates the given XML using the spec/support/schemas/sitemap-video.xsd`
  #   schema.  The XML namespace `xmlns:video='http://www.google.com/schemas/sitemap-video/1.1'` is automatically
  #   added to the root element for you.
  def xml_fragment_should_validate_against_schema(xml, schema_name, xmlns={})
    xml = xml.is_a?(String) ? xml : xml.to_s
    doc = Nokogiri::XML(xml)
    doc.root.send(:[]=, *xmlns.first)
    xml_data_should_validate_against_schema(doc, schema_name)
  end

  def gzipped_xml_file_should_have_minimal_whitespace(xml_gz_filename)
    Zlib::GzipReader.open(xml_gz_filename) do |xml_file|
      xml_data_should_have_minimal_whitespace xml_file.read
    end
  end

  def xml_data_should_have_minimal_whitespace(xml_data)
    expect(xml_data).not_to match(/^\s/)
    expect(xml_data).not_to match(/\s$/)
    expect(xml_data).not_to match(/\s\s+/)
    expect(xml_data).not_to match(/\s[<>]/)
    expect(xml_data).not_to match(/[<>]\s/)
  end
end
