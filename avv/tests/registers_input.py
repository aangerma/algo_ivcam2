#! python3
import slash
import os
import logging
import random
import matlab
import io
import sys
import matlab_eng
import re
import math
import struct
sys.path.insert(0, r"Avv\tests")
import a_common

try:
    from aux_functions import log
except:
    pass


# slash run -vv -l Avv/logs/ -o log.highlights_subpath={context.session.id}/highlights.log -f Avv/tests/test_list.txt -k test_random_registers_autogen_100
def run_randomize(eng, file_path):
    slash.logger.debug("running matlab randomize")
    try:
        regs_random_list = [
            'EPTGframeRate', 'FRMWxfov', 'FRMWyfov', 'FRMWprojectionYshear', 'FRMWlaserangleH',
            'FRMWlaserangleV', 'FRMWundistYfovFactor', 'DIGGundistBypass', 'EPTGmirrorFastFreq',
            'EPTGslowCouplingFactor', 'EPTGslowCouplingPhase', 'EPTGscndModePhase', 'EPTGscndModeFreq']
        if not os.path.isdir(os.path.dirname(file_path)):
            os.makedirs(os.path.dirname(file_path))
        eng.s.randomize_registers(file_path, regs_random_list, stdout=out, stderr=err, nargout=0)
        if not os.path.isfile(file_path):
            slash.logger.error("Failed creating file: {}".format(file_path))
            raise FileNotFoundError
    except matlab.engine.MatlabExecutionError:
        slash.logger.debug("randomize crash, err: {}".format(err.getvalue()))
        slash.logger.info("test randomize crash")
        return False

    return True


def run_pattern_generator(eng, file_path, data_path):
    slash.logger.debug("start patternGenerator")
    try:
        ivs_file_name, gt, regs, luts = eng.s.Pipe.patternGenerator(file_path, 'outputdir', data_path, stdout=out,
                                                                    stderr=err, nargout=4)
    except matlab.engine.MatlabExecutionError:
        s_err = err.getvalue()
        if "Constraint Failed:" in s_err:
            constraints_start = s_err.find("Constraint Failed:", )
            constraints_end = s_err.find("\n\n", constraints_start)
            slash.logger.info(
                "pattern generator constraint: {}".format(s_err[constraints_start:constraints_end].replace("\n", ", ")))
            return 1, None
        elif "bad constraint:" in s_err:
            constraints_start = s_err.find("bad constraint:", )
            constraints_end = s_err.find("\n\n", constraints_start)
            slash.logger.info(
                "pattern generator constraint: {}".format(s_err[constraints_start:constraints_end].replace("\n", ", ")))
            return 1, None
        else:
            slash.logger.debug("pattern generator crashed: {}".format(out.getvalue()))
            slash.logger.info("pattern generator crashed: {}".format(s_err))
            return 2, None

    return 0, ivs_file_name


def run_autopipe(eng, file_path, data_path, iteration):
    save_ivs_file = False
    slash.logger.debug("start autopipe")
    try:
        eng.s.Pipe.autopipe(file_path, stdout=out, stderr=err, nargout=0)
    except matlab.engine.MatlabExecutionError:
        if save_ivs_file:
            file_name = "ivs_fail_{}".format(iteration)
            file_ext = ".ivs"
            fail_file_path = os.path.join(data_path, file_name + file_ext)
            slash.logger.error("failed test, ivs file: {}".format(fail_file_path))
            if os.path.isfile(fail_file_path):
                os.remove(fail_file_path)
            os.rename(file_path, fail_file_path)
        slash.logger.error("autopipe crashed: {}".format(out.getvalue()))
        slash.logger.error("err: {}".format(err.getvalue()))
        return False

    return True


out = io.StringIO()
err = io.StringIO()


def test_random_registers_debug():
    test_status = {"pass": 0, "fail": 0, "constraints": 0, "Randomize_crash": 0}
    eng = slash.g.mat

    data_path = os.path.join(os.path.dirname(os.path.realpath("__file__")), "Avv", "test_data", "regs_random")
    file_name = "regs_info"
    file_ext = ".csv"
    file_path = os.path.join(data_path, file_name + file_ext)
    slash.logger.debug("regs file path: {}".format(file_path))

    iterations = 1
    slash.logger.info("Start test, number of iterations: {}".format(iterations))
    for i in range(iterations):
        slash.logger.info("start iteration: {}".format(i + 1))

        out.truncate(0)
        err.truncate(0)
        if not run_randomize(eng, file_path):
            test_status["Randomize_crash"] += 1
            continue

        status, ivs_file_name = run_pattern_generator(eng, file_path, data_path)
        if not status:
            test_status["constraints"] += 1
            continue

        if not run_autopipe(eng, ivs_file_name, data_path, i):
            test_status["fail"] += 1
            continue

        slash.logger.info("test passed")
        test_status["pass"] += 1

    slash.logger.info(test_status, extra={"highlight": True})


def read_regs_file(file_path):
    regs_list = {}
    logging.info("reading file: {}".format(file_path))
    line_index = 0
    columns_names = list()
    with open(file_path, "r") as dataFile:
        for line in dataFile:
            if len(line) <= 3:
                continue
            data = line.split(",")
            if line_index == 0:
                for d in data:
                    columns_names.append(d.strip())
            else:
                if len(data) != len(columns_names):
                    logging.error("file error, line {} doesnt have enough columns".format(index))
                    raise IndexError
                reg_data = {}
                for index in range(len(columns_names)):
                    reg_data[columns_names[index]] = data[index].strip()

                regs_list[reg_data["regName"]] = reg_data

            line_index += 1

    logging.info("file number of entries: {}".format(len(regs_list)))
    return regs_list


def clean_regs_list_to_generate(regs):
    regs_to_generate = {}
    for reg_name, reg in regs.items():
        if reg_name == "GNRLimgHsize":
            def_reg = {"regName": reg_name, "type": "uint16", "arraySize": "1", "range": "{[64:1280]}"}
            regs_to_generate[reg_name] = def_reg
        if reg_name == "GNRLimgVsize":
            def_reg = {"regName": reg_name, "type": "uint16", "arraySize": "1", "range": "{[60:960]}"}
            regs_to_generate[reg_name] = def_reg
        if "x" not in reg["autogen"] and "%" not in reg["uniqueID"]:
            regs_to_generate[reg_name] = reg

    logging.info(
        "clean reg list for generate, regs definition: {}, to generate: {}".format(len(regs), len(regs_to_generate)))
    return regs_to_generate


def convert_to_number(str_number):
    try:
        num = int(str_number)
    except ValueError:
        num = float(str_number)

    return num


def get_reg_range(reg={}):
    array_size = int(reg["arraySize"])
    reg_tyep = reg["type"]
    reg_range = str(reg["range"]).strip().replace("{", "").replace("}", "").replace("[", "").replace("]", "")
    ranages = reg_range.split(";")
    reg_ranges = list()
    reg_ranges_weight = list()
    selected_range = None
    for this_range in ranages:
        if ":/" in this_range:
            this_range = this_range.split(":/")
            reg_ranges.append(this_range[0])
            reg_ranges_weight.append(convert_to_number(this_range[1]))
        else:
            reg_ranges.append(this_range)
    if len(reg_ranges_weight) > 0:
        selected_range = reg_ranges[random.choices(range(len(reg_ranges)), reg_ranges_weight, k=1)[0]]
    if len(reg_ranges_weight) == 0:
        selected_range = random.choice(reg_ranges)

    # logging.debug(
    # "reg name: {}, reg range: {}, selected range: {}".format(reg["regName"], reg["range"], selected_range))
    return selected_range


