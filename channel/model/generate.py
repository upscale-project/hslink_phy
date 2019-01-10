#!/usr/bin/env python

from scipy.signal import tf2ss, cont2discrete, step
from string import Template
import numpy as np
import argparse
import sys
import contextlib
import time

class Filter:
    def __init__(self, A, B, type):
        self.A = A
        self.B = B
        self.type = type

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--sys', type=str, default='sys.txt')
    parser.add_argument('--template', type=str, default='channel_template.v')
    parser.add_argument('-o', '--outfile', type=str, default='channel.v')

    args = parser.parse_args()

    delay, A_list, C_list = get_tfs(args.sys)

    filters = make_filters(A_list, C_list)
    N = len(filters)

    with open(args.template) as f:
        orig = f.read()
    t = Template(orig)

    s = t.substitute(N=str(N), 
                    filters=fmt_filters(filters), 
                    scale=ones_array(N),
                    delay=fmt(delay))

    with open(args.outfile, 'w') as f:
        f.write(s)

def get_tfs(fname):
    tfs = []

    with open(fname, 'r') as f:
        lines = [l.strip() for l in f.readlines()]

    delay = float(lines[0])
    A = ri2c(lines[1])
    C = ri2c(lines[2])

    return delay, A, C

def make_filters(A_list, C_list):
    filters = []
    k = 0

    while k < len(A_list):
        A = +C_list[k]
        B = -A_list[k]

        if A_list[k].imag == 0:
            if C_list[k].imag != 0:
                raise Exception('Invalid coefficients')
            type = 'real'
            k += 1
        else:
            type = 'cplx'
            k += 2
            
        filters.append(Filter(A=A, B=B, type=type))

    return filters

def fmt_filters(filters):
    f_str = ''
    for k, f in enumerate(filters):
        f_str += fmt_filter(k, f)
        if k != len(filters)-1:
            f_str += '\n\n'
    return f_str
        
def fmt_filter(k, f):
    # start with empty string
    s = ''

    # define the constants
    s += decl_cplx('A{}'.format(k), f.A) + '\n'
    s += decl_cplx('B{}'.format(k), f.B) + '\n'

    # define the filter type
    s += 'pwl_filter_pfe '

    # define the tolerance
    s += '#(.etol(etol)) '

    # specify the filter name
    s += 'filter_{}'.format(k)

    # define the I/Os
    s += '('
    s += '.in(in), '
    s += '.out(out_arr[{}]), '.format(k)
    s += '.A(A{}), '.format(k)
    s += '.B(B{})'.format(k)
    s += ');'

    return s

def decl_cplx(name, value):
    return 'complex ' + name + ' = ' + fmt_cplx(value) + ';'

def fmt_cplx(x):
    return "'{" + fmt(x.real) + ", " + fmt(x.imag) + "}"

def ones_array(N):
    return "'{" + ", ".join(["1.0"]*N) + "}"

def fmt(x):
    return '{:0.12e}'.format(x)

def ri2c(s):
    a = [float(x) for x in s.split(' ')]
    return [complex(r, i) for r, i in pairs(a)]

# reference: https://opensourcehacker.com/2011/02/23/tuplifying-a-list-or-pairs-in-python/
def pairs(a):
    return zip(a[::2], a[1::2])

if __name__ == '__main__':
    main()
