if exists("g:loaded_vimux_javascript_test") || &cp
  finish
endif
let g:loaded_vimux_javascript_test = 1

if !has("ruby")
  finish
end

command RunJasmine :call s:RunJasmine()

function s:RunJasmine()
  ruby Jasmine.new.run_all
endfunction

ruby << EOF
module VIM
  class Buffer
    def method_missing(method, *args, &block)
      VIM.command "#{method} #{self.name}"
    end
  end
end

class Jasmine
  def current_file
    "http://localhost:8888/?&rand_#{Time.now.to_i}=1"
  end

  def run_all
    send_to_vimux("#{test_command} '#{current_file}'")
  end

  def test_command
    'open'
  end

  def send_to_vimux(test_command)
    Vim.command("call RunVimTmuxCommand(\"clear && #{test_command}\")")
  end
end
EOF