def get_constraints_list(file_path):
    constraints_list = list()
    slash.logger.info("reading file: {}".format(file_path))
    with open(file_path, "r") as dataFile:
        for line in dataFile:
            if len(line) <= 3:
                continue
            else:
                if line[0] == "%":
                    continue
                constraints_list.append(line)

    num_of_constraints = len(constraints_list)
    constraints_list.append("[FRMWxres]-[FRMWmarginL]-[FRMWmarginR]>64")
    constraints_list.append("mod([FRMWxres]-[FRMWmarginL]-[FRMWmarginR],2)==0")
    constraints_list.append("[FRMWyres]-[FRMWmarginT]-[FRMWmarginB]>60")
    constraints_list.append("mod([FRMWyres]-[FRMWmarginT]-[FRMWmarginB],2)==0")
    constraints_list.append("mod([FRMWxres],2)==0")
    constraints_list.append("mod([FRMWyres],2)==0")

    slash.logger.info("file number of constraints: {}, added: {}, total: ".format(num_of_constraints, len(constraints_list) - num_of_constraints, len(constraints_list)))
    return constraints_list


class Constraint:
    def __init__(self, constraint, regs):
        self._constraint = constraint
        self._regs = regs

    def __str__(self):
        return "constraint: {}, regs: {}".format(self._constraint, self._regs)

    def get_constraint(self):
        return self._constraint

    def get_regs(self):
        return self._regs


def create_constrains_table(constraints_list=list()):
    constraints = list()
    for constraint in constraints_list:
        constraint = constraint.replace("\n", "").strip()
        regs = list()
        regs_list = (re.findall(r"\[\w+\]", constraint))
        for reg in regs_list:
            regs.append(reg.replace("[", "").replace("]", "").strip())

        constraints.append(Constraint(constraint, regs))
    return constraints


def check_for_all_regs(selected_regs={}, regs=list()):
    for reg in regs:
        if reg not in selected_regs:
            return False

    return True


