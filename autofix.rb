# encoding: UTF-8

# author: Roman Grundkiewicz

input_file = ARGV[0]
output_file = ARGV[1] || input_file
raise ArgumentError, "Pierwszy argument oznacza plik wejściowy, drugi wyjściowy. Jeden argument oznacza nadpisanie wejścia. Skrypt jest głupi i nie posprząta wszystkiego." unless input_file

conjunctions = %w{z do na za u w od po a i że ze we o}
CONJUNCTIONS = conjunctions += conjunctions.map{ |c| c.capitalize }
COMMANDS = %w{\ref \cite}
INTERWORDS = %w{np. Np. i.e. tzw. m.in. M.in. tj. itd., itp., min. maks. por. zob. tzn.}

lines = File.readlines(input_file)
File.open("backup_#{input_file}", 'w+'){ |f| f.write(lines) } if input_file == output_file

def message(text, type="naprawiono")
  puts "** #{type} ** line #{@nr + 1} ** #{text} ** #{@line.chomp} **"
end

def comment?
  @line.start_with?("%")
end

def escape_letters
  CONJUNCTIONS.each do |c|
    result = @line.gsub!(" #{c} ", " #{c}~")
    message("wstawiono ~ za wyrazem #{c}") if result
    result = @line.gsub!(/^#{c} /, "#{c}~")
    message("wstawiono ~ za wyrazem #{c}") if result
  end
end

def escape_commands
  COMMANDS.each do |c|
    result = @line.gsub!(" #{c}", "~#{c}")
    message("wstawiono ~ przed komendą #{c}") if result
  end
end

def escape_abbr_end
  if @line =~ /([A-Z]+)([\.:])/
    @line.gsub!(/[A-Z]+[\.:]/, "#{$1}\\@#{$2}")
    message("wstawiono \\@ za skrótem #{$1}#{$2} na końcu zdania")
  end
end

def escape_interword_spacing
  INTERWORDS.each do |c|
    result = @line.gsub!("#{c} ", "#{c}\\ ")
    message("wstawiono \\ po skrócie #{c} w zdaniu") if result
  end
end

def remove_space_before_footnote
  result = @line.gsub!(/\s+\\footnote/, "\\footnote")
  message("usunięto odstęp przed komendą \\footnote") if result
  message("linia rozpoczyna się od komendy \\footnote", "uwaga") if @line =~ /^\\footnote/
end

def remove_spacing_before_label
  result = @line.gsub!(/\s+\\label/, "\\label")
  message("usunięto białe znaki przed komendą \\label") if result
end

new_content = ""
lines.each_with_index do |line, number|
  @line = line
  @nr = number

  unless comment?
    escape_letters
    escape_commands
    #escape_abbr_end
    escape_interword_spacing
    remove_space_before_footnote
    remove_spacing_before_label
  end

  new_content += @line
end

File.open(output_file, "w+"){ |f| f.write(new_content) }
