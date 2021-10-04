task :default do
  sh "rake -T"
end

desc "build syntax highlight"
task :rouge do
  # https://github.com/jneen/rouge
  sh "gem install rouge"
  # rougify help style
  # available themes:
  #   base16, base16.dark, base16.light, base16.monokai, base16.monokai.dark, base16.monokai.light, base16.solarized, base16.solarized.dark, base16.solarized.light, colorful, github, gruvbox, gruvbox.dark, gruvbox.light, igorpro, molokai, monokai, monokai.sublime, pastie, thankful_eyes, tulip
  # https://spsarolkar.github.io/rouge-theme-preview/
  style = 'github'
  sh "rougify style #{style} > webpack/src/rouge.css"
end


desc "build resources"
task :webpack do
  Dir.chdir "webpack" do
    sh "npm run build"
  end
end