def check_constraint(selected_regs={}, constraint=None):
    constr = constraint.get_constraint()
    if constr == "[EPTGframeRate]==0 |  1e9/([GNRLimgHsize]*[GNRLimgVsize])*(1/[EPTGframeRate]-[EPTGreturnTime]/1000)>32":
        return True
    elif constr == "mod([GNRLcodeLength],2)==0":
        return modulo(selected_regs["GNRLcodeLength"], 2) == 0
    elif constr == "([GNRLcodeLength]*[GNRLsampleRate]<=1024 & [GNRLcodeLength]*[GNRLsampleRate]>=128) | ([GNRLrangeFinder]==1 & [GNRLcodeLength]*[GNRLsampleRate]==2048)":
        return (selected_regs["GNRLcodeLength"] * selected_regs["GNRLsampleRate"] <= 1024 and selected_regs[
            "GNRLcodeLength"] * selected_regs["GNRLsampleRate"] >= 128) or (
                       selected_regs["GNRLrangeFinder"] == 1 & selected_regs["GNRLcodeLength"] * selected_regs[
                   "GNRLsampleRate"] == 2048)
    elif constr == "~([GNRLrangeFinder] & [RASToutIRvar] )":
        return not (selected_regs["GNRLrangeFinder"] and selected_regs["RASToutIRvar"])
    elif constr == "~([DIGGnestBypass] & [DCORoutIRnest])":
        return not (selected_regs["DIGGnestBypass"] and selected_regs["DCORoutIRnest"])
    elif constr == "~[DCORoutIRnest] |  ~[DCORbypass]":
        return not selected_regs["DCORoutIRnest"] or not selected_regs["DCORbypass"]
    elif constr == "([DCORoutIRnest] + [DCORoutIRcma] + [DESTaltIrEn] +  [RASToutIRvar]) <= 1":
        return (selected_regs["DCORoutIRnest"] + selected_regs["DCORoutIRcma"] + selected_regs["DESTaltIrEn"] +
                selected_regs["RASToutIRvar"]) <= 1
    elif constr == "[GNRLrangeFinder]==0 | ( [RASTbiltBypass] & [CBUFbypass] )":
        return selected_regs["GNRLrangeFinder"] == 0 or (
                selected_regs["RASTbiltBypass"] and selected_regs["CBUFbypass"])
    elif constr == "~([DCORoutIRnest] | [DCORoutIRcma] ) | [JFILbypass]":
        return not (selected_regs["DCORoutIRnest"] or selected_regs["DCORoutIRcma"]) or selected_regs["JFILbypass"]
    elif constr == "[JFILedge1maxTh] < [JFILedge1detectTh]":
        return selected_regs["JFILedge1maxTh"] < selected_regs["JFILedge1detectTh"]
    elif constr == "[JFILedge4maxTh] < [JFILedge4detectTh]":
        return selected_regs["JFILedge4maxTh"] < selected_regs["JFILedge4detectTh"]
    elif constr == "[JFILedge3maxTh] < [JFILedge3detectTh]":
        return selected_regs["JFILedge3maxTh"] < selected_regs["JFILedge3detectTh"]
    elif constr == "[JFILgrad1thrAveDiag]  < (2^(16- [GNRLzMaxSubMMExp]));":
        return selected_regs["JFILgrad1thrAveDiag"] < (2 ** (16 - selected_regs["GNRLzMaxSubMMExp"]))
    elif constr == "[JFILgrad1thrAveDx]  < (2^(16- [GNRLzMaxSubMMExp]));":
        return selected_regs["JFILgrad1thrAveDx"] < (2 ** (16 - selected_regs["GNRLzMaxSubMMExp"]))
    elif constr == "[JFILgrad1thrAveDy]  < (2^(16- [GNRLzMaxSubMMExp]));":
        return selected_regs["JFILgrad1thrAveDy"] < (2 ** (16 - selected_regs["GNRLzMaxSubMMExp"]))
    elif constr == "[JFILgrad1thrMaxDiag]  < (2^(16- [GNRLzMaxSubMMExp]));":
        return selected_regs["JFILgrad1thrMaxDiag"] < (2 ** (16 - selected_regs["GNRLzMaxSubMMExp"]))
    elif constr == "[JFILgrad1thrMaxDx]  < (2^(16- [GNRLzMaxSubMMExp]));":
        return selected_regs["JFILgrad1thrMaxDx"] < (2 ** (16 - selected_regs["GNRLzMaxSubMMExp"]))
    elif constr == "[JFILgrad1thrMaxDy]  < (2^(16- [GNRLzMaxSubMMExp]));":
        return selected_regs["JFILgrad1thrMaxDy"] < (2 ** (16 - selected_regs["GNRLzMaxSubMMExp"]))
    elif constr == "[JFILgrad1thrMinDiag]  < (2^(16- [GNRLzMaxSubMMExp]));":
        return selected_regs["JFILgrad1thrMinDiag"] < (2 ** (16 - selected_regs["GNRLzMaxSubMMExp"]))
    elif constr == "[JFILgrad1thrMinDx]  < (2^(16- [GNRLzMaxSubMMExp]));":
        return selected_regs["JFILgrad1thrMinDx"] < (2 ** (16 - selected_regs["GNRLzMaxSubMMExp"]))
    elif constr == "[JFILgrad1thrMinDy]  < (2^(16- [GNRLzMaxSubMMExp]));":
        return selected_regs["JFILgrad1thrMinDy"] < (2 ** (16 - selected_regs["GNRLzMaxSubMMExp"]))
    elif constr == "[JFILgrad1thrMode]  < (2^(16- [GNRLzMaxSubMMExp]));":
        return selected_regs["JFILgrad1thrMode"] < (2 ** (16 - selected_regs["GNRLzMaxSubMMExp"]))
    elif constr == "[JFILgrad2thrAveDiag]  < (2^(16- [GNRLzMaxSubMMExp]));":
        return selected_regs["JFILgrad2thrAveDiag"] < (2 ** (16 - selected_regs["GNRLzMaxSubMMExp"]))
    elif constr == "[JFILgrad2thrAveDx]  < (2^(16- [GNRLzMaxSubMMExp]));":
        return selected_regs["JFILgrad2thrAveDx"] < (2 ** (16 - selected_regs["GNRLzMaxSubMMExp"]))
    elif constr == "[JFILgrad2thrAveDy]  < (2^(16- [GNRLzMaxSubMMExp]));":
        return selected_regs["JFILgrad2thrAveDy"] < (2 ** (16 - selected_regs["GNRLzMaxSubMMExp"]))
    elif constr == "[JFILgrad2thrMaxDiag]  < (2^(16- [GNRLzMaxSubMMExp]));":
        return selected_regs["JFILgrad2thrMaxDiag"] < (2 ** (16 - selected_regs["GNRLzMaxSubMMExp"]))
    elif constr == "[JFILgrad2thrMaxDx]  < (2^(16- [GNRLzMaxSubMMExp]));":
        return selected_regs["JFILgrad2thrMaxDx"] < (2 ** (16 - selected_regs["GNRLzMaxSubMMExp"]))
    elif constr == "[JFILgrad2thrMaxDy]  < (2^(16- [GNRLzMaxSubMMExp]));":
        return selected_regs["JFILgrad2thrMaxDy"] < (2 ** (16 - selected_regs["GNRLzMaxSubMMExp"]))
    elif constr == "[JFILgrad2thrMinDiag]  < (2^(16- [GNRLzMaxSubMMExp]));":
        return selected_regs["JFILgrad2thrMinDiag"] < (2 ** (16 - selected_regs["GNRLzMaxSubMMExp"]))
    elif constr == "[JFILgrad2thrMinDx]  < (2^(16- [GNRLzMaxSubMMExp]));":
        return selected_regs["JFILgrad2thrMinDx"] < (2 ** (16 - selected_regs["GNRLzMaxSubMMExp"]))
    elif constr == "[JFILgrad2thrMinDy]  < (2^(16- [GNRLzMaxSubMMExp]));":
        return selected_regs["JFILgrad2thrMinDy"] < (2 ** (16 - selected_regs["GNRLzMaxSubMMExp"]))
    elif constr == "[JFILgrad2thrMode]  < (2^(16- [GNRLzMaxSubMMExp]));":
        return selected_regs["JFILgrad2thrMode"] < (2 ** (16 - selected_regs["GNRLzMaxSubMMExp"]))
    elif constr == "[JFILgrad2thrSpike]  < (2^(16- [GNRLzMaxSubMMExp]));":
        return selected_regs["JFILgrad2thrSpike"] < (2 ** (16 - selected_regs["GNRLzMaxSubMMExp"]))
    elif constr == "[JFILgrad1thrSpike]  < (2^(16- [GNRLzMaxSubMMExp]));":
        return selected_regs["JFILgrad1thrSpike"] < (2 ** (16 - selected_regs["GNRLzMaxSubMMExp"]))
    elif constr == "at([JFILinvMinMax],1)>at([JFILinvMinMax],0)":
        s = format(selected_regs["JFILinvMinMax"], "032b")
        return int(s[int(len(s) / 2):len(s)], 2) < int(s[0:int(len(s) / 2)], 2)
    elif constr == "[JFILsort1fixedConfValue] > 0":
        return selected_regs["JFILsort1fixedConfValue"] > 0
    elif constr == "sum([[JFILsort1iWeights]])<128":
        s = format(selected_regs["JFILsort1iWeights"], "032b")
        return int(s[0:8], 2) + int(s[8:16], 2) + int(s[16:24], 2) + int(s[24:32], 2) < 128
    elif constr == "sum([[JFILsort1dWeights]])<128":
        s = format(selected_regs["JFILsort1dWeights"], "032b")
        return int(s[0:8], 2) + int(s[8:16], 2) + int(s[16:24], 2) + int(s[24:32], 2) < 128
    elif constr == "sum([[JFILsort2dWeights]])<128":
        s = format(selected_regs["JFILsort2dWeights"], "032b")
        return int(s[0:8], 2) + int(s[8:16], 2) + int(s[16:24], 2) + int(s[24:32], 2) < 128
    elif constr == "[JFILsort2fixedConfValue] > 0":
        return selected_regs["JFILsort2fixedConfValue"] > 0
    elif constr == "sum([[JFILsort2iWeights]])<128":
        s = format(selected_regs["JFILsort2iWeights"], "032b")
        return int(s[0:8], 2) + int(s[8:16], 2) + int(s[16:24], 2) + int(s[24:32], 2) < 128
    elif constr == "sum([[JFILsort3dWeights]])<128":
        s = format(selected_regs["JFILsort3dWeights"], "032b")
        return int(s[0:8], 2) + int(s[8:16], 2) + int(s[16:24], 2) + int(s[24:32], 2) < 128
    elif constr == "[JFILsort3fixedConfValue] > 0":
        return selected_regs["JFILsort3fixedConfValue"] > 0
    elif constr == "sum([[JFILsort3iWeights]])<128":
        s = format(selected_regs["JFILsort3iWeights"], "032b")
        return int(s[0:8], 2) + int(s[8:16], 2) + int(s[16:24], 2) + int(s[24:32], 2) < 128
    elif constr == "[STATstt1Bypass] == 1 | ([STATstt1src] <=  1 | [STATstt1lowThrPxlNum] < [STATstt1cellHsize]*[STATstt1cellVsize])":
        return selected_regs["STATstt1Bypass"] == 1 or (
                selected_regs["STATstt1src"] <= 1 or selected_regs["STATstt1lowThrPxlNum"] < selected_regs[
            "STATstt1cellHsize"] * selected_regs["STATstt1cellVsize"])
    elif constr == "[STATstt1lowerThr] < [STATstt1upperThr]":
        return selected_regs["STATstt1lowerThr"] < selected_regs["STATstt1upperThr"]
    elif constr == "[STATstt2Bypass] == 1 | ([STATstt2src] <=  1 | [STATstt2lowThrPxlNum] <= [STATstt2cellHsize]*[STATstt2cellVsize])":
        return selected_regs["STATstt2Bypass"] == 1 or (
                selected_regs["STATstt2src"] <= 1 or selected_regs["STATstt2lowThrPxlNum"] <= selected_regs[
            "STATstt2cellHsize"] * selected_regs["STATstt2cellVsize"])
    elif constr == "[STATstt2lowerThr] < [STATstt2upperThr]":
        return selected_regs["STATstt2lowerThr"] < selected_regs["STATstt2upperThr"]
    elif constr == "sum([[GNRLrangeFinder] [DIGGsphericalEn] [MTLBxyRasterInput]])<=1":
        return (selected_regs["GNRLrangeFinder"] + selected_regs["DIGGsphericalEn"] + selected_regs[
            "MTLBxyRasterInput"]) <= 1
    elif constr == "[STATstt1Bypass] == 1 | ([STATstt1src] >  1 |  mod([STATstt1skipVsize],[MTLBtCamVsize]) == 0)":
        return selected_regs["STATstt1Bypass"] == 1 or (selected_regs["STATstt1src"] > 1 or
                                                        modulo(selected_regs["STATstt1skipVsize"],
                                                               selected_regs["MTLBtCamVsize"]) == 0)
    elif constr == "[STATstt2Bypass] == 1 | ([STATstt2src] >  1 |  mod([STATstt2skipVsize],[MTLBtCamVsize]) == 0)":
        return selected_regs["STATstt2Bypass"] == 1 or (selected_regs["STATstt2src"] > 1 or (modulo(
            selected_regs["STATstt2skipVsize"], selected_regs["MTLBtCamVsize"])) == 0)
    elif constr == "[STATstt1Bypass] == 1 | ([STATstt1src] > 1 | [STATstt1skipHsize] < [MTLBtCamHsize])":
        return selected_regs["STATstt1Bypass"] == 1 or (
                selected_regs["STATstt1src"] > 1 or selected_regs["STATstt1skipHsize"] < selected_regs[
            "MTLBtCamHsize"])
    elif constr == "[STATstt1Bypass] == 1 | ([STATstt1src] > 1 | ([STATstt1skipVsize] / [MTLBtCamHsize]) < [MTLBtCamVsize])":
        return selected_regs["STATstt1Bypass"] == 1 or (selected_regs["STATstt1src"] > 1 or (
                selected_regs["STATstt1skipVsize"] / selected_regs["MTLBtCamHsize"]) < selected_regs[
                                                            "MTLBtCamVsize"])
    elif constr == "[STATstt2Bypass] == 1 | ([STATstt2src] > 1 | [STATstt2skipHsize] < [MTLBtCamHsize])":
        return selected_regs["STATstt2Bypass"] == 1 or (
                selected_regs["STATstt2src"] > 1 or selected_regs["STATstt2skipHsize"] < selected_regs[
            "MTLBtCamHsize"])
    elif constr == "[STATstt2Bypass] == 1 | ([STATstt2src] > 1 | ([STATstt2skipVsize] / [MTLBtCamHsize]) < [MTLBtCamVsize])":
        return selected_regs["STATstt2Bypass"] == 1 or (selected_regs["STATstt2src"] > 1 or (
                selected_regs["STATstt2skipVsize"] / selected_regs["MTLBtCamHsize"]) < selected_regs[
                                                            "MTLBtCamVsize"])
    elif constr == "any(single([GNRLsampleRate])/[MTLBtxSymbolLength]==[4 8 16])":
        return selected_regs["GNRLsampleRate"] / selected_regs["MTLBtxSymbolLength"] == 4.0 or selected_regs[
            "GNRLsampleRate"] / selected_regs["MTLBtxSymbolLength"] == 8.0 or selected_regs["GNRLsampleRate"] / \
               selected_regs["MTLBtxSymbolLength"] == 16.0
    elif constr == "[EPTGminZ] <=[EPTGmaxZ]":
        return selected_regs["EPTGminZ"] <= selected_regs["EPTGmaxZ"]
    elif constr == "[EPTGnMaxSamples] == floor([EPTGnMaxSamples])":
        return selected_regs["EPTGnMaxSamples"] == int(selected_regs["EPTGnMaxSamples"])
    elif constr == "[EPTGreturnTime]*1e-3<1/[EPTGframeRate]":
        return selected_regs["EPTGreturnTime"] * 1 * 10 ** -3 < 1 / selected_regs["EPTGframeRate"]
    elif constr == "[STATstt1Bypass] == 1 | ([STATstt1src] <=  1 | [STATstt1skipHsize] < [FRMWxres])":
        return selected_regs["STATstt1Bypass"] == 1 or (
                selected_regs["STATstt1src"] <= 1 or selected_regs["STATstt1skipHsize"] < selected_regs["FRMWxres"])
    elif constr == "[STATstt2Bypass] == 1 | ([STATstt2src] <=  1 | [STATstt2skipHsize] < [FRMWxres])":
        return selected_regs["STATstt2Bypass"] == 1 or (
                selected_regs["STATstt2src"] <= 1 or selected_regs["STATstt2skipHsize"] < selected_regs["FRMWxres"])
    elif constr == "[EPTGframeRate]==0 | 1e9/(2*[EPTGmirrorFastFreq]*[FRMWyres]*(1+2*[FRMWgaurdBandV]))*2/pi>64/[GNRLsampleRate]":
        return selected_regs["EPTGframeRate"] == 0 or 1 * 10 ** 9 / (
                2 * selected_regs["EPTGmirrorFastFreq"] * selected_regs["FRMWyres"] * (
                1 + 2 * selected_regs["FRMWgaurdBandV"])) * 2 / math.pi > 64 / selected_regs["GNRLsampleRate"]
    elif constr == "[GNRLrangeFinder] | abs([FRMWxres]/[FRMWyres]*[FRMWyfov]/[FRMWxfov]*(1+2*[FRMWgaurdBandV])/(1+2*[FRMWgaurdBandH])-1)<0.8":
        return selected_regs["GNRLrangeFinder"] or abs(
            selected_regs["FRMWxres"] / selected_regs["FRMWyres"] * selected_regs["FRMWyfov"] / selected_regs[
                "FRMWxfov"] * (1 + 2 * selected_regs["FRMWgaurdBandV"]) / (
                    1 + 2 * selected_regs["FRMWgaurdBandH"]) - 1) < 0.8
    elif constr == "abs([FRMWmarginL]-[FRMWmarginR]) < [FRMWxres]":
        return abs(selected_regs["FRMWmarginL"] - selected_regs["FRMWmarginR"]) < selected_regs["FRMWxres"]
    elif constr == "[STATstt1Bypass] == 1 | ([STATstt1src] <=  1 |  mod([STATstt1skipVsize],([FRMWxres] -[FRMWmarginL] - [FRMWmarginR])) == 0)":
        return selected_regs["STATstt1Bypass"] == 1 or (
                selected_regs["STATstt1src"] <= 1 or modulo(selected_regs["STATstt1skipVsize"], (
                selected_regs["FRMWxres"] - selected_regs["FRMWmarginL"] - selected_regs["FRMWmarginR"])) == 0)
    elif constr == "[STATstt2Bypass] == 1 | ([STATstt2src] <=  1 |  mod([STATstt2skipVsize],[MTLBtCamVsize])) == 0)":
        return selected_regs["STATstt2Bypass"] == 1 or (selected_regs["STATstt2src"] <= 1 or (
            modulo(selected_regs["STATstt2skipVsize"], selected_regs["MTLBtCamVsize"])) == 0)
    elif constr == "[FRMWmarginL]<[FRMWxres]":
        return selected_regs["FRMWmarginL"] < selected_regs["FRMWxres"]
    elif constr == "[FRMWmarginT]<[FRMWyres]":
        return selected_regs["FRMWmarginT"] < selected_regs["FRMWyres"]
    elif constr == "abs([FRMWmarginB]-[FRMWmarginT]) < [FRMWyres]":
        return abs(selected_regs["FRMWmarginB"] - selected_regs["FRMWmarginT"]) < selected_regs["FRMWyres"]
    elif constr == "[STATstt1Bypass] == 1 | ([STATstt1src] <=  1 | [STATstt1skipVsize] / [GNRLimgHsize] < [GNRLimgVsize])":
        return selected_regs["STATstt1Bypass"] == 1 or (
                selected_regs["STATstt1src"] <= 1 or selected_regs["STATstt1skipVsize"] / selected_regs[
            "GNRLimgHsize"] < selected_regs["GNRLimgVsize"])
    elif constr == "[STATstt2Bypass] == 1 | ([STATstt2src] <=  1 | [STATstt2skipVsize] / ([FRMWxres] -[FRMWmarginL] - [FRMWmarginR]) < ([FRMWyres] -[FRMWmarginB] - [FRMWmarginT]))":
        return selected_regs["STATstt2Bypass"] == 1 or (
                selected_regs["STATstt2src"] <= 1 or selected_regs["STATstt2skipVsize"] / (
                selected_regs["FRMWxres"] - selected_regs["FRMWmarginL"] - selected_regs["FRMWmarginR"]) < (
                        selected_regs["FRMWyres"] - selected_regs["FRMWmarginB"] - selected_regs[
                    "FRMWmarginT"]))
    elif constr == "[STATstt2Bypass] == 1 | ([STATstt2src] <=  1 | [STATstt2skipVsize] < [GNRLimgVsize])":
        return selected_regs["STATstt2Bypass"] == 1 or (
                selected_regs["STATstt2src"] <= 1 or selected_regs["STATstt2skipVsize"] < selected_regs[
            "GNRLimgVsize"])
    elif constr == "[GNRLcodeLength]*[FRMWcoarseSampleRate]<=256":
        return selected_regs["GNRLcodeLength"] * selected_regs["FRMWcoarseSampleRate"] <= 256
    elif constr == "sum([GNRLsampleRate]/[FRMWcoarseSampleRate]==[2 4 8])==1":
        return selected_regs["GNRLsampleRate"] / selected_regs["FRMWcoarseSampleRate"] == 2 or selected_regs[
            "GNRLsampleRate"] / selected_regs["FRMWcoarseSampleRate"] == 4 or selected_regs["GNRLsampleRate"] / \
               selected_regs["FRMWcoarseSampleRate"] == 8
    elif constr == "~([FRMWtxCode_000]==0 & [FRMWtxCode_001]==0 & [FRMWtxCode_002]==0 & [FRMWtxCode_003]==0)":
        return not (selected_regs["FRMWtxCode_000"] == 0 and selected_regs["FRMWtxCode_001"] == 0 and selected_regs[
            "FRMWtxCode_002"] == 0 and selected_regs["FRMWtxCode_003"] == 0)
    elif constr == "[DIGGundistBypass] | [FRMWxfov]*[FRMWundistXfovFactor]<=89":
        return selected_regs["DIGGundistBypass"] or selected_regs["FRMWxfov"] * selected_regs[
            "FRMWundistXfovFactor"] <= 89
    elif constr == "[DIGGundistBypass] | [FRMWyfov]*[FRMWundistYfovFactor]<=89":
        return selected_regs["DIGGundistBypass"] or selected_regs["FRMWyfov"] * selected_regs[
            "FRMWundistYfovFactor"] <= 89
    elif constr == "at([JFILbiltGauss_000],0)~=0":
        s = format(selected_regs["JFILbiltGauss_000"], "032b")
        return int(s[24:32], 2) != 0
    elif constr == "at([JFILbiltGauss_001],2)~=0":
        s = format(selected_regs["JFILbiltGauss_001"], "032b")
        return int(s[8:16], 2) != 0
    elif constr == "at([JFILbiltGauss_003],0)~=0":
        s = format(selected_regs["JFILbiltGauss_003"], "032b")
        return int(s[24:32], 2) != 0
    elif constr == "at([JFILbiltGauss_004],2)~=0":
        s = format(selected_regs["JFILbiltGauss_004"], "032b")
        return int(s[8:16], 2) != 0
    elif constr == "at([JFILbiltGauss_006],0)~=0":
        s = format(selected_regs["JFILbiltGauss_006"], "032b")
        return int(s[24:32], 2) != 0
    elif constr == "at([JFILbiltGauss_007],2)~=0":
        s = format(selected_regs["JFILbiltGauss_007"], "032b")
        return int(s[8:16], 2) != 0
    elif constr == "at([JFILbiltGauss_009],0)~=0":
        s = format(selected_regs["JFILbiltGauss_009"], "032b")
        return int(s[24:32], 2) != 0
    elif constr == "at([JFILbiltGauss_010],2)~=0":
        s = format(selected_regs["JFILbiltGauss_010"], "032b")
        return int(s[8:16], 2) != 0
    elif constr == "at([JFILbiltGauss_012],0)~=0":
        s = format(selected_regs["JFILbiltGauss_012"], "032b")
        return int(s[24:32], 2) != 0
    elif constr == "at([JFILbiltGauss_013],2)~=0":
        s = format(selected_regs["JFILbiltGauss_013"], "032b")
        return int(s[8:16], 2) != 0
    elif constr == "at([JFILbiltGauss_015],0)~=0":
        s = format(selected_regs["JFILbiltGauss_015"], "032b")
        return int(s[24:32], 2) != 0
    elif constr == "at([JFILbiltGauss_016],2)~=0":
        s = format(selected_regs["JFILbiltGauss_016"], "032b")
        return int(s[8:16], 2) != 0
    elif constr == "at([JFILbiltGauss_018],0)~=0":
        s = format(selected_regs["JFILbiltGauss_018"], "032b")
        return int(s[24:32], 2) != 0
    elif constr == "at([JFILbiltGauss_019],2)~=0":
        s = format(selected_regs["JFILbiltGauss_019"], "032b")
        return int(s[8:16], 2) != 0
    elif constr == "at([JFILbiltGauss_021],0)~=0":
        s = format(selected_regs["JFILbiltGauss_021"], "032b")
        return int(s[24:32], 2) != 0
    elif constr == "at([JFILbiltGauss_022],2)~=0":
        s = format(selected_regs["JFILbiltGauss_022"], "032b")
        return int(s[8:16], 2) != 0
    elif constr == "at([JFILbiltGauss_024],0)~=0":
        s = format(selected_regs["JFILbiltGauss_024"], "032b")
        return int(s[24:32], 2) != 0
    elif constr == "at([JFILbiltGauss_025],2)~=0":
        s = format(selected_regs["JFILbiltGauss_025"], "032b")
        return int(s[8:16], 2) != 0
    elif constr == "at([JFILbiltGauss_027],0)~=0":
        s = format(selected_regs["JFILbiltGauss_027"], "032b")
        return int(s[24:32], 2) != 0
    elif constr == "at([JFILbiltGauss_028],2)~=0":
        s = format(selected_regs["JFILbiltGauss_028"], "032b")
        return int(s[8:16], 2) != 0
    elif constr == "at([JFILbiltGauss_030],0)~=0":
        s = format(selected_regs["JFILbiltGauss_030"], "032b")
        return int(s[24:32], 2) != 0
    elif constr == "at([JFILbiltGauss_031],2)~=0":
        s = format(selected_regs["JFILbiltGauss_031"], "032b")
        return int(s[8:16], 2) != 0
    elif constr == "at([JFILbiltGauss_033],0)~=0":
        s = format(selected_regs["JFILbiltGauss_033"], "032b")
        return int(s[24:32], 2) != 0
    elif constr == "at([JFILbiltGauss_034],2)~=0":
        s = format(selected_regs["JFILbiltGauss_034"], "032b")
        return int(s[8:16], 2) != 0
    elif constr == "at([JFILbiltGauss_036],0)~=0":
        s = format(selected_regs["JFILbiltGauss_036"], "032b")
        return int(s[24:32], 2) != 0
    elif constr == "at([JFILbiltGauss_037],2)~=0":
        s = format(selected_regs["JFILbiltGauss_037"], "032b")
        return int(s[8:16], 2) != 0
    elif constr == "at([JFILbiltGauss_039],0)~=0":
        s = format(selected_regs["JFILbiltGauss_039"], "032b")
        return int(s[24:32], 2) != 0
    elif constr == "at([JFILbiltGauss_040],2)~=0":
        s = format(selected_regs["JFILbiltGauss_040"], "032b")
        return int(s[8:16], 2) != 0
    elif constr == "at([JFILbiltGauss_042],0)~=0":
        s = format(selected_regs["JFILbiltGauss_042"], "032b")
        return int(s[24:32], 2) != 0
    elif constr == "at([JFILbiltGauss_043],2)~=0":
        s = format(selected_regs["JFILbiltGauss_043"], "032b")
        return int(s[8:16], 2) != 0
    elif constr == "at([JFILbiltGauss_045],0)~=0":
        s = format(selected_regs["JFILbiltGauss_045"], "032b")
        return int(s[24:32], 2) != 0
    elif constr == "at([JFILbiltGauss_046],2)~=0":
        s = format(selected_regs["JFILbiltGauss_046"], "032b")
        return int(s[8:16], 2) != 0
    elif constr == "[GNRLrangeFinder] | ([GNRLimgHsize]>=64 & [GNRLimgVsize]>=60)":
        return selected_regs["GNRLrangeFinder"] or (
                selected_regs["GNRLimgHsize"] >= 64 and selected_regs["GNRLimgVsize"] >= 60)
    elif constr == "[GNRLrangeFinder]==1 | ( mod([GNRLimgHsize],2)==0 & mod([GNRLimgVsize],2)==0 )":
        return selected_regs["GNRLrangeFinder"] == 1 or (
                modulo(selected_regs["GNRLimgHsize"], 2) == 0 and modulo(selected_regs["GNRLimgVsize"], 2) == 0)
    elif constr == "[GNRLimgHsize]>0":
        return selected_regs["GNRLimgHsize"] > 0
    elif constr == "[GNRLimgVsize]>0":
        return selected_regs["GNRLimgVsize"] > 0
    elif constr == "[GNRLrangeFinder]==0 | ( [GNRLimgHsize]==2 & [GNRLimgVsize]==1 )":
        return selected_regs["GNRLrangeFinder"] == 0 or (
                selected_regs["GNRLimgHsize"] == 2 and selected_regs["GNRLimgVsize"] == 1)
    elif constr == "[STATstt1Bypass] == 1 | ([STATstt1src] <=  1 |  mod([STATstt1skipVsize],[GNRLimgHsize]) == 0)":
        return selected_regs["STATstt1Bypass"] == 1 or (
                selected_regs["STATstt1src"] <= 1 or modulo(selected_regs["STATstt1skipVsize"],
                                                            selected_regs["GNRLimgHsize"]) == 0)
    elif constr == "[STATstt2Bypass] == 1 | ([STATstt2src] <=  1 |  mod([STATstt2skipVsize],[GNRLimgHsize]) == 0)":
        return selected_regs["STATstt2Bypass"] == 1 or (
                selected_regs["STATstt2src"] <= 1 or modulo(selected_regs["STATstt2skipVsize"],
                                                            selected_regs["GNRLimgHsize"]) == 0)
    elif constr == "[FRMWxres]-[FRMWmarginL]-[FRMWmarginR]>64":
        return selected_regs["FRMWxres"] - selected_regs["FRMWmarginL"] - selected_regs["FRMWmarginR"] > 64
    elif constr == "[FRMWyres]-[FRMWmarginT]-[FRMWmarginB]>60":
        return selected_regs["FRMWyres"] - selected_regs["FRMWmarginT"] - selected_regs["FRMWmarginB"] > 60
    elif constr == "mod([FRMWxres]-[FRMWmarginL]-[FRMWmarginR],2)==0":
        return modulo(selected_regs["FRMWxres"] - selected_regs["FRMWmarginL"] - selected_regs["FRMWmarginR"], 2) == 0
    elif constr == "mod([FRMWyres]-[FRMWmarginT]-[FRMWmarginB],2)==0":
        return modulo(selected_regs["FRMWyres"] - selected_regs["FRMWmarginT"] - selected_regs["FRMWmarginB"], 2) == 0
    elif constr == "[GNRLrangeFinder]==1 | ( mod([FRMWxres],2)==0 & mod([FRMWyres],2)==0 )":
        return selected_regs["GNRLrangeFinder"]==1 or modulo(selected_regs["FRMWxres"],2)==0 and modulo(selected_regs["FRMWyres"],2)==0
    elif constr == "mod([FRMWxres],2)==0":
        return modulo(selected_regs["FRMWxres"],2)==0
    elif constr == "mod([FRMWyres],2)==0":
        return modulo(selected_regs["FRMWyres"],2)==0
    else:
        slash.logger.warning("constraint not recognized: {}".format(constr))
        return True


