"""IL commands for labels, jumps, and function calls."""

import shivyc.asm_cmds as asm_cmds
import shivyc.spots as spots
from shivyc.il_cmds.base import ILCommand
from shivyc.spots import LiteralSpot, RegSpot, MemSpot


class Label(ILCommand):
    """Label - Analogous to an ASM label."""

    def __init__(self, label): # noqa D102
        """The label argument is an string label name unique to this label."""
        self.label = label

    def inputs(self): # noqa D102
        return []

    def outputs(self): # noqa D102
        return []

    def label_name(self):  # noqa D102
        return self.label

    def make_asm(self, spotmap, home_spots, get_reg, asm_code): # noqa D102
        asm_code.add(asm_cmds.Label(self.label))


class Jump(ILCommand):
    """Jumps unconditionally to a label."""

    def __init__(self, label): # noqa D102
        self.label = label

    def inputs(self): # noqa D102
        return []

    def outputs(self): # noqa D102
        return []

    def targets(self): # noqa D102
        return [self.label]

    def make_asm(self, spotmap, home_spots, get_reg, asm_code): # noqa D102
        asm_code.add(asm_cmds.Jump(self.label))


class _GeneralJump(ILCommand):
    """General class for jumping to a label based on condition."""

    # ASM command to output for this jump IL command.
    # (asm_cmds.Je for JumpZero and asm_cmds.Jne for JumpNotZero)
    asm_cmd = None

    def __init__(self, cond, label): # noqa D102
        self.cond = cond
        self.label = label

    def inputs(self): # noqa D102
        return [self.cond]

    def outputs(self): # noqa D102
        return []

    def targets(self): # noqa D102
        return [self.label]

    def make_asm(self, spotmap, home_spots, get_reg, asm_code): # noqa D102
        size = self.cond.ctype.size

        if isinstance(spotmap[self.cond], LiteralSpot):
            r = get_reg()
            asm_code.add(asm_cmds.Mov(r, spotmap[self.cond], size))
            cond_spot = r
            zero_spot = LiteralSpot("0")
            asm_code.add(asm_cmds.Cmp(cond_spot, zero_spot, size))

        elif isinstance(spotmap[self.cond], MemSpot):
            asm_code.add(asm_cmds.Read(spotmap[self.cond], spots.RegSpot("r12"), size))
        else:
            zero_spot = LiteralSpot("0")
            asm_code.add(asm_cmds.Cmp(spotmap[self.cond], zero_spot, size))


        asm_code.add(self.command(RegSpot("r0"), RegSpot("r12"), LiteralSpot(2)))
        #not bgt r12 r0 2 -> bge r0 r12 2
        #not bge r12 r0 2 -> bgt r0 r12 2

        #not beq r12 r0 2 -> bne r0 r12 2
        #not bne r12 r0 2 -> beq r0 r12 2

        asm_code.add(asm_cmds.Jump(self.label))

        #asm_code.add(self.command(self.label))

# NOTE:
# these comparisons are inverted, because in b332 asm we jump to offset 2 to skip the jump to label
# confusing, so think hard on this!

class JumpZero(_GeneralJump):
    """Jumps to a label if given condition is zero."""

    command = asm_cmds.Bne


class JumpNotZero(_GeneralJump):
    """Jumps to a label if given condition is zero."""

    command = asm_cmds.Beq


class Return(ILCommand):
    """RETURN - returns the given value from function.

    If arg is None, then returns from the function without putting any value
    in the return register. Today, only supports values that fit in one
    register.
    """

    def __init__(self, arg=None): # noqa D102
        # arg must already be cast to return type
        self.arg = arg

    def inputs(self): # noqa D102
        return [self.arg]

    def outputs(self): # noqa D102
        return []

    def clobber(self):  # noqa D102
        return [spots.RAX]

    def abs_spot_pref(self):  # noqa D102
        return {self.arg: [spots.RAX]}

    def make_asm(self, spotmap, home_spots, get_reg, asm_code): # noqa D102
        if self.arg and spotmap[self.arg] != spots.RAX:
            size = self.arg.ctype.size

            if isinstance(spotmap[self.arg], spots.LiteralSpot):
                asm_code.add(asm_cmds.Load(spotmap[self.arg], spots.RAX, size))
            elif isinstance(spotmap[self.arg], spots.MemSpot):
                asm_code.add(asm_cmds.Read(spotmap[self.arg], spots.RegSpot("r12"), size))
                asm_code.add(asm_cmds.Mov(spots.RAX, spots.RegSpot("r12"), size))
            elif isinstance(spotmap[self.arg], spots.RegSpot):
                asm_code.add(asm_cmds.Mov(spots.RAX, spotmap[self.arg], size))


            

        asm_code.add(asm_cmds.Mov(spots.RSP, spots.RBP))



        #asm_code.add(asm_cmds.Pop(spots.RBP, None, 8))
        
        asm_code.add(asm_cmds.Read(spots.RSP, spots.RBP))
        asm_code.add(asm_cmds.Add(spots.RSP, spots.LiteralSpot(1)))
        

        #asm_code.add(asm_cmds.Ret())
        asm_code.add(asm_cmds.Read(spots.RSP, spots.RegSpot("r12")))
        asm_code.add(asm_cmds.Add(spots.RSP, spots.LiteralSpot(1)))
        asm_code.add(asm_cmds.Jumpr(spots.LiteralSpot(4), spots.RegSpot("r12")))


