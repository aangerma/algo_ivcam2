#! python3
import slash
import matlab
import io
import sys
import os
import os.path as path
import xml.etree.ElementTree as et
import glob

sys.path.insert(0, r"Avv\tests")
import a_common


def calibration_turnin(mode='turnin'):
    xmlPath = r'X:\Avv\sources\calibration\calibration_turnin.xml'

    try:
        xml = et.parse(xmlPath)
        slash.logger.info("test xml definition file: {}".format(xmlPath), extra={"highlight": True})
    except FileNotFoundError:
        slash.logger.error("test xml definition file not found: {}".format(xmlPath))
        raise FileNotFoundError

    root = xml.getroot()
    output_dir_Path = root.find('./output_dir_Path').text
    calibparamsfilename = root.find('./calibration_params_filename').text
    calibParamsPath = os.path.join(os.getcwd(), 'Tools', 'CalibTools', 'IV2calibTool', calibparamsfilename)
    slash.logger.info("Calibration params path: {}".format(calibParamsPath), extra={"highlight": True})

    figfiles = glob.glob(os.path.join(output_dir_Path, 'figures', '*.*'))
    for f in figfiles:
        os.remove(f)

    params = dict()
    basic_path = root.find('./' + mode).text
    for element in root.find('./calibration_path'):
        params[element.tag] = os.path.join(basic_path, element.text)
        slash.logger.debug("{} : {}".format(element.tag, params[element.tag]))

    out = io.StringIO()
    err = io.StringIO()
    eng = slash.g.mat

    try:
        res = eng.s.test_calibration(calibParamsPath, output_dir_Path, params["DFZ_calib_path"],params["DSM_calib_path"],params["END_calib_path"],params["RGB_calib_path"],params["ROI_calib_path"],params["Short_Preset_calib_path"],params["Long_Preset_state1_calib_path"],params["Long_Preset_state2_calib_path"], stdout=out, stderr=err, nargout=1)
    except matlab.engine.MatlabExecutionError:
        s_err = err.getvalue()
        slash.logger.error("report crashed: {}".format(s_err))
        slash.logger.info(out.getvalue())
        raise RuntimeError

    slash.logger.debug(out.getvalue())
    slash.logger.info('** Matlab output:')

    for line in out.getvalue().splitlines():
        if '**' in line:
            if 'passed' in line:
                slash.logger.info('{}'.format(line), extra={"highlight": True})
            else:
                slash.logger.error('{}'.format(line))

    if not res:
        #raise a_common.TestFail('At least one of the tests failed')
        a_common.TestFail('At least one of the tests failed')


def test_calibration_turnin():
    calibration_turnin(mode='turnin')


def test_calibration_candidate():
    calibration_turnin(mode='candidate')


def test_robot_camera_calibration_ATC():
    CalibParamsXml = os.path.join(os.getcwd(), 'Tools', 'CalibTools', 'AlgoThermalCalibration', 'calibParams.xml')
    #runParamsXml = os.path.join(os.getcwd(), 'Tools', 'CalibTools', 'AlgoThermalCalibration', 'IV2AlgoThermalCalibTool.xml')

    try:
        CalibParams = et.parse(CalibParamsXml)
        slash.logger.info("CalibParams xml file: {}".format(CalibParamsXml), extra={"highlight": True})
    except FileNotFoundError:
        slash.logger.error("CalibParams xml file NOT FOUND: {}".format(CalibParamsXml))
        raise FileNotFoundError

    #try:
    #    runParams = et.parse(runParamsXml)
    #    slash.logger.info("runParams xml file: {}".format(runParamsXml), extra={"highlight": True})
    #except FileNotFoundError:
    #    slash.logger.error("runParams xml definition file NOT FOUND: {}".format(runParamsXml))
    #    raise FileNotFoundError

    root = CalibParams.getroot()
    robot = root.find('./robot')
    robot.find('./enable').text = "1"
    CalibParams.write(CalibParamsXml)
    slash.logger.info("Enable robot calibration: {}".format(robot.find('./enable').text), extra={"highlight": True})

    out = io.StringIO()
    err = io.StringIO()
    eng = slash.g.mat

    slash.logger.info("Starting ATC calibration- MATLAB...")

    try:
        eng.s.runThermalCalibrationWithoutGui(stdout=out, stderr=err, nargout=0)
    # except matlab.engine.MatlabExecutionError:
    except Exception as ex:
        slash.logger.error(ex)
        s_err = err.getvalue()
        slash.logger.error("Calibration crashed: {}".format(s_err))
        robot.find('./enable').text = "0"
        CalibParams.write(CalibParamsXml)
        slash.logger.info("Disable robot calibration: {}".format(robot.find('./enable').text), extra={"highlight": True})
        slash.logger.info(out.getvalue())
        raise RuntimeError

    robot.find('./enable').text = "0"
    CalibParams.write(CalibParamsXml)
    slash.logger.info("Disable robot calibration: {}".format(robot.find('./enable').text), extra={"highlight": True})

    slash.logger.info(out.getvalue())


def test_robot_camera_calibration_ACC():
    CalibParamsXml = os.path.join(os.getcwd(), 'Tools', 'CalibTools', 'AlgoCameraCalibration', 'calibParamsVXGA.xml')

    try:
        CalibParams = et.parse(CalibParamsXml)
        slash.logger.info("CalibParams xml file: {}".format(CalibParamsXml), extra={"highlight": True})
    except FileNotFoundError:
        slash.logger.error("CalibParams xml file NOT FOUND: {}".format(CalibParamsXml))
        raise FileNotFoundError

    root = CalibParams.getroot()
    robot = root.find('./robot')
    robot.find('./enable').text = "1"
    CalibParams.write(CalibParamsXml)
    slash.logger.info("Enable robot calibration: {}".format(robot.find('./enable').text), extra={"highlight": True})

    out = io.StringIO()
    err = io.StringIO()
    eng = slash.g.mat

    slash.logger.info("Starting ACC calibration- MATLAB...")
    try:
        eng.s.runCameraCalibrationWithoutGui(stdout=out, stderr=err, nargout=0)
    # except matlab.engine.MatlabExecutionError:
    except Exception as ex:
        slash.logger.error(ex)
        s_err = err.getvalue()
        slash.logger.error("Calibration crashed: {}".format(s_err))
        robot.find('./enable').text = "0"
        CalibParams.write(CalibParamsXml)
        slash.logger.info("Disable robot calibration: {}".format(robot.find('./enable').text), extra={"highlight": True})
        slash.logger.info(out.getvalue())
        raise RuntimeError

    robot.find('./enable').text = "0"
    CalibParams.write(CalibParamsXml)
    slash.logger.info("Disable robot calibration: {}".format(robot.find('./enable').text), extra={"highlight": True})

    slash.logger.info(out.getvalue())
