require "racc/parser"
require "ripper"
require "fisk"
require "set"

module ASMREPL

  class Parser < Racc::Parser
    def initialize
      @registers = Set.new Fisk::Registers.constants.map(&:to_s)
      @instructions = Set.new Fisk::Instructions.constants.map(&:to_s)
    end

    def parse input
      @tokens = Ripper.lex input
      do_parse
    end

    def new_command mnemonic, arg1, arg2
      [:command, mnemonic, arg1, arg2]
    end

    def new_tuple mnemonic, arg1
      [:command, mnemonic, arg1]
    end

    def new_single mnemonic
      [:command, mnemonic]
    end

    def next_token
      while tok = @tokens.shift
        next if tok[1] == :on_sp
        m = tok && [tok[1], tok[2]]
        case m
        in [:on_ident, ident]
          return case ident
          when "qword" then [:qword, ident]
          when "word"  then [:word, ident]
          when "dword" then [:dword, ident]
          when "byte"  then [:byte, ident]
          when "ptr"   then [:ptr, ident]
          else
            if ident.upcase == "RIP"
              [:on_rip, ident]
            elsif ident.upcase == "MOVABS"
              [:on_instruction, Fisk::Instructions::MOV]
            else
              if @instructions.include?(ident.upcase)
                [:on_instruction, Fisk::Instructions.const_get(ident.upcase)]
              elsif @registers.include?(ident.upcase)
                [:on_register, Fisk::Registers.const_get(ident.upcase)]
              else
                m
              end
            end
          end
        in [:on_op, ident]
          return case ident
          when "+" then [:plus, ident]
          when "-" then [:minus, ident]
          else
            m
          end
        else
          return m
        end
      end
    end
  end
end

require "asmrepl/parser.tab"
