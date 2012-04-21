"""Utility module for parsing wires from a file."""
import re


def _get_tokens(filename, keyword):
    """Parse all keyworded tokens in a file.

    Assumes all wirenames are declared on the same line as the 'wire'
    declaration.
    """
    with open(filename) as f:
        for line in f:
            if keyword in line:
                # if a wire is immediately assigned,
                # only parse the left hand side
                if '=' in line:
                    line = line.split('=')[0]
                if '//' in line:
                    line = line.split('//')[0]
                tokens = line.split()[1:]
                for token in tokens:
                    # wirenames consist of letters, numbers, and underscores
                    cleaned = re.search('[a-zA-Z0-9_]*', token).group(0)
                    if cleaned:
                        yield cleaned


def get_inputs(filename):
    """Parse all the inputs in a file.

    Assumes all wirenames are declared on the same line as the 'wire'
    declaration.
    """
    for token in _get_tokens(filename, 'input'):
        yield token

def get_outputs(filename):
    """Parse all the outputs in a file.

    Assumes all wirenames are declared on the same line as the 'wire'
    declaration.
    """
    for token in _get_tokens(filename, 'output'):
        yield token


def get_wires(filename):
    """Parse all the wire names in a file.

    Assumes all wirenames are declared on the same line as the 'wire'
    declaration.
    """
    for token in _get_tokens(filename, 'wire'):
        yield token
