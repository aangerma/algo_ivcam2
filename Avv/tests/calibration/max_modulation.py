#! python3
import slash
import io
import sys
import os.path as path
import xml.etree.ElementTree as et
import datetime

sys.path.insert(0, r"Avv\tests")
import a_common

sys.path.insert(0, r"algo_automation\infra")
import Robot
import libRealSense
import common


def _get_params_from_xml(root):
    params = dict()
    tests = list()

    for cElement in root.find('./params'):
        params[cElement.tag] = cElement.text

    slash.logger.debug("test params: {}".format(params))

    counter = 0
    for tElement in root.find('./tests'):
        counter += 1
        test = dict()
        test['name'] = tElement.get('name', counter)
        for pElement in tElement:
            test[pElement.tag] = pElement.text
        tests.append(test)

        slash.logger.debug('test: {}'.format(test['name']))

    slash.logger.info("found {} tests to run".format(len(tests)), extra={"highlight": True})
    return params, tests


def _create_data_folder(base_folder, extention):
    df = base_folder
    if '$' in base_folder:
        df = path.join(str(base_folder).replace('$', ''), extention)
        slash.logger.info('data folder: {}'.format(df))
    return df


def maxModulation(xmlPath, debug):
    slash.logger.info("running max modulation tests, xml: {}".format(xmlPath), extra={"highlight": True})

    try:
        xml = et.parse(xmlPath)
    except FileNotFoundError:
        slash.logger.error("test xml definition file not found: {}".format(xmlPath))
        raise FileNotFoundError

    root = xml.getroot()
    params, tests = _get_params_from_xml(root)

    shortTime = datetime.datetime.now().strftime('%m%d%H%M')
    params['dataFolder'] = _create_data_folder(params['dataFolder'], shortTime)

    eng = slash.g.mat
    if not debug:
        robot = Robot.Robot()

    for test in tests:
        slash.logger.info('starting test {}'.format(test['name']), extra={"highlight": True})

        if not debug:
            robot.safe_move('wall_10Reflectivity', test['range'])
        stableTemp = params.get('stableTemp', 'false').lower()
        if stableTemp == 'true':
            camera = libRealSense.LibRealSense(xRes=test.get('xRes', None), yRes=test.get('yRes', None),
                                               frameRate=test.get('frameRate', None))
            if not camera.get_to_stable_temp():
                raise common.TestFail("Test failed On stable temperature")
            camera.close_stream()

        dirName = '{}\{}\{}\{}'.format(params['dataFolder'], test['name'],test['preset'], test['range'])

        slash.logger.info("data: {}".format(dirName))
        out = io.StringIO()
        err = io.StringIO()

        reggresionParams = {'minModprc': params.get('minModprc', 0), 'laserDelta': params.get('laserDelta', 1),
                            'framesNum': params.get('framesNum', 10)}
        maskParams = {'roi': params.get('roi', 0.09), 'isRoiRect': params.get('isRoiRect', 0),
                      'roiCropRect': params.get('roiCropRect', 0), 'centerShiftX': params.get('centerShiftX', 0),
                      'centerShiftY': params.get('centerShiftY', 0)}
        fillRateTh = params.get('fillRateTh', 97)

        mTest = dict()
        for k,v in test.items():
            if v is not None:
                mTest[k] = v
        try:
            slash.logger.debug('send to matlab: reggresionParams: {}'.format(reggresionParams))
            slash.logger.debug('send to matlab: maskParams: {}'.format(maskParams))
            slash.logger.debug('send to matlab: fillRateTh: {}'.format(fillRateTh))
            slash.logger.debug('send to matlab: dirName: {}'.format(dirName))
            slash.logger.debug('send to matlab: test: {}'.format(mTest))
            maxRangeScaleModRef, maxFillRate, targetDist = eng.s.maxModulation(reggresionParams, maskParams, fillRateTh,
                                                                               dirName, mTest, stdout=out, stderr=err,
                                                                               nargout=3)
            slash.logger.info('test: {}, maxRangeScaleModRef {}, maxFillRate: {}, targetDist: {}'.format(test['name'],
                                                                                                         maxRangeScaleModRef,
                                                                                                         maxFillRate,
                                                                                                         targetDist),
                              extra={"highlight": True})
        except Exception as e:
            slash.logger.debug('matlab out: {}'.format(out.getvalue()))
            slash.logger.error('matlab error: {}'.format(err.getvalue()))
            raise e

        slash.logger.debug('matlab out: {}'.format(out.getvalue()))
        slash.logger.info(
            'test: {}, distance: {}, maxRangeScaleModRef: {}'.format(test['name'], test['range'], maxRangeScaleModRef),
            extra={"highlight": True})


@slash.tag('turn_in')
def test_maxModulation():
    filePath = r"X:\Avv\sources\robot\maxModulation.xml"
    debug = False
    maxModulation(filePath, debug)