def check_for_restriction(reg_name="", selected_regs={}, constraints=list()):
    for constraint in constraints:
        regs = constraint.get_regs()
        if reg_name in regs:
            if not check_for_all_regs(selected_regs, regs):
                continue
            else:
                if not check_constraint(selected_regs, constraint):
                    return False, constraint.get_constraint()
        else:
            continue
    return True, None


def modulo(a, b):
    if b == 0:
        return a

    return a % b


def concatenate_ints(nums, type):
    if "single" in type or "logical" in type:
        return nums[0]
    if len(nums) == 1:
        return nums[0]

    s = ""
    size = 0
    if "int2" in type:
        size = 2
    elif "int4" in type:
        size = 4
    elif "int8" in type:
        size = 8
    elif "int12" in type:
        size = 12
    elif "int16" in type:
        size = 16
    elif "int32" in type:
        size = 32
    elif "logical" in type:
        size = 1

    for i in range(len(nums)):
        s = s + format(nums[i] & ((2 ** size) - 1), '0{}b'.format(size))

    return int(s, 2)


def get_random_value(reg, selected_regs):
    reg_name = reg["regName"]
    array_size = int(reg["arraySize"])
    reg_type = reg["type"]

    if "logical" in reg_type:
        array_size == 1

    num = list()

    for i in range(array_size):
        selected_range = get_reg_range(reg)

        if ":" not in selected_range:
            num.append(convert_to_number(selected_range))
        else:
            ranges = str(selected_range).split(":")
            start = convert_to_number(ranges[0])
            end = convert_to_number(ranges[1])

            if reg_name in (
                    "JFILsort1iWeights", "JFILsort2iWeights", "JFILsort3iWeights", "JFILsort1dWeights",
                    "JFILsort2dWeights",
                    "JFILsort3dWeights"):
                sum = 0
                for n in num:
                    sum += n
                end = end - sum

            if reg_name in (
                    "JFILgrad1thrAveDiag", "JFILgrad1thrAveDx", "JFILgrad1thrAveDy", "JFILgrad1thrMaxDiag",
                    "JFILgrad1thrMaxDx",
                    "JFILgrad1thrMaxDy", "JFILgrad1thrMinDiag", "JFILgrad1thrMinDx", "JFILgrad1thrMinDy",
                    "JFILgrad1thrSpike"
                    , "JFILgrad2thrAveDiag", "JFILgrad2thrAveDx", "JFILgrad2thrAveDy", "JFILgrad2thrMaxDiag",
                    "JFILgrad2thrMaxDx", "JFILgrad2thrMaxDy", "JFILgrad2thrMinDiag", "JFILgrad2thrMinDx",
                    "JFILgrad2thrMinDy", "JFILgrad2thrSpike"):
                if selected_regs.get("GNRLzMaxSubMMExp") is not None:
                    end = 2 ** (16 - selected_regs["GNRLzMaxSubMMExp"])

            if reg_name == "FRMWmarginL":
                end = selected_regs["FRMWxres"] - selected_regs["FRMWmarginR"] + 64
                if end < start:
                    end = start
            if reg_name == "FRMWmarginB":
                end = selected_regs["FRMWyres"] - selected_regs["FRMWmarginT"] + 60
                if end < start:
                    end = start


            if type(start) == int and type(end) == int:
                num.append(random.randint(start, end))
            else:
                num.append(round(random.uniform(start, end), 10))

            if reg_name in ("GNRLimgHsize", "GNRLimgVsize", "GNRLcodeLength"):
                if num[len(num) - 1] % 2 != 0:
                    num[len(num) - 1] += 1
    # logging.debug("reg: {}, nums: {}".format(reg_name,num))
    return concatenate_ints(num, reg_type)


