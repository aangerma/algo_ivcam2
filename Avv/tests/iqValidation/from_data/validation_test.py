# ! python3
import slash
import sys

sys.path.insert(0, r"..\algo_automation\tests")
import runIqValidation


@slash.tag('turn_in')
def test_validation_turn_in():
    filePath = r'Avv/tests/iqValidation/from_data/turn_in.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.validationExecution(filePath)


def test_validation_es2():
    filePath = r'Avv/tests/iqValidation/from_data/es2.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.validationExecution(filePath)


@slash.tag('turn_in')
def test_validation_ivs():
    filePath = r'Avv/tests/iqValidation/from_data/ivs.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.validationExecution(filePath)


@slash.tag('ds')
def test_validation_ds5u_camera():
    filePath = r'Avv/tests/iqValidation/from_data/ds5u_camera.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.validationExecution(filePath)


@slash.tag('ds')
def test_validation_d4m_camera():
    filePath = r'Avv/tests/iqValidation/from_data/d4m_camera.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.validationExecution(filePath)


if __name__ == "__main__":
    test_validation_turn_in()