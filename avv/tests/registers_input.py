#! python3
import slash
import os
import logging
import random
import matlab
import io
import sys

sys.path.insert(0, r"..\algo_automation\infra")
import regs_files
import regsConstraints
import testsRegs

sys.path.insert(0, r"Avv\tests")
import a_common

try:
    from aux_functions import log
except ImportError:
    log = None
    pass

try:
    import matlab_eng
except Exception:
    pass


def run_randomize(eng, file_path):
    slash.logger.debug("running matlab randomize")
    try:
        regs_random_list = [
            'EPTGframeRate', 'FRMWxfov_000', 'FRMWxfov_001', 'FRMWxfov_002', 'FRMWxfov_003', 'FRMWxfov_004',
            'FRMWyfov_000', 'FRMWyfov_001', 'FRMWyfov_002', 'FRMWyfov_003', 'FRMWyfov_004', 'FRMWprojectionYshear_000',
            'FRMWprojectionYshear_001', 'FRMWprojectionYshear_002', 'FRMWprojectionYshear_003',
            'FRMWprojectionYshear_004', 'FRMWlaserangleH',
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
        eng.s.Pipe.autopipe(file_path, 'viewResults', False, stdout=out, stderr=err, nargout=0)

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

    slash.logger.info(
        "clean reg list for generate, regs definition: {}, to generate: {}".format(len(regs), len(regs_to_generate)))
    return regs_to_generate


def get_random_value(reg, selected_regs):
    reg_name = reg["regName"]
    array_size = int(reg["arraySize"])
    reg_type = reg["type"]

    if "logical" in reg_type:
        array_size = 1

    num = list()

    for i in range(array_size):
        selected_range = testsRegs.get_reg_range(reg)

        if ":" not in selected_range:
            num.append(regs_files.convert_to_number(selected_range))
        else:
            ranges = str(selected_range).split(":")
            start = regs_files.convert_to_number(ranges[0])
            end = regs_files.convert_to_number(ranges[1])

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

            if type(start) == int and type(end) == int:
                num.append(random.randint(start, end))
            else:
                num.append(round(random.uniform(start, end), 10))

            if reg_name in ("GNRLimgHsize", "GNRLimgVsize", "GNRLcodeLength"):
                if num[len(num) - 1] % 2 != 0:
                    num[len(num) - 1] += 1
    # logging.debug("reg: {}, nums: {}".format(reg_name,num))
    return testsRegs.concatenate_ints(num, reg_type)


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

        if reg_name in (
                "FRMWundistYfovFactor", "FRMWundistXfovFactor", "EPTGmultiFocalROI_000", "EPTGmultiFocalROI_001",
                "EPTGmultiFocalROI_002", "EPTGmultiFocalROI_003", "MTLBassertionStop", "FRMWxR2L", "MTLBdebug"):
            selected_regs[reg_name] = regs_files.convert_to_number(reg["defaultValue"][1:])
            i += 1
            continue

        if "MTLB" in reg_name and "MTLBtxSymbolLength" not in reg_name:
            selected_regs[reg_name] = regs_files.convert_to_number(reg["defaultValue"][1:])
            i += 1
            continue

        reg_added = False
        constraint_fail_index = 0
        while not reg_added:
            value = get_random_value(reg, selected_regs)
            selected_regs[reg_name] = value

            reg_added, constraint = regsConstraints.check_for_restriction(reg_name, selected_regs, constraints, regs_def)
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
    reg_order.extend(("GNRLrangeFinder", "EPTGframeRate", "GNRLimgHsize", "GNRLimgVsize", "FRMWyfov_000", "FRMWyfov_001",
                      "FRMWyfov_002", "FRMWyfov_003", "FRMWyfov_004", "FRMWguardBandV", "GNRLsampleRate",
                      "EPTGmirrorFastFreq",
                      "GNRLcodeLength", "MTLBtxSymbolLength", "FRMWcoarseSampleRate", "FRMWxfov_000", "FRMWxfov_001",
                      "FRMWxfov_002", "FRMWxfov_003", "FRMWxfov_004", "FRMWguardBandH",
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


# def get_constrains_map(regs_def_path, constraints_def_path):
#     regs_def_path = r"../../+Pipe/tables/regsDefinitions.frmw"
#     regs_def = regs_files.read_regs_file(regs_def_path)
#     regs_def = clean_regs_list_to_generate(regs_def)
#
#     constraints_def_path = r"../../+Pipe/tables/regsConstraints.frmw"
#     constraints_list = regsConstraints.get_constraints_list(constraints_def_path)
#     constraints = regsConstraints.create_constrains_table(constraints_list)
#     con = {}
#     for reg in regs_def.keys():
#         l = list()
#         for cons in constraints:
#             if reg in cons.get_regs():
#                 for r in cons.get_regs():
#                     if r != reg:
#                         l.append(r)
#         con[reg] = l
#     for k, v in con.items():
#         print(k, v)
#

def debug_test():
    log.create_logger(log_path="logs\\", log_name="debug")

    logging.info("init matlab")
    eng = matlab_eng.MyMatlab()
    eng.add_path(os.path.join("../../../algo_ivcam2"))
    eng.add_path(os.path.join("../../../algo_common/Common"))

    test_status = {"pass": 0, "fail": 0, "pattern_generator_constraint": 0, "pattern_generator_crash": 0,
                   "Randomize_failed": 0}

    data_path, file_path = get_data_path()

    csv_file_path = r"../../docs/IVCAM2.0_AlgoPipe_AD.csv"
    logging.info("reading file: {}".format(csv_file_path))
    data = list()
    with open(csv_file_path, "r") as dataFile:
        for line in dataFile:
            data.append(line.split(","))

    regsTests = {}
    for index in range(1, len(data[0])):
        tmp_data = {}
        for reg_index in range(1, len(data)):
            if data[reg_index][index] != "" and "\n" not in data[reg_index][index]:
                if data[reg_index][index].lower() in "true":
                    tmp_data[data[reg_index][0]] = 1
                elif data[reg_index][index].lower() in "false":
                    tmp_data[data[reg_index][0]] = 0
                else:
                    tmp_data[data[reg_index][0]] = regs_files.convert_to_number(data[reg_index][index])

        regsTests[data[0][index]] = tmp_data

    logging.info("file number of entries: {}".format(len(regsTests)))

    for mode, regs in regsTests.items():
        out.truncate(0)
        err.truncate(0)

        logging.info("start mode: {}".format(mode))
        logging.info("clear matlab memory")
        # eng.clear_memory(stdout=out, stderr=err, nargout=0)

        regs_files.print_regs(regs)
        regs_def = testsRegs.create_regs_def(regs)
        regs_files.write_regs_file(file_path, regs, regs_def)

        status, ivs_file_name = run_pattern_generator(eng, file_path, data_path)
        if status == 1:
            logging.info("test {} failed - pattern_generator_constraint".format(mode), extra={"highlight": True})
            test_status["pattern_generator_constraint"] += 1
            continue
        if status == 2:
            logging.info("test {} failed - pattern_generator_crash".format(mode), extra={"highlight": True})
            test_status["pattern_generator_crash"] += 1
            continue

        if not run_autopipe(eng, ivs_file_name, data_path, mode):
            test_status["fail"] += 1
            logging.info("test {} failed - FAIL".format(mode), extra={"highlight": True})
            continue

        logging.info("test {} passed".format(mode), extra={"highlight": True})
        test_status["pass"] += 1

    logging.info(test_status)


def get_data_path():
    data_path = os.path.join(os.path.dirname(os.path.realpath("__file__")), "Avv", "test_data", "regs_random")
    file_name = "regs_info"
    file_ext = ".csv"
    file_path = os.path.join(data_path, file_name + file_ext)
    slash.logger.info("regs file path: {}".format(file_path))
    return data_path, file_path


if __name__ == "__main__":
    try:
        debug_test()
    except Exception as ex:
        logging.error(ex)
        raise
    # get_constrains_map()


@a_common.ivcam2
def test_random_registers_randomize_100():
    # Random from matlab function
    test_status = {"pass": 0, "fail": 0, "pattern_generator_constraint": 0, "pattern_generator_crash": 0,
                   "Randomize_failed": 0}
    eng = slash.g.mat
    # eng.s.dbug_error(stdout=out, stderr=err, nargout=0)
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

        slash.logger.info("test {} passed".format(iteration), extra={"highlight": True})
        test_status["pass"] += 1

    slash.logger.info(test_status, extra={"highlight": True})


def random_registers(iterations=1):
    debug = False
    if debug:
        slash.logger.warning("Running in DEBUG mode")
        slash.logger.warning("Running in DEBUG mode")
        slash.logger.warning("Running in DEBUG mode")
        slash.logger.warning("Running in DEBUG mode")
        slash.logger.warning("Running in DEBUG mode")

    test_status = {"pass": 0, "fail": 0, "pattern_generator_constraint": 0, "pattern_generator_crash": 0,
                   "Randomize_failed": 0}
    eng = slash.g.mat
    data_path, file_path = get_data_path()

    constraints_def_path = r"+Pipe/tables/regsConstraints.frmw"
    constraints_list = regsConstraints.get_constraints_list(constraints_def_path)
    constraints = regsConstraints.create_constrains_table(constraints_list)

    regs_def_path = r"+Pipe/tables/regsDefinitions.frmw"
    regs_def = regs_files.read_regs_file(regs_def_path)
    regs_def = clean_regs_list_to_generate(regs_def)

    iterations = 100
    if debug:
        iterations = 10

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

        regs_files.print_regs(selected_regs)
        regs_files.write_regs_file(file_path, selected_regs, regs_def)

        status, ivs_file_name = run_pattern_generator(eng, file_path, data_path)
        if status == 1:
            slash.logger.info("test {} failed - pattern_generator_constraint".format(iteration),
                              extra={"highlight": True})
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

    if test_status["fail"] > 0 or test_status["pattern_generator_crash"] > 0:
        raise a_common.TestFail("Test failed please review log")


@a_common.ivcam2
def test_random_registers_autogen_100():
    random_registers(iterations=100)


@slash.tag('turn_in')
def test_regs_mode_table():
    eng = slash.g.mat

    test_status = {"pass": 0, "fail": 0, "pattern_generator_constraint": 0, "pattern_generator_crash": 0,
                   "Randomize_failed": 0}
    data_path, file_path = get_data_path()

    mode_table_path = r'docs/IVCAM2.0_AlgoPipe_AD.xlsx'
    regsTests = regs_files.get_mode_table(mode_table_path)

    regs_def_path = r"+Pipe/tables/regsDefinitions.frmw"
    regs_def = regs_files.read_regs_file(regs_def_path)

    executed_tests = 0
    for mode, modeTest in regsTests.items():
        if not modeTest.automated():
            continue
        executed_tests += 1
        out.truncate(0)
        err.truncate(0)

        slash.logger.info("start mode: {}".format(mode))
        slash.logger.debug("clear matlab memory")
        eng.s.clear_memory(stdout=out, stderr=err, nargout=0)

        regs_files.print_regs(modeTest.get_regs())
        regs_files.write_regs_file(file_path, modeTest.get_regs(), regs_def)

        status, ivs_file_name = run_pattern_generator(eng, file_path, data_path)
        if status == 1:
            slash.logger.info("test {} failed - pattern_generator_constraint".format(mode), extra={"highlight": True})
            test_status["pattern_generator_constraint"] += 1
            continue
        if status == 2:
            slash.logger.info("test {} failed - pattern_generator_crash".format(mode), extra={"highlight": True})
            test_status["pattern_generator_crash"] += 1
            continue

        if not run_autopipe(eng, ivs_file_name, data_path, mode):
            test_status["fail"] += 1
            slash.logger.info("test {} failed - FAIL".format(mode), extra={"highlight": True})
            continue

        slash.logger.info("test {} passed".format(mode), extra={"highlight": True})
        test_status["pass"] += 1

    slash.logger.info(test_status)
    if test_status["pass"] != executed_tests:
        raise a_common.TestFail("Test failed please review log")