def generate_regs_recursive(i, rec_depth, regs_def, reg_order, selected_regs, constraints):
    i = i - rec_depth
    while i < len(reg_order):
        reg_name = reg_order[i]
        reg = regs_def[reg_name]

        if reg_name == "GNRLrangeFinder":
            selected_regs[reg_name] = 0
            i += 1
            continue
        if reg_name == "STATstt1Bypass":
            selected_regs[reg_name] = 1
            i += 1
            continue
        if reg_name == "STATstt2Bypass":
            selected_regs[reg_name] = 1
            i += 1
            continue

        if reg_name == "DIGGundistBypass":
            selected_regs[reg_name] = 1
            i += 1
            continue


        if selected_regs.get("GNRLrangeFinder") == 1:
            if reg_name == "GNRLimgHsize":
                selected_regs[reg_name] = 2
                i += 1
                continue
            if reg_name == "GNRLimgVsize":
                selected_regs[reg_name] = 1
                i += 1
                continue
        else:
            if reg_name == "RASTbiltBypass":
                selected_regs[reg_name] = 1
                i += 1
                continue
            if reg_name == "CBUFbypass":
                selected_regs[reg_name] = 1
                i += 1
                continue

        if reg_name == "DCORoutIRcma":
            if selected_regs["DCORoutIRnest"] == 1:
                selected_regs[reg_name] = 0
                i += 1
                continue
        if reg_name == "DESTaltIrEn":
            if selected_regs["DCORoutIRnest"] == 1 or selected_regs["DCORoutIRcma"] == 1:
                selected_regs[reg_name] = 0
                i += 1
                continue
        if reg_name == "RASToutIRvar":
            if selected_regs["DCORoutIRnest"] == 1 or selected_regs["DCORoutIRcma"] == 1 or selected_regs[
                "DESTaltIrEn"] == 1:
                selected_regs[reg_name] = 0
                i += 1
                continue

        if reg_name == "DIGGnestBypass" and selected_regs["DCORoutIRnest"] == 1:
            selected_regs[reg_name] = 0
            i += 1
            continue

        if reg_name in ("FRMWundistYfovFactor", "FRMWundistXfovFactor", "EPTGmultiFocalROI_000", "EPTGmultiFocalROI_001", "EPTGmultiFocalROI_002", "EPTGmultiFocalROI_003","MTLBassertionStop","FRMWxR2L", "MTLBdebug"):
            selected_regs[reg_name] = convert_to_number(reg["defaultValue"][1:])
            i += 1
            continue


        reg_added = False
        constraint_fail_index = 0
        while not reg_added:
            value = get_random_value(reg, selected_regs)
            selected_regs[reg_name] = value

            reg_added, constraint = check_for_restriction(reg_name, selected_regs, constraints)
            if not reg_added:
                constraint_fail_index += 1
                if constraint_fail_index >= 10:
                    slash.logger.debug(
                        "failed random for {}, value: {}, constraint: {}".format(reg["regName"],
                                                                                 selected_regs[reg_name],
                                                                                 constraint))
                    del (selected_regs[reg_name])
                    break

        if not reg_added:
            rec_depth += 1
            if i - rec_depth <= 0:
                return i, rec_depth, regs_def, reg_order, selected_regs

            return generate_regs_recursive(i, rec_depth, regs_def, reg_order, selected_regs, constraints)
        else:
            i += 1

    return i, rec_depth, regs_def, reg_order, selected_regs


