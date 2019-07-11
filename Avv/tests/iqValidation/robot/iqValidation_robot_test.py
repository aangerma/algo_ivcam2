# ! python3
import slash
import sys

sys.path.insert(0, r"..\algo_automation\tests")
import runIqValidation


@slash.tag('robot')
def test_validation_robot_regression_long():
    filePath = r'Avv/tests/iqValidation/robot/robot_regression_long.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.validation_test(filePath)


@slash.tag('robot')
def test_validation_robot_regression_short():
    filePath = r'Avv/tests/iqValidation/robot/robot_regression_short.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.validation_test(filePath)


@slash.tag('robot')
def test_validation_robot_algonas():
    filePath = r'X:/Avv/sources/robot/robot.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.validation_test(filePath)


@slash.tag('robot')
def test_validation_robot_grid_angle():
    filePath = r'Avv/tests/iqValidation/robot/robot_grid_angle.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.validation_test(filePath)


@slash.tag('robot')
def test_validation_robot_time_drift():
    filePath = r'Avv/tests/iqValidation/robot/robot_long_test.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.validation_test(filePath)

def test_validation_DEBUG():
    filePath = r'Avv/tests/iqValidation/debug.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.validation_test(filePath)

if __name__ == "__main__":
    test_validation_robot_regression()