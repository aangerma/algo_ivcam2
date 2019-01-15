# ! python3
import slash
import sys
import os

sys.path.insert(0, r"..\algo_automation\infra")
import matlab_eng

sys.path.insert(0, r"..\algo_automation\tests")
import runIqValidation


def validation_debug():
    filePath = r'debug.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.validation_test(filePath)


def test_validation_regression():
    filePath = r'Avv/tests/iqValidation/regression.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.validation_test(filePath)

@slash.tag('turn_in')
def test_validation_turn_in():
    filePath = r'Avv/tests/iqValidation/turn_in.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.validation_test(filePath)


def test_validation_es2():
    filePath = r'Avv/tests/iqValidation/es2.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.validation_test(filePath)


@slash.tag('turn_in')
def test_validation_ivs():
    filePath = r'Avv/tests/iqValidation/ivs.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.validation_test(filePath)


@slash.tag('ds')
def test_validation_ds5u_camera():
    filePath = r'Avv/tests/iqValidation/ds5u_camera.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.validation_test(filePath)


@slash.tag('ds')
def test_validation_d4m_camera():
    filePath = r'Avv/tests/iqValidation/d4m_camera.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.validation_test(filePath)


@slash.tag('robot')
def test_validation_robot_regression():
    filePath = r'Avv/tests/iqValidation/robot_regression.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.validation_test(filePath)


@slash.tag('robot')
def test_validation_robot_algonas():
    filePath = r'X:/Avv/sources/robot/robot.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.validation_test(filePath)


@slash.tag('robot')
def test_validation_robot_max_range():
    filePath = r'Avv/tests/iqValidation/robot_max_range.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.validation_test(filePath)


@slash.tag('robot')
def test_validation_robot_system():
    filePath = r'Avv/tests/iqValidation/robot_system.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.validation_test(filePath)


if __name__ == "__main__":
    test_validation_robot_grid_angle()