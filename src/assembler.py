import argparse
from enum import Enum
import sys

def extract_cli_settings():
    cli_parser = argparse.ArgumentParser(
        description='Translate IITK-Mini-MIPS assembly to its binary equivalent.'
    )
    cli_parser.add_argument('file', type=str, help='source assembly path')
    cli_parser.add_argument('-o', '--output', type=str, help='path to output file')
    cli_parser.add_argument('-coe', '--coe', action='store_true', help='emit .coe file format')
    return cli_parser.parse_args()

def decompose_asm_line(statement: str) -> tuple[str, list[str]]:
    statement = statement.lower()
    arg_list = [x.strip() for x in statement.split(',')]
    if arg_list == ['']:
        raise ValueError("Invalid input")
    op_split = arg_list[0].split()
    cmd = op_split[0].rstrip()
    if len(op_split) == 2:
        arg_list[0] = op_split[1].lstrip()
    elif len(op_split) == 1:
        arg_list = []
    else:
        raise ValueError("Malformed line")
    return cmd, arg_list

def encode_binary(statement: str) -> str:
    Role = Enum('Role', 'A B C D E F G H I J K')
    A, B, C, D, E, F, G, H, I, J, K = Role.A, Role.B, Role.C, Role.D, Role.E, Role.F, Role.G, Role.H, Role.I, Role.J, Role.K

    inst_encoding = {
        'add': (0x00, C, A, B),
        'sub': (0x00, C, A, B),
        'lw':  (0x23, B, G),
        'sw':  (0x2b, B, G),
        'beq': (0x04, A, B, E),
        'j':   (0x02, F),
        'add.s': (0x11, J, H, I),
        'mov.s': (0x11, J, H),
        'c.eq.s': (0x11, K, H, I),
    }

    special_codes = {
        'add': 0x20,
        'sub': 0x22,
        'add.s': 0x00,
        'mov.s': 0x06,
        'c.eq.s': 0x32,
    }

    format_codes = {
        'add.s': 0x10,
        'mov.s': 0x10,
        'c.eq.s': 0x10,
    }

    cmd, arg_list = decompose_asm_line(statement)
    bin_form = bin(inst_encoding[cmd][0])[2:].zfill(6) + '0' * 26

    if len(inst_encoding[cmd]) - 1 != len(arg_list):
        raise ValueError("Mismatch operand count")

    def reg_num(text):
        if text[0] != '$':
            raise ValueError("Invalid register")
        try:
            return int(text[1:])
        except ValueError:
            r = {
                'zero': 0, 'ra': 31, 'sp': 29, 'fp': 30, 'gp': 28, 'a0': 4,
                'a1': 5, 'a2': 6, 'a3': 7, 't0': 8, 't1': 9, 't2': 10, 't3': 11,
            }
            return r.get(text[1:], None)

    for idx, argx in enumerate(arg_list):
        role = inst_encoding[cmd][idx + 1]
        if role in [A, B, C]:
            reg = reg_num(argx)
            if reg is None or not (0 <= reg <= 31): raise ValueError("Reg fail")
            offset = [6, 11, 16][[A, B, C].index(role)]
            bin_form = bin_form[:offset] + bin(reg)[2:].zfill(5) + bin_form[offset + 5:]
        elif role == D:
            shift = int(argx)
            bin_form = bin_form[:21] + bin(shift)[2:].zfill(5) + bin_form[26:]
        elif role == E:
            imm = int(argx)
            bin_form = bin_form[:16] + bin(imm & 0xffff)[2:].zfill(16)
        elif role == F:
            addr = int(argx)
            bin_form = bin_form[:6] + bin((addr >> 2) & 0x3ffffff)[2:].zfill(26)
        elif role in [H, I, J]:
            reg = reg_num(argx)
            if reg is None or not (0 <= reg <= 31): raise ValueError("FPR fail")
            offset = {H: 16, I: 11, J: 21}[role]
            bin_form = bin_form[:offset] + bin(reg)[2:].zfill(5) + bin_form[offset + 5:]
        elif role == K:
            flag = int(argx)
            if not (0 <= flag <= 7): raise ValueError("Flag idx err")
            bin_form = bin_form[:21] + bin(flag)[2:].zfill(3) + '00' + bin_form[26:]
        elif role == G:
            if '(' in argx:
                val, reg = argx.split('(')
                base = reg.strip(')')
                offset = int(val)
                reg = reg_num(base)
                if reg is None: raise ValueError("Bad base reg")
                bin_form = bin_form[:6] + bin(reg)[2:].zfill(5) + bin_form[11:16] + bin(offset & 0xffff)[2:].zfill(16)

    if cmd in special_codes:
        bin_form = bin_form[:26] + bin(special_codes[cmd])[2:].zfill(6)
    if cmd in format_codes:
        bin_form = bin_form[:6] + bin(format_codes[cmd])[2:].zfill(5) + bin_form[11:]

    assert len(bin_form) == 32
    return bin_form

def compile_lines(script_lines: list[str]) -> list[str]:
    result = []
    for line in script_lines:
        line = line.split('#')[0].strip()
        if not line:
            continue
        result.append(encode_binary(line))
    return result

def launch_conversion():
    settings = extract_cli_settings()
    try:
        with open(settings.file, 'r') as f:
            script_lines = f.readlines()
    except Exception as e:
        print(f"File access error: {e}", file=sys.stderr)
        return

    compiled_bits = compile_lines(script_lines)

    if settings.output:
        try:
            with open(settings.output, 'w') as out:
                if settings.coe:
                    out.write('; COE Output\n')
                    out.write('memory_initialization_radix=2;\n')
                    out.write('memory_initialization_vector=\n')
                for val in compiled_bits[:-1]:
                    out.write(val + '\n')
                if compiled_bits:
                    out.write(compiled_bits[-1])
                if settings.coe:
                    out.write(';')
        except Exception as e:
            print(f"Output error: {e}", file=sys.stderr)
    else:
        if settings.coe:
            print('memory_initialization_radix=2;')
            print('memory_initialization_vector=')
        for val in compiled_bits[:-1]:
            print(val)
        if compiled_bits:
            print(compiled_bits[-1], end='')
        if settings.coe:
            print(';')

if __name__ == '__main__':
    launch_conversion()
