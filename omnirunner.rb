#!/usr/bin/env ruby

require 'highline'
require 'open3'

cli = HighLine.new

# epub
# Encouraging message
cli.say("Okay, let's make an epub.")

begin
  # Ask user which folder to process
  answer = cli.ask("Which book folder are we processing?") { |q| q.default = "book" }

  if File.exist?(answer)
    bookfolder = answer
  else
    cli.say("Sorry #{answer} doesn't exist. Try again")
  end
end until bookfolder

begin
  # Ask if we're outputting the files from a subdirectory
  answer = cli.ask("If you're outputting files in a subdirectory (e.g. a translation), type its name. Otherwise, hit enter.")

  break if answer.empty?

  if File.exist?(File.join(bookfolder, answer))
    subdirectory = answer
  else
    cli.say("Sorry #{File.join(bookfolder, answer)} doesn't exist. Try again")
  end
end until subdirectory

begin
# Ask whether to include boilerplate mathjax directory
  answer = cli.ask("Include mathjax? Enter y for yes (or hit enter for no).") { |q| q.default = "n" }

  epubIncludeMathJax = (['y', 'n'].include?(answer) ? answer : nil)
end until epubIncludeMathJax

# Ask the user to add any extra Jekyll config files, e.g. _config.images.print-pdf.yml
config = cli.ask(%Q{
Any extra config files?
Enter filenames (including any relative path), comma separated, no spaces. E.g.
_configs/_config.myconfig.yml
If not, just hit return.
})

# Ask about validation
epubValidation = cli.ask("Shall we try to run EpubCheck when we're done? Hit enter for yes, or any key and enter for no.")

if subdirectory
  cli.say("Generating HTML for #{bookfolder}-#{subdirectory}.epub...")
else
  cli.say("Generating HTML for #{bookfolder}.epub...")
end 

# ...and run Jekyll to build new HTML
stdout, stderr, _ = Open3.capture3(%Q{bundle exec jekyll build --config="_config.yml,_configs/_config.epub.yml,#{config}"})
cli.say("output #{stdout}")
cli.say("errors #{stderr}\n")
cli.say("HTML generated")
