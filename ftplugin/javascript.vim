if exists("g:loaded_vimux_javascript_test") || &cp
  finish
endif
let g:loaded_vimux_javascript_test = 1

if !has("ruby")
  finish
end

command RunAllJasmineTests :call s:RunAllJasmineTests()
command RunFocusedJasmineTest :call s:RunFocusedJasmineTest()

function s:RunAllJasmineTests()
  ruby Jasmine.new.run_all
endfunction

function s:RunFocusedJasmineTest()
  ruby Jasmine.new.run_spec
endfunction

ruby << EOF
module VIM
  class Buffer
    def method_missing(method, *args, &block)
      VIM.command "#{method} #{self.name}"
    end
  end
end

require 'uri'
class Jasmine
  def current_file
    "http://localhost:8888/?&rand_#{Time.now.to_i}=1"
  end

  def current_line_number
    VIM::Buffer.current.line_number
  end

  def focussed_spec_name
    nested_describe = ''
    it_name = ''

    it_indent_level = 999
    last_describe_indent_level = 999
    seen_describe = false
    (current_line_number + 1).downto(1) do |line_number|
      if it_name.empty? &&
        !seen_describe &&
        (VIM::Buffer.current[line_number] =~ /(.*)(?:it)\("([^"]+)"/ ||
         VIM::Buffer.current[line_number] =~ /(.*)(?:it)\('([^']+)'/)

        it_indent_level = $1.length
        it_name = $2
      end

      if VIM::Buffer.current[line_number] =~ /(.*)(?:describe)\("([^"]+)"/ ||
         VIM::Buffer.current[line_number] =~ /(.*)(?:describe)\('([^']+)'/

        seen_describe = true
        current_describe_indent_level = $1.length
        if current_describe_indent_level < last_describe_indent_level &&
           current_describe_indent_level < it_indent_level
          nested_describe = nested_describe.empty? ? $2 : "#{$2} #{nested_describe}"
          last_describe_indent_level = current_describe_indent_level
        end

      end

    end

    spec_name = nested_describe
    spec_name += " #{it_name}" unless it_name.empty?

    URI.escape(spec_name)
  end

  def file_spec_name
    describe_name = ''

    1.upto(current_line_number + 1) do |line_number|
      if VIM::Buffer.current[line_number] =~ /(?:describe)\("([^"]+)"/ ||
         VIM::Buffer.current[line_number] =~ /(?:describe)\('([^']+)'/
        describe_name = $1
        break
      end
    end

    URI.escape(describe_name)
  end

  def run_spec
    send_to_vimux("#{test_command} '#{current_file}&spec=#{focussed_spec_name}'")
  end

  def run_all
    send_to_vimux("#{test_command} '#{current_file}&spec=#{file_spec_name}'")
  end

  def test_command
    "open -a 'Google Chrome'"
  end

  def send_to_vimux(test_command)
    Vim.command("call RunVimTmuxCommand(\"clear && #{test_command}\")")
  end
end
EOF
