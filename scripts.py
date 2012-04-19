import sys

from wires import get_wires


def generate_debug(filename):
    """Generate print statements for every wire in a file."""
    for wire in get_wires(filename):
        print '$display("%s: %%b", %s);' % (wire, wire)


if __name__ == "__main__":
    if sys.argv[1] == 'debug':
        sys.exit(generate_debug(sys.argv[2]))
