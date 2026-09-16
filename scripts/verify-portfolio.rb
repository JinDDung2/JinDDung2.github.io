require "nokogiri"
require "uri"

root = ARGV.fetch(0, "_site")
pages = %w[index.html portfolio/index.html portfolio/adevspoon/index.html portfolio/givemeticon/index.html portfolio/my-rate/index.html]
errors = []
pages.each do |page|
  document = Nokogiri::HTML(File.read(File.join(root, page)))
  document.css("a[href], img[src], link[rel=stylesheet]").each do |element|
    href = element["href"] || element["src"]
    next if href.nil? || href.empty?
    uri = URI.parse(href)
    next if uri.scheme || uri.host
    path = uri.path.to_s
    target = if path.empty?
      File.join(root, page)
    elsif path.start_with?("/")
      File.join(root, path.delete_prefix("/"))
    else
      File.expand_path(path, File.dirname(File.join(root, page)))
    end
    target = File.join(target, "index.html") if File.directory?(target)
    unless File.file?(target)
      errors << "#{page}: missing #{href}"
      next
    end
    if uri.fragment
      linked_document = Nokogiri::HTML(File.read(target))
      errors << "#{page}: missing anchor #{href}" unless linked_document.css("[id]").any? { |node| node["id"] == uri.fragment }
    end
  end
  errors << "#{page}: expected one h1" unless document.css("h1").length == 1
  errors << "#{page}: reference link leaked" if document.css("a[href]").any? { |link| link["href"].include?("/artifacts/") || link["href"].include?("/Users/") }
  puts "#{page}: checked links, anchors, images and heading"
end
errors << "Reference artifacts were published" if File.exist?(File.join(root, "portfolio/artifacts"))
abort(errors.join("\n")) unless errors.empty?
puts "Portfolio checks passed"
