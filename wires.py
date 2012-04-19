"""Utility module for parsing wires from a file."""
import re


def get_wires(filename):
    """Parse all the wire names in a file.

    Assumes all wirenames are declared on the same line as the 'wire'
    declaration.
    """
    with open(filename) as f:
        for line in f:
            if 'wire' in line:
                # if a wire is immediately assigned,
                # only parse the left hand side
                if '=' in line:
                    line = line.split('=')[0]
                tokens = line.split()[1:]
                for token in tokens:
                    # wirenames consist of letters, numbers, and underscores
                    cleaned = re.search('[a-zA-Z0-9_]*', token).group(0)
                    if cleaned:
                        yield cleaned