class Call(ILCommand):
    """Call a given function.

    func - Pointer to function
    args - Arguments of the function, in left-to-right order. Must match the
    parameter types the function expects.
    ret - If function has non-void return type, IL value to save the return
    value. Its type must match the function return value.
    """

    arg_regs = [spots.RDI, spots.RSI, spots.RDX, spots.RCX, spots.R8, spots.R9]

    def __init__(self, func, args, ret): # noqa D102
        self.func = func
        self.args = args
        self.ret = ret
        self.void_return = self.func.ctype.arg.ret.is_void()

        if len(self.args) > len(self.arg_regs):
            raise NotImplementedError("too many arguments")

    def inputs(self): # noqa D102
        return [self.func] + self.args

    def outputs(self): # noqa D102
        return [] if self.void_return else [self.ret]

    def clobber(self): # noqa D102
        # All caller-saved registers are clobbered by function call
        return [spots.RAX, spots.RCX, spots.RDX, spots.RSI, spots.RDI,
                spots.R8, spots.R9, spots.R10, spots.R11]

    def abs_spot_pref(self): # noqa D102
        prefs = {} if self.void_return else {self.ret: [spots.RAX]}
        for arg, reg in zip(self.args, self.arg_regs):
            prefs[arg] = [reg]

        return prefs

    def abs_spot_conf(self): # noqa D102
        # We don't want the function pointer to be in the same register as
        # an argument will be placed into.
        return {self.func: self.arg_regs[0:len(self.args)]}

    def indir_write(self): # noqa D102
        return self.args

    def indir_read(self): # noqa D102
        return self.args

    def make_asm(self, spotmap, home_spots, get_reg, asm_code): # noqa D102
        func_spot = spotmap[self.func]

        func_size = self.func.ctype.size
        ret_size = self.func.ctype.arg.ret.size

        useR13 = False

        # Check if function pointer spot will be clobbered by moving the
        # arguments into the correct registers.
        if spotmap[self.func] in self.arg_regs[0:len(self.args)]:
            # Get a register which isn't one of the unallowed registers.
            r = get_reg([], self.arg_regs[0:len(self.args)])
            asm_code.add(asm_cmds.Mov(r, spotmap[self.func], func_size))
            func_spot = r

        if isinstance(func_spot, spots.MemSpot):
            useR13 = True
            asm_code.add(asm_cmds.Read(func_spot, spots.RegSpot("r13"), func_size))

        for arg, reg in zip(self.args, self.arg_regs):
            if spotmap[arg] == reg:
                continue

            if isinstance(spotmap[arg], spots.MemSpot):
                asm_code.add(asm_cmds.Read(spotmap[arg], spots.RegSpot("r12"), arg.ctype.size))
                asm_code.add(asm_cmds.Mov(reg, spots.RegSpot("r12"), arg.ctype.size))
            else:
                asm_code.add(asm_cmds.Mov(reg, spotmap[arg], arg.ctype.size))

        asm_code.add(asm_cmds.SavPC(spots.RegSpot("r12")))
        asm_code.add(asm_cmds.Sub(spots.RegSpot("rsp"), spots.LiteralSpot(1)))
        asm_code.add(asm_cmds.Write(spots.RegSpot("rsp"), spots.RegSpot("r12")))
        #sub 1 rsp rsp
        #write 0 rsp r12
        if (useR13):
            asm_code.add(asm_cmds.Jumpr(spots.LiteralSpot(0), spots.RegSpot("r13")))
        else:
            asm_code.add(asm_cmds.Jumpr(spots.LiteralSpot(0), func_spot))

        if not self.void_return and spotmap[self.ret] != spots.RAX:
            asm_code.add(asm_cmds.Mov(spotmap[self.ret], spots.RAX, ret_size))
