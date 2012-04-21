from itertools import chain
import sys

from wires import get_inputs, get_outputs, get_wires


def generate_debug(filename):
    """Generate print statements for every wire in a file."""
    for wire in chain(get_inputs(filename), get_outputs(filename), get_wires(filename)):
        print '$display("%s: %%b", %s);' % (wire, wire)


def pc_trace(filename):
    with open(filename) as f:
        for line in f:
            tokens = line.strip().split(":")
            if tokens[0] == "time":
                print "TIME", tokens[1]
            elif tokens[0] == "m_pc_plus_one":
                print "PC+1", tokens[1]
            elif tokens[0] == "m_imem_out":
                print "INSN", tokens[1]


if __name__ == "__main__":
    if sys.argv[1] == 'debug':
        sys.exit(generate_debug(sys.argv[2]))
    elif sys.argv[1] == 'trace':
        sys.exit(pc_trace(sys.argv[2]))
