import slash
import os
import sys
sys.path.insert(0, r"..\algo_automation\infra")
import slash_common


ivcam2 = slash.tag('ivcam2')

@slash.hooks.session_start.register
def session_start_handler():
    slash.logger.info("add algo_ivcam2 to matlab path".format(slash.context.session.id))
    eng = slash.g.mat
    eng.add_path(os.path.join("../algo_ivcam2"))