def generate_regs(regs_def, constraints, reg_order):
    selected_regs = {}
    i = 0
    rec_depth = 0
    i, rec_depth, regs_def, reg_order, selected_regs = generate_regs_recursive(i, rec_depth, regs_def, reg_order,
                                                                               selected_regs, constraints)
    if i < 0:
        return False
    if len(reg_order) != len(selected_regs):
        return False, reg_order, selected_regs

    return True, reg_order, selected_regs


def get_regs_order(regs_def):
    slash.logger.info("setting regs generation order")
    reg_order = list()
    reg_order.extend(("GNRLrangeFinder", "EPTGframeRate", "FRMWyres", "FRMWmarginT",
                      "FRMWmarginB", "GNRLimgVsize", "FRMWxres",
                      "FRMWmarginR", "FRMWmarginL", "GNRLimgHsize", "FRMWyfov", "FRMWgaurdBandV", "GNRLsampleRate",
                      "EPTGmirrorFastFreq",
                      "GNRLcodeLength", "MTLBtxSymbolLength", "FRMWcoarseSampleRate", "FRMWxfov", "FRMWgaurdBandH",
                      "DIGGundistBypass",
                      "FRMWundistYfovFactor", "FRMWundistXfovFactor", "DCORoutIRnest", "DCORoutIRcma", "DESTaltIrEn",
                      "RASToutIRvar", "JFILbypass", "DCORbypass", "DIGGnestBypass", "FRMWtxCode_000", "FRMWtxCode_001",
                      "FRMWtxCode_002", "FRMWtxCode_003", "EPTGreturnTime", "EPTGminZ", "EPTGmaxZ", "EPTGnMaxSamples",
                      "JFILedge1maxTh", "JFILedge1detectTh", "JFILedge4maxTh", "JFILedge4detectTh",
                      "JFILedge3maxTh", "JFILedge3detectTh", "DIGGsphericalEn", "RASTbiltBypass", "CBUFbypass",
                      "MTLBxyRasterInput"))
    for reg_name in regs_def.keys():
        if reg_name not in reg_order:
            reg_order.append(reg_name)

    return reg_order


