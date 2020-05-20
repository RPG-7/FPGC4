#!/usr/bin/python3
"""
Main executable for C compiler.
This compiler is a modified version of the ShivyC compiler (C to x86_64 compiler, written in Python, see https://github.com/ShivamSarodia/ShivyC) by Shivam Sarodia.
It is modified to output B332 assembly instead of x86_64 assembly.
New features are/will be added as well, compared to the original version.
"""

"""
Currently the compiler is still a bit of a mess after converting the output stage to output B322 assembly.
There are random print statements, and things like the size parameter of registers/instructions still have to be removed.
Not all cases are tested yet, so for example divisions will result in x86_64 ish assembly that will not compile by the assembler.
"""

"""
The MIT License (MIT)

Copyright (c) 2016 Shivam Sarodia

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""

import argparse
import pathlib
import platform
import subprocess
import sys
import pprint

import shivyc.lexer as lexer
import shivyc.preproc as preproc

from shivyc.errors import error_collector, CompilerError
from shivyc.parser.parser import parse
from shivyc.il_gen import ILCode, SymbolTable, Context
from shivyc.asm_gen import ASMCode, ASMGen


def main():
    """Run the main compiler script."""

    if platform.system() != "Linux":
        err = "only x86_64 Linux is supported"
        print(CompilerError(err))
        return 1

    arguments = get_arguments()

    for file in arguments.files:
        process_file(file, arguments)

    error_collector.show()
    
    return 1


def process_file(file, args):
    """Process single file into object file and return the object file name."""
    print("processing file: ", file)
    if file[-2:] == ".c":
        return process_c_file(file, args)
    else:
        err = f"unknown file type: '{file}'"
        error_collector.add(CompilerError(err))
        return None


def process_c_file(file, args):
    """Compile a C file into an object file and return the object file name."""
    code = read_file(file)
    if not error_collector.ok():
        return None

    print("code:\n", code)

    token_list = lexer.tokenize(code, file)
    if not error_collector.ok():
        return None

    token_list = preproc.process(token_list, file)
    if not error_collector.ok():
        return None

    #print("token_list:\n", token_list)

    # If parse() can salvage the input into a parse tree, it may emit an
    # ast_root even when there are errors saved to the error_collector. In this
    # case, we still want to continue the compiler stages.
    ast_root = parse(token_list)

    if not ast_root:
        return None

    il_code = ILCode()

    symbol_table = SymbolTable()
    ast_root.make_il(il_code, symbol_table, Context())
    if not error_collector.ok():
        return None

    asm_code = ASMCode()

    # This is the part we want to modify to generate B322 ASM code instead
    ASMGen(il_code, symbol_table, asm_code, args).make_asm()
    asm_source = asm_code.full_code()
    #print("asm_source:\n", asm_source)
    if not error_collector.ok():
        return None

    
    return asm_source


def get_arguments():
    """Get the command-line arguments.

    This function sets up the argument parser. Returns a tuple containing
    an object storing the argument values and a list of the file names
    provided on command line.
    """
    desc = """Compile, assemble, and link C files. Option flags starting
    with `-z` are primarily for debugging or diagnostic purposes."""
    parser = argparse.ArgumentParser(
        description=desc, usage="shivyc [-h] [options] files...")

    # Files to compile
    parser.add_argument("files", metavar="files", nargs="+")

    # Boolean flag for whether to print register allocator performance info
    parser.add_argument("-z-reg-alloc-perf",
                        help="display register allocator performance info",
                        dest="show_reg_alloc_perf", action="store_true")

    return parser.parse_args()


def read_file(file):
    """Return the contents of the given file."""
    try:
        with open(file) as c_file:
            return c_file.read()
    except IOError as e:
        descrip = f"could not read file: '{file}'"
        error_collector.add(CompilerError(descrip))


def write_asm(asm_source, asm_filename):
    """Save the given assembly source to disk at asm_filename.

    asm_source (str) - Full assembly source code.
    asm_filename (str) - Filename to which to save the generated assembly.

    """
    try:
        with open(asm_filename, "w") as s_file:
            s_file.write(asm_source)
    except IOError:
        descrip = f"could not write output file '{asm_filename}'"
        error_collector.add(CompilerError(descrip))


def assemble(asm_name, obj_name):
    """Assemble the given assembly file into an object file."""
    try:
        subprocess.check_call(["as", "-64", "-o", obj_name, asm_name])
        return True
    except subprocess.CalledProcessError:
        err = "assembler returned non-zero status"
        error_collector.add(CompilerError(err))
        return False


def link(binary_name, obj_names):
    """Assemble the given object files into a binary."""

    try:
        crtnum = find_crtnum()
        if not crtnum: return

        crti = find_library_or_err("crti.o")
        if not crti: return

        linux_so = find_library_or_err("ld-linux-x86-64.so.2")
        if not linux_so: return

        crtn = find_library_or_err("crtn.o")
        if not crtn: return

        # find files to link
        subprocess.check_call(
            ["ld", "-dynamic-linker", linux_so, crtnum, crti, "-lc"]
            + obj_names + [crtn, "-o", binary_name])

        return True

    except subprocess.CalledProcessError:
        return False


def find_crtnum():
    """Search for the crt0, crt1, or crt2.o files on the system.

    If one is found, return its path. Else, add an error to the
    error_collector and return None.
    """
    for file in ["crt2.o", "crt1.o", "crt0.o"]:
        crt = find_library(file)
        if crt: return crt

    err = "could not find crt0.o, crt1.o, or crt2.o for linking"
    error_collector.add(CompilerError(err))
    return None


def find_library_or_err(file):
    """Search the given library file and return path if found.

    If not found, add an error to the error collector and return None.
    """
    path = find_library(file)
    if not path:
        err = f"could not find {file}"
        error_collector.add(CompilerError(err))
        return None
    else:
        return path


def find_library(file):
    """Search the given library file by searching in common directories.

    If found, returns the path. Otherwise, returns None.
    """
    search_paths = [pathlib.Path("/usr/local/lib/x86_64-linux-gnu"),
                    pathlib.Path("/lib/x86_64-linux-gnu"),
                    pathlib.Path("/usr/lib/x86_64-linux-gnu"),
                    pathlib.Path("/usr/local/lib64"),
                    pathlib.Path("/lib64"),
                    pathlib.Path("/usr/lib64"),
                    pathlib.Path("/usr/local/lib"),
                    pathlib.Path("/lib"),
                    pathlib.Path("/usr/lib"),
                    pathlib.Path("/usr/x86_64-linux-gnu/lib64"),
                    pathlib.Path("/usr/x86_64-linux-gnu/lib")]

    for path in search_paths:
        full = path.joinpath(file)
        if full.is_file():
            return str(full)
    return None


if __name__ == "__main__":
    sys.exit(main())