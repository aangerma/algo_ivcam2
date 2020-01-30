# ! python3
import slash
import sys

sys.path.insert(0, r"..\algo_automation\tests")
import runIqValidation


@slash.tag('robot')
def test_validation_robot_regression_vga_long():
    filePath = r'Avv/tests/iqValidation/robot/robot_regression_vga_long.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.robotRun(filePath)


@slash.tag('robot')
def test_validation_robot_regression_vga_short():
    filePath = r'Avv/tests/iqValidation/robot/robot_regression_vga_short.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.robotRun(filePath)


@slash.tag('robot')
def test_validation_robot_regression_xga_long():
    filePath = r'Avv/tests/iqValidation/robot/robot_regression_xga_long.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.robotRun(filePath)


@slash.tag('robot')
def test_validation_robot_regression_xga_short():
    filePath = r'Avv/tests/iqValidation/robot/robot_regression_xga_short.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.robotRun(filePath)


@slash.tag('robot')
def test_validation_robot_algonas():
    filePath = r'X:/Avv/sources/robot/robot.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.robotRun(filePath)


@slash.tag('robot')
def test_validation_robot_time_drift():
    filePath = r'Avv/tests/iqValidation/robot/robot_long_test.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.robotRun(filePath)


def test_validation_DEBUG():
    filePath = r'Avv/tests/iqValidation/debug.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.robotRun(filePath)


@slash.tag('analsys')
def test_validation_Run():
    runIqValidation.runMatlabValidation()


@slash.tag('FW')
def test_validation_FW():
    filePath = r'I:\AVV\tests\iqValidation\Algo_FW\FW_regression_vga_long.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.robotRun(filePath, robotFlag=False)
