# ! python3
import slash
import sys

sys.path.insert(0, r"..\algo_automation\tests")
import runIqValidation


@slash.tag('robot')
def test_validation_robot_regression():
    filePath = r'Avv/tests/iqValidation/robot/robot_regression.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.validation_test(filePath)


@slash.tag('robot')
def test_validation_robot_algonas():
    filePath = r'X:/Avv/sources/robot/robot.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.validation_test(filePath)


@slash.tag('robot')
def test_validation_robot_max_range():
    filePath = r'Avv/tests/iqValidation/robot/robot_max_range.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.validation_test(filePath)


@slash.tag('robot')
def test_validation_robot_system():
    filePath = r'Avv/tests/iqValidation/robot/robot_system.xml'
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


if __name__ == "__main__":
    test_validation_robot_regression()