def get_constrains_map():
    regs_def_path = r"../../+Pipe/tables/regsDefinitions.frmw"
    regs_def = read_regs_file(regs_def_path)
    regs_def = clean_regs_list_to_generate(regs_def)

    constraints_def_path = r"../../+Pipe/tables/regsConstraints.frmw"
    constraints_list = get_constraints_list(constraints_def_path)
    constraints = create_constrains_table(constraints_list)
    con = {}
    for reg in regs_def.keys():
        l = list()
        for cons in constraints:
            if reg in cons.get_regs():
                for r in cons.get_regs():
                    if r != reg:
                        l.append(r)
        con[reg] = l
    for k, v in con.items():
        print(k, v)


def to_hex(val, nbits):
    return hex((val + (1 << nbits)) % (1 << nbits))


def write_regs_file(file_path, selected_regs, regs_def):
    data = list()
    for reg, value in selected_regs.items():
        reg_data = regs_def[reg]
        reg_type = reg_data["type"]
        if reg_type == "single":
            val = hex(struct.unpack('<I', struct.pack('<f', value))[0])[2:]
            data.append("{}{}{}{}\n".format(reg, " " * (30 - len(reg)), "h", val))
        else:
            data.append("{}{}{}{}\n".format(reg, " " * (30 - len(reg)), "h", to_hex(value, 32)[2:]))

    print_regs(data)
    slash.logger.debug("writing file: {}".format(file_path))
    if not os.path.isdir(os.path.dirname(os.path.relpath(file_path))):
        os.makedirs(os.path.dirname(os.path.relpath(file_path)))
    with open(file_path, "w") as txt_file:
        txt_file.writelines(data)


