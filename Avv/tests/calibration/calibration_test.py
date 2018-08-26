#! python3
import slash
import io
import sys
import datetime
import os.path as path
import os
import json
import xml.etree.ElementTree as et

sys.path.insert(0, r"Avv\tests")
import a_common


def calibration(xmlPath):
    # c=Calibration.runCalibStream('D:\temp\calib0033_3\AlgoInternal\calibrationInputParams.xml','D:\gitsource\algo_ivcam2\scripts\IV2calibTool\calibParams.xml');
    calibFilePath = path.join(path.dirname(path.abspath(__file__)), '..\..\..\scripts\IV2calibTool\calibParams.xml')
    slash.logger.info("check calibrationInputParams.xml: {}".format(xmlPath),extra={"highlight": True})
    slash.logger.info("check calibParams.xml: {}".format(calibFilePath),
        extra={"highlight": True})
    if not path.exists(xmlPath):
        raise FileNotFoundError(xmlPath)

    if not path.exists(calibFilePath):
        raise FileNotFoundError(xmlPath)
    slash.logger.info("running calibration")
    eng = slash.g.mat
    out = io.StringIO()
    err = io.StringIO()

    try:
        calibPassed, score = eng.s.Calibration.runCalibStream(xmlPath, calibFilePath, stdout=out, stderr=err, nargout=2)
    except Exception as e:
        slash.logger.debug('matlab out: {}'.format(out.getvalue()))
        slash.logger.error('matlab error: {}'.format(err.getvalue()))
        raise e

    slash.logger.debug('matlab out: {}'.format(out.getvalue()))

    status = lambda x: 'pass' if x else 'failed'
    slash.logger.info("calibration : {}".format(status(calibPassed)), extra={"highlight": True})
    slash.logger.debug("calibration score: {}".format(score), extra={"highlight": True})

    try:
        score = float(score)
    except TypeError:
        slash.logger.error("calibration: failed converting result: {}".format(score), extra={"highlight": True})
        raise a_common.TestFail("Test failed please review log")

    threshold = 80
    s = "calibration: score: {}, threshold: {}, calibration out: {}".format(score, threshold, status(calibPassed))
    if score < threshold:
        slash.logger.error(s, extra={"highlight": True})
        raise a_common.TestFail("Test failed please review log")

    slash.logger.info(s, extra={"highlight": True})


# slash run -vv -l Avv/logs/ -o log.highlights_subpath={context.session.id}/highlights.log -f Avv/tests/test_list.txt -k test_calibration_basic
@slash.tag('turn_in')
def test_calibration_basic():
    filePath = r'X:\Avv\sources\calibration_record\sessionParams.xml'
    calibration(filePath)
