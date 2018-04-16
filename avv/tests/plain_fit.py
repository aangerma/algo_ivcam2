#! python3
import slash
import os
import common

@common.ivcam2
def test_wall():
    slash.logger.info("Start")

    eng = slash.g.mat
    data_path = os.path.join(os.path.dirname(os.path.realpath("__file__")), "tests", "data", "wall")
    slash.logger.info("data: {}".format(data_path))
    slash.logger.info("running pattern generator, might take a wail...")
    ivs_file_name,gt,regs,luts = eng.s.Pipe.patternGenerator('wall', 'outputdir',  data_path, nargout=4)
    slash.logger.info("running autopipe, might take a wail...")
    eng.s.Pipe.autopipe(ivs_file_name, nargout=0)






