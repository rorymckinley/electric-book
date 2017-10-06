#!/usr/bin/env ruby

require 'highline'
require 'open3'
require 'fileutils'

def directory_has_contents?(path)
  # To deal with Windows and *nix-like
  # Ruby 2.4 has Dir.empty? which is a bit cleaner, but 2.4 only
  Dir.entries(path).any? { |i| i != '.' && i != '..' }
end

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

# What's next?
cli.say('Assembling epub...')

# Copy styles, images, text and package.opf to epub folder.
# The echo f preemptively answers xcopy's question whether
# this is a file (see https://stackoverflow.com/a/3018371).
# The > nul supresses command-line feedback (pseudo silent mode)

# Test copying options
cli.say('Copying styles...')
if subdirectory
  styles_path = File.join('_site', bookfolder, subdirectory, 'styles')
  if Dir.exist?(styles_path) and directory_has_contents?(styles_path)
    # Translation output, and an styles subdir for that translation exists:
    # create folder structure, and copy only the styles in that translation folder
    # Copy translated styles, after deleting original styles
    FileUtils.remove_entry_secure(File.join('_site', bookfolder, 'styles'))
    styles_dest_path = File.join('_site', 'epub', subdirectory, 'styles')
    FileUtils.mkdir_p(styles_dest_path)
    FileUtils.cp(Dir.glob(File.join(styles_path, '*.css')), styles_dest_path)
  else
    # Translation output, but no translated-styles subdirectory for that translation:
    # copy the original styles files only
    styles_dest_path = File.join('_site', 'epub', 'styles')
    FileUtils.mkdir(styles_dest_path)
    FileUtils.cp(Dir.glob(File.join('_site', bookfolder, 'styles', '*.css')), styles_dest_path)
  end
else
  # If original language output: copy only files in fonts/epub
  styles_dest_path = File.join('_site', 'epub', 'styles')
  FileUtils.mkdir(styles_dest_path)
  FileUtils.cp(Dir.glob(File.join('_site', bookfolder, 'styles', '*.css')), styles_dest_path)
end
cli.say('Styles copied')
