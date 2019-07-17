#! python3
import slash
import io
import sys
import os.path as path
import xml.etree.ElementTree as et

sys.path.insert(0, r"Avv\tests")
import a_common


def calibration(xmlPath):
    slash.logger.info("check calibrationInputParams.xml: {}".format(xmlPath),extra={"highlight": True})
    if not path.exists(xmlPath):
        raise FileNotFoundError(xmlPath)

    try:
        xml = et.parse(xmlPath)
        root = xml.getroot()
        calibFileName = root.find('./calibParamsFile').text
    except AttributeError:
        slash.logger.error("can't find calibParamsFile in xml")
        raise AttributeError

    calibFilePath = path.join(path.dirname(path.abspath(__file__)), '..\..\..\Tools\CalibTools\IV2calibTool\{}'.format(calibFileName))
    slash.logger.info("check calibParams.xml: {}".format(calibFilePath),extra={"highlight": True})
    if not path.exists(calibFilePath):
        raise FileNotFoundError(xmlPath)

    slash.logger.info("running calibration")
    eng = slash.g.mat
    out = io.StringIO()
    err = io.StringIO()

    try:
        calibPassed = eng.s.Calibration.runCalibStream(xmlPath, calibFilePath, stdout=out, stderr=err, nargout=1)
    except Exception as e:
        slash.logger.debug('matlab out: {}'.format(out.getvalue()))
        slash.logger.error('matlab error: {}'.format(err.getvalue()))
        raise e

    slash.logger.debug('matlab out: {}'.format(out.getvalue()))

    status = lambda x: 'pass' if x else 'failed'
    slash.logger.info("calibration : {}".format(status(calibPassed)), extra={"highlight": True})

    s = "calibration: out: {}".format(status(calibPassed))
    slash.logger.info(s, extra={"highlight": True})


# slash run -vv -l Avv/logs/ -o log.highlights_subpath={context.session.id}/highlights.log -f Avv/tests/test_list.txt -k test_calibration_basic
@slash.tag('turn_in')
def test_calibration_basic():
    filePath = r'X:\Avv\sources\calibration_record\basic\sessionParams.xml'
    calibration(filePath)
