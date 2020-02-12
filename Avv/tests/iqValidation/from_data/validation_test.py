# ! python3
import slash
import sys

sys.path.insert(0, r"..\algo_automation\tests")
import runIqValidation


# IVCAM 2.0 turn in tests - mat, ivs, bin extensions supported.
@slash.tag('turn_in_mat')
def test_validation_turn_in_mat():
    filePath = r'x:\Avv\sources\validation_turn_in\Turn_in_mat\turn_in_mat.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.validationExecution(filePath)


@slash.tag('turn_in_IVS')
def test_validation_turn_in_ivs():
    filePath = r'x:\Avv\sources\validation_turn_in\Turn_in_IVS\turn_in_ivs.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.validationExecution(filePath)


@slash.tag('turn_in_bin')
def test_validation_turn_in_bin():
    filePath = r'x:\Avv\sources\validation_turn_in\Turn_in_bin\turn_in_bin.xml'
    slash.logger.info("running iqValidation test, xml: {}".format(filePath), extra={"highlight": True})
    runIqValidation.validationExecution(filePath)

# IVCAM 2.0 turn in tests - END here ----

def test_validation_es2():
    filePath = r'Avv/tests/iqValidation/from_data/es2.xml'
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
    test_validation_turn_in_mat()
    test_validation_turn_in_ivs()
    test_validation_turn_in_bin()
