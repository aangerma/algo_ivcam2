#! python3
import slash
import sys
sys.path.insert(0, r"Avv\tests")
# import a_common
sys.path.insert(0, r"..\algo_automation\infra")
import robot


@slash.tag('robot')
def test_robot_reset():
    robot.reset()

