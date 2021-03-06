# For complete documentation of this file, please see Geany's main documentation
[styling]
# Edit these in the colorscheme .conf file instead
default=default
comment=comment_line
commentblock=comment
commentdirective=comment
number=number_1
string=string_1
operator=operator
identifier=identifier_1
cpuinstruction=keyword_1
mathinstruction=keyword_2
register=type
directive=preprocessor
directiveoperand=keyword_3
character=character
stringeol=string_eol
extinstruction=keyword_4

[keywords]
instructions=xchg mov add sub sbb adc xor and or int lgdt lidt cli cld jmp std rep movsb movsw shl shr out in call not lodsw lodsb jcxz ret stosw stosb stosd push pop ltr iretd iret pusha popa movzx lea lodsd inc dec sti cmp je jz jne jnz rcr rcl cmove cmovne jnb jnc jb jc invlpg bts rdmsr wrmsr sgdt movsd div loop loopnz loopz test insw les repe cmpsb mul cwd lds repne repz repnz jnbe retf scasb scasw ja imul neg jns
registers=ax bx cx dx sp bp si di ah al bh bl ch cl dh dl eax ebx ecx edx esp ebp esi edi cs ds es ss fs gs cr0 cr1 cr2 cr3 cr4 cr5 cr6 cr7
directives=org macro brk db dw dd dq use16 use32 file include equ byte word dword if end times align repeat far short near format entry segment

[settings]
# default extension used when saving files
extension=asm

# the following characters are these which a "word" can contains, see documentation
#wordchars=_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789

# single comments, like # in this file
comment_single=;
# multiline comments
#comment_open=
#comment_close=

# set to false if a comment character/string should start at column 0 of a line, true uses any
# indentation of the line, e.g. setting to true causes the following on pressing CTRL+d
	#command_example();
# setting to false would generate this
#	command_example();
# This setting works only for single line comments
comment_use_indent=true

# context action command (please see Geany's main documentation for details)
context_action_cmd=

[indentation]
#width=4
# 0 is spaces, 1 is tabs, 2 is tab & spaces
#type=1

[build_settings]
# %f will be replaced by the complete filename
# %e will be replaced by the filename without extension
# (use only one of it at one time)
compiler=fasm "%f"

