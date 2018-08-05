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


def get_params_from_xml(root):
    params = dict()
    for cElement in root.find('./params'):
        params[cElement.tag] = cElement.text

    slash.logger.debug("test params: {}".format(params))
    return params


def get_tests_from_xml(root):
    tests = dict()
    for cElement in root.find('tests'):
        tName = "{}_{}_{}".format(cElement.attrib['metrics'], cElement.attrib['target'], cElement.attrib['distance'])
        try:
            if cElement.attrib['name']:
                tName = cElement.attrib['name']
        except:
            pass

        tests[tName] = cElement.attrib
        tests[tName]['name'] = tName

    slash.logger.debug("tests: {}".format(tests))
    return tests


def to_save_data(root):
    db_path = None
    for db in root.findall('./db[@saveData="yes"]'):
        db_path = db.text

    if db_path is None:
        slash.logger.debug("Not saving results to db")
    else:
        slash.logger.debug("save db, path: {}".format(db_path))
    return db_path


def save_data(db, data):
    if db is None:
        return
    slash.logger.info("saving to db file: {}".format(db), extra={"highlight": True})
    if not path.isdir(path.dirname(db)):
        os.makedirs(path.dirname(db))
    with open(db, 'a') as file:
        json.dump(data, file)
        file.write('\n')


def validation(xmlPath):
    try:
        slash.logger.info("test xml definition file: {}".format(xmlPath), extra={"highlight": True})
        xml = et.parse(xmlPath)
    except FileNotFoundError:
        filePath = r'debug.xml'
        slash.logger.info("test xml definition file: {}".format(xmlPath))
        xml = et.parse(filePath)
    root = xml.getroot()

    test_params = get_params_from_xml(root)
    tests = get_tests_from_xml(root)
    db = to_save_data(root)

    systemName = "camera"
    if db is not None:
        systemName = input("Camera name: ")
        if not systemName:
            return
    slash.logger.info("start test for: {}".format(systemName), extra={"highlight": True})

    testTime = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    slash.logger.info("test time: {}".format(testTime))

    params = {'config': test_params}

    eng = slash.g.mat
    out = io.StringIO()
    err = io.StringIO()

    validationResults = None
    try:
        score, validationResults = eng.s.Validation.runIQValidation(tests, params, stdout=out, stderr=err, nargout=2)
    except Exception as e:
        slash.logger.debug('matlab out: {}'.format(out.getvalue()))
        slash.logger.error('matlab error: {}'.format(err.getvalue()))
        raise e

    slash.logger.debug('matlab out: {}'.format(out.getvalue()))
    slash.logger.debug("validation results: {}".format(validationResults))
    slash.logger.debug("validation score: {}".format(score))

    data = {systemName: {'testTime': testTime, 'result': validationResults}}
    save_data(db, data)

    testFailed = False
    for test in tests.keys():
        try:
            tScore = float(score[test])
            thresholds = tests[test]["threshold"].replace('[','').replace(']','').replace(' ','').split(':')
            tbottomThreshold = float(thresholds[0])
            tTopThreshold = float(thresholds[1])

            testStatus = tbottomThreshold < tScore < tTopThreshold
            s = "test: {}, score: {}, threshold: {}, result: {}".format(test, score[test], tests[test]["threshold"],
                                                                    testStatus)
        except TypeError:
            testStatus = False
            s = "test: {}, failed converting result: {}".format(test, score[test])

        if testStatus:
            slash.logger.info(s, extra={"highlight": True})
        else:
            testFailed = True
            slash.logger.error(s, extra={"highlight": True})

    if testFailed:
        raise a_common.TestFail("Test failed please review log")


# slash run -vv -l Avv/logs/ -o log.highlights_subpath={context.session.id}/highlights.log -f Avv/tests/test_list.txt -k test_validation_debug
def test_validation_debug():
    filePath = r'Avv/tests/validation/debug.xml'
    validation(filePath)


def test_validation_regression():
    filePath = r'Avv/tests/validation/regression.xml'
    validation(filePath)


def test_validation_turn_in():
    filePath = r'Avv/tests/validation/turn_in.xml'
    validation(filePath)


def test_validation_es2():
    filePath = r'Avv/tests/validation/es2.xml'
    validation(filePath)