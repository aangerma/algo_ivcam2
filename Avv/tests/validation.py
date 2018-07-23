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


def check_with_user(question):
    yes = ("y", "yes")
    no = ("n", "no")
    while True:
        answer = input(question)
        slash.logger.debug("user input: {}".format(answer))
        if answer.lower() in yes:
            return True
        elif answer.lower() in no:
            return False
        else:
            slash.logger.warning("Please provide a y/n answer")


# slash run -vv -l Avv/logs/ -o log.highlights_subpath={context.session.id}/highlights.log -f Avv/tests/test_list.txt -k test_validation_tests
def test_validation_tests():
    filePath = r'X:\Avv\debug\Validation.txt'
    vTests= list()
    if not check_with_user("To run all tests? "):
        xml = et.parse(r'+Validation/tests.xml')
        root = xml.getroot()
        for child in root:
            test = child.tag
            ch = child.getchildren()
            for a in ch:
                if a.tag == 'target':
                    target = a.text
            if check_with_user("to run: {}, with target: {}? ".format(test,target)):
                vTests.append(test)
    else:
        vTests.append("all")


    slash.logger.info("Running tests: {}".format(vTests))

    res = list()
    while True:
        systemName = input("Camera name: ")
        if not systemName:
            break
        slash.logger.info("start test for: {}".format(systemName))
        testTime = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        slash.logger.info("test time: {}".format(testTime))

        vTests=["all"]
        params = {'config':{'dataSource':'HW'}}
        slash.logger.debug("validation tests: {}".format(vTests))
        eng = slash.g.mat

        out = io.StringIO()
        err = io.StringIO()
        validationResults=None
        try:
            validationResults = eng.s.Validation.runValidation(vTests,params, stdout=out, stderr=err, nargout=1)
        except:
            slash.logger.error('matlab error: {}'.format(err.getvalue()))

        slash.logger.debug('matlab out: {}'.format(out.getvalue()))
        slash.logger.debug("validation results: {}".format(validationResults))
        res.append({systemName: {'testTime': testTime, 'result':validationResults}})

    if not path.isdir(path.dirname(filePath)):
        os.makedirs(path.dirname(filePath))
    with open(filePath, 'a') as file:
        for line in res:
            json.dump(line,file)
            file.write('\n')
    print(res)


