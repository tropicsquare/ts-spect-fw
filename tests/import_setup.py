import sys
import os

def import_setup():
    ts_repo_root = os.environ["TS_REPO_ROOT"]
    sdk_tests_path = os.path.join(ts_repo_root, 'modules/ts-spect-sdk/tests')
    sys.path.insert(0, sdk_tests_path)
