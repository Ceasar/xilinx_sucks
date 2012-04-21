file = File.new(ARGV[0], "r")

imem_out_regex = /(^.*?)imem_out: (\d+)$/


general_regex = /(^.*): (\d+)$/

def replace(insn, r)
  if insn == "0000"
    (r == "000000000000") ? "NOP" : "BRANCH #{r[0..3]} #{r[4..15]}" + "\t\t\t #{insn} #{r}"
  elsif insn == "0001"
    "ARITH d=#{r[0..2]} s=#{r[3..5]} kind=#{r[6..8]} t=#{r[9..12]}" + "\t\t\t #{insn} #{r}"
  elsif insn == "0010"
    "CMP s=#{r[0..2]} kind=#{r[3..4]} #{r[5..12]}" + "\t\t\t #{insn} #{r}"
  elsif insn == "0100"
    "JSR kind=#{r[0]} #{r[1..12]}" + "\t\t\t #{insn} #{r}"
  elsif insn == "0101"
    "BOOL d=#{r[0..2]} s=#{r[3..5]} kind=#{r[6..8]} t=#{r[9..12]}" + "\t\t\t #{insn} #{r}"
  elsif insn == "0110"
    "LOAD #{r}" + "\t\t\t #{insn} #{r}"
  elsif insn == "0111"
    "STORE #{r}" + "\t\t\t #{insn} #{r}"
  elsif insn == "1000"
    "RTI" + "\t\t\t #{insn} #{r}"
  elsif insn == "1001"
    "CONST #{r[0..2]} #{r[3..15]}" + "\t\t\t #{insn} #{r}"
  elsif insn == "1010"
    "SHIFT d=#{r[0..2]} s=#{r[3..5]} kind=#{r[6..7]} t=#{r[8..11]}" + "\t\t\t #{insn} #{r}"
  elsif insn == "1100"
    "JUMP #{r[0..12]}" + "\t\t\t #{insn} #{r}"
  elsif insn == "1101"
    "HICONST d=#{r[0..2]} 1 #{r[5..12]}" + "\t\t\t #{insn} #{r}"
  elsif insn == "1111"
    "TRAP #{r[5..12]}" + "\t\t\t #{insn} #{r}"
  end
end

while line = file.gets
  match = imem_out_regex.match(line)
  if !match.nil?
    puts "#{match[1]}imem_out: #{replace(match[2][0..3], match[2][4..15])}"
  else
    match = general_regex.match(line)
    if !match.nil?
        if !line.include? "opcode" and line.include? "pc"
            puts "#{match[1]}: #{match[2].to_i(2).to_s(16)}"
        else
            puts line
        end
    else
        puts line
    end
  end 
end
