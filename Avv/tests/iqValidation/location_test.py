# ! python3
import slash
import sys
import os

sys.path.insert(0, r"..\algo_automation\infra")
import matlab_eng

sys.path.insert(0, r"..\algo_automation\tests")
import runIqValidation


@slash.tag('robot')
def test_validation_robot_grid_angle():
    filePath = r'Avv/tests/iqValidation/robot_grid_angle.xml'
    # filePath = r'robot_grid_angle.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.positional_test(filePath)


if __name__ == "__main__":
    test_validation_robot_grid_angle()