def print_regs(selected_regs):
    slash.logger.debug("regs list: {}".format(selected_regs))


def debug_test():
    log.create_logger(log_path="logs\\", log_name="debug")

    logging.info("init matlab")
    eng = matlab_eng.MyMatlab()
    eng.add_path(os.path.join("../../../algo_ivcam2"))

    test_status = {"pass": 0, "fail": 0, "pattern_generator_constraint": 0, "pattern_generator_crash": 0,
                   "Randomize_failed": 0}

    data_path, file_path = get_data_path()

    constraints_def_path = r"../../+Pipe/tables/regsConstraints.frmw"
    constraints_list = get_constraints_list(constraints_def_path)
    constraints = create_constrains_table(constraints_list)

    regs_def_path = r"../../+Pipe/tables/regsDefinitions.frmw"
    regs_def = read_regs_file(regs_def_path)
    regs_def = clean_regs_list_to_generate(regs_def)

    iterations = 10
    logging.info("Start test, number of iterations: {}".format(iterations))

    reg_order = get_regs_order(regs_def)

    for i in range(iterations):
        iteration = i + 1
        logging.info("start iteration: {}".format(iteration))
        logging.debug("clear matlab memory")
        eng.s.clear_memory(stdout=out, stderr=err, nargout=0)
        out.truncate(0)
        err.truncate(0)

        status, reg_order, selected_regs = generate_regs(regs_def, constraints, reg_order)
        if not status:
            test_status["Randomize_failed"] += 1
            logging.info("generate randomize failed")
            continue

        print_regs(selected_regs)
        write_regs_file(file_path, selected_regs, regs_def)

        status, ivs_file_name = run_pattern_generator(eng, file_path, data_path)
        if status == 1:
            test_status["pattern_generator_constraint"] += 1
            continue
        if status == 2:
            test_status["pattern_generator_crash"] += 1
            continue

        if not run_autopipe(eng, ivs_file_name, data_path, iteration):
            test_status["fail"] += 1
            continue

        slash.logger.info("test passed")

        test_status["pass"] += 1

    logging.info(test_status)


if __name__ == "__main__":
    try:
        debug_test()
    except Exception as ex:
        logging.error(ex)
        raise
    # get_constrains_map()


def get_data_path():
    data_path = os.path.join(os.path.dirname(os.path.realpath("__file__")), "Avv", "test_data", "regs_random")
    file_name = "regs_info"
    file_ext = ".csv"
    file_path = os.path.join(data_path, file_name + file_ext)
    slash.logger.info("regs file path: {}".format(file_path))
    return data_path, file_path

@a_common.ivcam2
def test_random_registers_randomize_100():
    test_status = {"pass": 0, "fail": 0, "pattern_generator_constraint": 0, "pattern_generator_crash": 0,
                   "Randomize_failed": 0}
    eng = slash.g.mat
    data_path, file_path = get_data_path()
    iterations = 100

    slash.logger.info("Start test, number of iterations: {}".format(iterations))
    for i in range(iterations):
        iteration = i + 1
        slash.logger.info("start iteration: {}".format(iteration))
        out.truncate(0)
        err.truncate(0)

        if not run_randomize(eng, file_path):
            test_status["randomize_crash"] += 1
            slash.logger.info("test {} failed- randomize_crash".format(i), extra={"highlight": True})
            continue

        status, ivs_file_name = run_pattern_generator(eng, file_path, data_path)
        if status == 1:
            slash.logger.info("test {} failed - pattern_generator_constraint".format(i), extra={"highlight": True})
            test_status["pattern_generator_constraint"] += 1
            continue
        if status == 2:
            slash.logger.info("test {} failed - pattern_generator_crash".format(i), extra={"highlight": True})
            test_status["pattern_generator_crash"] += 1
            continue

        if not run_autopipe(eng, ivs_file_name, data_path, i):
            test_status["fail"] += 1
            slash.logger.info("test {} failed - FAIL".format(i), extra={"highlight": True})
            continue

        slash.logger.info("test {} passed".format(i), extra={"highlight": True})
        test_status["pass"] += 1

    slash.logger.info(test_status, extra={"highlight": True})


@a_common.ivcam2
def test_random_registers_autogen_100():
    test_status = {"pass": 0, "fail": 0, "pattern_generator_constraint": 0, "pattern_generator_crash": 0,
                   "Randomize_failed": 0}
    eng = slash.g.mat
    data_path, file_path = get_data_path()

    constraints_def_path = r"+Pipe/tables/regsConstraints.frmw"
    constraints_list = get_constraints_list(constraints_def_path)
    constraints = create_constrains_table(constraints_list)

    regs_def_path = r"+Pipe/tables/regsDefinitions.frmw"
    regs_def = read_regs_file(regs_def_path)
    regs_def = clean_regs_list_to_generate(regs_def)

    iterations = 100
    slash.logger.info("Start test, number of iterations: {}".format(iterations))

    reg_order = get_regs_order(regs_def)

    for i in range(iterations):
        iteration = i + 1
        out.truncate(0)
        err.truncate(0)

        slash.logger.info("start iteration: {}".format(iteration))
        slash.logger.debug("clear matlab memory")
        eng.s.clear_memory(stdout=out, stderr=err, nargout=0)

        status, reg_order, selected_regs = generate_regs(regs_def, constraints, reg_order)
        if not status:
            test_status["Randomize_failed"] += 1
            slash.logger.info("test {} failed - generate randomize failed".format(iteration), extra={"highlight": True})
            continue

        print_regs(selected_regs)
        write_regs_file(file_path, selected_regs, regs_def)

        status, ivs_file_name = run_pattern_generator(eng, file_path, data_path)
        if status == 1:
            slash.logger.info("test {} failed - pattern_generator_constraint".format(iteration), extra={"highlight": True})
            test_status["pattern_generator_constraint"] += 1
            continue
        if status == 2:
            slash.logger.info("test {} failed - pattern_generator_crash".format(iteration), extra={"highlight": True})
            test_status["pattern_generator_crash"] += 1
            continue

        if not run_autopipe(eng, ivs_file_name, data_path, iteration):
            test_status["fail"] += 1
            slash.logger.info("test {} failed - FAIL".format(iteration), extra={"highlight": True})
            continue

        slash.logger.info("test {} passed".format(iteration), extra={"highlight": True})
        test_status["pass"] += 1

    slash.logger.info(test_status, extra={"highlight": True})
